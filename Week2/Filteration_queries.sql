-- ############################################################
--                   FILTERING
--         Filter Data using WHERE and Conditions
-- ############################################################

-- ============================================================
-- B1. Filter Records Where Sales > 500
-- ============================================================
SELECT *
FROM superstore
WHERE Sales > 500;

-- ============================================================
-- B2. Filter by Category (Furniture)
-- ============================================================
SELECT *
FROM superstore
WHERE Category = 'Furniture';

-- ============================================================
-- B3. Filter by Date Range (Year 2016)
-- ============================================================
SELECT *
FROM superstore
WHERE `Order Date` BETWEEN '2016-01-01' AND '2016-12-31';

-- ============================================================
-- B4. Sort Sales from Highest to Lowest
-- ============================================================
SELECT *
FROM superstore
ORDER BY Sales DESC;

-- ============================================================
-- B5. Top 5 Highest Sales Records
-- ============================================================
SELECT *
FROM superstore
ORDER BY Sales DESC
LIMIT 5;

