-- =================================================================
-- PROJECT: ADVENTUREWORKS SALES ANALYSIS
-- FILE 2: ADVANCED ANALYTICS & WINDOW FUNCTIONS
-- Author: Data / Business Analyst Candidate
-- Database: AdventureWorks2019 (SQL Server)
-- =================================================================

USE AdventureWorks2019;
GO

-- =================================================================
-- SECTION 3: COMMON TABLE EXPRESSIONS (CTEs) & MULTI-TABLE JOINS
-- Goal: Structure complex business logic using modular CTEs.
-- =================================================================

-- 3.1 Customer Order Count & Lifetime Value Summary
SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    COUNT(soh.SalesOrderID) AS TotalOrdersPlaced,
    ISNULL(ROUND(SUM(soh.TotalDue), 2), 0) AS LifetimeValue
FROM Sales.Customer c
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, p.FirstName, p.LastName;

-- 3.2 Modular CTE for Filtering and Analyzing Annual Sales (2011)
WITH CTE_Orders2011 AS (
    SELECT 
        CustomerID, 
        SalesOrderID, 
        OrderDate,
        TotalDue
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2011
)
SELECT 
    c.CustomerID, 
    COUNT(o.SalesOrderID) AS OrdersIn2011,
    ROUND(SUM(o.TotalDue), 2) AS SalesIn2011
FROM Sales.Customer c
LEFT JOIN CTE_Orders2011 o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
HAVING SUM(o.TotalDue) > 5000
ORDER BY SalesIn2011 DESC;

-- 3.3 Multi-Level CTE: Product Profitability & Category Margins
WITH ProductCosts AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        p.StandardCost,
        p.ListPrice,
        (p.ListPrice - p.StandardCost) AS UnitMargin
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
),
SalesSummary AS (
    SELECT 
        ProductID,
        SUM(OrderQty) AS TotalQtySold,
        SUM(LineTotal) AS GrossSales
    FROM Sales.SalesOrderDetail
    GROUP BY ProductID
)
SELECT 
    pc.ProductName,
    pc.CategoryName,
    pc.UnitMargin,
    ISNULL(ss.TotalQtySold, 0) AS TotalQtySold,
    ISNULL(ROUND(ss.GrossSales, 2), 0) AS GrossSales
FROM ProductCosts pc
LEFT JOIN SalesSummary ss ON pc.ProductID = ss.ProductID
WHERE pc.UnitMargin > 0
ORDER BY GrossSales DESC;


-- =================================================================
-- SECTION 4: ADVANCED ANALYTICS & WINDOW FUNCTIONS
-- Goal: Execute Partitioning, Moving Averages, Customer Deciles (NTILE),
--       and Explicit Running Total Framing.
-- =================================================================

-- 4.1 Customer Revenue Deciles (NTILE Bucket Analysis)
SELECT 
    CustomerID, 
    ROUND(SUM(TotalDue), 2) AS TotalSales, 
    NTILE(10) OVER(
        ORDER BY SUM(TotalDue) DESC
    ) AS RevenueDecile 
FROM Sales.SalesOrderHeader 
WHERE YEAR(OrderDate) = 2011 
GROUP BY CustomerID;

-- 4.2 Partitioned Row Numbering by Product Subcategory
SELECT 
    ProductID,
    Name AS ProductName,
    ProductSubCategoryID,
    ROW_NUMBER() OVER(
        PARTITION BY ProductSubCategoryID 
        ORDER BY ProductID ASC
    ) AS SubcategoryRank
FROM Production.Product
WHERE ProductSubCategoryID IS NOT NULL;

-- 4.3 Overall vs. Per-Customer Order Average Comparison
SELECT 
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalDue,
    ROUND(AVG(TotalDue) OVER(), 2) AS OverallAverageOrderValue,
    ROUND(AVG(TotalDue) OVER(PARTITION BY CustomerID), 2) AS CustomerAverageOrderValue
FROM Sales.SalesOrderHeader;

-- 4.4 Product Cumulative Running Total with Explicit Frame Optimization (ROWS)
SELECT 
    SalesOrderID,
    ProductID,
    LineTotal,
    ROUND(SUM(LineTotal) OVER(
        PARTITION BY ProductID 
        ORDER BY SalesOrderID 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS CumulativeLineTotal
FROM Sales.SalesOrderDetail;

-- 4.5 Moving 3-Row Average Order Value Calculation
SELECT 
    SalesOrderID,
    ProductID,
    LineTotal,
    ROUND(AVG(LineTotal) OVER(
        PARTITION BY ProductID 
        ORDER BY SalesOrderID 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS MovingAverageLineTotal
FROM Sales.SalesOrderDetail;
