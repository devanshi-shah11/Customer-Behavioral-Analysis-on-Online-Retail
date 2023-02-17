-- INST754 - Devanshi Shah - CUSTOMER BEHAVIORAL ANALYSIS.
-- Step 1 - Analysis of the data

SELECT * FROM [Datadb].[dbo].[online_retail_main]

-- a) I calculated the total number of products, transactions, and customers in the data, 
-- which correspond to the total unique stock codes, invoice number, and customer IDs present in the data. 
-- Products = 3958 , Transactions = 25900 , No. of customers = 4372

SELECT COUNT(DISTINCT(StockCode)) AS 'Products1', COUNT(DISTINCT(InvoiceNo)) As 'Transcations1', 
          COUNT(DISTINCT(CustomerID)) AS 'No. of Customers1'  FROM [Datadb].[dbo].[online_retail_main]
          
-- Conclusion from a) - Each product is likely to have multiple transactions in the data. There are almost as many products as customers in the data as well.
-- Now the data is extracted and uploaded in PowerBI for the calculation of the country with the highest % of orders.
-- United Kingdom has the highest number of sales among all the countries -- about 92%
-- More than 90% of orders are coming from United Kingdom and no other country even makes up 3% of the orders in the data.

-- Step 2-  Cleaning Data 
--  Initally, Total rows = 541909
-- CustomerID is null = 135080
-- 406829 Records have CustomerID

;with online_retail as 
(
SELECT [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [Datadb].[dbo].[online_retail_main]
  WHERE CustomerID is NOT NULL
 )
 , quantity_unit_Price as 

(
-- I filtered the rows and removed Quantities and Unit Price values < 0, here the quanities which are negative means that the quantities were not returned. 
-- 397884 rows with quantity and unit price > 0 
SELECT * 
FROM online_retail 
WHERE Quantity > 0 and UnitPrice > 0 
)
, checking_duplicates as 

(
-- Checking for duplicate values 

SELECT * , ROW_NUMBER() OVER ( PARTITION BY  InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) dup 
FROM quantity_unit_Price
)
-- I have 392669 clean data records 
-- Removed 5215 duplicate records from the data
SELECT * INTO #online_retail_temp
FROM checking_duplicates
WHERE dup = 1

-- I calculated the total number of products, transactions, and customers in the data after removing duplicates.
-- Products = 3665 , Transactions = 18532 , No. of customers = 4338

SELECT COUNT(DISTINCT(StockCode)) AS 'Products', COUNT(DISTINCT(InvoiceNo)) As 'Transcations', 
          COUNT(DISTINCT(CustomerID)) AS 'No. of Customers'  FROM #online_retail_temp

-- Step 3- Customer Cohort Analysis
SELECT * FROM #online_retail_temp

SELECT CustomerID, min(InvoiceDate) AS 'first_purchase_date',
   DATEFROMPARTS(year(min(InvoiceDate)), month(min(InvoiceDate)),1) AS Cohort_Date
   into #cohort
FROM #online_retail_temp
GROUP BY CustomerID

SELECT * FROM #cohort

-- Creating Cohort Index
SELECT 
  ttt.*,
  cohortindex = yrdiff * 12 + mthdiff + 1

-- if cohort index = 1, then the customer made their next purchase in the same month after the first purchase
INTO #cohortretention 
FROM 

(SELECT
tt.*,
yrdiff = invoiceyr - cohortyr,
mthdiff = invoicemth - cohortmth
FROM(
SELECT 
t.*, 
x.Cohort_Date,
year(t.InvoiceDate) invoiceyr,
month(t.InvoiceDate) invoicemth,
year(x.Cohort_Date) cohortyr,
month(x.Cohort_Date) cohortmth
FROM #online_retail_temp t
LEFT JOIN #cohort x
    ON t.CustomerID = x.CustomerID
) tt
) ttt

SELECT * FROM #cohortretention

-- The data from #cohortretention is then extracted as a .csv file and uploaded into PowerBI for further data visualization.