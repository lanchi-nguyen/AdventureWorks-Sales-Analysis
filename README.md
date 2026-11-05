# AdventureWorks-Sales-Analysis

##  Executive Summary
This repository showcases an end-to-end Data & Business Intelligence solution leveraging enterprise-grade datasets (**AdventureWorks2019**, **Microsoft DA-100/PL-300**, and **VanArsdel / Dashboard in a Day**). The portfolio highlights a robust SQL analytics pipeline alongside three specialized Power BI dashboards designed to drive executive-level decision-making across product performance, customer segmentations, and global sales trends.

---

##  Tech Stack & Methods
* **SQL Server (T-SQL):** Data exploration, missing data auditing, multi-table `JOIN`s, set operators (`EXCEPT`, `UNION`), multi-level `CTE`s, advanced Window Functions (`NTILE`, `ROWS BETWEEN`), Views, UDFs, and Stored Procedures.
* **Power BI Desktop & DAX:** Star Schema Data Modeling, Time Intelligence (YTD, YoY Growth, Cumulative Revenue), Dynamic Slicing, RLS (Row-Level Security), and Interactive Dashboard Design.
* **Microsoft Excel:** Data inspection, initial data cleansing, and tabular cross-verification.

---

## 📊 Power BI Dashboards Overview

### 1. AdventureWorks Sales & Operations Performance
![AdventureWorks Dashboard Preview](power_bi/adventureworks_preview.png)
* **Dataset:** Microsoft AdventureWorks2019 Enterprise Database
* **Focus:** Executive KPI tracking, category profit margins, customer lifetime value, and regional territory revenue contribution.
* **Key DAX Metrics:** `Total Revenue`, `Total Profit Margin %`, `YoY Growth %`, and `YTD Sales`.

### 2. DA-100 / PL-300 Enterprise Sales Analytics
![DA-100 Dashboard Preview](power_bi/da100_preview.png)
* **Dataset:** Official Microsoft DA-100/PL-300 Exam Standard Dataset
* **Focus:** Data modeling (Star Schema), role-based access logic, sales quota comparisons, and product subcategory analysis.
* **Key Features:** Time intelligence calculations, drill-through functionality, and dynamic target tracking.

### 3. VanArsdel Market Share & Competitor Analysis (Dashboard in a Day)
![VanArsdel DIAD Preview](power_bi/vanarsdel_preview.png)
* **Dataset:** Microsoft DIAD (Dashboard in a Day - VanArsdel Growth Analysis)
* **Focus:** Industry competitor product positioning, and regional penetration trends for VanArsdel vs. competitors.
* **Key Features:** Custom calendar tables, and dynamic trend analysis.

---

## 🔍 SQL Scripts Breakdown

### 1. `01_data_cleaning_and_exploration.sql`
* **Data Auditing:** Evaluates missing values (`NULL` checks) across `CustomerID`, `TerritoryID`, and order amounts.
* **Text Standardizing:** Cleans and formats customer names using `CONCAT()` and `COALESCE()`.
* **Set Operations:** Uses `EXCEPT` to identify inventory products that have never recorded a transaction.

### 2. `02_advanced_analytics_window_functions.sql`
* **Multi-Level CTE:** Calculates unit margins, gross revenue, and product profitability categories.
* **Customer Deciles:** Segments top-performing customers into 10 deciles (`NTILE(10)`).
* **Explicit Window Framing:** Uses `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` for cumulative running totals, and `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` for moving 3-row averages.

### 3. `03_database_objects_views_procedures.sql`
* **Reporting Views:** Implements `dbo.vw_CustomerTotals` for aggregated yearly/monthly reporting.
* **User-Defined Functions (UDF):** Develops string sanitization (`fn_RemoveNumbers`) and phone number formatting (`fn_FormatPhone`).
* **Stored Procedures:** Constructs parameterized procedure `dbo.usp_ProductSales` with `OUTPUT` parameters for downstream integration.
