CREATE TABLE projects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status_id BIGINT NOT NULL REFERENCES statuses(status_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    owner_id BIGINT NOT NULL REFERENCES users(id)
);