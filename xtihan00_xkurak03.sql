/*----------------------------------------------------------------------------------------
-- IDS Part 2 - SQL script for creating database schema objects
--
-- Creators:
--   - Alexandr Tihanschi (xtihan00)
--   - Kirill Kurakov (xkurak03)
--
----------------------------------------------------------------------------------------*/

/* Drop sequences */
DROP SEQUENCE person_seq;
DROP SEQUENCE room_seq;
DROP SEQUENCE reservation_seq;
DROP SEQUENCE action_seq;
DROP SEQUENCE service_request_seq;
DROP SEQUENCE service_seq;
DROP SEQUENCE term_seq;
DROP SEQUENCE payment_seq;

/* Drop tables */
DROP TABLE service_request_service_employee_perform;
DROP TABLE service_request;
DROP TABLE term;
DROP TABLE service;
DROP TABLE payment;
DROP TABLE action;
DROP TABLE reservation_customer_live;
DROP TABLE reservation;
DROP TABLE room;
DROP TABLE customer;
DROP TABLE service_employee;
DROP TABLE front_desk_employee;
DROP TABLE person;

/* Create sequences */
create sequence person_seq START with 1 increment by 1;
create sequence room_seq START with 100 increment by 1;
create sequence reservation_seq START with 1 increment by 1;
create sequence action_seq START with 1 increment by 1;
create sequence service_request_seq START with 1 increment by 1;
create sequence service_seq START with 1 increment by 1;
create sequence term_seq START with 1 increment by 1;
create sequence payment_seq START with 1 increment by 1;

/* Create tables */
/*  For the generalization relationship here is usedtable for supertype + for 
    subtypes with primary key of supertype. The subtypes are too different to be in 
    the same table (with types) and also for 3 character types it is excessive 
    to store the same attributes like in the first way of solving this problem */
create table person(
    person_id INT, 
    first_name VARCHAR2(255) NOT NULL,
    last_name VARCHAR2(255) NOT NULL,
    birth_date DATE NOT NULL,
    sex CHAR(1) NOT NULL,
    id_card_number VARCHAR2(32) UNIQUE,
    telephone VARCHAR2(32) UNIQUE,
    email VARCHAR2(64),
    nationality VARCHAR2(8),

    CONSTRAINT check_sex CHECK (sex IN ('M', 'F')),
    CONSTRAINT check_telephone CHECK (REGEXP_LIKE(telephone, '^\+[0-9]{1,3}-?[0-9]{1,14}$')),
    CONSTRAINT check_email CHECK (REGEXP_LIKE(email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    CONSTRAINT PK_person PRIMARY KEY (person_id)
);

/* child table of the person */
create table front_desk_employee(
    person_id INT,
    "RANK" VARCHAR2(6),

    CONSTRAINT check_rank CHECK ("RANK" IN ('JUNIOR', 'SENIOR')),
    CONSTRAINT FK_fde_person FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE CASCADE,
    CONSTRAINT PK_fde PRIMARY KEY (person_id)
);

/* child table of the person */
create table service_employee(
    person_id INT,
    specialization VARCHAR2(32),

    CONSTRAINT spec_check CHECK (specialization IN ('RESTAURANT', 'HOUSEKEEPING', 'MAINTENANCE', 'ENTERTAINMENT', 'FITNESS', 'OTHER')),
    CONSTRAINT FK_service_employee_person FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE CASCADE,
    CONSTRAINT PK_service_employee PRIMARY KEY (person_id)
);

/* child table of the person */
/* This solution, unlike the ER diagram from the first part, does not have a 
    separate entity-table for clients. It is connected to the person entity 
    by a generalization/specialization relationship */
create table customer(
    person_id INT,
    special_requests VARCHAR2(512),

    CONSTRAINT FK_customer_person FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE CASCADE,
    CONSTRAINT PK_customer PRIMARY KEY (person_id)
);

create table room(
    room_number INT,
    class VARCHAR2(8),
    bed_capacity INT CHECK(bed_capacity > 0 AND bed_capacity < 6),
    price DECIMAL(10, 2),
    air_conditioner NUMBER(1),
    smoke NUMBER(1),
    pets NUMBER(1),
    window_view VARCHAR2(32),

    CONSTRAINT check_class CHECK (class IN ('STANDARD', 'LUXE')),
    CONSTRAINT window_view_check CHECK (window_view IN ('CITY', 'SEA', 'MOUNTAIN', 'FOREST', 'OTHER')),
    CONSTRAINT PK_room PRIMARY KEY (room_number)
);

create table reservation(
    reservation_id INT,
    room_number INT,
    customer_id INT NOT NULL,
    "FROM" DATE NOT NULL,
    expected_arrival_time TIMESTAMP,
    until DATE NOT NULL,
    status VARCHAR2(16) NOT NULL,

    CONSTRAINT PK_reservation PRIMARY KEY (reservation_id),
    CONSTRAINT status_check CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'CHECKED_IN', 'CHECKED_OUT')),
    CONSTRAINT FK_reservation_room FOREIGN KEY (room_number) REFERENCES room (room_number) ON DELETE SET NULL,
    CONSTRAINT FK_reservation_customer FOREIGN KEY (customer_id) REFERENCES customer (person_id) ON DELETE CASCADE
);

create table action(
    action_id INT,
    front_desk_employee_id INT NOT NULL,
    reservation_id INT NOT NULL,
    date_time TIMESTAMP NOT NULL,
    action_type VARCHAR2(32) NOT NULL,
    description VARCHAR2(512),

    CONSTRAINT PK_action PRIMARY KEY (action_id),
    CONSTRAINT action_type_check CHECK (action_type IN ('CONFIRM_RES', 'ADD_GUEST', 'CHECK_IN', 'CHECK_OUT', 'ROOM_CHANGE', 'DATE_CHANGE', 'ENTER_ARRIVAL_TIME', 'OTHER')),
    CONSTRAINT FK_action_fd_employee FOREIGN KEY (front_desk_employee_id) REFERENCES front_desk_employee (person_id) ON DELETE SET NULL,
    CONSTRAINT FK_action_reservation FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id) ON DELETE CASCADE
);

/* more to more relationship */
create table reservation_customer_live(
    reservation_id INT,
    customer_id INT,

    CONSTRAINT FK_rcl_reservation FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT FK_rcl_customer FOREIGN KEY (customer_id) REFERENCES customer (person_id) ON DELETE CASCADE,
    CONSTRAINT PK_rcl PRIMARY KEY (reservation_id, customer_id)
);

create table service(
    service_id INT,
    name VARCHAR2(64) NOT NULL,
    service_type VARCHAR2(32) NOT NULL,
    description VARCHAR2(512),

    CONSTRAINT check_service_type CHECK (service_type IN ('HEALTH', 'RESTAURANT', 'ENTERTAINMENT', 'FITNESS', 'SHOP', 'OTHER')),
    CONSTRAINT PK_service PRIMARY KEY (service_id)
);

/* A new entity has been added to our solution (2nd part). Previously (in the 1st part of the project) 
    in the entity service we had an attribute schedule, which is difficult to represent 
    without separate entity, thats why we added new entity term. Now service has many terms
    and service request connected directly with term, not with service */
create table term(
    term_id INT,
    service_id INT,
    week_day VARCHAR2(16) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    price DECIMAL(10, 2) CHECK(price > 0),

    CONSTRAINT week_day_check CHECK (week_day IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
    CONSTRAINT FK_term_service FOREIGN KEY (service_id) REFERENCES service (service_id) ON DELETE CASCADE,
    CONSTRAINT PK_term PRIMARY KEY (term_id, service_id)
);

create table payment(
    payment_id INT,
    reservation_id INT,
    amount DECIMAL(10, 2) NOT NULL,
    amount_with_discount DECIMAL(10, 2) NOT NULL,
    date_time TIMESTAMP NOT NULL,
    discount DECIMAL(4, 2) CHECK(discount >= 0 AND discount <= 100) NOT NULL,
    payment_method VARCHAR2(16) NOT NULL,

    CONSTRAINT payment_method_check CHECK (payment_method IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'OTHER')),
    CONSTRAINT FK_payment_reservation FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT PK_payment PRIMARY KEY (payment_id, reservation_id)
);

create table service_request(
    service_request_id INT,
    reservation_id INT NOT NULL,
    term_id INT NOT NULL,
    service_id INT NOT NULL,
    payment_id INT NOT NULL,
    fd_employee_creator_id INT,
    date_time TIMESTAMP NOT NULL,
    description VARCHAR2(512),

    CONSTRAINT FK_service_request_customer FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT FK_service_request_payment FOREIGN KEY (payment_id, reservation_id) REFERENCES payment (payment_id, reservation_id) ON DELETE SET NULL,
    CONSTRAINT FK_service_request_service FOREIGN KEY (term_id, service_id) REFERENCES term (term_id, service_id) ON DELETE SET NULL,
    CONSTRAINT FK_service_request_fd_employee_creator FOREIGN KEY (fd_employee_creator_id) REFERENCES front_desk_employee (person_id) ON DELETE SET NULL,
    CONSTRAINT PK_service_request PRIMARY KEY (service_request_id, reservation_id)
);

/* more to more relationship */
create table service_request_service_employee_perform(
    service_request_id INT,
    service_employee_id INT,
    reservation_id INT,

    CONSTRAINT FK_srsesp_service_request FOREIGN KEY (service_request_id, reservation_id) REFERENCES service_request (service_request_id, reservation_id) ON DELETE CASCADE,
    CONSTRAINT FK_srsesp_service_employee FOREIGN KEY (service_employee_id) REFERENCES service_employee (person_id) ON DELETE CASCADE,
    CONSTRAINT PK_srsesp PRIMARY KEY (service_request_id, reservation_id, service_employee_id)
);

/* Trigger generation id for action table */
CREATE OR REPLACE TRIGGER trg_before_insert_action
BEFORE INSERT ON action
FOR EACH ROW
BEGIN
    SELECT action_seq.nextval INTO :NEW.action_id FROM dual;
END;
/

/* Moq data */
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality) 
VALUES (person_seq.nextval, 'Jiri', 'Rohlik', TO_DATE('01-01-1990', 'DD-MM-YYYY'), 'M', '112233445566', '+420-123456789', 'jirirohlik1990@seznam.cz', 'CZ');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality) 
VALUES (person_seq.nextval, 'Vaclav', 'Kubicek', TO_DATE('10-12-1995', 'DD-MM-YYYY'), 'M', '998877665544', '+420-987654321', 'jirirohlik1990@seznam.cz', 'CZ');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality) 
VALUES (person_seq.nextval, 'Maria', 'Garcia', TO_DATE('10-05-1985', 'DD-MM-YYYY'), 'F', '9988738665544', '+34-123456789', 'mariagarcia85@example.com', 'ES');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality) 
VALUES (person_seq.nextval, 'Hiroshi', 'Tanaka', TO_DATE('20-09-1982', 'DD-MM-YYYY'), 'M', '776655443322', '+81-123456789', 'hiroshitanaka82@example.com', 'JP');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality) 
VALUES (person_seq.nextval, 'Sophie', 'Dubois', TO_DATE('05-07-1995', 'DD-MM-YYYY'), 'F', '554433221100', '+33-123456789', 'sophiedubois95@example.com', 'FR');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality)
VALUES (person_seq.nextval, 'Sven', 'Andersen', TO_DATE('15-03-1988', 'DD-MM-YYYY'), 'M', '443322110088', '+47-123456789', 'svenandersen88@example.com', 'NO');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality)
VALUES (person_seq.nextval, 'Kirill', 'Kurakov', TO_DATE('08-08-2003', 'DD-MM-YYYY'), 'M', '56743256345', '+7-9053642028', 'kirillkurakov03@example.com', 'RU');
INSERT INTO person (person_id, first_name, last_name, birth_date, sex, id_card_number, telephone, email, nationality)
VALUES (person_seq.nextval, 'Alexandr', 'Tihanschi', TO_DATE('30-09-2003', 'DD-MM-YYYY'), 'M', '12345126789', '+420-213456789', 'alexandertihanschi03@example.com', 'MD');

INSERT INTO front_desk_employee (person_id, "RANK") 
VALUES (1, 'JUNIOR');
INSERT INTO front_desk_employee (person_id, "RANK")
VALUES (2, 'SENIOR');

INSERT INTO service_employee (person_id, specialization)
VALUES (3, 'RESTAURANT');
INSERT INTO service_employee (person_id, specialization)
VALUES (4, 'HOUSEKEEPING');
INSERT INTO service_employee (person_id, specialization)
VALUES (8, 'FITNESS');

INSERT INTO customer (person_id, special_requests)
VALUES (5, 'I would like to have a room with a sea view.');
INSERT INTO customer (person_id, special_requests)
VALUES (6, 'I would like to have a room with a mountain view.');
INSERT INTO customer (person_id, special_requests)
VALUES (7, 'I would like to have a room with a forest view and i would like to have a dinner once.');

INSERT INTO room (room_number, class, bed_capacity, price, air_conditioner, smoke, pets, window_view)
VALUES (room_seq.nextval, 'STANDARD', 2, 1000.00, 1, 0, 0, 'CITY');
INSERT INTO room (room_number, class, bed_capacity, price, air_conditioner, smoke, pets, window_view)
VALUES (room_seq.nextval, 'LUXE', 4, 2000.00, 1, 0, 1, 'SEA');

INSERT INTO reservation (reservation_id, room_number, customer_id, "FROM", expected_arrival_time, until, status)
VALUES (reservation_seq.nextval, 101, 5, TO_DATE('01-06-2024', 'DD-MM-YYYY'), TO_TIMESTAMP('01-06-2024 14:00', 'DD-MM-YYYY HH24:MI'), TO_DATE('10-06-2024', 'DD-MM-YYYY'), 'CONFIRMED');
INSERT INTO reservation (reservation_id, room_number, customer_id, "FROM", expected_arrival_time, until, status)
VALUES (reservation_seq.nextval, 100, 7, TO_DATE('23-04-2024', 'DD-MM-YYYY'), TO_TIMESTAMP('10-05-2024 16:30', 'DD-MM-YYYY HH24:MI'), TO_DATE('07-05-2024', 'DD-MM-YYYY'), 'CHECKED_IN');
INSERT INTO reservation (reservation_id, room_number, customer_id, "FROM", expected_arrival_time, until, status)
VALUES (reservation_seq.nextval, 101, 7, TO_DATE('11-06-2024', 'DD-MM-YYYY'), NULL, TO_DATE('15-06-2024', 'DD-MM-YYYY'), 'CONFIRMED');

INSERT INTO reservation_customer_live (reservation_id, customer_id)
VALUES (1, 5);
INSERT INTO reservation_customer_live (reservation_id, customer_id)
VALUES (1, 6);
INSERT INTO reservation_customer_live (reservation_id, customer_id)
VALUES (2, 7);
INSERT INTO reservation_customer_live (reservation_id, customer_id)
VALUES (2, 5);
INSERT INTO reservation_customer_live (reservation_id, customer_id)
VALUES (3, 7);

INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 2, 1, TO_TIMESTAMP('22-03-2024 13:50', 'DD-MM-YYYY HH24:MI'), 'CONFIRM_RES', 'The customer made a new reservation.');
INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 2, 1, TO_TIMESTAMP('22-03-2024 14:00', 'DD-MM-YYYY HH24:MI'), 'ROOM_CHANGE', 'The customer has changed room to 101.');
INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 1, 1, TO_TIMESTAMP('22-03-2024 14:10', 'DD-MM-YYYY HH24:MI'), 'ENTER_ARRIVAL_TIME', 'The customer has entered the expected arrival time 14:00.');
INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 2, 2, TO_TIMESTAMP('23-03-2024 14:50', 'DD-MM-YYYY HH24:MI'), 'CONFIRM_RES', 'The customer made a new reservation.');
INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 2, 2, TO_TIMESTAMP('23-03-2024 15:00', 'DD-MM-YYYY HH24:MI'), 'ENTER_ARRIVAL_TIME', 'The customer has entered the expected arrival time 16:30.');
INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 2, 2, TO_TIMESTAMP('23-04-2024 16:35', 'DD-MM-YYYY HH24:MI'), 'CHECK_IN', 'The customer has checked in.');
INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
VALUES (NULL, 1, 3, TO_TIMESTAMP('23-04-2024 16:40', 'DD-MM-YYYY HH24:MI'), 'CONFIRM_RES', 'The customer made a new reservation.');

INSERT INTO service (service_id, name, service_type, description)
VALUES (service_seq.nextval, 'Breakfast', 'RESTAURANT', 'Breakfast in the hotel restaurant.');
INSERT INTO service (service_id, name, service_type, description)
VALUES (service_seq.nextval, 'Dinner', 'RESTAURANT', 'Dinner in the hotel restaurant.');
INSERT INTO service (service_id, name, service_type, description)
VALUES (service_seq.nextval, 'Gym', 'FITNESS', 'Access to the hotel gym.');

INSERT INTO term (term_id, service_id, week_day, start_time, end_time, price)
VALUES (term_seq.nextval, 1, 'MONDAY', TO_TIMESTAMP('02-06-2024 08:00', 'DD-MM-YYYY HH24:MI'), TO_TIMESTAMP('02-06-2024 10:00', 'DD-MM-YYYY HH24:MI'), 10.00);
INSERT INTO term (term_id, service_id, week_day, start_time, end_time, price)
VALUES (term_seq.nextval, 1, 'TUESDAY', TO_TIMESTAMP('03-06-2024 08:00', 'DD-MM-YYYY HH24:MI'), TO_TIMESTAMP('03-06-2024 10:00', 'DD-MM-YYYY HH24:MI'), 10.00);
INSERT INTO term (term_id, service_id, week_day, start_time, end_time, price)
VALUES (term_seq.nextval, 2, 'MONDAY', TO_TIMESTAMP('02-06-2024 18:00', 'DD-MM-YYYY HH24:MI'), TO_TIMESTAMP('02-06-2024 20:00', 'DD-MM-YYYY HH24:MI'), 20.00);
INSERT INTO term (term_id, service_id, week_day, start_time, end_time, price)
VALUES (term_seq.nextval, 2, 'TUESDAY', TO_TIMESTAMP('03-06-2024 18:00', 'DD-MM-YYYY HH24:MI'), TO_TIMESTAMP('03-06-2024 20:00', 'DD-MM-YYYY HH24:MI'), 20.00);
INSERT INTO term (term_id, service_id, week_day, start_time, end_time, price)
VALUES (term_seq.nextval, 3, 'WEDNESDAY', TO_TIMESTAMP('04-06-2024 10:00', 'DD-MM-YYYY HH24:MI'), TO_TIMESTAMP('04-06-2024 12:00', 'DD-MM-YYYY HH24:MI'), 5.00);

INSERT INTO payment (payment_id, reservation_id, amount, amount_with_discount, date_time, discount, payment_method)
VALUES (payment_seq.nextval, 1, 1000.00, 1000.00, TO_TIMESTAMP('22-03-2024 14:00', 'DD-MM-YYYY HH24:MI'), 0, 'CREDIT_CARD');
INSERT INTO payment (payment_id, reservation_id, amount, amount_with_discount, date_time, discount, payment_method)
VALUES (payment_seq.nextval, 1, 20.00, 20.00, TO_TIMESTAMP('22-03-2024 14:00', 'DD-MM-YYYY HH24:MI'), 0, 'CREDIT_CARD');
INSERT INTO payment (payment_id, reservation_id, amount, amount_with_discount, date_time, discount, payment_method)
VALUES (payment_seq.nextval, 1, 5.00, 5.00, TO_TIMESTAMP('23-03-2024 14:30', 'DD-MM-YYYY HH24:MI'), 0, 'CREDIT_CARD');


INSERT INTO service_request (service_request_id, reservation_id, term_id, service_id, payment_id, fd_employee_creator_id, date_time, description)
VALUES (service_request_seq.nextval, 1, 1, 1, 2, 2, TO_TIMESTAMP('22-03-2024 14:00', 'DD-MM-YYYY HH24:MI'), 'I would like to order breakfast.');
INSERT INTO service_request_service_employee_perform (service_request_id, service_employee_id, reservation_id)
VALUES (1, 3, 1);
INSERT INTO service_request (service_request_id, reservation_id, term_id, service_id, payment_id, fd_employee_creator_id, date_time, description)
VALUES (service_request_seq.nextval, 1, 1, 1, 2, 2, TO_TIMESTAMP('22-03-2024 14:00', 'DD-MM-YYYY HH24:MI'), 'I would like to order breakfast.');
INSERT INTO service_request_service_employee_perform (service_request_id, service_employee_id, reservation_id)
VALUES (2, 3, 1);
INSERT INTO service_request (service_request_id, reservation_id, term_id, service_id, payment_id, fd_employee_creator_id, date_time, description)
VALUES (service_request_seq.nextval, 1, 5, 3, 3, 2, TO_TIMESTAMP('22-03-2024 14:00', 'DD-MM-YYYY HH24:MI'), 'I would like to visit gym.');
INSERT INTO service_request_service_employee_perform (service_request_id, service_employee_id, reservation_id)
VALUES (3, 8, 1);

------------------------------------------------------------------- SELECTS -------------------------------------------------------------------

/* Writes out all reservations and wishes of guests who have already checked in.
    It's helpful if we want to know our guests' preferences */
SELECT P.person_id, P.first_name, P.last_name, R.reservation_id, R."FROM", R.until, R.status, C.special_requests
FROM person P
INNER JOIN customer C ON P.person_id = C.person_id
INNER JOIN reservation_customer_live L ON C.person_id = L.customer_id
INNER JOIN reservation R ON L.reservation_id = R.reservation_id
WHERE R.status = 'CHECKED_IN'
ORDER BY person_id;

/* Write out all currently occupied and reserved for future rooms and reservations.
    Important information for monitoring available rooms */
SELECT room.room_number, R."FROM", R.until
FROM reservation R
INNER JOIN room ON room.room_number = R.room_number
WHERE (R.until > SYSTIMESTAMP) AND (R.status = 'CHECKED_IN' OR R.status = 'CONFIRMED')
ORDER BY room_number, R."FROM";

/* Writes out all payment details for every term (may shows a single transaction with a number of identical service terms) and reservation (with no serv. term information) for bank records.
    Useful in accounting or when writing a check. */
SELECT P.payment_id, P.amount, P.date_time, P.discount, P.payment_method, R.reservation_id, T.week_day, T.start_time, T.price, service.name, COUNT(S.service_request_id) AS number_of_requests
FROM payment P
INNER JOIN reservation R ON P.reservation_id = R.reservation_id
LEFT JOIN (service_request S
INNER JOIN term T ON S.term_id = T.term_id
INNER JOIN service ON T.service_id = service.service_id) ON P.payment_id = S.payment_id
WHERE P.date_time BETWEEN :start_date AND :end_date
GROUP BY P.payment_id, P.amount, P.date_time, P.discount, P.payment_method, R.reservation_id, T.week_day, T.start_time, T.price, service.name
ORDER BY P.date_time, P.payment_id;

/* Returns the number of employees of the given specialization.
    Useful information for understanding how many employees work in which specializations */
SELECT specialization, COUNT(*)
FROM service_employee E
GROUP BY E.specialization;

/* Returns how much guests pay on average for every calendar day when we had customers.
    Statistical information */
SELECT TRUNC(date_time), AVG(amount) AS amount
FROM (SELECT person_id, date_time, SUM(amount_with_discount) AS amount
    FROM payment P
    INNER JOIN reservation R ON P.reservation_id = R.reservation_id
    INNER JOIN customer C ON R.customer_id = C.person_id
    GROUP BY person_id, date_time)
GROUP BY TRUNC(date_time);

/* Returns all guest reservations or false if it is a new guest. 
    When a new guest arrives, it is necessary to check if they are already in our system. */
SELECT *
FROM reservation
WHERE EXISTS (
    SELECT 1
    FROM customer
    INNER JOIN person ON customer.person_id = person.person_id
    WHERE person.id_card_number = :id_card_number
    AND reservation.customer_id = customer.person_id
)

/* Returns all requests to the service where is the service with the specified name.
    Information about all orders for choosen service */
SELECT *
FROM service_request S
NATURAL JOIN term T
WHERE service_id IN (
    SELECT service_id
    FROM service
    WHERE name = :service_name
);


------------------------------------------------------------------- TRIGGERS -------------------------------------------------------------------

/* Trigger adds a new record in the table Action based on changes to the data in the table reservation
    We simulate the work of an employee, when he works, it is necessary that the information about the 
    changes he made be loaded into the table Action. He can change, for example, the status or the date of arrival.
    When we execute add this trigger we ned to write front desk employee id*/
CREATE OR REPLACE TRIGGER new_action_record
AFTER UPDATE OF status, room_number, expected_arrival_time, until, "FROM" ON reservation
FOR EACH ROW
DECLARE
    v_front_desk_employee_id VARCHAR2(50);
    v_action_type VARCHAR2(32);
    v_description VARCHAR2(512);
BEGIN 
    SELECT person_id INTO v_front_desk_employee_id
    FROM front_desk_employee
    WHERE person_id = &front_desk_employee_id;

    IF :OLD.room_number != :NEW.room_number THEN
        v_action_type := 'ROOM_CHANGE';
        v_description := 'The room has been changed to ' || :NEW.room_number || '.';
    ELSIF :NEW.status = 'CONFIRMED' THEN
        v_action_type := 'CONFIRM_RES';
        v_description := 'The reservation has been confirmed.';
    ELSIF :NEW.status = 'CHECKED_IN' THEN
        v_action_type := 'CHECK_IN';
        v_description := 'The customer has checked in.';
    ELSIF :NEW.status = 'CHECKED_OUT' THEN
        v_action_type := 'CHECK_OUT';
        v_description := 'The customer has checked out.';
    ELSIF :NEW.expected_arrival_time != :OLD.expected_arrival_time THEN
        v_action_type := 'ENTER_ARRIVAL_TIME';
        v_description := 'The customer has entered the expected arrival time ' || :NEW.expected_arrival_time || '.';
    ELSIF :NEW.until <> :OLD.until THEN
        v_action_type := 'DATE_CHANGE';
        v_description := 'The reservation date has been changed.';
    ELSIF :NEW."FROM" <> :OLD."FROM" THEN
        v_action_type := 'DATE_CHANGE';
        v_description := 'The reservation date has been changed.';
    ELSE 
        v_action_type := 'OTHER';
        v_description := 'The reservation has been updated.';
    END IF;

    INSERT INTO action (action_id, front_desk_employee_id, reservation_id, date_time, action_type, description)
    VALUES (NULL, v_front_desk_employee_id, :OLD.reservation_id, SYSTIMESTAMP, v_action_type, v_description);
END;
/

/* After this update trigger will create new row in Action table with Action type CHECK IN*/
UPDATE reservation SET status = 'CHECKED_IN' WHERE reservation_id = 1;

/* This trigger automatically count price with discount if we add a discount to the payment */
CREATE OR REPLACE TRIGGER calculate_new_discount_with_amount
BEFORE INSERT OR UPDATE OF discount ON PAYMENT
FOR EACH ROW
BEGIN
    :NEW.amount_with_discount := :NEW.amount - (:NEW.amount * (:NEW.discount / 100));
END;
/

/* Adding discount to the payment */
UPDATE payment SET discount = 10 WHERE payment_id = 1;


------------------------------------------------------------------- PROCEDURE -------------------------------------------------------------------

/* Procedure recalculates the price of all rooms by a given percentage 
   Prices may go up or down depending on the percentage
   Procedure also print the old price and the new price for each room */
CREATE OR REPLACE PROCEDURE recalc_room_prices(percent IN DECIMAL) IS
    CURSOR room_cursor IS SELECT * FROM room;
    cur_room room%ROWTYPE;
    v_new_price DECIMAL(10, 2);
    BEGIN
        OPEN room_cursor;
        LOOP
            FETCH room_cursor INTO cur_room;
            EXIT WHEN room_cursor%NOTFOUND;

            v_new_price := cur_room.price + (cur_room.price * percent / 100);

            UPDATE room
            SET price = v_new_price
            WHERE room_number = cur_room.room_number;
            dbms_output.put_line('Room number ' || cur_room.room_number || ' old price - ' || cur_room.price || ' new price - ' || v_new_price);
        END LOOP;
        CLOSE room_cursor;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('No rooms found');
    WHEN OTHERS THEN
        dbms_output.put_line('An error occured.');
END; 
/

/* Procedure execute */
BEGIN
    recalc_room_prices(10.00);
END;

/* Procedure writes out all how much customer spent in every payment and total amount for all time*/
CREATE OR REPLACE PROCEDURE calc_all_customer_payments(customer_first_name IN person.first_name%TYPE, customer_last_name in person.last_name%TYPE) AS
    CURSOR payment_cursor IS
        SELECT P.amount_with_discount, P.payment_method, P.date_time
        FROM person P
        INNER JOIN customer C on P.person_id = C.person_id
        INNER JOIN reservation R on C.person_id = R.customer_id
        INNER JOIN payment P on R.reservation_id = P.reservation_id
        WHERE P.first_name = customer_first_name AND P.last_name = customer_last_name;
    v_final_amount DECIMAL(10, 2);
    cur_payment payment_cursor%ROWTYPE;
    BEGIN
        OPEN payment_cursor;
        v_final_amount := 0;
        dbms_output.put_line('Customer ' || customer_first_name || ' ' || customer_last_name);
        LOOP
            FETCH payment_cursor INTO cur_payment;
            EXIT WHEN payment_cursor%NOTFOUND;
            v_final_amount := v_final_amount + cur_payment.amount_with_discount;
            IF cur_payment.amount_with_discount IS NOT NULL THEN
                dbms_output.put_line('Payment ' || cur_payment.amount_with_discount || ' ' || cur_payment.date_time);
            END IF;
        END LOOP;
        dbms_output.put_line('Customer total spend ' || v_final_amount);
        CLOSE payment_cursor;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('No rooms found');
WHEN OTHERS THEN
    dbms_output.put_line('An error occured.');
END;
/

/* Procedure execute */
BEGIN
    calc_all_customer_payments('Sophie', 'Dubois');
END;


------------------------------------------------------------------- Index and Explain Plan -------------------------------------------------------------------

DROP INDEX service_name_index;

/* Expain plan for select how many terms exists for every service*/
EXPLAIN PLAN FOR
SELECT S.name, count(T.term_id) AS terms_count
FROM service S
INNER JOIN term T ON T.service_id = S.service_id
GROUP BY S.name;

SELECT * FROM TABLE(dbms_xplan.display());

CREATE INDEX service_name_index ON service (service_id, name);

/* The same select that optimalized by index */
EXPLAIN PLAN FOR
SELECT S.name, count(T.term_id) AS terms_count
FROM service S
INNER JOIN term T ON T.service_id = S.service_id
GROUP BY S.name;

SELECT * FROM TABLE(dbms_xplan.display());

    
------------------------------------------------------------------- Access rights for xtihan00 -------------------------------------------------------------------

GRANT ALL ON person TO xtihan00;
GRANT ALL ON front_desk_employee TO xtihan00;
GRANT ALL ON service_employee TO xtihan00;
GRANT ALL ON customer TO xtihan00;
GRANT ALL ON room TO xtihan00;
GRANT ALL ON reservation TO xtihan00;
GRANT ALL ON action TO xtihan00;
GRANT ALL ON reservation_customer_live TO xtihan00;
GRANT ALL ON service TO xtihan00;
GRANT ALL ON term TO xtihan00;
GRANT ALL ON payment TO xtihan00;
GRANT ALL ON service_request TO xtihan00;
GRANT ALL ON service_request_service_employee_perform TO xtihan00;

GRANT EXECUTE ON recalc_room_prices TO xtihan00;
GRANT EXECUTE ON calc_all_customer_payments TO xtihan00;

------------------------------------------------------------------- Materialised view -------------------------------------------------------------------

DROP MATERIALIZED VIEW reservation_log;

DROP MATERIALIZED VIEW LOG ON reservation;

/* Materialized view log helps to refresh materialized view very fast because 
    This allows it to update only the relevant rows in the materialized view, 
    rather than recalculating it completely. */
CREATE MATERIALIZED VIEW LOG ON reservation WITH PRIMARY KEY, ROWID INCLUDING NEW VALUES;

/* Materialized view that contains all reservations with status CHECKED_IN and CONFIRMED */
CREATE MATERIALIZED VIEW reservation_log
    CACHE
    BUILD IMMEDIATE
    REFRESH FAST ON COMMIT
    AS SELECT R.reservation_id, R.room_number, R.customer_id, R."FROM", R.expected_arrival_time, R.until, R.status
    FROM reservation R
    WHERE R.status = 'CHECKED_IN' OR R.status = 'CONFIRMED';

/* Grant access to the materialized view for second team member*/
GRANT ALL ON reservation_log TO xtihan00; 

SELECT * FROM reservation_log;

INSERT INTO reservation (reservation_id, room_number, customer_id, "FROM", expected_arrival_time, until, status)
VALUES (reservation_seq.nextval, 100, 5, TO_DATE('06-05-2077', 'DD-MM-YYYY'), TO_TIMESTAMP('06-05-2077 14:00', 'DD-MM-YYYY HH24:MI'), TO_DATE('06-05-2077', 'DD-MM-YYYY'), 'CONFIRMED');
COMMIT;

/* Materialized view has updated */
SELECT * FROM reservation_log;


------------------------------------------------------------------- SELECT WITH CASE -------------------------------------------------------------------

/* In this sql query we get table with working hours for every fitness trainer in out hotel at the specified week day, than in the next 
    "with" table we use previous and calculate average work hours on this day and than we compare every trainer work hours with average
    and write out if it is higher, lower or equal to average. So you  can find out which trainers underworked and which are overworked */
WITH workload_table(first_name, last_name, work_hours) AS
    (SELECT P.first_name, P.last_name, COUNT(R.service_request_id)
    FROM person P
    INNER JOIN service_employee SE ON P.person_id = SE.person_id
    INNER JOIN service_request_service_employee_perform SRSE ON SE.person_id = SRSE.service_employee_id
    INNER JOIN service_request R ON SRSE.service_request_id = R.service_request_id
    INNER JOIN term ON R.term_id = term.term_id
    INNER JOIN service ON term.service_id = service.service_id
    WHERE service.service_type = 'FITNESS' AND term.week_day = :week_day
    GROUP BY P.first_name, P.last_name),
    avg_workload(avg_workload_hours) AS
    (SELECT avg(work_hours) AS avg_workload FROM workload_table)
SELECT 
    first_name, 
    last_name, 
    work_hours,
    avg_workload_hours,
    CASE
        WHEN work_hours > avg_workload_hours THEN 'Workload is higher than average'
        WHEN work_hours = avg_workload_hours THEN 'Workload is average'
        ELSE 'Workload is lower than average'
    END AS workload
    FROM workload_table, avg_workload;




