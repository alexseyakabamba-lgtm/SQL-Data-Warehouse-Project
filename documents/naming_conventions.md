# **Naming Conventions**

This document defines the naming conventions used throughout the data warehouse for schemas, tables, views, columns, stored procedures, and other database objects.

## **Table of Contents**

1. [General Principles](#general-principles)
2. [Table Naming Conventions](#table-naming-conventions)
   - [Bronze Layer](#bronze-layer)
   - [Silver Layer](#silver-layer)
   - [Gold Layer](#gold-layer)
3. [Column Naming Conventions](#column-naming-conventions)
   - [Surrogate Keys](#surrogate-keys)
   - [Technical Columns](#technical-columns)
4. [Stored Procedures](#stored-procedures-naming-conventions)
---

## **General Principles**

- **Naming Convention:** Use **snake_case**, with lowercase letters and underscores (`_`) to separate words.
- **Language:** Use English for all database object names.
- **Meaningful Names:** Choose clear, descriptive names that accurately reflect the purpose of the object.
- **Reserved Keywords:** Avoid using SQL reserved keywords as object names.
- **Consistency:** Apply the same naming conventions consistently across all layers of the data warehouse.

## **Table Naming Conventions**

### **Bronze Layer**

- Bronze tables represent raw source data and should preserve the original structure and naming of the source systems as closely as possible.
- Table names must begin with the source system identifier followed by the original entity name.
- **Naming Pattern:** **`<source_system>_<entity>`**
  - **`<source_system>`**: Identifier of the source system (e.g., `crm`, `erp`).
  - **`<entity>`**: Original table name from the source system, without renaming.
- **Example:** `crm_cust_info` → Customer information extracted directly from the CRM system.

### **Silver Layer**

- Silver tables contain cleansed, standardized, and enriched data while maintaining close alignment with the original source systems.
- Table names must begin with the source system identifier and retain the original entity names to preserve traceability between the Bronze and Silver layers.
- **Naming Pattern:** **`<source_system>_<entity>`**
  - **`<source_system>`**: Identifier of the source system (e.g., `crm`, `erp`).
  - **`<entity>`**: Original table name from the source system.
- **Example:** `crm_cust_info` → Cleansed and standardized customer information from the CRM system.

### **Gold Layer**

- Gold tables are business-ready, analytics-focused objects designed to support reporting, dashboards, and decision-making.
- Table names should use meaningful, business-oriented names rather than source system identifiers, reflecting the entities and measures used by business users.
- **Naming Pattern:** **`<category>_<entity>`**
  - **`<category>`**: Indicates the role of the object, such as `dim` (dimension), `fact` (fact table), or `report` (analytical reporting view).
  - **`<entity>`**: Descriptive business entity represented by the table or view (e.g., `customers`, `products`, `sales`).
- **Examples:**
  - `dim_customers` → Customer dimension containing descriptive customer attributes.
  - `dim_products` → Product dimension containing descriptive product attributes.
  - `fact_sales` → Fact table containing sales transactions and business measures.
  - `report_customers` → Analytical report providing customer-level KPIs and insights.

#### **Glossary of Category Patterns**

| Pattern     | Meaning                           | Example(s)                              |
|-------------|-----------------------------------|-----------------------------------------|
| `dim_`      | Dimension table                  | `dim_customer`, `dim_product`           |
| `fact_`     | Fact table                       | `fact_sales`                            |
| `report_`   | Report table                     | `report_customers`, `report_sales_monthly`   |

## **Column Naming Conventions**

### **Surrogate Keys**

- Surrogate keys serve as the primary keys for dimension tables and must use the suffix `_key`.
- **Naming Pattern:** **`<entity>_key`**
  - **`<entity>`**: The business entity represented by the dimension (e.g., `customer`, `product`).
  - **`_key`**: Suffix indicating that the column is a system-generated surrogate key.
- **Examples:**
  - `customer_key` → Surrogate key for the `dim_customers` dimension.
  - `product_key` → Surrogate key for the `dim_products` dimension.
  
### **Technical Columns**

- Technical columns store system-generated metadata used for auditing, data lineage, and operational tracking within the data warehouse.
- All technical columns must begin with the prefix `dwh_`, followed by a descriptive name that clearly identifies the metadata being stored.
- **Naming Pattern:** **`dwh_<column_name>`**
  - **`dwh`**: Prefix reserved exclusively for data warehouse metadata columns.
  - **`<column_name>`**: Descriptive name indicating the purpose of the metadata field.
- **Examples:**
  - `dwh_create_date` → Timestamp indicating when the record was loaded into the data warehouse.
  - `dwh_update_date` → Timestamp indicating when the record was last updated.
  - `dwh_batch_id` → Identifier of the ETL/ELT batch that loaded the record.
 
## **Stored Procedures Naming Conventions**

- Stored procedures responsible for loading data into the data warehouse must follow a consistent naming convention based on the target layer.
- **Naming Pattern:** **`load_<layer>`**
  - **`load`**: Indicates that the stored procedure performs a data loading operation.
  - **`<layer>`**: Target data warehouse layer being loaded (e.g., `bronze`, `silver`, or `gold`).
- **Examples:**
  - `load_bronze` → Loads raw data from the source systems into the Bronze layer.
  - `load_silver` → Loads cleansed and standardized data into the Silver layer.
  - `load_gold` → Loads business-ready data into the Gold layer.
