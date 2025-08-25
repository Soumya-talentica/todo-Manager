const { WorkflowRun, MetricsDaily, sequelize } = require('./models');
const { fetchWorkflowRuns } = require('./github');

async function upsertRuns(workflowRuns) {
  for (const run of workflowRuns) {
    const startIso = run.run_started_at || run.created_at;
    const endIso = run.updated_at || run.completed_at || run.run_completed_at || run.updated_at;
    let durationMs = null;
    if (startIso && endIso) {
      const start = new Date(startIso).getTime();
      const end = new Date(endIso).getTime();
      if (Number.isFinite(start) && Number.isFinite(end) && end >= start) durationMs = end - start;
    }
    await WorkflowRun.upsert({
      id: run.id,
      workflow_name: run.name,
      status: run.status,
      conclusion: run.conclusion,
      event: run.event,
      branch: run.head_branch,
      actor: run.actor && run.actor.login,
      html_url: run.html_url,
      created_at: run.created_at,
      updated_at: run.updated_at,
      run_started_at: run.run_started_at,
      run_duration_ms: durationMs
    });
  }
}

async function recomputeDailyMetrics(lookbackDays = 30) {
  // Compute per-day aggregates for recent window
  const [rows] = await sequelize.query(`
    WITH recent AS (
      SELECT * FROM workflow_runs
      WHERE created_at >= NOW() - INTERVAL '${lookbackDays} days'
    ),
    agg AS (
      SELECT 
        DATE(created_at) AS day,
        COALESCE(workflow_name, 'all') AS workflow_name,
        COUNT(*) AS runs,
        SUM(CASE WHEN conclusion = 'success' THEN 1 ELSE 0 END) AS successes,
        SUM(CASE WHEN conclusion IN ('failure','cancelled','timed_out') THEN 1 ELSE 0 END) AS failures,
        AVG(NULLIF(run_duration_ms, 0)) AS avg_duration_ms
      FROM recent
      GROUP BY 1,2
    )
    SELECT day, workflow_name, runs, successes, failures, 
           COALESCE(ROUND(avg_duration_ms)::bigint, NULL) AS avg_duration_ms,
           CASE WHEN runs > 0 THEN ROUND((successes::decimal / runs) * 100)::int ELSE NULL END AS success_rate
    FROM agg
    ORDER BY day DESC, workflow_name;
  `);

  // Upsert aggregates
  for (const r of rows) {
    await MetricsDaily.upsert(r);
  }
}

async function runCollectorCycle() {
  const perPage = process.env.POLL_PER_PAGE ? Number(process.env.POLL_PER_PAGE) : 50;
  const runs = await fetchWorkflowRuns({ per_page: String(perPage) });
  await upsertRuns(runs);
  const lookbackDays = process.env.LOOKBACK_DAYS ? Number(process.env.LOOKBACK_DAYS) : 30;
  await recomputeDailyMetrics(lookbackDays);
}

function startCollector() {
  const enabled = String(process.env.POLL_ENABLED || 'true').toLowerCase() === 'true';
  if (!enabled) {
    console.log('Metrics collector disabled (POLL_ENABLED=false)');
    return;
  }
  const intervalMs = process.env.POLL_INTERVAL_MS ? Number(process.env.POLL_INTERVAL_MS) : 60000;
  console.log(`Starting metrics collector, interval ${intervalMs}ms`);
  // run once at startup
  runCollectorCycle().catch(err => console.error('Collector cycle error:', err));
  // schedule repeats
  setInterval(() => {
    runCollectorCycle().catch(err => console.error('Collector cycle error:', err));
  }, intervalMs);
}

module.exports = { startCollector };

