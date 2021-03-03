/*	CHAPTER 7 SOLUTION	*/

-- Write a query against the dbo.Orders table that computes both a rank and a dense rank for each
-- customer order, partitioned by custid and ordered by qty:

SELECT custid, orderid, qty,
	RANK() OVER(PARTITION BY custid
					ORDER BY qty) AS rnk,
	DENSE_RANK() OVER(PARTITION BY custid
						ORDER BY qty) AS drnk 
FROM dbo.Orders;

-- Find an alternative way to return distinct values and their associated row numbers in
-- Sales.OrderValues view

-- 1st method

SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;

-- 2nd method

WITH C AS
(
	SELECT DISTINCT val
	FROM Sales.OrderValues
)
SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM C;

-- Write a query against the dbo.Orders table that computes for each customer order both the
-- difference between the current order quantity and the customer ’s previous order quantity and
-- the difference between the current order quantity and the customer ’s next order quantity:

SELECT custid, orderid, qty,
	qty - LAG(qty) OVER(PARTITION BY custid
							ORDER BY orderdate, orderid) AS diffprev,
	qty - LEAD(qty) OVER(PARTITION BY custid
							ORDER BY orderdate, orderid) AS diffnext

FROM dbo.Orders;

-- Write a query against the dbo.Orders table that returns a row for each employee, a column for
-- each order year, and the count of orders for each employee and order year:

SELECT DISTINCT YEAR(orderdate)
FROM dbo.Orders;

-- 1st method

WITH CTE_Order 
AS
(
	SELECT empid, YEAR(orderdate) AS orderyear, orderid
	FROM dbo.Orders
)
SELECT empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016 
FROM CTE_Order
	PIVOT(COUNT(orderid) FOR orderyear IN ([2014], [2015], [2016])) AS T;

-- 2nd method

SELECT empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016 
FROM (SELECT empid, YEAR(orderdate) AS orderyear, orderid
		FROM dbo.Orders) AS D
			PIVOT(COUNT(orderid) FOR orderyear IN ([2014], [2015], [2016])) AS T;

-- Run the below query

USE TSQLV4;

IF OBJECT_ID('dbo.EmpYearOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpYearOrders;

CREATE TABLE dbo.EmpYearOrders
(
	empid INT NOT NULL 
		CONSTRAINT PK_EmpYearOrders PRIMARY KEY,
	cnt2014 INT NOT NULL,
	cnt2015 INT NOT NULL,
	cnt2016 INT NOT NULL
);

INSERT INTO dbo.EmpYearOrders(empid, cnt2014, cnt2015, cnt2016)
	SELECT empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016 
	FROM (SELECT empid, YEAR(orderdate) AS orderyear
		FROM dbo.Orders) AS D
			PIVOT(COUNT(orderyear) FOR orderyear IN ([2014], [2015], [2016])) AS T;

-- Write a query against the EmpYearOrders table that unpivots the data, returning a row for
-- each employee and order year with the number of orders. Exclude rows in which the number
-- of orders is 0 (in this example, employee 3 in the year 2015).

SELECT *
FROM dbo.EmpYearOrders;

-- 1st method

SELECT empid, numorders, SUBSTRING(orderyear,4, 7) AS orderyear
FROM dbo.EmpYearOrders
	UNPIVOT(numorders FOR orderyear IN(cnt2014, cnt2015, cnt2016)) AS T
WHERE numorders <> 0;

-- 2nd method

SELECT empid, orderyear, numorders
FROM dbo.EmpYearOrders
	CROSS APPLY (VALUES(2014, cnt2014),
						(2015, cnt2015),
						(2016, cnt2016)) AS A(orderyear, numorders)
WHERE numorders <> 0;

-- Write a query against the dbo.Orders table that returns the total quantities for each of the
-- following: (employee, customer, and order year), (employee and order year), and (customer
-- and order year). Include a result column in the output that uniquely identifies the grouping set
-- with which the current row is associated:

SELECT 
	GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
	empid, custid, YEAR(orderdate) AS orderyear, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
		(
			(empid, custid, YEAR(orderdate)),
			(empid, YEAR(orderdate)),
			(custid, YEAR(orderdate))	
		);


IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;