/* CHAPTER 10 Transactions and concurrency	*/

/*
This chapter covers transactions and their properties. How SQL Server handles users concurrently
trying to access same data? How to troubleshoot blocking situations? How SQL Server uses locks
to isolate inconsistent data? How to contol the consistency level when querying data with isolation 
levels?
*/

/*
	TRANSACTIONS

A transaction is a unit of work that contains multiple activities such as querying and modifying data
 and that can also change the data definition.

 We can define the boundaries of a transaction with the following:

 BEGIN TRAN : start transaction
 COMMIT TRAN : commit transaction
 ROLLBACK TRAN: to undo the transaction

 When we do not mark the boundaries of a transaction explicitly, by default, SQL Server treats
 each individual statement as a transaction. that is, by default, SQL Server automatically
 commits the transaction at the end of each statement.

 We can change the way SQL server handles implicit transaction with a session option called
 IMPLICIT_TRANSACTIONS. This option is turned off by default. However, when this feature is
 turned ON. there is no need to use BEGIN TRAN to initiate the start of every transaction.
 Rather, we are only obliged to use COMMIT TRAND and ROLLBACK TRAN to end or undo thne transaction
 that are initiated by default.

Transactions have 4 properties: atomicity, consistency, isolation and durability

NOTE: the variable @@TRANCOUNT tells us whether there is an open transaction or not

*/

-- Here is an example of marking the boundaries of a transaction with 2 INSERT statements

BEGIN TRAN;
	INSERT INTO dbo.T1(keycol, col1, col2) VALUES(4, 101, 'C');
	INSERT INTO dbo.T2(keycol, col1, col2) VALUES(4, 201, 'X');
COMMIT TRAN;

SELECT @@TRANCOUNT; -- ) returns not an open transaction otherwise, it is an open transaction

-- For example, the following code defines a transaction that records information about a new
-- order in the TSQLV4 database:

USE TSQLV4;

-- Start a new transaction

BEGIN TRAN;

	--Declare a variable
	DECLARE @neworderid AS INT;

	-- insert a new order into the Sales.Orders table
	INSERT INTO Sales.Orders
			(custid, empid, orderdate, requireddate, shippeddate,
			shipperid, freight, shipname, shipaddress, shipcity,
			shippostalcode, shipcountry)
	VALUES
		(85, 5, '20090212', '20090301', '20090216',
		3, 32.38, N'Ship to 85-B', N'6789 rue de l''Abbaye', N'Reims',
		N'10345', N'France');

	-- Save the new order ID in a variable
	SET @neworderid = SCOPE_IDENTITY();

	-- Return the new order ID
	SELECT @neworderid AS neworderid;

	-- Insert order lines for the new order into Sales.OrderDetails
	INSERT INTO Sales.OrderDetails
		(orderid, productid, unitprice, qty, discount)
	VALUES(@neworderid, 11, 14.00, 12, 0.000),
		  (@neworderid, 42, 9.80, 10, 0.000),
		  (@neworderid, 72, 34.80, 5, 0.000);

	-- Commit the transaction
COMMIT TRAN;

-- Run then following code for cleanup

DELETE FROM Sales.OrderDetails
WHERE orderid > 11077;

DELETE FROM Sales.Orders
WHERE orderid > 11077;

/*
	LOCKS and BLOCKING

By default, SQL Server box product uses a pure locking model to enforce the isolation property
of transactions.

Azure SQL Database uses row-versioning model by default. If one is to test this following code
in this chapter. The property READ_COMMITTED_SNAPSHOT should be turned off to swith to the locking
model by default. 

ALTER DATABASE TSQLV4 SET READ_COMMITTED_SNAPSHOT OFF;

There are 2 types of lock modes: exclusive and shared lock

For SQL Server box product, when trying to modify data, by default, the transaction requests
an exlusive lock on the data resource. What this means is that, other transactions cannot
have exclusive lock or perhaps access to the data until we COMMIT TRAN or ROLLBACK TRAN.

However, when reading a data, a shared lock is by default requested by the transaction. 
Therefore, other transactions can also initiate a shared lock or perhaps read the same data
resource. In this case, isolation level is by default READ COMMITTED.

When modifying a data, the lock mode and duration required cannot be changed. However, when
reading a data, it is possible to change way locking is handled by changing the isolation level.

In Azure SQL database, the default isolation level is READ COMMITTED SNAPSHOT. With this a 
combination of locking and row-versioning are implemented. This means if a transaction is
modifying a data row, it is also possible for another transaction to read the same data but in this case
the data being read by another transaction would be last stable consistent data. This happens
pretty much within the time of the first transaction.


*/

/*
	TROUBLESHOOTING BLOCKING

Blocking is normal in a system as long as requests are satisfied within a reasonable amount
of time. However, if some requests wait too long, you might need to troubleshoot the blocking
situation and see whether you can do something to prevent such long latencies.

For example, long-running transactions result in long wait. Transction can be shortened by moving activities
in the unit of work outside the transaction. A bug can also make the transaction open for a longtime
long time. 
*/

USE TSQLV4;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRAN;
	-- connection 1
	UPDATE Production.Products
	SET unitprice += 1.00
	WHERE productid = 2;

	-- connection 2 (highlight only below and run it)
	SELECT productid, unitprice
	FROM Production.Products
	WHERE productid = 2;

-- sys.dm_tran_locks provides dynamic info about various aspects of your system

SELECT -- use * to explore other available attributes
	request_session_id AS sid,
	resource_type AS restype,
	resource_database_id AS dbid,
	DB_NAME(resource_database_id) AS dbname,
	resource_description AS res,
	resource_associated_entity_id AS resid,
	request_mode AS mode,
	request_status AS status
FROM sys.dm_tran_locks;

SELECT @@SPID AS session_id;  -- To show session id

/*

*/
SELECT -- use * to explore
	session_id AS sid,
	connect_time,
	last_read,
	last_write,
	most_recent_sql_handle
FROM sys.dm_exec_connections
WHERE session_id IN(52);