CREATE TABLE tasks (
    task_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_name TEXT NOT NULL,
    description TEXT,
    due_date DATE,
    status_id BIGINT NOT NULL REFERENCES statuses(status_id),
    priority_id BIGINT REFERENCES priorities(priority_id),
    project_id BIGINT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    assigned_to BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);