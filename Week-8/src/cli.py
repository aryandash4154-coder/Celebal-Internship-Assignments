import sys
from datetime import datetime, timedelta

from src.database import DatabaseManager


def get_report_metrics(db_manager, start_date, end_date):
    """Compute summary metrics and top 3 products for a MySQL date range."""
    summary_sql = """
        SELECT
            COUNT(DISTINCT o.order_id) AS total_orders,
            COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 0) AS total_revenue,
            COUNT(DISTINCT o.customer_id) AS unique_customers
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_date >= %s
          AND o.order_date <= %s
          AND o.status <> 'CANCELLED';
    """
    with db_manager.conn.cursor() as cursor:
        cursor.execute(summary_sql, (start_date, end_date))
        row = cursor.fetchone()

        top_products_sql = """
            SELECT
                p.product_name,
                SUM(oi.quantity) AS total_qty,
                ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS product_revenue
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            JOIN orders o ON oi.order_id = o.order_id
            WHERE o.order_date >= %s
              AND o.order_date <= %s
              AND o.status <> 'CANCELLED'
            GROUP BY p.product_name
            ORDER BY product_revenue DESC
            LIMIT 3;
        """
        cursor.execute(top_products_sql, (start_date, end_date))
        top_products = cursor.fetchall()

    return {
        "total_orders": row["total_orders"] or 0,
        "total_revenue": round(float(row["total_revenue"] or 0), 2),
        "unique_customers": row["unique_customers"] or 0,
        "top_products": top_products,
    }


def calculate_previous_period(start_str, end_str):
    """Calculate a previous period with the same duration."""
    d1 = datetime.strptime(start_str.split()[0], "%Y-%m-%d")
    d2 = datetime.strptime(end_str.split()[0], "%Y-%m-%d")
    duration = d2 - d1

    prev_end = d1 - timedelta(days=1)
    prev_start = prev_end - duration

    return prev_start.strftime("%Y-%m-%d 00:00:00"), prev_end.strftime("%Y-%m-%d 23:59:59")


def generate_cli_report(
    db_manager=None,
    report_type="monthly",
    start_date="2024-01-01",
    end_date="2024-12-31",
):
    """Generate a MySQL-backed business summary report."""
    owns_connection = db_manager is None
    db_manager = db_manager or DatabaseManager()

    if not db_manager.conn:
        db_manager.connect()

    start_date_full = f"{start_date} 00:00:00" if len(start_date) == 10 else start_date
    end_date_full = f"{end_date} 23:59:59" if len(end_date) == 10 else end_date

    curr_metrics = get_report_metrics(db_manager, start_date_full, end_date_full)
    prev_start_full, prev_end_full = calculate_previous_period(start_date_full, end_date_full)
    prev_metrics = get_report_metrics(db_manager, prev_start_full, prev_end_full)

    def pct_change(curr, prev):
        if prev == 0:
            return 100.0 if curr > 0 else 0.0
        return round(((curr - prev) / prev) * 100.0, 2)

    orders_pct = pct_change(curr_metrics["total_orders"], prev_metrics["total_orders"])
    rev_pct = pct_change(curr_metrics["total_revenue"], prev_metrics["total_revenue"])
    cust_pct = pct_change(curr_metrics["unique_customers"], prev_metrics["unique_customers"])

    report_output = f"""
======================================================
     E-COMMERCE BUSINESS SUMMARY REPORT ({report_type.upper()})
======================================================
Selected Period : {start_date_full} to {end_date_full}
Prior Period    : {prev_start_full} to {prev_end_full}

--- CORE PERFORMANCE METRICS ---
Total Revenue     : ${curr_metrics['total_revenue']:,.2f}  ({rev_pct:+.2f}% vs prior period)
Total Orders      : {curr_metrics['total_orders']:,}  ({orders_pct:+.2f}% vs prior period)
Unique Customers  : {curr_metrics['unique_customers']:,}  ({cust_pct:+.2f}% vs prior period)

--- TOP 3 PERFORMING PRODUCTS ---
"""

    for idx, product in enumerate(curr_metrics["top_products"], 1):
        report_output += (
            f"  {idx}. {product['product_name']} | "
            f"Quantity Sold: {product['total_qty']} | "
            f"Revenue: ${float(product['product_revenue'] or 0):,.2f}\n"
        )

    report_output += "======================================================\n"
    print(report_output)

    if owns_connection:
        db_manager.close()

    return report_output


def interactive_cli():
    """Interactive MySQL-backed command-line reporting loop."""
    print("\n--- Welcome to E-Commerce Analytics CLI Reporting Tool ---")
    print("Select Report Type:")
    print("  1. Daily")
    print("  2. Weekly")
    print("  3. Monthly")
    choice = input("Enter choice (1-3) [default: 3]: ").strip()

    type_map = {"1": "daily", "2": "weekly", "3": "monthly"}
    report_type = type_map.get(choice, "monthly")
    start_date = input("Enter Start Date (YYYY-MM-DD) [default: 2024-01-01]: ").strip() or "2024-01-01"
    end_date = input("Enter End Date (YYYY-MM-DD) [default: 2024-12-31]: ").strip() or "2024-12-31"

    generate_cli_report(report_type=report_type, start_date=start_date, end_date=end_date)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--interactive":
        interactive_cli()
    else:
        generate_cli_report()
