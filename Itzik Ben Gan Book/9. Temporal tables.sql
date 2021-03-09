/*
	CHAPTER 9 TEMPORAL TABLES

When we modify data in tables. we lose track of the premodified state of the rows. But what
if we need access historical states of the data. SQL Server 2016 and beyond provides of with
a built-in feature called system-versioned temporal tables. This provides built-in feature 
that is both simpler and more efficient than a customized solution.

A system-versioned temporal table has two columns representing the validity period of the row
, plus a linked history table with a mirrored schema holding older states of modified rows.

When we query data. we get access to the current table/stste of then data. When we modify data,
SQL Server automatically updates the period column and moves older versions of rows to the history table.
Therefore, when we want to query historical state of the data, we still query the same table but
with a clause indicating that one wants to see an older state or period of time. SQL Server queries
the current and history tables behind the scenes as needed.

The SQL standard supports three types of temporal tables:

-- System-versioned temporal tables rely on the system transaction time to define the
validity period of a row.

-- Application-time period tables rely on the application’s definition of the validity period
of a row. This means you can define a validity period that will become effective in the
future.

-- Bitemporal combines the two types just mentioned (transaction and valid time).

This chapter covers system-versioned temporal tables in three sections: creating tables,
modifying data, and querying data.

*/

/*
	CREATING TABLES

When you create a system-versioned temporal table, you need to make sure to set the following 
elements:

-- Primary key
-- Two columns with DATETIME2 which are non-nullable and represent the start and end of the
rows validity period in the UTC time zone
-- The start column should be marked with the option GENERATED ALWAYS AS ROW START
-- The end column should be marked with the option GENERATED ALWAYS AS ROW END
-- A designation of the period columns with the option PERIOD FOR SYSTEM_TIME(start, end)
-- The table option SYSTEM_VERSIONING, which should be set to ON
-- A linked history table(which SQL Server can create for you) to hold the past rows of 
modified rows

	Optionally, you can mark the period columns as hidden so that when you're querying the
table with SELECT * they won't be returned and when you're inserting the data they'll be
ignored.
*/

-- Run the following code to create a system-versioned temporal table called Employees and a
-- linked history table called EmployeesHistory:

USE TSQLV4;

DROP TABLE IF EXISTS dbo.Employees;

CREATE TABLE dbo.Employees
(
	empid		INT								NOT NULL
		CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
	empname		VARCHAR(25)						NOT NULL,
	department	VARCHAR(50)						NOT NULL,
	salary		NUMERIC(10, 2)					NOT NULL,
	sysstart	DATETIME2(0) 
		GENERATED ALWAYS AS ROW START	HIDDEN	NOT NULL,
	sysend		DATETIME2(0) 
		GENERATED ALWAYS AS ROW END		HIDDEN	NOT NULL,
	PERIOD FOR SYSTEM_TIME (sysstart, sysend),
	INDEX ix_Employees CLUSTERED(empid, sysstart, sysend)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeesHistory));

-- We can also convert an existing non-temporal table into a temporal table using ALTER TABLE
-- (Pls do not run the below code since Employees table is already temporal in nature)

ALTER TABLE dbo.Employees ADD
	sysstart DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL
		CONSTRAINT DFT_Employees_sysstart DEFAULT('19000101'),
	sysend DATETIME2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL
		CONSTRAINT DFT_Employees_sysend DEFAULT('99991231 23:59:59'),
	PERIOD FOR SYSTEM_TIME(sysstart, sysend);

-- WE can then alter the table to enable system versioning and linking to the history table

ALTER TABLE dbo.Employees
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeesHistory));

-- Since we marked the period columns as hidden, SELECT * would not return the period columns

SELECT * FROM dbo.Employees;

-- However if we do want the period columns, we should name them explicitly in the SELECT clause

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

/*
It is also possible to make a schema change without needing to disable system versioning
first. When we issue the schema change to the current table. THe change is also applied
on the history table. Naturally, if you want to add a non-nullable column, you will need to
add it with a default constraint.
*/

-- Let us add a non-nullable column called hiredate to our Employees table and use the date
-- January 1st, 1990 as the default. 

ALTER TABLE dbo.Employees
	ADD hiredate DATE NOT NULL
		CONSTRAINT DFT_Employees_hiredate DEFAULT('19000101');

SELECT * FROM dbo.Employees; -- Sweetly implemented

SELECT * FROM dbo.EmployeesHistory;

-- Change ripples through the Employees history table as well.

-- To drop the hiredate column, we first drop the default constraint and thereafter the 
-- hiredate column

ALTER TABLE dbo.Employees
	DROP CONSTRAINT DFT_Employees_hiredate;

ALTER TABLE dbo.Employees
	DROP COLUMN hiredate;

-- Lets check to be sure hiredate is succesfully dropped(Yeah! It is successful)

SELECT * FROM dbo.Employees;

SELECT * FROM dbo.EmployeesHistory;

/*
	MODIFY TEMPORAL TABLE


*/

-- Lets makes some modification to Employees table by inserting a few rows
-- Since, the period columns are hidden, it is not necessary to specify them

INSERT INTO dbo.Employees(empid, empname, department, salary)
	VALUES(1, 'Sara', 'IT' , 50000.00),
		(2, 'Don' , 'HR' , 45000.00),
		(3, 'Judy', 'Sales' , 55000.00),
		(4, 'Yael', 'Marketing', 55000.00),
		(5, 'Sven', 'IT' , 45000.00),
		(6, 'Paul', 'Sales' , 40000.00);

-- Let us query data to see what is happening behind the scene
-- The validity period indicates that the rows are considered valid since the time they
-- were inserted and with no end limit

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

-- the systart represents the date that the rows were inserted 

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;

-- The history table is empty at this point

-- Run the following code to delete the row where the employee ID is 6

DELETE FROM dbo.Employees
WHERE empid = 6;

-- SQL Server moves then deleted row to the history table, setting its sysend value to the
-- deletion time. (Run both queries simultaneously to observe the tables)

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;

-- An update of a row is treated as a delete plus an insert. The old version is moved into the
-- history table with sysstart and sysend as time in which transaction was carried out
-- while the new version is retained in the original table with transaction time as sysstart
-- and maximum value as period end time

UPDATE dbo.Employees
	SET salary *= 1.05
WHERE department = 'IT';

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;

-- Let us run a lon-standing transaction

BEGIN TRAN;

UPDATE dbo.Employees
	SET department = 'Sales'
WHERE empid = 5;

-- Wait a few seconds and run the below code

UPDATE dbo.Employees
	SET department = 'IT'
WHERE empid = 3;

COMMIT TRAN;

-- Lets check the current of the table

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;

-- Generally the new version of the updated columns is retained in the original table with
-- systart of transaction time of update and sysend of maximum date specified while for the
-- old version, it is moved into the history table with a sysstart of transaction time of 
-- original creation while sysend is same as transaction time of update.

/*
	QUERYING DATA

 Querying temporal tables is simple and elegant. IF one wants to query the current state of 
 the data, one only needs to query the current table. However to query past data, one would 
 still query the current table, but one would add a clause called FOR SYSTEM_TIME and a 
 subclause that indicates the valididty point or period of time you're interested in.

  To query historical data, we use the syntax below:

SELECT ... FROM <table_or_view> FOR SYSTEM_TIME <subclause> AS <alias>

Of the five subclauses that the SYSTEM_TIME clause supports, you’ll probably use the AS
OF subclause most often. You use it to request to see the data correct to a specific point in
time you specify. The syntax of this subclause is FOR SYSTEM_TIME AS OF <datetime2
value>. The input can be either a constant, variable, or parameter. Say the input is a variable
called @datetime. You’ll get back the rows where @datetime is on or after sysstart and before
sysend. In other words, the validity period starts on or before @datetime and ends after
@datetime. 

The following predicate identifies the qualifying rows:

sysstart <= @datetime AND sysend > @datetime

*/

-- Before examining the specifics of querying temporal tables, run the following code to recreate
-- the Employees and EmployeesHistory tables and to populate them with the same sample
-- data as in my environment, including the values in the period columns:

USE TSQLV4;

-- Drop tables if exist

IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
BEGIN
	IF OBJECTPROPERTY(OBJECT_ID('dbo.Employees', 'U'), 'TableTemporalType') = 2
		ALTER TABLE dbo.Employees SET (SYSTEM_VERSIONING = OFF);
	DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees;
END;
GO

-- Create and populate Employees table

CREATE TABLE dbo.Employees
(
	empid		INT				NOT NULL
		CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
	empname		VARCHAR(25)		NOT NULL,
	department	VARCHAR(50)		NOT NULL,
	salary		NUMERIC(10, 2)	NOT NULL,
	sysstart	DATETIME2(0)	NOT NULL,
	sysend		DATETIME2(0)	NOT NULL,
	INDEX ix_Employees CLUSTERED(empid, sysstart, sysend)
);

INSERT INTO dbo.Employees(empid, empname, department, salary, sysstart, sysend)
VALUES
(1 , 'Sara', 'IT' , 52500.00, '2016-02-16 17:20:02', '9999-12-31 23:59:59'),
(2 , 'Don' , 'HR' , 45000.00, '2016-02-16 17:08:41', '9999-12-31 23:59:59'),
(3 , 'Judy', 'IT' , 55000.00, '2016-02-16 17:28:10', '9999-12-31 23:59:59'),
(4 , 'Yael', 'Marketing', 55000.00, '2016-02-16 17:08:41', '9999-12-31 23:59:59'),
(5 , 'Sven', 'Sales' , 47250.00, '2016-02-16 17:28:10', '9999-12-31 23:59:59');

-- Create and populate EmployeesHistory table

CREATE TABLE dbo.EmployeesHistory
(
	empid		INT NOT NULL,
	empname		VARCHAR(25) NOT NULL,
	department	VARCHAR(50) NOT NULL,
	salary		NUMERIC(10, 2) NOT NULL,
	sysstart	DATETIME2(0) NOT NULL,
	sysend		DATETIME2(0) NOT NULL,
	INDEX ix_EmployeesHistory CLUSTERED(sysend, sysstart)
		WITH (DATA_COMPRESSION = PAGE)
);

INSERT INTO dbo.EmployeesHistory(empid, empname, department, salary, sysstart, sysend) 
VALUES
(6 , 'Paul', 'Sales' , 40000.00, '2016-02-16 17:08:41', '2016-02-16 17:15:26'),
(1 , 'Sara', 'IT' , 50000.00, '2016-02-16 17:08:41', '2016-02-16 17:20:02'),
(5 , 'Sven', 'IT' , 45000.00, '2016-02-16 17:08:41', '2016-02-16 17:20:02'),
(3 , 'Judy', 'Sales' , 55000.00, '2016-02-16 17:08:41', '2016-02-16 17:28:10'),
(5 , 'Sven', 'IT' , 47250.00, '2016-02-16 17:20:02', '2016-02-16 17:28:10');

--Enable system versioning

ALTER TABLE dbo.Employees ADD PERIOD FOR SYSTEM_TIME (sysstart, sysend);

ALTER TABLE dbo.Employees ALTER COLUMN sysstart ADD HIDDEN;
ALTER TABLE dbo.Employees ALTER COLUMN sysend ADD HIDDEN;

ALTER TABLE dbo.Employees
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeesHistory));

SELECT * FROM dbo.Employees;

-- Run the following code to return the employee rows correct to the point in time 
-- 2016-02-16 17:00:00:

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:00:00';

-- This gives an empty result because the first insert against the table happened at
-- 2016-02-16 17:08:41:

-- Let us query again, this time as of '2016-02-16 17:10:00'

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:10:00';

-- You can also query multiple instances of the same table, comparing different states of the
-- data at different points in time. For example, the following query returns the percentage of
-- increase of salary of employees who had a salary increase between two different points in
-- time:

SELECT T2.empid, T1.empid,
	CAST( (T2.salary/ T1.salary - 1.0) * 100 AS NUMERIC(10, 2)) AS pct
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:10:00' AS T1
	INNER JOIN dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:25:00' AS T2
		ON T1.empid = T2.empid AND T2.salary > T1.salary;

-- The subclause FROM @start TO @end returns the rows that satisfy the predicate sysstart <
-- @end AND sysend > @start. In other words, it returns the rows with a validity period that
-- starts before the input interval ends and that ends after the input interval starts. The following
-- query demonstrates using this subclause:

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees 
	FOR SYSTEM_TIME FROM '2016-02-16 17:15:26' TO '2016-02-16 17:20:02';

/*
Notice that rows with a sysstart value of 2016-02-16 17:20:02 are not included in the output.
If you need the input @end value to be inclusive, use the BETWEEN subclause instead of the
FROM subclause. The syntax of the BETWEEN subclause is BETWEEN @start AND @end,
and it returns the rows that satisfy the predicate sysstart <= @end AND sysend > @start. It
returns the rows with a validity period that starts on or before the input interval ends and that
ends after the input interval starts. The following query demonstrates using this subclause with
the same input values as in the previous query:
*/

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
FOR SYSTEM_TIME BETWEEN '2016-02-16 17:15:26' AND '2016-02-16 17:20:02';

/*
The subclause FOR SYSTEM_TIME CONTAINED IN(@start, @end) returns the rows that
satisfy the predicate sysstart >= @start AND sysend <= @end. It returns the rows with a
validity period that starts on or after the input interval starts and that ends on or before the
input interval ends. In other words, the validity period needs to be completely contained in the
input period.
*/

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
	FOR SYSTEM_TIME CONTAINED IN('2016-02-16 17:00:00', '2016-02-16 18:00:00');

-- T-SQL also supports the ALL subclause, which simply returns all rows from both tables.
-- The following query demonstrates the use of this subclause:

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees FOR SYSTEM_TIME ALL;

/*
Remember that the period columns reflect the validity period of the row as datetime2
values in the UTC time zone. If you want to return those as datetimeoffset values in a desired
time zone, you can use the AT TIME ZONE function. You’ll need to use the function twice.
Once to convert the input to datetimeoffset, indicating that it’s in the UTC time zone, and
another to convert the value to the target time zone—for example, sysstart AT TIME ZONE
‘UTC’ AT TIME ZONE ‘Pacific Standard Time’. If you use only one conversion straight to the
target time zone, the function will assume that the source value is already in the target time
zone and won’t perform the desired switching.

Another thing to consider is that for the sysend column, if the value is the maximum in the
type, you’ll just want to consider it as using the UTC time zone. Otherwise, you’ll want to
convert it to the target time zone as with the sysstart column. You can use a CASE expression
to apply this logic.

*/

-- As an example, the following query returns all rows and presents the period columns in the
-- time zone Pacific Standard Time:

SELECT empid, empname, department, salary,
	sysstart AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS sysstart,
	CASE
		WHEN sysend = '9999-12-31 23:59:59' THEN sysend AT TIME ZONE 'UTC'
		ELSE sysend AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'
	END AS sysend
FROM dbo.Employees FOR SYSTEM_TIME ALL;

-- Lets run the below code for cleanup

IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
BEGIN
	IF OBJECTPROPERTY(OBJECT_ID('dbo.Employees', 'U'), 'TableTemporalType') = 2
		ALTER TABLE dbo.Employees SET (SYSTEM_VERSIONING = OFF);
	DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees
END;