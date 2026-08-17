"""
Master Pipeline Orchestrator for Global Retail Data Modelling Project
Executes Bronze (Ingestion) -> Silver (Cleansing) -> Gold (Star Schema) SQL pipelines targeting MySQL Data Warehouse.
"""

import sys
import os
import time
import datetime
import re
import pandas as pd
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from config.settings import (
    MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE,
    SQLITE_DB_PATH, BRONZE_SQL_DIR, SILVER_SQL_DIR, GOLD_SQL_DIR,
    SCD_SQL_DIR, ANALYTICS_SQL_DIR, TESTING_SQL_DIR,
    SOURCE_CRM_DIR, SOURCE_ERP_DIR
)

def _sqlite_str_to_date(val, fmt):
    if not val: return None
    s = str(val).strip()
    if not s or s == '0': return None
    try:
        if fmt == '%Y%m%d' and len(s) == 8:
            return f"{s[:4]}-{s[4:6]}-{s[6:8]}"
        if '/' in s:
            parts = s.split('/')
            if len(parts) == 3: return f"{parts[0]:0>4}-{parts[1]:0>2}-{parts[2]:0>2}"
    except Exception:
        pass
    return s

def _sqlite_date_format(val, fmt):
    if not val: return None
    s = str(val).strip()
    if fmt == '%Y%m%d':
        return s.replace('-', '')[:8]
    if fmt == '%Y-%m':
        return s[:7]
    return s

def _sqlite_date_sub(val, expr):
    try:
        d = datetime.datetime.strptime(str(val)[:10], '%Y-%m-%d').date()
        return str(d - datetime.timedelta(days=1))
    except Exception:
        return val

def _sqlite_timestampdiff(unit, val1, val2):
    try:
        d1 = datetime.datetime.strptime(str(val1)[:10], '%Y-%m-%d').date()
        d2 = datetime.datetime.strptime(str(val2)[:10], '%Y-%m-%d').date()
        return (d2 - d1).days // 365
    except Exception:
        return 0

def _sqlite_date_add(val, expr):
    try:
        d = datetime.datetime.strptime(str(val)[:10], '%Y-%m-%d').date()
        return str(d + datetime.timedelta(days=1))
    except Exception:
        return val

def _sqlite_year(val):
    try: return int(str(val)[:4])
    except Exception: return None

def _sqlite_quarter(val):
    try: return (int(str(val)[5:7]) - 1) // 3 + 1
    except Exception: return None

def _sqlite_month(val):
    try: return int(str(val)[5:7])
    except Exception: return None

def _sqlite_dayofmonth(val):
    try: return int(str(val)[8:10])
    except Exception: return None

def _sqlite_dayofweek(val):
    try:
        d = datetime.datetime.strptime(str(val)[:10], '%Y-%m-%d').date()
        return (d.weekday() + 1) % 7 + 1
    except Exception: return 1

def _sqlite_datediff(val1, val2):
    try:
        d1 = datetime.datetime.strptime(str(val1)[:10], '%Y-%m-%d').date()
        d2 = datetime.datetime.strptime(str(val2)[:10], '%Y-%m-%d').date()
        return (d1 - d2).days
    except Exception:
        return 0

def get_database_connection():
    """Attempts to connect to MySQL database server; falls back to SQLite engine if MySQL is unavailable."""
    try:
        import mysql.connector
        conn = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            autocommit=True
        )
        print(f"  [+] Connected to MySQL Server at {MYSQL_HOST}:{MYSQL_PORT}")
        return conn, "mysql"
    except Exception:
        try:
            import pymysql
            conn = pymysql.connect(
                host=MYSQL_HOST,
                port=MYSQL_PORT,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                database=MYSQL_DATABASE,
                autocommit=True
            )
            print(f"  [+] Connected to MySQL Server (PyMySQL) at {MYSQL_HOST}:{MYSQL_PORT}")
            return conn, "mysql"
        except Exception:
            print(f"  [!] MySQL server connection unavailable on {MYSQL_HOST}:{MYSQL_PORT}.")
            print(f"  [*] Initializing local SQLite database engine at {SQLITE_DB_PATH} for execution fallback...")
            import sqlite3
            SQLITE_DB_PATH.parent.mkdir(parents=True, exist_ok=True)
            conn = sqlite3.connect(str(SQLITE_DB_PATH))
            # Register MySQL compatibility functions in SQLite fallback
            conn.create_function("REGEXP", 2, lambda expr, item: 1 if item and expr in item else 0)
            conn.create_function("STR_TO_DATE", 2, _sqlite_str_to_date)
            conn.create_function("DATE_FORMAT", 2, _sqlite_date_format)
            conn.create_function("DATE_SUB", 2, _sqlite_date_sub)
            conn.create_function("DATE_ADD", 2, _sqlite_date_add)
            conn.create_function("DATEDIFF", 2, _sqlite_datediff)
            conn.create_function("YEAR", 1, _sqlite_year)
            conn.create_function("QUARTER", 1, _sqlite_quarter)
            conn.create_function("MONTH", 1, _sqlite_month)
            conn.create_function("DAYOFMONTH", 1, _sqlite_dayofmonth)
            conn.create_function("DAYOFWEEK", 1, _sqlite_dayofweek)
            conn.create_function("TIMESTAMPDIFF", 3, _sqlite_timestampdiff)
            conn.create_function("CONCAT", -1, lambda *args: "".join(str(a) if a is not None else "" for a in args))
            return conn, "sqlite"

def load_csv_to_bronze(conn, db_type):
    """Loads raw CSV datasets from source_crm and source_erp into Bronze schema tables fast."""
    csv_mappings = {
        "bronze.crm_cust_info": SOURCE_CRM_DIR / "cust_info.csv",
        "bronze.crm_prd_info": SOURCE_CRM_DIR / "prd_info.csv",
        "bronze.crm_sales_details": SOURCE_CRM_DIR / "sales_details.csv",
        "bronze.erp_cust_az12": SOURCE_ERP_DIR / "CUST_AZ12.csv",
        "bronze.erp_loc_a101": SOURCE_ERP_DIR / "LOC_A101.csv",
        "bronze.erp_px_cat_g1v2": SOURCE_ERP_DIR / "PX_CAT_G1V2.csv",
    }
    
    if db_type == "sqlite":
        for full_table_name, csv_path in csv_mappings.items():
            if not csv_path.exists():
                continue
            table_name = full_table_name.replace(".", "_")
            df = pd.read_csv(csv_path, dtype=str).fillna("")
            df.to_sql(table_name, conn, if_exists="replace", index=False)
            print(f"  [+] Ingested {len(df):>6,d} rows into {full_table_name} from {csv_path.name}")
        conn.commit()
    else:
        cursor = conn.cursor()
        for full_table_name, csv_path in csv_mappings.items():
            if not csv_path.exists():
                print(f"  [!] Warning: CSV file not found at {csv_path}")
                continue

            df = pd.read_csv(csv_path, dtype=str).fillna("")
            columns = list(df.columns)
            table_name = full_table_name
            placeholders = ", ".join(["%s"] * len(columns))
            col_names = ", ".join([f"`{c}`" for c in columns])
            
            try:
                cursor.execute(f"DELETE FROM {table_name}")
            except Exception:
                pass

            insert_sql = f"INSERT INTO {table_name} ({col_names}) VALUES ({placeholders})"
            rows = [tuple(x) for x in df.to_numpy()]
            cursor.executemany(insert_sql, rows)
            print(f"  [+] Ingested {len(rows):>6,d} rows into {full_table_name} from {csv_path.name}")
        cursor.close()

def clean_sql_for_engine(sql_content, db_type):
    """Translates MySQL-specific DDL/DML statements for SQLite compatibility if fallback is active."""
    if db_type == "mysql":
        return sql_content
    
    # SQLite compatibility transformations
    sql = sql_content
    sql = sql.replace("CREATE DATABASE IF NOT EXISTS bronze;", "")
    sql = sql.replace("CREATE DATABASE IF NOT EXISTS silver;", "")
    sql = sql.replace("CREATE DATABASE IF NOT EXISTS gold;", "")
    sql = sql.replace("SET SESSION cte_max_recursion_depth = 10000;", "")
    sql = sql.replace("bronze.", "bronze_")
    sql = sql.replace("silver.", "silver_")
    sql = sql.replace("gold.", "gold_")
    sql = sql.replace("SIGNED", "INTEGER")
    sql = sql.replace("AUTO_INCREMENT", "")
    sql = sql.replace("CURRENT_TIMESTAMP", "CURRENT_TIMESTAMP")
    sql = sql.replace("CHAR_LENGTH(", "LENGTH(")
    sql = sql.replace("DATE_ADD(full_date, INTERVAL 1 DAY)", "DATE(full_date, '+1 day')")
    sql = re.sub(r'DATE_SUB\s*\((.*?),\s*INTERVAL\s+1\s+DAY\)', r"DATE(\1, '-1 day')", sql, flags=re.IGNORECASE | re.DOTALL)
    sql = sql.replace("DECIMAL(5, 2)", "NUMERIC")
    sql = sql.replace("DECIMAL(5,2)", "NUMERIC")
    sql = sql.replace("TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE)", "CAST((julianday('now') - julianday(birthdate))/365.25 AS INTEGER)")
    return sql

def execute_sql_file(conn, sql_file, db_type):
    """Reads and executes a single SQL script file."""
    if db_type == "sqlite" and sql_file.name == "03_dim_date.sql":
        dates = pd.date_range('2010-01-01', '2016-12-31')
        df_date = pd.DataFrame({
            'date_key': dates.strftime('%Y%m%d').astype(int),
            'full_date': dates.strftime('%Y-%m-%d'),
            'year': dates.year,
            'quarter': dates.quarter,
            'month_number': dates.month,
            'month_name': dates.strftime('%B'),
            'month_short': dates.strftime('%b'),
            'day_of_month': dates.day,
            'day_of_week': dates.dayofweek + 1,
            'day_name': dates.strftime('%A'),
            'is_weekend': dates.dayofweek.isin([5, 6]).astype(int),
            'fiscal_year': dates.year,
            'fiscal_quarter': 'Q' + dates.quarter.astype(str)
        })
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS gold_dim_date")
        cursor.close()
        df_date.to_sql('gold_dim_date', conn, if_exists='replace', index=False)
        conn.commit()
        return

    raw_sql = sql_file.read_text(encoding="utf-8")
    clean_sql = clean_sql_for_engine(raw_sql, db_type)
    
    # Remove single-line SQL comments before splitting on semicolon
    lines = []
    for line in clean_sql.splitlines():
        if line.strip().startswith("--"):
            continue
        lines.append(line)
    without_comments = "\n".join(lines)

    cursor = conn.cursor()
    statements = [stmt.strip() for stmt in without_comments.split(";") if stmt.strip()]
    for stmt in statements:
        cursor.execute(stmt)

        # MySQL Connector/Python does not allow another statement to be
        # executed while the previous SELECT result is still unread.
        # Analytics SQL files intentionally contain multiple SELECT
        # statements, so consume each result set before continuing.
        if cursor.description is not None:
            cursor.fetchall()

    cursor.close()
    if db_type == "sqlite":
        conn.commit()

def run_sql_files_in_dir(conn, directory, layer_name, db_type):
    """Executes all SQL files in directory sequentially."""
    print(f"\n==========================================")
    print(f"Executing {layer_name.upper()} Layer Transformations ({db_type.upper()})")
    print(f"==========================================")
    
    sql_files = sorted(list(Path(directory).glob("*.sql")))
    if not sql_files:
        print(f"No SQL scripts found in {directory}")
        return

    for sql_file in sql_files:
        start_time = time.time()
        print(f"  [+] Executing: {sql_file.name}...", end="", flush=True)
        try:
            execute_sql_file(conn, sql_file, db_type)
            if "bronze" in layer_name.lower() and sql_file == sql_files[-1]:
                load_csv_to_bronze(conn, db_type)
            elapsed = time.time() - start_time
            print(f" SUCCESS ({elapsed:.2f}s)")
        except Exception as e:
            print(f" FAILED!")
            print(f"     Error in {sql_file.name}: {e}")
            raise e

def print_layer_summary(conn, db_type):
    """Prints table row counts across Bronze, Silver, and Gold layers."""
    print(f"\n==========================================")
    print(f"Global Retail Data Modelling Summary")
    print(f"==========================================")
    
    cursor = conn.cursor()
    tables_by_layer = {
        'BRONZE': ['crm_cust_info', 'crm_prd_info', 'crm_sales_details', 'erp_cust_az12', 'erp_loc_a101', 'erp_px_cat_g1v2'],
        'SILVER': ['crm_cust_info', 'crm_prd_info', 'crm_sales_details', 'erp_cust_az12', 'erp_loc_a101', 'erp_px_cat_g1v2'],
        'GOLD': ['dim_customers', 'dim_products', 'dim_date', 'fact_sales']
    }

    for layer, tables in tables_by_layer.items():
        print(f"\n[{layer} LAYER TABLES]")
        for tbl in tables:
            full_tbl = f"{layer.lower()}.{tbl}" if db_type == "mysql" else f"{layer.lower()}_{tbl}"
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {full_tbl}")
                count = cursor.fetchone()[0]
                print(f"  - {full_tbl:<30}: {count:>8,d} rows")
            except Exception as e:
                print(f"  - {full_tbl:<30}: Error ({e})")
    cursor.close()

def main():
    print("Starting Global Retail Data Modelling Pipeline (MySQL Architecture)...")
    start_pipeline_time = time.time()

    conn, db_type = get_database_connection()
    
    try:
        # Step 1: Execute Bronze Layer DDL & CSV Ingestion (01_bronze)
        run_sql_files_in_dir(conn, BRONZE_SQL_DIR, "01_Bronze", db_type)
        
        # Step 2: Execute Silver Layer Cleansing (02_silver)
        run_sql_files_in_dir(conn, SILVER_SQL_DIR, "02_Silver", db_type)
        
        # Step 3: Execute Base Gold Dimensions (03_gold: dim_date)
        dim_date_file = GOLD_SQL_DIR / "03_dim_date.sql"
        if dim_date_file.exists():
            print(f"\n==========================================")
            print(f"Executing BASE Gold Dimensions ({db_type.upper()})")
            print(f"==========================================")
            print(f"  [+] Executing: {dim_date_file.name}...", end="", flush=True)
            t0 = time.time()
            execute_sql_file(conn, dim_date_file, db_type)
            print(f" SUCCESS ({time.time()-t0:.2f}s)")

        # Step 4: Execute Dedicated SCD Type 2 Dimensions (04_scd_type2: dim_customers, dim_products)
        run_sql_files_in_dir(conn, SCD_SQL_DIR, "04_SCD_Type2_Dimensions", db_type)

        # Step 5: Execute Gold Sales Fact Table (03_gold/04_fact_sales.sql - built AFTER final SCD dimension keys exist)
        fact_file = GOLD_SQL_DIR / "04_fact_sales.sql"
        if fact_file.exists():
            print(f"\n==========================================")
            print(f"Executing GOLD Sales Fact Table ({db_type.upper()})")
            print(f"==========================================")
            print(f"  [+] Executing: {fact_file.name}...", end="", flush=True)
            t0 = time.time()
            execute_sql_file(conn, fact_file, db_type)
            print(f" SUCCESS ({time.time()-t0:.2f}s)")

        # Step 6: Execute Analytical Business Queries (05_analytics)
        run_sql_files_in_dir(conn, ANALYTICS_SQL_DIR, "05_Analytics", db_type)

        # Step 7: Execute SQL Data Quality & Integrity Validation (06_testing)
        run_sql_files_in_dir(conn, TESTING_SQL_DIR, "06_Testing", db_type)
        
        # Summary Report
        print_layer_summary(conn, db_type)
        
        total_time = time.time() - start_pipeline_time
        print(f"\n[SUCCESS] Global Retail Data Modelling Pipeline executed successfully in {total_time:.2f} seconds.")
        
    except Exception as e:
        print(f"\n[ERROR] Pipeline execution terminated with errors: {e}")
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
