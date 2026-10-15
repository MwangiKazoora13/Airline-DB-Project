-- =====================================================================
--  AIRLINE RESERVATION DATABASE  |  MySQL 8.0.16+  |  01_schema.sql
--  Creates: database, 10 tables, 1 function, 2 triggers, 2 procedures,
--           4 views
--  Run order: 01_schema.sql -> 02_sample_data.sql -> 03_sample_queries.sql
-- =====================================================================

DROP DATABASE IF EXISTS airline_reservation_db;
CREATE DATABASE airline_reservation_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE airline_reservation_db;

-- ---------------------------------------------------------------------
-- 1. AIRLINE  - companies that operate flights
-- ---------------------------------------------------------------------
CREATE TABLE airline (
    airline_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    airline_code  CHAR(2)      NOT NULL,            -- IATA code, e.g. KQ
    airline_name  VARCHAR(80)  NOT NULL,
    home_country  VARCHAR(60)  NOT NULL,
    PRIMARY KEY (airline_id),
    UNIQUE KEY uq_airline_code (airline_code)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. AIRPORT  - places a flight can depart from / arrive at
-- ---------------------------------------------------------------------
CREATE TABLE airport (
    airport_code  CHAR(3)      NOT NULL,            -- IATA code, e.g. NBO
    airport_name  VARCHAR(100) NOT NULL,
    city          VARCHAR(60)  NOT NULL,
    country       VARCHAR(60)  NOT NULL,
    PRIMARY KEY (airport_code)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. FLIGHT  - a route product, e.g. "KQ 101 Nairobi -> Accra".
--    (Original design: FLIGHT. Airline code is now a foreign key and the
--    flight number is unique PER AIRLINE.)
-- ---------------------------------------------------------------------
CREATE TABLE flight (
    flight_id            INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    airline_id           SMALLINT UNSIGNED NOT NULL,
    flight_number        SMALLINT UNSIGNED NOT NULL,
    origin_airport       CHAR(3)           NOT NULL,
    destination_airport  CHAR(3)           NOT NULL,
    smoking_allowed      BOOLEAN           NOT NULL DEFAULT FALSE,  -- "Smoking allowed indicator"
    has_business_class   BOOLEAN           NOT NULL DEFAULT TRUE,   -- "Business class indicator"
    PRIMARY KEY (flight_id),
    UNIQUE KEY uq_flight_per_airline (airline_id, flight_number),
    KEY idx_flight_route (origin_airport, destination_airport),
    CONSTRAINT fk_flight_airline FOREIGN KEY (airline_id)
        REFERENCES airline (airline_id),
    CONSTRAINT fk_flight_origin FOREIGN KEY (origin_airport)
        REFERENCES airport (airport_code),
    CONSTRAINT fk_flight_destination FOREIGN KEY (destination_airport)
        REFERENCES airport (airport_code),
    CONSTRAINT chk_flight_route CHECK (origin_airport <> destination_airport)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. FLIGHT_AVAILABILITY - one dated departure of a flight, with its
--    seat capacity and ticket prices.
--    NOTE: "booked seats" are NOT stored here. They are calculated from
--    the booking table, so the numbers can never drift out of sync.
-- ---------------------------------------------------------------------
CREATE TABLE flight_availability (
    availability_id       INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    flight_id             INT UNSIGNED      NOT NULL,
    departure_datetime    DATETIME          NOT NULL,   -- stored as UTC
    arrival_datetime      DATETIME          NOT NULL,   -- stored as UTC
    economy_seats_total   SMALLINT UNSIGNED NOT NULL,
    business_seats_total  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    economy_price         DECIMAL(10,2)     NOT NULL,   -- per passenger, USD
    business_price        DECIMAL(10,2)     NOT NULL DEFAULT 0.00,
    PRIMARY KEY (availability_id),
    UNIQUE KEY uq_flight_departure (flight_id, departure_datetime),
    KEY idx_departure (departure_datetime),
    CONSTRAINT fk_avail_flight FOREIGN KEY (flight_id)
        REFERENCES flight (flight_id),
    CONSTRAINT chk_avail_times CHECK (arrival_datetime > departure_datetime),
    CONSTRAINT chk_avail_prices CHECK (economy_price > 0 AND business_price >= 0),
    CONSTRAINT chk_avail_business CHECK (business_seats_total = 0 OR business_price > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. MAILING_ADDRESS - where the airline posts information to
-- ---------------------------------------------------------------------
CREATE TABLE mailing_address (
    address_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    street       VARCHAR(100) NOT NULL,
    city         VARCHAR(60)  NOT NULL,
    state        VARCHAR(60)  NOT NULL,               -- state / county / province
    postal_code  VARCHAR(12)  NULL,                   -- some countries have none
    country      VARCHAR(60)  NOT NULL,
    PRIMARY KEY (address_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. CUSTOMER
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(100) NOT NULL,
    address_id   INT UNSIGNED NOT NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customer_email (email),
    CONSTRAINT fk_customer_address FOREIGN KEY (address_id)
        REFERENCES mailing_address (address_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. CUSTOMER_PHONE - a customer can have many phone numbers
--    (replaces the old "Phonenumber(s)" column, which was the primary
--    key of customers and could hold only one value)
-- ---------------------------------------------------------------------
CREATE TABLE customer_phone (
    phone_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id   INT UNSIGNED NOT NULL,
    phone_number  VARCHAR(20)  NOT NULL,              -- international format
    PRIMARY KEY (phone_id),
    UNIQUE KEY uq_phone_number (phone_number),
    CONSTRAINT fk_phone_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. CUSTOMER_FAX - optional, at most one fax per customer (1:0..1)
--    The customer_id is both the primary key and the foreign key.
-- ---------------------------------------------------------------------
CREATE TABLE customer_fax (
    customer_id   INT UNSIGNED NOT NULL,
    country_code  VARCHAR(4)   NOT NULL,
    area_code     VARCHAR(6)   NOT NULL,
    local_number  VARCHAR(12)  NOT NULL,
    PRIMARY KEY (customer_id),
    CONSTRAINT fk_fax_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. BOOKING_STATUS - lookup table (the old "Status indicator")
-- ---------------------------------------------------------------------
CREATE TABLE booking_status (
    status_id    TINYINT UNSIGNED NOT NULL,
    status_name  VARCHAR(20)      NOT NULL,
    description  VARCHAR(120)     NOT NULL,
    PRIMARY KEY (status_id),
    UNIQUE KEY uq_status_name (status_name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. BOOKING - a customer reserving seats on one dated departure.
--     Departure/arrival times are no longer copied here (they live in
--     flight_availability). Price columns are filled by a trigger.
--     AUTO_INCREMENT starts at 4532, the first booking no. of the
--     original project.
-- ---------------------------------------------------------------------
CREATE TABLE booking (
    booking_id       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    customer_id      INT UNSIGNED     NOT NULL,
    availability_id  INT UNSIGNED     NOT NULL,
    booking_city     VARCHAR(60)      NOT NULL,       -- city where booking was made
    booking_date     DATE             NOT NULL DEFAULT (CURRENT_DATE),
    travel_class     ENUM('economy','business') NOT NULL,
    passengers       TINYINT UNSIGNED NOT NULL DEFAULT 1,
    status_id        TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- 1 = booked
    base_amount      DECIMAL(10,2)    NOT NULL DEFAULT 0.00, -- set by trigger
    tax_amount       DECIMAL(10,2)    NOT NULL DEFAULT 0.00, -- set by trigger
    total_amount     DECIMAL(10,2)    NOT NULL DEFAULT 0.00, -- set by trigger
    created_at       TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (booking_id),
    KEY idx_booking_customer (customer_id),
    KEY idx_booking_seats (availability_id, travel_class, status_id),
    CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id),
    CONSTRAINT fk_booking_availability FOREIGN KEY (availability_id)
        REFERENCES flight_availability (availability_id),
    CONSTRAINT fk_booking_status FOREIGN KEY (status_id)
        REFERENCES booking_status (status_id),
    CONSTRAINT chk_booking_passengers CHECK (passengers BETWEEN 1 AND 9)
) ENGINE=InnoDB AUTO_INCREMENT=4532;

-- =====================================================================
--  VIEWS
-- =====================================================================

-- Seats currently held by active ("booked") reservations, per departure
CREATE VIEW v_seat_usage AS
SELECT  availability_id,
        SUM(CASE WHEN travel_class = 'economy' THEN passengers ELSE 0 END) AS economy_booked,
        SUM(CASE WHEN travel_class = 'business' THEN passengers ELSE 0 END) AS business_booked
FROM    booking
WHERE   status_id = 1
GROUP BY availability_id;

-- Everything a search page needs: route, times, prices, seats left
CREATE VIEW v_flight_availability AS
SELECT  fa.availability_id,
        CONCAT(al.airline_code, ' ', f.flight_number)  AS flight_code,
        al.airline_name,
        f.origin_airport       AS origin_code,
        o.city                 AS origin_city,
        f.destination_airport  AS destination_code,
        d.city                 AS destination_city,
        fa.departure_datetime,
        fa.arrival_datetime,
        f.smoking_allowed,
        f.has_business_class,
        fa.economy_price,
        fa.business_price,
        fa.economy_seats_total,
        COALESCE(u.economy_booked, 0)                             AS economy_booked,
        fa.economy_seats_total - COALESCE(u.economy_booked, 0)    AS economy_available,
        fa.business_seats_total,
        COALESCE(u.business_booked, 0)                            AS business_booked,
        fa.business_seats_total - COALESCE(u.business_booked, 0)  AS business_available
FROM    flight_availability fa
JOIN    flight   f  ON f.flight_id      = fa.flight_id
JOIN    airline  al ON al.airline_id    = f.airline_id
JOIN    airport  o  ON o.airport_code   = f.origin_airport
JOIN    airport  d  ON d.airport_code   = f.destination_airport
LEFT JOIN v_seat_usage u ON u.availability_id = fa.availability_id;

-- One readable row per booking
CREATE VIEW v_booking_details AS
SELECT  b.booking_id,
        b.booking_date,
        b.booking_city,
        c.customer_id,
        c.full_name       AS customer_name,
        c.email,
        v.flight_code,
        CONCAT(v.origin_code, ' -> ', v.destination_code) AS route,
        v.departure_datetime,
        b.travel_class,
        b.passengers,
        s.status_name,
        b.base_amount,
        b.tax_amount,
        b.total_amount
FROM    booking b
JOIN    customer c              ON c.customer_id      = b.customer_id
JOIN    booking_status s        ON s.status_id        = b.status_id
JOIN    v_flight_availability v ON v.availability_id  = b.availability_id;

-- Customer contact card: address + all phones + fax in one row
CREATE VIEW v_customer_contacts AS
SELECT  c.customer_id,
        c.full_name,
        c.email,
        CONCAT(a.street, ', ', a.city, ', ', a.state, ', ', a.country) AS mailing_address,
        (SELECT GROUP_CONCAT(p.phone_number ORDER BY p.phone_id SEPARATOR ', ')
           FROM customer_phone p
          WHERE p.customer_id = c.customer_id) AS phone_numbers,
        (SELECT CONCAT('+', x.country_code, ' ', x.area_code, ' ', x.local_number)
           FROM customer_fax x
          WHERE x.customer_id = c.customer_id) AS fax
FROM    customer c
JOIN    mailing_address a ON a.address_id = c.address_id;

-- =====================================================================
--  STORED FUNCTION, TRIGGERS, PROCEDURES  (business rules)
-- =====================================================================
DELIMITER $$

-- Seats still free in one class of one departure (NULL if departure unknown)
CREATE FUNCTION fn_seats_left(p_availability_id INT UNSIGNED, p_class VARCHAR(10))
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total  INT;
    DECLARE v_booked INT;

    SELECT CASE WHEN p_class = 'economy' THEN economy_seats_total
                ELSE business_seats_total END
      INTO v_total
      FROM flight_availability
     WHERE availability_id = p_availability_id;

    IF v_total IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(SUM(passengers), 0)
      INTO v_booked
      FROM booking
     WHERE availability_id = p_availability_id
       AND travel_class    = p_class
       AND status_id       = 1;

    RETURN v_total - v_booked;
END$$

-- On every new booking: refuse overbooking and calculate the price + tax
CREATE TRIGGER trg_booking_before_insert
BEFORE INSERT ON booking
FOR EACH ROW
BEGIN
    DECLARE v_left  INT;
    DECLARE v_price DECIMAL(10,2);

    SET v_left = fn_seats_left(NEW.availability_id, NEW.travel_class);

    IF v_left IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown flight departure.';
    END IF;

    -- only active bookings consume seats
    IF NEW.status_id = 1 AND NEW.passengers > v_left THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough seats left in this class on this departure.';
    END IF;

    SELECT CASE WHEN NEW.travel_class = 'economy' THEN economy_price
                ELSE business_price END
      INTO v_price
      FROM flight_availability
     WHERE availability_id = NEW.availability_id;

    SET NEW.base_amount  = v_price * NEW.passengers;
    SET NEW.tax_amount   = ROUND(NEW.base_amount * 0.16, 2);   -- flat 16% demo tax rate
    SET NEW.total_amount = NEW.base_amount + NEW.tax_amount;
END$$

-- On update: only the status may change; re-activating a booking needs seats
CREATE TRIGGER trg_booking_before_update
BEFORE UPDATE ON booking
FOR EACH ROW
BEGIN
    IF NEW.availability_id <> OLD.availability_id
       OR NEW.travel_class <> OLD.travel_class
       OR NEW.passengers   <> OLD.passengers THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Flight, class and passengers cannot be edited. Cancel and rebook instead.';
    END IF;

    -- prices are frozen at booking time
    SET NEW.base_amount  = OLD.base_amount;
    SET NEW.tax_amount   = OLD.tax_amount;
    SET NEW.total_amount = OLD.total_amount;

    IF NEW.status_id = 1 AND OLD.status_id <> 1
       AND NEW.passengers > fn_seats_left(OLD.availability_id, OLD.travel_class) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot re-activate: seats are no longer available.';
    END IF;
END$$

-- Safe way to book: locks the departure row so two people cannot take
-- the last seat at the same time
CREATE PROCEDURE sp_book_flight(
    IN  p_customer_id     INT UNSIGNED,
    IN  p_availability_id INT UNSIGNED,
    IN  p_class           VARCHAR(10),
    IN  p_passengers      TINYINT UNSIGNED,
    IN  p_booking_city    VARCHAR(60),
    OUT p_booking_id      INT UNSIGNED
)
BEGIN
    DECLARE v_lock INT UNSIGNED;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT availability_id INTO v_lock
      FROM flight_availability
     WHERE availability_id = p_availability_id
       FOR UPDATE;

    INSERT INTO booking (customer_id, availability_id, booking_city,
                         travel_class, passengers, status_id)
    VALUES (p_customer_id, p_availability_id, p_booking_city,
            p_class, p_passengers, 1);

    SET p_booking_id = LAST_INSERT_ID();
    COMMIT;
END$$

-- Cancel an active booking (frees its seats automatically)
CREATE PROCEDURE sp_cancel_booking(IN p_booking_id INT UNSIGNED)
BEGIN
    UPDATE booking
       SET status_id = 2                -- cancelled
     WHERE booking_id = p_booking_id
       AND status_id  = 1;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Booking not found or not currently active.';
    END IF;
END$$

DELIMITER ;
