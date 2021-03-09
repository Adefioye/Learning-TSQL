/*	CHAPTER 8 SOLUTION	*/

-- Run the following code to create dbo.Customers

USE TSQLV4;

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers
(
	custid		INT				NOT NULL PRIMARY KEY,
	companyname NVARCHAR(40)	NOT NULL,
	country		NVARCHAR(15)	NOT NULL,
	region		NVARCHAR(15)	NULL,
	city		NVARCHAR(15)	NOT NULL
);

-- Insert into the dbo.Customers table a row with the following information:
-- custid: 100, companyname: Coho Winery, country: USA, region: WA, city: Redmond

INSERT INTO dbo.Customers(custid, companyname, country, region, city)
	VALUES(100, 'Coho Winery', 'USA', 'WA', 'Redmond');

SELECT * FROM dbo.Customers;

-- Insert into the dbo.Customers table all customers from Sales.Customers who placed orders.

-- 1st method

INSERT INTO dbo.Customers(custid, companyname, country, region, city)
	SELECT DISTINCT
		C.custid, C.companyname, C.country, C.region, C.city
	FROM Sales.Customers AS C INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid;

-- 2nd method (most declarative)

INSERT INTO dbo.Customers(custid, companyname, country, region, city)
	SELECT custid, companyname, country, region, city
	FROM Sales.Customers AS C
	WHERE EXISTS
				(SELECT * FROM Sales.Orders AS O
				WHERE O.custid = C.custid);

SELECT * FROM dbo.Customers;

-- Use a SELECT INTO statement to create and populate the dbo.Orders table with orders from
-- the Sales.Orders table that were placed in the years 2014 through 2016.

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

-- 1st method

SELECT *
INTO dbo.Orders
FROM Sales.Orders
WHERE orderdate BETWEEN '20140101' AND '20161231';

-- 2nd method

SELECT *
INTO dbo.Orders
FROM Sales.Orders
WHERE orderdate >= '20140101'
	AND orderdate < '20170101';


SELECT * FROM dbo.Orders;

-- Delete from the dbo.Orders table orders that were placed before August 2014. Use the
-- OUTPUT clause to return the orderid and orderdate values of the deleted orders:

DELETE FROM dbo.Orders
OUTPUT deleted.orderid, deleted.orderdate
WHERE orderdate < '20140801';

-- Delete from the dbo.Orders table orders placed by customers from Brazil.

-- Using standard SQL(1st method)

DELETE FROM dbo.Orders
OUTPUT deleted.custid, deleted.shipcountry
WHERE EXISTS
			(SELECT *
				FROM dbo.Customers AS C
				WHERE C.custid = Orders.custid AND C.country = 'Brazil');

-- USing T-SQL non-standard SQL(2nd method)

DELETE FROM O
FROM dbo.Orders AS O
	INNER JOIN dbo.Customers AS C ON O.custid = C.custid
WHERE country = N'Brazil';

-- USing MERGE statement(3rd method)

MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = 'Brazil') AS C
	ON O.custid = C.custid
WHEN MATCHED THEN DELETE; 


-- Run the following query against dbo.Customers, and notice that some rows have a NULL in
-- the region column: Change the NULL region to None. Use the OUTPUT clause to show
-- custid, oldregion, and newregion

SELECT * FROM dbo.Customers;

UPDATE dbo.Customers
	SET region = '<None>'
OUTPUT deleted.custid, deleted.region AS oldregion, inserted.region AS newregion
WHERE region IS NULL;

-- Update all orders in the dbo.Orders table that were placed by United Kingdom customers, and
-- set their shipcountry, shipregion, and shipcity values to the country, region, and city values of
-- the corresponding customers.

SELECT * FROM dbo.Orders;

SELECT * FROM dbo.Customers;

-- 1st method (most intuitive)
UPDATE O
	SET O.shipcountry = C.country,
		O.shipregion = C.region,
		O.shipcity = C.city
FROM dbo.Orders AS O INNER JOIN dbo.Customers AS C
	ON O.custid = C.custid
WHERE C.country = 'UK';

-- Using Table expression(2nd method)

WITH CTE_UPD AS
(
	SELECT
		O.shipcountry AS ocountry, C.country AS ccountry,
		O.shipregion AS oregion, C.region AS cregion,
		O.shipcity AS ocity, C.city AS ccity
	FROM dbo.Orders AS O
		INNER JOIN dbo.Customers AS C ON O.custid = C.custid
	WHERE C.country = N'UK'
)
UPDATE CTE_UPD
SET ocountry = ccountry, oregion = cregion, ocity = ccity;

-- Run the following code to create the tables Orders and OrderDetails and populate them with
-- data:

USE TSQLV4;

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

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
	CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

-- Write and test the T-SQL code that is required to truncate both tables, and make sure your
-- code runs successfully.

-- There is foreign-key relationship. We can delete the referencing table but not the 
-- referenced table. To delete the referenced table, we would have to drop foreign key relationship
-- even if there is no related row in the referencing table, we would have to drop then foreign-key
-- relationship in the referencing table in order to be able to drop the referenced table.

TRUNCATE TABLE dbo.OrderDetails;

ALTER TABLE dbo.OrderDetails DROP CONSTRAINT FK_OrderDetails_Orders;
	
TRUNCATE TABLE dbo.Orders; -- Performed successfully having drop the foreign-key relationship

-- LEts re-instate the foreign-key relationship

ALTER TABLE dbo.OrderDetails ADD CONSTRAINT FK_OrderDetails_Orders
	FOREIGN KEY(orderid) REFERENCES dbo.Orders(orderid);

-- Run the following code for cleanup

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;



