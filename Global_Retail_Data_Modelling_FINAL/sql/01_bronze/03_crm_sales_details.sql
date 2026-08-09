-- Bronze Layer: crm_sales_details
-- Description: Ingests raw CRM Sales Details transaction records preserving raw strings and audit metadata.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS bronze;

DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num VARCHAR(255),
    sls_prd_key VARCHAR(255),
    sls_cust_id VARCHAR(255),
    sls_order_dt VARCHAR(255),
    sls_ship_dt VARCHAR(255),
    sls_due_dt VARCHAR(255),
    sls_sales VARCHAR(255),
    sls_quantity VARCHAR(255),
    sls_price VARCHAR(255),
    _ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
