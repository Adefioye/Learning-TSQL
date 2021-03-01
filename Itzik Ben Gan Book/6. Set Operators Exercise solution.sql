/* Solution to chapter 6 set operators	*/

-- Write a query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10
-- without using a looping construct. You do not need to guarantee any order of the rows in the
-- output of your solution:

-- Method 1 using UNION ALL operator

SELECT 1 AS n
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
UNION ALL SELECT 9
UNION ALL SELECT 10;

/*
	Method 2 using VALUES clause

VALUES clause does not have to be used for a single row, it can be used for multiple rows as
well. It is also not restricted to INSERT statements but can be used to define a table expression
with rows based on constants.
*/

SELECT n
FROM (VALUES(1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS Nums(n);

-- Write a query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10
-- without using a looping construct. You do not need to guarantee any order of the rows in the
-- output of your solution:

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160101' AND '20160131'
EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160201' AND '20160229';

-- Write a query that returns customer and employee pairs that had order activity in both January
-- 2016 and February 2016: 

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160101' AND '20160131'
	INTERSECT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160201' AND '20160229'
	EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160201' AND '20160229';

-- Write a query that returns customer and employee pairs that had order activity in both January
-- 2016 and February 2016 but not in 2015:

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160101' AND '20160131'
	INTERSECT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160201' AND '20160229'
	EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20150101' AND '20151231';

-- 2nd method

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160101' AND '20160131'
	INTERSECT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20160201' AND '20160229'
	EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate LIKE '%2015%';

-- You are given the following query: The task is to ensure the return of rows from Employees
-- table before Suppliers table. Also within each segment, the rows should be sorted by
-- country, region and city.

SELECT country, region, city
FROM HR.Employees
UNION ALL
SELECT country, region, city
FROM Production.Suppliers;

WITH UNION_ALL
AS
(
	SELECT 1 AS sortcol, country, region, city
	FROM HR.Employees

	UNION ALL

	SELECT 2, country, region, city
	FROM Production.Suppliers
)
SELECT country, region, city
FROM UNION_ALL
ORDER BY sortcol, country, region, city;