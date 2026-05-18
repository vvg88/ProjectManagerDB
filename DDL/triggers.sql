SET search_path = proj_manager, PUBLIC;

-- Trigger function to log task updates to log_history
CREATE OR REPLACE FUNCTION log_task_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Log name change
    IF OLD.name IS DISTINCT FROM NEW.name THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (NEW.id, NULL, 'name'::change_type, OLD.name, NEW.name);
    END IF;

    -- Log description change
    IF OLD.description IS DISTINCT FROM NEW.description THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (NEW.id, NULL, 'description'::change_type, OLD.description, NEW.description);
    END IF;

    -- Log due_date change
    IF OLD.due_date IS DISTINCT FROM NEW.due_date THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (NEW.id, NULL, 'due_date'::change_type, OLD.due_date::TEXT, NEW.due_date::TEXT);
    END IF;

    -- Log status_id change
    IF OLD.status_id IS DISTINCT FROM NEW.status_id THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (NEW.id, NULL, 'status'::change_type, OLD.status_id::TEXT, NEW.status_id::TEXT);
    END IF;

    -- Log priority_id change
    IF OLD.priority_id IS DISTINCT FROM NEW.priority_id THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (NEW.id, NULL, 'priority'::change_type, OLD.priority_id::TEXT, NEW.priority_id::TEXT);
    END IF;

    -- Log assigned_to change
    IF OLD.assigned_to IS DISTINCT FROM NEW.assigned_to THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (NEW.id, NULL, 'assignment'::change_type, OLD.assigned_to::TEXT, NEW.assigned_to::TEXT);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on tasks table
CREATE TRIGGER task_update_trigger
AFTER UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION log_task_changes();
