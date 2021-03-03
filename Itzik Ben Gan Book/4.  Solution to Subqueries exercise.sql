/* CHAPTER 4 EXERCISE SOLUTION	*/

-- Write a query that returns all orders placed on the last day of activity that can be found in the
-- Orders table:

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders AS O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
						FROM Sales.Orders O2);


-- Write a query that returns all orders placed by the customer(s) who placed the highest number
-- of orders. Note that more than one customer might have the same number of orders:

-- 1st method

SELECT custid, orderid, orderdate, empid
FROM (SELECT TOP (1) WITH TIES
			custid, orderid, orderdate, empid,
			(SELECT COUNT(O2.orderid)
				FROM Sales.Orders O2
				WHERE O1.custid = O2.custid) AS num_of_orders
		FROM Sales.Orders AS O1
		ORDER BY num_of_orders DESC) AS T1;

-- 2nd method

WITH CTE_CUST_WITH_TOP_ORDER
AS
(
	SELECT TOP (1) WITH TIES
		custid, orderid, orderdate, empid,
		COUNT(orderid) OVER(PARTITION BY custid) AS numoforders
	FROM Sales.Orders
	ORDER BY numoforders DESC
)
SELECT custid, orderid, orderdate, empid
FROM CTE_CUST_WITH_TOP_ORDER;

-- 3rd method(most awesome)

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN
	(SELECT TOP (1) WITH TIES O.custid
		FROM Sales.Orders AS O
		GROUP BY O.custid
		ORDER BY COUNT(*) DESC);


-- Write a query that returns employees who did not place orders on or after May 1, 2016:

-- 1nd method

SELECT empid, firstname, lastname
FROM HR.Employees E
WHERE E.empid IN (
		(SELECT empid FROM Sales.Orders) 
		EXCEPT (SELECT empid FROM Sales.Orders WHERE orderdate >= '20160501'));

-- 2nd method(Most awesome)

SELECT empid, firstname, lastname
FROM HR.Employees E
WHERE E.empid NOT IN 
	(SELECT O.empid
		FROM Sales.Orders AS O
		WHERE O.orderdate >= '20160501');

-- 3rd method (Another fantastic one)

SELECT empid, firstname, lastname
FROM HR.Employees AS E
WHERE NOT EXISTS
	(SELECT O.empid
		FROM Sales.Orders AS O
		WHERE E.empid = O.empid AND O.orderdate >= '20160501');




-- Write a query that returns countries where there are customers but not employees:

-- 1st method (cool)

(SELECT country FROM Sales.Customers) EXCEPT (SELECT country FROM HR.Employees);

-- 2nd method

SELECT DISTINCT
	country
FROM Sales.Customers AS C
WHERE NOT EXISTS (
					SELECT E.country
					FROM HR.Employees AS E
					WHERE C.country = E.country);

-- Write a query that returns for each customer all orders placed on the customer’s last day of
-- activity:

-- 1st method

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
						FROM Sales.Orders O2
						WHERE O1.custid = O2.custid)
ORDER BY custid;

-- 2nd method

-- Write a query that returns customers who placed orders in 2015 but not in 2016:

-- 1st method

SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.custid IN ((SELECT O.custid FROM Sales.Orders O WHERE YEAR(O.orderdate) = 2015)
 EXCEPT (SELECT O.custid FROM Sales.Orders O WHERE YEAR(O.orderdate) = 2016))
ORDER BY custid;

-- 2nd method (Busting-head query)

SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
		(SELECT *
			FROM Sales.Orders AS O
			WHERE (C.custid = O.custid) AND O.orderdate LIKE '%2015%')
		AND NOT EXISTS
		(SELECT *
			FROM Sales.Orders AS O
			WHERE (C.custid = O.custid) AND O.orderdate LIKE '%2016%');


-- Write a query that returns customers who ordered product 12:

-- 1st method

SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.custid IN (SELECT O.custid
					FROM Sales.Orders O INNER JOIN Sales.OrderDetails OD
							ON O.orderid = OD.orderid
					WHERE OD.productid = 12);

-- 2nd method (Itzik Ben-Gan Solution-- Sweet one)

SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
		   (SELECT *
			FROM Sales.Orders AS O
			WHERE O.custid = C.custid
			AND EXISTS
			   (SELECT *
				FROM Sales.OrderDetails AS OD
				WHERE OD.orderid = O.orderid AND OD.ProductID = 12));

-- Write a query that calculates a running-total quantity for each customer and month:

-- 1st method

SELECT custid, ordermonth, qty, 
	(SELECT SUM(C2.qty)
	 FROM Sales.CustOrders AS C2
	 WHERE C1.custid = C2.custid AND C1.ordermonth >= C2.ordermonth) AS run_qty
FROM Sales.CustOrders AS C1
ORDER BY custid;

-- 2nd method (Using window function)

SELECT custid, ordermonth, qty,
	SUM(qty) OVER(PARTITION BY custid ORDER BY ordermonth) AS runqty
FROM Sales.CustOrders;

-- Write a query that returns for each order the number of days that passed since the same
-- customer’s previous order. To determine recency among orders, use orderdate as the primary
-- sort element and orderid as the tiebreaker:

SELECT O1.custid, O1.orderdate, O1.orderid,
					DATEDIFF(DAY,
					(SELECT MAX(O2.orderdate)
					FROM Sales.Orders AS O2
					WHERE O1.custid = O2.custid AND O2.orderdate < O1.orderdate),
					O1.orderdate) AS diff
FROM Sales.Orders AS O1
ORDER BY custid, orderdate, orderid;

-- 2nd method (Coolest display of the powers of windows functions)

SELECT custid, orderdate, orderid, 
	DATEDIFF(DAY, 
	LAG(orderdate) OVER(PARTITION BY custid ORDER BY orderdate, orderid),
	orderdate) AS diff
FROM Sales.Orders;







