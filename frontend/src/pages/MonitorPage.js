import React, { useEffect, useState } from 'react';
import axios from 'axios';

function TrendChart({ data, width = 600, height = 120 }) {
  if (!data || data.length === 0) return <div>No trend data</div>;
  const rows = data.filter(r => r.workflow_name === 'all');
  if (rows.length === 0) return <div>No trend data</div>;
  const padding = 20;
  const xVals = rows.map((_, i) => i);
  const yVals = rows.map(r => r.success_rate || 0);
  const minX = 0, maxX = xVals.length - 1;
  const minY = 0, maxY = 100;
  const scaleX = (x) => padding + (x - minX) * ((width - 2 * padding) / Math.max(1, (maxX - minX)));
  const scaleY = (y) => height - padding - (y - minY) * ((height - 2 * padding) / Math.max(1, (maxY - minY)));
  const points = xVals.map((x, i) => `${scaleX(x)},${scaleY(yVals[i])}`).join(' ');
  return (
    <svg width={width} height={height} style={{ border: '1px solid #eee', borderRadius: 6, background: '#fff' }}>
      <polyline fill="none" stroke="#4f46e5" strokeWidth="2" points={points} />
      <text x={padding} y={padding} fontSize="12" fill="#555">Success Rate (%)</text>
    </svg>
  );
}

export default function MonitorPage() {
  const [metrics, setMetrics] = useState({ loading: true, error: null, data: null });
  const [lastUpdated, setLastUpdated] = useState(null);
  const [trends, setTrends] = useState({ loading: true, error: null, data: [] });
  const [recentRuns, setRecentRuns] = useState({ loading: true, error: null, data: [] });

  const fetchMetrics = async () => {
    try {
      const res = await axios.get('/api/metrics/summary');
      setMetrics({ loading: false, error: null, data: res.data.metrics });
      setLastUpdated(new Date());
    } catch (err) {
      setMetrics({ loading: false, error: err.message || 'Failed to load metrics', data: null });
    }
  };

  const fetchTrends = async () => {
    try {
      const res = await axios.get('/api/metrics/trends?windowDays=14');
      setTrends({ loading: false, error: null, data: res.data.data || [] });
    } catch (err) {
      setTrends({ loading: false, error: err.message || 'Failed to load trends', data: [] });
    }
  };

  const fetchRecentRuns = async () => {
    try {
      const res = await axios.get('/api/runs/recent?limit=20');
      setRecentRuns({ loading: false, error: null, data: res.data.data || [] });
    } catch (err) {
      setRecentRuns({ loading: false, error: err.message || 'Failed to load recent runs', data: [] });
    }
  };

  useEffect(() => {
    fetchMetrics();
    fetchTrends();
    fetchRecentRuns();
    const id1 = setInterval(fetchMetrics, 30000);
    const id2 = setInterval(fetchTrends, 60000);
    const id3 = setInterval(fetchRecentRuns, 60000);
    return () => { clearInterval(id1); clearInterval(id2); clearInterval(id3); };
  }, []);

  const kpiStyle = { background: '#fff', border: '1px solid #eee', borderRadius: 6, padding: 12, flex: 1, minWidth: 160 };
  const kpiValueStyle = { fontSize: 22, fontWeight: 700 };
  const formatMs = (ms) => {
    if (ms == null) return '—';
    const s = Math.round(ms / 1000);
    if (s < 60) return `${s}s`;
    const m = Math.floor(s / 60);
    const rem = s % 60;
    return `${m}m ${rem}s`;
  };

  return (
    <div style={{ maxWidth: 900, margin: '2rem auto', fontFamily: 'sans-serif' }}>
      <h2>CI/CD Health</h2>
      <div style={{ marginBottom: 20, padding: 12, background: '#f5f7fb', border: '1px solid #e5e9f2', borderRadius: 6 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h3 style={{ margin: 0 }}>Summary</h3>
          <div style={{ fontSize: 12, color: '#666' }}>{lastUpdated ? `Updated ${lastUpdated.toLocaleTimeString()}` : ''}</div>
        </div>
        {metrics.loading ? (
          <div>Loading metrics…</div>
        ) : metrics.error ? (
          <div style={{ color: 'red' }}>Error: {metrics.error}</div>
        ) : (
          <div style={{ display: 'flex', gap: 12, marginTop: 12, flexWrap: 'wrap' }}>
            <div style={kpiStyle}>
              <div>Success Rate</div>
              <div style={kpiValueStyle}>{metrics.data.successRate != null ? `${metrics.data.successRate}%` : '—'}</div>
            </div>
            <div style={kpiStyle}>
              <div>Avg Build Time</div>
              <div style={kpiValueStyle}>{formatMs(metrics.data.averageBuildTimeMs)}</div>
            </div>
            <div style={kpiStyle}>
              <div>Last Build</div>
              <div style={kpiValueStyle}>{metrics.data.lastBuildStatus || '—'}</div>
            </div>
            <div style={kpiStyle}>
              <div>Sample Size</div>
              <div style={kpiValueStyle}>{metrics.data.sampleSize}</div>
            </div>
          </div>
        )}
      </div>

      <div style={{ marginBottom: 20, padding: 12, background: '#f5f7fb', border: '1px solid #e5e9f2', borderRadius: 6 }}>
        <h3 style={{ marginTop: 0 }}>Trends (Last 14 days)</h3>
        {trends.loading ? <div>Loading…</div> : trends.error ? <div style={{ color: 'red' }}>Error: {trends.error}</div> : <TrendChart data={trends.data} />}
      </div>

      <div style={{ marginBottom: 20, padding: 12, background: '#f5f7fb', border: '1px solid #e5e9f2', borderRadius: 6 }}>
        <h3 style={{ marginTop: 0 }}>Recent Runs</h3>
        {recentRuns.loading ? (
          <div>Loading…</div>
        ) : recentRuns.error ? (
          <div style={{ color: 'red' }}>Error: {recentRuns.error}</div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', background: '#fff' }}>
              <thead>
                <tr>
                  <th style={{ textAlign: 'left', borderBottom: '1px solid #eee', padding: 8 }}>Workflow</th>
                  <th style={{ textAlign: 'left', borderBottom: '1px solid #eee', padding: 8 }}>Status</th>
                  <th style={{ textAlign: 'left', borderBottom: '1px solid #eee', padding: 8 }}>Branch</th>
                  <th style={{ textAlign: 'left', borderBottom: '1px solid #eee', padding: 8 }}>Actor</th>
                  <th style={{ textAlign: 'left', borderBottom: '1px solid #eee', padding: 8 }}>Duration</th>
                  <th style={{ textAlign: 'left', borderBottom: '1px solid #eee', padding: 8 }}>Created</th>
                </tr>
              </thead>
              <tbody>
                {recentRuns.data.map(r => (
                  <tr key={r.id}>
                    <td style={{ borderBottom: '1px solid #f2f2f2', padding: 8 }}>
                      <a href={r.html_url} target="_blank" rel="noreferrer">{r.workflow_name || '—'}</a>
                    </td>
                    <td style={{ borderBottom: '1px solid #f2f2f2', padding: 8 }}>
                      {(r.conclusion || r.status || '—')}
                    </td>
                    <td style={{ borderBottom: '1px solid #f2f2f2', padding: 8 }}>{r.branch || '—'}</td>
                    <td style={{ borderBottom: '1px solid #f2f2f2', padding: 8 }}>{r.actor || '—'}</td>
                    <td style={{ borderBottom: '1px solid #f2f2f2', padding: 8 }}>{formatMs(r.run_duration_ms)}</td>
                    <td style={{ borderBottom: '1px solid #f2f2f2', padding: 8 }}>{r.created_at ? new Date(r.created_at).toLocaleString() : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

