import os
import random
import pandas as pd
from datetime import datetime, timedelta

def generate_datasets(output_dir="data/raw", num_customers=200, num_products=60, num_orders=600, num_items=1200, seed=42):
    """
    Generates 4 CSV files (customers.csv, products.csv, orders.csv, order_items.csv)
    with realistic e-commerce data and intentional data anomalies as specified in requirements:
      - 5% orders have NULL customer_id
      - 3% order_items have negative quantity
      - Some order dates in wrong format (DD-MM-YYYY)
      - Some product names have extra spaces or mixed case
      - 2% customer emails are invalid
    """
    random.seed(seed)
    os.makedirs(output_dir, exist_ok=True)
    
    first_names = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Elizabeth", 
                   "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen",
                   "Arjun", "Priya", "Rahul", "Ananya", "Siddharth", "Neha", "Vikram", "Pooja", "Aarav", "Isha"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
                  "Sharma", "Verma", "Patel", "Mehta", "Singh", "Nair", "Kulkarni", "Gupta", "Rao", "Reddy"]
    domains = ["gmail.com", "yahoo.com", "outlook.com", "icloud.com", "example.com", "techstore.org"]
    
    customer_types = ["REGULAR", "PREMIUM", "VIP"]
    customer_rows = []
    
    start_reg_date = datetime(2023, 1, 1)
    
    for i in range(1, num_customers + 1):
        cid = f"CUST-{i:04d}"
        fn = random.choice(first_names)
        ln = random.choice(last_names)
        name = f"{fn} {ln}"
        
        # 2% invalid emails (missing @ or missing domain)
        if random.random() < 0.02:
            if random.random() < 0.5:
                email = f"{fn.lower()}{ln.lower()}{domains[0]}" # missing @
            else:
                email = f"{fn.lower()}{ln.lower()}@" # missing domain
        else:
            email = f"{fn.lower()}.{ln.lower()}{random.randint(1, 99)}@{random.choice(domains)}"
            
        reg_days = random.randint(0, 500)
        reg_date = (start_reg_date + timedelta(days=reg_days)).strftime("%Y-%m-%d")
        ctype = random.choice(customer_types)
        
        customer_rows.append({
            "customer_id": cid,
            "customer_name": name,
            "email": email,
            "registration_date": reg_date,
            "customer_type": ctype
        })
        
    df_customers = pd.DataFrame(customer_rows)
    df_customers.to_csv(os.path.join(output_dir, "customers.csv"), index=False)
    
    # 2. Generate products.csv
    categories_spec = {
        "Electronics": [("Smartphone Pro", 799.99), ("Wireless Earbuds", 89.99), ("4K Monitor", 349.99), 
                        ("Mechanical Keyboard", 119.99), ("Gaming Mouse", 49.99), ("Bluetooth Speaker", 59.99),
                        ("USB-C Hub", 29.99), ("Webcam HD", 69.99), ("Smart Watch", 199.99), ("Tablet Air", 499.99)],
        "Clothing": [("Denim Jacket", 65.00), ("Cotton T-Shirt", 19.99), ("Slim Fit Jeans", 45.00),
                     ("Running Shoes", 85.00), ("Wool Sweater", 55.00), ("Leather Belt", 25.00),
                     ("Winter Coat", 120.00), ("Sports Socks (3-pack)", 12.50), ("Hoodie Sweatshirt", 40.00)],
        "Home": [("Ergonomic Desk Chair", 180.00), ("LED Desk Lamp", 35.00), ("Ceramic Coffee Mug", 12.00),
                 ("Memory Foam Pillow", 40.00), ("Air Purifier", 130.00), ("Robot Vacuum", 250.00),
                 ("Stainless Water Bottle", 22.00), ("Blender 1000W", 75.00)],
        "Books": [("Python Data Science Handbook", 45.00), ("Clean Code Guide", 38.00), ("SQL for Analytics", 32.00),
                  ("The Lean Startup", 28.00), ("Designing Data Systems", 52.00), ("Atomic Habits", 22.00)]
    }
    
    product_rows = []
    pid_counter = 1
    
    for cat, items in categories_spec.items():
        for pname, unit_cost in items:
            pid = f"PROD-{pid_counter:04d}"
            pid_counter += 1
            
            subcat = f"{cat} General"
            
            # Anomaly: Some product names have extra spaces or mixed case
            raw_pname = pname
            rand_val = random.random()
            if rand_val < 0.15:
                raw_pname = f"  {pname.upper()}  "
            elif rand_val < 0.30:
                raw_pname = f"{pname.lower()} "
                
            product_rows.append({
                "product_id": pid,
                "product_name": raw_pname,
                "category": cat,
                "subcategory": subcat,
                "cost_price": round(unit_cost * 0.6, 2)
            })
            
    df_products = pd.DataFrame(product_rows)
    df_products.to_csv(os.path.join(output_dir, "products.csv"), index=False)
    
    # 3. Generate orders.csv
    statuses = ["PLACED", "SHIPPED", "DELIVERED", "CANCELLED", "RETURNED"]
    regions = ["US-EAST", "US-WEST", "EU-CENTRAL", "APAC-SOUTH", "LATAM"]
    status_weights = [0.10, 0.15, 0.60, 0.08, 0.07]
    
    order_rows = []
    start_order_date = datetime(2024, 1, 1)
    end_order_date = datetime(2025, 8, 1)
    date_span_seconds = int((end_order_date - start_order_date).total_seconds())
    
    customer_ids = [c["customer_id"] for c in customer_rows]
    
    for i in range(1, num_orders + 1):
        oid = f"ORD-{i:05d}"
        
        # 5% orders have NULL customer_id
        if random.random() < 0.05:
            cid = None
        else:
            cid = random.choice(customer_ids)
            
        random_seconds = random.randint(0, date_span_seconds)
        dt = start_order_date + timedelta(seconds=random_seconds)
        
        # Anomaly: Some dates in DD-MM-YYYY HH:MM:SS format instead of YYYY-MM-DD HH:MM:SS
        if random.random() < 0.08:
            date_str = dt.strftime("%d-%m-%Y %H:%M:%S")
        else:
            date_str = dt.strftime("%Y-%m-%d %H:%M:%S")
            
        st = random.choices(statuses, weights=status_weights)[0]
        reg = random.choice(regions)
        
        order_rows.append({
            "order_id": oid,
            "customer_id": cid if cid is not None else "",
            "order_date": date_str,
            "status": st,
            "region_code": reg
        })
        
    df_orders = pd.DataFrame(order_rows)
    df_orders.to_csv(os.path.join(output_dir, "orders.csv"), index=False)
    
    # 4. Generate order_items.csv
    order_items_rows = []
    all_order_ids = [o["order_id"] for o in order_rows]
    all_product_dict = {p["product_id"]: p for p in product_rows}
    all_product_ids = list(all_product_dict.keys())
    
    item_id_counter = 1
    for _ in range(num_items):
        item_id = f"ITEM-{item_id_counter:06d}"
        item_id_counter += 1
        
        oid = random.choice(all_order_ids)
        pid = random.choice(all_product_ids)
        
        # Quantity logic: 3% negative quantity (returns)
        if random.random() < 0.03:
            qty = -random.randint(1, 3)
        else:
            qty = random.randint(1, 5)
            
        unit_price = round(all_product_dict[pid]["cost_price"] / 0.6, 2)
        discount_percent = random.choice([0.0, 0.0, 0.0, 5.0, 10.0, 15.0, 20.0])
        
        order_items_rows.append({
            "item_id": item_id,
            "order_id": oid,
            "product_id": pid,
            "quantity": qty,
            "unit_price": unit_price,
            "discount_percent": discount_percent
        })
        
    df_items = pd.DataFrame(order_items_rows)
    df_items.to_csv(os.path.join(output_dir, "order_items.csv"), index=False)
    
    print(f"Data Generation Complete! Files saved in '{output_dir}':")
    print(f" - customers.csv ({len(df_customers)} rows)")
    print(f" - products.csv ({len(df_products)} rows)")
    print(f" - orders.csv ({len(df_orders)} rows)")
    print(f" - order_items.csv ({len(df_items)} rows)")

if __name__ == "__main__":
    generate_datasets()
