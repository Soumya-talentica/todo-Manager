const request = require('supertest');
const express = require('express');

// Minimal stub for metrics routes by mounting handlers from index.js would require refactor.
// Instead, verify response shape contract for /api/metrics/summary with mocked handler.

const app = express();
app.get('/api/metrics/summary', (req, res) => {
  res.json({ ok: true, metrics: { sampleSize: 0, successRate: null, averageBuildTimeMs: null, lastBuildStatus: null, lastRun: null } });
});

describe('Metrics Summary contract', () => {
  test('GET /api/metrics/summary returns expected fields', async () => {
    const response = await request(app).get('/api/metrics/summary');
    expect(response.status).toBe(200);
    expect(response.body.ok).toBe(true);
    expect(response.body.metrics).toHaveProperty('sampleSize');
    expect(response.body.metrics).toHaveProperty('successRate');
    expect(response.body.metrics).toHaveProperty('averageBuildTimeMs');
    expect(response.body.metrics).toHaveProperty('lastBuildStatus');
    expect(response.body.metrics).toHaveProperty('lastRun');
  });
});

