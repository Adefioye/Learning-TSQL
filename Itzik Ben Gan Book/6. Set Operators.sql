/*	SET OPERATORS	

Set operators combine rows from 2 query result sets(or multisets). Some of the operators
remove duplicates returning a set, some do not resulting a multiset. T-SQL supports the following 
operators: UNION, UNION ALL, INTERSECT and EXCEPT. The general form of the operators is shown 
below.

Syntax: General form shown below
	Input Query1
	<set_operator>
	Input Query2
	[ORDER BY ...] 

Generally, a set operator expects multisets as input queries. therefore, ORDER BY clause cannot
be used in the input queries because this results in a cursor. However, there are some ways
to circumvent this, that would be shown later.

 UNION and UNION ALL

 UNION and UNION ALL unifies all results from the input queries with dplicates and without duplicates
 respectively. Therefore, UNION operator returns a set while UNION ALL operator returns a
 multiset.

*/

-- The below returns all locations of employees and customers with duplicates

USE TSQLV4;

SELECT country, region, city FROM HR.Employees
UNION ALL
SELECT country, region, city FROM Sales.Customers;

-- The below returns all locations of employees and customers without duplicates

SELECT country, region, city FROM HR.Employees
UNION
SELECT country, region, city FROM Sales.Customers;

-- The below returns distinct locations that are both employee locations and customer locations

SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

/*
T-SQL does not yet support INTERSECT ALL operator. That is returning the duplicates of the 
INTERSECT operator. INTERSECT Operator returns min(m, n) where m and n are occurences of 
a row in both input queries.

For example, the location (UK, NULL, London) appears four times in Employees and
six times in Customers; hence, INTERSECT ALL returns four occurrences in the output.

Since, T-SQL has no INTERSECT ALL operator. A workaround is to use the ROW_NUMBER function.
To show that there is no order when using the PARTITIONING, we use SELECT <constant>.

	EXCEPT and EXCEPT ALL operator 
	
EXCEPT operator is noncommutative, that is, the order in which you specify the input
queries matter.

EXCEPT ALL operator work such that, the operator returns rows in query 1 (x - y) times.
Where, x is the occurence of s specific row in query 1 and y is occurence of the rows in
query 2.

*/

-- USing ROW_NUMBER function to implement the INTERSECT ALL operation

SELECT
	ROW_NUMBER()
		OVER(PARTITION BY country, region, city
				ORDER BY (SELECT 0)) AS rownum,
	country, region, city
FROM HR.Employees

INTERSECT

SELECT
	ROW_NUMBER()
		OVER(PARTITION BY country, region, city
				ORDER BY (SELECT 0)) AS rownum,
	country, region, city
FROM Sales.Customers;

-- Lets use CTE so we can extract just the info on location with row numbers

WITH INTERSECT_ALL
AS
(
	SELECT
		ROW_NUMBER()
			OVER(PARTITION BY country, region, city
					ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM HR.Employees

	INTERSECT

	SELECT
		ROW_NUMBER()
			OVER(PARTITION BY country, region, city
					ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city
FROM INTERSECT_ALL;


-- The below returns employee locations where there are no customers

SELECT country, region, city FROM Sales.Customers
EXCEPT
SELECT country, region, city FROM HR.Employees;

-- The below returns customer locations where there are no employees

SELECT country, region, city FROM HR.Employees
EXCEPT
SELECT country, region, city FROM Sales.Customers;


-- Implementation of EXCEPT_ALL using ROW_NUMBER function

WITH EXCEPT_ALL
AS
(
	SELECT
		ROW_NUMBER()
			OVER(PARTITION BY country, region, city
					ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM HR.Employees

	EXCEPT

	SELECT
		ROW_NUMBER()
			OVER(PARTITION BY country, region, city
					ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city
FROM EXCEPT_ALL;



