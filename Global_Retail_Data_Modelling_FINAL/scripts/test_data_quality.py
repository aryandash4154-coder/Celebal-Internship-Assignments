"""
Data Quality & Integrity Unit Test Suite for Global Retail Data Modelling Pipeline
Asserts schema validity, surrogate key uniqueness, SCD Type 2 integrity,
referential integrity, and categorical standardization.
"""

import pytest
import sqlite3
import mysql.connector
import pymysql
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parent.parent))
from config.settings import MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, SQLITE_DB_PATH

@pytest.fixture(scope="module")
def db_con():
    """Fixture providing database connection (MySQL or SQLite fallback)."""
    conn = None
    db_type = None
    try:
        conn = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE
        )
        db_type = "mysql"
    except Exception:
        try:
            conn = pymysql.connect(
                host=MYSQL_HOST,
                port=MYSQL_PORT,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                database=MYSQL_DATABASE
            )
            db_type = "mysql"
        except Exception:
            if not SQLITE_DB_PATH.exists():
                pytest.fail(f"Database not found at {SQLITE_DB_PATH}. Run scripts/run_pipeline.py first.")
            conn = sqlite3.connect(str(SQLITE_DB_PATH))
            db_type = "sqlite"

    yield conn, db_type
    conn.close()

def query_one(db_con, sql):
    conn, db_type = db_con
    if db_type == "sqlite":
        sql = sql.replace("gold.", "gold_")
    cursor = conn.cursor()
    cursor.execute(sql)
    res = cursor.fetchone()
    cursor.close()
    return res

def test_dim_customers_uniqueness(db_con):
    """Assert customer_key is unique in dim_customers."""
    res = query_one(db_con, """
        SELECT COUNT(customer_key) - COUNT(DISTINCT customer_key) AS key_dups
        FROM gold.dim_customers
    """)
    assert res[0] == 0, "Duplicate customer_key found in gold.dim_customers"

def test_dim_customers_scd2_columns(db_con):
    """Assert dim_customers contains SCD Type 2 fields: effective_start_date, effective_end_date, is_current."""
    res = query_one(db_con, """
        SELECT COUNT(*) 
        FROM gold.dim_customers 
        WHERE effective_start_date IS NULL OR is_current NOT IN (0, 1)
    """)
    assert res[0] == 0, "Null effective_start_date or invalid is_current flag found in dim_customers"

def test_dim_products_uniqueness(db_con):
    """Assert product_key is unique in dim_products."""
    res = query_one(db_con, """
        SELECT COUNT(product_key) - COUNT(DISTINCT product_key) AS key_dups
        FROM gold.dim_products
    """)
    assert res[0] == 0, "Duplicate product_key found in gold.dim_products"

def test_dim_date_uniqueness(db_con):
    """Assert date_key and full_date are unique in dim_date."""
    res = query_one(db_con, """
        SELECT COUNT(date_key) - COUNT(DISTINCT date_key) AS key_dups,
               COUNT(full_date) - COUNT(DISTINCT full_date) AS date_dups
        FROM gold.dim_date
    """)
    assert res[0] == 0, "Duplicate date_key found in gold.dim_date"
    assert res[1] == 0, "Duplicate full_date found in gold.dim_date"

def test_fact_sales_uniqueness(db_con):
    """Assert sales_key is unique in fact_sales."""
    res = query_one(db_con, """
        SELECT COUNT(sales_key) - COUNT(DISTINCT sales_key) AS key_dups
        FROM gold.fact_sales
    """)
    assert res[0] == 0, "Duplicate sales_key found in gold.fact_sales"

def test_fact_sales_referential_integrity(db_con):
    """Assert foreign keys in fact_sales link cleanly to dimension tables."""
    orphan_cust = query_one(db_con, """
        SELECT COUNT(*) FROM gold.fact_sales f
        LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
        WHERE c.customer_key IS NULL
    """)[0]
    
    orphan_prd = query_one(db_con, """
        SELECT COUNT(*) FROM gold.fact_sales f
        LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
        WHERE p.product_key IS NULL
    """)[0]

    assert orphan_cust == 0, f"Found {orphan_cust} orphan customer keys in fact_sales"
    assert orphan_prd == 0, f"Found {orphan_prd} orphan product keys in fact_sales"

def test_fact_sales_non_negative_measures(db_con):
    """Assert sales measures are non-negative and mathematically sound."""
    invalid_rows = query_one(db_con, """
        SELECT COUNT(*) 
        FROM gold.fact_sales 
        WHERE sales_amount < 0 OR quantity <= 0 OR unit_price < 0
    """)[0]
    assert invalid_rows == 0, f"Found {invalid_rows} sales records with invalid/negative amounts"

def test_categorical_standardization(db_con):
    """Assert gender and marital_status adhere strictly to standardized domains."""
    invalid_gender = query_one(db_con, """
        SELECT COUNT(*) 
        FROM gold.dim_customers 
        WHERE gender NOT IN ('Male', 'Female', 'n/a')
    """)[0]
    
    invalid_marital = query_one(db_con, """
        SELECT COUNT(*) 
        FROM gold.dim_customers 
        WHERE marital_status NOT IN ('Single', 'Married', 'n/a')
    """)[0]

    assert invalid_gender == 0, f"Found {invalid_gender} unstandardized gender values"
    assert invalid_marital == 0, f"Found {invalid_marital} unstandardized marital status values"
