import os
import re
import pandas as pd
import pymysql


class DatabaseManager:
    """MySQL-only database manager for the e-commerce analytics pipeline."""

    def __init__(
        self,
        host=None,
        port=None,
        user=None,
        password=None,
        database=None,
    ):
        self.host = host or os.getenv("MYSQL_HOST", "localhost")
        self.port = int(port or os.getenv("MYSQL_PORT", "3306"))
        self.user = user or os.getenv("MYSQL_USER", "root")
        self.password = password if password is not None else os.getenv("MYSQL_PASSWORD", "")
        self.database = database or os.getenv("MYSQL_DATABASE", "ecommerce_analytics")
        self.conn = None

        if not re.fullmatch(r"[A-Za-z0-9_]+", self.database):
            raise ValueError("MYSQL_DATABASE must contain only letters, numbers, and underscores.")

    def connect(self):
        """Create the MySQL database if needed and connect to it."""
        if self.conn:
            return self.conn

        root_conn = pymysql.connect(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            autocommit=True,
            charset="utf8mb4",
        )
        try:
            with root_conn.cursor() as cursor:
                cursor.execute(
                    f"CREATE DATABASE IF NOT EXISTS `{self.database}` "
                    "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                )
        finally:
            root_conn.close()

        self.conn = pymysql.connect(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            database=self.database,
            autocommit=False,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
        )
        print(f"[DatabaseManager] Connected to MySQL '{self.database}' at {self.host}:{self.port}")
        return self.conn

    def create_tables(self):
        """Create the MySQL schema with primary and foreign-key constraints."""
        if not self.conn:
            self.connect()

        with self.conn.cursor() as cursor:
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
            cursor.execute("DROP TABLE IF EXISTS order_items;")
            cursor.execute("DROP TABLE IF EXISTS orders;")
            cursor.execute("DROP TABLE IF EXISTS products;")
            cursor.execute("DROP TABLE IF EXISTS customers;")
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")

            cursor.execute("""
                CREATE TABLE customers (
                    customer_id VARCHAR(50) PRIMARY KEY,
                    customer_name VARCHAR(100) NOT NULL,
                    email VARCHAR(100),
                    registration_date DATE,
                    customer_type VARCHAR(20),
                    INDEX idx_customers_registration_date (registration_date)
                ) ENGINE=InnoDB;
            """)

            cursor.execute("""
                CREATE TABLE products (
                    product_id VARCHAR(50) PRIMARY KEY,
                    product_name VARCHAR(150) NOT NULL,
                    category VARCHAR(50) NOT NULL,
                    subcategory VARCHAR(50),
                    cost_price DECIMAL(10, 2) NOT NULL
                ) ENGINE=InnoDB;
            """)

            cursor.execute("""
                CREATE TABLE orders (
                    order_id VARCHAR(50) PRIMARY KEY,
                    customer_id VARCHAR(50),
                    order_date DATETIME NOT NULL,
                    status VARCHAR(20) NOT NULL,
                    region_code VARCHAR(20),
                    INDEX idx_orders_customer_id (customer_id),
                    INDEX idx_orders_order_date (order_date),
                    CONSTRAINT fk_orders_customer
                        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
                ) ENGINE=InnoDB;
            """)

            cursor.execute("""
                CREATE TABLE order_items (
                    item_id VARCHAR(50) PRIMARY KEY,
                    order_id VARCHAR(50) NOT NULL,
                    product_id VARCHAR(50) NOT NULL,
                    quantity INT NOT NULL,
                    unit_price DECIMAL(10, 2) NOT NULL,
                    discount_percent DECIMAL(5, 2) NOT NULL,
                    INDEX idx_items_order_id (order_id),
                    INDEX idx_items_product_id (product_id),
                    CONSTRAINT fk_items_order
                        FOREIGN KEY (order_id) REFERENCES orders(order_id),
                    CONSTRAINT fk_items_product
                        FOREIGN KEY (product_id) REFERENCES products(product_id)
                ) ENGINE=InnoDB;
            """)

        self.conn.commit()
        print("[DatabaseManager] MySQL tables successfully created!")

    @staticmethod
    def _clean_value(value):
        if pd.isna(value):
            return None
        if isinstance(value, pd.Timestamp):
            return value.to_pydatetime()
        return value

    def load_cleaned_data(self, cleaned_dir="data/cleaned"):
        """Bulk-load cleaned CSV data into MySQL tables."""
        if not self.conn:
            self.connect()

        df_cust = pd.read_csv(os.path.join(cleaned_dir, "customers_cleaned.csv"))
        df_prod = pd.read_csv(os.path.join(cleaned_dir, "products_cleaned.csv"))
        df_ord = pd.read_csv(os.path.join(cleaned_dir, "orders_cleaned.csv"))
        df_items = pd.read_csv(os.path.join(cleaned_dir, "order_items_cleaned.csv"))

        # Orders with missing customer IDs are assigned to a controlled placeholder.
        if not (df_cust["customer_id"] == "UNASSIGNED").any():
            df_cust.loc[len(df_cust)] = {
                "customer_id": "UNASSIGNED",
                "customer_name": "Unassigned Customer",
                "email": None,
                "registration_date": None,
                "customer_type": "UNKNOWN",
            }

        customer_rows = [
            tuple(self._clean_value(r[c]) for c in [
                "customer_id", "customer_name", "email", "registration_date", "customer_type"
            ])
            for _, r in df_cust.iterrows()
        ]
        product_rows = [
            tuple(self._clean_value(r[c]) for c in [
                "product_id", "product_name", "category", "subcategory", "cost_price"
            ])
            for _, r in df_prod.iterrows()
        ]
        order_rows = [
            tuple(self._clean_value(r[c]) for c in [
                "order_id", "customer_id", "order_date", "status", "region_code"
            ])
            for _, r in df_ord.iterrows()
        ]
        item_rows = [
            tuple(self._clean_value(r[c]) for c in [
                "item_id", "order_id", "product_id", "quantity", "unit_price", "discount_percent"
            ])
            for _, r in df_items.iterrows()
        ]

        try:
            with self.conn.cursor() as cursor:
                cursor.executemany(
                    "INSERT INTO customers "
                    "(customer_id, customer_name, email, registration_date, customer_type) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    customer_rows,
                )
                cursor.executemany(
                    "INSERT INTO products "
                    "(product_id, product_name, category, subcategory, cost_price) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    product_rows,
                )
                cursor.executemany(
                    "INSERT INTO orders "
                    "(order_id, customer_id, order_date, status, region_code) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    order_rows,
                )
                cursor.executemany(
                    "INSERT INTO order_items "
                    "(item_id, order_id, product_id, quantity, unit_price, discount_percent) "
                    "VALUES (%s, %s, %s, %s, %s, %s)",
                    item_rows,
                )
            self.conn.commit()
        except Exception:
            self.conn.rollback()
            raise

        print("[DatabaseManager] Cleaned CSV data successfully loaded into MySQL!")

    def execute_query(self, query_sql):
        """Execute a MySQL query and return the result as a pandas DataFrame."""
        if not self.conn:
            self.connect()

        with self.conn.cursor() as cursor:
            cursor.execute(query_sql)
            rows = cursor.fetchall()
            columns = [column[0] for column in cursor.description] if cursor.description else []

        return pd.DataFrame(rows, columns=columns)

    def close(self):
        """Close the MySQL connection."""
        if self.conn:
            self.conn.close()
            self.conn = None
            print("[DatabaseManager] MySQL connection closed.")
