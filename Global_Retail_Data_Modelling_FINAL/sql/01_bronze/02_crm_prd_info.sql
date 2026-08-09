-- Bronze Layer: crm_prd_info
-- Description: Ingests raw CRM Product Info table preserving raw strings and adding audit metadata.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS bronze;

DROP TABLE IF EXISTS bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id VARCHAR(255),
    prd_key VARCHAR(255),
    prd_nm VARCHAR(255),
    prd_cost VARCHAR(255),
    prd_line VARCHAR(255),
    prd_start_dt VARCHAR(255),
    prd_end_dt VARCHAR(255),
    _ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
