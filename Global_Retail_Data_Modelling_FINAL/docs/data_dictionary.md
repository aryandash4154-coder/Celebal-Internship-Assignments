# Global Retail Data Modelling - Enterprise Data Dictionary

This document provides a field-by-field reference dictionary for all schemas and tables in the Global Retail Data Warehouse.

---

## Gold Layer (Analytics Star Schema & SCD Type 2)

### Table: `gold.dim_customers`
Conformed Customer Dimension containing demographic, geographic, lifecycle attributes, and **SCD Type 2** version tracking.

| Field Name | Data Type | Nullable | Constraint | Description |
| :--- | :--- | :--- | :--- | :--- |
| `customer_key` | BIGINT | No | Primary Key | Surrogate integer key generated for Star Schema queries |
| `customer_id` | INT | No | - | Natural numeric customer identifier from CRM system |
| `customer_natural_key` | VARCHAR | No | - | Business key formatted across systems (e.g., `AW00011000`) |
| `first_name` | VARCHAR | Yes | - | Customer first name (whitespace trimmed) |
| `last_name` | VARCHAR | Yes | - | Customer last name (whitespace trimmed) |
| `full_name` | VARCHAR | Yes | - | Concatenated first and last name |
| `marital_status` | VARCHAR | No | - | Marital status: `Single`, `Married`, or `n/a` |
| `gender` | VARCHAR | No | - | Standardized gender: `Male`, `Female`, or `n/a` |
| `birthdate` | DATE | Yes | - | Customer birth date from ERP records |
| `age` | INT | Yes | - | Derived current age in years |
| `age_group` | VARCHAR | No | - | Age bracket: `< 25`, `25 - 34`, `35 - 44`, `45 - 54`, `55+`, `Unknown` |
| `country` | VARCHAR | No | - | Standardized country location from ERP records |
| `customer_since_date` | DATE | Yes | - | Account creation date |
| `effective_start_date` | DATE | No | - | SCD Type 2 effective start date |
| `effective_end_date` | DATE | Yes | - | SCD Type 2 effective end date (NULL if active) |
| `is_current` | TINYINT(1) | No | - | 1 if active current record, 0 if historical version |

---

### Table: `gold.dim_products`
Conformed Product Dimension containing product catalog metadata, category hierarchies, cost metrics, and **SCD Type 2** version tracking.

| Field Name | Data Type | Nullable | Constraint | Description |
| :--- | :--- | :--- | :--- | :--- |
| `product_key` | BIGINT | No | Primary Key | Surrogate integer key for Star Schema joins |
| `product_id` | INT | No | - | Natural product identifier from CRM |
| `product_natural_key` | VARCHAR | No | - | Full product code string (e.g., `BI-RB-BK-R93R-62`) |
| `item_key` | VARCHAR | No | - | Product item key suffix matching sales transaction key |
| `product_name` | VARCHAR | No | - | Full descriptive product title |
| `category_name` | VARCHAR | No | - | High-level product category (`Bikes`, `Accessories`, `Clothing`, `Components`) |
| `subcategory_name` | VARCHAR | No | - | Detailed subcategory (`Mountain Bikes`, `Helmets`, `Road Frames`) |
| `product_line` | VARCHAR | No | - | Product line: `Mountain`, `Road`, `Touring`, `Other Sales`, `n/a` |
| `unit_cost` | DECIMAL(10,2) | No | - | Standard cost per item |
| `is_maintenance_required` | TINYINT(1) | No | - | Flag indicating if product requires routine servicing |
| `effective_start_date` | DATE | Yes | - | SCD Type 2 effective start date |
| `effective_end_date` | DATE | Yes | - | SCD Type 2 effective end date (NULL if active) |
| `is_current` | TINYINT(1) | No | - | 1 if active current record, 0 if historical version |

---

### Table: `gold.dim_date`
Calendar dimension table spanning historical and current order date ranges.

| Field Name | Data Type | Nullable | Constraint | Description |
| :--- | :--- | :--- | :--- | :--- |
| `date_key` | INT | No | Primary Key | Integer date key formatted as YYYYMMDD |
| `full_date` | DATE | No | Unique | ANSI standard calendar date |
| `year` | INT | No | - | 4-digit calendar year |
| `quarter` | INT | No | - | Calendar quarter (1-4) |
| `month_number` | INT | No | - | Month number (1-12) |
| `month_name` | VARCHAR | No | - | Full month name (e.g., `January`) |
| `day_of_month` | INT | No | - | Day of month (1-31) |
| `day_name` | VARCHAR | No | - | Full day name (e.g., `Monday`) |
| `is_weekend` | TINYINT(1) | No | - | 1 if day is Saturday or Sunday, else 0 |

---

### Table: `gold.fact_sales`
Central Fact Table recording transactional sales events and financial measures.

> **Grain**: One row per sales order line/product transaction.

| Field Name | Data Type | Nullable | Constraint | Description |
| :--- | :--- | :--- | :--- | :--- |
| `sales_key` | BIGINT | No | Primary Key | Surrogate primary key for sales transaction line |
| `order_number` | VARCHAR | No | - | Sales Order Number (e.g., `SO43697`) |
| `customer_key` | BIGINT | No | Foreign Key | Link to `gold.dim_customers.customer_key` |
| `product_key` | BIGINT | No | Foreign Key | Link to `gold.dim_products.product_key` |
| `order_date_key` | INT | No | Foreign Key | Link to `gold.dim_date.date_key` |
| `ship_date_key` | INT | Yes | Foreign Key | Link to `gold.dim_date.date_key` |
| `due_date_key` | INT | Yes | Foreign Key | Link to `gold.dim_date.date_key` |
| `quantity` | INT | No | - | Units purchased |
| `unit_price` | DECIMAL(10,2) | No | - | Sale price per unit |
| `sales_amount` | DECIMAL(10,2) | No | - | Total gross sales revenue (`quantity * unit_price`) |
| `unit_cost` | DECIMAL(10,2) | No | - | Unit cost for profit calculation |
| `cost_amount` | DECIMAL(10,2) | No | - | Total cost (`quantity * unit_cost`) |
| `profit_amount` | DECIMAL(10,2) | No | - | Net profit (`sales_amount - cost_amount`) |
| `margin_pct` | DECIMAL(5,2) | No | - | Profit margin percentage |
