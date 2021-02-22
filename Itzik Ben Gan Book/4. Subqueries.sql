/* Chapter 4 SUBQUERIES*/

/*
The outer query is the query whose result set is returned to the caller while subquery is the
inner query whose result set is fed as input to the outer query.

A subquery can either be self-contained or correlated. Self-contained query has no dependency
on the tables from the outer query. However, a correlated subquery does.

Sub-query can be single-valued, multivalued or table-valued. This means that can return a 
single value, multiple values, or a whole result table.

In this chapter, single-valued, multivalued subqueries are dealt with. Table-valued subquery 
is dealt with in Chapter 5(Table expressions).
*/

-- Using a variable to query Order table with the maximum Order ID.

USE TSQLV4;

DECLARE @maxid AS INT = (SELECT MAX(orderid)
						 FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid;

-- The self-contained subquery can also be specified directly in thw WHERE clause

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = (SELECT MAX(orderid)
				FROM Sales.Orders);

/*
It is important to note that when multiple values are returned by the query, = sign
is not appriate for the query.
*/

SELECT orderid
FROM Sales.Orders
WHERE empid = (SELECT E.empid
               FROM HR.Employees AS E
			   WHERE E.lastname LIKE N'D%');

/* 
The query above fails because the subquery returns more than one value.
The IN operator should be used isntead of '=' sign for self-contained multivalued 
subquery. Other operators that can be used are SOME, ANy and ALL. However, they are rarely
used
*/

-- The IN operator is used on the above query that failed.
SELECT orderid
FROM Sales.Orders
WHERE empid IN (SELECT E.empid
               FROM HR.Employees AS E
			   WHERE E.lastname LIKE N'D%');
 
 /*
 Query the Orders table that returns orders where the customer ID is in the set of customer
 IDs of customers from the united states
 */

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN (SELECT C.custid
				FROM Sales.Customers AS C
				WHERE C.country = N'USA');

/*
Like every other query, the IN operator can be negated using NOT IN operator.
We query the custid of the customers that do not placed orders.

in using subqueries, there is no need to use the DISTINCT clause to ensure that unique
customer IDs are returned. The database engine is smart enough to remove the duplicates.

*/

SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN (SELECT O.custid
					FROM Sales.Orders AS O);



-- Let us watch the use of multiple self-contained subqueries

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders(orderid INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);

INSERT INTO dbo.Orders(orderid)
	SELECT orderid
	FROM Sales.Orders
	WHERE orderid % 2 = 0;

-- Let us try to query order IDs that are missing between the minimum and maximum ones in a 
-- table. We use the popular dno.Nums table to solve this problem.

SELECT n
FROM dbo.Nums
WHERE n BETWEEN (SELECT MIN(orderid) FROM dbo.Orders) AND (SELECT MAX(orderid) FROM dbo.Orders)
		AND n NOT IN (SELECT orderid FROM dbo.Orders);


-- Clean up the TSQLV4 

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;


/*
Correlated Subqueries
*/

-- The query returns the info for each customer with the maximum orderid
SELECT O1.custid, O1.orderid, O1.orderdate, O1.empid
FROM Sales.Orders O1
WHERE O1.orderid = (SELECT MAX(O2.orderid)
					FROM Sales.Orders O2
					WHERE O1.custid = O2.custid)


-- For each customer, we wanna return the pct of each order value to the customers  value 
-- total

SELECT O1.orderid, O1.custid, O1.val, 
	CAST(100 * O1.val/ (SELECT SUM(O2.val)
					FROM Sales.OrderValues O2
					WHERE O1.custid = O2.custid)
					AS NUMERIC(5, 2)) AS pct
FROM Sales.OrderValues O1
ORDER BY custid, orderid;


/*
	EXISTS PREDICATE

T-SQL supports a predicate called EXISTS that accepts a subquery as input and returns TRUE
if the subquery returns any rows and FALSE otherwise.

Using EXISTS is a good optimization practice. The predicate cares only about matching rows.
Hence, the database knows when to short-circuit the code by not processing all qualifying rows.
.Using * in SELECT clause is not bad practice, considering the optimization of code with the
EXISTS predicate.

*/
-- The below returns customers from Spain who placed orders

SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.country = 'Spain'
	AND EXISTS
		(SELECT * 
		FROM Sales.Orders O
		WHERE C.custid = O.custid);

-- The customers from spain that did not place orders

SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.country = 'Spain'
	AND NOT EXISTS
		(SELECT * 
		FROM Sales.Orders O
		WHERE C.custid = O.custid);




/*			
		ADVANCED READING
Return the previous and next order value using correlated query.
 It is important to note that WINDOW FUNCTIONS can be used for this purpose. For example,
 LAG and LEAD function.
*/
-- Return the next order id for each order id. This essentially means the minimum value
-- higher than the current order id

SELECT orderid, orderdate, empid, custid,
	(SELECT MIN(O2.orderid)
	 FROM Sales.Orders O2
	 WHERE O2.orderid > O1.orderid) AS next_order_id
FROM Sales.Orders O1;

-- Return the previous order id for each order id. This essentially means the maximum value
-- lower than the current order id

SELECT orderid, orderdate, empid, custid,
	(SELECT MAX(O2.orderid)
	 FROM Sales.Orders O2
	 WHERE O2.orderid < O1.orderid) AS previous_order_id
FROM Sales.Orders O1;

-- RUnning aggregates
-- Compute the running total of quantity up until current year

SELECT orderyear, qty,
	(SELECT SUM(O2.qty)
	FROM Sales.OrderTotalsByYear O2
	WHERE O1.orderyear >= O2.orderyear) AS qty_running_total
FROM Sales.OrderTotalsByYear O1
ORDER BY orderyear;

/*
	NULL PROBLEM
*/

SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
					FROM Sales.Orders AS O);

-- Insert NULL values for custid

INSERT INTO Sales.Orders
			(custid, empid, orderdate, requireddate, shippeddate, shipperid,
				freight, shipname, shipaddress, shipcity, shipregion,
					shippostalcode, shipcountry)
VALUES
	(NULL, 1, '20160212', '20160212',
					'20160212', 1, 123.00, N'abc', N'abc', N'abc',
					N'abc', N'abc', N'abc');

SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
					FROM Sales.Orders AS O);

/*
The query above returns an empty set because of the presence of NULL in the subquery. When custid
are compared with other values including the NULL value. The engine is not sure whether the
custid is present. Why? It is possible that the NULL is the value and it may not be. Hence the
custids evaluate to unknown leading to the filtering of all unknown values.

To address this problem, we either use filter out the NULL in the subquery or use the NOT EXISTS
predicate that operate on just a 2-valued logic.
*/

-- Using the NOT IN operator with filtering of NULL in the subquery

SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
					FROM Sales.Orders AS O
					WHERE O.custid IS NOT NULL);

--

SELECT custid, companyname
FROM Sales.Customers C
WHERE NOT EXISTS(SELECT O.custid
				FROM Sales.Orders AS O
				WHERE C.custid = O.custid);


-- Run the following code for cleanup

DELETE FROM Sales.Orders WHERE custid IS NULL;


/*
		Substitution errors in subquery column names
*/

IF OBJECT_ID(N'Sales.MyShippers', N'U') IS NOT NULL DROP TABLE Sales.MyShippers;

CREATE TABLE Sales.MyShippers
(
	shipper_id INT NOT NULL,
	companyname NVARCHAR(40) NOT NULL,
	phone NVARCHAR(24) NOT NULL,
	CONSTRAINT PK_MyShippers PRIMARY KEY(shipper_id)
);

INSERT INTO Sales.MyShippers(shipper_id, companyname, phone)
	VALUES(1, N'Shipper GVSUA', N'(503) 555-0137'),
		  (2, N'Shipper ETYNR', N'(425) 555-0136'),
		  (3, N'Shipper ZHISN', N'(415) 555-0138');


-- This query returns Shippers that ship to customer with ID of 43

SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN (SELECT shipper_id
					FROM Sales.Orders
					WHERE custid = 43);

/*
The above query returns an incorrect result set. This is because an incorrect attribute name
is used in the subquery. "shipper_id" is used instead of "shipperid" that can be found in the
Sales.Orders table. 

The query returns all rowss in MyShippers table because when the database engine could not
find the attribe name in Sales.Orders table, it went to the outer table to find the attribute
. Unfortunately, there is an atrribute name with shipper_id in then outer table making all
rows to match.

This behavior is by SQL design which was adhered to by SQL server. To avoid this kind of problem,
It is advised to follow best practices. Example

- Using consistent attribute names across all tables
- Applying a prefix/alias on tables in a subquery 
*/

SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN (SELECT O.shipper_id
					FROM Sales.Orders AS O
					WHERE O.custid = 43);

-- When an alias is used, we can easily detect that the shipper_id is not in Sales.Orders
-- table. and we can easily fix the problem

SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN (SELECT O.shipperid
					FROM Sales.Orders AS O
					WHERE O.custid = 43);

