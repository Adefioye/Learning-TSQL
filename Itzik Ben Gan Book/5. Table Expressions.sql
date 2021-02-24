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


/*
	Recursive CTEs (ADVANCED READING)

CTEs are unique amongst table expressions because they support recursion. Just like the 
non-recursive ones, they are defined by SQL standard. A recursive CTE is defined by at least
2 queries-- at least one query known as the anchor member and at least one known as 
recursive member.

The general form is shown below:

WITH <CTE_Name> [(<target_column_list>)]
AS
(
	<anchor_member>
	UNION ALL
	<recursive_member>
)
<outer_query_against_CTE>

NOTE: If there are logical errors or problems with the data that result in cycles, the
recursive member can be invoked infinite amount of times. For safety purpose, SQL Server
restricts the number of times the recursive member can be invoked to 100 by default. 
It can howerver be changed by setting OPTION(MAXRECURSION n) where n is an integer between
0 and 32,767. If we wanna remove the restriction specify MAXRECURSION 0.

Please note that SQL Server stores the intermediate result by the anchor and recursive 
members in a work table in tempdb; If restriction is removed and there is a runaway query,
the work table will quickly get very large and the query will never finish.
*/

-- Return subordinates of all managers in the HR.Employees table, REcursive CTE is used.

WITH Emp_CTE AS
(
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 2

	UNION ALL

	SELECT E.empid, E.mgrid, E.firstname, E.lastname
	FROM Emp_CTE AS P INNER JOIN HR.Employees AS E
		ON E.mgrid = P.empid
)
SELECT * FROM Emp_CTE;

/*
	VIEWS

Derived tables and CTEs are single-statement scope, which means they are not reusable.
Views and inline table-valued functions are 2 types of table expressions whose definitions
are stored as permanent objects in the database, making them reusable.

If there were just 2 columns in the underlying table, if we alter the columns in the 
underlying table of the view. SQL server will not update the view with the new columns. To
allow for the new column to be effected in the view we refresh the view's metadata using
sp_refreshview, sp_refreshsqlmodule

To avoid confusion, the best practice is to explicitly list the column names you need in the
definition of the view. If columns are added to the underlying tables and you need them in the
view, use the ALTER VIEW statement to revise the view definition accordingly.

*/

-- Let us create a view called USA_Custs


USE TSQLV4;
IF OBJECT_ID(N'Sales.USACusts', N'U') IS NOT NULL DROP TABLE Sales.USACusts;

GO
CREATE VIEW Sales.USACusts 
AS
SELECT *
FROM Sales.Customers
WHERE country = 'USA';
GO

-- Let us query the view Sales.USACusts.

SELECT custid, companyname
FROM Sales.USACusts;

-- If ORDER BY is used in a view, an error occurs

ALTER VIEW Sales.USACusts
AS
SELECT *
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

-- The error can be circumvented using TOP or OFFSET-FETCH. This creates an 'ordered view'
-- However, it is not guaranteed that when an outer query is made against the view, it
-- would be in an ordered fashion.

ALTER VIEW Sales.USACusts
AS
SELECT TOP (100) PERCENT
	*
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

-- Lets try and query the view to be sure that the result set is not ordered.

SELECT custid, companyname, region
FROM Sales.USACusts;

-- Lets use offset in the view definition

ALTER VIEW Sales.USACusts
AS

SELECT *
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region
OFFSET 0 ROWS;
GO

-- The query below seem to be ordered by region. This does not mean it is ordered, it just 
-- happened by luck due to current optimization. The presenatation of thne result set can only
-- be guaranteed with an ORDER BY clause.
SELECT *
FROM Sales.USACusts;
