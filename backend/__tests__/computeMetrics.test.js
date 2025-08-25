const { computeMetricsFromRuns } = require('../github');

describe('computeMetricsFromRuns', () => {
  test('handles empty input', () => {
    const m = computeMetricsFromRuns([]);
    expect(m.sampleSize).toBe(0);
    expect(m.successRate).toBeNull();
    expect(m.averageBuildTimeMs).toBeNull();
    expect(m.lastBuildStatus).toBeNull();
  });

  test('computes success rate and avg duration', () => {
    const now = Date.now();
    const runs = [
      { id: 1, conclusion: 'success', created_at: new Date(now - 60000).toISOString(), updated_at: new Date(now).toISOString() },
      { id: 2, conclusion: 'failure', created_at: new Date(now - 120000).toISOString(), updated_at: new Date(now - 60000).toISOString() }
    ];
    const m = computeMetricsFromRuns(runs);
    expect(m.sampleSize).toBe(2);
    expect(m.successRate).toBe(50);
    expect(m.averageBuildTimeMs).toBeGreaterThan(0);
    expect(['success', 'failure', 'queued', 'in_progress', null]).toContain(m.lastBuildStatus);
  });
});

