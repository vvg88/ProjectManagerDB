CREATE DATABASE sales_db;
USE sales_db;

CREATE TABLE stores (
    store_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(50) NOT NULL
);

CREATE TABLE sales (
    sale_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    store_id BIGINT UNSIGNED REFERENCES stores (store_id),
    date TIMESTAMP NOT NULL,
    sale_amount DECIMAL(10,2) NOT NULL
);

-- Процедура для генерации данных
DELIMITER //
CREATE PROCEDURE generate_data()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE store_count INT DEFAULT 10;
    DECLARE sales_count INT DEFAULT 10000;
    DECLARE s_id BIGINT UNSIGNED;
    DECLARE sale_date TIMESTAMP;
    DECLARE amount DECIMAL(10,2);

    -- Вставляем магазины
    SET i = 1;
    WHILE i <= store_count DO
        INSERT INTO stores (address) VALUES (CONCAT('Store Address ', i));
        SET i = i + 1;
    END WHILE;

    -- Вставляем продажи
    SET i = 1;
    WHILE i <= sales_count DO
        -- Случайный магазин от 1 до 10
        SET s_id = FLOOR(RAND() * 10) + 1; -- 1 to 10

        -- Случайная дата продажи в пределах последних 2 лет
        SET sale_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 730) DAY);

        -- Случайная сумма продаж между 1.00 и 1000.00
        SET amount = ROUND(RAND() * 999 + 1, 2);

        INSERT INTO sales (store_id, date, sale_amount) VALUES (s_id, sale_date, amount);
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL generate_data();

-- Исходный запрос для получения магазинов, у которых объем продаж в месяц превышает средний объем продаж по этому магазину
EXPLAIN ANALYZE
WITH sales_in_month AS (
    SELECT store_id,
           DATE_FORMAT(date, '%Y-%m') AS month,
           SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY store_id, month
)
SELECT s.store_id, s.address, sim.month, sim.total_sales FROM sales_in_month sim
JOIN stores s ON sim.store_id = s.store_id
WHERE sim.total_sales > (
    SELECT AVG(total_sales) FROM sales_in_month WHERE store_id = sim.store_id
)
ORDER BY sim.month, sim.total_sales;

-- Оптимизированный запрос с использованием CTE для предварительного расчета среднего объема продаж по каждому магазину
EXPLAIN ANALYZE
WITH sales_in_month AS (
    SELECT store_id,
           DATE_FORMAT(date, '%Y-%m') AS month,
           SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY store_id, month
),
store_avg AS (
    SELECT store_id,
           AVG(total_sales) AS avg_sales
    FROM sales_in_month
    GROUP BY store_id
)
SELECT s.store_id, s.address, sim.month, sim.total_sales 
FROM sales_in_month sim
JOIN stores s ON sim.store_id = s.store_id
JOIN store_avg sa ON sim.store_id = sa.store_id
WHERE sim.total_sales > sa.avg_sales
ORDER BY sim.month, sim.total_sales;
