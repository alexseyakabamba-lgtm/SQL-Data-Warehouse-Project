/*
===============================================================================
Quality Checks - Silver Layer
===============================================================================
Script Purpose:
    This script performs data quality validations on the Silver layer
    after the ETL loading process. The checks ensure data consistency,
    completeness, accuracy, and standardization before the data is
    promoted to the Gold layer.

    The validations include:
    - NULL or duplicate primary keys.
    - Missing or blank business keys.
    - Leading and trailing whitespace.
    - Standardized categorical values.
    - Invalid or inconsistent dates.
    - Business rule validation.
    - Referential integrity checks.
    - Data consistency between related columns.

Usage Notes:
    - Execute this script after running the Silver layer load procedure.
    - Queries are expected to return either no rows or only the
      documented valid values.
    - Investigate and resolve any unexpected results before loading
      the Gold layer.
===============================================================================
*/


-- ============================================================================
-- Checking 'silver.crm_cust_info'
-- ============================================================================

-- Check for NULLs or Duplicate Primary Keys
-- Expectation: No Results
SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;

-- Check for Missing or Blank Customer Keys
-- Expectation: No Results
SELECT *
FROM silver.crm_cust_info
WHERE cst_key IS NULL
   OR TRIM(cst_key) = '';

-- Check for Leading or Trailing Spaces
-- Expectation: No Results
SELECT
    cst_key,
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_key <> TRIM(cst_key)
   OR cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);

-- Verify Standardized Marital Status Values
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info
ORDER BY cst_marital_status;

-- Verify Standardized Gender Values
SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info
ORDER BY cst_gndr;



-- ============================================================================
-- Checking 'silver.crm_prd_info'
-- ============================================================================

-- Check for NULLs or Duplicate Primary Keys
-- Expectation: No Results
SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;

-- Check for Missing Product Keys
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_key IS NULL
   OR TRIM(prd_key) = '';

-- Check for Leading or Trailing Spaces
-- Expectation: No Results
SELECT
    prd_key,
    prd_nm
FROM silver.crm_prd_info
WHERE prd_key <> TRIM(prd_key)
   OR prd_nm <> TRIM(prd_nm);

-- Check for Invalid Product Cost
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_cost < 0;

-- Verify Product Line Standardization
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info
ORDER BY prd_line;

-- Check for Invalid Product Date Ranges
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;



-- ============================================================================
-- Checking 'silver.crm_sales_details'
-- ============================================================================

-- Check for Invalid Date Order
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check for Invalid Sales Calculations
-- Expectation: No Results
SELECT
    sls_ord_num,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_ord_num;

-- Check for Orphan Customer Records
-- Expectation: No Results
SELECT s.*
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_cust_info c
    ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL;

-- Check for Orphan Product Records
-- Expectation: No Results
SELECT s.*
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;



-- ============================================================================
-- Checking 'silver.erp_cust_az12'
-- ============================================================================

-- Check for Missing Customer IDs
-- Expectation: No Results
SELECT *
FROM silver.erp_cust_az12
WHERE cid IS NULL
   OR TRIM(cid) = '';

-- Identify Invalid Birth Dates
-- Expectation: No results
-- Birth dates should be between 1916-02-10 and today.
SELECT *
FROM silver.erp_cust_az12
WHERE bdate < '1916-02-10'
   OR bdate > GETDATE();

-- Verify Gender Standardization
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12
ORDER BY gen;



-- ============================================================================
-- Checking 'silver.erp_loc_a101'
-- ============================================================================

-- Check for Missing Customer IDs
-- Expectation: No Results
SELECT *
FROM silver.erp_loc_a101
WHERE cid IS NULL
   OR TRIM(cid) = '';

-- Verify Country Standardization
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;



-- ============================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ============================================================================

-- Check for Leading or Trailing Spaces
-- Expectation: No Results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);

-- Verify Maintenance Values
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2
ORDER BY maintenance;
