-- Database: boat_business

-- DROP DATABASE IF EXISTS boat_business;

CREATE DATABASE boat_business
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False
	

	CREATE TABLE class(
		id SERIAL PRIMARY key,
		class_name CHAR(20) UNIQUE,
		rental_fee DECIMAL(10, 2)
);
	
	CREATE TABLE yacht(
		id SERIAL PRIMARY KEY,
		class_id INTEGER REFERENCES class(id),
		size INTEGER,
		displacement INTEGER,
		condition CHAR(20)
);
	
	CREATE TABLE client (
    id SERIAL PRIMARY KEY,
    name CHAR(30),
    address CHAR(50),
    phone CHAR(20),
    document_number CHAR(20),
    bank_account CHAR(30)
);
	CREATE TABLE rental (
    id SERIAL PRIMARY KEY,
    yacht_id INTEGER REFERENCES yacht(id),
    client_id INTEGER REFERENCES client(id),
    start_date DATE,
    end_date DATE,
    rental_fee DECIMAL(10,2),
    payment_scheme CHAR(20)
);
	CREATE TABLE inspection (
    id SERIAL PRIMARY KEY,
    yacht_id INTEGER REFERENCES yacht(id),
    rental_id INTEGER REFERENCES rental(id),
    date DATE,
    condition CHAR(20)
);
	CREATE TABLE payment (
    id SERIAL PRIMARY KEY,
    rental_id INTEGER REFERENCES rental(id),
    amount DECIMAL(10,2),
    payment_date DATE,
    payment_type CHAR(20)
);
	CREATE TABLE overdue (
    id SERIAL PRIMARY KEY,
    rental_id INTEGER REFERENCES rental(id),
    overdue_amount DECIMAL(10,2),
    overdue_days INTEGER
)

INSERT INTO class(class_name, rental_fee) VALUES
('Class A', 300.00),
('Class B', 250.00),
('Class C', 200.00),
('Class D', 150.00);
select * from class;

INSERT INTO yacht(class_id, size, displacement, condition) VALUES
(4, 25, 8, 'Good'),
(1, 45, 18, 'Fair');

INSERT INTO client(name, address, phone, document_number, bank_account) VALUES
('John Smith', '123 Main St, Anytown USA', '555-555-5555', '123456789', '1234567890'),
('Jane Doe', '456 Park Ave, Anycity USA', '555-555-5556', '234567890', '2345678901'),
('Bob Johnson', '789 Elm St, Anystate USA', '555-555-5557', '345678901', '34567890'),
('Samantha Williams', '369 Oak St, Anycountry USA', '555-555-5558', '456789012', '4567890123');

INSERT INTO rental(yacht_id, client_id, start_date, end_date, rental_fee, payment_scheme) VALUES
(1, 1, '2022-01-01', '2022-01-07', 300.00, 'Full Payment'),
(2, 2, '2022-01-08', '2022-01-14', 250.00, 'Half Payment'),
(3, 3, '2022-01-15', '2022-02-15', 200.00, 'Monthly Payment'),
(4, 4, '2022-02-16', '2022-03-15', 150.00, 'Monthly Payment'),
(5, 2, '2022-03-16', '2022-04-15', 300.00, 'Half Payment');

INSERT INTO inspection(yacht_id, rental_id, date, condition) VALUES
(1, 1, '2022-01-08', 'Good'),
(2, 2, '2022-01-15', 'Fair'),
(3, 3, '2022-02-16', 'Poor'),
(4, 4, '2022-03-16', 'Good'),
(5, 5, '2022-04-15', 'Fair');

INSERT INTO payment(rental_id, amount, payment_date, payment_type) VALUES
(1, 300.00, '2022-01-08', 'Bank Transfer'),
(2, 125.00, '2022-01-15', 'Credit Card'),
(3, 100.00, '2022-02-16', 'Cash'),
(4, 75.00, '2022-03-16', 'Check'),
(5, 150.00, '2022-04-15', 'Bank Transfer');

INSERT INTO overdue(rental_id, overdue_amount, overdue_days) VALUES
(1, 50.00, 3),
(2, 75.00, 7),
(3, 100.00, 10),
(4, 125.00, 14),
(5, 150.00, 20);


--Запросы:

SELECT id, yacht_name FROM yacht ORDER BY yacht_name;

SELECT yacht.id, yacht.size, yacht.displacement, class.class_name
FROM yacht
INNER JOIN class ON yacht.class_id = class.id
WHERE class.class_name = 'Class A'

SELECT client.name, client.address, client.phone, rental.start_date, rental.end_date
FROM client
INNER JOIN rental ON client.id = rental.client_id
INNER JOIN yacht ON rental.yacht_id = yacht.id
WHERE yacht.id = 1
AND rental.start_date >= '2022-01-01'
AND rental.end_date <= '2022-12-31'

WITH last_inspection AS (
  SELECT yacht_id, max(date) as date
  FROM inspection
  GROUP BY yacht_id
)
SELECT yacht.id, yacht.size, yacht.displacement,yacht.yacht_name ,last_inspection.date
FROM yacht
INNER JOIN last_inspection ON yacht.id = last_inspection.yacht_id
WHERE last_inspection.date >= NOW() - INTERVAL '1 month';

SELECT client.name, client.address, client.phone, rental.end_date, rental.return_date
FROM client
INNER JOIN rental ON client.id = rental.client_id
WHERE rental.return_date > rental.end_date



WITH delayed_rentals AS (
  SELECT rental.client_id, rental.end_date, rental.id
  FROM rental
  WHERE rental.return_date > rental.end_date
)
SELECT client.name, client.address, client.phone, delayed_rentals.end_date
FROM client
INNER JOIN delayed_rentals ON client.id = delayed_rentals.client_id


WITH client_rental_period AS (
    SELECT client_id, SUM(end_date - start_date) AS total_rental_period
    FROM rental
    GROUP BY client_id
)
SELECT client.name, client.address, client.phone, client_rental_period.total_rental_period
FROM client
INNER JOIN client_rental_period ON client.id = client_rental_period.client_id
INNER JOIN rental ON client_rental_period.client_id = rental.client_id
INNER JOIN yacht ON rental.yacht_id = yacht.id
WHERE yacht.yacht_name = 'Bluebird'
ORDER BY client_rental_period.total_rental_period DESC
LIMIT 1;


WITH client_payment AS (
  SELECT client_id, SUM(amount) as total_amount
  FROM payment
  GROUP BY client_id
)
SELECT client.name, client.address, client.phone, client_payment.total_amount
FROM client
INNER JOIN client_payment ON client.id = client_payment.client_id
ORDER BY client_payment.total_amount
LIMIT 1


WITH poor_condition_inspections AS (
  SELECT rental.client_id, inspection.condition
  FROM inspection
  INNER JOIN rental ON inspection.rental_id = rental.id
  WHERE inspection.condition = 'Unsatisfactory'
)
SELECT client.name, client.address, client.phone, poor_condition_inspections.condition
FROM client
INNER JOIN poor_condition_inspections ON client.id = poor_condition_inspections.client_id
GROUP BY client.name, client.address, client.phone, poor_condition_inspections.condition


UPDATE inspection
SET condition = 'satisfactory'
WHERE yacht_id = 5;

WITH yacht_popularity AS (
  SELECT yacht_id, COUNT(yacht_id) as rental_count
  FROM rental
  GROUP BY yacht_id
)
SELECT yacht.id, yacht.size, yacht.displacement, yacht_popularity.rental_count
FROM yacht
INNER JOIN yacht_popularity ON yacht.id = yacht_popularity.yacht_id
ORDER BY yacht_popularity.rental_count DESC


WITH client_favorites AS (
  SELECT client_id, yacht_id, COUNT(yacht_id) as rental_count, SUM(age(end_date, start_date)) as rental_period
  FROM rental
  GROUP BY client_id, yacht_id
)
SELECT client.name, client.address, client.phone, client_favorites.yacht_id, client_favorites.rental_count, client_favorites.rental_period
FROM client
INNER JOIN client_favorites ON client.id = client_favorites.client_id
WHERE rental_count = (SELECT max(rental_count) FROM client_favorites WHERE client_favorites.client_id = client.id)
AND rental_period = (SELECT max(rental_period) FROM client_favorites WHERE client_favorites.client_id = client.id AND rental_count = (SELECT max(rental_count) FROM client_favorites WHERE client_favorites.client_id = client.id))

--Хранимые процедуры и функции

CREATE PROCEDURE increase_yacht_cost(percentage INTEGER)
AS $$
BEGIN
  -- Increase rental fee of all yachts
  UPDATE class SET rental_fee = rental_fee * (1 + (percentage / 100.0));

  -- Increase remaining payments of all rentals
  UPDATE rental SET rental_fee = rental_fee * (1 + (percentage / 100.0))
  WHERE id IN (SELECT rental_id FROM payment WHERE amount < rental_fee);
END $$ LANGUAGE plpgsql;

CALL increase_yacht_cost(10);



--2

CREATE OR REPLACE FUNCTION calculate_discount(client_id INTEGER)
RETURNS DECIMAL(10,2)
AS $$
DECLARE
    c1 DECIMAL(10,2) := 0.01;
    total_amount DECIMAL(10,2);
    discount DECIMAL(10,2);
BEGIN
    -- check if client has overdue payments
    IF EXISTS (SELECT * FROM overdue WHERE client_id = client_id) THEN
        RETURN 0;
    END IF;
    -- check if client always returned yachts in good condition
    IF NOT EXISTS (SELECT * FROM inspection WHERE condition = 'Unsatisfactory' AND client_id = client_id) THEN
        RETURN 0;
    END IF;
    -- calculate total amount of money paid by client
    SELECT SUM(amount) INTO total_amount FROM payment WHERE client_id = client_id;
    -- calculate discount
    discount := c1 * total_amount;
    IF discount > 25 THEN
        RETURN 25;
    ELSE
        RETURN discount;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION expected_payments(date_due date)
RETURNS TABLE(rental_id INTEGER, amount DECIMAL, due_date DATE, client_name CHAR(30), account_number CHAR(30))
AS $$
BEGIN
RETURN QUERY
SELECT rental.id as rental_id, rental.rental_fee as amount, rental.end_date as due_date, client.name as client_name, client.bank_account as account_number
FROM rental
INNER JOIN client ON rental.client_id = client.id
WHERE rental.end_date <= date_due AND rental.payment_scheme = 'not_paid'
ORDER BY rental.end_date;
END;
$$ LANGUAGE plpgsql;



--Триггеры

CREATE TRIGGER check_yacht_availability
  BEFORE INSERT ON rental
  FOR EACH ROW
  EXECUTE FUNCTION check_yacht_and_inspection();
  
  
CREATE FUNCTION check_yacht_and_inspection() RETURNS TRIGGER AS $$
BEGIN
    -- Check if yacht is currently available
    IF EXISTS (SELECT id FROM rental WHERE yacht_id = NEW.yacht_id AND end_date > NOW()) THEN
        RAISE EXCEPTION 'Yacht is not available for rental at this time.';
    END IF;

    -- Check if yacht's last inspection is recent
    IF NOT EXISTS (SELECT id FROM inspection WHERE yacht_id = NEW.yacht_id AND date > NOW() - INTERVAL '1 month') THEN
        RAISE EXCEPTION 'Yacht has not been recently inspected and may not be in suitable condition for rental.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION check_inspection_update() RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM rental WHERE rental.yacht_id = NEW.yacht_id AND rental.end_date > NOW()) THEN
    RAISE EXCEPTION 'Cannot update inspection for yacht that is currently in rental';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_inspection_update
BEFORE UPDATE ON inspection
FOR EACH ROW
EXECUTE FUNCTION check_inspection_update();



