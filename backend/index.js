const express = require('express');
const cors = require('cors');
const { sequelize, Task } = require('./models');
require('dotenv').config();

const app = express();
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const allowedOrigin = process.env.FRONTEND_ORIGIN || '*';
app.use(helmet());
app.use(cors({ origin: allowedOrigin === '*' ? true : allowedOrigin }));
app.use(express.json());

app.get('/health', (req, res) => res.send('OK'));

// CI/CD health metrics
const { fetchWorkflowRuns, computeMetricsFromRuns } = require('./github');
app.get('/api/metrics/summary', async (req, res) => {
  try {
    const { branch, event, per_page } = req.query;
    const runs = await fetchWorkflowRuns({ branch, event, per_page });
    const metrics = computeMetricsFromRuns(runs);
    res.json({ ok: true, metrics });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// Trends API from persisted aggregates
const { MetricsDaily, WorkflowRun } = require('./models');
app.get('/api/metrics/trends', async (req, res) => {
  try {
    const windowDays = req.query.windowDays ? Number(req.query.windowDays) : 7;
    const where = {};
    const rows = await MetricsDaily.findAll({
      where,
      order: [['day', 'DESC'], ['workflow_name', 'ASC']],
      limit: windowDays * 10 // rough cap for multiple workflows
    });
    res.json({ ok: true, data: rows });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// Recent runs API
app.get('/api/runs/recent', async (req, res) => {
  try {
    const limit = req.query.limit ? Number(req.query.limit) : 50;
    const rows = await WorkflowRun.findAll({ order: [['created_at', 'DESC']], limit });
    res.json({ ok: true, data: rows });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// Webhook listener for GitHub Actions (workflow_run events)
const crypto = require('crypto');
const { sendAlertEmail } = require('./mailer');

function verifyGithubSignature(req) {
  const secret = process.env.GITHUB_WEBHOOK_SECRET;
  if (!secret) return true; // signature verification disabled when no secret configured
  const sig = req.get('x-hub-signature-256');
  if (!sig) return false;
  const body = JSON.stringify(req.body);
  const hmac = crypto.createHmac('sha256', secret);
  const digest = 'sha256=' + hmac.update(body).digest('hex');
  try {
    return crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(digest));
  } catch { return false; }
}

const webhookLimiter = rateLimit({ windowMs: 60 * 1000, max: 60 });
app.post('/webhook/github', webhookLimiter, (req, res) => {
  if (!verifyGithubSignature(req)) {
    return res.status(401).send('Invalid signature');
  }
  const event = req.get('x-github-event');
  if (event !== 'workflow_run') {
    return res.status(204).end();
  }
  const run = req.body && req.body.workflow_run;
  if (!run) return res.status(400).send('No workflow_run');
  const conclusion = run.conclusion || run.status;
  if (['failure', 'cancelled', 'timed_out'].includes(conclusion)) {
    const html = `
      <div>
        <p><strong>Workflow failed:</strong> ${run.name}</p>
        <p><strong>Status:</strong> ${conclusion}</p>
        <p><strong>Branch:</strong> ${run.head_branch}</p>
        <p><strong>Commit:</strong> ${run.head_sha}</p>
        <p><a href="${run.html_url}">Open in GitHub</a></p>
      </div>`;
    sendAlertEmail({ subject: `CI/CD Failure: ${run.name}`, html })
      .then(() => res.status(202).json({ ok: true }))
      .catch(err => res.status(500).json({ ok: false, error: err.message }));
  } else {
    res.status(204).end();
  }
});

// Manual test endpoint for alerts (for admins)
app.post('/api/alerts/test', async (req, res) => {
  try {
    const html = '<p>This is a test alert from CI/CD health monitor.</p>';
    await sendAlertEmail({ subject: 'Test CI/CD Alert', html });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/tasks', async (req, res) => {
  const tasks = await Task.findAll();
  res.json(tasks);
});

app.post('/api/tasks', async (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: 'Title required' });
  const task = await Task.create({ title, description });
  res.status(201).json(task);
});

app.put('/api/tasks/:id', async (req, res) => {
  const { id } = req.params;
  const { completed } = req.body;
  const task = await Task.findByPk(id);
  if (!task) return res.status(404).json({ error: 'Not found' });
  task.completed = completed;
  await task.save();
  res.json(task);
});

app.delete('/api/tasks/:id', async (req, res) => {
  const { id } = req.params;
  const task = await Task.findByPk(id);
  if (!task) return res.status(404).json({ error: 'Not found' });
  await task.destroy();
  res.status(204).end();
});

const PORT = process.env.PORT || 5000;
const { startCollector } = require('./collector');
(async () => {
  try {
    await sequelize.authenticate();
    console.log('DB connected');
    // Kick off metrics collector after DB is ready
    startCollector();
    app.listen(PORT, () => console.log(`Server running on ${PORT}`));
  } catch (err) {
    console.error('Unable to connect to DB:', err);
    process.exit(1);
  }
})();
