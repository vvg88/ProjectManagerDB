-- Users indexes
CREATE INDEX idx_users_username ON users(username);

-- Tasks indexes
-- GIN index for full-text search on task name
CREATE INDEX idx_tasks_task_name_gin ON tasks USING gin (to_tsvector(task_name));

-- GIN index for full-text search on task description
CREATE INDEX idx_tasks_task_description_gin ON tasks USING gin (to_tsvector(task_description));

-- Composite partial index to search for tasks assigned to a user in a status == 'completed' (status_id = 3)
CREATE INDEX idx_tasks_assigned_to_status ON tasks(assigned_to, status_id) WHERE status_id = 3;

-- Composite index to search for tasks of a project and group (order) by status
CREATE INDEX idx_tasks_project_id_status ON tasks(project_id, status_id);

-- Log_history indexes
-- Search log history records of a specific task
CREATE INDEX idx_log_history_task_id ON log_history(task_id);

-- Comments indexes
-- Search comments by task_id and order by created_at
CREATE INDEX idx_comments_task_id_created_at ON comments(task_id, created_at);

-- Files indexes
-- Search files by task_id
CREATE INDEX idx_files_task_id ON files(task_id);

-- Task_dependencies indexes
-- Search dependent tasks by task_id
CREATE INDEX idx_task_dependencies_task_id ON task_dependencies(task_id);

-- Team_members indexes
-- Search users in a team
CREATE INDEX idx_team_members_team_id ON team_members(team_id);

-- Time_tracking indexes
-- Search time tracking entries by task_id and user_id
CREATE INDEX idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id) INCLUDE (hours_spent, entry_date);

-- Search time tracking entries for task by date
CREATE INDEX idx_time_tracking_task_id_entry_date ON time_tracking(task_id, entry_date) INCLUDE (hours_spent);

-- Search time tracking entries for user by date
CREATE INDEX idx_time_tracking_user_id_entry_date ON time_tracking(user_id, entry_date) INCLUDE (task_id, hours_spent);
