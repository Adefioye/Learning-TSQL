/* CHAPTER 2 EXERCISES AND SOLUTIONS*/

/*
Write a query against the Sales.Orders table that returns orders placed in June 2015:
*/

/*1st method*/

SELECT orderid, custid, orderdate, empid 
FROM Sales.Orders
WHERE orderdate >= '20150601' AND orderdate < '20150701';

/*2nd method*/
SELECT orderid, custid, orderdate, empid 
FROM Sales.Orders
WHERE orderdate LIKE '_____06%';

/*3rd method*/
SELECT orderid, custid, orderdate, empid 
FROM Sales.Orders
WHERE orderdate LIKE '_____06___';


/*
Write a query against the Sales.Orders table that returns orders placed on the last day of the
month:
*/


SELECT orderid, custid, orderdate, empid 
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);


/*
Write a query against the HR.Employees table that returns employees with a last name
containing the letter e twice or more:
*/

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE '%e%e%';


/*
Write a query against the Sales.OrderDetails table that returns orders with a total value
(quantity * unitprice) greater than 10,000, sorted by total value:
*/

SELECT orderid, SUM(qty * unitprice) AS total_value
FROM Sales.OrderDetails
GROUP BY orderid
HAVING SUM(qty * unitprice) > 10000
ORDER BY total_value;


/* 
Write a query against the HR.Employees table that returns
employees with a last name that starts with a lowercase English letter in the range a through z.
Remember that the collation of the sample database is case insensitive
(Latin1_General_CI_AS):
*/

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS = '[a-z]%';


/*
Explain the difference between the following two queries:
*/

-- Query 1

-- The below query returns num_of_orders processed by each employee on 1st may, 2015.

SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
WHERE orderdate < '20160501'
GROUP BY empid;

-- Query 2

--The below query returns num_of_orders processed by each employee before 1st may, 2015.

SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20160501';


/* Write a query against the Sales.Orders table that returns the three shipped-to countries with the
highest average freight in 2015:*/

-- 1st method

SELECT TOP 3
	shipcountry, AVG(freight) AS avg_freight
FROM Sales.Orders
WHERE orderdate LIKE '2015%'
GROUP BY shipcountry
ORDER BY avg_freight DESC;

-- 2nd method

SELECT TOP 3
	shipcountry, AVG(freight) AS avg_freight
FROM Sales.Orders
WHERE YEAR(orderdate) = 2015
GROUP BY shipcountry
ORDER BY avg_freight DESC;


/*
Write a query against the Sales.Orders table that calculates row numbers for orders based on
order date ordering (using the order ID as the tiebreaker) for each customer separately:
*/

SELECT custid, orderdate, orderid, 
	ROW_NUMBER() OVER(PARTITION BY custid
						ORDER BY orderdate, orderid) AS row_num
FROM Sales.Orders;


/*
write a SELECT statement that returns for each employee the
gender based on the title of courtesy. For ‘Ms.’ and ‘Mrs.’ return ‘Female’; for ‘Mr.’ return
‘Male’; and in all other cases (for example, ‘Dr.‘) return ‘Unknown’:
*/

SELECT empid, firstname, lastname, titleofcourtesy,
	CASE titleofcourtesy
		WHEN 'Ms.'  THEN 'Female'
		WHEN 'Mrs.' THEN 'Female'
		WHEN 'Mr.'  THEN 'Male'
		ELSE 'Unknown'
	END AS gender		
FROM HR.Employees;
