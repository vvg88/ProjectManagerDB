-- Создание базы данных и таблицы для товаров
CREATE DATABASE store_db;
USE store_db;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    title VARCHAR(32) NOT NULL,
    category VARCHAR(32),
    price INT,
    rating INT,
    status VARCHAR(32) NOT NULL,
    PRIMARY KEY (title)
);

-- Вставляем данные в таблицу products
INSERT INTO products (title, category, price, rating, status) VALUES
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

-- Количество товаров в каждой категории
SELECT category,
       COUNT(*) AS product_count FROM products
GROUP BY category;

-- Количество товаров в каждой категории и статусе
SELECT category, status, COUNT(*) AS product_count FROM products
GROUP BY category, status
ORDER BY category, status;

-- Количество товаров в наличии в каждой категории
SELECT category, status, COUNT(*) AS product_count FROM products
GROUP BY category, status
HAVING status = 'instock'
ORDER BY product_count DESC;

-- Количество товаров в наличии в каждой категории (пример с CASE)
SELECT category,
       SUM(CASE WHEN status = 'instock' THEN 1 ELSE 0 END) AS in_stock_count
FROM products
GROUP BY category

-- Максимальная, минимальная цена в каждой категории и количество товаров в наличии в каждой категории
SELECT title,
       category,
       price,
       MAX(price) OVER (PARTITION BY category) AS max_price_in_category,
       MIN(price) OVER (PARTITION BY category) AS min_price_in_category,
       SUM(CASE WHEN status = 'instock' THEN 1 ELSE 0 END) OVER (PARTITION BY category) AS in_stock_count_in_category
FROM products

-- Суммарная стоимость товаров в каждой категории и сумма по всем категориям
SELECT IF(GROUPING(category), 'Итого', category) AS category,
       SUM(price) AS total_price
FROM products
GROUP BY category
WITH ROLLUP

-- Количество товаров в наличии в каждой категории и общее количество товаров в наличии
SELECT IF(GROUPING(category), 'Итого', category) AS category,
       SUM(CASE WHEN status = 'instock' THEN 1 ELSE 0 END) AS in_stock_count_in_category
FROM products
GROUP BY category
WITH ROLLUP

-- Товары с максимальной и минимальной ценой в каждой категории
WITH products_with_min_max_prices AS (
    SELECT title,
           category,
           price,
           MAX(price) OVER (PARTITION BY category) AS max_price_in_category,
           MIN(price) OVER (PARTITION BY category) AS min_price_in_category
    FROM products
)
SELECT title, category, price
FROM products_with_min_max_prices
WHERE price = max_price_in_category OR price = min_price_in_category