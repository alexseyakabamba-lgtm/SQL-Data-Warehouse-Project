# SQL Data Warehouse Project

This portfolio project showcases the design and implementation of a modern SQL Server data warehouse using the Medallion Architecture. It demonstrates an end-to-end ELT pipeline, dimensional data modeling, and the creation of analytics-ready datasets for business intelligence and advanced analytics. It highlights industry best practices in data engineering and analytics. 

The project management steps followed during the solution implementation can be accessed on Notion by clicking below:

[![Project Plan](https://img.shields.io/badge/Project%20Plan-View%20on%20Notion-blue?style=for-the-badge&logo=notion)](https://spotless-brisket-a87.notion.site/Warehouse-Project-Plan-392993c45a2c803bbebdf038d0d6ec05?pvs=143)


## Table of Contents

- [Repository Structure](#repository-structure)
- [Overview](#overview)
- [Project Architecture](#project-architecture)
- [Bronze Layer](#bronze-layer)
- [Silver Layer](#silver-layer)
- [Gold Layer](#gold-layer)
- [Analytical Data Model](#analytical-data-model)
- [Key Features](#key-features)
- [Tools & Concepts Used](#tools-and-concepts-used)

## Repository Structure

The repository is organized into logical directories that separate data sources, documentation, SQL scripts, and data quality tests, making the project easy to navigate and maintain.

```text
SQL-Data-Warehouse-Project
│
├── datasets
│   ├── source_crm
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   │
│   └── source_erp
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
│
├── documents
│   ├── High-Level Architecture.png
│   ├── Data Flow.png
│   ├── Data Integration.png
│   ├── Star Schema.png
│   ├── data_catalog.md
│   └── naming_conventions.md
│
├── scripts
│   ├── init_database.sql
│   │
│   ├── bronze
│   │   ├── ddl_bronze.sql
│   │   └── proc_load_bronze.sql
│   │
│   ├── silver
│   │   ├── ddl_silver.sql
│   │   └── proc_load_silver.sql
│   │
│   └── gold
│       └── ddl_gold.sql
│
├── tests
│   ├── quality_checks_silver.sql
│   └── quality_checks_gold.sql
│
├── LICENSE
└── README.md
```


## Overview

This project demonstrates the design and implementation of a modern **SQL Server Data Warehouse** using the **Medallion Architecture**. It showcases an end-to-end **ELT (Extract, Load, Transform)** pipeline that ingests raw business data from two enterprise source systems ,**Customer Relationship Management (CRM)** and **Enterprise Resource Planning (ERP)**, provided as CSV files.

The project begins by creating a SQL Server database named **DataWarehouse**, which serves as the central repository for all warehouse operations. Data is then progressively refined through the **Bronze**, **Silver**, and **Gold** layers, transforming raw source data into trusted, analytics-ready datasets. Detailed table documentation and the naming conventions adopted throughout this project are available in the documents folder.

Throughout the project, SQL Server is used to implement:

- Data ingestion
- ELT pipeline development
- Data cleansing and standardization
- Data quality validation
- Dimensional modeling
- Business reporting
- Analytical data preparation

The final **Gold layer** provides a business-ready data model optimized for **Business Intelligence (BI)**, **reporting**, **dashboarding**, **advanced analytics**, and **machine learning** applications.

---

## Project Architecture

The project follows the **Medallion Architecture**, a layered data engineering design pattern that progressively improves data quality while maintaining complete traceability from the original source systems.

The data flows through three distinct layers:

- **Bronze Layer** : Stores raw data exactly as received from the source systems.
- **Silver Layer** : Cleanses, validates, standardizes, and enriches the data.
- **Gold Layer** : Models the data into business-friendly dimensions, facts, and reporting views for analytics and decision-making.

The following diagram illustrates the high-level architecture of the project and the flow of data across each layer.

<img width="854" height="559" alt="High Level Architecture" src="https://github.com/user-attachments/assets/12da6e66-c528-4680-a803-b013b187d644" />


---

## Bronze Layer

The **Bronze layer** serves as the raw landing zone of the data warehouse.

Data is loaded from the six source CSV files (three CRM files and three ERP files) using SQL Server's **BULK INSERT** command as part of a **batch-processing ELT pipeline**.

At this stage:

- Data is loaded without modification.
- No cleansing or transformation is performed.
- The original source structure is preserved to maintain complete data lineage and traceability.
- Data quality checks are then performed to verify the completeness, accuracy, and integrity of the data loaded into the Bronze layer.

The Bronze layer acts as the immutable source of truth for the remainder of the warehouse.

---

## Silver Layer

The Silver layer contains high-quality, standardized data prepared for downstream processing. To keep the project focused on current-state analytics, historical versioning (historization) is intentionally excluded from the implementation.

Data from the Bronze layer is transformed through a series of quality improvement processes, including:

- Removing duplicates
- Handling missing or invalid values
- Standardizing formats and naming conventions
- Validating business rules
- Enriching data where required

The transformed data is then loaded into six Silver tables corresponding to the six Bronze tables. Data quality checks are subsequently performed to ensure the Silver layer contains clean, consistent, and reliable data.

This layer significantly improves data quality while preserving relationships with the original source systems.

---

## Gold Layer

The **Gold layer** represents the business presentation layer of the data warehouse.

Unlike the previous layers, the Gold layer does not store raw operational data. Instead, it integrates and models data into a **Star Schema**, making it easier to analyze and consume for reporting and analytics.

The Gold layer includes:

- **Dimension Views**
  - Customer Dimension
  - Product Dimension

- **Fact View**
  - Sales Fact

These objects provide a simplified analytical model that supports:

- Business Intelligence
- Interactive dashboards
- Executive reporting
- Self-service analytics
- Machine learning applications

The following diagram illustrates the relationships between the Silver layer tables. Based on these relationships, data is integrated, consolidated, and transformed into a Star Schema within the Gold layer, providing a business-ready model for reporting, analytics, and machine learning applications.

<img width="691" height="781" alt="Data Integration" src="https://github.com/user-attachments/assets/b814a38f-742c-46a9-bb37-1fa64cadfe95" />




---

## Analytical Data Model

The final analytical model consists of two dimension views and one fact view.

- **dim_customers**
- **dim_products**
- **fact_sales**

The relationships between these objects are illustrated in the following dimensional model.

<img width="781" height="572" alt="Sales Data Mart (Star Schema)" src="https://github.com/user-attachments/assets/e327c878-1141-4f58-ad57-87cf1cbb8de1" />


---

# Key Features

This project demonstrates the implementation of:

- Modern SQL Server Data Warehouse
- Medallion Architecture
- End-to-End ELT Pipeline
- Batch Data Processing
- Bulk Data Loading using BULK INSERT
- Data Cleansing and Standardization
- Data Validation and Quality Checks
- Star Schema Design
- Dimension and Fact Modeling
- Analytical Reporting Views
- Business-Ready Data Preparation

---

## Tools and Concepts Used

- SQL Server
- T-SQL
- BULK INSERT
- Views
- Stored Procedures
- Window Functions
- Common Table Expressions (CTEs)
- Star Schema
- Medallion Architecture


---

The resulting data warehouse provides a scalable and maintainable foundation for business reporting, dashboarding, advanced analytics, and future AI and machine learning workloads.

## About me
Hi, I'm Alex, I have a background in Metallurgical Engineering with a strong passion for Data Engineering, Data Analytics, and Data Science. I enjoy building data solutions, uncovering insights from data, and continuously expanding my technical skills through hands-on projects.

I'm always open to new opportunities where I can learn, contribute, and grow in the data field. Feel free to connect or get in touch with me on Linkedin by clicking here:  

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/alex-seya-261008b8/)
