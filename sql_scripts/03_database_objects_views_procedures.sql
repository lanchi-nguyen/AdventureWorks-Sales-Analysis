-- =================================================================
-- PROJECT: ADVENTUREWORKS SALES ANALYSIS
-- FILE 3: REUSABLE DATABASE OBJECTS (VIEWS, UDFs & STORED PROCEDURES)
-- Author: Data / Business Analyst Candidate
-- Database: AdventureWorks2019 (SQL Server)
-- =================================================================

USE AdventureWorks2019;
GO

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

