USE db_RMSBD
GO

INSERT INTO Positions VALUES
	(1, 'Dyrektor', 5000, 7000),
	(2, 'Pracownik', 2000, 4000),
	(3, 'Dostawca', 3000, 5000),
	(4, 'Ochroniaż', 2500, 4500);

INSERT INTO Employees(employee_id, employee_name, employee_surname, salary, street, house_nr, flat_nr, city, zip_code, position, department) VALUES
	(1, 'Marcin', 'Wachulski', 5200, 'Piotrkowska', '210', '18', 'Gliwice', '94-021', 1, 1),
	(2, 'Jacek', 'Gierewicz', 6200, 'Aleksandrowska', '125', '12', 'Poznan', '93-351', 1, 2),
	(3, 'Tomasz', 'Kuc', 7000, 'Pojezierska', '42', '18', 'Sieradz', '91-416', 1, 3);

INSERT INTO Employees(employee_id, employee_name, employee_surname, salary, street, house_nr, flat_nr, city, zip_code, superior_id, position, department) VALUES
	(4, 'Marlena', 'Polewicz', 2500, 'Rabicka', '665', '6', 'Teodory', '92-612', 1, 2, 1),
	(5, 'Karina', 'Andrzejewicz', 2300, 'Krotka', '90', '8', 'Warszawa', '97-203', 1, 2, 1),
	(6, 'Patrycja', 'Bis', 2600, 'Opolska', '210', '15', 'Aleksandrow Lodzki', '97-614', 3, 2, 3),
	(7, 'Franciszek', 'Major', 2800, 'Maratonska', '777', '10', 'Sieradz', '93-456', 3, 2, 3),
	(8, 'Piotr', 'Zedryk', 2100, 'Boniec', '729', '9', 'Warszawa', '94-080', 3, 2, 3),
	(9, 'Bartosz', 'Dolic', 2100, 'Radwanska', '121', '6', 'Opole', '98-603', 2, 2, 2),
	(10, 'Elmund', 'Telarid', 3100, 'Durden', '91', '2', 'Zakopane', '96-710', 3, 3, 3),
	(11, 'Karolina', 'Jamnik', 3200, 'Lipiec', '62', '29', 'Mosin', '90-765', 3, 3, 3),
	(12, 'Sebastian', 'Irys', 2550, 'Warszawska', '164', '84', 'Lepody', '93-123', 1, 4, 1),
	(13, 'Bogdan', 'Popel', 5500, 'Konieczna', '75', '73', 'Rusiec', '96-925', 2, 4, 2),
	(14, 'Katarzyna', 'Silna', 3300, 'Smutna', '36', '42', 'Gliwice', '99-821', 3, 4, 3),
	(15, 'Hanna', 'Widawka', 2600, 'Wesola', '352', '12', 'Torun', '99-951', 3, 4, 3);

INSERT INTO DepartmentCategory VALUES
	(1, 'Magazyn'),
	(2, 'Biblioteka');

INSERT INTO Department VALUES
	(1, 'Biblioteka Publiczna im. Wladyslawa Matejki', 1, 2),
	(2, 'Biblioteka Niepubliczna im. Ernesta Hemingwaya', 2, 2),
	(3, 'Magazyn ksiazek im. Jana Przechowywacza', 3, 1);

INSERT INTO BookCategory VALUES
	(1, 'fantastyka', 15),
	(2, 'horror', 20),
	(3, 'klasyka', 17),
	(4, 'powiesc historyczna', 25),
	(5, 'biografia', 30);

INSERT INTO Books VALUES
	(10, 'Dwa Miecze', 'Andrzej Sapkowski', 1, 1),
	(8, 'Upadly Aniol', 'Jakub Cwiek', 1, 1),
	(20, 'To', 'Stephen King', 2, 1),
	(15, 'Mistrz i Malgorzata', 'Michail Bulhakow', 3, 1),
	(10, 'Kamienie na szaniec', 'Aleksander Kamińsk', 4, 2),
	(5, 'Pamietnik narkomanki', 'Barbara Rosiek', 5, 2),
	(2, 'Steve Jobs', 'Walter Isaacson', 5, 2),
	(10, 'Hobbit', 'J.R.R. Tolkien', 1, 2),
	(15, 'Romeo i Julia', 'William Shakespeare', 3, 1),
	(11, 'Sezon Burz', 'Andrzej Sapkowski', 4, 1),
	(12, 'Przed świtem', 'Stephenie Meyer', 1, 3),
	(13, 'Dracula', 'Bram Stoker', 2, 3),
	(6, 'Dziady', 'Adam Mickiewicz', 3, 3),
	(8, 'Król', 'Szczepan Twardoch', 4, 3),
	(20, 'Pianista', 'Wladyslaw Szpilman', 5, 3);

INSERT INTO BooksDelivery(quantity, delivery_date, price, book, department) VALUES
	(5, '2019-10-10 12:00:00', 500, 15, 2),
	(3, '2019-09-12 14:00:00', 300, 14, 1),
	(2, '2019-08-20 18:00:00', 500, 13, 2),
	(10, '2019-11-11 08:00:00', 500, 12, 2),
	(7, '2019-05-05 12:30:00', 500, 11, 1);

	SELECT * FROM Positions;
	SELECT * FROM Employees;
	SELECT * FROM DepartmentCategory;
	SELECT * FROM Department;
	SELECT * FROM BookCategory;
	SELECT * FROM Books;
	SELECT * FROM BooksDelivery;