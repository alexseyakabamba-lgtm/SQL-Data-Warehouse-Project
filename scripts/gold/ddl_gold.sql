/*
===============================================================================
DDL Script: Gold Layer
===============================================================================
Purpose:
    Creates the Gold layer views that expose business-ready data for
    reporting and analytics.

    The Gold layer implements a star schema consisting of dimension
    and fact views built from the cleansed and standardized Silver
    layer.

    The views:
    - Consolidate data from multiple source systems.
    - Apply business-friendly column names.
    - Generate surrogate keys for dimensions.
    - Filter historical records where appropriate.
    - Provide a simplified analytical model for reporting and BI.
Usage:
    The Gold layer serves as the presentation layer of the data
    warehouse and is intended for  dashboards, reporting, and
    analytical workloads.
===============================================================================
*/


-- ============================================================================
-- Create Dimension: gold.dim_customers
-- ============================================================================
-- Combines customer information from the CRM and ERP systems.
-- CRM is treated as the master source for customer attributes,
-- while ERP contributes demographic and geographic information.
-- ============================================================================

CREATE OR ALTER VIEW gold.dim_customers AS

SELECT

    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,     -- Surrogate Key

    ci.cst_id  AS customer_id,      -- Business Keys
    ci.cst_key AS customer_number,
    ci.cst_firstname      AS first_name,    -- Customer Information
    ci.cst_lastname       AS last_name,
    la.cntry              AS country,
    ci.cst_marital_status AS marital_status,
    CASE                                    -- CRM is the master source for gender.
        WHEN ci.cst_gndr <> 'n/a'           -- Fall back to ERP when unavailable.
            THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,
    ca.bdate          AS birthdate,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

GO


-- ============================================================================
-- Create Dimension: gold.dim_products
-- ============================================================================
-- Combines CRM product information with ERP category data.
-- Only the most recent products are included in the dimension.
-- ============================================================================

CREATE OR ALTER VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER
        (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,  -- Surrogate Key

    pn.prd_id  AS product_id,     -- Business Keys
    pn.prd_key AS product_number,

    pn.prd_nm      AS product_name,     -- Product Attributes
    pn.cat_id      AS category_id,
    pc.cat         AS category,
    pc.subcat      AS subcategory,
    pc.maintenance,
    pn.prd_cost    AS cost,
    pn.prd_line    AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;        -- Keep only the most recent products.

GO
