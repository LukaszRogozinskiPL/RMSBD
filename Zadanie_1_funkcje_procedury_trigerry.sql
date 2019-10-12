USE db_RMSBD
IF EXISTS ( SELECT	1 
			FROM	sys.objects 
			WHERE	object_id = OBJECT_ID(N'dbo.checkSalary')
					AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ) )
DROP FUNCTION dbo.checkSalary
GO
CREATE FUNCTION checkSalary(@employee_id INT)
RETURNS BIT AS
BEGIN
	DECLARE @isTheRightAmmout BIT, @salary SMALLMONEY, @position INT
	SELECT @salary = salary, @position = position
	FROM Employees
	WHERE employee_id = @employee_id
	IF (@salary >= ANY(SELECT min_salary
	FROM Positions WHERE position_id = @position)
	AND @salary <= ANY(SELECT max_salary
	FROM Positions WHERE position_id = @position))
		SET @isTheRightAmmout = 1
	ELSE
		SET @isTheRightAmmout = 0
	RETURN @isTheRightAmmout
END
GO


--SELECT * FROM Employees
--SELECT dbo.checkSalary(1) AS isSalaryOK
--SELECT dbo.checkSalary(3) AS isSalaryOK

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'dbo.orderBookDelivery')
                    AND type IN ( N'P', N'PC' ) )
DROP PROCEDURE dbo.orderBookDelivery
GO
CREATE PROCEDURE orderBookDelivery(@sender INT, @receiver INT, @book INT, @number_of_books INT)
AS
BEGIN
	DECLARE @department_category_id INT, @storehouse INT
	SET @storehouse = 1 --id of storehouse department category
	SET @department_category_id = (SELECT category FROM Department WHERE department_id = @sender)
	IF(@department_category_id = @storehouse)
	BEGIN
		IF(@number_of_books > (SELECT quantity FROM Books WHERE book_id = @book))
			BEGIN
				THROW 60000, 'not enough ammount of books', 1
			END
			BEGIN
				INSERT INTO BooksDelivery(quantity, delivery_date, price, book, department) -- mozliwy do dodania trigger ktory sprawdzi date delivery_date i o tej porze doda odpowiednia krotke do tabeli books
				VALUES(
					@number_of_books,
					(SELECT DATEADD(SECOND, 5, GETDATE())),
					(SELECT BookCategory.price FROM BookCategory WHERE BookCategory.book_category_id IN (SELECT book_category FROM Books WHERE book_id = @book)) * @number_of_books,
					@book,
					@receiver
				)
				UPDATE Books SET quantity = quantity - @number_of_books WHERE book_id = @book
			END
	END
	ELSE 
	BEGIN
		THROW 60000, 'books can be delivered only from warehouse', 1
	END
END
GO

--not warehouse
BEGIN TRY
	EXECUTE orderBookDelivery 2, 1, 14, 99
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH

--not  enough books
BEGIN TRY
	EXECUTE orderBookDelivery 3, 1, 14, 99
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH

SELECT * FROM BooksDelivery
SELECT * FROM Books WHERE name = 'Król'

BEGIN TRY
	EXECUTE orderBookDelivery 3, 2, 14, 2
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH

SELECT * FROM BooksDelivery
SELECT * FROM Books WHERE name = 'Król'


IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'dbo.changePosition')
                    AND type IN ( N'P', N'PC' ) )
DROP PROCEDURE dbo.changePosition
GO
CREATE PROCEDURE changePosition(@employee_id INT, @position_id INT)
AS
BEGIN
	DECLARE @min_salary SMALLMONEY, @max_salary SMALLMONEY, @actual_salary SMALLMONEY, @new_salary SMALLMONEY
	SELECT @actual_salary = salary FROM Employees WHERE @employee_id = employee_id
	SELECT @min_salary = min_salary FROM Positions WHERE @position_id = position_id
	SELECT @max_salary = max_salary FROM Positions WHERE @position_id = position_id
	IF (@position_id = (SELECT position FROM Employees WHERE @employee_id = employee_id))
	BEGIN
		THROW 60000, 'selected employee can not be promoted to position which currently have', 1
	END
	IF (@actual_salary <= @min_salary)
	BEGIN
		SET @new_salary = @min_salary
	END
	ELSE
	BEGIN
		IF (@actual_salary >= @min_salary AND @actual_salary <= @max_salary)
		BEGIN
			SET @new_salary = @actual_salary
		END
		ELSE
		BEGIN
			SET @new_salary = @max_salary
		END
	END
	UPDATE Employees SET salary = @new_salary, position = @position_id WHERE employee_id = @employee_id
	INSERT INTO SalaryHistory (salary, date, employee) VALUES (@new_salary, GETDATE(), @employee_id)
END
GO

--error
BEGIN TRY
	EXECUTE changePosition 2, 1
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH

--success
BEGIN TRY
	EXECUTE changePosition 2, 1
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH


IF EXISTS ( SELECT	1 
			FROM	sys.objects 
			WHERE	object_id = OBJECT_ID(N'dbo.checkWhoEarnTheMostInTheSamePosition')
					AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ) )
DROP FUNCTION dbo.checkWhoEarnTheMostInTheSamePosition
GO
CREATE FUNCTION checkWhoEarnTheMostInTheSamePosition(@position INT)
RETURNS @employee_id_and_salary TABLE
(
	employee_id INT PRIMARY KEY,
	salary SMALLMONEY
)
AS
BEGIN
	DECLARE @employee_id INT, @employee_id_with_max_salary SMALLMONEY, @max_salary SMALLMONEY, @employee_salary SMALLMONEY
	SET @max_salary = 0
	
	DECLARE employees SCROLL CURSOR FOR
	SELECT employee_id, salary FROM Employees WHERE position = @position

	OPEN employees
	FETCH NEXT FROM employees
	INTO @employee_id, @employee_salary

	WHILE @@FETCH_STATUS=0
	BEGIN
		IF (@max_salary < @employee_salary)
		BEGIN
			SET @max_salary = @employee_salary
			SET @employee_id_with_max_salary = @employee_id 
		END
		FETCH NEXT FROM employees INTO @employee_id, @employee_salary 
	END
	CLOSE employees
	DEALLOCATE employees
	INSERT @employee_id_and_salary
	SELECT @employee_id_with_max_salary, @max_salary
	RETURN
END
GO
SELECT * FROM dbo.checkWhoEarnTheMostInTheSamePosition(2)
SELECT * FROM Employees WHERE position = 2

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'dbo.changeSuperiorOfEmployee')
                    AND type IN ( N'P', N'PC' ) )
DROP PROCEDURE dbo.changeSuperiorOfEmployee
GO
CREATE PROCEDURE changeSuperiorOfEmployee(@employee INT, @new_superior INT)
AS
BEGIN
	DECLARE @current_superior INT
	SET @current_superior = (SELECT superior_id FROM Employees WHERE employee_id = @employee)
	IF (@current_superior = @new_superior)
	BEGIN
		THROW 60000, 'this employee already have superior with selected ID', 1
	END
	ELSE 
	BEGIN
		DECLARE @employee_department INT, @superior_department INT
		SET @employee_department = (SELECT department FROM Employees WHERE employee_id = @employee)
		SET @superior_department = (SELECT Department FROM Employees WHERE employee_id = @new_superior)
		
		IF((@employee_department != @superior_department))
		BEGIN
			THROW 60000, 'employee have to work in the same department as his superior', 1
		END
		ELSE
		BEGIN
			UPDATE Employees SET superior_id = @new_superior WHERE employee_id = @employee
		END
	END
END
GO


--same id
BEGIN TRY
	EXECUTE changeSuperiorOfEmployee 4, 1
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH
select * from Employees

--different department
BEGIN TRY
	EXECUTE changeSuperiorOfEmployee 4, 2
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH


INSERT INTO Employees(employee_id, employee_name, employee_surname, salary, superior_id, position, department) VALUES
	(16, 'Marlena', 'Polewicz', 2500,3, 2, 1);

BEGIN TRY
	EXECUTE changeSuperiorOfEmployee 16, 1
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH


IF EXISTS ( SELECT	1 
			FROM	sys.objects 
			WHERE	object_id = OBJECT_ID(N'dbo.checkIfSuperiorOK')
					AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ) )
DROP FUNCTION dbo.checkIfSuperiorOK
GO
CREATE FUNCTION checkIfSuperiorOK(@employee INT)
RETURNS BIT AS
BEGIN
	DECLARE @response BIT, @superior INT, @employee_department INT, @superior_department INT
	
	SET @superior = (SELECT superior_id FROM Employees WHERE employee_id = @employee)
	SET @employee_department = (SELECT department FROM Employees WHERE employee_id = @employee)
	SET @superior_department = (SELECT department FROM Employees WHERE employee_id = @superior)

	IF(@superior_department != @employee_department)
	BEGIN
		SET @response = 0
	END
	ELSE
	BEGIN
		SET @response = 1
	END
	RETURN @response
END
GO

SELECT dbo.checkIfSuperiorOK(16) AS isSuperiorOK
GO


IF EXISTS ( SELECT * 
			FROM sys.triggers
			WHERE object_id = OBJECT_ID(N'dbo.bookDeliveryTrigger'))
DROP TRIGGER dbo.bookDeliveryTrigger
GO
CREATE TRIGGER bookDeliveryTrigger ON BooksDelivery
AFTER INSERT AS
BEGIN
	DECLARE @delay DATETIME
	SET @delay = DATEDIFF(SECOND, GETDATE(), (SELECT delivery_date FROM inserted))
	--SET @delay = '00:00:02'
	WAITFOR DELAY @delay
	BEGIN
		DECLARE @book_name VARCHAR(20), @book_author VARCHAR(20), @book_category INT, @inserted_book_department INT, @inserted_book_id INT, @inserted_book_quantity INT, @existing_book_id_in_selected_department INT
		
		SET @inserted_book_id = (SELECT book FROM inserted)
		SET @book_name = (SELECT name FROM Books WHERE book_id = @inserted_book_id)
		SET @book_author = (SELECT author FROM Books WHERE book_id = @inserted_book_id)
		SET @book_category = (SELECT book_category FROM Books WHERE book_id = @inserted_book_id)
		SET @inserted_book_department = (SELECT department FROM inserted)
		SET @inserted_book_quantity = (SELECT quantity FROM inserted)

		SET @existing_book_id_in_selected_department = (SELECT book_id FROM Books WHERE department = @inserted_book_department AND name = @book_name)
		IF (@existing_book_id_in_selected_department IS NOT NULL)
		BEGIN
			UPDATE Books SET quantity = quantity + @inserted_book_quantity WHERE book_id = @existing_book_id_in_selected_department
		END
		ELSE
		BEGIN
			INSERT INTO Books VALUES(@inserted_book_quantity , @book_name, @book_author, @book_category, @inserted_book_department)
		END
	END
END
GO

--trigger wywolywany przy orderbookDelivery


IF EXISTS ( SELECT * 
			FROM sys.triggers
			WHERE object_id = OBJECT_ID(N'dbo.updateSalaryHistory'))
DROP TRIGGER dbo.updateSalaryHistory
GO
CREATE TRIGGER updateSalaryHistory ON Employees
AFTER UPDATE AS
BEGIN
	IF UPDATE (salary)
	BEGIN
		DECLARE @salary SMALLMONEY, @employee_id INT
		SET @salary = (SELECT salary FROM inserted)
		SET @employee_id = (SELECT employee_id FROM inserted)
		INSERT INTO SalaryHistory VALUES (@salary, GETDATE(), @employee_id)
	END
END

--wywolane przy changePosition

IF EXISTS ( SELECT * 
			FROM sys.triggers
			WHERE object_id = OBJECT_ID(N'dbo.deleteEmployee'))
DROP TRIGGER dbo.deleteEmployee
GO
CREATE TRIGGER deleteEmployee ON Employees
INSTEAD OF DELETE AS
BEGIN
	DECLARE @employee INT, @manager_id INT, @employee_position INT
	SET @employee = (SELECT employee_id FROM deleted)
	SET @manager_id = (SELECT position_id FROM Positions WHERE name = 'Dyrektor')
	SET @employee_position = (SELECT position from deleted)
	IF (@employee_position = @manager_id)
	BEGIN
		DECLARE @department_of_deleted_employee INT, @another_manager INT
		SET @department_of_deleted_employee = (SELECT department FROM deleted)
		SET @another_manager = (SELECT employee_id FROM Employees WHERE department = @department_of_deleted_employee AND position = @employee_position AND employee_id != @employee)
		IF(@another_manager IS NOT NULL)
		BEGIN
			UPDATE Department SET manager = @another_manager WHERE department_id = @department_of_deleted_employee
			UPDATE Employees SET superior_id = @another_manager WHERE superior_id = @employee
			DELETE FROM Employees WHERE employee_id = @employee
		END
		ELSE
		BEGIN
			THROW 60000, 'Cannot delete this manager because there have to be at least one manager in department', 1
		END
	END
	ELSE
	BEGIN
		DELETE FROM Employees WHERE employee_id = @employee
	END
END
BEGIN TRY
	DELETE FROM Employees WHERE employee_id = 1
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH

INSERT INTO Employees(employee_id, employee_name, employee_surname, salary, position, department) VALUES
	(17, 'Jakub', 'Trębacz', 9999, 1, 1);

BEGIN TRY
	DELETE FROM Employees WHERE employee_id = 1
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS Error
END CATCH
SELECT * FROM Employees