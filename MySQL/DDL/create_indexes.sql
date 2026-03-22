-- Индексы для таблицы users
CREATE INDEX idx_users_username ON users(username);

-- Индексы для таблицы tasks
-- Полнотекстовый индекс для поиска по названию задачи
CREATE FULLTEXT INDEX idx_tasks_name_fulltext ON tasks(name);

-- Полнотекстовый индекс для поиска по описанию задачи
CREATE FULLTEXT INDEX idx_tasks_description_fulltext ON tasks(description);

-- Составной индекс для поиска задач по исполнителю и статусу
CREATE INDEX idx_tasks_assigned_to_status ON tasks(assigned_to, status_id);

-- Составной индекс для поиска задач проекта и группировки/сортировки по статусу
CREATE INDEX idx_tasks_project_id_status ON tasks(project_id, status_id);

-- Индексы таблицы log_history
-- Поиск записей истории изменений для конкретной задачи
CREATE INDEX idx_log_history_task_id ON log_history(task_id);

-- Индексы таблицы comments
-- Поиск комментариев по task_id и сортировка по created_at
CREATE INDEX idx_comments_task_id_created_at ON comments(task_id, created_at);

-- Индексы таблицы files
-- Поиск файлов по task_id
CREATE INDEX idx_files_task_id ON files(task_id);

-- Индексы таблицы task_dependencies
-- Поиск зависимых задач по task_id
CREATE INDEX idx_task_dependencies_task_id ON task_dependencies(task_id);

-- Индексы таблицы team_members
-- Поиск пользователей в команде по team_id
CREATE INDEX idx_team_members_team_id ON team_members(team_id);

-- Индексы таблицы time_tracking
-- Поиск записей учёта времени по task_id и user_id (покрывающий индекс включает hours_spent и entry_date)
CREATE INDEX idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id, hours_spent, entry_date);

-- Поиск записей учёта времени для задачи по дате (покрывающий индекс включает hours_spent)
CREATE INDEX idx_time_tracking_task_id_entry_date ON time_tracking(task_id, entry_date, hours_spent);

-- Поиск записей учёта времени для пользователя по дате (покрывающий индекс включает task_id и hours_spent)
CREATE INDEX idx_time_tracking_user_id_entry_date ON time_tracking(user_id, entry_date, task_id, hours_spent);

-- Пример запроса, который выигрывает от этих индексов:
EXPLAIN SELECT username, email FROM users WHERE username = 'user050';
/*
 *  Демо данные для таблицы users включают 100 записей (user001..user100).
 *  Они задаются в файле MySQL/DML/insert_demo_users.sql.
 *
 *  Результат без индекса:
 *  -> Filter: (users.username = 'user050')  (cost=10.2 rows=10)
 *  -> Table scan on users  (cost=10.2 rows=100)
 *  
 *  Результат с индексом:
 *  -> Index lookup on users using idx_users_username (username = 'user050')  (cost=0.35 rows=1)
 */