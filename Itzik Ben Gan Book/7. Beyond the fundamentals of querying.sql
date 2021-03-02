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

/*
Note: Window function are logically evaluated as part of the SELECT list, before the DISTINCT
clause is evaluated. 
*/

-- The below did not produce distinct 795 rows in val. This is because window function is 
-- evaluated before the DISTINCT phase

SELECT DISTINCT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues;

-- To create 795 distinct row numbers, we use a GROUP BY. This is because GROUP BY is 
-- logically-processed before SELECT clause. This therefore makes ROW_NUMBER to be applied
-- on the 795 grouped values

SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;


/*
	OFFSET WINDOW FUNCTION

OFFSET window functions are used to return a row that is at a certain offset from the 
current row in the partition.

TSQL supports the following offset functions: LEAD, LAG, FIRST_VALUE, LAST_VALUE.

LAG function looks before the row while LEAD function looks after the row. They both have
3 arguments: The element to be returned, the optional offset argument(1 if not specified)
and the default value to return if no element is returned(NULL if not specified).

NOTE: LAG(val, 2, 0) ==> This returns value that is 2 place before the current in the window frame, and
returns 0 if no element is returned

NOTE: val - LAG(val), val - LEAD(val) ==> can be used to work out the difference between current value
and lead and lag values

	FRIST_VALUE and LAST_VALUE

This can be used to return the first and last value within the window frame. They require
the window [artition, window order-by and window-frame clause. When using these functions. 
the window-frame clauses should be specified.

FOr FIRST_VALUE: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
For LAST_VALUE: ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING

NOTE: We can compute difference between current and first/ last customer's order

 
*/

-- We use LAG and LEAD function to return previous and next value of each customers order

SELECT custid, orderid, val,
	LAG(val) OVER(PARTITION BY custid
					ORDER BY orderdate, orderid) AS prevval,
	LEAD(val) OVER(PARTITION BY custid
					ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

-- Using FIRST_VALUE and LAST_VALUE to return value of last customer's order

SELECT custid, orderid, val,
	FIRST_VALUE(val) OVER(PARTITION BY custid
							ORDER BY orderdate, orderid
							ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS firstval,
	LAST_VALUE(val) OVER(PARTITION BY custid
							ORDER BY orderdate, orderid
							ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;


/*
	AGGREGATE WINDOW FUNCTIONS

these agrregate the rows within a defined window. They support window-partition,
window-order and window-frame clauses. When we specify the OVER() clause, we are exposing
the entire window, that is, the underlying query result set to the window function.
However, when we specify the PARTITION clause, we then restrict the window to just the 
elements within the partition element
*/

-- Let us return the grandtotal of order values and the customer's total

SELECT orderid, custid, val,
	SUM(val) OVER() AS totalvalue,
	SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;

-- Since window functions do not hide details, we can calculate pct of current out of
-- grandtotal and out of customer total.

SELECT orderid, custid, val,
	100 * val / SUM(val) OVER() AS pct_of_total,
	100 * val / SUM(val) OVER(PARTITION BY custid) AS pct_of_custtotal
FROM Sales.OrderValues;

/*
Aggregate function supports a window frame. The frame allows for more sophisticated 
calculations such as running and moving aggregates, YTD and MTD calculations, and others.

NOTE: ROW BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ==> Simply means performing
window function from the beginning of the partition to current row.

T-SQL also supports other forms of delimiters for the ROWS window-frame unit. We can indicate
an offset back and forward from then current row.

To perform a window function on 2 rows before and 1 row after the current row we use:
ROWS 2 PRECEDING AND 1 FOLLOWING
*/


/*
	PIVOTING DATA

Pivoting data involves rotating data from a state of rows to a state of columns, possibly
aggregating values along the way. In many cases, pivoting of data is handled by the presentation 
layer for purposes such as reporting. 

This section teaches you how to handle pivoting with T-SQL for cases you do decide to handle
pivoting with T-SQL for cases you do decide to handle in the database.

Pivoting involves 3 logical processing phase: grouping, spreading and aggregating

	PIVOTING with the PIVOT OPERATOR

the PIVOT operator takes a table as left input, pivots the data, and returns a result table.

Syntax: 

SELECT ...
FROM <input_table>
	PIVOT(<agg_function>(<aggregation_element>)
			FOR <spreading_element> IN (<list_of_target_columns>)) AS <result_table_alias>
WHERE .....;

NOTE: With the PIVOT operator, we do not specify the grouping elements, it is usually implied.
Hence, after specifying the spreading elements and the aggregating elements. THe remaining
attributes are used as grouping elements. Therefore, it is important to only use attributes
necessary in the table expression.

*/

USE TSQLV4;

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
	orderid		INT			NOT NULL,
	orderdate	DATE		NOT NULL,
	empid		INT			NOT NULL,
	custid		VARCHAR(5)	NOT NULL,
	qty			INT			NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
)

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
	(30001, '20140802', 3, 'A', 10),
	(10001, '20141224', 2, 'A', 12),
	(10005, '20141224', 1, 'B', 20),
	(40001, '20150109', 2, 'A', 40),
	(10006, '20150118', 1, 'C', 14),
	(20001, '20150212', 2, 'B', 12),
	(40005, '20160212', 3, 'A', 10),
	(20002, '20160216', 1, 'C', 20),
	(30003, '20160418', 2, 'B', 15),
	(30004, '20140418', 3, 'C', 22),
	(30007, '20160907', 3, 'D', 30);


SELECT * FROM dbo.Orders;

-- This returns then total order qty for each employee and customer 

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

-- Pivoting using explicit groupby, spread and agg operator

SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY empid

-- Pivoting with PIVOT OPERATOR

SELECT empid, A, B, C, D
FROM (SELECT empid, custid, qty
		FROM dbo.Orders) AS D
		PIVOT(SUM(qty) FOR custid IN (A, B, C,D)) AS T;

-- Using PIVOT operator when spreading elements contain digits, we use delimiters like 
-- Square brackets

SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
		FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR empid IN ([1], [2], [3])) AS T;


/*
	UNPIVOT DATA

Unpivoting can be done using the APPLY operator or using the UNPIVOT operator.

APPLY operator makes use of the 3 approaches: generating copies, extracting elements and 
eliminating NULL intersections.

Syntax:

UNPIVOT operator

SELECT ...
FROM <input_table>
	UNPIVOT(<values_column> FOR <names_column> IN(<source_columns>)) AS <result_table_alias>
WHERE ....;
*/
USE TSQLV4;

IF OBJECT_ID('dbo.EmpCustOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpCustOrders;
-- DROP TABLE IF EXISTS dbo.EmpCustOrders;

CREATE TABLE dbo.EmpCustOrders
(
	empid INT NOT NULL
		CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
	A VARCHAR(5) NULL,
	B VARCHAR(5) NULL,
	C VARCHAR(5) NULL,
	D VARCHAR(5) NULL
);
INSERT INTO dbo.EmpCustOrders(empid, A, B, C, D)
	SELECT empid, A, B, C, D
	FROM (SELECT empid, custid, qty
			FROM dbo.Orders) AS D
		PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;


SELECT * FROM dbo.EmpCustOrders;

-- UNpivot dbo.EmpCustOrders using the CROSS APPLY method

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	CROSS APPLY (VALUES('A', A), ('B', B), ('C', C), ('D', D)) AS C(custid, qty)
WHERE qty IS NOT NULL;

-- UNpivot dbo.EmpCustOrders using the UNPIVOT method

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	UNPIVOT(qty FOR custid IN(A, B, C, D)) AS T;

-- Let us cleanup

IF OBJECT_ID('dbo.EmpCustOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpCustOrders;


/*
	GROUPING SETS, CUBE and ROLLUP
	
These can be used to define multiple grouping sets in GROUP BY clause. They are mainly used
for reporting and data analysis. There are also the GROUPING and GROUPING_ID functions.

These features usually need the presentation layer to use more sophisticated GUI controls
to display the data than the typical grid control with its columns and rows.

	GROUPING SETS
	
This is a powerful enhancement to the GROUP BY clause. You can use it to define multiple
grouping sets in the same query. All we need to do is simply list out the grouping sets we
want in parentheses of the GROUPING SETS subclause and for each grouping set, list the members
in parentheses followed by commas.

	CUBE Subclause

This is also applicable in a GROUP BY clause. It is an abbreviation for defining multiple
grouping sets. This helps to group data by all possible subsets of elements in the set passed
onto it. For example CUBE(a, b, c) is equivalent to GROUPING SETS( (a, b, c), (a,
b), (a, c), (b, c), (a), (b), (c), () ).

	ROLLUP Subclause

THis provides an abbreviation to the CUBE subclause. Allowing for just a subset of the 
subset of elements passed into it.

ROLLUP(a, b, c) produces only 4 grouping sets based on the hierarchy a>b>c. 
Therefore, ROLLUP(a, b, c) ==> GROUPING SETS((a,b,c), (a,b), (a), ())

Also, 
GROUPING SETS(
(YEAR(orderdate), MONTH(orderdate), DAY(orderdate)),
(YEAR(orderdate), MONTH(orderdate)),
(YEAR(orderdate)),
() )

is the same as 

ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate))

NOTE: When using grouping functions for grouping muktiple sets in the GROUP BY clause, we 
tend to experience NULLS in the data. This could be as a result of 2 situations. One, it can
either be that the NULL is part of the data as an aggregate element or it can be that the 
NULL is used to show that the element is non-participating in the grouping set.

To clear up air on this, the GROUPING function can be used to differentiate between these 
2 situations. When a column name is passed to the GROUPING function, it returns 1 when
NULL represents not part of the grouping set(aggregate element) and 
0 when part of the grouping set. THIS IS COUNTERINTUITIVE. But it is what it is.

GROUPING_ID function is used to get an integer bitmap of the columns passed into it

*/

-- Let us group the Orders table by (empid, custid), (empid), (custid), and ():
-- The empty () represents the grand total.

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
		(empid, custid),
		(empid),
		(custid),
		()
	);


-- The above can also be implemented using CUBE function

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- Using rollup clause to return a query

SELECT 
	YEAR(orderdate) AS orderyear,
	MONTH(orderdate) AS ordermonth,
	DAY(orderdate) AS orderday,
	SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate))

-- Using GROUPING function to know if NULL is an aggregate element or deatil element(part of the grouping set)

SELECT 
	GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- Using GROUPING_ID function. This results in an integer than can be converted to binary form
-- For (empid, custid): integer 1(binary 01) represents empid is a grouping set and custid is
-- not a grouping set; integer 2(binary 10) represents empid is not a grouping set and custid
-- is a grouping set; integer 3(bainary 11) represents empid and custid are not grouping sets

SELECT
	GROUPING_ID(empid, custid) AS groupingset,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
