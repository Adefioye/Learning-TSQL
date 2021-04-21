/*	RAISING THROWING AND CUSTOMIZING  ERRORS	*/


/*

Note: Error with severity level less than 11 are not CATCHable. However those greater
than 11 are CATCHable.

Syntax : RAISERROR(message, severity, state, user_string, user_digit)

THROW syntax

THROW [error_number, message, state][;]

*/

RAISERROR('You cannot apply a 50%% discount on %s number %d', 6, 1, 'product', 5);

-- Concept on THROW without parameters
--(NOT YET RUN)

CREATE PROCEDURE insert_product
  @product_name VARCHAR(50),
  @stock INT,
  @price DECIMAL

AS

BEGIN TRY
	INSERT INTO products (product_name, stock, price)
		VALUES (@product_name, @stock, @price);
END TRY
-- Set up the CATCH block
BEGIN CATCH
	-- Insert the error and end the statement with a semicolon
    INSERT INTO errors VALUES ('Error inserting a product');
    -- Re-throw the error
	THROW; 
END CATCH

-- Lets use the stored procedure

BEGIN TRY
	EXEC insert_product
    	@product_name = 'Trek Conduit+',
        @stock = 3,
        @price = 499.99;
END TRY
BEGIN CATCH
	SELECT 'Error inserting product!';
END CATCH

-- Another exercise

DECLARE @staff_id INT = 45;

IF NOT EXISTS (SELECT * FROM staff WHERE staff_id = @staff_id)
	THROW 50001, 'No staff member with such id', 1;
ELSE
   	SELECT * FROM staff WHERE staff_id = @staff_id;

/*

RAISERROR('No %s with id %d.', 16, 1, 'staff member', 15)

THROW 52000, 'No staff member with id 15', 1; (error_number, message_txt, state)

	CUSTOMIZING ERROR MESSAGES

It can be done using variable and CONCAT FUNCTION

FORMATMESSAGE('msg_string', msg_number, param_value)

We can also use sp_addmessage msg_id, severity, msgtext

*/

select * from sysmessages;

-- Using CONCAT and variable to customize error message

DECLARE @first_name NVARCHAR(20) = 'David';

DECLARE @my_message NVARCHAR(500) =
	CONCAT('There is no staff member with ', @first_name, ' as the first name.');

IF NOT EXISTS (SELECT * FROM staff WHERE first_name = @first_name)
	THROW 50000, @my_message, 1;

-- Using FORMATMESSAGE to customize error message

DECLARE @product_name AS NVARCHAR(50) = 'Trek CrossRip+ - 2018';
DECLARE @sold_bikes AS INT = 10;
DECLARE @current_stock INT;

SELECT @current_stock = stock FROM products WHERE product_name = @product_name;

DECLARE @my_message NVARCHAR(500) =
	FORMATMESSAGE('There are not enough %s bikes. You have %d in stock', @product_name, @current_stock);

IF (@current_stock - @sold_bikes < 0)
	THROW 50000, @my_message, 1;

-- Using stored procedure

EXEC sp_addmessage @msgnum = 50002, @severity = 16, @msgtext = 'There are not enough %s bikes. You only have %d in stock.', @lang = N'us_english';

DECLARE @product_name AS NVARCHAR(50) = 'Trek CrossRip+ - 2018';
DECLARE @sold_bikes AS INT = 10;
DECLARE @current_stock INT;

SELECT @current_stock = stock FROM products WHERE product_name = @product_name;

DECLARE @my_message NVARCHAR(500) =
	-- Prepare the error message
	FORMATMESSAGE(50002, @product_name, @current_stock);

IF (@current_stock - @sold_bikes < 0)
	-- Throw the error
	THROW 50000, @my_message, 1;