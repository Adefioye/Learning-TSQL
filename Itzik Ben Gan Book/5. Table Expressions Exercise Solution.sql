/*	Chapter 5 solution	*/

/*
The following query attempts to filter orders that were not placed on the last day of the year.
It’s supposed to return the order ID, order date, customer ID, employee ID, and respective
end-of-year date for each order:
*/

SELECT orderid, orderdate, custid, empid,
	DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> endofyear;

-- This is a classic logical processing error

-- Solution 1

SELECT orderid, orderdate, custid, empid,
	DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> DATEFROMPARTS(YEAR(orderdate), 12, 31);

-- Solution 2 using derived tables

SELECT orderid, orderdate, custid, empid, endofyear
FROM (SELECT orderid, orderdate, custid, empid, 
			DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
		FROM Sales.Orders) AS A
WHERE orderdate <> endofyear;


-- Write a query that returns the maximum value in the orderdate column for each employee:

-- First solution

SELECT DISTINCT empid, 
	(SELECT MAX(OD.orderdate)
		FROM Sales.Orders OD
		WHERE O.empid = OD.empid) AS maxorderdate
FROM Sales.Orders O;

-- Second solution

SELECT empid, MAX(orderdate)
FROM Sales.Orders
GROUP BY empid;

-- Encapsulate the query from above in a derived table. Write a join query between the
-- derived table and the Orders table to return the orders with the maximum order date for each
-- employee:

SELECT O1.empid, O1.custid, O1.orderdate, O1.orderid
FROM Sales.Orders O1 INNER JOIN (SELECT DISTINCT 
									empid, (SELECT MAX(OD.orderdate)
											FROM Sales.Orders OD
											WHERE O.empid = OD.empid) AS maxorderdate
								 FROM Sales.Orders O) AS A
	ON O1.empid = A.empid AND O1.orderdate = A.maxorderdate;


-- Write a query that calculates a row number for each order based on orderdate, orderid
-- ordering:

SELECT 
	orderid, orderdate, custid, empid, 
	ROW_NUMBER() OVER(ORDER BY orderid, orderdate) AS rownum
FROM Sales.Orders;

-- Write a query that returns rows with row numbers 11 through 20 based on the row-number
-- definition above. Use a CTE to encapsulate the code from above

WITH CTE_Orders_11_20 AS 
(
	SELECT 
		orderid, orderdate, custid, empid, 
		ROW_NUMBER() OVER(ORDER BY orderid, orderdate) AS rownum
	FROM Sales.Orders
)
SELECT
	orderid, orderdate, custid, empid, rownum
FROM CTE_Orders_11_20
WHERE rownum BETWEEN 11 AND 20;

-- Write a solution using a recursive CTE that returns the management chain leading to Patricia
-- Doyle (employee ID 9):

WITH CTE_Emp_9 AS
(
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 9

	UNION ALL

	SELECT E.empid, E.mgrid, E.firstname, E.lastname
	FROM CTE_Emp_9 AS P INNER JOIN HR.Employees AS E
		ON E.empid = P.mgrid
)
SELECT 
	empid, mgrid, firstname, lastname
FROM CTE_Emp_9;

-- Create a view that returns the total quantity for each employee and year:

IF OBJECT_ID('Sales.VEmpOrders', 'U') IS NOT NULL DROP VIEW Sales.VEmpOrders;
GO

CREATE VIEW Sales.VEmpOrders
AS

SELECT O.empid, YEAR(O.orderdate) AS orderyear, SUM(OD.qty) AS qty
FROM Sales.Orders AS O INNER JOIN Sales.OrderDetails AS OD
	ON O.orderid = OD.orderid
GROUP BY O.empid, YEAR(O.orderdate);
GO

-- Query the view as shown below

SELECT * FROM Sales.VEmpOrders ORDER BY empid, orderyear;

-- Write a query against Sales.VEmpOrders that returns the running total quantity for each
-- employee and year:

SELECT 
	empid, orderyear, qty,
		(SELECT SUM(V2.qty)
			FROM Sales.VEmpOrders AS V2
			WHERE V1.empid = V2.empid AND V1.orderyear >= V2.orderyear) AS runqty
FROM Sales.VEmpOrders AS V1
ORDER BY empid, orderyear;

-- Create an inline TVF that accepts as inputs a supplier ID (@supid AS INT) and a requested
-- number of products (@n AS INT). The function should return @n products with the highest
-- unit prices that are supplied by the specified supplier ID:

IF OBJECT_ID('Production.TopProducts', 'U') IS NOT NULL DROP FUNCTION Production.TopProducts;
GO
CREATE FUNCTION Production.TopProducts
	(@supid AS INT, @n AS INT) 
	RETURNS TABLE
AS
RETURN
	SELECT TOP (@n)
		productid, productname, unitprice
	FROM Production.Products
	WHERE supplierid = @supid
	ORDER BY unitprice DESC;
GO

SELECT * FROM Production.TopProducts(5, 2);

-- Using the CROSS APPLY operator and the function you created above, return the two
-- most expensive products for each supplier:

SELECT S.supplierid, S.companyname, T.productid, T.productid, T.unitprice
FROM Production.Suppliers AS S
	CROSS APPLY
		Production.TopProducts(S.supplierid, 2) AS T;