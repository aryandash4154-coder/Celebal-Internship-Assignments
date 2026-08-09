# E-Commerce Order Analytics System

A comprehensive end-to-end data processing, analytics, and reporting pipeline built with **Python, Pandas, MySQL 8.0+, and Jupyter Notebook**.

> **Database:** MySQL only. SQLite is not used anywhere in the project.

## Features

1. **Synthetic Data Generation (`src/generator.py`)**
   - Generates realistic `customers.csv`, `products.csv`, `orders.csv`, and `order_items.csv`.
   - Injects realistic data-quality anomalies:
     - Missing customer IDs
     - Negative quantities representing returns
     - Mixed date formats
     - Inconsistent product-name formatting
     - Invalid customer email formats

2. **Data Cleaning & Quality Assurance (`src/cleaner.py`)
   - Standardizes order dates to `YYYY-MM-DD HH:MM:SS`.
   - Trims whitespace and applies Title Case to product names.
   - Validates customer emails with regular expressions.
   - Detects orphan order items and records them in `cleaning_report.json`.

3. **MySQL 8.0+ Database Architecture (`src/database.py`, `src/sql_analytics.py`, `queries/*.sql`)
   - Creates the `ecommerce_analytics` MySQL database automatically when the configured MySQL user has permission.
   - Uses InnoDB tables with primary keys, foreign keys, and useful indexes.
   - Loads cleaned CSV data into MySQL using bulk `executemany()` inserts.
   - Executes 16 advanced MySQL analytical queries covering:
     - Revenue aggregations and ranking
     - Window functions (`DENSE_RANK`, `LAG`, `NTILE`, `FIRST_VALUE`, `LAST_VALUE`)
     - Multi-level CTE customer tiering
     - Year-over-Year revenue comparison
     - Pareto 80/20 distribution
     - Cohort retention analysis
     - Frequently bought-together product pairs

4. **CLI Summary Reporting Tool (`src/cli.py`)
   - Runs directly against MySQL.
   - Reports Revenue, Orders, Unique Customers, Top 3 Products, and period-over-period growth.

5. **Edge Case Verification Suite (`tests/test_edge_cases.py`)
   - Automated tests for orphan records, excessive discounts, zero quantities, and future order dates.

6. **Interactive Jupyter Notebook (`ecommerce_analytics.ipynb`)
   - Uses the same MySQL database and analytical query layer.
   - Includes Matplotlib-based visualizations.

---

## MySQL Setup

Install MySQL Server 8.0+ and make sure the MySQL service is running.

Set the following environment variables if your MySQL credentials are not the defaults:

### Windows PowerShell

```powershell
$env:MYSQL_HOST="localhost"
$env:MYSQL_PORT="3306"
$env:MYSQL_USER="root"
$env:MYSQL_PASSWORD="your_mysql_password"
$env:MYSQL_DATABASE="ecommerce_analytics"
```

If your local MySQL `root` account has no password, you can leave `MYSQL_PASSWORD` empty.

## Installation

```bash
pip install -r requirements.txt
```

## Run the End-to-End Pipeline

```bash
python main.py
```

The pipeline performs:

```text
1. Generate raw CSV data
2. Clean and validate data
3. Create MySQL schema
4. Load cleaned data into MySQL
5. Execute 16 analytical SQL queries
6. Generate the MySQL-backed CLI report
7. Run edge-case tests
```

## Interactive CLI Report

```bash
python src/cli.py --interactive
```

## Run Tests

```bash
pytest tests/test_edge_cases.py
```

## Jupyter Notebook

```bash
jupyter notebook ecommerce_analytics.ipynb
```

Then run the notebook cells. The notebook connects to the same MySQL database used by the Python pipeline.

## Database Schema

```text
customers
   │
   └──< orders
          │
          └──< order_items >── products
```

### Tables

- `customers(customer_id PK, customer_name, email, registration_date, customer_type)`
- `products(product_id PK, product_name, category, subcategory, cost_price)`
- `orders(order_id PK, customer_id FK, order_date, status, region_code)`
- `order_items(item_id PK, order_id FK, product_id FK, quantity, unit_price, discount_percent)`

## Technologies

- Python 3
- Pandas
- MySQL 8.0+
- PyMySQL
- MySQL Connector/Python
- SQL / Advanced SQL
- Matplotlib
- Jupyter Notebook
- Pytest

## Key Data Engineering Concepts Demonstrated

- Data generation
- Data cleaning and standardization
- Data quality validation
- Referential integrity
- Relational database design
- Primary and foreign keys
- Indexing
- Bulk data loading
- CTEs
- Window functions
- Cohort analysis
- Pareto analysis
- SQL analytics
- Automated testing
- CLI reporting
