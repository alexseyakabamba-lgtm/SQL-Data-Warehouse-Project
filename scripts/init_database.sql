/*
==============================================
Create Database and schemas
==============================================

This script creates a new database named DataWarehouse only if it does not already exist, and 
sets up three schemas within it: bronze, silver, and gold.

*/


USE master;

GO


-- Create the 'DataWarehouse' database if it does not exist


IF NOT EXISTS (
    SELECT name 
    FROM sys.databases 
    WHERE name = 'DataWarehouse'
)
BEGIN
    CREATE DATABASE DataWarehouse;
END

GO

USE DataWarehouse

GO 

--Create Schemas


CREATE SCHEMA bronze;

GO

CREATE SCHEMA silver;

GO

CREATE SCHEMA gold;
