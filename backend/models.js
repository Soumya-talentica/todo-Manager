const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: 'postgres',
    logging: false
  }
);

const Task = sequelize.define('Task', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT
  },
  completed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  }
}, {
  tableName: 'tasks',
  timestamps: false
});

const WorkflowRun = sequelize.define('WorkflowRun', {
  id: { type: DataTypes.BIGINT, primaryKey: true },
  workflow_name: { type: DataTypes.STRING },
  status: { type: DataTypes.STRING },
  conclusion: { type: DataTypes.STRING },
  event: { type: DataTypes.STRING },
  branch: { type: DataTypes.STRING },
  actor: { type: DataTypes.STRING },
  html_url: { type: DataTypes.TEXT },
  created_at: { type: DataTypes.DATE },
  updated_at: { type: DataTypes.DATE },
  run_started_at: { type: DataTypes.DATE },
  run_duration_ms: { type: DataTypes.BIGINT }
}, {
  tableName: 'workflow_runs',
  timestamps: false
});

const MetricsDaily = sequelize.define('MetricsDaily', {
  day: { type: DataTypes.DATEONLY, primaryKey: true },
  workflow_name: { type: DataTypes.STRING, primaryKey: true },
  runs: { type: DataTypes.INTEGER },
  successes: { type: DataTypes.INTEGER },
  failures: { type: DataTypes.INTEGER },
  avg_duration_ms: { type: DataTypes.BIGINT },
  success_rate: { type: DataTypes.INTEGER }
}, {
  tableName: 'metrics_daily',
  timestamps: false
});

module.exports = { sequelize, Task, WorkflowRun, MetricsDaily };
