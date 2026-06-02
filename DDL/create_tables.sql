SET search_path = proj_manager, PUBLIC;

-- Create enums
CREATE TYPE change_type AS ENUM ('status', 'name', 'description', 'comment', 'assignment', 'due_date', 'priority');
CREATE TYPE dependency_type AS ENUM ('blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of');
CREATE TYPE team_role AS ENUM ('lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member');
CREATE TYPE file_type AS ENUM ('zip', 'rar', '7z', 'pdf', 'log', 'doc', 'other');

-- Create tables
CREATE TABLE priorities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    priority_level VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE statuses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE projects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status_id BIGINT NOT NULL REFERENCES statuses(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    owner_id BIGINT NOT NULL REFERENCES users(id)
);

CREATE TABLE tasks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    status_id BIGINT NOT NULL REFERENCES statuses(id),
    priority_id BIGINT NOT NULL REFERENCES priorities(id),
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    assigned_to BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE files (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_type file_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE comments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE log_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    changed_by BIGINT NOT NULL REFERENCES users(id),
    change_type change_type NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE task_dependencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    dependent_task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    dependency_type dependency_type NOT NULL,
    UNIQUE (task_id, dependent_task_id)
);

CREATE TABLE teams (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_name VARCHAR(128) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    owner_id BIGINT NOT NULL REFERENCES users(id)
);

CREATE TABLE team_members (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_id BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    role team_role NOT NULL DEFAULT 'member'
);

CREATE TABLE time_tracking (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    hours_spent NUMERIC(6,2) NOT NULL CHECK (hours_spent >= 0 AND hours_spent <= 16),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE
);