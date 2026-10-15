-- =====================================================================
--  AIRLINE RESERVATION DATABASE  |  03_sample_queries.sql
--  Run these one at a time after loading the schema and sample data.
-- =====================================================================
USE airline_reservation_db;

-- Q1. Search: all departures from Nairobi with seats left and prices
SELECT flight_code, origin_city, destination_city, departure_datetime,
       economy_price, economy_available, business_price, business_available
FROM   v_flight_availability
WHERE  origin_code = 'NBO'
ORDER BY departure_datetime;

-- Q2. Which departures are completely sold out in economy?
SELECT flight_code, origin_city, destination_city, departure_datetime
FROM   v_flight_availability
WHERE  economy_available = 0;

-- Q3. Full booking list in readable form
SELECT booking_id, customer_name, flight_code, route, departure_datetime,
       travel_class, passengers, status_name, total_amount
FROM   v_booking_details
ORDER BY booking_id;

-- Q4. Booking history of one customer (Jack Omondi, id 2)
SELECT booking_id, flight_code, route, travel_class, passengers,
       status_name, base_amount, tax_amount, total_amount
FROM   v_booking_details
WHERE  customer_id = 2;

-- Q5. Revenue per airline (active bookings only)
SELECT al.airline_name,
       COUNT(*)            AS bookings,
       SUM(b.passengers)   AS passengers,
       SUM(b.total_amount) AS revenue_usd
FROM   booking b
JOIN   flight_availability fa ON fa.availability_id = b.availability_id
JOIN   flight  f              ON f.flight_id        = fa.flight_id
JOIN   airline al             ON al.airline_id      = f.airline_id
WHERE  b.status_id = 1
GROUP BY al.airline_id, al.airline_name
ORDER BY revenue_usd DESC;

-- Q6. How many bookings are in each status?
SELECT s.status_name, COUNT(b.booking_id) AS bookings
FROM   booking_status s
LEFT JOIN booking b ON b.status_id = s.status_id
GROUP BY s.status_id, s.status_name
ORDER BY s.status_id;

-- Q7. Load factor (% of seats sold) for every departure
SELECT flight_code, departure_datetime,
       ROUND(100 * (economy_booked + business_booked)
                 / (economy_seats_total + business_seats_total), 1) AS pct_full
FROM   v_flight_availability
ORDER BY pct_full DESC;

-- Q8. Customers who have booked more than once
SELECT c.full_name, COUNT(*) AS active_bookings, SUM(b.total_amount) AS total_spent
FROM   customer c
JOIN   booking  b ON b.customer_id = c.customer_id AND b.status_id = 1
GROUP BY c.customer_id, c.full_name
HAVING COUNT(*) > 1;

-- Q9. Customer contact cards (address, all phones, fax)
SELECT * FROM v_customer_contacts;

-- Q10. Customers per country (via the mailing address)
SELECT a.country, COUNT(*) AS customers
FROM   customer c
JOIN   mailing_address a ON a.address_id = c.address_id
GROUP BY a.country
ORDER BY customers DESC;

-- =====================================================================
--  Business-rule demos
-- =====================================================================

-- D1. Make a booking with the safe procedure (Alice, 2 economy seats,
--     NBO->ACC on 12 Nov). Price and tax are calculated automatically.
CALL sp_book_flight(4, 2, 'economy', 2, 'Kigali', @new_booking);
SELECT * FROM v_booking_details WHERE booking_id = @new_booking;

-- D2. Seats left drop automatically (no seat counter to update)
SELECT flight_code, economy_available FROM v_flight_availability WHERE availability_id = 2;

-- D3. Cancel it: the seats come back
CALL sp_cancel_booking(@new_booking);
SELECT flight_code, economy_available FROM v_flight_availability WHERE availability_id = 2;

-- D4. Overbooking is rejected (the MBA->NBO plane is full).
--     Expected: ERROR 1644 "Not enough seats left in this class on this departure."
CALL sp_book_flight(1, 4, 'economy', 1, 'Cairo', @x);

-- D5. Business class on a flight that has none is rejected the same way.
CALL sp_book_flight(1, 4, 'business', 1, 'Cairo', @x);

-- D6. Referential integrity: a booking for a customer that does not exist fails.
--     Expected: ERROR 1452 foreign key constraint fails.
INSERT INTO booking (customer_id, availability_id, booking_city, travel_class)
VALUES (999, 1, 'Nairobi', 'economy');

-- D7. Prices are frozen: trying to edit them is silently ignored by the trigger.
UPDATE booking SET total_amount = 1.00 WHERE booking_id = 4532;
SELECT booking_id, total_amount FROM booking WHERE booking_id = 4532;   -- unchanged
