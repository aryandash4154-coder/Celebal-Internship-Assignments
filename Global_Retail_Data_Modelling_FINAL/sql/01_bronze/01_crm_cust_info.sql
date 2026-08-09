-- Bronze Layer: crm_cust_info
-- Description: Ingests raw CRM Customer Info table preserving raw strings and adding audit metadata.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS bronze;

DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id VARCHAR(255),
    cst_key VARCHAR(255),
    cst_firstname VARCHAR(255),
    cst_lastname VARCHAR(255),
    cst_marital_status VARCHAR(255),
    cst_gndr VARCHAR(255),
    cst_create_date VARCHAR(255),
    _ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
