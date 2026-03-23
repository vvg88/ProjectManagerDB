CREATE DATABASE sales_db;

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

    -- Insert stores
    SET i = 1;
    WHILE i <= store_count DO
        INSERT INTO stores (address) VALUES (CONCAT('Store Address ', i));
        SET i = i + 1;
    END WHILE;

    -- Insert sales
    SET i = 1;
    WHILE i <= sales_count DO
        -- Choose store: 70% chance for store 1
        IF RAND() < 0.7 THEN
            SET s_id = 1;
        ELSE
            SET s_id = FLOOR(RAND() * 9) + 2; -- 2 to 10
        END IF;

        -- Random date in last 2 years (approx 730 days)
        SET sale_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 730) DAY);

        -- Random amount between 1.00 and 1000.00
        SET amount = ROUND(RAND() * 999 + 1, 2);

        INSERT INTO sales (store_id, date, sale_amount) VALUES (s_id, sale_date, amount);

        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL generate_data();

-- Пример запроса с оконной функцией для анализа роста продаж по месяцам для каждого магазина
WITH sales_in_month AS (
    SELECT store_id,
           DATE_FORMAT(date, '%Y-%m') AS month,
           SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY store_id, month
)
SELECT store_id,
       month,
       total_sales,
       SUM(total_sales) OVER (PARTITION BY store_id ORDER BY total_sales) AS total_sales_growing
FROM sales_in_month
ORDER BY store_id;

-- Пример запроса с оконной функцией для расчёта скользящего среднего продаж за 7 дней для магазина с наибольшими продажами
WITH store_total_sales AS (
    SELECT store_id,
           SUM(sale_amount) AS total_sales
    FROM sales
    WHERE date >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
    GROUP BY store_id
    ORDER BY total_sales DESC
    LIMIT 1
),
sales_in_day AS (
    SELECT store_id,
        DATE(date) AS sale_date,
        SUM(sale_amount) AS total_sales_in_day
    FROM sales
    WHERE date >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
    AND store_id = (SELECT store_id FROM store_total_sales)
    GROUP BY store_id, DATE(date)
)
SELECT 
    store_id,
    sale_date,
    total_sales_in_day,
    AVG(total_sales_in_day) OVER (
        PARTITION BY store_id 
        ORDER BY sale_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day
FROM sales_in_day
ORDER BY store_id, sale_date;

