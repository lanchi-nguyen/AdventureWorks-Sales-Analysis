-- =================================================================
-- PROJECT: ADVENTUREWORKS ENTERPRISE DATA & ANALYTICS PIPELINE (EXTENDED EDITION)
-- Target Database: AdventureWorks2019 (SQL Server)
-- Author: Data / Business Analyst Candidate
-- Purpose: Comprehensive Production-Grade Portfolio Script featuring 25+ Advanced
--          SQL Queries, Data Auditing, Subqueries, CTEs, Window Framing,
--          Set Operators, DML Transactions, Views, UDFs, and Stored Procedures.
-- =================================================================

USE AdventureWorks2019;
GO

-- =================================================================
-- SECTION 1: DATA EXPLORATION, CLEANING & STRING MANIPULATION
-- Goal: Inspect missing records, clean nulls, and format customer/product text.
-- =================================================================

-- 1.1 Full Name Concatenation with NULL Handling (Standardizing Middle Names)
SELECT 
    BusinessEntityID,
    PersonType,
    CONCAT(FirstName, ' ', COALESCE(MiddleName + ' ', ''), LastName) AS FullNameStandardized
FROM Person.Person;

-- 1.2 Identify Invalid / Missing Data across Sales Order Headers
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerIDs,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS MissingTerritoryIDs,
    SUM(CASE WHEN TotalDue IS NULL OR TotalDue <= 0 THEN 1 ELSE 0 END) AS InvalidTotalDue
FROM Sales.SalesOrderHeader;

-- 1.3 Conditional Keyword Search (Mountain Products in Silver)
SELECT 
    ps.Name AS SubcategoryName,
    p.Name AS ProductName,
    p.ProductID,
    p.Color,
    p.ListPrice
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE p.Color = 'Silver'
  AND (p.Name LIKE '%Mountain%' OR ps.Name LIKE '%Mountain%');

-- 1.4 Custom Conditional Sorting via CASE WHEN (Sort specific PersonTypes by LastName)
SELECT 
    PersonType, 
    FirstName, 
    LastName
FROM Person.Person
ORDER BY 
    CASE 
        WHEN PersonType IN ('IN', 'SP', 'SC') THEN LastName 
        ELSE FirstName 
    END ASC;


-- =================================================================
-- SECTION 2: SET OPERATORS, SUBQUERIES & DERIVED TABLES
-- Goal: Leverage EXCEPT, UNION, IN/NOT IN, and Subqueries for dataset validation.
-- =================================================================

-- 2.1 Identify Products Never Sold using EXCEPT Set Operator
SELECT ProductID, Name
FROM Production.Product
WHERE ProductID IN (
    SELECT ProductID FROM Production.Product
    EXCEPT
    SELECT ProductID FROM Sales.SalesOrderDetail
);

-- 2.2 Identify Unused Colors using NOT EXISTS Anti-Join Logic
SELECT DISTINCT p.Color
FROM Production.Product p
WHERE p.Color IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM Production.ProductSubcategory ps 
      WHERE ps.Name LIKE '%Bike%' AND p.Color = 'Yellow'
  );

-- 2.3 Consolidate Unique Business Entities Across HR and Person via UNION
SELECT BusinessEntityID, 'Employee' AS EntityRole
FROM HumanResources.Employee
UNION
SELECT BusinessEntityID, 'Customer' AS EntityRole
FROM Sales.Customer
WHERE PersonID IS NOT NULL;

-- 2.4 Subquery / Derived Table Join for Order Details
SELECT 
    soh.SalesOrderID, 
    soh.OrderDate, 
    soh.CustomerID,
    sod.ProductID,
    sod.UnitPrice
FROM Sales.SalesOrderHeader soh
INNER JOIN (
    SELECT SalesOrderID, ProductID, UnitPrice
    FROM Sales.SalesOrderDetail
    WHERE UnitPrice > 1000
) sod ON soh.SalesOrderID = sod.SalesOrderID;


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


-- =================================================================
-- SECTION 5: DATA MANIPULATION (DML) & TABLE STAGING
-- Goal: Audit tables, Bulk Inserts with NOT EXISTS checks, Updates, and Constraints.
-- =================================================================

-- 5.1 Create Audited Summary Staging Table
IF OBJECT_ID('dbo.CustomerSummary', 'U') IS NOT NULL
    DROP TABLE dbo.CustomerSummary;

SELECT 
    CustomerID, 
    COUNT(SalesOrderID) AS TotalOrders, 
    SUM(TotalDue) AS TotalSpent
INTO dbo.CustomerSummary
FROM Sales.SalesOrderHeader
GROUP BY CustomerID;

-- 5.2 Safe Bulk Insert Checking for Record Non-Existence
INSERT INTO dbo.CustomerSummary (CustomerID, TotalOrders, TotalSpent)
SELECT 
    soh.CustomerID,
    COUNT(soh.SalesOrderID),
    SUM(soh.TotalDue)
FROM Sales.SalesOrderHeader soh
WHERE NOT EXISTS (
    SELECT 1 
    FROM dbo.CustomerSummary cs 
    WHERE cs.CustomerID = soh.CustomerID
)
GROUP BY soh.CustomerID;

-- 5.3 Batch Price Updates & Multi-Table UPDATE
IF OBJECT_ID('dbo.demoProduct', 'U') IS NOT NULL
    DROP TABLE dbo.demoProduct;

SELECT * INTO dbo.demoProduct FROM Production.Product;

UPDATE dbo.demoProduct
SET ListPrice = ListPrice * 1.10
WHERE StandardCost > 500;

-- 5.4 Default Constraint Addition for Audit Columns
IF OBJECT_ID('dbo.demoSalesOrderHeader', 'U') IS NOT NULL
    DROP TABLE dbo.demoSalesOrderHeader;

SELECT * INTO dbo.demoSalesOrderHeader FROM Sales.SalesOrderHeader;

ALTER TABLE dbo.demoSalesOrderHeader ADD CONSTRAINT
[DF_demoSalesOrderHeader_DateEntered]
DEFAULT (GETDATE()) FOR [OrderDate];


-- =================================================================
-- SECTION 6: REUSABLE DATABASE OBJECTS (VIEWS, UDFs & STORED PROCEDURES)
-- Goal: Modularize production reporting logic into reusable database objects.
-- =================================================================

-- 6.1 View: Product Cost History Tracking
IF OBJECT_ID('dbo.vw_ProductsCostHistory', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ProductsCostHistory;
GO

CREATE VIEW dbo.vw_ProductsCostHistory AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.StandardCost AS CurrentStandardCost,
    pch.StartDate AS CostStartDate,
    pch.EndDate AS CostEndDate,
    pch.StandardCost AS HistoricalStandardCost
FROM Production.Product p
INNER JOIN Production.ProductCostHistory pch ON p.ProductID = pch.ProductID;
GO

-- 6.2 View: Monthly & Yearly Sales Aggregation per Customer
IF OBJECT_ID('dbo.vw_CustomerTotals', 'V') IS NOT NULL
    DROP VIEW dbo.vw_CustomerTotals;
GO

CREATE VIEW dbo.vw_CustomerTotals AS
SELECT 
    soh.CustomerID,
    YEAR(soh.OrderDate) AS OrderYear,
    MONTH(soh.OrderDate) AS OrderMonth,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
GROUP BY 
    soh.CustomerID,
    YEAR(soh.OrderDate),
    MONTH(soh.OrderDate);
GO

-- 6.3 User-Defined Function (UDF): String Digits Removal
IF OBJECT_ID('dbo.fn_RemoveNumbers', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_RemoveNumbers;
GO

CREATE FUNCTION dbo.fn_RemoveNumbers (
    @InputString VARCHAR(250)
)
RETURNS VARCHAR(250)
AS
BEGIN
    WHILE PATINDEX('%[0-9]%', @InputString) > 0
    BEGIN
        SET @InputString = STUFF(@InputString, PATINDEX('%[0-9]%', @InputString), 1, '');
    END;
    RETURN @InputString;
END;
GO

-- 6.4 User-Defined Function (UDF): Phone Number Standardizer
IF OBJECT_ID('dbo.fn_FormatPhone', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_FormatPhone;
GO

CREATE FUNCTION dbo.fn_FormatPhone (
    @PhoneString VARCHAR(10)
)
RETURNS VARCHAR(15)
AS
BEGIN
    IF LEN(@PhoneString) <> 10 OR ISNUMERIC(@PhoneString) = 0
        RETURN @PhoneString;

    RETURN '(' + SUBSTRING(@PhoneString, 1, 3) + ') ' 
              + SUBSTRING(@PhoneString, 4, 3) + '-' 
              + SUBSTRING(@PhoneString, 7, 4);
END;
GO

-- 6.5 Parameterized Stored Procedure with Output Parameter
IF OBJECT_ID('dbo.usp_ProductSales', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ProductSales;
GO

CREATE PROCEDURE dbo.usp_ProductSales
    @ProductID INT,
    @TotalSold INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalSold = COALESCE(SUM(OrderQty), 0)
    FROM Sales.SalesOrderDetail
    WHERE ProductID = @ProductID;
END;
GO

-- Execute Procedure
DECLARE @TotalUnits INT;
EXEC dbo.usp_ProductSales @ProductID = 776, @TotalSold = @TotalUnits OUTPUT;
SELECT @TotalUnits AS TotalUnitsSold;
GO

-- =================================================================
-- END OF SCRIPT
-- =================================================================
