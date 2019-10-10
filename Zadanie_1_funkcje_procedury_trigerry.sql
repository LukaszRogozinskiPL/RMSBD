IF EXISTS(SELECT 1 FROM sys.objects WHERE TYPE='F' AND NAME = 'checkSalary') DROP FUNCTION checkSalary
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

IF EXISTS(SELECT 1 FROM sys.objects WHERE TYPE='P' AND NAME = 'orderBookDelivery') DROP PROCEDURE orderBookDelivery
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
				INSERT INTO BooksDelivery(quantity, delivery_date, price, book, department)
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

IF EXISTS(SELECT 1 FROM sys.objects WHERE TYPE='P' AND NAME = 'changePosition') DROP PROCEDURE changePosition
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