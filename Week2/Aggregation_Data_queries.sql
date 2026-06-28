-- ############################################################
--                 AGGREGATION
--      Use GROUP BY and Aggregate Functions
-- ############################################################

-- ============================================================
-- C1. Calculate Total Sales
-- ============================================================
SELECT SUM(Sales) AS Total_Sales
FROM superstore;

-- ============================================================
-- C2. Calculate Total Profit
-- ============================================================
SELECT SUM(Profit) AS Total_Profit
FROM superstore;

-- ============================================================
-- C3. Calculate Average Sales
-- ============================================================
SELECT AVG(Sales) AS Average_Sales
FROM superstore;

-- ============================================================
-- C4. Find Highest Sales Order
-- ============================================================
SELECT MAX(Sales) AS Highest_Sales
FROM superstore;

-- ============================================================
-- C5. Find Lowest Sales Order
-- ============================================================
SELECT MIN(Sales) AS Lowest_Sales
FROM superstore;

-- ============================================================
-- C6. Sales by Category
-- ============================================================
SELECT Category,
       SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Category
ORDER BY Total_Sales DESC;

-- ============================================================
-- C7. Sales by Region
-- ============================================================
SELECT Region,
       SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Region
ORDER BY Total_Sales DESC;

-- ============================================================
-- C8. Sales by Segment
-- ============================================================
SELECT Segment,
       SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Segment
ORDER BY Total_Sales DESC;

-- ============================================================
-- C9. Top 10 Customers by Sales
-- ============================================================
SELECT `Customer Name`,
       SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY `Customer Name`
ORDER BY Total_Sales DESC
LIMIT 10;

-- ============================================================
-- C10. Top 10 Products by Sales
-- ============================================================
SELECT `Product Name`,
       SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY `Product Name`
ORDER BY Total_Sales DESC
LIMIT 10;

-- ============================================================
-- C11. Categories with High Sales (HAVING Clause)
-- ============================================================
SELECT Category,
       SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Category
HAVING SUM(Sales) > 50000;

