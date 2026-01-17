CREATE TABLE statistic(
    player_name VARCHAR(100) NOT NULL,
    player_id INT NOT NULL,
    year_game SMALLINT NOT NULL CHECK (year_game > 0),
    points DECIMAL(12,2) CHECK (points >= 0),
    PRIMARY KEY (player_name,year_game)
);

INSERT INTO
    statistic(player_name, player_id, year_game, points)
VALUES
    ('Mike',1,2018,18),
    ('Jack',2,2018,14),
    ('Jackie',3,2018,30),
    ('Jet',4,2018,30),
    ('Luke',1,2019,16),
    ('Mike',2,2019,14),
    ('Jack',3,2019,15),
    ('Jackie',4,2019,28),
    ('Jet',5,2019,25),
    ('Luke',1,2020,19),
    ('Mike',2,2020,17),
    ('Jack',3,2020,18),
    ('Jackie',4,2020,29),
    ('Jet',5,2020,27);

-- Суммарные и средние очки игроков
SELECT player_name, SUM(points) AS total_points, ROUND(AVG(points), 2) AS average_points FROM statistic
GROUP BY player_name
ORDER BY total_points DESC;
/*
player_name|total_points|average_points|
-----------+------------+--------------+
Jackie     |       87.00|         29.00|
Jet        |       82.00|         27.33|
Mike       |       49.00|         16.33|
Jack       |       47.00|         15.67|
Luke       |       35.00|         17.50| */

-- Суммарные очки по годам
SELECT year_game, SUM(points) AS total_points FROM statistic
GROUP BY year_game
ORDER BY year_game DESC;
/*
year_game|total_points|
---------+------------+
     2020|      110.00|
     2019|       98.00|
     2018|       92.00| */

-- CTE для суммарных очков по годам
WITH total_points_per_year(year, total_points) AS
    (SELECT year_game, SUM(points) AS total_points FROM statistic
     GROUP BY year_game)
SELECT * FROM total_points_per_year
ORDER BY year desc
/*
year|total_points|
----+------------+
2020|      110.00|
2019|       98.00|
2018|       92.00| */

-- CTE с использованием оконной функции LAG для сравнения суммарных очков по годам
WITH total_points_per_year(year, total_points) AS
    (SELECT year_game, SUM(points) AS total_points FROM statistic
     GROUP BY year_game)
SELECT year, total_points, LAG(total_points) OVER (ORDER BY year) AS previous_year_points FROM total_points_per_year
ORDER BY year desc
/*
year|total_points|previous_year_points|
----+------------+--------------------+
2020|      110.00|               98.00|
2019|       98.00|               92.00|
2018|       92.00|                    | */

-- Использование GROUPING SETS для получения суммарных очков по игрокам и годам
SELECT
    player_name,
    year_game,
    GROUPING(player_name) AS is_player_name_aggregated,
    GROUPING(year_game) AS is_year_game_aggregated,
    SUM(points) AS total_points
FROM statistic
GROUP BY GROUPING SETS (player_name, year_game)
ORDER BY total_points DESC;
/*
player_name|year_game|is_player_name_aggregated|is_year_game_aggregated|total_points|
-----------+---------+-------------------------+-----------------------+------------+
           |     2020|                        1|                      0|      110.00|
           |     2019|                        1|                      0|       98.00|
           |     2018|                        1|                      0|       92.00|
Jackie     |         |                        0|                      1|       87.00|
Jet        |         |                        0|                      1|       82.00|
Mike       |         |                        0|                      1|       49.00|
Jack       |         |                        0|                      1|       47.00|
Luke       |         |                        0|                      1|       35.00| */

-- Использование CUBE для получения всех возможных комбинаций суммарных очков по игрокам и годам
SELECT
    player_name,
    year_game,
    GROUPING(player_name) AS is_player_name_aggregated,
    GROUPING(year_game) AS is_year_game_aggregated,
    SUM(points) AS total_points
FROM statistic
GROUP BY CUBE(player_name, year_game)
ORDER BY total_points DESC;
/*
player_name|year_game|is_player_name_aggregated|is_year_game_aggregated|total_points|
-----------+---------+-------------------------+-----------------------+------------+
           |         |                        1|                      1|      300.00|
           |     2020|                        1|                      0|      110.00|
           |     2019|                        1|                      0|       98.00|
           |     2018|                        1|                      0|       92.00|
Jackie     |         |                        0|                      1|       87.00|
Jet        |         |                        0|                      1|       82.00|
Mike       |         |                        0|                      1|       49.00|
Jack       |         |                        0|                      1|       47.00|
Luke       |         |                        0|                      1|       35.00|
Jackie     |     2018|                        0|                      0|       30.00|
Jet        |     2018|                        0|                      0|       30.00|
Jackie     |     2020|                        0|                      0|       29.00|
Jackie     |     2019|                        0|                      0|       28.00|
Jet        |     2020|                        0|                      0|       27.00|
Jet        |     2019|                        0|                      0|       25.00|
Luke       |     2020|                        0|                      0|       19.00|
Jack       |     2020|                        0|                      0|       18.00|
Mike       |     2018|                        0|                      0|       18.00|
Mike       |     2020|                        0|                      0|       17.00|
Luke       |     2019|                        0|                      0|       16.00|
Jack       |     2019|                        0|                      0|       15.00|
Mike       |     2019|                        0|                      0|       14.00|
Jack       |     2018|                        0|                      0|       14.00| */
