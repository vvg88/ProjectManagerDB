CREATE PROCEDURE CREATE_PROJECT(
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_start_date DATE,
    IN p_owner_name VARCHAR(255),
    OUT out_project_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_owner_id BIGINT UNSIGNED;

    START TRANSACTION;

    SELECT id INTO v_owner_id
    FROM users
    WHERE username = p_owner_name
    LIMIT 1;

    IF v_owner_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Owner not found';
    END IF;

    SET @status_id = (SELECT id FROM statuses WHERE status = 'planned' LIMIT 1);

    INSERT INTO projects (name, description, start_date, end_date, status_id, created_at, owner_id)
    VALUES (p_name, p_description, p_start_date, NULL, @status_id, CURRENT_TIMESTAMP, v_owner_id);

    SET out_project_id = LAST_INSERT_ID();

    COMMIT;
END

CREATE PROCEDURE CREATE_TEAM(
    IN p_team_name VARCHAR(128),
    IN p_owner_name VARCHAR(255),
    IN p_members JSON,
    OUT out_team_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_owner_id BIGINT UNSIGNED;

    START TRANSACTION;

    SELECT id INTO v_owner_id
    FROM users
    WHERE username = p_owner_name
    LIMIT 1;

    IF v_owner_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Owner not found';
    END IF;

    INSERT INTO teams (team_name, created_at, owner_id)
    VALUES (p_team_name, CURRENT_TIMESTAMP, v_owner_id);

    SET out_team_id = LAST_INSERT_ID();

    IF p_members IS NOT NULL AND JSON_LENGTH(p_members) > 0 THEN
        INSERT INTO team_members (team_id, user_id, role)
        SELECT out_team_id, u.id, COALESCE(members.role, 'member')
        FROM JSON_TABLE(p_members, '$[*]'
            COLUMNS (
                username VARCHAR(255) PATH '$.username',
                role VARCHAR(32) PATH '$.role'
            )
        ) AS members
        JOIN users u ON u.username = members.username;
    END IF;

    COMMIT;
END

