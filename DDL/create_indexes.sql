-- Users index
-- Уникальный индекс для быстрого поиска по имени пользователя
CREATE INDEX idx_users_username ON users(username);

-- Tasks indexes
-- GIN index для полнотекстового поиска по имени задачи
CREATE INDEX idx_tasks_task_name_gin ON tasks USING gin (to_tsvector(name));

-- GIN index для полнотекстового поиска по описанию задачи
CREATE INDEX idx_tasks_task_description_gin ON tasks USING gin (to_tsvector(description));

-- Составной индекс для поиска задач по назначенному пользователю и сортировке или группировки по статусу
CREATE INDEX idx_tasks_assigned_to_status ON tasks(assigned_to, status_id);

-- Составной индекс для поиска задач по проекту и статусу
CREATE INDEX idx_tasks_project_id_status ON tasks(project_id, status_id);

-- Log_history индекс
-- Поиск истории изменений по task_id
CREATE INDEX idx_log_history_task_id ON log_history(task_id);

-- Comments индекс
-- Поиск комментариев по task_id и сортировка по created_at
CREATE INDEX idx_comments_task_id_created_at ON comments(task_id, created_at);

-- Files индекс
-- Поиск файлов по task_id
CREATE INDEX idx_files_task_id ON files(task_id);

-- Индекс для поиска файлов по типу
CREATE INDEX idx_files_file_type ON files(file_type);

-- Task_dependencies индекс
-- Поиск зависимых задач по task_id
CREATE INDEX idx_task_dependencies_task_id ON task_dependencies(task_id);

-- Team_members индекс
-- Поиск пользователей в команде
CREATE INDEX idx_team_members_team_id ON team_members(team_id);

-- Time_tracking индексы
-- Поиск записей по task_id и user_id с включением полей hours_spent и entry_date
CREATE INDEX idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id) INCLUDE (hours_spent, entry_date);

-- Поиск записей по task_id и entry_date 
CREATE INDEX idx_time_tracking_task_id_entry_date ON time_tracking(task_id, entry_date) INCLUDE (hours_spent);

-- Поиск записей по user_id и entry_date для анализа активности пользователя
CREATE INDEX idx_time_tracking_user_id_entry_date ON time_tracking(user_id, entry_date) INCLUDE (task_id, hours_spent);
