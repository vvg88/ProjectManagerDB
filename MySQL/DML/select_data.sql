-- Active: 1771063096281@@127.0.0.1@3306@project_manager_db
USE project_manager_db;

-- Получить информацию обо всех проектах
SELECT p.name, p.description, p.start_date, p.end_date, u.username AS owner_username, s.status AS status_name FROM projects p
JOIN users u ON p.owner_id = u.id
JOIN statuses s ON p.status_id = s.id

-- Задачи в статусе 'active' для проекта ':project_id'
SELECT t.name, pr.priority_level, u.username AS assigned_to_username FROM tasks t
JOIN statuses st ON t.status_id = st.id
JOIN priorities pr ON t.priority_id = pr.id
JOIN users u ON t.assigned_to = u.id
WHERE t.project_id = :project_id AND st.status = 'active'

-- Задачи не в статусе 'active' для проекта ':project_id'
SELECT t.name, pr.priority_level, u.username AS assigned_to_username FROM tasks t
JOIN statuses st ON t.status_id = st.id
JOIN priorities pr ON t.priority_id = pr.id
JOIN users u ON t.assigned_to = u.id
WHERE t.project_id = :project_id AND st.status <> 'active'

-- Комментарии к задаче
SELECT c.content, u.username AS commenter_username, c.created_at FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.task_id = :task_id

-- Файлы, прикрепленные к задаче
SELECT f.file_name, f.file_path, f.uploaded_at FROM files f
WHERE f.task_id = :task_id

-- История изменений задачи ':task_id'
SELECT lh.old_value, lh.new_value, lh.changed_at, u.username AS changed_by_username FROM log_history lh
JOIN users u ON lh.changed_by = u.id
WHERE lh.task_id = :task_id

-- История изменений статуса для задачи ':task_id'
SELECT lh.old_value->>'$.status' AS old_status,
       lh.new_value->>'$.status' AS new_status,
       lh.changed_at, u.username AS changed_by_username
FROM log_history lh
JOIN users u ON lh.changed_by = u.id
WHERE lh.task_id = :task_id AND lh.old_value->>'$.status' <> lh.new_value->>'$.status'

-- Члены команды ':team_id'
SELECT t.team_name, u.username, tm.role FROM teams t
JOIN team_members tm ON t.id = tm.team_id
JOIN users u ON tm.user_id = u.id
WHERE t.id = :team_id

-- Пользователи, не входящие ни в одну команду
SELECT u.username FROM team_members tm
RIGHT JOIN users u ON tm.user_id = u.id
WHERE tm.id IS NULL

-- Члены команды, участвующие в проекте ':project_id'
SELECT p.name, t.team_name, u.username, tm.role FROM projects p
JOIN teams t ON p.owner_id = t.owner_id
JOIN team_members tm ON t.id = tm.team_id
JOIN users u ON tm.user_id = u.id
WHERE p.id = :project_id

-- Зависимые задачи для задачи ':task_id'
SELECT td.dependency_type, t1.name AS task_name, t2.name AS dependent_task_name FROM task_dependencies td
JOIN tasks t1 ON td.task_id = t1.id
JOIN tasks t2 ON td.dependent_task_id = t2.id
WHERE td.task_id = :task_id

-- Затраты времени на задачу ':task_id' сгруппированные по пользователям и дням
SELECT t.name, u.username, tt.entry_date, SUM(tt.hours_spent) AS total_hours FROM tasks t
JOIN time_tracking tt ON t.id = tt.task_id
JOIN users u ON tt.user_id = u.id
WHERE tt.task_id = :task_id
GROUP BY tt.user_id, tt.entry_date;

-- Затраты времени для пользователя ':user_id' сгруппированные по дням и задачам за последние 7 дней
SELECT u.username,
       tt.entry_date,
       SUM(tt.hours_spent) AS total_hours
FROM time_tracking tt
JOIN users u ON tt.user_id = u.id
WHERE tt.user_id = :user_id
      AND tt.entry_date BETWEEN DATE_SUB(:entry_date, INTERVAL 7 DAY) AND :entry_date
GROUP BY tt.entry_date, tt.task_id
ORDER BY tt.entry_date;
