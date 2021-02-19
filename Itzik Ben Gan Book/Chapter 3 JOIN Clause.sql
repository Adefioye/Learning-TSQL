-- CROSS JOINS (cartesian product)

SELECT C.custid, E.empid
FROM Sales.Customers AS C CROSS JOIN HR.Employees AS E;

/*
	SELF CROSS JOINS
Joining multiple instances of the same table. The below query performs self cross join between
tow instances of then Employees table.

in a self join, aliasing table is not optional. Without it, column names in thne result of the
join would be ambiguous.
*/

SELECT
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1 CROSS JOIN HR.Employees AS E2;

/*
Use case for cross join. Generating table with rows of 1000 from a table of 10 rows.
Each row represent different powers of 10 (1, 10, 100). The below produces a sequence of
1,000 integers. If we want 1,000,000 rows, we should join six instances.
*/

IF OBJECT_ID(N'dbo.Digits', N'U') IS NOT NULL DROP TABLE dbo.Digits;

-- DROP TABLE IF EXISTS dbo.Digits;
CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.Digits(digit)
	VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT digit FROM dbo.Digits;

SELECT D3.digit * 100 + D2.digit * 10 + D1.digit + 1 AS n
FROM		   dbo.Digits AS D1
	CROSS JOIN dbo.Digits AS D2
	CROSS JOIN dbo.Digits AS D3
ORDER BY n;

/*
	INNER JOIN
This applies cartesian product and filtering based on predicate supplied in the ON clause.

the following query performs an inner join between the Employees and Orders tables.
 matching employees and orders based on the predicate E.empid = O.empid:
*/

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
	INNER JOIN Sales.Orders AS O ON E.empid = O.empid;

/*
	COMPOSITE JOIN
This is used when tables are joined on multiple attributes. This is usuall as a result of the 
fact that two tables are related by a composite key.

The query below join 2 tables based on perimary key-foreign key relationship
*/

IF OBJECT_ID(N'Sales.OrderDetailsAudit', N'U') IS NOT NULL DROP TABLE Sales.OrderDetailsAudit;

CREATE TABLE Sales.OrderDetailsAudit
	(
		lsn INT NOT NULL IDENTITY,
		orderid INT NOT NULL,
		productid INT NOT NULL,
		dt DATETIME NOT NULL,
		loginname sysname NOT NULL,
		columnname sysname NOT NULL,
		oldval SQL_VARIANT,
		newval SQL_VARIANT,
		CONSTRAINT PK_OrderDetailsAudit PRIMARY KEY(lsn),
		CONSTRAINT FK_OrderDetailsAudit_OrderDetails
			FOREIGN KEY(orderid, productid)
			REFERENCES Sales.OrderDetails(orderid, productid)
	);

SELECT OD.orderid, OD.productid, OD.qty, ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM Sales.OrderDetails AS OD
	INNER JOIN Sales.OrderDetailsAudit AS ODA
	ON OD.orderid = ODA.orderid AND OD.productid = ODA.productid
WHERE ODA.columnname = 'qty';

/*
	NON-EQUI JOIN
This occurs when the JOIN predicate does not have '=' SIGN.
*/

-- Thne query below filters self pairs (1 and 1) and only retain one of mirror pairs
-- (1 and 2 / 2 and 1) where the left is less than 

SELECT
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
	INNER JOIN HR.Employees AS E2 ON E1.empid < E2.empid;

SELECT
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
	INNER JOIN HR.Employees AS E2 ON E1.empid = E2.empid;

/*
	OUTER JOIN
This performs 3 logical processin steps as follows for 2 tables: First, cartesian product,
filtering on The ON clause and re-adding of the filtered rows from the 2nd phase.

The below returns customers that did not place any orders.

	ADVANCED USES OF OUTER JOIN
It can be used to identify and include missing values when querying data.
Another use case is that it can be used to generate date within a certain range.

NOTE: Filtering attributes from the unpreserved side of an OUTER JOIN results in the 
filtering of the outer rows. because values on the outer rows evaluate to UNKNOWN as they
contain NULL. And where clause filters out UNKNOWN.
*/

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O ON C.custid = O.custid
WHERE O.orderid IS NULL;

-- Query returns sequence of dates between Jan 1, 2014 and Dec 31, 2016.

SELECT DATEADD(DAY, n - 1, CAST('20140101' AS DATE)) AS order_date
FROM dbo.Nums
WHERE n <= DATEDIFF(DAY, '20140101', '20161231') + 1
ORDER BY order_date;

-- Using the query above to answer question of dates between the range above that are
-- not in the orders table

SELECT 
	DATEADD(DAY, N.n - 1, CAST('20140101' AS DATE)) AS order_date, O.orderid,
	O.custid, O.empid
FROM Sales.Orders O
	RIGHT JOIN dbo.Nums AS N 
	ON O.orderdate = DATEADD(DAY, N.n - 1, CAST('20140101' AS DATE)) 
WHERE N.n <= DATEDIFF(DAY, '20140101', '20161231') + 1
ORDER BY order_date;

-- COUNT(*) actually count NULL values
-- COUNT(column) does not count NULL values


SELECT C.custid, COUNT(O.orderid) AS num_of_orders
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O ON C.custid = O.custid
GROUP BY C.custid;
