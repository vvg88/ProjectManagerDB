CREATE TABLE time_tracking (
    time_entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    hours_spent NUMERIC(6,2) NOT NULL CHECK (hours_spent >= 0),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE
);