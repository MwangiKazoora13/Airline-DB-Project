-- =====================================================================
--  AIRLINE RESERVATION DATABASE  |  02_sample_data.sql
--  Sample data (all people and numbers are fictional).
--  Load AFTER 01_schema.sql. Rows are inserted parent-first so every
--  foreign key is satisfied.
-- =====================================================================
USE airline_reservation_db;

-- 1. Airlines ----------------------------------------------------------
INSERT INTO airline (airline_id, airline_code, airline_name, home_country) VALUES
(1, 'KQ', 'Kenya Airways',          'Kenya'),
(2, 'MS', 'EgyptAir',               'Egypt'),
(3, 'ET', 'Ethiopian Airlines',     'Ethiopia'),
(4, 'WB', 'RwandAir',               'Rwanda'),
(5, 'AW', 'Africa World Airlines',  'Ghana'),
(6, 'HM', 'Air Seychelles',         'Seychelles'),
(7, 'MK', 'Air Mauritius',          'Mauritius'),
(8, 'SA', 'South African Airways',  'South Africa');

-- 2. Airports ----------------------------------------------------------
INSERT INTO airport (airport_code, airport_name, city, country) VALUES
('NBO', 'Jomo Kenyatta International Airport',     'Nairobi',      'Kenya'),
('MBA', 'Moi International Airport',               'Mombasa',      'Kenya'),
('KIS', 'Kisumu International Airport',            'Kisumu',       'Kenya'),
('CAI', 'Cairo International Airport',             'Cairo',        'Egypt'),
('ADD', 'Addis Ababa Bole International Airport',  'Addis Ababa',  'Ethiopia'),
('ACC', 'Kotoka International Airport',            'Accra',        'Ghana'),
('KGL', 'Kigali International Airport',            'Kigali',       'Rwanda'),
('SEZ', 'Seychelles International Airport',        'Victoria',     'Seychelles'),
('MRU', 'Sir Seewoosagur Ramgoolam Intl Airport',  'Port Louis',   'Mauritius'),
('CPT', 'Cape Town International Airport',         'Cape Town',    'South Africa'),
('JNB', 'O. R. Tambo International Airport',       'Johannesburg', 'South Africa');

-- 3. Flights (route products) ---------------------------------------------
--    smoking_allowed = 0 everywhere; flight 3 is a domestic hop, economy only
INSERT INTO flight (flight_id, airline_id, flight_number, origin_airport, destination_airport,
                    smoking_allowed, has_business_class) VALUES
(1,  1, 101, 'NBO', 'ACC', 0, 1),
(2,  1, 202, 'NBO', 'KGL', 0, 1),
(3,  1, 303, 'MBA', 'NBO', 0, 0),
(4,  2, 401, 'CAI', 'NBO', 0, 1),
(5,  3, 501, 'ADD', 'NBO', 0, 1),
(6,  4, 601, 'KGL', 'NBO', 0, 1),
(7,  5, 701, 'ACC', 'CAI', 0, 1),
(8,  6, 801, 'SEZ', 'NBO', 0, 1),
(9,  7, 901, 'MRU', 'CPT', 0, 1),
(10, 8, 111, 'CPT', 'NBO', 0, 1);

-- 4. Dated departures with capacity and prices (USD, per passenger) -----------
INSERT INTO flight_availability
 (availability_id, flight_id, departure_datetime, arrival_datetime,
  economy_seats_total, business_seats_total, economy_price, business_price) VALUES
(1,  1, '2026-11-05 08:00:00', '2026-11-05 13:30:00', 150, 24, 520.00, 1450.00),
(2,  1, '2026-11-12 08:00:00', '2026-11-12 13:30:00', 150, 24, 520.00, 1450.00),
(3,  2, '2026-11-06 10:15:00', '2026-11-06 11:45:00', 120, 16, 180.00,  520.00),
(4,  3, '2026-11-07 07:00:00', '2026-11-07 08:00:00',   4,  0,  60.00,    0.00),  -- tiny plane: sells out
(5,  4, '2026-11-08 23:30:00', '2026-11-09 04:30:00', 160, 20, 480.00, 1300.00),
(6,  5, '2026-11-10 06:40:00', '2026-11-10 08:40:00', 140, 18, 250.00,  700.00),
(7,  6, '2026-11-15 14:00:00', '2026-11-15 15:30:00', 110, 12, 210.00,  600.00),
(8,  7, '2026-11-20 09:00:00', '2026-11-20 14:00:00', 130, 16, 430.00, 1200.00),
(9,  8, '2026-12-01 11:00:00', '2026-12-01 15:00:00', 100, 14, 390.00, 1100.00),
(10, 9, '2026-12-03 13:30:00', '2026-12-03 18:30:00', 120, 16, 410.00, 1250.00),
(11, 10,'2026-12-05 06:00:00', '2026-12-05 11:00:00', 150, 20, 460.00, 1380.00),
(12, 2, '2026-12-18 10:15:00', '2026-12-18 11:45:00', 120, 16, 180.00,  520.00);

-- 5. Mailing addresses ---------------------------------------------------------
INSERT INTO mailing_address (address_id, street, city, state, postal_code, country) VALUES
(1, '12 Nile Corniche Street', 'Cairo',        'Cairo Governorate', '11511',  'Egypt'),
(2, '45 Tom Mboya Street',     'Nairobi',      'Nairobi County',    '00100',  'Kenya'),
(3, '8 Oxford Street',         'Accra',        'Greater Accra',     'GA-039', 'Ghana'),
(4, '3 KG 7 Avenue',           'Kigali',       'Kigali City',       NULL,     'Rwanda'),
(5, '22 Nyali Road',           'Mombasa',      'Mombasa County',    '80100',  'Kenya'),
(6, '17 Ring Road Central',    'Accra',        'Greater Accra',     'GA-184', 'Ghana'),
(7, '5 Bole Road',             'Addis Ababa',  'Addis Ababa',       '1000',   'Ethiopia'),
(8, '9 Long Street',           'Cape Town',    'Western Cape',      '8001',   'South Africa');

-- 6. Customers (first four come from the original project) -------------------------
INSERT INTO customer (customer_id, full_name, email, address_id) VALUES
(1, 'Aziz Husein',    'aziz22@gmail.com',   1),
(2, 'Jack Omondi',    'jack49@gmail.com',   2),
(3, 'Johnny Miracle', 'johny331@gmail.com', 3),
(4, 'Alice Mwiza',    'alice12@gmail.com',  4),
(5, 'Amina Yusuf',    'amina.y@example.com',   5),
(6, 'Kwame Mensah',   'kwame.m@example.com',   6),
(7, 'Selam Tesfaye',  'selam.t@example.com',   7),
(8, 'Thabo Nkosi',    'thabo.n@example.com',   8);

-- 7. Phone numbers (some customers have two) -------------------------------------
INSERT INTO customer_phone (customer_id, phone_number) VALUES
(1, '+201234567890'),
(2, '+254723443212'),
(2, '+254733100200'),
(3, '+233843582973'),
(4, '+250788234567'),
(5, '+254711456789'),
(6, '+233244123456'),
(6, '+233302765432'),
(7, '+251911223344'),
(8, '+27821234567');

-- 8. Fax numbers (optional; only some customers have one) ----------------------------
INSERT INTO customer_fax (customer_id, country_code, area_code, local_number) VALUES
(1, '20',  '2',   '23456789'),
(2, '254', '20',  '2223344'),
(3, '233', '30',  '2765432'),
(4, '250', '252', '570000');

-- 9. Booking statuses ----------------------------------------------------------
INSERT INTO booking_status (status_id, status_name, description) VALUES
(1, 'booked',    'Active reservation; the seats are held for the customer.'),
(2, 'cancelled', 'Cancelled by the customer; the seats are released.'),
(3, 'scratched', 'Removed from the list by the airline (e.g. no-show or flight change); seats are released.');

-- 10. Bookings -------------------------------------------------------------------
--     base_amount / tax_amount / total_amount are filled in by the
--     trg_booking_before_insert trigger, so they are not listed here.
INSERT INTO booking (customer_id, availability_id, booking_city, booking_date,
                     travel_class, passengers, status_id) VALUES
(2, 1,  'Nairobi',     '2026-10-01', 'economy',  2, 1),   -- 4532 Jack, NBO->ACC
(1, 5,  'Cairo',       '2026-10-02', 'business', 1, 1),   -- 4533 Aziz, CAI->NBO
(3, 8,  'Accra',       '2026-10-03', 'economy',  1, 2),   -- 4534 Johnny, cancelled
(4, 7,  'Kigali',      '2026-10-04', 'economy',  1, 3),   -- 4535 Alice, scratched
(5, 4,  'Mombasa',     '2026-10-05', 'economy',  3, 1),   -- 4536 Amina, MBA->NBO
(6, 1,  'Accra',       '2026-10-06', 'economy',  1, 1),   -- 4537 Kwame, NBO->ACC
(7, 6,  'Addis Ababa', '2026-10-07', 'business', 2, 1),   -- 4538 Selam, ADD->NBO
(8, 11, 'Cape Town',   '2026-10-07', 'economy',  1, 1),   -- 4539 Thabo, CPT->NBO
(2, 2,  'Nairobi',     '2026-10-08', 'business', 1, 1),   -- 4540 Jack, NBO->ACC again
(4, 12, 'Kigali',      '2026-10-09', 'economy',  1, 1),   -- 4541 Alice, NBO->KGL
(1, 8,  'Cairo',       '2026-10-09', 'business', 1, 1),   -- 4542 Aziz, ACC->CAI
(3, 4,  'Accra',       '2026-10-10', 'economy',  1, 1),   -- 4543 Johnny: fills the 4-seat MBA->NBO plane
(7, 10, 'Addis Ababa', '2026-10-11', 'economy',  2, 1);   -- 4544 Selam, MRU->CPT
