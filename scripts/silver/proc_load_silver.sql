/* ============================================================
   Stored Procedure: silver.load_silver
   ============================================================
   Purpose:
   Loads cleansed and transformed data from the Bronze layer into
   the Silver layer of the data warehouse.

   The procedure performs a full refresh of each Silver table by:
   - Truncating existing data from the target tables.
   - Applying data cleansing and validation rules.
   - Standardizing data formats and business values.
   - Handling duplicates and invalid records.
   - Enriching data through calculated and derived columns.
   - Recording the load duration for each table.
   - Displaying progress messages throughout the execution.
   - Handling and reporting errors using TRY...CATCH.

   Parameters:
      None. This stored procedure accepts no parameters and
      returns no value.

   Usage:
      EXEC silver.load_silver;

   This procedure serves as the transformation stage of the ETL
   pipeline, converting raw Bronze layer data into cleansed,
   standardized, and business-ready datasets for loading into the
   Gold layer.
   ============================================================ */


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN 
	BEGIN TRY
		DECLARE @start_time DATETIME2, @end_time DATETIME2, @batch_start_time DATETIME2, @batch_end_time DATETIME2;
		
		SET @batch_start_time = GETDATE();

		PRINT '======================================================';
		PRINT 'Loading Silver Layer '
		PRINT '======================================================';

		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '------------------------------------------------------';
        
        -- Loading silver.crm_cust_info

		SET @start_time = GETDATE();
	
		PRINT '>>> Truncating table: silver.crm_cust_info';

		TRUNCATE TABLE silver.crm_cust_info;

		PRINT '>>> Inserting Data Into: silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info (
            cst_id,
	        cst_key,
	        cst_firstname,
	        cst_lastname,
	        cst_marital_status,
	        cst_gndr,
	        cst_create_date
         )
 
        SELECT 
            cst_id,                                   
            cst_key,    
			
            -- remove leading/trailing spaces
            TRIM(cst_firstname) AS cst_first_name,     
            TRIM(cst_lastname)  AS cst_last_name,      
			
			-- normalize marital status to readable format
            CASE                                      
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'n/a'
            END AS cst_marital_status,
			
			-- normalize gender
            CASE                                      
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date
            	
			-- Deduplicate customers by keeping the most recent record per cst_id
        FROM (SELECT       
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id                -- group rows by customer ID
                    ORDER BY cst_create_date DESC      -- rank newest record first
                ) AS rn
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL  ) t
        WHERE rn = 1;                                 -- keep only the latest record per customer

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table silver.crm_cust_info: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);
	
		PRINT '--------------------------------------------------------';

        -- Loading silver.crm_prd_info;

		SET @start_time = GETDATE();

		PRINT '>>> Truncating table: silver.crm_prd_info';
 
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>>> Inserting Data Into: silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )

        SELECT 
            prd_id, 
			
            -- Extract the category ID: take first 5 chars of prd_key, replace '-' with '_'
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,  

            -- Extract the product key: everything after position 7
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,       

            TRIM(prd_nm) AS prd_nm,                               

            COALESCE(prd_cost, 0) AS prd_cost,                    

            -- Map product line codes to descriptive values
            CASE UPPER(TRIM(prd_line)) 
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,                                      

            -- Cast start date to DATE to remove time component
            CAST(prd_start_dt AS DATE) AS prd_start_dt,           

            -- Calculate end date: one day before the next start date
            DATEADD(DAY, -1, 
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key 
                    ORDER BY prd_start_dt
                )
            ) AS prd_end_dt                                       
        FROM bronze.crm_prd_info;

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table silver.crm_prd_info: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);		

		PRINT '--------------------------------------------------------';

        -- Loading silver.crm_sales_details

		SET @start_time = GETDATE();

		PRINT '>>> Truncating table: silver.crm_sales_details';

		TRUNCATE TABLE silver.crm_sales_details; 

		PRINT '>>> Inserting Data Into: silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )

        SELECT
            sls_ord_num,                                
            sls_prd_key,                              
            sls_cust_id,                              

            -- Clean order date: ensure valid 8-digit value, else NULL
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE TRY_CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE) 
            END AS sls_order_dt,

            -- Clean ship date: same validation as order date
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE TRY_CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE) 
            END AS sls_ship_dt,

            -- Clean due date: same validation as above
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE TRY_CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE) 
            END AS sls_due_dt,

            -- Normalize sales: recalc if NULL, <=0, or inconsistent with quantity * price
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,                               

            -- Normalize price: derive from sales/quantity if missing or invalid
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0 
                    THEN sls_sales / NULLIF(sls_quantity, 0)   
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table silver.crm_sales_details: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

        PRINT '------------------------------------------------------';
        PRINT 'Loading ERP Tables'
        PRINT '------------------------------------------------------';

        -- Loading silver.erp_cust_az12

		SET @start_time = GETDATE();

		PRINT '>>> Truncating table: silver.erp_cust_az12';

		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT '>>> Inserting Data Into: silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )

        SELECT 
            -- Normalize customer ID: if it starts with 'NAS', strip the prefix (first 3 chars) and keep the rest
            CASE 
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
                ELSE cid 
            END AS cid,

            -- If the birthday is in the future, set it to NULL
            CASE 
                WHEN bdate > GETDATE() THEN NULL 
                ELSE bdate 
            END AS bdate,

            -- Standardize gender values
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M','MALE')   THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table silver.erp_cust_az12: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';
        
        --Loading silver.erp_loc_a101

        		SET @start_time = GETDATE();

		PRINT '>>> Truncating table: silver.erp_loc_a101';

		TRUNCATE TABLE silver.erp_loc_a101;

		PRINT '>>> Inserting Data Into: silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry   
        )

        SELECT 
            -- Normalize customer ID: remove all dashes from cid for consistency
            REPLACE(cid, '-', '') AS cid,

            -- Normalize country values
            CASE 
                WHEN TRIM(cntry) IN ('United States', 'US', 'USA')  THEN 'United States'
                WHEN TRIM(cntry) IN ('DE', 'Germany')               THEN 'Germany'
                WHEN TRIM(cntry) = '' OR cntry IS NULL              THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;


		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table silver.erp_loc_a101: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';

        -- Loading silver.erp_px_cat_g1v2

		SET @start_time = GETDATE();

		PRINT '>>> Truncating table: silver.erp_px_cat_g1v2';

		TRUNCATE TABLE silver.erp_px_cat_g1v2;

		PRINT '>>> Inserting Data Into: silver.erp_px_cat_g1v2'

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )

        SELECT 
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table silver.erp_px_cat_g1v2: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';

		SET @batch_end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of whole silver batch: ',
			DATEDIFF(SECOND, @batch_start_time, @batch_end_time),
			' seconds'
			);

	END TRY
	BEGIN CATCH
		PRINT '============================================================'
		PRINT '============================================================'
		PRINT 'ERROR OCCURED DURING LOADING OF THE SILVER LAYER';
		PRINT 'Error Message	: ' + ERROR_MESSAGE();
		PRINT 'Error Number		: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State		: ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT 'Error Line		: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
		PRINT 'Error Procedure	: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
		PRINT '==========================================================='
		PRINT '==========================================================='
	END CATCH
END;

