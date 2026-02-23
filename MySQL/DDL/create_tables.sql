-- Active: 1771063096281@@127.0.0.1@3306@project_manager_db
USE project_manager_db;

-- Create enums
-- CREATE TYPE change_type AS ENUM ('status', 'name', 'description', 'comment', 'assignment', 'due_date', 'priority');
-- CREATE TYPE dependency_type AS ENUM ('blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of');
-- CREATE TYPE team_role AS ENUM ('lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member');

-- Create tables
CREATE TABLE priorities (
    id SERIAL PRIMARY KEY,
    priority_level VARCHAR(32) NOT NULL UNIQUE,
    color_code VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE statuses (
    id SERIAL PRIMARY KEY,
    status VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status_id BIGINT UNSIGNED NOT NULL REFERENCES statuses(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    owner_id BIGINT UNSIGNED NOT NULL REFERENCES users(id)
);

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    status_id BIGINT UNSIGNED NOT NULL REFERENCES statuses(id),
    priority_id BIGINT UNSIGNED REFERENCES priorities(id),
    project_id BIGINT UNSIGNED NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    assigned_to BIGINT UNSIGNED REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE files (
    id SERIAL PRIMARY KEY,
    task_id BIGINT UNSIGNED NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    task_id BIGINT UNSIGNED NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id BIGINT UNSIGNED REFERENCES users(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Log history table to track changes to tasks. Stores old and new values as JSON having the following structure:
-- {
--    "status": "In Progress",
--    "name": "Implement login feature",
--    "description": "Implement user authentication and authorization",
--    "assigned_to": 123,
--    "due_date": "2024-12-31",
--    "priority_id": 2
-- }
CREATE TABLE log_history (
    id SERIAL PRIMARY KEY,
    task_id BIGINT UNSIGNED NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    changed_by BIGINT UNSIGNED REFERENCES users(id) ON DELETE SET NULL,
    old_value JSON,
    new_value JSON,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_dependencies (
    id SERIAL PRIMARY KEY,
    task_id BIGINT UNSIGNED NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    dependent_task_id BIGINT UNSIGNED NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    dependency_type ENUM ('blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of') NOT NULL DEFAULT 'relates_to',
    UNIQUE (task_id, dependent_task_id)
);

CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    team_name VARCHAR(128) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    owner_id BIGINT UNSIGNED REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE team_members (
    id SERIAL PRIMARY KEY,
    team_id BIGINT UNSIGNED NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id BIGINT UNSIGNED NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role ENUM ('lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member') NOT NULL DEFAULT 'member'
);

CREATE TABLE time_tracking (
    id SERIAL PRIMARY KEY,
    task_id BIGINT UNSIGNED NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id BIGINT UNSIGNED REFERENCES users(id) ON DELETE SET NULL,
    hours_spent DECIMAL(6,2) NOT NULL CHECK (hours_spent >= 0),
    entry_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);