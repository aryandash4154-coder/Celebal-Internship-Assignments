-- Bronze Layer: erp_px_cat_g1v2
-- Description: Ingests raw ERP Product Category hierarchy table.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS bronze;

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id VARCHAR(255),
    cat VARCHAR(255),
    subcat VARCHAR(255),
    maintenance VARCHAR(255),
    _ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
