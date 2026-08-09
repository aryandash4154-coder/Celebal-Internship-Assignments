"""
Automated Chart Generator for Portfolio README Visuals
Queries Gold Star Schema in MySQL database and renders publication-ready plots.
"""

import sys
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from config.settings import (
    MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE,
    SQLITE_DB_PATH, VISUALIZATIONS_DIR
)

def get_connection():
    try:
        import mysql.connector
        conn = mysql.connector.connect(
            host=MYSQL_HOST, port=MYSQL_PORT, user=MYSQL_USER, password=MYSQL_PASSWORD, database=MYSQL_DATABASE
        )
        return conn, "mysql"
    except Exception:
        try:
            import pymysql
            conn = pymysql.connect(
                host=MYSQL_HOST, port=MYSQL_PORT, user=MYSQL_USER, password=MYSQL_PASSWORD, database=MYSQL_DATABASE
            )
            return conn, "mysql"
        except Exception:
            conn = sqlite3.connect(str(SQLITE_DB_PATH))
            return conn, "sqlite"

def read_df(conn, db_type, sql):
    if db_type == "sqlite":
        sql = sql.replace("gold.", "gold_")
    return pd.read_sql_query(sql, conn)

def set_style():
    """Applies clean, modern plotting styling."""
    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
    plt.rcParams['font.sans-serif'] = 'Arial'
    plt.rcParams['axes.edgecolor'] = '#cccccc'
    plt.rcParams['axes.linewidth'] = 0.8

def generate_sales_trend(conn, db_type):
    """Generates monthly revenue & profit trend chart."""
    sql = """
        SELECT 
            SUBSTR(d.full_date, 1, 7) AS year_month,
            SUM(f.sales_amount) / 1e6 AS revenue_millions,
            SUM(f.profit_amount) / 1e6 AS profit_millions
        FROM gold.fact_sales f
        JOIN gold.dim_date d ON f.order_date_key = d.date_key
        GROUP BY SUBSTR(d.full_date, 1, 7)
        ORDER BY year_month
    """
    df = read_df(conn, db_type, sql)

    plt.figure(figsize=(10, 5))
    plt.plot(df['year_month'], df['revenue_millions'], marker='o', linewidth=2.5, color='#1f77b4', label='Revenue ($M)')
    plt.plot(df['year_month'], df['profit_millions'], marker='s', linewidth=2.5, color='#2ca02c', label='Profit ($M)')
    
    plt.title('Monthly Sales Revenue & Profit Trend (2010 - 2014)', fontsize=14, fontweight='bold', pad=15)
    plt.xlabel('Year-Month', fontsize=11, labelpad=10)
    plt.ylabel('Amount ($ Millions)', fontsize=11, labelpad=10)
    plt.xticks(rotation=45, ha='right', fontsize=9)
    plt.legend(frameon=True, facecolor='white', edgecolor='#e0e0e0')
    plt.tight_layout()
    
    output_path = VISUALIZATIONS_DIR / "sales_trend.png"
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"  [+] Chart saved: {output_path.name}")

def generate_category_breakdown(conn, db_type):
    """Generates revenue & profit breakdown by product category."""
    sql = """
        SELECT 
            p.category_name,
            SUM(f.sales_amount) / 1e6 AS revenue_millions,
            SUM(f.profit_amount) / 1e6 AS profit_millions
        FROM gold.fact_sales f
        JOIN gold.dim_products p ON f.product_key = p.product_key
        GROUP BY p.category_name
        ORDER BY revenue_millions DESC
    """
    df = read_df(conn, db_type, sql)

    fig, ax = plt.subplots(figsize=(8, 5))
    x = range(len(df['category_name']))
    width = 0.35

    ax.bar([i - width/2 for i in x], df['revenue_millions'], width, label='Revenue ($M)', color='#2b5c8f')
    ax.bar([i + width/2 for i in x], df['profit_millions'], width, label='Profit ($M)', color='#47a050')

    ax.set_title('Revenue & Profit by Product Category', fontsize=14, fontweight='bold', pad=15)
    ax.set_ylabel('Amount ($ Millions)', fontsize=11)
    ax.set_xticks(x)
    ax.set_xticklabels(df['category_name'], fontsize=10)
    ax.legend(frameon=True, facecolor='white', edgecolor='#e0e0e0')
    plt.tight_layout()

    output_path = VISUALIZATIONS_DIR / "revenue_by_category.png"
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"  [+] Chart saved: {output_path.name}")

def generate_country_demographics(conn, db_type):
    """Generates regional spend distribution chart."""
    sql = """
        SELECT 
            c.country,
            SUM(f.sales_amount) / 1e6 AS total_revenue
        FROM gold.fact_sales f
        JOIN gold.dim_customers c ON f.customer_key = c.customer_key
        GROUP BY c.country
        ORDER BY total_revenue DESC
    """
    df = read_df(conn, db_type, sql)

    plt.figure(figsize=(8, 5))
    colors = ['#1f77b4', '#aec7e8', '#ff7f0e', '#ffbb78', '#2ca02c', '#98df8a']
    bars = plt.barh(df['country'], df['total_revenue'], color=colors[:len(df)])
    
    plt.title('Total Revenue by Customer Geographic Region', fontsize=14, fontweight='bold', pad=15)
    plt.xlabel('Revenue ($ Millions)', fontsize=11, labelpad=10)
    plt.gca().invert_yaxis()  # Top revenue at top
    
    # Add data labels
    for bar in bars:
        width = bar.get_width()
        plt.text(width + 0.5, bar.get_y() + bar.get_height()/2, f'${width:.2f}M', ha='left', va='center', fontsize=9)

    plt.tight_layout()
    output_path = VISUALIZATIONS_DIR / "customer_demographics.png"
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"  [+] Chart saved: {output_path.name}")

def main():
    print("Generating Analytical Visualization Charts...")
    set_style()
    conn, db_type = get_connection()
    try:
        generate_sales_trend(conn, db_type)
        generate_category_breakdown(conn, db_type)
        generate_country_demographics(conn, db_type)
        print("[SUCCESS] All visualization charts successfully rendered!")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
