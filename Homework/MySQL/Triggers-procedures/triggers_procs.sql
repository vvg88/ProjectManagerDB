-- Active: 1776510434773@@127.0.0.1@3306@store_db
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
GRANT SELECT ON store_db.* TO 'manager'@'localhost';

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
