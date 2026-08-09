-- Bronze Layer: erp_cust_az12
-- Description: Ingests raw ERP Customer Demographics table.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS bronze;

DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid VARCHAR(255),
    bdate VARCHAR(255),
    gen VARCHAR(255),
    _ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
