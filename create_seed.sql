-- Create sample tables
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS user_metrics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    login_count INTEGER DEFAULT 0,
    session_duration_minutes INTEGER DEFAULT 0,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data only if tables are empty
INSERT INTO users (username, email, last_login, is_active) 
SELECT * FROM (VALUES 
    ('john_doe', 'john@example.com', NOW() - INTERVAL '2 hours', true),
    ('jane_smith', 'jane@example.com', NOW() - INTERVAL '1 day', true),
    ('bob_wilson', 'bob@example.com', NOW() - INTERVAL '3 days', false),
    ('alice_brown', 'alice@example.com', NOW() - INTERVAL '1 hour', true),
    ('charlie_davis', 'charlie@example.com', NOW() - INTERVAL '5 days', true)
) AS tmp(username, email, last_login, is_active)
WHERE NOT EXISTS (SELECT 1 FROM users);

INSERT INTO user_metrics (user_id, login_count, session_duration_minutes) 
SELECT * FROM (VALUES 
    (1, 45, 120),
    (2, 23, 90),
    (3, 12, 45),
    (4, 67, 180),
    (5, 34, 75)
) AS tmp(user_id, login_count, session_duration_minutes)
WHERE NOT EXISTS (SELECT 1 FROM user_metrics);