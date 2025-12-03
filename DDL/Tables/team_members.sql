CREATE TYPE team_role AS ENUM ('lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member');

CREATE TABLE team_members (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_id BIGINT NOT NULL REFERENCES teams(team_id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role team_role NOT NULL DEFAULT 'member'
);