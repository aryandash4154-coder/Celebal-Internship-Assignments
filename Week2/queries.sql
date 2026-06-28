-- Query 1: Total Number of Records
SELECT COUNT(*) AS Total_Records
FROM superstore;

-- Query 2: Total Sales
SELECT SUM(Sales) AS Total_Sales
FROM superstore;

-- Query 3: Average Sales
SELECT AVG(Sales) AS Average_Sales
FROM superstore;

-- Query 4: Total Profit
SELECT SUM(Profit) AS Total_Profit
FROM superstore;

-- Query 5: Sales by Region
SELECT Region, SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Query 6: Sales by Category
SELECT Category, SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Category
ORDER BY Total_Sales DESC;

-- Query 7: Average Profit by Region
SELECT Region, AVG(Profit) AS Average_Profit
FROM superstore
GROUP BY Region
ORDER BY Average_Profit DESC;

-- Query 8: Top 10 Customers by Sales
SELECT Customer_Name, SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Customer_Name
ORDER BY Total_Sales DESC
LIMIT 10;

-- Query 9: Top 10 Products by Sales
SELECT Product_Name, SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY Product_Name
ORDER BY Total_Sales DESC
LIMIT 10;

-- Query 10: Orders from West Region
SELECT *
FROM superstore
WHERE Region = 'West';

-- Query 11: Furniture Orders
SELECT *
FROM superstore
WHERE Category = 'Furniture';

-- Query 12: Orders with Sales Greater Than 1000
SELECT *
FROM superstore
WHERE Sales > 1000;

-- Query 13: Monthly Sales Trend
SELECT MONTH(Order_Date) AS Month,
SUM(Sales) AS Total_Sales
FROM superstore
GROUP BY MONTH(Order_Date)
ORDER BY Month;

-- Query 14: Check for Duplicate Order IDs
SELECT Order_ID, COUNT(*)
FROM superstore
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- Query 15: Check for NULL Customer IDs
SELECT *
FROM superstore
WHERE Customer_ID IS NULL;
