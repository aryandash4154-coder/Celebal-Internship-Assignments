"""
Configuration Settings for Global Retail Data Modelling Pipeline
Configured for MySQL Data Warehousing & Medallion Architecture.
"""

import os
from pathlib import Path

# Base Directory (Project Root)
BASE_DIR = Path(__file__).resolve().parent.parent

# Data Directories
DATA_DIR = BASE_DIR / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
SOURCE_CRM_DIR = RAW_DATA_DIR / "source_crm"
SOURCE_ERP_DIR = RAW_DATA_DIR / "source_erp"

# MySQL Database Configuration
MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", 3306))
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "global_retail_dw")

# SQLite fallback path for environments without active MySQL service
SQLITE_DB_PATH = DATA_DIR / "warehouse.db"

# SQL Directory Stages (01 to 06)
SQL_DIR = BASE_DIR / "sql"
BRONZE_SQL_DIR = SQL_DIR / "01_bronze"
SILVER_SQL_DIR = SQL_DIR / "02_silver"
GOLD_SQL_DIR = SQL_DIR / "03_gold"
SCD_SQL_DIR = SQL_DIR / "04_scd_type2"
ANALYTICS_SQL_DIR = SQL_DIR / "05_analytics"
TESTING_SQL_DIR = SQL_DIR / "06_testing"

# Output Visualization Directory
VISUALIZATIONS_DIR = BASE_DIR / "visualizations"
VISUALIZATIONS_DIR.mkdir(parents=True, exist_ok=True)
