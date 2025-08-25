const assert = require('assert');

function getGithubConfig() {
  const { GITHUB_TOKEN, GITHUB_OWNER, GITHUB_REPO } = process.env;
  assert(GITHUB_OWNER, 'GITHUB_OWNER is required');
  assert(GITHUB_REPO, 'GITHUB_REPO is required');
  return { token: GITHUB_TOKEN, owner: GITHUB_OWNER, repo: GITHUB_REPO };
}

async function fetchWorkflowRuns(params = {}) {
  const { owner, repo, token } = getGithubConfig();
  const url = new URL(`https://api.github.com/repos/${owner}/${repo}/actions/runs`);
  url.searchParams.set('per_page', params.per_page || '50');
  if (params.branch) url.searchParams.set('branch', params.branch);
  if (params.event) url.searchParams.set('event', params.event);
  const headers = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'ci-cd-health-monitor',
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`GitHub API error ${res.status}: ${text}`);
  }
  const data = await res.json();
  return data.workflow_runs || [];
}

function computeMetricsFromRuns(workflowRuns) {
  if (!Array.isArray(workflowRuns) || workflowRuns.length === 0) {
    return {
      sampleSize: 0,
      successRate: null,
      averageBuildTimeMs: null,
      lastBuildStatus: null,
      lastRun: null
    };
  }

  let successCount = 0;
  let durationTotalMs = 0;
  let durationCount = 0;

  for (const run of workflowRuns) {
    if (run.conclusion === 'success') successCount += 1;
    // Prefer run_started_at/completed_at if present, fallback to created_at/updated_at
    const startIso = run.run_started_at || run.created_at;
    const endIso = run.updated_at || run.completed_at || run.run_completed_at || run.updated_at;
    if (startIso && endIso) {
      const start = new Date(startIso).getTime();
      const end = new Date(endIso).getTime();
      if (Number.isFinite(start) && Number.isFinite(end) && end >= start) {
        durationTotalMs += (end - start);
        durationCount += 1;
      }
    }
  }

  const lastRun = workflowRuns[0] || null;
  const averageBuildTimeMs = durationCount > 0 ? Math.round(durationTotalMs / durationCount) : null;
  const successRate = Math.round((successCount / workflowRuns.length) * 100);

  return {
    sampleSize: workflowRuns.length,
    successRate,
    averageBuildTimeMs,
    lastBuildStatus: lastRun ? (lastRun.conclusion || lastRun.status) : null,
    lastRun
  };
}

module.exports = { fetchWorkflowRuns, computeMetricsFromRuns };

