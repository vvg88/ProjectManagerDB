SET search_path = proj_manager, PUBLIC;

-- Project information
SELECT p.name, p.description, p.start_date, p.end_date, u.username AS owner_username, s.name AS status_name FROM projects p
JOIN users u ON p.owner_id = u.id
JOIN statuses s ON p.status_id = s.id

-- Tasks for a specific project
SELECT t.name, t.description, t.due_date, st.status AS status_name, pr.priority_level, u.username AS assigned_to_username FROM tasks t
JOIN statuses st ON t.status_id = st.id
JOIN priorities pr ON t.priority_id = pr.id
JOIN users u ON t.assigned_to_id = u.id
WHERE t.project_id = :project_id

-- Task comments
SELECT c.content, u.username AS commenter_username, c.created_at FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.task_id = :task_id

-- Files associated with a task
SELECT f.file_name, f.file_path, f.uploaded_at FROM files f
WHERE f.task_id = :task_id

-- Task change history
SELECT lh.change_type, lh.old_value, lh.new_value, lh.changed_at, u.username AS changed_by_username FROM log_history lh
JOIN users u ON lh.changed_by = u.id
WHERE lh.task_id = :task_id

-- Team members
SELECT t.team_name, u.username, tm.team_role FROM teams t
JOIN team_members tm ON t.id = tm.team_id
JOIN users u ON tm.user_id = u.id
WHERE t.id = :team_id

-- Team members involved in a specific project
SELECT p.name, t.team_name, u.username, tm.team_role FROM projects p
JOIN teams t ON p.owner_id = t.owner_id
JOIN team_members tm ON t.id = tm.team_id
JOIN users u ON tm.user_id = u.id
WHERE p.id = :project_id

-- Task dependencies
SELECT td.dependency_type, t1.name AS task_name, t2.name AS dependent_task_name FROM task_dependencies td
JOIN tasks t1 ON td.task_id = t1.id
JOIN tasks t2 ON td.dependent_task_id = t2.id
WHERE td.task_id = :task_id

-- Time tracking for task and user by date
SELECT t.name, u.username, tt.entry_date, SUM(tt.hours_spent) AS total_hours FROM tasks t
JOIN time_tracking tt ON t.id = tt.task_id
JOIN users u ON tt.user_id = u.id
WHERE tt.task_id = :task_id
GROUP BY tt.task_id, tt.user_id, tt.entry_date;
