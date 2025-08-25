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
