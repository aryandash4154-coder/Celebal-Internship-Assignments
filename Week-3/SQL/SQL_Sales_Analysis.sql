USE sales_analysis;

-- Create Customers Table
CREATE TABLE customers AS
SELECT DISTINCT
    `Customer ID` AS Customer_ID,
    `Customer Name` AS Customer_Name,
    Segment,
    Country,
    City,
    State,
    `Postal Code` AS Postal_Code,
    Region
FROM superstore_raw;

-- Create Products Table
CREATE TABLE products AS
SELECT DISTINCT
    `Product ID` AS Product_ID,
    Category,
    `Sub-Category` AS Sub_Category,
    `Product Name` AS Product_Name
FROM superstore_raw;

-- Create Orders Table
CREATE TABLE orders AS
SELECT
    `Row ID` AS Row_ID,
    `Order ID` AS Order_ID,
    `Order Date` AS Order_Date,
    `Ship Date` AS Ship_Date,
    `Ship Mode` AS Ship_Mode,
    `Customer ID` AS Customer_ID,
    `Product ID` AS Product_ID,
    Sales,
    Quantity,
    Discount,
    Profit
FROM superstore_raw;

-- Subquery 1: Orders Above Average Sales
SELECT *
FROM orders
WHERE Sales >
(
    SELECT AVG(Sales)
    FROM orders
);

-- Subquery 2: Highest Order Per Customer
SELECT *
FROM orders o
WHERE Sales =
(
    SELECT MAX(Sales)
    FROM orders
    WHERE Customer_ID = o.Customer_ID
);

-- CTE 1: Total Sales Per Customer
WITH customer_sales AS
(
    SELECT
        Customer_ID,
        SUM(Sales) AS Total_Sales
    FROM orders
    GROUP BY Customer_ID
)
SELECT *
FROM customer_sales
ORDER BY Total_Sales DESC;

-- CTE 2: Average Profit Per Customer
WITH customer_profit AS
(
    SELECT
        Customer_ID,
        AVG(Profit) AS Avg_Profit
    FROM orders
    GROUP BY Customer_ID
)
SELECT *
FROM customer_profit;

-- Window Function: ROW_NUMBER
SELECT
    Customer_ID,
    Sales,
    ROW_NUMBER() OVER (ORDER BY Sales DESC)
FROM orders;

-- Window Function: RANK
SELECT
    Customer_ID,
    SUM(Sales) AS Total_Sales,
    RANK() OVER (ORDER BY SUM(Sales) DESC)
FROM orders
GROUP BY Customer_ID;

-- JOIN + CTE + Window Function
WITH customer_sales AS
(
    SELECT
        Customer_ID,
        SUM(Sales) AS Total_Sales
    FROM orders
    GROUP BY Customer_ID
)
SELECT
    c.Customer_Name AS Customer,
    cs.Total_Sales,
    RANK() OVER (ORDER BY cs.Total_Sales DESC) AS Customer_Rank
FROM customers c
JOIN customer_sales cs
ON c.Customer_ID = cs.Customer_ID;

-- Business Query 1: Top 10 Customers
SELECT
    Customer_ID,
    SUM(Sales) AS Total_Sales
FROM orders
GROUP BY Customer_ID
ORDER BY Total_Sales DESC
LIMIT 10;

-- Business Query 2: Lowest 10 Customers
SELECT
    Customer_ID,
    SUM(Sales) AS Total_Sales
FROM orders
GROUP BY Customer_ID
ORDER BY Total_Sales ASC
LIMIT 10;

-- Business Query 3: Customers with Only One Order
SELECT
    Customer_ID,
    COUNT(Order_ID) AS Total_Orders
FROM orders
GROUP BY Customer_ID
HAVING COUNT(Order_ID) = 1;

-- Business Query 4: Customers Above Average Total Sales
SELECT
    Customer_ID,
    SUM(Sales) AS Total_Sales
FROM orders
GROUP BY Customer_ID
HAVING SUM(Sales) >
(
    SELECT AVG(TotalSales)
    FROM
    (
        SELECT SUM(Sales) AS TotalSales
        FROM orders
        GROUP BY Customer_ID
    ) AS AvgSales
);