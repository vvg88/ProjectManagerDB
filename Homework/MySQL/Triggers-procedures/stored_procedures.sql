CREATE DATABASE store_db;
USE store_db;

-- Создание таблицы products
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    name VARCHAR(32) NOT NULL,
    category VARCHAR(32),
    price INT,
    rating INT,
    status VARCHAR(32) NOT NULL,
    PRIMARY KEY (name)
);

-- Вставляем данные в таблицу products
INSERT INTO products (name, category, price, rating, status) VALUES
    ('Laptop', 'Electronics', 1200, 4, 'instock'),
    ('Smartphone', 'Electronics', 800, 5, 'instock'),
    ('Headphones', 'Electronics', 150, 3, 'outofstock'),
    ('Coffee Maker', 'Home Appliances', 100, 4, 'instock'),
    ('Blender', 'Home Appliances', 80, 2, 'instock'),
    ('Vacuum Cleaner', 'Home Appliances', 200, 5, 'outofstock'),
    ('T-Shirt', 'Clothing', 20, 4, 'instock'),
    ('Jeans', 'Clothing', 50, 3, 'instock'),
    ('Jacket', 'Clothing', 100, 5, 'outofstock'),
    ('Sneakers', 'Footwear', 70, 4, 'instock');

-- Создание таблицы sales
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(32) NOT NULL,
    quantity INT NOT NULL,
    sale_price DECIMAL(10, 2) NOT NULL,
    sale_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_name) REFERENCES products(name)
);

-- Вставка демонстрационных данных в таблицу sales
INSERT INTO sales (product_name, quantity, sale_price, sale_date) VALUES
    ('Laptop', 2, 1200.00, '2026-04-15 10:30:00'),
    ('Smartphone', 5, 800.00, '2026-04-15 11:45:00'),
    ('Coffee Maker', 3, 100.00, '2026-04-16 09:15:00'),
    ('T-Shirt', 10, 20.00, '2026-04-16 14:20:00'),
    ('Jeans', 4, 50.00, '2026-04-16 15:50:00'),
    ('Sneakers', 2, 70.00, '2026-04-17 08:30:00'),
    ('Blender', 1, 80.00, '2026-04-17 10:00:00'),
    ('Laptop', 1, 1200.00, '2026-04-17 13:25:00'),
    ('Headphones', 6, 150.00, '2026-04-18 09:00:00'),
    ('Jacket', 3, 100.00, '2026-04-18 11:30:00');

-- Создание пользователей и назначение прав доступа
CREATE USER IF NOT EXISTS 'client'@'localhost' IDENTIFIED BY 'client_pwd';
CREATE USER IF NOT EXISTS 'manager'@'localhost' IDENTIFIED BY 'manager_pwd';

GRANT EXECUTE ON PROCEDURE store_db.GetProducts TO 'client'@'localhost';
GRANT EXECUTE ON PROCEDURE store_db.GetSales TO 'manager'@'localhost';

FLUSH PRIVILEGES;

DELIMITER $$
CREATE PROCEDURE GetProducts(
    IN category_name VARCHAR(32),
    IN status_name VARCHAR(32),
    IN order_by VARCHAR(10),
    IN products_per_page INT,
    IN page_number INT,
    OUT product_count INT)
BEGIN
    -- Вычисляем смещение для пагинации
    DECLARE offset_value INT;
    SET offset_value = (page_number - 1) * products_per_page;

    -- Создание временной таблицы для фильтрации продуктов
    CREATE TEMPORARY TABLE temp_products AS
    SELECT * FROM products
    WHERE (category = category_name OR category_name IS NULL)
      AND (status = status_name OR status_name IS NULL);
    
    -- Подсчет общего количества продуктов, соответствующих фильтрам
    SELECT COUNT(*) INTO product_count FROM temp_products;
    
    -- Выбор продуктов с сортировкой и пагинацией
    IF (order_by = 'price') THEN
        SELECT * FROM temp_products 
        ORDER BY price DESC
        LIMIT offset_value, products_per_page;
    ELSEIF (order_by = 'rating') THEN
        SELECT * FROM temp_products 
        ORDER BY rating DESC
        LIMIT offset_value, products_per_page;
    ELSE
        SELECT * FROM temp_products 
        ORDER BY name
        LIMIT offset_value, products_per_page;
    END IF;
    
    DROP TEMPORARY TABLE temp_products;
END$$
DELIMITER ;

CALL GetProducts(NULL, NULL, 'rating', 10, 1, @count);

DELIMITER $$
CREATE PROCEDURE GetSales(
    IN start_date DATETIME,
    IN end_date DATETIME,
    IN group_by VARCHAR(10),
    OUT total_sales DECIMAL(10, 2))
BEGIN
    -- Вычисляем общую сумму продаж за указанный период
    SELECT SUM(sale_price * quantity) INTO total_sales
    FROM sales
    WHERE sale_date BETWEEN start_date AND end_date;

    -- Создание временной таблицы для объединения данных из sales и products
    CREATE TEMPORARY TABLE temp_sales AS
    SELECT s.product_name, s.quantity, s.sale_date, s.sale_price, p.category FROM sales s
    JOIN products p ON s.product_name = p.name
    WHERE sale_date BETWEEN start_date AND end_date;
    
    -- Группировка данных по дате, продукту или категории
    IF (group_by = 'date') THEN
        SELECT 
            DATE(sale_date) AS sale_day,
            SUM(sale_price * quantity) AS daily_sales,
            SUM(quantity) AS total_quantity
        FROM temp_sales
        GROUP BY sale_day
        ORDER BY sale_day;
    ELSEIF (group_by = 'product') THEN
        SELECT
            product_name,
            SUM(sale_price * quantity) AS product_sales,
            SUM(quantity) AS total_quantity
        FROM temp_sales
        GROUP BY product_name
        ORDER BY product_sales DESC;
    ELSEIF (group_by = 'category') THEN
        SELECT
            category,
            SUM(sale_price * quantity) AS category_sales,
            SUM(quantity) AS total_quantity
        FROM temp_sales
        GROUP BY category
        ORDER BY category_sales DESC;
    ELSE
        SELECT * FROM temp_sales;
    END IF;

    DROP TEMPORARY TABLE temp_sales;
END$$
DELIMITER ;

CALL GetSales('2026-04-15 00:00:00', '2026-04-18 23:59:59', 'category', @total_sales);
