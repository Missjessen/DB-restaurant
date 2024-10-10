DROP DATABASE IF EXISTS RestaurantDB1;
CREATE DATABASE RestaurantDB1;
USE RestaurantDB1;

--  Kunde-tabellen
CREATE TABLE `customer` (
    customer_ID INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
    first_name VARCHAR(100) NULL,
    last_name VARCHAR(100) NULL,
    phone VARCHAR(15) NULL,
    email VARCHAR(100) NULL
);

-- Bord-tabellen med bordnumre fra 1 til 15
CREATE TABLE `restaurant_table` (
    `table_ID` INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
    table_number INT UNIQUE NULL, 
    numberSeat INT DEFAULT 8 NULL
);

-- Booking-tabellen med referencer til Kunde- og Bord-tabellen
CREATE TABLE `Booking` (
    booking_ID INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
    customer_ID INT NOT NULL,
    `table_ID` INT NOT NULL,
    bookingDate DATE NULL,
    start_time TIME NULL,
    number_guests INT NULL,
    FOREIGN KEY (customer_ID) REFERENCES customer(customer_ID),
    FOREIGN KEY (`table_ID`) REFERENCES restaurant_table(`table_ID`)
);

DELIMITER $$

CREATE TRIGGER auto_booking_2_hours
BEFORE INSERT ON Booking
FOR EACH ROW
BEGIN
    -- (2 timer efter start_time)
    DECLARE end_time TIME;
    SET end_time = ADDTIME(NEW.start_time, '02:00:00');

    -- Tjek  15:00 og 20:00 
    IF NEW.start_time < '15:00:00' OR NEW.start_time >= '20:00:00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking start time must be between 03:00 PM and 08:00 PM ';
    END IF;

    -- Tjek om end_time går ud over kl. 21:00
    IF end_time > '21:00:00' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking end time must be before 09:00 PM';
    END IF;

    -- Tjek allerede er en booking for samme bord
    IF EXISTS (
        SELECT 1 FROM Booking
        WHERE table_ID = NEW.table_ID
        AND bookingDate = NEW.bookingDate
        AND (
            (NEW.start_time BETWEEN start_time AND ADDTIME(start_time, '02:00:00')) OR
            (end_time BETWEEN start_time AND ADDTIME(start_time, '02:00:00')) OR
            (start_time BETWEEN NEW.start_time AND end_time)
        )
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This table is already booked for the selected time slot';
    END IF;

    -- number_guests er mellem 1 og 8
    IF NEW.number_guests < 1 OR NEW.number_guests > 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Number of guests must be between 1 and 8. For larger reservations, call 123456789.';
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER check_seat_availability
BEFORE INSERT ON Booking
FOR EACH ROW
BEGIN
    DECLARE available_seats INT;
    DECLARE seat_info VARCHAR(255);
    DECLARE error_message VARCHAR(500);

    -- antal pladser for det valgte bord
    SELECT numberSeat INTO available_seats 
    FROM restaurant_table 
    WHERE table_ID = NEW.table_ID;

    -- Tjek om gæster overstiger antal 
    IF NEW.number_guests > available_seats THEN
        -- Find alle borde med tilstrækkelig kapacitet og gem dem i seat_info
        SELECT GROUP_CONCAT(CONCAT('Bord ', table_number, ': ', numberSeat, ' pladser') SEPARATOR '; ') 
        INTO seat_info
        FROM restaurant_table
        WHERE numberSeat >= NEW.number_guests;

        -- Hvis ingen borde har tilstrækkelig kapacitet
        IF seat_info IS NULL THEN
            SET seat_info = 'Ingen borde har tilstrækkelig kapacitet.';
        END IF;

        -- fejlbesked
        SET error_message = CONCAT('Bordet kan ikke rumme ', NEW.number_guests, 
                                   ' gæster. Tilgængelige borde: ', seat_info);

        -- Send fejlbesked
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;
END $$

DELIMITER ;






-- testdata i Kunde-tabellen
INSERT INTO customer (first_name, last_name, phone, email) VALUES
('Rosalia', 'Gant', '440-436-2079', 'rgant0@deliciousdays.com'),
('Kassandra', 'Rosettini', '223-213-5705', 'krosettini1@woothemes.com'),
('Monty', 'Raisbeck', '628-126-4421', 'mraisbeck2@buzzfeed.com'),
('Lemar', 'Pasfield', '130-288-4109', 'lpasfield3@dion.ne.jp'),
('Irene', 'Adamovicz', '502-245-7057', 'iadamovicz4@oaic.gov.au'),
('Heriberto', 'Stollery', '518-505-0687', 'hstollery5@163.com'),
('Maya', 'Tindle', '312-455-6678', 'mtindle0@wordpress.com'),
('Oscar', 'Wyman', '227-916-3490', 'owyman1@github.io'),
('Fiona', 'Lawler', '481-732-5481', 'flawler2@behance.net'),
('Glen', 'Devore', '243-198-9831', 'gdevore3@linkedin.com'),
('Maggie', 'Poland', '514-612-9832', 'mpoland4@blogspot.com'),
('Clara', 'Arnold', '429-652-1023', 'carnold5@flickr.com'),
('Roger', 'Harkness', '541-720-4390', 'rharkness6@walmart.com'),
('Lila', 'Fitzpatrick', '630-555-0164', 'lfitzpatrick7@etsy.com'),
('Byron', 'Napier', '313-334-7788', 'bnapier8@tumblr.com'),
('Norah', 'Judd', '518-533-9021', 'njudd9@usnews.com');

--  15 borde i Bord-tabellen med bordnumre og antal sæder
INSERT INTO `restaurant_table` (table_number, numberSeat) VALUES
(1, 4), 
(2, 4), 
(3, 4), 
(4, 4), 
(5, 6), 
(6, 6), 
(7, 6), 
(8, 6), 
(9, 6), 
(10, 6), 
(11, 6), 
(12, 8), 
(13, 8), 
(14, 8), 
(15, 8);

-- testdata i Booking-tabellen
INSERT INTO booking (customer_ID, table_ID, bookingDate, start_time, number_guests) VALUES
(1, 3, '2024-06-23', '17:15:00', 4),
(2, 4, '2023-12-01', '17:22:00', 3), 
(3, 15, '2024-03-30', '18:35:00', 6), 
(4, 7, '2024-08-13', '18:55:00', 5), 
(5, 6, '2024-12-24', '17:47:00', 2), 
(5, 5, '2024-12-24', '17:47:00', 2),
(6, 2, '2024-05-05', '16:30:00', 4), 
(7, 8, '2024-07-14', '18:00:00', 3), 
(8, 1, '2024-10-10', '15:45:00', 3), 
(9, 12, '2024-11-03', '17:00:00', 5), 
(10, 10, '2024-09-18', '19:00:00', 4), 
(11, 12, '2024-08-20', '16:15:00', 8),
(12, 13, '2024-10-25', '18:10:00', 4), 
(13, 14, '2024-06-05', '17:30:00', 6), 
(14, 9, '2024-12-15', '16:00:00', 3), 
(15, 15, '2024-08-22', '18:20:00', 2);


CREATE VIEW restaurant_tables AS
SELECT table_ID, table_number, numberSeat
FROM restaurant_table;

CREATE VIEW table_bookings AS
SELECT 
    b.booking_ID, 
    r.table_number,
    b.bookingDate, 
    c.first_name, 
    c.last_name, 
    b.number_guests,  
    b.start_time
FROM Booking b
JOIN customer c ON b.customer_ID = c.customer_ID
JOIN restaurant_table r ON b.table_ID = r.table_ID
ORDER BY b.bookingDate;


CREATE OR REPLACE VIEW receptionist_view AS
SELECT 
    b.booking_ID,
    c.first_name,
    c.last_name,
    c.phone,
    b.bookingDate,
    b.number_guests,
    r.table_number,
    b.start_time,
    ADDTIME(b.start_time, '02:00:00') AS end_time
FROM Booking b
JOIN customer c ON b.customer_ID = c.customer_ID
JOIN restaurant_table r ON b.table_ID = r.table_ID
ORDER BY b.bookingDate;

