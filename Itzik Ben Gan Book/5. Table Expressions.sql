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

	ENCRYPTION option

Encryption option is available when we create/ alter views, triggers, stored procedures,
and user-defined functions. This tells the SQL Server to store text with the definition of
the object in an obfuscated format.

The obfuscated text is not directly visible to users through any of the catalog objects --
only to privileged users through special means

NOTE: When we alter a view, we would not be able to retain the exsisting permissions if not 
explicitly specified. So if we have an ENCRYPTION option on the CREATE VIEW statement, when
we alter the existing view, we should re-specify the ENCRYPTION option, otherwise, it would be 
lost.

	SCHEMABINDING option

 This option is available to view and UDFs and it helps to bind the schema/ columns of the 
 referenced objects to that of the referencing objects. What this does is, it makes it impossible
 to drop columns and table of the referenced objects.

 NOTE: Please note that the SCHEMABINDING option can only be used for view/ UDFs definition
 wthout the "*" in the SELECT statement. Hence, columns should be explicitly specified within
 the SELECT clause. Also, 2-part schema-qualified names should be used when referring to the 
 objects. 
 
	CHECK OPTION

THis helps to prevent the modification of a view except it satisfies the condition of the 
view definition. For example, if a view filters out customers that are non-USA, with a 
CHECK OPTION enabled, it will not be possible to update or mlodify the view with a rows of 
information of customers that are non-USA. Otherwise, without CHECK option the update
operation will go through the view and update the relation of the underlying object.
	 


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

-- To use the ENCRYPTION option. Let us first alter the view of USACusts

ALTER VIEW Sales.USACusts
AS

SELECT 
	*
FROM Sales.Customers
WHERE country = 'USA';
GO

-- To get the definition of the view, we invoke the OBJECT_DEFINITION.

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

-- We were able to see the text with the view definition. To make this unavailable, we use
-- the ENCRYPTION option together with the VIEW definition.

ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS

SELECT 
	*
FROM Sales.Customers
WHERE country = 'USA';
GO

-- Lets try to view the object definition again. we will try use sp_helptext

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

EXEC sp_helptext 'Sales.USACusts';

EXEC sp_helptext 'HR.Employees';

-- Lets try the use of schema-binding

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT
	*
FROM Sales.Customers
WHERE country = N'USA';
GO

-- The attempt to alter above failed because the '*' is used. Hence, columns should be
-- properly named and specified

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = 'USA';
GO

-- Let us now try to drop the address column from the customers table, we therefore
-- get an error that says we are now allowed to drop the column.  

ALTER TABLE Sales.Customers DROP COLUMN address;

SELECT *
FROM Sales.Customers;

/* Using CHECK OPTION*/

-- Let us try to insert a row of info of a customer to from the UK into the USACusts view

INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address, city,
	region, postalcode, country, phone, fax)
VALUES(
	N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
	N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

-- If we check the row above in USACusts view, it returns an empty set.

/*
DELETE FROM Sales.Customers
WHERE custid > 91;
*/

SELECT custid, companyname, country
FROM Sales.USACusts
WHERE contactname = 'Contact ABCDE';

-- However, when we check for the info in the sales.Customers table, we find the info
-- This is because there is no WITH CHECK OPTION to prevent the update of info that did not
-- satisfy the view definition.

SELECT custid, companyname, country
FROM Sales.Customers
WHERE contactname = 'Contact ABCDE';

-- To prevent the addition of info that did not satisfy the view definition, we use
-- WITH CHECK OPTION

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = 'USA'
WITH CHECK OPTION;
GO

-- Lets try insert another customer from the UK. This result in an error as the row
-- did not satisfy the view definition

INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax)
VALUES(
	N'Customer FGHIJ', N'Contact FGHIJ', N'Title FGHIJ', N'Address FGHIJ',
	N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

-- Sweet yeah! We are unable to add rows of info that did not satisfy the view definition

DELETE FROM Sales.Customers
WHERE custid > 91;

IF OBJECT_ID(N'Sales.USACusts', N'U') IS NOT NULL DROP VIEW Sales.USACusts;


/*
	INLINE TABLE-VALUED FUNCTIONS

Inline TVFs are reusable table expressions that support input parameters. In most respects,
except for the support of input parameters, Inline TVFs are similar to views. IN this respect,
inline TVFs are referred to as parmeterized views, even though they are not formally referred
to this way.
 
T-SQL supports another type of table function called multi-statement TVF, which populates
and returns a table variable. This type is not considered a table expression because 
it is not based on a query.  

*/

-- The below code creates an inline TVFs called GetCustOrders
-- Inline TVFs accept input parameters and are specified inside a parentheses following a 
-- function's name

USE TSQLV4;
IF OBJECT_ID('dbo.GetCustOrders', 'U') IS NOT NULL DROP FUNCTION dbo.GetCustOrders;
GO
CREATE FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE
AS
RETURN 
	SELECT orderid, custid, empid, orderdate, requireddate,
	shippeddate, shipperid, freight, shipname, shipaddress, shipcity,
	shipregion, shippostalcode, shipcountry 
	FROM Sales.Orders
	WHERE custid = @cid;
GO

-- LEts query the inline TVFs. This returns orders with customer id of 1

SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;

-- As with tables, inline TVFs can be used in JOIN operations

SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O INNER JOIN Sales.OrderDetails AS OD
	ON O.orderid = OD.orderid;

-- Lets cleanup

IF OBJECT_ID('dbo.GetCustOrders', 'U') IS NOT NULL DROP FUNCTION dbo.GetCustOrders;

/*
	APPLY operator

This is used in the FROM clause of a query. There are 2 supported types of APPLY: 
CROSS APPLY and OUTER APPLY. APPLY performs its job in the logical-query processing phase.
CROSS APPLY implements onely ONE(1) logical-query processing phase whereas OUTER APPLY 
implements TWO(2).

NOTE: APPLY is not standard. The standard counterpart is called LATERAL, but the standard 
form was not implemented in SQL server.

APPLY operator operates on two input tables; I'll refer to them as "left" and "right" tables.
The right table is typically a derived table or a TVF. CROSS APPLY work more like a CROSS JOIN.
However, CROSS JOIN treats 2 input tables as a set, meaning, one cxanot refer one element on
one side to elements from the other. with APPLY, the left side is evaluated first. Then the right
right is then evaluated per row from the left.
*/

-- Let us use CROSS APPLY to return the 3 most recent orders by customer. We can think of
-- A as a correlated derived table.

SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
	(SELECT TOP (3)
		orderid, empid, orderdate, requireddate
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid
	 ORDER BY orderdate DESC, orderid DESC) AS A;

-- In the query above, if the right table returns an empty set, CROSS APPLY will not return 
-- elements from the left table. To fetch out these result(customers with no top 3 recent orders),
-- OUTER APPLY is used similar to how LEFT JOIN works.


-- We might find it convenient to work with inline TVFs instead of derived tables.
-- The below code creates an inline TVF called TopOrders that accepts as inputs a customer
-- ID(@custid) and a number (@n), and returns the @n most recent orders for customer @custid

IF OBJECT_ID('dbo.TopOrders') IS NOT NULL DROP FUNCTION dbo.TopOrders;
GO
CREATE FUNCTION dbo.TopOrders
	(@custid AS INT, @n AS INT)
	RETURNS TABLE
AS
RETURN 
	SELECT TOP (@n) orderid, empid, orderdate, requireddate
	FROM Sales.Orders
	WHERE custid = @custid
	ORDER BY orderdate DESC, orderid DESC;
GO

-- USing the correlated inline TVFs

SELECT C.custid, T.orderid, T.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
		dbo.TopOrders(C.custid, 3) AS T;