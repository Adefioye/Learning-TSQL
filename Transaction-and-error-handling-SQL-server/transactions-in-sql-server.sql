/*	TRANSACTIONS IN SQL SERVER	*/

/*


*/

-- Coorecting a transaction statement

USE tehandling;
GO

BEGIN TRY  
	BEGIN TRAN;
		UPDATE accounts SET current_balance = current_balance - 100 WHERE account_id = 1;
		INSERT INTO transactions VALUES (1, -100, GETDATE());
        
		UPDATE accounts SET current_balance = current_balance + 100 WHERE account_id = 5;
		INSERT INTO transactions VALUES (5, 100, GETDATE());
	COMMIT TRAN;
END TRY
BEGIN CATCH  
	ROLLBACK TRAN;
END CATCH

--

BEGIN TRY  
	BEGIN TRAN;
		UPDATE accounts SET current_balance = current_balance - 100 WHERE account_id = 1;
		INSERT INTO transactions VALUES (1, -100, GETDATE());
        
		UPDATE accounts SET current_balance = current_balance + 100 WHERE account_id = 5;
		INSERT INTO transactions VALUES (500, 100, GETDATE());
	COMMIT TRAN;    
END TRY
BEGIN CATCH  
	SELECT 'Rolling back the transaction';
	ROLLBACK TRAN;
END CATCH

-- Updating account if condition is met

-- Begin the transaction
BEGIN TRAN; 
	UPDATE accounts set current_balance = current_balance + 100
		WHERE current_balance < 5000;
	IF @@ROWCOUNT > 200 
		BEGIN 
			ROLLBACK TRAN; 
			SELECT 'More accounts than expected. Rolling back'; 
		END
	ELSE
		BEGIN 
			COMMIT TRAN; 
			SELECT 'Updates commited'; 
		END

/*

@@TRANCOUNT returns the number of BEGIN TRAN statements that are active in then current 
connections.


*/

-- USing @@TRANCOUNT

BEGIN TRY
	BEGIN TRAN;
		UPDATE accounts SET current_balance = current_balance + 200
			WHERE account_id = 10;
		IF @@TRANCOUNT > 0     
			COMMIT TRAN;
     
	SELECT * FROM accounts
    	WHERE account_id = 10;      
END TRY
BEGIN CATCH  
    SELECT 'Rolling back the transaction'; 
    IF @@TRANCOUNT > 0   	
        ROLLBACK TRAN;
END CATCH

-- using savepoints SAVE TRAN

BEGIN TRAN;
	SAVE TRAN savepoint1;
	INSERT INTO customers VALUES ('Mark', 'Davis', 'markdavis@mail.com', '555909090');

    SAVE TRAN savepoint2;
	INSERT INTO customers VALUES ('Zack', 'Roberts', 'zackroberts@mail.com', '555919191');

	ROLLBACK TRAN savepoint2;
	ROLLBACK TRAN savepoint1;

	SAVE TRAN savepoint3;
	INSERT INTO customers VALUES ('Jeremy', 'Johnsson', 'jeremyjohnsson@mail.com', '555929292');
COMMIT TRAN;


/*
	USING XACT_ABORT & XACT_STATE

XACT_ABORT determines whether the current transaction will be automatically rolled back
when an error ocuur.

Syntax : SET XACT_ABORT {ON | OFF}

XACT_STATE()
0 --> no open transaction
1 --> open and committable transaction
-1 --> open and uncommittable transaction

When a transaction is uncommittable, you can't commit transaction, you can't rollback to 
a savepoint, you can't rollback the full transaction and lastly you canm't make any changes
/can read data.
*/

-- Use the appropriate setting
SET XACT_ABORT ON;
BEGIN TRAN; 
	UPDATE accounts set current_balance = current_balance - current_balance * 0.01 / 100
		WHERE current_balance > 5000000;
	IF @@ROWCOUNT <= 10	
		THROW 55000, 'Not enough wealthy customers!', 1;
	ELSE		
		COMMIT TRAN; 

-- Using XACT_ABORT and XACT_STATE

SET XACT_ABORT ON;
BEGIN TRY
	BEGIN TRAN;
		INSERT INTO customers VALUES ('Mark', 'Davis', 'markdavis@mail.com', '555909090');
		INSERT INTO customers VALUES ('Dylan', 'Smith', 'dylansmith@mail.com', '555888999');
	COMMIT TRAN;
END TRY
BEGIN CATCH
	-- Check if there is an open transaction
	IF XACT_STATE() <> 0
		ROLLBACK TRAN;
    -- Select the message of the error
    SELECT ERROR_MESSAGE() AS Error_message;
END CATCH