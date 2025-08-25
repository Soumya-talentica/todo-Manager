-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE
);

-- Insert sample tasks
INSERT INTO tasks (title, description, completed) VALUES
('Buy groceries', 'Milk, eggs, bread, and fruits', FALSE),
('Finish assignment', 'Prepare CI/CD health monitor dashboard report', FALSE),
('Book flight tickets', 'Book flight to Delhi for next month', TRUE),
('Read a book', 'Continue reading "Clean Code"', FALSE),
('Workout', 'Do 30 minutes of cardio and strength training', TRUE),
('Pay electricity bill', 'Pay online before due date', FALSE),
('Prepare presentation', 'Slides for Monday team meeting', FALSE);

-- CI/CD health monitor tables
CREATE TABLE IF NOT EXISTS workflow_runs (
    id BIGINT PRIMARY KEY,
    workflow_name VARCHAR(255),
    status VARCHAR(64),
    conclusion VARCHAR(64),
    event VARCHAR(64),
    branch VARCHAR(255),
    actor VARCHAR(255),
    html_url TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    run_started_at TIMESTAMPTZ,
    run_duration_ms BIGINT
);

CREATE INDEX IF NOT EXISTS idx_workflow_runs_created_at ON workflow_runs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_workflow ON workflow_runs(workflow_name);

CREATE TABLE IF NOT EXISTS metrics_daily (
    day DATE,
    workflow_name VARCHAR(255),
    runs INT,
    successes INT,
    failures INT,
    avg_duration_ms BIGINT,
    success_rate INT,
    PRIMARY KEY (day, workflow_name)
);
