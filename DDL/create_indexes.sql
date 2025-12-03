-- users indexes
CREATE INDEX idx_users_email_username ON users(email, username);

-- tasks indexes
CREATE INDEX idx_tasks_task_name ON tasks(task_name);
CREATE INDEX idx_tasks_assigned_to_status ON tasks(assigned_to, status_id);
CREATE INDEX idx_tasks_project_id_status ON tasks(project_id, status_id);

-- change_history indexes
CREATE INDEX idx_change_history_task_id_changed_by ON change_history(task_id, changed_by);

-- comments indexes
CREATE INDEX idx_comments_task_id_created_at ON comments(task_id, created_at);

-- files indexes
CREATE INDEX idx_files_task_id ON files(task_id);

-- task_dependencies indexes
CREATE INDEX idx_task_dependencies_dependency_type ON task_dependencies(dependency_type);

-- team_members indexes
CREATE INDEX idx_team_members_user_id_team_id ON team_members(user_id, team_id);

-- time_tracking indexes
CREATE INDEX idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id);
CREATE INDEX idx_time_tracking_task_id_entry_date ON time_tracking(task_id, entry_date);
CREATE INDEX idx_time_tracking_user_id_entry_date ON time_tracking(user_id, entry_date);
