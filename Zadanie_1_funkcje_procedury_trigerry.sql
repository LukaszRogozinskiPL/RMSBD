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
					(SELECT DATEADD(DAY, 2, GETDATE())),
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









-------------------------------------------------------------------------------
use db_RMSBD
CREATE FUNCTION checkIfAllDepartmentHaveDirector()
RETURNS BIT
AS BEGIN
	DECLARE @response BIT, @department_id INT
	DECLARE departments SCROLL CURSOR FOR
	SELECT department_id FROM Department

	OPEN departments
	FETCH NEXT FROM departments
	INTO @department_id

	WHILE @@FETCH_STATUS=0
	BEGIN
	IF((SELECT director FROM Department WHERE department_id = @department_id) = NULL)
	BEGIN
		SET @response = 0
		RETURN @response
	END
	ELSE
	BEGIN
		SET @response = 1
	END
	FETCH NEXT FROM departments INTO @department_id
	END
	CLOSE departments
	DEALLOCATE departments
	RETURN @response
END

CREATE FUNCTION printWhichBookWasNotDelivered(@book INT)
RETURNS VARCHAR 
AS BEGIN
	DECLARE @response VARCHAR(200), @book_id INT, @book_name VARCHAR(20)
	SET @response = ''
	DECLARE books SCROLL CURSOR FOR
	SELECT book FROM BooksDelivery 
	WHERE delivery_date < GETDATE()

	OPEN books
	FETCH NEXT FROM books
	INTO @book_id

	WHILE @@FETCH_STATUS=0
	BEGIN
		--SET @response = @response + CAST(@book_id AS VARCHAR(2)) + ','
		SET @response = @book_id

		--RETURN @book_id
		--PRINT 'id of book ' + CAST(@book_id AS VARCHAR(10))
		FETCH NEXT FROM books INTO @book_id
	END
	CLOSE books
	DEALLOCATE books
	RETURN @response
END
GO


SELECT dbo.printWhichBookWasNotDelivered(1)

SELECT dbo.checkIfBookWasDelivered(2)

SELECT book FROM BooksDelivery WHERE delivery_date < GETDATE()