/* Starting with error handling */

/*
USE a TRY-CATCH BLOCK to ensure product table has stock values that are greater than
zero.

*/

USE tehandling;
GO

BEGIN TRY
	ALTER TABLE products
		ADD CONSTRAINT CHK_Stock CHECK (stock >= 0);
END TRY
BEGIN CATCH
	SELECT 'An error occurred!!!, Perhaps negative number was inserted';
END CATCH
GO

-- Try insert values with stock=-1

INSERT INTO products(product_name, stock, price)
	VALUES(N'Trek Neko+', -1, 2799);


/*
USing Nested TRY-AND-CATCH BLOCKS
*/

USE tehandling;
GO

BEGIN TRY
	INSERT INTO buyers (first_name, last_name, email, phone)
		VALUES ('Peter', 'Thompson', 'peterthomson@mail.com', '555000100');
END TRY
BEGIN CATCH
	SELECT 'An error occurred inserting the buyer! You are in the first CATCH block';
    BEGIN TRY
    	INSERT INTO errors 
        	VALUES ('Error inserting a buyer');
        SELECT 'Error inserted correctly!';
	END TRY
    BEGIN CATCH
    	SELECT 'An error occurred inserting the error! You are in the nested CATCH block';
    END CATCH 
END CATCH

-- LEts execute this script

USE tehandling;
GO

INSERT INTO products (product_name, stock, price)
    VALUES ('Trek Powerfly 5 - 2018', 10, 3499.99);

-- Lets execute the below code that catches the error
BEGIN TRY
	INSERT INTO products (product_name, stock, price)
		VALUES ('Sun Bicycles ElectroLite - 2017', 10, 1559.99);
END TRY
BEGIN CATCH
	SELECT 'An error occurred inserting the product!';
    BEGIN TRY
    	INSERT INTO errors
        	VALUES ('Error inserting a product');
    END TRY    
    BEGIN CATCH
    	SELECT 'An error occurred inserting the error!';
    END CATCH    
END CATCH

/*
	ERROR FUNCTIONS

Whenever we use TRY-CATCH block, we can lose useful info about the actual error, because 
of the error message specified within the CATCH block. To gain insight about the error
lost we can use the following error functions.

ERROR_NUMBER() : returns the number of the error
ERROR_SEVERITY() : returns the severity of error(11-19)
ERROR_STATE() : returns the state of the error
ERROR_LINE() : returns the number of the line of the error
ERROR_SEVERITY() : returns the name of ten stored procedure/ trigger. NULL is returned
if there is no stored procedure/trigger.
ERROR_MESSAGE() : returns the text of the error message

*/

-- Lets use the error function

BEGIN TRY  	
	SELECT 'Total: ' + SUM(price * quantity) AS total
	FROM orders;
END TRY
BEGIN CATCH 
	SELECT  ERROR_NUMBER() AS number,  
        	ERROR_SEVERITY() AS severity_level,  
        	ERROR_STATE() AS state,
        	ERROR_LINE() AS line,  
        	ERROR_MESSAGE() AS message; 	
END CATCH

-- Lets use error function again

BEGIN TRY
    INSERT INTO products (product_name, stock, price) 
    VALUES	('Trek Powerfly 5 - 2018', 2, 3499.99),   		
    		('New Power K- 2018', 3, 1999.99);	
END TRY
-- Set up the outer CATCH block
BEGIN CATCH
	SELECT 'An error occurred inserting the product!';
    -- Set up the inner TRY block
    BEGIN TRY
    	-- Insert the error
    	INSERT INTO errors
        	VALUES ('Error inserting a product');
    END TRY    
    -- Set up the inner CATCH block
    BEGIN CATCH
    	-- Show number and message error
    	SELECT 
        	ERROR_LINE() AS line,	   
			ERROR_MESSAGE() AS message; 
    END CATCH   
END CATCH