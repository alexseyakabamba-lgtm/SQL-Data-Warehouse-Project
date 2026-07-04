/* 
=======================================================================
Stored Procedure: bronze.load_bronze
=======================================================================
Purpose:
	Loads raw CRM and ERP source data into the Bronze layer of the
	data warehouse.

The procedure performs a full reload of each Bronze table by:
	- Truncating existing data from the target tables.
	- Importing the latest source files using BULK INSERT.
	- Recording the load duration for each table.
	- Displaying progress messages throughout the execution.
	- Handling and reporting errors using TRY...CATCH.

Parameters: 
	None, this stored procedure accepts no parameters and 
	returns no value

Usage Example: 
	Exec bronze.load_bronze;

This procedure serves as the data ingestion process for the
Bronze layer, ensuring that raw source data is refreshed and
available for downstream transformation into the Silver layer.
=====================================================================
 */


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME2, @end_time DATETIME2, @batch_start_time DATETIME2, @batch_end_time DATETIME2;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '======================================================';
		PRINT 'Loading Bronze Layer '
		PRINT '======================================================';

		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '------------------------------------------------------';

		-- Loading bronze.crm_cust_info

		SET @start_time = GETDATE();

		PRINT '>>> Truncating Table: bronze.crm_cust_info';

		TRUNCATE TABLE bronze.crm_cust_info

		PRINT '>>> Inserting Data Into: bronze.crm_cust_info';

		BULK INSERT bronze.crm_cust_info
		FROM  'C:\SQL projects datasets\Data warehouse\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table bronze.crm_cust_info: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';

		-- Loading bronze.crm_prd_info

		SET @start_time = GETDATE();

		PRINT '>>> Truncating Table: bronze.crm_prd_info';

		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>>> Inserting Data Into: bronze.crm_prd_info';

		BULK INSERT bronze.crm_prd_info
		FROM  'C:\SQL projects datasets\Data warehouse\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table bronze.crm_prd_info: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);		

		PRINT '--------------------------------------------------------';

		-- Loading bronze.crm_sales_details

		SET @start_time = GETDATE();

		PRINT '>>> Truncating Table: bronze.crm_sales_details';

		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>>> Inserting Data Into: bronze.crm_sales_details';

		BULK INSERT bronze.crm_sales_details
		FROM  'C:\SQL projects datasets\Data warehouse\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT CONCAT(
		'>>> Rows Loaded: ',
		@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table bronze.crm_sales_details: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '------------------------------------------------------';
		PRINT 'Loading ERP Tables'
		PRINT '------------------------------------------------------';

		-- Loading bronze.erp_cust_az12'

		SET @start_time = GETDATE();

		PRINT '>>> Truncating Table: bronze.erp_cust_az12';	

		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>>> Inserting Data Into: bronze.erp_cust_az12';

		BULK INSERT bronze.erp_cust_az12
		FROM  'C:\SQL projects datasets\Data warehouse\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table bronze.erp_cust_az12: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';

		-- Loading bronze.erp_loc_a101

		SET @start_time = GETDATE();

		PRINT '>>> Truncating Table: bronze.erp_loc_a101';	

		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>>> Inserting Data Into: bronze.erp_loc_a101';

		BULK INSERT bronze.erp_loc_a101
		FROM  'C:\SQL projects datasets\Data warehouse\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table bronze.erp_loc_a101: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';

		-- Loading bronze.erp_px_cat_g1v2

		SET @start_time = GETDATE();

		PRINT '>>> Truncating Table: bronze.erp_px_cat_g1v2';	

		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>>> Inserting Data Into: bronze.erp_px_cat_g1v2';

		BULK INSERT bronze.erp_px_cat_g1v2
		FROM  'C:\SQL projects datasets\Data warehouse\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		
		PRINT CONCAT(
			'>>> Rows Loaded: ',
			@@ROWCOUNT
		);

		SET @end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of Table bronze.erp_px_cat_g1v2: ',
			DATEDIFF(SECOND, @start_time, @end_time),
			' seconds'
		);

		PRINT '--------------------------------------------------------';

		SET @batch_end_time = GETDATE();

		PRINT CONCAT(
			'>>> Load Duration of whole bronze layer: ',
			DATEDIFF(SECOND, @batch_start_time, @batch_end_time),
			' seconds'
		);

	END TRY
	BEGIN CATCH
		PRINT '======================================================'
		PRINT 'ERROR OCCURED DURING LOADING OF THE BRONZE LAYER';
		PRINT 'Error Message	: ' + ERROR_MESSAGE();
		PRINT 'Error Number		: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State		: ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT 'Error Line		: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
		PRINT 'Error Procedure	: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
		PRINT '======================================================'
	END CATCH
END

