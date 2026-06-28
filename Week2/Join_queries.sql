
--                     JOINS
--         Combine Data from Multiple Tables
-- ############################################################

-- ============================================================
-- D0. Create Customers Table
-- ============================================================
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(50),
    region        VARCHAR(20)
);

-- ============================================================
-- D0. Insert Sample Data into Customers
-- ============================================================
INSERT INTO customers VALUES
(1, 'Amit',  'East'),
(2, 'Sneha', 'West'),
(3, 'Rahul', 'North'),
(4, 'Priya', 'South');

-- ============================================================
-- D1. INNER JOIN — Only Matching Records
-- ============================================================
SELECT
    superstore.`Customer Name`,
    customers.region
FROM superstore
INNER JOIN customers
ON superstore.`Customer Name` = customers.customer_name;

-- ============================================================
-- D2. LEFT JOIN — All Superstore Records + Matching Customers
-- ============================================================
SELECT
    superstore.`Customer Name`,
    customers.region
FROM superstore
LEFT JOIN customers
ON superstore.`Customer Name` = customers.customer_name;

