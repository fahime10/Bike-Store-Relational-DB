USE BikeStoreDB;

-- Initial Data Exploration

SELECT * FROM brands;

SELECT * FROM categories;

SELECT TOP 20 * FROM customers;

SELECT TOP 20 * FROM order_items;

-- Order status map:
-- 1: Pending, 2: Processing, 3: Rejected, 4: Completed
SELECT TOP 20 * FROM orders;

SELECT TOP 20 * FROM products;

SELECT * FROM staffs;

SELECT TOP 20 * FROM stocks;

SELECT * FROM stores;

--------------------------------

-- Duplicate handling

-- Customers table
SELECT COUNT(*) AS Total_Customers, COUNT (DISTINCT email) AS Distinct_Emails 
FROM customers;

-- Identify if there are duplicated IDs
SELECT customer_id, COUNT(*) AS duplicate_ids
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT *
FROM customers
WHERE customer_id = 1 OR customer_id = 2 OR
	  customer_id = 3 OR customer_id = 4 OR
	  customer_id = 5;
-- They are exact duplicates with no missing names or emails

WITH CTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
	FROM customers
)
DELETE FROM CTE WHERE rn > 1;
-- Customer duplicates removed

-- Identify if there are nulls or invalid data
SELECT * FROM customers
WHERE first_name IS NULL
	OR last_name IS NULL
	OR email NOT LIKE '%@%.%'
	OR LEN(CAST(zip_code AS VARCHAR)) > 5;

DELETE FROM customers
WHERE first_name IS NULL
	OR last_name IS NULL
	OR email NOT LIKE '%@%.%'
	OR LEN(CAST(zip_code as VARCHAR)) > 5;
-- Nulls and invalid data removed


-- Orders table
-- Identify any date outliers and date nulls
SELECT * FROM orders
WHERE order_date IS NULL
	OR order_date < '2010-01-01'
	OR order_date > GETDATE();

DELETE FROM orders
WHERE order_date IS NULL
	OR order_date < '2010-01-01'
	OR order_date > GETDATE();
-- Date outliers removed

-- Identify any duplicates
SELECT order_id, COUNT(*) AS duplicate_ids
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

WITH CTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id) AS rn
	FROM orders
)
DELETE FROM CTE WHERE rn > 1;
-- Duplicates removed


-- Products table
SELECT product_name, brand_id, category_id, model_year, COUNT(*) AS Duplicated_Row
FROM products
GROUP BY product_name, brand_id, category_id, model_year
HAVING COUNT(*) > 1;

WITH CTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY product_id) AS rn
	FROM products
)
DELETE FROM CTE WHERE rn > 1;
-- Removed duplicates

-- Identify any price outliers
WITH ProductStats AS (
	SELECT product_id, product_name, list_price,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY list_price) OVER () AS Q1,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY list_price) OVER () AS Q3
	FROM products
),
OutlierBounds AS (
	SELECT DISTINCT 
		Q1,
		Q3,
		(Q3 - Q1) AS IQR,
		(Q1 - 1.5 * (Q3 - Q1)) AS LowerBound,
		(Q3 + 1.5 * (Q3 - Q1)) AS UpperBound
	FROM ProductStats
)
SELECT p.*, b.LowerBound, b.UpperBound
FROM products p
CROSS JOIN OutlierBounds b
WHERE p.list_price < b.LowerBound OR
	  p.list_price > b.UpperBound;
-- Identified one outlier that is not reasonable, other outliers are justifiable
-- The query also sets the lower bound very low and so there may be other 
-- outliers where list price cannot zero or negative

SELECT * FROM products
WHERE list_price <= 0 OR
      list_price > 12000;

DELETE FROM products
WHERE list_price IS NULL OR
	  list_price <= 0 OR
	  list_price > 12000;


SELECT * FROM products
WHERE product_name IS NULL;

DELETE FROM products
WHERE product_name IS NULL;

-- Staff table
-- Identify any duplicates and outliers (phone length)
SELECT * FROM staffs
WHERE staff_id IN (SELECT staff_id FROM staffs GROUP BY staff_id HAVING COUNT(*) > 1) OR
	email NOT LIKE '%@%.%' OR
	LEN(phone) > 20;
	
WITH StaffCTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY staff_id) AS rn
	FROM staffs
)
DELETE FROM StaffCTE WHERE rn > 1;
-- Removed duplicates

DELETE FROM staffs
WHERE email NOT LIKE '%@%.%' OR
	LEN(phone) > 20;
-- Removed bad entry


-- Stocks table
-- Identify duplicates and out of range quantities
SELECT store_id, product_id, COUNT(*) AS occurrence_count
FROM stocks
GROUP BY store_id, product_id
HAVING COUNT(*) > 1;

SELECT * FROM stocks
WHERE quantity < 0;

WITH StockCleanCTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY store_id, product_id ORDER BY (SELECT NULL)
	) AS row_num
FROM stocks
)
DELETE FROM StockCleanCTE
WHERE row_num > 1 OR
	quantity < 0;


-- Stores table
-- Identify duplicates and entry errors
SELECT * FROM stores 
WHERE LEN(CAST(zip_code AS VARCHAR)) < 5 OR
	LEN(store_name) > 100;

DELETE FROM stores
WHERE LEN(CAST(zip_code AS VARCHAR)) < 5 OR
	LEN(store_name) > 100;

SELECT store_name, phone, email, street, city, state, zip_code, COUNT(*) AS duplicated_records 
FROM stores
GROUP BY store_name, phone, email, street, city, state, zip_code
HAVING COUNT(*) > 1;

WITH StoreCTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY store_id) AS rn
	FROM stores
)
DELETE FROM StoreCTE WHERE rn > 1;