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


*/