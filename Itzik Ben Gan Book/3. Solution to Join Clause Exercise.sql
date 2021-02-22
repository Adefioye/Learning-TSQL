/* CHAPTER 3 Exercise solution	*/

-- Write a query that generates five copies of each employee row:
-- Using HR.Employees and dbo.Nums

SELECT E.empid, E.firstname, E.lastname, N.n AS n
FROM dbo.Nums AS N
	CROSS JOIN HR.Employees E
WHERE N.n <=5;


-- Write a query that returns a row for each employee and day in the range June 12, 2016
-- through June 16, 2016:

SELECT E.empid, CAST(DATEADD(DAY, N.n - 1, '20160612') AS DATE) AS dt
FROM HR.Employees AS E
	CROSS JOIN dbo.Nums AS N
WHERE N.n <= DATEDIFF(DAY, '20160612', '20160616') + 1
ORDER BY E.empid;

-- Rewriting the query to properly reference the aliases of the Orders and Customers table

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O ON C.custid = O.custid;


-- Return US customers, and for each customer return the total number of orders and total
-- quantities: Sales.Customers, Sales.Orders, and Sales.OrderDetails


SELECT 
	C.custid,
	COUNT(DISTINCT OD.orderid) AS num_of_orders,
	SUM(OD.qty) AS total_qty
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O 
	ON ((C.custid = O.custid) AND (C.country = 'USA'))
	LEFT JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
GROUP BY C.custid;

-- Return customers and their orders, including customers who placed no orders:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
	ON C.custid = O.custid;


-- Return customers who placed no orders:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderid IS NULL;


-- Return customers with orders placed on February 12, 2016, along with their orders:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderdate = '20160212';

-- Write a query that returns all customers in the output, but matches them with their respective
-- orders only if they were placed on February 12, 2016:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
		ON (C.custid = O.custid AND O.orderdate = '20160212');


-- Return all customers, and for each return a Yes/No value depending on whether the customer
-- placed orders on February 12, 2016:


SELECT C.custid, C.companyname, 
	CASE 
		WHEN O.orderid IS NULL THEN 'No'
		ELSE 'Yes'
	END AS Has_Order_on_20160212
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
		ON (C.custid = O.custid AND O.orderdate = '20160212')
ORDER BY C.custid;
