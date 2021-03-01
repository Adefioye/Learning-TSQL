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


/*
	PRECEDENCE OF SET OPERATORS

INTERSECT operator precedes UNION and EXCEPT, and UNION and EXCEPT are evaluated in order
of appearance.

To control the order of evaluation of set operators, parentheses is used because they have 
the highest precedence. Also, using parentheses increases readability, tgus reducing the 
chance for errors.
*/


-- In the code below, INTERSECT is evaluated first even though it appears second.

-- THe query returns locations that are supplier locations but not in both employee and 
-- customers locations.

SELECT country, region, city FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- Using parentheses, to control order of precedence. For example, locations that are supplier
-- locations but not employee locations and that are also customer locations.

(SELECT country, region, city FROM Production.Suppliers
	EXCEPT
SELECT country, region, city FROM HR.Employees)
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- This also works just like the above

SELECT country, region, city FROM Production.Suppliers
INTERSECT
SELECT country, region, city FROM Sales.Customers
EXCEPT
SELECT country, region, city FROM HR.Employees;


/*
 CIRCUMVENTING UNSUPPORTED LOGICAL PHASES

Individual queries that are inputs to a set operator support logical processing phases such as
WHERE, GROUPBY and HAVING. However, they are not supported by the result of set operators.
Also, the inputs are not supported by ORDER BY clause. These can only be applied to the results of the set operators.

On another note, it is possible to circumvent the non-support of WHERE, GROUP BY and HAVING by 
the result of set operators. THis is done usually by using table expressions. Defining a table
expression based on a query with set operator, and apply any logical-query processing phases you
 want in the outer query.

 ORDER BY clause is not allowed in the input queries, but it can be accomodated inside table
 expressions. 
*/

-- the following query returns the number of distinct locations that are either employee or
-- customer locations in each country:

SELECT country, COUNT(*) AS numlocations
FROM (SELECT country, region, city FROM HR.Employees
	  UNION
	  SELECT country, region, city FROM Sales.Customers) AS U
GROUP BY country;


-- The following code uses TOP queries to return the two most recent orders for
-- employees 3 and 5:

SELECT empid, orderid, orderdate
FROM (SELECT TOP (2) empid, orderid, orderdate
		FROM Sales.Orders
		WHERE empid = 3
		ORDER BY orderdate DESC, orderid DESC) AS D1

UNION ALL

SELECT empid, orderid, orderdate
FROM (SELECT TOP (2) empid, orderid, orderdate
		FROM Sales.Orders
		WHERE empid = 5
		ORDER BY orderdate DESC, orderid DESC) AS D2;