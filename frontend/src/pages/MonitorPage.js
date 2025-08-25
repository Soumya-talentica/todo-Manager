import React, { useEffect, useState } from 'react';
import axios from 'axios';

function StatusBadge({ status }) {
  const getStatusColor = (status) => {
    switch (status) {
      case 'success': return { bg: '#dcfce7', text: '#166534', border: '#bbf7d0' };
      case 'failure': return { bg: '#fef2f2', text: '#dc2626', border: '#fecaca' };
      case 'cancelled': return { bg: '#fef3c7', text: '#d97706', border: '#fed7aa' };
      case 'timed_out': return { bg: '#fef3c7', text: '#d97706', border: '#fed7aa' };
      case 'in_progress': return { bg: '#dbeafe', text: '#2563eb', border: '#bfdbfe' };
      case 'queued': return { bg: '#f3f4f6', text: '#6b7280', border: '#d1d5db' };
      default: return { bg: '#f3f4f6', text: '#6b7280', border: '#d1d5db' };
    }
  };

  const colors = getStatusColor(status);
  return (
    <span style={{
      backgroundColor: colors.bg,
      color: colors.text,
      border: `1px solid ${colors.border}`,
      padding: '4px 8px',
      borderRadius: '12px',
      fontSize: '12px',
      fontWeight: '500',
      textTransform: 'capitalize'
    }}>
      {status || 'unknown'}
    </span>
  );
}

function TrendChart({ data, width = 600, height = 200 }) {
  if (!data || data.length === 0) return (
    <div style={{ 
      height, 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      color: '#6b7280',
      fontSize: '14px'
    }}>
      No trend data available
    </div>
  );

  const rows = data.filter(r => r.workflow_name === 'all');
  if (rows.length === 0) return (
    <div style={{ 
      height, 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      color: '#6b7280',
      fontSize: '14px'
    }}>
      No aggregate trend data available
    </div>
  );

  const padding = 40;
  const chartWidth = width - 2 * padding;
  const chartHeight = height - 2 * padding;
  
  const xVals = rows.map((_, i) => i);
  const yVals = rows.map(r => r.success_rate || 0);
  const minX = 0, maxX = xVals.length - 1;
  const minY = 0, maxY = 100;
  
  const scaleX = (x) => padding + (x - minX) * (chartWidth / Math.max(1, (maxX - minX)));
  const scaleY = (y) => height - padding - (y - minY) * (chartHeight / Math.max(1, (maxY - minY)));
  
  const points = xVals.map((x, i) => `${scaleX(x)},${scaleY(yVals[i])}`).join(' ');
  
  // Generate grid lines
  const gridLines = [];
  for (let i = 0; i <= 4; i++) {
    const y = padding + (i * chartHeight / 4);
    gridLines.push(
      <line key={i} x1={padding} y1={y} x2={width - padding} y2={y} 
            stroke="#e5e7eb" strokeWidth="1" strokeDasharray="2,2" />
    );
  }

  return (
    <div style={{ position: 'relative' }}>
      <svg width={width} height={height} style={{ 
        background: '#fff', 
        borderRadius: '8px',
        border: '1px solid #e5e7eb'
      }}>
        {/* Grid lines */}
        {gridLines}
        
        {/* Chart area */}
        <rect x={padding} y={padding} width={chartWidth} height={chartHeight} 
              fill="none" stroke="#e5e7eb" strokeWidth="1" />
        
        {/* Trend line */}
        <polyline fill="none" stroke="#3b82f6" strokeWidth="3" points={points} />
        
        {/* Data points */}
        {xVals.map((x, i) => (
          <circle key={i} cx={scaleX(x)} cy={scaleY(yVals[i])} r="4" 
                  fill="#3b82f6" stroke="#fff" strokeWidth="2" />
        ))}
        
        {/* Labels */}
        <text x={padding} y={padding - 10} fontSize="12" fill="#6b7280" fontWeight="500">
          Success Rate (%)
        </text>
        <text x={width - padding} y={height - 10} fontSize="12" fill="#6b7280" textAnchor="end">
          {rows[0]?.day ? new Date(rows[0].day).toLocaleDateString() : 'Latest'}
        </text>
      </svg>
    </div>
  );
}

function MetricCard({ title, value, subtitle, trend, icon }) {
  return (
    <div style={{
      background: '#fff',
      border: '1px solid #e5e7eb',
      borderRadius: '12px',
      padding: '20px',
      flex: 1,
      minWidth: '200px',
      boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
        {icon && <span style={{ marginRight: '8px', fontSize: '20px' }}>{icon}</span>}
        <h3 style={{ margin: 0, fontSize: '14px', color: '#6b7280', fontWeight: '500' }}>
          {title}
        </h3>
      </div>
      <div style={{ fontSize: '28px', fontWeight: '700', color: '#111827', marginBottom: '4px' }}>
        {value}
      </div>
      {subtitle && (
        <div style={{ fontSize: '12px', color: '#6b7280' }}>
          {subtitle}
        </div>
      )}
      {trend && (
        <div style={{ 
          fontSize: '12px', 
          color: trend > 0 ? '#059669' : '#dc2626',
          marginTop: '8px'
        }}>
          {trend > 0 ? '↗' : '↘'} {Math.abs(trend)}% from last period
        </div>
      )}
    </div>
  );
}

export default function MonitorPage() {
  const [metrics, setMetrics] = useState({ loading: true, error: null, data: null });
  const [lastUpdated, setLastUpdated] = useState(null);
  const [trends, setTrends] = useState({ loading: true, error: null, data: [] });
  const [recentRuns, setRecentRuns] = useState({ loading: true, error: null, data: [] });
  const [autoRefresh, setAutoRefresh] = useState(true);

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
    
    if (autoRefresh) {
      const id1 = setInterval(fetchMetrics, 30000);
      const id2 = setInterval(fetchTrends, 60000);
      const id3 = setInterval(fetchRecentRuns, 60000);
      return () => { clearInterval(id1); clearInterval(id2); clearInterval(id3); };
    }
  }, [autoRefresh]);

  const formatMs = (ms) => {
    if (ms == null) return '—';
    const s = Math.round(ms / 1000);
    if (s < 60) return `${s}s`;
    const m = Math.floor(s / 60);
    const rem = s % 60;
    return `${m}m ${rem}s`;
  };

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    return `${diffDays}d ago`;
  };

  if (metrics.loading) {
    return (
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        height: '400px',
        fontSize: '16px',
        color: '#6b7280'
      }}>
        Loading CI/CD metrics...
      </div>
    );
  }

  if (metrics.error) {
    return (
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        height: '400px',
        fontSize: '16px',
        color: '#dc2626'
      }}>
        Error: {metrics.error}
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '24px', fontFamily: 'system-ui, -apple-system, sans-serif' }}>
      {/* Header */}
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        marginBottom: '32px',
        paddingBottom: '16px',
        borderBottom: '1px solid #e5e7eb'
      }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: '700', color: '#111827' }}>
            CI/CD Health Monitor
          </h1>
          <p style={{ margin: '8px 0 0 0', color: '#6b7280', fontSize: '14px' }}>
            Monitor your GitHub Actions workflows and build health
          </p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px' }}>
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              style={{ margin: 0 }}
            />
            Auto-refresh
          </label>
          {lastUpdated && (
            <div style={{ fontSize: '12px', color: '#6b7280' }}>
              Updated {lastUpdated.toLocaleTimeString()}
            </div>
          )}
        </div>
      </div>

      {/* KPI Cards */}
      <div style={{ display: 'flex', gap: '20px', marginBottom: '32px', flexWrap: 'wrap' }}>
        <MetricCard
          title="Success Rate"
          value={metrics.data.successRate != null ? `${metrics.data.successRate}%` : '—'}
          subtitle={`${metrics.data.sampleSize} runs analyzed`}
          icon="📊"
        />
        <MetricCard
          title="Average Build Time"
          value={formatMs(metrics.data.averageBuildTimeMs)}
          subtitle="Recent workflow runs"
          icon="⏱️"
        />
        <MetricCard
          title="Last Build Status"
          value={<StatusBadge status={metrics.data.lastBuildStatus} />}
          subtitle="Most recent workflow run"
          icon="🔄"
        />
        <MetricCard
          title="Total Runs"
          value={metrics.data.sampleSize || 0}
          subtitle="In analyzed period"
          icon="📈"
        />
      </div>

      {/* Trends Chart */}
      <div style={{ 
        background: '#fff', 
        border: '1px solid #e5e7eb', 
        borderRadius: '12px', 
        padding: '24px',
        marginBottom: '32px',
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
      }}>
        <h3 style={{ margin: '0 0 20px 0', fontSize: '18px', fontWeight: '600', color: '#111827' }}>
          Success Rate Trends (Last 14 Days)
        </h3>
        {trends.loading ? (
          <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#6b7280' }}>
            Loading trends...
          </div>
        ) : trends.error ? (
          <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#dc2626' }}>
            Error: {trends.error}
          </div>
        ) : (
          <TrendChart data={trends.data} />
        )}
      </div>

      {/* Recent Runs Table */}
      <div style={{ 
        background: '#fff', 
        border: '1px solid #e5e7eb', 
        borderRadius: '12px',
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
      }}>
        <div style={{ padding: '24px 24px 16px 24px', borderBottom: '1px solid #e5e7eb' }}>
          <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '600', color: '#111827' }}>
            Recent Workflow Runs
          </h3>
        </div>
        {recentRuns.loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>
            Loading recent runs...
          </div>
        ) : recentRuns.error ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#dc2626' }}>
            Error: {recentRuns.error}
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ backgroundColor: '#f9fafb' }}>
                  <th style={{ textAlign: 'left', padding: '16px 24px', fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Workflow
                  </th>
                  <th style={{ textAlign: 'left', padding: '16px 16px', fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Status
                  </th>
                  <th style={{ textAlign: 'left', padding: '16px 16px', fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Branch
                  </th>
                  <th style={{ textAlign: 'left', padding: '16px 16px', fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Actor
                  </th>
                  <th style={{ textAlign: 'left', padding: '16px 16px', fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Duration
                  </th>
                  <th style={{ textAlign: 'left', padding: '16px 16px', fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Created
                  </th>
                </tr>
              </thead>
              <tbody>
                {recentRuns.data.map((run, index) => (
                  <tr key={run.id} style={{ 
                    borderBottom: '1px solid #f3f4f6',
                    backgroundColor: index % 2 === 0 ? '#fff' : '#f9fafb'
                  }}>
                    <td style={{ padding: '16px 24px' }}>
                      <a 
                        href={run.html_url} 
                        target="_blank" 
                        rel="noreferrer"
                        style={{ 
                          color: '#3b82f6', 
                          textDecoration: 'none', 
                          fontWeight: '500',
                          fontSize: '14px'
                        }}
                        onMouseEnter={(e) => e.target.style.textDecoration = 'underline'}
                        onMouseLeave={(e) => e.target.style.textDecoration = 'none'}
                      >
                        {run.workflow_name || '—'}
                      </a>
                    </td>
                    <td style={{ padding: '16px 16px' }}>
                      <StatusBadge status={run.conclusion || run.status} />
                    </td>
                    <td style={{ padding: '16px 16px', fontSize: '14px', color: '#374151' }}>
                      {run.branch || '—'}
                    </td>
                    <td style={{ padding: '16px 16px', fontSize: '14px', color: '#374151' }}>
                      {run.actor || '—'}
                    </td>
                    <td style={{ padding: '16px 16px', fontSize: '14px', color: '#374151' }}>
                      {formatMs(run.run_duration_ms)}
                    </td>
                    <td style={{ padding: '16px 16px', fontSize: '14px', color: '#6b7280' }}>
                      {formatDate(run.created_at)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {recentRuns.data.length === 0 && (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>
                No recent workflow runs found
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

