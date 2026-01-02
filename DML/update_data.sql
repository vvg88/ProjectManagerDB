SET search_path = proj_manager, PUBLIC;

-- Tasks
-- Create new task
INSERT INTO tasks (name, description, due_date, status_id, priority_id, project_id, assigned_to)
VALUES (
    :task_name,
    :task_description,
    :task_due_date,
    (SELECT id FROM statuses WHERE status = 'planned'),
    (SELECT id FROM priorities WHERE priority_level = 'normal'),
    :project_id,
    :assigned_user_id)
RETURNING id, name, description;

-- Update existing task
UPDATE tasks SET
    name = :task_name,
    description = :task_description,
    due_date = :task_due_date,
    status_id = (SELECT id FROM statuses WHERE status = :status),
    priority_id = (SELECT id FROM priorities WHERE priority_level = :priority_level),
    assigned_to = :assigned_user_id
WHERE id = :task_id;

-- Create task dependency
INSERT INTO task_dependencies (task_id, dependent_task_id, dependency_type) VALUES
    (:task_id,
    :dependent_task_id,
    :dependency_type);

-- Comments
-- Add task's comment
INSERT INTO comments (task_id, user_id, content) VALUES
    (:task_id,
    :commenter_user_id,
    :comment_content);
RETURNING (SELECT username FROM users WHERE id = :commenter_user_id) AS commenter_username, created_at;

-- Update task's comment
UPDATE comments SET content = :comment_content
WHERE id = :comment_id
  AND task_id = :task_id;

-- Delete comments that are not linked to any task
DELETE FROM comments
WHERE task_id NOT IN (SELECT id FROM tasks);

-- Files
-- Attach file to task
INSERT INTO files (task_id, file_name, file_path) VALUES
    (:task_id,
    :file_name,
    :file_path);

-- Delete files that are not linked to any task
DELETE FROM files
WHERE task_id NOT IN (SELECT id FROM tasks);

-- Change log history
-- Save task change history
INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value) VALUES
    (:task_id,
    :changed_by_user_id,
    :change_type,
    :old_value,
    :new_value);

-- Delete log history entries that are not linked to any task
DELETE FROM log_history
WHERE task_id NOT IN (SELECT id FROM tasks);

-- Time tracking
-- Create time tracking entry
INSERT INTO time_tracking (task_id, user_id, entry_date, hours_spent) VALUES
    (:task_id,
    :user_id,
    :entry_date,
    :hours_spent);

-- Update time tracking entry
UPDATE time_tracking SET hours_spent = :hours_spent
WHERE task_id = :task_id
  AND user_id = :user_id
  AND entry_date = :entry_date;

-- Delete time tracking entries that are not linked to any task
DELETE FROM time_tracking
WHERE task_id NOT IN (SELECT id FROM tasks);

-- Delete time tracking entries for a specific user name
DELETE FROM time_tracking tt
USING users u
WHERE tt.user_id = u.id AND u.username = :user_name;

-- Teams
-- Create team
INSERT INTO teams (team_name, owner_id) VALUES
    (:team_name,
    :owner_user_id);

-- Add member to team
INSERT INTO team_members (team_id, user_id, role) VALUES
    (:team_id,
    :member_user_id,
    :role);
