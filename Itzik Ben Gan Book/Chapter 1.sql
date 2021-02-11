/* Chapter 1 Itzik Ben Gan*/

/*Create Table Employees in the dbo schema*/

USE TSQLV4;

/*To drop table in sql server version 2016 and later*/

/* drop table if exists dbo.Employees; */

/* To drop table in sql version before 2016 us the below*/

IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL DROP TABLE dbo.Employees;

CREATE TABLE dbo.Employees
(
	emp_id INT NOT NULL,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	hire_date DATE NOT NULL,
	m_grid INT NULL,
	ssn VARCHAR(20) NOT NULL,
	salary MONEY NOT NULL
);


/*Defining Data Integrity

Example of data integrity are primary key, unique, foreign key, check and default
constraints. These constraints can be defined when making CREATE TABLE and ALTER TABLE 
statements. All types of constraints except for default constraints can be defined
as COMPOSITE CONSTRAINTS-- that is, based on more than one attribute*/

/* Primary-key constraints allow for the enforcement of uniqueness in a table*/

USE TSQLV4;

ALTER TABLE dbo.Employees
	ADD CONSTRAINT PK_Employees
	PRIMARY KEY(emp_id);



/* Unique constraints allow us to enforce uniqueness in a table. In addition, it allows 
for us to implement the concept of alternate keys in a table. Unlike primary keys, there
can be multiple unique contraints in a table. Also, unique constraint is not restricted
to columns defined as NOT NULL.

In standard SQL, Unique contraint is implemented by allowing multiple NULLs
In SQL server, it is implemented by rejecting duplicate NULLs

To have both worlds, unique filtered index is used. This filters only NOT-NULL values 
while allowing for duplicate rows of NULLs
*/

ALTER TABLE dbo.Employees
	ADD CONSTRAINT UNQ_Employees_ssn
	UNIQUE(ssn);


/*Create a unique filtered index*/

CREATE UNIQUE INDEX idx_ssn_notnull ON dbo.Employees(ssn) WHERE ssn IS NOT NULL;

/*
Foreign key enforces referential integrity. The constraint can be defined on one or 
more attributes in the referencing table and it points to candidate-key/primary-key/
unique-constraint of the referenced table.

The foreign-key ensures that the values in the foreign-key columns are the allowable 
values in the referenced columns
*/

USE TSQLV4;

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
	order_id INT NOT NULL,
	emp_id INT NOT NULL,
	cust_id VARCHAR(10) NOT NULL,
	order_ts DATETIME2 NOT NULL,
	qty INT NOT NULL,
	CONSTRAINT PK_Orders
		PRIMARY KEY(Order_id)
)

/*Enforce referential integrity on emp_id column on dbo.Orders*/

ALTER TABLE dbo.Orders
	ADD CONSTRAINT FK_Orders_Employees
	FOREIGN KEY(emp_id)
	REFERENCES dbo.Employees(emp_id)


/*To restrict values in m_grid to those in emp_id*/

ALTER TABLE dbo.Employees
	ADD CONSTRAINT FK_Employees_Employees
	FOREIGN KEY(m_grid)
	REFERENCES dbo.Employees(emp_id)


/* The two preceding examples are basic definitions of foreign keys with NO ACTION.
This simply means that any action performed on rows in referenced table with related rows
in the referencing table will be deleted. To carry out actions. Options can be defined with
ON DELETE and ON UPDATE with actions such as CASCADE, SET DEFAULT and SET NULL.
ON DELETE CASCADE means when you delete a row from referenced table, RDBMS will delete
related rows from the referencing table.
SET DEFAULT and SET NULL mean that the compensating action will set the foreign-key attributes
of the related rows to column's default value or null.

Note that regardless of which action you choose, the referencing table will have only 
orphaned rows in the case of the exception with NULLs that I mentioned earlier.
Parents with no children are always allowed.
 */

 /*Check constraints
 
 This can be used to define a predicate-- necessary to ensure a row satisfies the condition
 before being succesfully inputed into the table. The below example ensures that salary
 values are positive values.

 Its important to note that a check constraint rejects INSERT/UPDATE operation. If the 
 predicate evaluates to FALSE. However, the modification will be accepted if predicates 
 evaluates to TRUE/ UNKNOWN-- that is when salary is 50000 or NULL

 When adding check and foreign-key constraint, WITH NOCHECK option can be set-- This simply means 
 that RDBMS should neglect constraint checking on existing data. This is considered bad
 practice especially in the bid to achieve consistent data. 

 It is also possible to disable or enable existing check and foreign-key constraint.
 */

 USE TSQLV4;

 ALTER TABLE dbo.Employees
	ADD CONSTRAINT CHK_Employees_salary
	CHECK(salary > 0.00)


/*Default constraint

This is associated to a particular attribute. It is an expression that is used as the 
default value when an explicit value is not set on that attribute when inserting a row.

The below code defines a default constraint for the order_ts attribute of dbo.Orders
*/

ALTER TABLE dbo.Orders
	ADD CONSTRAINT DFT_Orders_order_ts
	DEFAULT(SYSDATETIME()) FOR order_ts;


/* Drop dbo.Orders abd dbo.Employees for cleanup*/

USE TSQLV4;

/*The referencing table should be deleted before the referenced table*/

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;

IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL DROP TABLE dbo.Employees;