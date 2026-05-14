SET search_path = proj_manager, PUBLIC;

-- Stored procedure to update task and log changes to log_history
CREATE OR REPLACE PROCEDURE update_task_with_log(
    p_task_id BIGINT,
    p_name VARCHAR(255) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_status_id BIGINT DEFAULT NULL,
    p_priority_id BIGINT DEFAULT NULL,
    p_assigned_to BIGINT DEFAULT NULL,
    p_changed_by BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_task RECORD;
    v_change_count INT := 0;
BEGIN
    -- Get current task values
    SELECT * INTO v_old_task FROM tasks WHERE id = p_task_id;
    
    -- Check if task exists
    IF v_old_task IS NULL THEN
        RAISE EXCEPTION 'Task with id % does not exist', p_task_id;
    END IF;

    -- Update task name if provided and changed
    IF p_name IS NOT NULL AND v_old_task.name IS DISTINCT FROM p_name THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, p_changed_by, 'name'::change_type, v_old_task.name, p_name);
        UPDATE tasks SET name = p_name WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Update task description if provided and changed
    IF p_description IS NOT NULL AND v_old_task.description IS DISTINCT FROM p_description THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, p_changed_by, 'description'::change_type, v_old_task.description, p_description);
        UPDATE tasks SET description = p_description WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Update due_date if provided and changed
    IF p_due_date IS NOT NULL AND v_old_task.due_date IS DISTINCT FROM p_due_date THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, p_changed_by, 'due_date'::change_type, v_old_task.due_date::TEXT, p_due_date::TEXT);
        UPDATE tasks SET due_date = p_due_date WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Update status_id if provided and changed
    IF p_status_id IS NOT NULL AND v_old_task.status_id IS DISTINCT FROM p_status_id THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, p_changed_by, 'status'::change_type, v_old_task.status_id::TEXT, p_status_id::TEXT);
        UPDATE tasks SET status_id = p_status_id WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Update priority_id if provided and changed
    IF p_priority_id IS NOT NULL AND v_old_task.priority_id IS DISTINCT FROM p_priority_id THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, p_changed_by, 'priority'::change_type, v_old_task.priority_id::TEXT, p_priority_id::TEXT);
        UPDATE tasks SET priority_id = p_priority_id WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Update assigned_to if provided and changed
    IF p_assigned_to IS NOT NULL AND v_old_task.assigned_to IS DISTINCT FROM p_assigned_to THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, p_changed_by, 'assignment'::change_type, v_old_task.assigned_to::TEXT, p_assigned_to::TEXT);
        UPDATE tasks SET assigned_to = p_assigned_to WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Commit and log result
    IF v_change_count > 0 THEN
        RAISE NOTICE 'Task % updated successfully. % field(s) changed and logged.', p_task_id, v_change_count;
    ELSE
        RAISE NOTICE 'Task % not updated: no changes provided.', p_task_id;
    END IF;

END;
$$;

-- Example usage:
-- CALL update_task_with_log(
--     p_task_id := 1,
--     p_name := 'Updated Task Name',
--     p_status_id := 2,
--     p_changed_by := 1
-- );
