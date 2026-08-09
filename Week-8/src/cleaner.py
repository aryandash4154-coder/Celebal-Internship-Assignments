import os
import re
import json
import pandas as pd
from datetime import datetime

def clean_orders(df_orders):
    """
    Fixes order_date formats to YYYY-MM-DD HH:MM:SS and handles NULL/empty customer_ids.
    Returns cleaned DataFrame and issue records.
    """
    df = df_orders.copy()
    issues = []
    
    # 1. Handle NULL/empty customer_ids
    missing_cust_mask = df['customer_id'].isna() | (df['customer_id'].astype(str).str.strip() == '') | (df['customer_id'].astype(str).str.upper() == 'NULL')
    missing_cust_count = int(missing_cust_mask.sum())
    missing_order_ids = df[missing_cust_mask]['order_id'].tolist()
    
    if missing_cust_count > 0:
        issues.append({
            "issue_type": "MISSING_CUSTOMER_ID",
            "count": missing_cust_count,
            "affected_order_ids": missing_order_ids,
            "action": "Flagged & set customer_id to 'UNASSIGNED'"
        })
        df.loc[missing_cust_mask, 'customer_id'] = 'UNASSIGNED'
        
    # 2. Fix date formats
    def parse_and_format_date(val):
        if pd.isna(val) or not str(val).strip():
            return None
        val_str = str(val).strip()
        # Try standard YYYY-MM-DD HH:MM:SS
        for fmt in ("%Y-%m-%d %H:%M:%S", "%d-%m-%Y %H:%M:%S", "%Y-%m-%d", "%d-%m-%Y"):
            try:
                dt = datetime.strptime(val_str, fmt)
                return dt.strftime("%Y-%m-%d %H:%M:%S")
            except ValueError:
                continue
        # If pandas can parse it
        try:
            dt = pd.to_datetime(val_str)
            return dt.strftime("%Y-%m-%d %H:%M:%S")
        except Exception:
            return val_str

    original_dates = df['order_date'].copy()
    df['order_date'] = df['order_date'].apply(parse_and_format_date)
    
    # Identify reformatted dates
    date_changed_mask = original_dates != df['order_date']
    if date_changed_mask.sum() > 0:
        issues.append({
            "issue_type": "NON_STANDARD_DATE_FORMAT",
            "count": int(date_changed_mask.sum()),
            "action": "Standardized all date strings to YYYY-MM-DD HH:MM:SS format"
        })
        
    return df, issues

def clean_products(df_products):
    """
    Normalizes product names (trims leading/trailing spaces, converts to Title Case).
    Returns cleaned DataFrame and issue records.
    """
    df = df_products.copy()
    issues = []
    
    original_names = df['product_name'].copy()
    df['product_name'] = df['product_name'].astype(str).str.strip().str.title()
    
    changed_mask = original_names != df['product_name']
    if changed_mask.sum() > 0:
        issues.append({
            "issue_type": "UNNORMALIZED_PRODUCT_NAME",
            "count": int(changed_mask.sum()),
            "affected_product_ids": df[changed_mask]['product_id'].tolist(),
            "action": "Trimmed whitespace and converted product_name to Title Case"
        })
        
    return df, issues

def validate_emails(df_customers):
    """
    Identifies customer_ids with invalid email addresses (missing @ or missing domain).
    Returns list of invalid customer_ids and details.
    """
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    invalid_customers = []
    
    for idx, row in df_customers.iterrows():
        cid = row['customer_id']
        email = str(row['email']).strip() if pd.notna(row['email']) else ""
        if not re.match(email_regex, email):
            invalid_customers.append({
                "customer_id": cid,
                "email": email
            })
            
    return invalid_customers

def check_referential_integrity(df_orders, df_order_items):
    """
    Finds order_items that reference non-existent orders.
    Returns list of orphan item_ids and order_ids.
    """
    valid_order_ids = set(df_orders['order_id'].dropna().unique())
    orphan_items = []
    
    for idx, row in df_order_items.iterrows():
        oid = row['order_id']
        if oid not in valid_order_ids:
            orphan_items.append({
                "item_id": row['item_id'],
                "order_id": oid
            })
            
    return orphan_items

def run_data_cleaning_pipeline(raw_dir="data/raw", cleaned_dir="data/cleaned"):
    """
    Executes Part 2 cleaning tasks, saves cleaned CSVs, and outputs cleaning_report.json.
    """
    os.makedirs(cleaned_dir, exist_ok=True)
    
    df_customers = pd.read_csv(os.path.join(raw_dir, "customers.csv"))
    df_products = pd.read_csv(os.path.join(raw_dir, "products.csv"))
    df_orders = pd.read_csv(os.path.join(raw_dir, "orders.csv"))
    df_order_items = pd.read_csv(os.path.join(raw_dir, "order_items.csv"))
    
    # 1. Clean Orders
    cleaned_orders_df, order_issues = clean_orders(df_orders)
    
    # 2. Clean Products
    cleaned_products_df, product_issues = clean_products(df_products)
    
    # 3. Validate Emails
    invalid_email_list = validate_emails(df_customers)
    
    # 4. Check Referential Integrity
    orphan_items_list = check_referential_integrity(cleaned_orders_df, df_order_items)
    
    # Save Cleaned CSVs
    cleaned_orders_df.to_csv(os.path.join(cleaned_dir, "orders_cleaned.csv"), index=False)
    cleaned_products_df.to_csv(os.path.join(cleaned_dir, "products_cleaned.csv"), index=False)
    df_order_items.to_csv(os.path.join(cleaned_dir, "order_items_cleaned.csv"), index=False)
    df_customers.to_csv(os.path.join(cleaned_dir, "customers_cleaned.csv"), index=False)
    
    report = {
        "summary": "Data Cleaning & Validation Report",
        "orders_issues": order_issues,
        "products_issues": product_issues,
        "invalid_emails_count": len(invalid_email_list),
        "invalid_emails": invalid_email_list,
        "orphan_order_items_count": len(orphan_items_list),
        "orphan_order_items": orphan_items_list
    }
    
    with open(os.path.join(cleaned_dir, "cleaning_report.json"), "w") as f:
        json.dump(report, f, indent=2)
        
    print("Data Cleaning Pipeline Execution Completed!")
    print(f"Cleaned datasets & 'cleaning_report.json' written to '{cleaned_dir}/'")
    return report

if __name__ == "__main__":
    run_data_cleaning_pipeline()
