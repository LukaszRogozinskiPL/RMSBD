USE db_RMSBD
GO
--rodzaje stanowisk--
CREATE TABLE Positions
(
	position_id INT PRIMARY KEY,
	name VARCHAR(50) NOT NULL UNIQUE,
	min_salary SMALLMONEY,
	max_salary SMALLMONEY
)
GO

--pracownicy biblioteki--
CREATE TABLE Employees
(
	employee_id INT PRIMARY KEY,
	employee_name VARCHAR(20) NOT NULL,
	employee_surname VARCHAR(40) NOT NULL,
	salary SMALLMONEY NOT NULL,
	--street VARCHAR(60) NOT NULL,
	--house_nr INT NOT NULL,
	--flat_nr INT,
	--city VARCHAR(20) NOT NULL,
	--zip_code VARCHAR(20) NOT NULL,
	superior_id INT,
	position INT NOT NULL,
	department INT NOT NULL,
	CONSTRAINT FK_employees_superior
	FOREIGN KEY(superior_id) REFERENCES Employees(employee_id),
	CONSTRAINT FK_employees_position
	FOREIGN KEY(position) REFERENCES Positions(position_id),
--	CONSTRAINT FK_employees_department
--	FOREIGN KEY(department) REFERENCES Department(department_id)
)
GO

--rodzaj oddzialu--
CREATE TABLE DepartmentCategory
(
	department_category_id INT PRIMARY KEY,
	name VARCHAR(20) NOT NULL
)
GO

--placowki bibliotek--
CREATE TABLE Department
(
	department_id INT PRIMARY KEY,
	department_name VARCHAR(50),
	category INT NOT NULL,
	manager INT NOT NULL,
	CONSTRAINT FK_department_manager
	FOREIGN KEY(manager) REFERENCES Employees(employee_id),
	CONSTRAINT FK_department_departmentCategory
	FOREIGN KEY(category) REFERENCES DepartmentCategory(department_category_id)
)
GO

--kategorie ksiazek--
CREATE TABLE BookCategory
(
	book_category_id INT PRIMARY KEY,
	name VARCHAR(40) NOT NULL,
	price SMALLMONEY NOT NULL
)
GO
--książki--
CREATE TABLE Books
(
	book_id INT IDENTITY(1,1) PRIMARY KEY,
	quantity INT NOT NULL,
	name VARCHAR(20) NOT NULL,
	author VARCHAR(100) NOT NULL,
	book_category INT NOT NULL,
	department INT NOT NULL,
	CONSTRAINT FK_books_categoryOfBooks
	FOREIGN KEY(book_category) REFERENCES BookCategory(book_category_id),
	CONSTRAINT FK_books_department
	FOREIGN KEY(department) REFERENCES Department(department_id)
)
GO

--dostawy książek--
CREATE TABLE BooksDelivery
(
	book_deliver_id INT IDENTITY(1,1) PRIMARY KEY,
	quantity INT NOT NULL,
	description VARCHAR(100),
	delivery_date SMALLDATETIME NOT NULL,
	price SMALLMONEY NOT NULL,
	book INT NOT NULL,
	department INT NOT NULL,
	CONSTRAINT FK_booksDelivery_Books
	FOREIGN KEY(book) REFERENCES Books(book_id),
	CONSTRAINT FK_booksDelivery_Department
	FOREIGN KEY(department) REFERENCES Department(department_id)
)
GO
--historia pensji pracowników--
CREATE TABLE SalaryHistory
(
	salary_history_id INT IDENTITY(1,1) PRIMARY KEY,
	salary SMALLMONEY,
	date DATETIME,
	employee INT NOT NULL,
	CONSTRAINT FK_salaryHistory_Employee
	FOREIGN KEY(employee) REFERENCES employees(employee_id)
)
GO