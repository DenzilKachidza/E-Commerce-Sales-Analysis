-- Checking for nulls
SELECT
	COUNT(*) AS TotalRows,
	SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID,
	SUM(CASE WHEN Description IS NULL OR Description = '' THEN 1 ELSE 0 END) AS  MissingDescription,
	SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceDate
FROM dbo.Sales;

-- Checking negatives (returns)
SELECT 
	COUNT(*) AS ReturnsCount
FROM dbo.Sales
WHERE Quantity < 0;

-- Replace empty string with NULL
UPDATE dbo.Sales
SET CustomerID = NULL
WHERE CustomerID = '';


-- Seperating the returns
ALTER TABLE dbo.Sales
ADD IsReturn BIT;

UPDATE dbo.Sales
SET IsReturn = CASE WHEN Quantity < 0 THEN 1 ELSE 0 END;

SELECT *
FROM dbo.Sales

-- Standardize dates
-- adding year and month column
ALTER TABLE dbo.Sales
ADD InvoiceYear INT,
	InvoiceMonth INT;

UPDATE dbo.Sales
SET InvoiceYear = YEAR(InvoiceDate),
    InvoiceMonth = MONTH(InvoiceDate);

SELECT *
FROM dbo.Sales
ORDER BY InvoiceYear ASC;

-- Adding a revenue column and calculating
ALTER TABLE dbo.Sales
ADD Revenue AS (Quantity * Price);

SELECT *
FROM dbo.Sales

-- Adding catergories for tableau
ALTER TABLE dbo.Sales
ADD ProductCategory NVARCHAR(50);

UPDATE dbo.Sales
SET ProductCategory = CASE 
    WHEN Description LIKE '%HEART%' THEN 'Home Decor'
    WHEN Description LIKE '%CANDLE%' THEN 'Home Decor'
    WHEN Description LIKE '%PEN%' THEN 'Stationery'
    ELSE 'Other'
END;
SELECT *
FROM dbo.Sales

-- Total revenue
SELECT ROUND(SUM(Revenue),2) AS TotalRevenue
FROM dbo.Sales;

-- Revenue by country
SELECT Country, ROUND(SUM(Revenue),2) AS CountryRevenue
FROM dbo.Sales
GROUP BY Country
ORDER BY CountryRevenue DESC;

-- Monthly revenue trend
SELECT 
    InvoiceYear,
    InvoiceMonth, 
    ROUND(SUM(Revenue),2) AS MonthlyRevenue
FROM dbo.Sales
GROUP BY InvoiceYear, InvoiceMonth
ORDER BY InvoiceYear, InvoiceMonth;


-- Which products (Descriptions) generate the most revenue?
SELECT 
    Description,
    ROUND(SUM(Revenue),2) AS TotalRevenue
FROM dbo.Sales
WHERE IsReturn = 0 
GROUP BY Description
ORDER BY TotalRevenue DESC;

-- Which customers spend the most?
SELECT 
    CustomerID,
    ROUND(SUM(Revenue),2) AS TotalSpent,
    COUNT(DISTINCT Invoice) AS OrdersCount
FROM dbo.Sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

-- Who are repeat customers?
SELECT 
    CustomerID,
    COUNT(DISTINCT Invoice) AS PurchaseFrequency
FROM dbo.Sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(DISTINCT Invoice) > 1
ORDER BY PurchaseFrequency DESC;

-- Top customers and order count
SELECT
  CustomerID,
  SUM(Quantity * Price) AS TotalSpent,
  COUNT(DISTINCT Invoice) AS OrdersCount
FROM dbo.Sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;

-- Which countries generate the most revenue?
SELECT 
    Country,
    ROUND(SUM(Revenue),2) AS TotalRevenue,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM dbo.Sales
GROUP BY Country
ORDER BY TotalRevenue DESC;

-- Monthly revenue (gives a real date for Tableau)
CREATE OR ALTER VIEW dbo.v_RevenueMonthly AS
SELECT
  DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1) AS MonthStart,
  SUM(Quantity * Price) AS TotalRevenue
FROM dbo.Sales
WHERE InvoiceDate IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1);


-- Top products by revenue
CREATE OR ALTER VIEW dbo.v_TopProducts AS
SELECT
  Description,
  SUM(Quantity * Price) AS TotalRevenue
FROM dbo.Sales
WHERE ISNULL(IsReturn,0) = 0
GROUP BY Description;

-- Top customers and order count
CREATE OR ALTER VIEW dbo.v_TopCustomers AS
SELECT
  CustomerID,
  SUM(Quantity * Price) AS TotalSpent,
  COUNT(DISTINCT Invoice) AS OrdersCount
FROM dbo.Sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;


-- Country revenue
CREATE OR ALTER VIEW dbo.v_CountryRevenue AS
SELECT
  Country,
  SUM(Quantity * Price) AS TotalRevenue,
  COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM dbo.Sales
GROUP BY Country;

