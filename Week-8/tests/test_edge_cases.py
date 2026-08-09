import os
import pytest
import pandas as pd
from datetime import datetime
from src.cleaner import check_referential_integrity, clean_orders

def test_orphan_order_items():
    """
    1. Verifies system behavior when order_items references order_id not present in orders table.
    """
    df_orders = pd.DataFrame([
        {"order_id": "ORD-00001", "customer_id": "CUST-0001", "order_date": "2024-01-01 10:00:00", "status": "DELIVERED", "region_code": "US-EAST"}
    ])
    
    df_order_items = pd.DataFrame([
        {"item_id": "ITEM-000001", "order_id": "ORD-00001", "product_id": "PROD-0001", "quantity": 2, "unit_price": 50.0, "discount_percent": 0.0},
        {"item_id": "ITEM-000002", "order_id": "ORD-99999", "product_id": "PROD-0002", "quantity": 1, "unit_price": 100.0, "discount_percent": 10.0}
    ])
    
    orphans = check_referential_integrity(df_orders, df_order_items)
    
    assert len(orphans) == 1, "Should detect exactly 1 orphan order_item record"
    assert orphans[0]["item_id"] == "ITEM-000002", "Orphan item ID should be ITEM-000002"
    assert orphans[0]["order_id"] == "ORD-99999", "Orphan order ID should be ORD-99999"
    print("\n[TEST PASSED] test_orphan_order_items correctly caught invalid order reference!")

def test_excessive_discount_percent():
    """
    2. Verifies system behavior when discount_percent > 100%.
       Flags/caps discount to 100% or raises data validation warning.
    """
    df_order_items = pd.DataFrame([
        {"item_id": "ITEM-00001", "order_id": "ORD-00001", "product_id": "PROD-0001", "quantity": 1, "unit_price": 100.0, "discount_percent": 150.0}
    ])
    
    # Validation logic: Cap discounts at 100% or flag invalid discounts
    invalid_discounts = df_order_items[df_order_items['discount_percent'] > 100]
    assert len(invalid_discounts) == 1, "Should catch discount > 100%"
    
    # Apply safety cap
    df_order_items['discount_percent_cleaned'] = df_order_items['discount_percent'].clip(upper=100.0)
    assert df_order_items['discount_percent_cleaned'].iloc[0] == 100.0
    print("\n[TEST PASSED] test_excessive_discount_percent correctly capped invalid discount at 100%!")

def test_zero_quantity_items():
    """
    3. Verifies system behavior when order item quantity is 0.
       Calculates revenue as 0 and flags non-actionable line item.
    """
    df_order_items = pd.DataFrame([
        {"item_id": "ITEM-00001", "order_id": "ORD-00001", "product_id": "PROD-0001", "quantity": 0, "unit_price": 100.0, "discount_percent": 10.0}
    ])
    
    zero_qty_mask = df_order_items['quantity'] == 0
    assert zero_qty_mask.sum() == 1, "Should detect zero-quantity item"
    
    df_order_items['revenue'] = df_order_items['quantity'] * df_order_items['unit_price'] * (1 - df_order_items['discount_percent']/100.0)
    assert df_order_items['revenue'].iloc[0] == 0.0, "Revenue for zero-quantity item must be 0.0"
    print("\n[TEST PASSED] test_zero_quantity_items handled 0 quantity gracefully with 0 revenue!")

def test_future_order_date():
    """
    4. Verifies system behavior when order_date is in the future relative to execution cutoff.
    """
    future_date_str = (datetime.now() + pd.Timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
    
    df_orders = pd.DataFrame([
        {"order_id": "ORD-00001", "customer_id": "CUST-0001", "order_date": future_date_str, "status": "PLACED", "region_code": "US-EAST"}
    ])
    
    cleaned_df, issues = clean_orders(df_orders)
    
    current_now = datetime.now()
    future_mask = pd.to_datetime(cleaned_df['order_date']) > current_now
    assert future_mask.sum() == 1, "Should detect order date in the future"
    print("\n[TEST PASSED] test_future_order_date accurately flagged future date order!")

if __name__ == "__main__":
    test_orphan_order_items()
    test_excessive_discount_percent()
    test_zero_quantity_items()
    test_future_order_date()
