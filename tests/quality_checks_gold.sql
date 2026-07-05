/*
===============================================================================
Quality Checks - Gold Layer
===============================================================================
Purpose:
    This script validates the integrity, consistency, and completeness
    of the Gold layer after the dimension and fact views have been
    created.

    The validations include:
    - Surrogate key uniqueness.
    - Business key uniqueness.
    - Referential integrity between facts and dimensions.
    - Data completeness.
    - Valid business measures.
   

Usage Notes:
    - Execute this script after creating or refreshing the Gold layer.
    - Queries are expected to return either no rows or only the
      documented valid values.
    - Investigate and resolve any unexpected results before exposing
      the Gold layer to reporting or analytical applications.
===============================================================================
*/


-- ============================================================================
-- Checking 'gold.dim_customers'
-- ============================================================================

-- Check for Duplicate Surrogate Keys
-- Expectation: No Results
SELECT
    customer_key,
    COUNT(*) AS record_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- Check for Duplicate Business Keys
-- Expectation: No Results
SELECT
    customer_id,
    COUNT(*) AS record_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check for Missing Customer IDs
-- Expectation: No Results
SELECT *
FROM gold.dim_customers
WHERE customer_id IS NULL;


-- Verify Gender Values
-- Expectation:
-- Female
-- Male
-- n/a
SELECT DISTINCT
    gender
FROM gold.dim_customers
ORDER BY gender;


-- ============================================================================
-- Checking 'gold.dim_products'
-- ============================================================================

-- Check for Duplicate Surrogate Keys
-- Expectation: No Results
SELECT
    product_key,
    COUNT(*) AS record_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- Check for Duplicate Business Keys
-- Expectation: No Results
SELECT
    product_id,
    COUNT(*) AS record_count
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Check for Missing Product IDs
-- Expectation: No Results
SELECT *
FROM gold.dim_products
WHERE product_id IS NULL;


-- Verify Product Categories
SELECT DISTINCT
    category
FROM gold.dim_products
ORDER BY category;


-- Verify Product Lines
SELECT DISTINCT
    product_line
FROM gold.dim_products
ORDER BY product_line;


-- ============================================================================
-- Checking 'gold.fact_sales'
-- ============================================================================

-- Check Referential Integrity
-- Expectation: No Results
SELECT
    f.*
FROM gold.fact_sales f

LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key

LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key

WHERE c.customer_key IS NULL
   OR p.product_key IS NULL;


-- Check for Missing Dimension Keys
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL
   OR product_key IS NULL;


-- Check for Missing Order Dates
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE order_date IS NULL;


-- Check for Invalid Measures
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE sales_amount <= 0
   OR quantity <= 0
   OR price <= 0
   OR sales_amount IS NULL
   OR quantity IS NULL
   OR price IS NULL;


-- Check Sales Calculation
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE sales_amount <> quantity * price;


-- Check for Duplicate Sales Records
-- Expectation:
-- Depends on business rules.
-- If each order number represents a single transaction,
-- this query should return no rows.
SELECT
    order_number,
    COUNT(*) AS record_count
FROM gold.fact_sales
GROUP BY order_number
HAVING COUNT(*) > 1;
