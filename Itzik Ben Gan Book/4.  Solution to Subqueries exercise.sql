/* CHAPTER 4 EXERCISE SOLUTION	*/

-- Write a query that returns all orders placed on the last day of activity that can be found in the
-- Orders table:

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
						FROM Sales.Orders O2);


-- Write a query that returns all orders placed by the customer(s) who placed the highest number
-- of orders. Note that more than one customer might have the same number of orders:

SELECT custid, orderid, orderdate, empid
FROM (SELECT TOP (1) WITH TIES
	custid, orderid, orderdate, empid,
	(SELECT SUM(O2.orderid)
	FROM Sales.Orders O2
	WHERE O1.custid = O2.custid) AS num_of_orders
FROM Sales.Orders O1
ORDER BY num_of_orders DESC) AS T1;


-- Write a query that returns employees who did not place orders on or after May 1, 2016:
--Keep trying

SELECT empid, firstname, lastname
FROM HR.Employees E
WHERE NOT EXISTS (SELECT O.empid
					FROM Sales.Orders O
					WHERE O.orderdate < '20160501'); -- Placed orders less than '20160501'


-- Write a query that returns for each customer all orders placed on the customer’s last day of
-- activity:

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
					FROM Sales.Orders O2
					WHERE O1.custid = O2.custid)
ORDER BY custid;


