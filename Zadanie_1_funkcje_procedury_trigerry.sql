IF EXISTS ( SELECT	1 
			FROM	sys.objects 
			WHERE	object_id = OBJECT_ID(N'dbo.checkSalary')
					AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ) )
DROP FUNCTION dbo.checkSalary
GO
CREATE FUNCTION checkSalary(@id INT)
RETURNS BIT AS
BEGIN
	DECLARE @isTheRightAmmout BIT, @salary SMALLMONEY,  @position INT
	SELECT @salary = salary, @position = position
	FROM Employees
	WHERE employee_id =@id
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

--SELECT dbo.checkSalary(2)

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
					(SELECT DATEADD(SECOND, 20, GETDATE())),
					(SELECT BookCategory.price FROM BookCategory WHERE BookCategory.book_category_id IN (SELECT book_category FROM Books WHERE book_id = @book)) * @number_of_books,
					@book,
					@receiver
				)
				UPDATE Books SET quantity = quantity - @number_of_books WHERE book_id = @book
				PRINT 'succesfully ordered book deliver to library number ' + CAST(@receiver AS VARCHAR(2))
			END
	END
	ELSE 
	BEGIN
		THROW 60000, 'books can be delivered only from warehouse', 1
	END
END
GO

--EXECUTE orderBookDelivery 2, 1, 14, 5

--select dbo.checkSalary(13)

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

--SELECT * FROM Employees WHERE employee_id = 2
--EXECUTE changePosition 2, 2

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
	SELECT employee_id, salary FROM Employees

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
--SELECT * FROM dbo.checkWhoEarnTheMostInTheSamePosition(1)
--SELECT * FROM Employees WHERE position = 1

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
INSERT INTO Employees(employee_id, employee_name, employee_surname, salary, street, house_nr, flat_nr, city, zip_code, position, department) VALUES
	(16, 'Marlena', 'Polewicz', 2500, 'Rabicka', '665', '6', 'Teodory', '92-612', 2, 1);
	

--SELECT * FROM Employees WHERE employee_id = 16
--GO
--EXECUTE changeSuperiorOfEmployee 16, 1
--GO
--SELECT * FROM Employees WHERE employee_id = 16
--GO

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

--SELECT dbo.checkIfSuperiorOK(4)
--GO


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
		SELECT @existing_book_id_in_selected_department AS beforeIf
		IF (@existing_book_id_in_selected_department IS NOT NULL)
		BEGIN
			UPDATE Books SET quantity = quantity + @inserted_book_quantity WHERE book_id = @existing_book_id_in_selected_department
		END
		ELSE
		BEGIN
			INSERT INTO Books VALUES(@inserted_book_quantity , @book_name, @book_author, @book_category, @inserted_book_department)
		END
		UPDATE Books SET quantity = quantity - @inserted_book_quantity WHERE book_id = @inserted_book_id
	END
END
GO

--SELECT * FROM Books
--SELECT * FROM BooksDelivery

--INSERT INTO BooksDelivery VALUES(3, 'dostawa ksiazki', '2019-10-11 12:35:00', 50,  2, 1)