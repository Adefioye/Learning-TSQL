/*	TABLE EXPRESSIONS */

/*
Table expressions is a named query expression that represents a valid relational table. We can
use table expressions in data-manipulation statements much like you use other tables. T-SQL
supports four types of table expressions: derived tables, common table expressions(CTEs),
views, and inline table-valued functions (inline TVFs).

The focus of this chapter is on using SELECT queries against table expressions.

Table expressions do not physically materialise anywhere in the table-- They are entirely 
virtual. When table expressions are queried, inner query gets unnested, therefore leading 
to the merging of inner query and outer query. 

One of the many use cases of table expressions has to do with its use when we are unable to 
reference aliases in the SELECT clause. It is also useful in simplifying our solution using
the modular approach.

The chapter also introduces the APPLY table operator as it is used in conjunction with a 
table expression.

	DERIVED TABLES
Theses are also known as table subqueries. They are defined in the FROM Clause of an outer query. 
Their scope of existence is the outer query. Once the outer query is finished, the derived
table is gone. The derived table is defined inside parentheses and followed by the AS keyword

NOTE: There are 3 valid conditions necessary for a query to be a table expression

-- Order is not guaranteed. Therefore ORDER BY is not needed in table expressions except in situations
where ORDER BY does not serve a presentation purpose except for filtering purpose such as
its use in the use of TOP or OFFSET-FETCH filter.

-- All of its column names must be unique.

-- All columns must have names.
*/

-- The following defined a derived table called USA_custs which is to return all customers
-- from the united states and the outer query selects all rows from the derived table.

USE TSQLV4;

SELECT *
FROM (SELECT custid, companyname
		FROM Sales.Customers
		WHERE country = N'USA') AS USA_custs


-- The below code results in an error, because the alias "orderyear" is referred to in
-- the GROUP BY clause. which is usually processed logically before the SELECT clause.
-- Hence, the database engine has not made meaning of what the orderyear is.

SELECT
	YEAR(orderdate) AS orderyear,
	COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY orderyear;

-- The above error can be circumvented using the a inline derived table 

SELECT orderyear, COUNT(DISTINCT custid) AS num_of_custs
FROM (SELECT YEAR(orderdate) AS orderyear, custid
		FROM Sales.Orders) AS D
GROUP BY orderyear;

-- Another workaround using SQL Server is to access the underlying objects directly
-- This approach is called inline aliasing form

SELECT YEAR(orderdate) AS order_year, COUNT(DISTINCT custid) AS num_of_custs
FROM Sales.Orders
GROUP BY YEAR(orderdate)

-- The below can also be used but is referred to as external aliasing form
-- This is because the alias 'orderyear' is specified as column for the alias of the 
-- derived table.


SELECT orderyear, COUNT(DISTINCT custid) AS num_of_custs
FROM (SELECT YEAR(orderdate), custid
		FROM Sales.Orders) AS D(orderyear, custid)
GROUP BY orderyear;

-- Using local variables or input parameters to a routine

DECLARE @empid AS INT = 3;

SELECT order_year, COUNT(DISTINCT custid) AS num_of_custs
FROM (SELECT YEAR(orderdate) AS order_year, custid
		FROM Sales.Orders
		WHERE empid = @empid) AS D
GROUP BY order_year;

-- Using nesting, nesting usually reduces the readability of a code

SELECT orderyear, num_of_custs
FROM (SELECT orderyear, COUNT(DISTINCT custid) AS num_of_custs
		FROM (SELECT YEAR(orderdate) AS orderyear, custid
				FROM Sales.Orders) AS D1
		GROUP BY orderyear) AS D
WHERE num_of_custs > 70;

-- The above nested query can be re-written in another form as shown below

SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY YEAR(orderdate)
HAVING COUNT(DISTINCT custid) > 70;
 

/*
	COMMON TABLE EXPRESSIONS

These are another standard form of table expression similar to derived tables, yet with a 
couple of important advantages.

CTEs are defined by using a WITH statement and have the following general form.

WITH <CTE_Name>[ <target_column_list> ]
AS
(
	<inner_query_defining_CTE>
)

<outer_query_against_CTE>

NOTE: As soon as the outer query finishes, CTE goes out of scope.

NOTE: WITH clause is used in T-SQL for several purposes. It is used to define a table hint
in a query to force a certain optimization option or isolation level. Therefore, to avoid 
ambiguity, WITH clasuse defining the CTE should be terminated with a semi-colon.

CTEs also support inline and external aliasing

NOTE: Even if we want to, we cannot nest CTEs nor can we define a CTE within parentheses
of a derived table. This restriction is referred by experts as a good thing 
*/ 

-- Using CTE to extract all rows of customers in USA

WITH USA_custs AS
(
	SELECT custid, companyname
	FROM Sales.Customers
	WHERE country = 'USA'
)
SELECT * FROM USA_custs;

-- USing inline aliasing with CTE

WITH C AS 
(
	SELECT YEAR(orderdate) AS order_year, custid
	FROM Sales.Orders
)
SELECT order_year, COUNT(DISTINCT custid) AS num_of_custs
FROM C
GROUP BY order_year;

-- USing external aliasing with CTE

WITH C(order_year, custid) AS 
(
	SELECT YEAR(orderdate), custid
	FROM Sales.Orders
)
SELECT order_year, COUNT(DISTINCT custid) AS num_of_custs
FROM C
GROUP BY order_year;

-- Using arguments in CTEs. 

DECLARE @empid AS INT = 3;

WITH C AS 
(
	SELECT YEAR(orderdate) AS order_year, custid
	FROM Sales.Orders
	WHERE empid = @empid
)
SELECT order_year, COUNT(DISTINCT custid) AS num_of_custs
FROM C
GROUP BY order_year;

-- Using multiple CTEs. This leverages the use of modular approach. It improves readability
-- and maintainability of the code compared to the nested derived table approach.

WITH C1 AS 
(
	SELECT YEAR(orderdate) AS order_year, custid
	FROM Sales.Orders
),
C2 AS
(
	SELECT order_year, COUNT(DISTINCT custid) AS num_of_custs
	FROM C1
	GROUP BY order_year
)
SELECT order_year, num_of_custs
FROM C2
WHERE num_of_custs  > 70;

-- Multiple references to CTEs

WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS num_of_custs
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)
SELECT cur.orderyear, cur.num_of_custs AS cur_num_of_custs,
	prv.num_of_custs AS pre_num_of_custs, 
	cur.num_of_custs - prv.num_of_custs AS growth	
FROM YearlyCount AS cur  LEFT JOIN YearlyCount AS prv
	ON cur.orderyear = prv.orderyear + 1


-- Recursive CTEs