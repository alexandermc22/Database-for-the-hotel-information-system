# Project Overview: Database Management System for Hotel Operations

## Introduction:
This project aims to develop a comprehensive database management system tailored for hotel operations. Leveraging SQL (Structured Query Language), it manages various aspects of hotel functionalities such as reservations, guest preferences, employee management, financial transactions, and service requests. The system enhances operational efficiency, streamlines data management, and provides valuable insights for informed decision-making within the hospitality industry.

## Features Implemented:

Reservation Management:

- Tracks reservations from booking to checkout, including guest preferences and special requests.
- Differentiates between checked-in, confirmed, and checked-out reservations.
- Provides real-time updates on room status and availability.

Employee Management:

- Manages both front desk and service employees, including their specializations and work schedules.
- Tracks employee actions such as room changes, check-ins, and check-outs through triggers.

Financial Transactions:

- Records all payment details, including amounts, discounts, payment methods, and transaction dates.
- Calculates discounts automatically before inserting or updating payment records.

Data Analysis and Reporting:

- Generates statistical insights such as average daily spending per guest and workload analysis for fitness trainers.
- Utilizes SQL queries with CASE statements for comparative analysis.

Access Rights Management:

- Assigns appropriate access rights to users for different database entities.
- Ensures data security and privacy by limiting access based on roles.

Materialized View:

- Maintains a materialized view of reservations with statuses 'CHECKED_IN' and 'CONFIRMED' for faster access and reporting.
- Utilizes materialized view logs for efficient refresh during commits.