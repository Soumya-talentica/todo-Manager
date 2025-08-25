# To-Do List Manager Backend

Node.js + Express API for To-Do List. Connects to PostgreSQL using Sequelize.

## Endpoints
- `GET /api/tasks` — List tasks
- `POST /api/tasks` — Add a task
- `PUT /api/tasks/:id` — Mark complete
- `DELETE /api/tasks/:id` — Delete a task
- `GET /health` — Health check

## CI/CD Metrics
- `GET /api/metrics/summary` — Returns JSON with `successRate`, `averageBuildTimeMs`, `lastBuildStatus`, `sampleSize`, `lastRun`.
  - Query params: `branch`, `event`, `per_page` (default 50)

### Required environment variables
- `GITHUB_OWNER` — GitHub org/user that owns the repo
- `GITHUB_REPO` — Repository name
- `GITHUB_TOKEN` — (optional) PAT or GitHub App token with `actions:read`

You can use the `.env.example` at the repo root as a template for required variables.

### Webhook and Alerting
- `POST /webhook/github` — Accepts `workflow_run` events. Sends email on failures.
- `POST /api/alerts/test` — Sends a test email.

Env vars for alerts/webhook:
- `GITHUB_WEBHOOK_SECRET` — Optional HMAC secret to validate webhook payloads
- `SMTP_HOST`, `SMTP_PORT` — SMTP server
- `SMTP_USER`, `SMTP_PASS` — Optional SMTP auth
- `SMTP_SECURE` — `true` to use TLS
- `ALERT_FROM`, `ALERT_TO` — Email sender and recipient
 - `FRONTEND_ORIGIN` — Allowed origin for CORS (default: http://localhost:3000)

### Collector and Trends
- Background poller fetches recent workflow runs and computes daily aggregates.
- Env vars:
  - `POLL_ENABLED` (default: true)
  - `POLL_INTERVAL_MS` (default: 60000)
  - `POLL_PER_PAGE` (default: 50)
  - `LOOKBACK_DAYS` (default: 30)

Endpoints:
- `GET /api/metrics/trends?windowDays=7` — Recent daily aggregates
- `GET /api/runs/recent?limit=50` — Recent workflow runs
