-- =================================================================
-- PROJECT: ADVENTUREWORKS SALES ANALYSIS
-- FILE 1: DATA EXPLORATION & CLEANING
-- Author: Data / Business Analyst Candidate
-- Database: AdventureWorks2019 (SQL Server)
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
