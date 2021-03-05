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

This is a non-standard T-SQL statement that creates a target table and populates it with data.
This statement cannot be used to insert data into an existing table.

NOTE: The target table’s structure and data are based on the source table. The SELECT INTO
statement copies from the source the base structure (such as column names, types, nullability,
and identity property) and the data. It does not copy from the source constraints, indexes,
triggers, column properties such as SPARSE and FILESTREAM, and permissions. If you need
those in the target, you’ll need to create them yourself.


*/

-- The following code creates a table called dbo.Orders and populates it with all rows
-- from the Sales.Orders table:

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders;


-- If you need to use a SELECT INTO statement with set operations, you specify the INTO
-- clause right in front of the FROM clause of the first query. For example, the following
-- SELECT INTO statement creates a table called Locations and populates it with the result of an
-- EXCEPT set operation, returning locations that are customer locations but not employee
-- locations:

IF OBJECT_ID('dbo.Locations', 'U') IS NOT NULL DROP TABLE dbo.Locations;

SELECT country, region, city
INTO dbo.Locations
FROM Sales.Customers

EXCEPT

SELECT country, region, city
FROM HR.Employees;

/*
	BULK INSERT statement

The BULK INSERT statement is used to insert into an existing table data originating from a
file. In the statement, you specify the target table, the source file, and options. You can specify
many options, including the data file type (for example, char or native), the field terminator,
the row terminator, and others—all of which are fully documented.

*/

-- The following code bulk inserts the contents of the file c:\temp\orders.txt into
-- the table dbo.Orders, specifying that the data file type is char, the field terminator is a comma,
-- and the row terminator is the newline character:

BULK INSERT dbo.Orders FROM 'C:\temp\orders.txt'
	WITH
		(
			DATAFILETYPE = 'char',
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n'
		);

SELECT *
FROM dbo.Orders;

/*
	IDENTITY PROPERTY and SEQUENCE OBJECT

SQL Server supports 2 built-in solutions to automatically generate numeric keys. These are
the IDENTITY PROPERTY and SEQUENCE OBJECT. The identity works well for some scenarios but has
many limitations. The sequence object helps to resolve many of identity's limitations.

Identity is a standard column property. You can define this property for a column with any
numeric type with a scale of zero (no fraction). When defining the property, you can
optionally specify a seed (the first value) and an increment (a step value). If you don’t provide
those, the default is 1 for both. You typically use this property to generate surrogate keys,
which are keys that are produced by the system and are not derived from the application data.

NOTE: In INSERT statement, the IDENTITY column must be ignored

@@identity and SCOPE_IDENTITY are used to get last value of identity generated in the current
session. Therefore, they both do not account for inserts done in other session.

To be able to get the last identity value in the table regardless of session, the
IDENT_CURRENT function is used.

SQL Server uses performance cache for the IDENTITY property, which can result in gaps between the 
keys when there's an unclean termination of the SQL Server(for example, power failure ). Hence,
teh IDENTITY property should be used when we wanna allow gaps between the keys. 

We can use IDENTITY_INSERT to specify our own explicit values for the identity column.
Unfortunately, there is no way to update the values of the rows if and when necessary.



*/

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
	keycol  INT			NOT NULL	IDENTITY(1, 1)
		CONSTRAINT PK_T1 PRIMARY KEY,
	datacol VARCHAR(10)	NOT NULL CHECK(datacol LIKE '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]%')
);

-- The table also contains a character string column called datacol, whose data is 
-- restricted with a CHECK constraint to strings starting with an alphabetical character.

-- Identity column ignored

INSERT INTO dbo.T1(datacol) VALUES('AAAAA'),('CCCCC'),('BBBBB');

SELECT * FROM dbo.T1;

-- The generic $identity word can be used to return the identity column

SELECT $identity FROM dbo.T1;

-- the following code inserts a new row into the table T1, obtains the newly
-- generated identity value and places it into a variable by querying the SCOPE_IDENTITY
-- function, and queries the variable:

DECLARE @new_key AS INT;

INSERT INTO dbo.T1(datacol) VALUES('AAAAA');

SET @new_key = SCOPE_IDENTITY()

SELECT @new_key AS new_key;

-- Using IDENT_FUNCTION to get the last identity value in table regardless of session

SELECT 
	SCOPE_IDENTITY() AS [SCOPE_IDENTITY],
	@@IDENTITY AS '@@IDENTITY',
	IDENT_CURRENT('dbo.T1') AS 'IDENT_FUNCTION';

-- Run the following INSERT which conflicts with the CHECK constraint

INSERT INTO dbo.T1(datacol) VALUES('12345');

-- Lets check the IDENTITY functions. It was shockingly observed that IDENT_FUNCTION reflects
-- the increase of the current identity value from 5 to 6 in spite of the failure of the 
-- INSERT statement due to its conflict with the CHECK constraint on that column.

SELECT 
	SCOPE_IDENTITY() AS [SCOPE_IDENTITY],
	@@IDENTITY AS '@@IDENTITY',
	IDENT_CURRENT('dbo.T1') AS 'IDENT_FUNCTION';

-- Let us do another insert

INSERT INTO dbo.T1(datacol) VALUES('EEEEE');

-- The query below shows a gap in keycol from 5 to 7

SELECT * FROM dbo.T1;

-- The following shows us how to insert a row into T1 with an explicit 5 on the keycol

 SET IDENTITY_INSERT dbo.T1 ON;
 INSERT INTO dbo.T1(keycol, datacol) VALUES(6, 'FFFFFF');
 SET IDENTITY_INSERT dbo.T1 OFF;

 

 /*
	SEQUENCE OBJECT
	
This serves as an alternative to IDENTITY property. It is not tied to one column rather it is
an ondependent object that can be applied to more than 1 column in the table.Whenever a new
value is to be generated, you invoke a function on the object and then returns a value to be 
used wherever you like.

To create a sequence object, we use CREATE SEQUENCE AS <specify-datatype>. If the datatype is 
not passed, BIGINT is assumed by default. It is also supported by MINVALUE<val>, MAXVALUE<val>,
START WITH <val>, INCREMENT BY <val>.

ITs a must to specify TYPE, MINVALUE and CYCLE. Others can be set as defaults.

The sequence object also supports a caching option (CACHE <val> | NO CACHE) that tells
SQL Server how often to write the recoverable value to disk. For example, if you specify a
cache value of 10,000, SQL Server will write to disk every 10,000 requests, and in between
disk writes, it will maintain the current value and how many values are left in memory.

You can change any of the sequence properties except the data type with the ALTER
SEQUENCE command (MINVAL <val>, MAXVAL <val>, RESTART WITH <val>,
INCREMENT BY <val>, CYCLE | NO CYCLE, or CACHE <val> | NO CACHE).

 
*/

-- For example, suppose you want to create a sequence that will help you generate order IDs.
-- You want it to be of an INT type, have a minimum value of 1 and a maximum value that is the
-- maximum supported by the type, start with 1, increment by 1, and allow cycling. Here’s the
-- CREATE SEQUENCE command you would use to create such a sequence:

CREATE SEQUENCE dbo.SeqOrderIDs AS INT
	MINVALUE 1
	CYCLE;

-- We can prevent dbo.SeqOrderIDs from cycling by using the ALTER SEQUENCE command.

ALTER SEQUENCE dbo.SeqOrderIDs
	NO CYCLE;

-- To generate a new sequence value, you need to invoke the standard function 
-- NEXT VALUE FOR <sequence name>

SELECT NEXT VALUE FOR dbo.SeqOrderIDs;

-- Notice that unlike IDENTITY property. there is no need to insert a row into a table in
-- order to generate a new value.

-- Some applications need to generate the new value before using it. With sequences, you can
-- store the result of the function in a variable and use it later in the code. To
-- demonstrate this, first create a table called T1 with the following code:

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
	keycol  INT			NOT NULL
		CONSTRAINT PK_T1 PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
);

-- The following code generates a sequence value, stores it in a variable, and then uses
-- the variable in an INSERT statement to insert a row into the table:

DECLARE @neworderid AS INT = NEXT VALUE FOR dbo.SeqOrderIDs;
INSERT INTO dbo.T1(keycol, datacol) VALUES(@neworderid, 'a'); 

SELECT * FROM dbo.T1;

-- We can also just specify NEXT VALUE FOR function as part of our INSERT statement

INSERT INTO dbo.T1(keycol, datacol) VALUES(NEXT VALUE FOR dbo.SeqOrderIDs, 'b');

SELECT * FROM dbo.T1;

-- Unlike identity, we can generate new sequence values in an UPDATE statement

UPDATE dbo.T1 
	SET keycol = NEXT VALUE FOR dbo.SeqOrderIDs;

SELECT * FROM dbo.T1;

-- To get information about our sequence, query a view called sys.sequences. For example, to
-- find the current sequence value in the SeqOrderIDs sequence, you use the following code:

SELECT current_value
FROM sys.sequences
WHERE OBJECT_ID = OBJECT_ID('dbo.SeqOrderIDs');

-- SQL Server also allows for the control of the order of the assigned sequence values in a 
-- multirow insert by using an OVER clause

INSERT INTO dbo.T1(keycol, datacol)
	SELECT 
		NEXT VALUE FOR dbo.SeqORderIDs OVER(ORDER BY hiredate),
		LEFT(firstname, 1) + LEFT(lastname, 1)
	FROM HR.Employees;

SELECT * FROM dbo.T1;

-- Another extension to the standard allows the use of the NEXT VALUE FOR function in a 
-- default constraint

ALTER TABLE dbo.T1
	ADD CONSTRAINT DFT_T1_keycol
		DEFAULT (NEXT VALUE FOR SeqOrderIDs) FOR keycol;

-- Let us insert new row, this time we don't have to indicate a value for keycol

INSERT INTO dbo.T1(datacol) VALUES('c');

SELECT * FROM dbo.T1;

/*Unlike with identity, which you cannot add to or remove from an existing column, you can
add or remove a default constraint. The preceding example showed how to add a default
constraint to a table and associate it with a column. To remove a constraint, use the syntax:
ALTER TABLE <table_name> DROP CONSTRAINT <constraint_name>

There’s another extension to the standard you can use to allocate a whole range of sequence
values at once by using a stored procedure called sp_sequence_get_range. The idea is that
it is efficient to update a range of sequence at once whenan application needs one.

SQL_VARIANT is a generic data type that can hold within it various base data types. The
sp_sequence_get_range procedure uses this type for several of its parameters,
including the output parameter @range_first_value.

Note that like with identity, the sequence object does not guarantee you will have no gaps. If
a new sequence value was generated by a transaction that failed or intentionally rolled back,
the sequence change is not undone. Also, as mentioned earlier with identity, sequence objects
support a performance cache feature, which can result in gaps when there’s an unclean
termination of the SQL Server process.
*/

DECLARE @first AS SQL_VARIANT;

EXEC sys.sp_sequence_get_range
	@sequence_name = 'dbo.SeqOrderIDs',
	@range_size = 1000000,
	@range_first_value = @first OUTPUT;

SELECT @first;

-- Let us run the following code for cleanup

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

IF OBJECT_ID('dbo.SeqOrderIDs', 'U') IS NOT NULL DROP SEQUENCE dbo.SeqOrderIDs;

/*
 DELETING DATA

There are 2 statements for deleting rows from a table: DELETE and TRUNCATE.

DELETE statement deletes data from a table based on optional filter predicate. DELETE statement
is usually expensive when large numbe rof rows is deleted bacuse it is a fully logged operation.

TRUNCATE statement deletes a whole table and it is minimally logged. For performance difference,
when deleting table with millions of rows, itis better to use TRUNCATE.

TRUNCATE and DELETE also have a functional difference when the table has an identity
column. TRUNCATE resets the identity value back to the original seed, but DELETE doesn’t.

TRUNCATE is not allowed when the table has a foreign key. It can only be allowed only when 
the foreign reference has been dropped using ALTER TABLE DROP CONSTRAINT. It can be re-created
using ALTER TABLE ADD CONSTRAINT.

SQL Server 2016 enhances the TRUNCATE statement by supporting the truncation of individual partitions. You can specify a
list of partitions and partition ranges (with the keyword TO between the range delimiters). As

Table partitioning is about dividing your table into multiple units called partitions,
mainly for manageability purposes. This allows handling processes like importing data
into the table and purging historic data to be handled more efficiently.

NOTE: T-SQL supports a nonstandard DELETE syntax based on joins. This means we can delete
rows from a table based on filter against attributes in related rows from another table.

*/

-- Run the following code ro create and populate those tables:

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers
(
	custid			INT				NOT NULL,
	companyname		NVARCHAR(40)	NOT NULL,
	contactname		NVARCHAR(30)	NOT NULL,
	contacttitle	NVARCHAR(30)	NOT NULL,
	address			NVARCHAR(60)	NOT NULL,
	city			NVARCHAR(15)	NOT NULL,
	region			NVARCHAR(15)	NULL,
	postalcode		NVARCHAR(10)	NULL,
	country			NVARCHAR(15)	NOT NULL,
	phone			NVARCHAR(24)	NOT NULL,
	fax				NVARCHAR(24)	NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
	orderid			INT NOT NULL,
	custid			INT NULL,
	empid			INT NOT NULL,
	orderdate		DATE NOT NULL,
	requireddate	DATE NOT NULL,
	shippeddate		DATE NULL,
	shipperid		INT NOT NULL,
	freight			MONEY NOT NULL
		CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname		NVARCHAR(40) NOT NULL,
	shipaddress		NVARCHAR(60) NOT NULL,
	shipcity		NVARCHAR(15) NOT NULL,
	shipregion		NVARCHAR(15) NULL,
	shippostalcode	NVARCHAR(10) NULL,
	shipcountry		NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid),
	CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
		REFERENCES dbo.Customers(custid)
);
GO

INSERT INTO dbo.Customers SELECT * FROM Sales.Customers;
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

-- The following statement deletes, from the dbo.Orders table, all orders that
-- were placed prior to 2015:

DELETE FROM dbo.Orders
WHERE orderdate < '20150101';

-- For example, suppose you had a partitioned table called T1 and you wanted to truncate
-- partitions 1, 3, 5, and 7 through 10. You would use the following code to achieve this:

TRUNCATE TABLE db.T1 WITH ( PARTITIONS(1, 3, 5, 7 TO 10) ); -- SQL Server 2016

-- DELETE based on a join, 
-- FROM in the DELETE clause is optional, we can specify DELETE O instead of DELETE FROM O

DELETE FROM O
FROM dbo.Orders AS O
	INNER JOIN dbo.Customers AS C ON O.custid = C.custid
WHERE C.country = 'USA';

-- Since DELETE based on JOIN is non-standard, We can use standard code by using subqueries
-- instead of joins. For example, the following DELETE statement uses a subquery to achieve
-- the same task:

DELETE FROM dbo.Orders
WHERE EXISTS
	(SELECT *
		FROM dbo.Customers AS C
		WHERE Orders.custid = C.custid AND C.country = 'USA');

-- Let us cleanup the code by deleting dbo.Orders, dbo.Customers

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;


/*
	UPDATING DATA

T-SQL supports a standard UPDATE statement that can be used to update rows in a table.
T-SQL also supports nonstandard forms of the UPDATE staement with joins and with variables.

To observe the change we can run SELECT statement on the filter before and after the 
UPDATE to see changes. We can also use a clause called OUTPUT.

T-SQL supports compound assignment operators: += (plus equal), –= (minus equal), *=
(multiplication equal), /= (division equal), %= (modulo equal), and others.
*/

-- Lets run the following code to craete and populate Orders and Orderdetails table 
-- created in the dbo.schema

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;

CREATE TABLE dbo.Orders
(
	orderid			INT				NOT NULL,
	custid			INT				NULL,
	empid			INT				NOT NULL,
	orderdate		DATE			NOT NULL,
	requireddate	DATE			NOT NULL,
	shippeddate		DATE			NULL,
	shipperid		INT				NOT NULL,
	freight			MONEY			NOT NULL
		CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname		NVARCHAR(40)	NOT NULL,
	shipaddress		NVARCHAR(60)	NOT NULL,
	shipcity		NVARCHAR(15)	NOT NULL,
	shipregion		NVARCHAR(15)	NULL,
	shippostalcode	NVARCHAR(10)	NULL,
	shipcountry		NVARCHAR(15)	NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

CREATE TABLE dbo.OrderDetails
(
	orderid			INT				NOT NULL,
	productid		INT				NOT NULL,
	unitprice		MONEY			NOT NULL
		CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty				SMALLINT		NOT NULL
		CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
	discount		NUMERIC(4, 3)	NOT NULL
		CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
		REFERENCES dbo.Orders(orderid),
	CONSTRAINT CHK_discount CHECK(discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK(qty > 0),
	CONSTRAINT CHK_unitprice CHECK(unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

-- Let us increase the discount of all order details for product 51 by 5 percent:

UPDATE dbo.OrderDetails
	SET discount = discount + 0.05
WHERE productid = 51; 

-- We could express the above using a compound assignment operator

UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE productid = 51;

-- All-at-once-operation happens to expressions in the same logical phase, that is, expressions
-- are evaluated as a set.

UPDATE dbo.T1
	SET col1 = col1 + 10, col2 = col1 + 10;

-- For the above query both expressions are evaluated at the same time in the SET clause.
-- Hence, the same value of col1 is used by both columns(col1 and col2)

-- The UPDATE statement is used to increase the discount of all order details of orders 
-- placed by customer 1 by 5 percent.

UPDATE OD
	SET discount += 0.05
FROM dbo.OrderDetails AS OD INNER JOIN dbo.Orders AS O
	ON OD.orderid = O.orderid
WHERE O.custid = 1;

-- We can also specify the full table name instead of alias by sticking to the standard 
-- method instead of UPDATE with a JOIN approach.

 -- UPDATE with JOIN allows us access to attributes of the other table

UPDATE T1
	SET col1 = T2.col1,
		col2 = T2.col2,
		col3 = T2.col3
FROM dbo.T1 JOIN dbo.T2 ON T2.keycol = T1.keycol
WHERE T2.col4 = 'ABC';

-- Attempt to write the above code using STANDARD method results in lengthy query as shown

UPDATE dbo.T1
	SET col1 = (SELECT col1
				FROM dbo.T2
				WHERE T2.keycol = T1.keycol),
		col2 = (SELECT col2
				FROM dbo.T2
				WHERE T2.keycol = T1.keycol),
		col3 = (SELECT col3
				FROM dbo.T2
				WHERE T2.keycol = T1.keycol)
WHERE EXISTS
	(SELECT *
		FROM dbo.T2
		WHERE T2.keycol = T1.keycol AND T2.col4 = 'ABC');

/*
Standard SQL has support for row constructors (also known as vector expressions) that
were only implemented partially in T-SQL. As of SQL Server 2016, many aspects of row
constructors have not yet been implemented, including the ability to use them in the SET
clause of an UPDATE statement like this:
*/

UPDATE dbo.T1
	SET (col1, col2, col3) =
		(SELECT col1, col2, col3
			FROM dbo.T2
			WHERE T2.keycol = T1.keycol)
WHERE EXISTS
	(SELECT *
		FROM dbo.T2
		WHERE T2.keycol = T1.keycol AND T2.col4 = 'ABC');

/*
	Assignment UPDATE

T-SQL supports a proprietary UPDATE syntax that both updates data in a table and assigns
values to variables at the same time. This syntax saves you the need to use separate UPDATE
and SELECT statements to achieve the same task.

One of the common cases for which you can use this syntax is in maintaining a custom
sequence/autonumbering mechanism when the identity column property and the sequence
object don’t work for you. One example is when you need to guarantee that there are no gaps
between the values. To achieve this, you keep the last-used value in a table, and whenever you
need a new value, you use the
*/


IF OBJECT_ID('dbo.MySequences', 'U') IS NOT NULL DROP TABLE dbo.MySequences;

CREATE TABLE dbo.MySequences
(
	id VARCHAR(10)	NOT NULL
		CONSTRAINT PK_MySequences PRIMARY KEY(id),
	val INT			NOT NULL
);
INSERT INTO dbo.MySequences VALUES('SEQ1', 0);

DECLARE @nextval AS INT;

UPDATE dbo.MySequences
	SET @nextval = val += 1
WHERE id = 'SEQ1';

SELECT @nextval;

SELECT * FROM dbo.MySequences;

-- Let us cleanup

IF OBJECT_ID('dbo.MySequences', 'U') IS NOT NULL DROP TABLE dbo.MySequences;

