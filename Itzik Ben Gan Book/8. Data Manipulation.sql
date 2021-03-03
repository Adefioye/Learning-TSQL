/*	DATA MODIFICATION	

DML involves set of statements for manipulating data. However DML can also be used for
data retrieval. This includes statements SELECT, INSERT, UPDATE, DELETE, TRUNCATE, and MERGE.

	INSERTING DATA

T-SQL provides several statements for inserting data into tables: INSERT VALUES,
INSERT SELECT,INSERT EXEC, SELECT INTO, BULK INSERT.
*/

-- Learning to use INSERT VALUES

USE TSQLV4;

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
	orderid		INT			NOT NULL
		CONSTRAINT PK_Orders PRIMARY KEY,
	orderdate	DATE		NOT NULL
		CONSTRAINT DFT_orderdate DEFAULT(SYSDATETIME()),
	empid		INT			NOT NULL,
	custid		VARCHAR(10)	NOT NULL
);

/* The below code demonstrates how to use INSERT VALUES statement to insert a single row
into the Orders table:

Specifying the column names is OPTIONAL. DOing it ony allows for clear association between
values and columns. 

If a value is not specified for a column. SQL Server will use a default value if one was
defined for the column. if default value is not specified and the column allows NULLs, a NULL
will be used. If no default is defined and column does not allow NULLs, INSERT statement
will fail.


*/ 

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	VALUES(10001, '20160212', 3, 'A');

-- The below code relies on the default SYSDATETIME since orderdate value is not specified

INSERT INTO dbo.Orders(orderid, empid, custid)
	VALUES(10002, 5, 'B');

-- T-SQL also support specification of multiple rows in the VALUES clause. The code below is
-- treated as a transaction. If any row fails to enter the table, none of the rows in the
-- INSERT statement will enter the table.

INSERT INTO dbo.Orders
	(orderid, orderdate, empid, custid)
	VALUES
	(10003, '20160213', 4, 'B'),
	(10004, '20160214', 1, 'A'),
	(10005, '20160213', 1, 'C'),
	(10006, '20160215', 3, 'C');

-- There is more to this enhanced VALUES clause

SELECT *
FROM (	VALUES
			(10003, '20160213', 4, 'B'),
			(10004, '20160214', 1, 'A'),
			(10005, '20160213', 1, 'C'),
			(10006, '20160215', 3, 'C'))
		AS O(orderid, orderdate, empid, custid);

/*
	INSERT SELECT

THis inserts a set of rows returned by a SELECT query into a traget table. It is important
to note that the rule about default constraint and column nullability explained before applies
to the INSERT SELECT statement.

Also, if any row fails to enter the table, none of the rows enters thne table.

NOTE: If you include a system function such as SYSDATETIME in the inserted query, the
function gets invoked only once for the entire query and not once per row. The
exception to this rule is if you generate globally unique identifiers (GUIDs) using the
NEWID function, which gets invoked per row. 
*/

-- The following code inserts into the dbo.Orders table the result of a query against the Sales.Orders table and returns
-- orders that were shipped to the United Kingdom:

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE shipcountry = 'UK';


/*
	INSERT EXEC

You use INSERT EXEC statement to insert a result set froma stored procedure or a dynamic SQL
batch into the ytarget table 
*/

-- The code below creates a stored procedure called Sales.GetOrders and it returns orders
-- that were shipped to a specified input country(with the @country parameter)

IF OBJECT_ID('Sales.GetOrders', 'U') IS NOT NULL DROP PROC Sales.GetOrders;
GO

CREATE PROC Sales.GetOrders
	@country AS NVARCHAR(40)
AS

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE shipcountry = @country
GO

-- To test the stored procedure, execute it with the input country France:

EXEC Sales.GetOrders @country = 'USA';

EXEC Sales.GetOrders @country = 'France';

-- By using an INSERT EXEC statement, you can insert the result set returned from the
-- procedure into the dbo.Orders table:

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	EXEC Sales.GetOrders @country = N'France';


/*
	SELECT INTO statement


*/