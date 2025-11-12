CREATE TABLE priorities (
    priority_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    priority_level TEXT NOT NULL UNIQUE,
    color_code TEXT
);