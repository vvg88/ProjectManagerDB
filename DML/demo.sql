SET search_path = proj_manager, PUBLIC;

-- Выбор всех проектов с их статусами и именами владельцев
SELECT p.id,
       p.name,
       p.description,
       p.start_date,
       p.end_date,
       u.username AS owner_username,
       s.status AS status_name
FROM projects p
JOIN users u ON p.owner_id = u.id
JOIN statuses s ON p.status_id = s.id;

-- Выбор всех задач для конкретного проекта с их статусами, приоритетами и именами назначенных пользователей
SELECT t.id,
       t.name,
       t.description,
       t.due_date,
       st.status AS status_name,
       pr.priority_level,
       u.username AS assigned_to_username
FROM tasks t
JOIN statuses st ON t.status_id = st.id
JOIN priorities pr ON t.priority_id = pr.id
JOIN users u ON t.assigned_to = u.id
WHERE t.project_id = 7;

-- Выбор всех комментариев для конкретной задачи с именами комментаторов и датой создания
SELECT c.id,
       c.content,
       u.username AS commenter_username,
       c.created_at
FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.task_id = 3;

-- Выбор всех файлов, прикрепленных к конкретной задаче, с их именами, путями, типами и датой загрузки
SELECT f.id,
       f.file_name,
       f.file_path,
       f.file_type,
       f.created_at
FROM files f
WHERE f.task_id = 3;

-- Обновить задачу
DO $$
    DECLARE v_error_code INT;
BEGIN
    CALL update_task_with_log(
        3,
        'Carol',
        v_error_code,
        p_due_date => '2026-06-15'
    );
END $$;

-- Выбор истории изменений для конкретной задачи с типами изменений, старыми и новыми значениями, датой изменения и именами пользователей, которые внесли изменения
SELECT lh.id,
       lh.change_type,
       lh.old_value,
       lh.new_value,
       lh.changed_at,
       u.username AS changed_by_username
FROM log_history lh
JOIN users u ON lh.changed_by = u.id
WHERE lh.task_id = 3;

-- Выбор членов команды конкретного проекта с их ролями
SELECT p.id AS project_id,
       p.name AS project_name,
       t.id AS team_id,
       t.team_name,
       u.id AS user_id,
       u.username,
       tm.role
FROM projects p
JOIN teams t ON p.owner_id = t.owner_id
JOIN team_members tm ON t.id = tm.team_id
JOIN users u ON tm.user_id = u.id
WHERE p.id = 7;

-- Выбор времени, затраченного пользователями на конкретную задачу, с датой и именами пользователей
SELECT t.id,
       t.name,
       u.id AS user_id,
       u.username,
       tt.entry_date,
       SUM(tt.hours_spent) AS total_hours
FROM tasks t
JOIN time_tracking tt ON t.id = tt.task_id
LEFT JOIN users u ON tt.user_id = u.id
WHERE tt.task_id = 3
GROUP BY t.id, u.id, tt.entry_date
ORDER BY tt.entry_date DESC;