/*CHAPTER 2*/

/*Single table queries*/

USE TSQLV4;

SELECT empid, YEAR(orderdate) AS order_year, COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, order_year;

/*
The ORder of processing is showed below:

FROM 
WHERE
GROUP BY
HAVING 
SELECT
ORDER BY
*/

/*The below code returns all rows in Orders table and the 5 attributes specified in 
the SELECT statement */

SELECT empid, YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);

/*Attributes that are not in GROUP BY function are allowed only as INPUT in 
aggregate functions

Note that aggregate functions ignore NULLs except COUNT(*) which returns the
number of rows per group 
*/

SELECT
	empid,
	YEAR(orderdate) AS order_year,
	SUM(freight) AS total_freight,
	COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)

/*Return the number of unique customers return by each employee for each order year*/

SELECT
	empid,
	YEAR(orderdate) AS order_year,
	COUNT(DISTINCT custid) num_of_customers
FROM Sales.Orders
GROUP BY empid, YEAR(orderdate)

/*Using Having clause*/

SELECT 
	empid,
	YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1

/*Using AS as alias for a new column or renaming a new column is important
because the other for (<expression <alias>) has a special way of causing unintended 
problems in code.

IF comma between 2 columns is ommitted, the second column is gonna be taking as alias of 
the first column.
*/

SELECT orderid orderdate
FROM Sales.Orders;

SELECT 
	empid,
	YEAR(orderdate) AS order_year,
	COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;