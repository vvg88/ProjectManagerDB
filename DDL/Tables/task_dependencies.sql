CREATE TYPE dependency_type AS ENUM ('blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of');

CREATE TABLE task_dependencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    dependent_task_id BIGINT NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    dependency_type dependency_type NOT NULL,
    UNIQUE (task_id, dependent_task_id)
);