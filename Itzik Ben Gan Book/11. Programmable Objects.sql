/*	CHAPTER 11 PROGRAMMABLE OBJECTS	*/

/*
This chapter provides a high-level overview of programmable objects. The chapter covers
variales, batches, flow elements, cursors, temporary tables, routines such as 
user-defined functions, stored procedures, triggers and dynamic SQL.
*/

/*
	Variables

Variables are used to temprarily store data values for later use in the same batch in which they
are declared.

SET statement operates on only one variable at a time. If one needs to assign values to
multiple variables, multiple SET statements should be used.

*/

-- the following code declares a variable called @i of an INT data type and assigns it the 
-- value 10:

-- 1st method
DECLARE @i AS INT;
SET @i = 10;

-- 2nd method
DECLARE @i AS INT = 10;

SELECT @i;

/*
When you assign a value to a scalar variable, the value must be the result of a scalar
expression.
*/

-- the following code declares a variable called @empname and assigns it the result of a 
-- scalar subquery that returns the full name of the employee with an ID of 3:

DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + ' ' + lastname
				FROM HR.Employees
				WHERE empid = 3);

SELECT @empname AS empname;

-- The following code uses two separate SET statements to pull both the first and last names
-- of the employee with the ID of 3 to two separate variables:

DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SET @firstname = (SELECT firstname
					FROM HR.Employees
					WHERE empid = 3);

SET @lastname = (SELECT lastname
					FROM HR.Employees
					WHERE empid = 3);

SELECT @firstname AS firstname, @lastname AS lastname;

-- T-SQL also supports a nonstandard assignment SELECT statement as shown below

DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SELECT
	@firstname = firstname,
	@lastname = lastname
FROM HR.Employees
WHERE empid = 3;

SELECT @firstname AS firstname, @lastname AS lastname;

/*
The assignment SELECT has predictable behavior when exactly one row qualifies.
However, note that if the query has more than one qualifying row, the code doesn’t fail. The
assignments take place per qualifying row, and with each row accessed, the values from the
current row overwrite the existing values in the variables. When the assignment SELECT
finishes, the values in the variables are those from the last row that SQL Server happened to
access. For example, the following assignment SELECT has two qualifying rows:
*/

DECLARE @empname AS NVARCHAR(61);

SELECT @empname = firstname + N' ' + lastname
FROM HR.Employees
WHERE mgrid = 2;

SELECT @empname AS empname;

/*
SET statement is safer than the assignment SELECT because it requires you to use a scalar 
subquery to pull data from a table. Remember that a scalar subquery fails at run time if 
it returns more than one value. 

*/

-- For example, the following code fails:

DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + ' ' + lastname
				FROM HR.Employees
				WHERE mgrid = 2);

SELECT @empname AS empname;

/*
	BATCHES

Batch is one or more T-SQL statements sent by a client application to SQL Server for execution
as a single unit. The batch undergoes parsing, resolution/binding and optimization as a unit.

Do not confuse transactions and batches. A transaction is an atomic unit of work. A batch can have
multiple transactions and a transaction can be submitted in parts as multiple batches.

When a transaction is cancelled or rolled back, SQL Server undoes the partial activity that
has taken place since the beginning of the transaction, regardless of where the batch began.

Client application programming interfaces (APIs) such as ADO.NET provide you with
methods for submitting a batch of code to SQL Server for execution. SQL Server utilities
such as SQL Server Management Studio (SSMS), SQLCMD, and OSQL provide a client tool
command called GO that signals the end of a batch. Note that the GO command is a client tool
command and not a T-SQL server command.

A batch is a set of commands that are parsed and executed as a unit. If the parsing is successful,
SQL Server then attempts to execute the batch. If there is syntax error in the batch, the whole
batch is not submitted to SQL Server.
*/

-- A batch as a unit of parsing:

-- Valid batch
PRINT 'First batch'
USE TSQLV4;
GO

-- Invalid batch
PRINT 'Second batch'
SELECT custid FROM Sales.Customers;
SELECT orderid FRO Sales.Orders;
GO

-- Valid batch
PRINT 'Third batch';
SELECT empid FROM HR.Employees;

/*
	BATCHES and VARIABLES

A variable is LOCAL to the batch in which it is defined. If you refer to a variable that was
defined in another batch, you will get an error saying that the variable was not defined.

*/

-- The following code declares a variable and prints its content in one batch, and then it tries to print
-- its content from another batch(error ensues)

DECLARE @i AS INT;
SET @i = 10;

-- This succeeds(Why? Because it is in a batch)
PRINT @i;
GO

-- Fails (Why? It is in another batch)
PRINT @i

/*
Some statements cannot be combined with other statements in the same batch. Examples of those
statements are CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE SCHEMA,
CREATE TRIGGER, and CREATE VIEW
*/

-- The following code has a DROP statement followed by a CREATE VIEW statement in the same batch
-- and therefore is invalid:

DROP VIEW IF EXISTS Sales.MyView;

CREATE VIEW Sales.MyView
AS

SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate)
GO

-- To solve the error above, DROP VIEW and CREATE VIEW statements should be separated into
-- different batches by adding GO command after the DROP VIEW


/*
A batch is a unit of resolution (also known as binding). This means that checking the existence
of objects and columns happens at the batch level. Keep this fact in mind when you’re
designing batch boundaries. When you apply schema changes to an object and try to
manipulate the object data in the same batch, SQL Server might not be aware of the schema
changes yet and fail the data-manipulation statement with a resolution error. let us demonstrate
the problem through an example and then recommend best practices.

NOTE: It is best to avoid resolution error by separating DDL and DML statements into different
batches
*/

-- Run the following code to create a table called T1 in the current database, with one column
-- called col1:

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT);

-- Next, try to add a column called col2 to T1 and query the new column in the same batch:
-- Selecting the 2 statements below result in error. because there is no col2 yet until the
-- BATCH is launched(To resolve this GO should be placed under ALTER TABLE before accessing
-- col2 or doing DML on col2)

ALTER TABLE dbo.T1 ADD col2 INT;
GO

SELECT col1, col2 FROM dbo.T1;

/*
GO n option

n is the number of times the batch is carried out
*/


DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT IDENTITY);

SET NOCOUNT ON; -- This suppresses the output showing numbers of rows affected by DML statements
INSERT INTO dbo.T1 DEFAULT VALUES;
GO 100;

SELECT * FROM dbo.T1;

/*
	FLOW STATEMENTS
*/

IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(DAY, 1, SYSDATETIME()))
	PRINT 'Today is the last day of the year.';
ELSE 
	PRINT 'Today is not the last day of the year.';

/*
For example, the next code I’ll show you handles the following three cases
differently:

--> Today is the last day of the year.
--> Today is the last day of the month but not the last day of the year.
--> Today is not the last day of the month.
*/

IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(DAY, 1, SYSDATETIME()))
	PRINT 'Today is the last day of the year.';
ELSE
	IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(DAY, 1, SYSDATETIME()))
		PRINT 'Today is the last day of the month but not the last day of the year.';
	ELSE
		PRINT 'Today is not the last day of the month.';

/*
If we wanna run multiple statements in the IF or ELSE block. We need to wrap them in a
BEGIN-END keyword
*/

IF DAY(SYSDATETIME()) = 1
BEGIN
	PRINT 'Today is the first day of the month.';
	PRINT 'Starting first-of-month-day process.';
	/*... process code goes here ...	*/
	PRINT 'Finished first-of-month-day database process.';
END;
ELSE
BEGIN
	PRINT 'Today is not the first day of the month.';
	PRINT 'Starting non-first-of-month-day process.';
	/*	... process code goes here ...	*/
	PRINT 'Finished non-first-of-month-day database process';
END;


/*
WHILE FLOW STATEMENT
*/

-- The following code demonstrates how to write a loop that iterates 10 times:

-- Using WHILE LOOP

DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
	PRINT @i;
	SET @i = @i + 1;
END;

-- Using the BREAK statement to exit the loop. The following code breaks from the loop if
-- the value of @i is equal to 6

DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
	IF @i = 6 BREAK;
	PRINT @i;
	SET @i += 1;
END;

-- Using the CONTINUE to skip the rest of activity in the current iteration

DECLARE @i AS INT = 0;
WHILE @i < 10
BEGIN
	SET @i += 1;
	IF @i = 6 CONTINUE;
	PRINT @i;
END;

-- Using WHILE loop to populate dbo.Numbers with values 1 through 1000 in column n

SET NOCOUNT ON;
DROP TABLE IF EXISTS dbo.Numbers;
CREATE TABLE dbo.Numbers(n INT NOT NULL PRIMARY KEY);
GO

DECLARE @i AS INT = 1;
WHILE @i  <= 1000
BEGIN
	INSERT INTO dbo.Numbers(n) VALUES(@i);
	SET @i += 1;
END;

SELECT * FROM dbo.Numbers;

/*
 EXCEPTION TO THE USE OF TABLES
 -- you might need to execute some administrative
task for each index or table in your database. In such a case, it makes sense to use a cursor to
iterate through the index or table names one at a time and execute the relevant task for each of
those.

-- you should consider cursors is when your set-based solution
performs badly and you exhaust your tuning efforts using the set-based approach. As
mentioned, set-based solutions tend to be much faster, but in some exceptional cases the
cursor solution is faster. One such example is computing running aggregates using T-SQL

	HOW TO USE CURSOR TO PROCESS ROWS

Working with a cursor generally involves the following steps:
-- Declare the cursor based on a query
-- Open the cursor
-- Fetch the attributes values from the first cursor record into variables
-- As long as you have not reached the end of the cursor (while the value of a function called
@@FETCH_STATUS is 0), loop through the cursor records; in each iteration of the loop, perform
the processing needed for the current row, and then fetch the attribute values from the next
row into the variables
-- Close the cursor
-- Deallocate the cursor

*/

-- The following example with cursor code calculates the running total quantity for each
-- customer and month from the Sales.CustOrders view:

SET NOCOUNT ON;

DECLARE @Result AS TABLE
(
	custid INT,
	ordermonth DATE,
	qty INT,
	runqty INT,
	PRIMARY KEY(custid, ordermonth)
);

DECLARE 
	@custid AS INT,
	@prvcustid AS INT,
	@ordermonth AS DATE,
	@qty AS INT,
	@runqty AS INT;

DECLARE C CURSOR FAST_FORWARD /* read only, forward only */ FOR
	SELECT custid, ordermonth, qty
	FROM Sales.CustOrders
	ORDER BY custid, ordermonth;

OPEN C;

FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;

SELECT @prvcustid = @custid, @runqty = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @custid <> @prvcustid
		SELECT @prvcustid = @custid, @runqty = 0;

	SET @runqty += @qty;

	INSERT INTO @Result VALUES(@custid, @ordermonth, @qty, @runqty);

	FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;
END;

CLOSE C;

DEALLOCATE C;

SELECT
	custid,
	CONVERT(VARCHAR(7), ordermonth, 121) AS ordermonth,
	qty,
	runqty
FROM @Result
ORDER BY custid, ordermonth;


/*
	TEMPORARY TABLES

When you need to temporarily store tables in order to make data visible only to the current 
session or even only to the current batch. Another example would be when we dont have
permissions to create permanent tables in a user database.

SQL Server provides 3 kinds of temporary tables one might find more convenient to work with
than permanent tables: local temporary tables, global temporary tables and table variables

	Local Temporary Tables

This is useful to work with like tables. However, it only works in the session in which they
are created. CAnnot be accesed ny other sessions. It is prefixed with a # symbol.

	Global Temporary Tables (GTB)

AS at SQL Server 2016. GTB only works on SQL server box product and not on Azure SQL database
This works within the session that creates it. It also can be accessed by other sessions. It gets
destroyed when the session that creates it is disconnected. It can be created by prefixing
the table nname with double # symbol.

NOTE: If you want a global temporary table to be created every time SQL Server starts, and you
don’t want SQL Server to try to destroy it automatically, you need to create the table from a
stored procedure that is marked as a startup procedure.


*/

-- The following code illustrates this scenario using a local temporary table

DROP TABLE IF EXISTS #MyOrderTotalsByYear;
GO

CREATE TABLE #MyOrderTotalsByYear
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty		  INT NOT NULL
);

INSERT INTO #MyOrderTotalsByYear(orderyear, qty)
	SELECT
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
		INNER JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM #MyOrderTotalsByYear AS Cur
	LEFT OUTER JOIN #MyOrderTotalsByYear AS Prv ON Cur.orderyear = Prv.orderyear + 1;


-- Try the following code in another session (It has been destroyed)

USE TSQLV4;

SELECT orderyear, qty FROM #MyOrderTotalsByYear;

-- It is general practice to clean up resources when one is done working with them

DROP TABLE IF EXISTS #MyOrderTotalsByYear;

-- The following illustrates the use of global temporary table

DROP TABLE IF EXISTS ##Globals

CREATE TABLE ##Globals
(
	id sysname NOT NULL PRIMARY KEY, -- sysname data type is used internally to represent identifiers
	val SQL_VARIANT NOT NULL		 -- SQL_VARIANT is generic data type that stores value of almost any base type
);

INSERT INTO ##Globals(id, val) VALUES('i', CAST(10 AS INT));

SELECT val FROM ##Globals WHERE id = N'i';

-- The following code can be used from any session to destroy the global temporary table

DROP TABLE IF EXISTS ##Globals;

-- The following code uses a table variable instead of a local temporary table to
-- compare total order quantities of each order year with the year before:

DECLARE @MyOrderTotalsByYear TABLE
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty		  INT NOT NULL
);

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
	SELECT
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O INNER JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate);

	SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
	FROM @MyOrderTotalsByYear AS Cur LEFT OUTER JOIN @MyOrderTotalsByYear AS Prv
				ON Cur.orderyear = Prv.orderyear + 1;

-- The above can be implemented using windows function

SELECT
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS curyearqty,
	LAG(SUM(OD.qty)) OVER(ORDER BY YEAR(orderdate)) AS prvyearqty
FROM Sales.Orders AS O INNER JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

/*
	Table types
You can use a table type to preserve a table definition as an object in the database. Later you
can reuse it as the table definition of table variables and input parameters of stored procedures
and user-defined functions. Table types are required for table-valued parameters (TVPs).

The benefit of the table type feature extends beyond just helping you shorten your code. As
I mentioned, you can use it as the type of input parameters of stored procedures and functions,
which is a useful capability.

*/

-- The following code creates a table type called dbo.OrderTotalsByYear in the current database:

DROP TYPE IF EXISTS dbo.OrderTotalsByYear;

CREATE TYPE dbo.OrderTotalsByYear AS TABLE
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty		  INT NOT NULL
);

-- We can easily create a table variable from a type(if it exists)

DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear

/*
the following code declares a variable called
@MyOrderTotalsByYear of the new table type, queries the Orders and OrderDetails tables to
calculate total order quantities by order year, stores the result of the query in the table
variable, and queries the variable to present its contents:
*/

DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
	SELECT
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O INNER JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate);


SELECT orderyear, qty FROM @MyOrderTotalsByYear;