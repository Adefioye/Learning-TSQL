/*	CONTROLLING CONCURRENCY	*/

/*
syntax:

SET TRANSACTION ISOLATION LEVEL
	{READ UNCOMMITTED | READ COMMITTED | REPEATABLE READ | SERIALIZABLE | SNAPSHOT}

	READ UNCOMMITTED

This is the least restrictive isolation level. It reads rows modified by other transactions
without been committed/rolled back.

READ UNCOMMITTED can have dirty reads, non-repeatable reads and phantom reads.

	READ COMMITTED

This is the default behavior of SQL server. It would not allow a transaction to read
data from another transaction until it is committed or rolled back.

READ COMMITTED prevents dirty reads, but allows non-repeatable reads and phantom reads.
with READ COMMITTED, one can be blocked by another transaction.

	REPEATABLE READ

This prevents reading out uncommitted transactions. if some data is read under this isolation
level, other transactions cannot modify the data until REPEATABLE READ transaction 
finishes.

	SERIALIZABLE

This is most restrictive isolation level.

QUERY with WHERE clause based on an index range --> Locks only that records
QUERY not based on an index usage --> Locks the conplete table

SERIALIZABLE is good when data consistency is a must. It prevents dirty, non-repeatable
and phantom reads.
*/

-- USing SERIALIZABLE

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRAN
SELECT * 
FROM customers
WHERE customer_id BETWEEN 1 AND 10;

-- After completing some mathematical operation, select customer_id between 1 and 10
SELECT * 
FROM customers
WHERE customer_id BETWEEN 1 AND 10;

-- Commit the transaction
COMMIT TRAN

/*
	SNAPSHOT

ALTER DATABASE nyDatabaseName SET ALLOW_SNAPSHOT_ISOLATION ON
SET TRANSACTION ISOLATION LEVEL SNAPSHOT

It prevents dirty, non-repeatable and phantom reads without locking. good for data consistency.
However, the size of the tempDB increases.

SNAPSHOT is iseful when data consistency is a must and we dont want blocking.

	WITH( NOLOCK)

This is used to read uncommitted data.

READ UNCOMMITTED applies to the entire connection/ WITH (NO LOCK) option applies to 
specific table.

Remember that the main difference between READ COMMITTED SNAPSHOT and the SNAPSHOT 
isolation level is that with the SNAPSHOT isolation level you can only see the 
committed changes that occur before the start of a transaction and the changes 
made by that transaction.

*/