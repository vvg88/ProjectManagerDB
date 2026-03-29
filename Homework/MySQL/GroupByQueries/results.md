# Запросы и результаты

### Количество товаров в каждой категории

``` sql
SELECT category,
       COUNT(*) AS product_count FROM products
GROUP BY category;
```

| category | product_count |
|----------|---------------|
| Home Appliances | 3 |
| Electronics | 3 |
| Clothing | 3 |
| Footwear | 1 |

### Количество товаров в каждой категории и статусе

``` sql
SELECT category, status, COUNT(*) AS product_count FROM products
GROUP BY category, status
ORDER BY category, status;
```

| category | status | product_count |
|----------|--------|---------------|
| Clothing | instock | 2 |
| Clothing | outofstock | 1 |
| Electronics | instock | 2 |
| Electronics | outofstock | 1 |
| Footwear | instock | 1 |
| Home Appliances | instock | 2 |
| Home Appliances | outofstock | 1 |

### Количество товаров в наличии в каждой категории

``` sql
SELECT category, status, COUNT(*) AS product_count FROM products
GROUP BY category, status
HAVING status = 'instock'
ORDER BY product_count DESC;
```

| category | status | product_count |
|----------|--------|---------------|
| Home Appliances | instock | 2 |
| Clothing | instock | 2 |
| Electronics | instock | 2 |
| Footwear | instock | 1 |

### Количество товаров в наличии в каждой категории (пример с CASE)

``` sql
SELECT category,
       SUM(CASE WHEN status = 'instock' THEN 1 ELSE 0 END) AS in_stock_count
FROM products
GROUP BY category
```

| category | in_stock_count |
|----------|----------------|
| Home Appliances | 2 |
| Electronics | 2 |
| Clothing | 2 |
| Footwear | 1 |

### Максимальная, минимальная цена в каждой категории и количество товаров в наличии в каждой категории
``` sql
SELECT title,
       category,
       price,
       MAX(price) OVER (PARTITION BY category) AS max_price_in_category,
       MIN(price) OVER (PARTITION BY category) AS min_price_in_category,
       SUM(CASE WHEN status = 'instock' THEN 1 ELSE 0 END) OVER (PARTITION BY category) AS in_stock_count_in_category
FROM products
```

| title | category | price | max_price_in_category | min_price_in_category | in_stock_count_in_category |
|-------|----------|-------|----------------------|----------------------|----------------------------|
| Jacket | Clothing | 100 | 100 | 20 | 2 |
| Jeans | Clothing | 50 | 100 | 20 | 2 |
| T-Shirt | Clothing | 20 | 100 | 20 | 2 |
| Headphones | Electronics | 150 | 1200 | 150 | 2 |
| Laptop | Electronics | 1200 | 1200 | 150 | 2 |
| Smartphone | Electronics | 800 | 1200 | 150 | 2 |
| Sneakers | Footwear | 70 | 70 | 70 | 1 |
| Blender | Home Appliances | 80 | 200 | 80 | 2 |
| Coffee Maker | Home Appliances | 100 | 200 | 80 | 2 |
| Vacuum Cleaner | Home Appliances | 200 | 200 | 80 | 2 |

### Суммарная стоимость товаров в каждой категории и сумма по всем категориям
``` sql
SELECT IF(GROUPING(category), 'Итого', category) AS category,
       SUM(price) AS total_price
FROM products
GROUP BY category
WITH ROLLUP
```

| category | total_price |
|----------|-------------|
| Clothing | 170 |
| Electronics | 2150 |
| Footwear | 70 |
| Home Appliances | 380 |
| Итого | 2770 |

### Количество товаров в наличии в каждой категории и общее количество товаров в наличии
``` sql
SELECT IF(GROUPING(category), 'Итого', category) AS category,
       SUM(CASE WHEN status = 'instock' THEN 1 ELSE 0 END) AS in_stock_count_in_category
FROM products
GROUP BY category
WITH ROLLUP
```

| category | in_stock_count_in_category |
|----------|----------------------------|
| Clothing | 2 |
| Electronics | 2 |
| Footwear | 1 |
| Home Appliances | 2 |
| Итого | 7 |

### Товары с максимальной и минимальной ценой в каждой категории
``` sql
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
```

| title | category | price |
|-------|----------|-------|
| Jacket | Clothing | 100 |
| T-Shirt | Clothing | 20 |
| Headphones | Electronics | 150 |
| Laptop | Electronics | 1200 |
| Sneakers | Footwear | 70 |
| Blender | Home Appliances | 80 |
| Vacuum Cleaner | Home Appliances | 200 |