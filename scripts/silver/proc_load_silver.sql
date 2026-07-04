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

		INSERT INTO silver.crm_cust_info(
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
			TRIM(cst_firstname)		AS cst_first_name,
			TRIM(cst_lastname)		AS cst_last_name,
			CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S'	THEN 'SINGLE'
					WHEN UPPER(TRIM(cst_marital_status)) = 'M'	THEN 'MARRIED'	
					ELSE 'n/a'
			END	AS cst_marital_status,			-- Normalise/standadirze marital status to readable format
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
					WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'	
					ELSE 'n/a'
			END	AS cst_gndr,		-- Normalise/standadirze gender to readable format
			cst_create_date
		FROM( 
			SELECT
					*,
					ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
				FROM bronze.crm_cust_info
				WHERE cst_id IS NOT NULL
			) t 
			WHERE flag_last = 1				-- Handle duplicates by selecting the most recent record



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

		-- Loading silver.crm_prd_info

		SET @start_time = GETDATE();

		PRINT '>>> Truncating table: silver.crm_prd_info';
 
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>>> Inserting Data Into: silver.crm_prd_info';

		INSERT INTO silver.crm_prd_info(
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
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, --Extract category ID
			SUBSTRING(prd_key, 7, LEN(prd_key))  AS prd_key,	--Extract product key
			prd_nm,
			ISNULL(prd_cost,0)	AS prd_cost,
			CASE UPPER(TRIM(prd_line)) 
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE	'n/a'
			END AS prd_line,		--Map product line codes to descriptive values
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1	
			AS prd_end_dt	--Enriches the data by calculating the end date as one day before the next start date
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
			CASE WHEN sls_order_dt = 0 OR LEN (sls_order_dt) != 8 THEN NULL
					ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END	 AS sls_order_dt,
			CASE WHEN sls_ship_dt = 0 OR LEN (sls_ship_dt) != 8 THEN NULL
					ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END	 AS sls_ship_dt,
			CASE WHEN sls_due_dt = 0 OR LEN (sls_due_dt) != 8 THEN NULL
					ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END	 AS sls_due_dt,
			CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
					THEN sls_quantity * ABS (sls_price)
					ELSE sls_sales
			END	 AS sls_sales, -- Recalculate sales if original value is missing or incorrect
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <= 0	
					THEN sls_sales / NULLIF(sls_quantity,0)
					ELSE sls_price	-- Derive price f original value is invalid 
			END	 AS sls_price
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

		INSERT INTO silver.erp_cust_az12
			(cid,bdate,gen)

		SELECT
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING (cid, 4, LEN(cid)) --Remove 'NAS' prefix if present
			ELSE cid
		END AS cid,
		CASE WHEN bdate > GETDATE() THEN NULL	
			ELSE bdate
		END	AS bdate,		--Set future birthdays to NULL
		CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M','MALE')	 THEN 'Male'
				ELSE 'n/a'
		END AS gen		--Standadirze gen values and handle unknown cases
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

		INSERT INTO silver.erp_loc_a101
			(cid,cntry)

		SELECT
			REPLACE(cid,'-','') cid,
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
					WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
					WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
					ELSE TRIM(cntry)
			END AS cntry		-- Normalize and handle missing or blank country codes
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

		INSERT INTO silver.erp_px_cat_g1v2
			(id,cat,subcat,maintenance)

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
		PRINT '======================================================'
		PRINT '======================================================'
		PRINT 'ERROR OCCURED DURING LOADING OF THE SILVER LAYER';
		PRINT 'Error Message	: ' + ERROR_MESSAGE();
		PRINT 'Error Number		: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State		: ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT 'Error Line		: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
		PRINT 'Error Procedure	: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
		PRINT '======================================================'
		PRINT '======================================================'
	END CATCH
END

