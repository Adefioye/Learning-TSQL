/*	CHAPTER 9 EXERCISE SOLUTION	*/

/*
Create a system-versioned temporal table called Departments with an associated history table
called DepartmentsHistory in the database TSQLV4. The table should have the following
columns: deptid INT, deptname VARCHAR(25), and mgrid INT, all disallowing NULLs. Also
include columns called validfrom and validto that define the validity period of the row. Define
those with precision zero (1 second), and make them hidden.
*/

USE TSQLV4;

DROP TABLE IF EXISTS dbo.Departments

CREATE TABLE dbo.Departments
(
	deptid INT NOT NULL CONSTRAINT PK_Departments PRIMARY KEY,
	deptname VARCHAR(25) NOT NULL,
	mgrid INT NOT NULL,
	validfrom DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
	validto DATETIME2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
	PERIOD FOR SYSTEM_TIME(validfrom, validto)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.DepartmentsHistory));


/*
Insert four rows to the table Departments with the following details, and note the time when
you apply this insert (call it P1):
*/

SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P1;

INSERT INTO dbo.Departments(deptid, deptname, mgrid)
VALUES
	(1, 'HR', 7),
	(2, 'IT', 5),
	(3, 'Sales', 11),
	(4, 'Marketing', 13);

-- P1 is 2021-03-10 10:06:57

/*
In one transaction, update the name of department 3 to Sales and Marketing and delete
department 4. Call the point in time when the transaction starts P2.
*/

SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P2;

BEGIN TRAN;

UPDATE dbo.Departments
	SET deptname = 'Sales and Marketing'
WHERE deptid = 3;

DELETE dbo.Departments
WHERE deptid = 4;

COMMIT TRAN;

-- P2 is 2021-03-10 10:14:15

/*
In one transaction, update the name of department 3 to Sales and Marketing and delete
department 4. Call the point in time when the transaction starts P2.
*/

SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P3;

UPDATE dbo.Departments
	SET mgrid = 13
WHERE deptid = 3;

-- P3 is 2021-03-10 10:18:48

-- Let us query departments table and departmentshistory table.

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments;

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.DepartmentsHistory;

-- Query the current state of the table Departments

SELECT * FROM dbo.Departments; -- Doesnt reveal validfrom and validto because they are hidden

-- Query the state of the table Departments at a point in time after P2 and before P3:

SELECT *
FROM dbo.Departments 
	FOR SYSTEM_TIME FROM '2021-03-10 10:14:15' TO '2021-03-10 10:18:48';

-- Query the state of the table Departments in the period between P2 and P3. Be explicit about the
-- column names in the SELECT list, and include the validfrom and validto columns:

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments
	FOR SYSTEM_TIME BETWEEN '2021-03-10 10:14:15' AND '2021-03-10 10:18:48';

-- DROP Departments and DEpartmentsHistory table
-- To drop the table, we set off system-versioning

ALTER TABLE dbo.Departments SET (SYSTEM_VERSIONING = OFF);

DROP TABLE IF EXISTS dbo.Departments, dbo.DepartmentsHistory;