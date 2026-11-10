-- ============================================
-- SUPPLY CHAIN DATA ANALYSIS PROJECT
-- MYSQL DATA VALIDATION, CLEANING AND ANALYSIS
-- ============================================


-- PART 1: DATABASE SETUP

CREATE DATABASE IF NOT EXISTS supply_chain_bi;

USE supply_chain_bi;


-- PART 2: DATABASE VERIFICATION

-- Display all tables

SHOW TABLES;


-- Check total records in each table

SELECT COUNT(*) AS total_orders FROM orders;

SELECT COUNT(*) AS total_order_items FROM order_items;

SELECT COUNT(*) AS total_products FROM products;

SELECT COUNT(*) AS total_customers FROM customers;

SELECT COUNT(*) AS total_suppliers FROM suppliers;

SELECT COUNT(*) AS total_shipments FROM shipments;

SELECT COUNT(*) AS total_inventory_records FROM inventory;


-- Display sample records

SELECT * FROM orders LIMIT 10;

SELECT * FROM order_items LIMIT 10;

SELECT * FROM products LIMIT 10;

SELECT * FROM customers LIMIT 10;

SELECT * FROM suppliers LIMIT 10;

SELECT * FROM shipments LIMIT 10;

SELECT * FROM inventory LIMIT 10;


-- ============================================
-- PART 3: DATA VALIDATION
-- ============================================


-- 1. Check missing values in orders

SELECT *
FROM orders
WHERE order_id IS NULL
OR order_date IS NULL
OR customer_id IS NULL
OR region IS NULL
OR warehouse IS NULL
OR sales_channel IS NULL
OR order_status IS NULL
OR supplier_id IS NULL;


-- 2. Check duplicate order IDs

SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 3. Check missing values in order_items

SELECT *
FROM order_items
WHERE order_item_id IS NULL
OR order_id IS NULL
OR product_id IS NULL
OR quantity IS NULL
OR unit_price IS NULL
OR unit_cost IS NULL
OR discount_pct IS NULL;


-- 4. Check invalid quantities

SELECT *
FROM order_items
WHERE quantity <= 0;


-- 5. Check invalid prices

SELECT *
FROM order_items
WHERE unit_price < 0
OR unit_cost < 0;


-- 6. Check invalid discounts
-- Assumes discount_pct is stored between 0 and 1

SELECT *
FROM order_items
WHERE discount_pct < 0
OR discount_pct > 1;


-- 7. Check duplicate product IDs

SELECT product_id, COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- 8. Check missing customer IDs

SELECT *
FROM customers
WHERE customer_id IS NULL;


-- 9. Check duplicate customer IDs

SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 10. Check invalid supplier ratings

SELECT *
FROM suppliers
WHERE supplier_rating < 1
OR supplier_rating > 5;


-- 11. Check invalid lead time

SELECT *
FROM suppliers
WHERE lead_time_days < 0;


-- 12. Check invalid shipping cost

SELECT *
FROM shipments
WHERE shipping_cost < 0;


-- 13. Check delivery dates

SELECT *
FROM shipments
WHERE actual_delivery_date < promised_delivery_date;


-- 14. Check invalid inventory values

SELECT *
FROM inventory
WHERE stock_on_hand < 0
OR reorder_point < 0;


-- ============================================
-- PART 4: DATA CLEANING
-- ============================================

-- Check unwanted spaces in customer regions

SELECT *
FROM customers
WHERE customer_region <> TRIM(customer_region);


-- Check unwanted spaces in product names

SELECT *
FROM products
WHERE product_name <> TRIM(product_name);


-- Check unwanted spaces in warehouse names

SELECT *
FROM orders
WHERE warehouse <> TRIM(warehouse);


-- Remove unwanted spaces from text columns
-- Run only after reviewing the affected records

UPDATE orders
SET region = TRIM(region),
    warehouse = TRIM(warehouse),
    sales_channel = TRIM(sales_channel),
    order_status = TRIM(order_status);


UPDATE products
SET product_name = TRIM(product_name),
    category = TRIM(category);


UPDATE customers
SET customer_segment = TRIM(customer_segment),
    customer_region = TRIM(customer_region);


UPDATE suppliers
SET supplier_name = TRIM(supplier_name),
    supplier_region = TRIM(supplier_region);


-- ============================================
-- PART 5: BASIC DATA ANALYSIS
-- ============================================


-- 1. Total number of orders

SELECT COUNT(*) AS total_orders
FROM orders;


-- 2. Orders by region

SELECT region, COUNT(*) AS total_orders
FROM orders
GROUP BY region
ORDER BY total_orders DESC;


-- 3. Orders by warehouse

SELECT warehouse, COUNT(*) AS total_orders
FROM orders
GROUP BY warehouse
ORDER BY total_orders DESC;


-- 4. Orders by status

SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 5. Orders by sales channel

SELECT sales_channel, COUNT(*) AS total_orders
FROM orders
GROUP BY sales_channel;


-- 6. Total quantity sold

SELECT SUM(quantity) AS total_quantity_sold
FROM order_items;


-- 7. Total sales

SELECT ROUND(
    SUM(quantity * unit_price * (1 - discount_pct)), 2
) AS total_sales
FROM order_items;


-- 8. Total cost

SELECT ROUND(
    SUM(quantity * unit_cost), 2
) AS total_cost
FROM order_items;


-- 9. Total profit

SELECT ROUND(
    SUM(quantity * unit_price * (1 - discount_pct))
    - SUM(quantity * unit_cost), 2
) AS total_profit
FROM order_items;


-- 10. Sales by product

SELECT
    p.product_name,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2
    ) AS total_sales
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC;


-- 11. Sales by category

SELECT
    p.category,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2
    ) AS total_sales
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;


-- 12. Monthly orders

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


-- 13. Top 10 customers by number of orders

SELECT
    c.customer_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id
ORDER BY total_orders DESC
LIMIT 10;


-- 14. Supplier performance

SELECT
    supplier_name,
    supplier_rating,
    lead_time_days
FROM suppliers
ORDER BY lead_time_days ASC;


-- 15. Delayed shipments

SELECT *
FROM shipments
WHERE actual_delivery_date > promised_delivery_date;


-- 16. Orders by shipping mode

SELECT
    shipping_mode,
    COUNT(*) AS total_shipments
FROM shipments
GROUP BY shipping_mode;


-- 17. Average shipping cost

SELECT ROUND(AVG(shipping_cost), 2) AS average_shipping_cost
FROM shipments;


-- 18. Products requiring restocking

SELECT
    product_id,
    warehouse,
    stock_on_hand,
    reorder_point
FROM inventory
WHERE stock_on_hand < reorder_point;


-- 19. Inventory status

SELECT
    COUNT(*) AS total_inventory_records,
    SUM(CASE
        WHEN stock_on_hand < reorder_point THEN 1
        ELSE 0
    END) AS products_below_reorder_point
FROM inventory;


-- 20. Customer segment analysis

SELECT
    c.customer_segment,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY total_orders DESC;


-- ============================================
-- END OF SUPPLY CHAIN SQL PROJECT
-- ============================================
