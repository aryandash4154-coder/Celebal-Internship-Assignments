-- ====================================================================
-- Stage 04: SCD Type 2 Management
-- File: 02_product_scd_type2.sql
-- Description: Processes Product Dimension Slowly Changing Dimension (SCD) Type 2 tracking.
-- Preserves effective date ranges (prd_start_dt, prd_end_dt) and current version flags from source CRM catalog.
-- Dialect: MySQL 8.0+
-- ====================================================================

CREATE DATABASE IF NOT EXISTS gold;

DROP TABLE IF EXISTS gold.dim_products;

CREATE TABLE gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY p.prd_id, p.prd_start_dt) AS product_key,
    p.prd_id AS product_id,
    p.prd_key AS product_natural_key,
    p.item_key,
    p.prd_nm AS product_name,
    COALESCE(x.category, 'Unassigned') AS category_name,
    COALESCE(x.subcategory, 'Unassigned') AS subcategory_name,
    p.prd_line AS product_line,
    p.prd_cost AS unit_cost,
    COALESCE(x.is_maintenance_required, 0) AS is_maintenance_required,
    p.prd_start_dt AS effective_start_date,
    p.prd_end_dt AS effective_end_date,
    p.is_current
FROM silver.crm_prd_info p
LEFT JOIN silver.erp_px_cat_g1v2 x ON p.cat_id = x.cat_id;
