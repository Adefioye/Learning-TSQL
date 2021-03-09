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

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;