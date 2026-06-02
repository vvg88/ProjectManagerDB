-- trigger that on user delete sets it as inactive but does not actually delete the user, to preserve data integrity in tasks, comments, log_history, etc. 
CREATE OR REPLACE FUNCTION set_user_inactive_on_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users SET is_active = FALSE WHERE id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_user_inactive_on_delete
BEFORE DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION set_user_inactive_on_delete();
