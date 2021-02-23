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

-- 2nd method

SELECT empid, firstname, lastname
FROM HR.Employees E
WHERE E.empid IN (
		(SELECT empid FROM Sales.Orders) 
		EXCEPT (SELECT empid FROM Sales.Orders WHERE orderdate >= '20160501'));


-- Write a query that returns countries where there are customers but not employees:

(SELECT country FROM Sales.Customers) EXCEPT (SELECT country FROM HR.Employees);

-- Write a query that returns for each customer all orders placed on the customer’s last day of
-- activity:

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
					FROM Sales.Orders O2
					WHERE O1.custid = O2.custid)
ORDER BY custid;


-- Write a query that returns customers who placed orders in 2015 but not in 2016:

-- 1st method

SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.custid IN ((SELECT O.custid FROM Sales.Orders O WHERE YEAR(O.orderdate) = 2015)
 EXCEPT (SELECT O.custid FROM Sales.Orders O WHERE YEAR(O.orderdate) = 2016))
ORDER BY custid;


-- Write a query that returns customers who ordered product 12:

SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.custid IN (SELECT O.custid
					FROM Sales.Orders O INNER JOIN Sales.OrderDetails OD
							ON O.orderid = OD.orderid
					WHERE OD.productid = 12);


-- Write a query that calculates a running-total quantity for each customer and month:

SELECT custid, ordermonth, qty, 
	(SELECT SUM(C2.qty)
	 FROM Sales.CustOrders AS C2
	 WHERE C1.custid = C2.custid AND C1.ordermonth >= C2.ordermonth) AS run_qty
FROM Sales.CustOrders AS C1
ORDER BY custid;

-- Write a query that returns for each order the number of days that passed since the same
-- customer’s previous order. To determine recency among orders, use orderdate as the primary
-- sort element and orderid as the tiebreaker:

SELECT O1.custid, O1.orderdate, O1.orderid,
					(SELECT MIN(O2.orderdate)
					FROM Sales.Orders AS O2
					WHERE O1.custid = O2.custid 
					AND O2.orderdate < O1.orderdate)
FROM Sales.Orders AS O1
ORDER BY custid;







