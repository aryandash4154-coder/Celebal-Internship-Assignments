import os
import sys
from src.generator import generate_datasets
from src.cleaner import run_data_cleaning_pipeline
from src.database import DatabaseManager
from src.sql_analytics import SQLAnalyticsRunner
from src.cli import generate_cli_report
from tests.test_edge_cases import (
    test_orphan_order_items,
    test_excessive_discount_percent,
    test_zero_quantity_items,
    test_future_order_date
)

def run_pipeline():
    print("Starting E-Commerce Analytics Pipeline\n")
    
    # 1. Generate data
    print("1. Generating sample raw CSV datasets...")
    generate_datasets(output_dir="data/raw", seed=42)
    print("Done.\n")
    
    # 2. Clean data
    print("2. Cleaning raw data and validating integrity...")
    cleaning_report = run_data_cleaning_pipeline(raw_dir="data/raw", cleaned_dir="data/cleaned")
    print("Done.\n")
    
    # 3. Database setup & queries
    print("3. Loading cleaned data into database...")
    db_mgr = DatabaseManager()
    db_mgr.connect()
    db_mgr.create_tables()
    db_mgr.load_cleaned_data(cleaned_dir="data/cleaned")
    print("Done.\n")
    
    print("4. Executing 16 SQL analysis queries...")
    sql_runner = SQLAnalyticsRunner(db_manager=db_mgr)
    query_results = sql_runner.run_all_queries(queries_dir="queries")
    print("Done.\n")
    
    # 4. CLI report
    print("5. Generating summary CLI report...")
    generate_cli_report(db_manager=db_mgr, report_type="monthly", start_date="2024-01-01", end_date="2025-06-30")
    print("Done.\n")
    
    # 5. Run tests
    print("6. Running edge case tests...")
    test_orphan_order_items()
    test_excessive_discount_percent()
    test_zero_quantity_items()
    test_future_order_date()
    print("All edge case tests completed successfully!\n")
    
    print("Pipeline finished successfully.")

if __name__ == "__main__":
    run_pipeline()
