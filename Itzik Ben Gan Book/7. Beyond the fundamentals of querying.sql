/* Chapter 7 BEYOND THE FUNDAMENTALS OF QUERYING	*/

/*
WINDOW Functions are functions that are applied to a set of rows and return a scalar value for 
each subset of rows. Each subset of row is called a window and defined by a window descriptor
called OVER.

The OVER clause which define window functions has 3 logical processing phase: 
window PARTITION clause, window ORDER BY clause, and thne window FRAME clause. There is 
also the RANGE clause but it will not be treated here.

Window PARTITION clause: This is used for grouping the underlying rows based on a column,
or set of columns.

Window ORDER BY clause: This is to specify the frame upon which the window function is going
to be performed. It is not a presentation clause. It only specifies the frame upon which
the claculation is gonna be performed.

Window FRAME clause: This helps to limit the frame upon which the calculation will be 
performed. 

Window FRAME clause syntax: ROWS BETWEEN <upper-limit> AND <lower-limit>
	

*/

-- The following query returns running total values for each employee and month

USE TSQLV4;

SELECT empid, ordermonth, val,
	SUM(val) OVER(PARTITION BY empid
				  ORDER BY ordermonth
				  ROWS BETWEEN UNBOUNDED PRECEDING 
					AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

SELECT empid, ordermonth, val,
	SUM(val) OVER() AS runval
FROM Sales.EmpOrders;

/*	RANKING WINDOW FUNCTIONS	

We use ranking window functions to rank each row with respect to others in the window.
T-SQL supports 4 ranking functions; ROW_NUMBER, RANK, DENSE_RANK, NTILE.

ROW_NUMBER returns incremental sequential integer based on the window ORDER BY clause

RANK returns returns incremental sequential integer but assign same int when values are the
same. In addition, For each integer i, there are (i - 1) values that are less than or equal to i.

DENSE_RANK returns incremental sequential integer but assign same int when values are the
same. In addition, For each integer i, there are (i - 1) distinct values that are less than i.

NTILE: This groups the underlying rows into sub-groups

*/

-- Query typifying window functions

SELECT orderid, custid, val,
	ROW_NUMBER() OVER(ORDER BY val) AS rownum,
	RANK()		 OVER(ORDER BY val) AS rank_,
	DENSE_RANK() OVER(ORDER BY val) AS dense_rank_,
	NTILE(10)    OVER(ORDER BY val) AS ntile_
FROM Sales.OrderValues
ORDER BY val

SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid
						ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;




