-- ============================================================================
-- SQL PRACTICE PLAYBOOK FOR 3 YEARS EXP JAVA / SPRING BOOT / MICROSERVICES DEVELOPER
-- ============================================================================
-- Target Database : PostgreSQL 12+
-- Usage:
--   1. Open in psql, pgAdmin, DBeaver, or IntelliJ Database Tool.
--   2. Run Part 1 & Part 2 to create schema and populate rich test data.
--   3. Solve Part 3 queries. Each question includes real-world microservice context,
--      difficulty rating, optimal solution, and architectural explanations.
-- ============================================================================

-- ============================================================================
-- PART 0: IN-DEPTH THEORY, ENGINE MECHANICS & ARCHITECTURAL CHEATSHEET
-- ============================================================================
-- This theoretical foundation explains the "WHY" and "HOW" behind every advanced
-- SQL query below, specifically mapped to Java / Spring Boot Microservices.
--
-- ----------------------------------------------------------------------------
-- 1. SQL LOGICAL QUERY PROCESSING ORDER (THE ENGINE'S ORDER OF OPERATIONS)
-- ----------------------------------------------------------------------------
-- Unlike Java code which executes top-to-bottom, SQL is declarative.
-- The PostgreSQL Query Engine processes clauses in this EXACT sequence:
--
--   Step 1 : FROM               -> Resolves base tables & cross-joins
--   Step 2 : ON                 -> Evaluates join conditions
--   Step 3 : JOIN               -> Applies join type (INNER, LEFT, RIGHT, FULL)
--   Step 4 : WHERE              -> Filters individual rows BEFORE grouping
--   Step 5 : GROUP BY           -> Collapses rows into distinct aggregate buckets
--   Step 6 : HAVING             -> Filters aggregated groups (AFTER GROUP BY)
--   Step 7 : WINDOW             -> Calculates Window Functions (OVER ...)
--   Step 8 : SELECT             -> Projects requested columns and scalar expressions
--   Step 9 : DISTINCT           -> Eliminates duplicate projected rows
--   Step 10: UNION/EXCEPT       -> Applies set operations
--   Step 11: ORDER BY           -> Sorts the final output rows
--   Step 12: LIMIT / OFFSET     -> Restricts pagination slice returned to client
--
-- KEY INTERVIEW INSIGHTS FOR 3 YOE:
-- * Why can't you use a column alias defined in SELECT inside the WHERE clause?
--   Because Step 4 (WHERE) executes BEFORE Step 8 (SELECT). The alias does not exist yet!
-- * Why can't you use Window Functions inside WHERE or HAVING?
--   Because Step 7 (WINDOW) executes AFTER Step 4 (WHERE) and Step 6 (HAVING).
--   To filter on a window function result, you MUST wrap it in a CTE or Subquery.
--
-- ----------------------------------------------------------------------------
-- 2. WINDOW FUNCTIONS ANATOMY & INTERNAL MECHANICS
-- ----------------------------------------------------------------------------
-- Concept: What is the fundamental difference between GROUP BY and WINDOW functions?
--   - GROUP BY collapses N rows into 1 summary row per bucket.
--   - WINDOW functions calculate aggregates/rankings across a set of rows (a 'window'),
--     but RETAIN EVERY SINGLE INDIVIDUAL ROW in the output!
--
-- Syntax Anatomy:
--   <function>() OVER (
--       PARTITION BY <columns>   -- Divides rows into groups (optional)
--       ORDER BY <columns>       -- Determines evaluation sequence in window (optional)
--       ROWS/RANGE <frame_spec>  -- Boundaries of calculation within partition
--   )
--
-- The Three Ranking Siblings (Crucial Interview Topic):
--   Assume salaries: [100k, 90k, 90k, 80k]
--   +----------+------------+--------+------------+
--   | Salary   | ROW_NUMBER | RANK   | DENSE_RANK |
--   +----------+------------+--------+------------+
--   | 100,000  | 1          | 1      | 1          |
--   |  90,000  | 2          | 2      | 2          | (Tied)
--   |  90,000  | 3          | 2      | 2          | (Tied)
--   |  80,000  | 4          | 4      | 3          | (Notice: RANK skipped 3; DENSE didn't!)
--   +----------+------------+--------+------------+
--   - Use ROW_NUMBER() when you need unique sequential identifiers (e.g. deduplication).
--   - Use DENSE_RANK() when calculating N-th highest values (e.g. 2nd highest salary).
--   - Use RANK() when sports/academic ranking where ties share a rank and skip spots.
--
-- Window Framing Mechanics (ROWS BETWEEN ...):
--   Default framing when ORDER BY is present:
--     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--   CAUTION: RANGE considers rows with identical ORDER BY values as peers and computes
--   aggregates over all peers simultaneously! For running sums on duplicate values,
--   always explicitly specify:
--     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--
-- ----------------------------------------------------------------------------
-- 3. THREE-VALUED LOGIC & THE NOT IN (NULL) TRAP (ANTI-JOINS)
-- ----------------------------------------------------------------------------
-- SQL uses Ternary (3-valued) Logic: TRUE, FALSE, and UNKNOWN (NULL).
--
-- Why NOT IN fails silently in production:
--   Query: SELECT * FROM customers WHERE customer_id NOT IN (SELECT customer_id FROM orders);
--   If orders has even ONE row where customer_id IS NULL:
--   The condition expands to:
--     customer_id != 201 AND customer_id != 202 AND customer_id != NULL
--   In SQL:
--     (anything != NULL) evaluates to UNKNOWN!
--     TRUE AND TRUE AND UNKNOWN evaluates to UNKNOWN!
--   The WHERE clause only returns rows where condition evaluates to TRUE.
--   Result: ZERO ROWS RETURNED! A devastating silent bug in production.
--
-- THE REMEDY (Always use NOT EXISTS or LEFT JOIN ... WHERE NULL):
--   NOT EXISTS uses two-valued boolean check. If the subquery finds a row, it returns
--   TRUE, else FALSE. It short-circuits immediately and is completely immune to NULLs!
--
-- ----------------------------------------------------------------------------
-- 4. RECURSIVE COMMON TABLE EXPRESSIONS (CTEs)
-- ----------------------------------------------------------------------------
-- Used for Hierarchical & Graph data: Org charts, Bill-of-Materials, Category trees.
--
-- How the PostgreSQL Engine executes WITH RECURSIVE:
--   1. Evaluates the ANCHOR query (non-recursive query).
--   2. Inserts anchor rows into an internal Working Table and Intermediate Table.
--   3. While Working Table is NOT empty:
--      a. Evaluates the RECURSIVE query using the Working Table as input.
--      b. Replaces Working Table with newly produced rows.
--      c. Appends newly produced rows into the Intermediate Table.
--   4. When Working Table is empty, returns the Intermediate Table.
--
-- Spring Boot Mapping:
--   Avoids loading thousands of Java Entity objects in recursive parent-child
--   relationships into memory, preventing OutOfMemoryError (OOM) on large trees.
--
-- ----------------------------------------------------------------------------
-- 5. CONCURRENCY, LOCKING & MVCC (SPRING BOOT & MICROSERVICES)
-- ----------------------------------------------------------------------------
-- What is MVCC (Multi-Version Concurrency Control)?
--   In PostgreSQL: "Readers never block writers, and writers never block readers."
--   When a row is UPDATED:
--     - PostgreSQL does NOT overwrite in place.
--     - It creates a NEW version (tuple) of the row with an incremented xmin.
--     - The old tuple's xmax is set to the current transaction ID.
--     - Other concurrent readers still read the old tuple version snapshot!
--     - Dead tuples are cleaned up asynchronously by VACUUM / AUTOVACUUM.
--
-- Pessimistic vs Optimistic Locking:
--   * Pessimistic Locking:
--     - Query: SELECT ... FOR UPDATE;
--     - Engine acquires an exclusive row-level lock. Concurrent transactions
--       attempting to read with FOR UPDATE or modify this row will BLOCK until COMMIT/ROLLBACK.
--     - Spring Boot: @Lock(LockModeType.PESSIMISTIC_WRITE)
--     - Best for: Flash sales, stock reservation, high contention where conflicts are frequent.
--   * Optimistic Locking:
--     - No DB lock. Uses a version number or timestamp column.
--     - UPDATE products SET stock = stock - 1, version = version + 1 WHERE id = ? AND version = ?
--     - If 0 rows updated, throws OptimisticLockingFailureException in Spring.
--     - Best for: Low-contention web apps with long think times.
--   * Queue Processing Pattern (SKIP LOCKED):
--     - SELECT * FROM orders WHERE status = 'PENDING' LIMIT 1 FOR UPDATE SKIP LOCKED;
--     - Multiple microservice consumer pods can query concurrently without blocking
--       each other; each pod skips already-locked rows and immediately claims the next!
--
-- ----------------------------------------------------------------------------
-- 6. HIGH-PERFORMANCE PAGINATION: KEYSET (CURSOR) VS OFFSET
-- ----------------------------------------------------------------------------
-- Why OFFSET is an anti-pattern at scale:
--   SELECT * FROM orders ORDER BY order_id LIMIT 10 OFFSET 100000;
--   - PostgreSQL MUST scan the B-Tree index and fetch 100,010 rows from disk.
--   - It throws away the first 100,000 rows and returns only 10 rows.
--   - Cost: O(N) time and heavy disk buffer pool churn.
--
-- Keyset (Seek / Cursor-based) Pagination:
--   SELECT * FROM orders WHERE order_id > 100000 ORDER BY order_id ASC LIMIT 10;
--   - PostgreSQL performs a direct B-Tree index lookup to order_id = 100001.
--   - Cost: O(log N) constant time, regardless of whether you are on page 1 or page 10,000!
--   - Highly resilient to data drift (inserts/deletions do not cause duplicate items across pages).
--
-- ----------------------------------------------------------------------------
-- 7. SOLVING THE HIBERNATE / SPRING DATA JPA N+1 PROBLEM IN SQL
-- ----------------------------------------------------------------------------
-- What is the N+1 Problem?
--   1 query to fetch 100 Customers + 100 individual queries to fetch their Orders = 101 queries!
--   Causes massive network latency, connection pool starvation, and database CPU spikes.
--
-- SQL Solution:
--   Using JSON_AGG(JSON_BUILD_OBJECT(...)) lets PostgreSQL do the nested serialization
--   inside the C engine and return 1 single payload in 1 DB roundtrip!
--
-- ----------------------------------------------------------------------------
-- 8. INDEXING ARCHITECTURE & EXPLAIN ANALYZE
-- ----------------------------------------------------------------------------
-- * B-Tree Indexes: Default in PostgreSQL. Balanced tree where leaf nodes point to heap TIDs.
-- * Leftmost Prefix Rule (Composite Indexes):
--   Index on (status, order_date):
--   - Queries on (status) -> Index USED.
--   - Queries on (status, order_date) -> Index USED.
--   - Queries on (order_date alone) -> Index NOT USED! (Violates leftmost prefix).
-- * Index Column Order Rule:
--   Equality columns FIRST, Range / Inequality columns LAST.
--   Example: WHERE status = 'COMPLETED' AND order_date >= '2024-01-01'
--   Index: CREATE INDEX idx_orders_st_dt ON orders(status, order_date);
-- * Partial Indexes:
--   CREATE INDEX idx_active_products ON products(product_name) WHERE is_deleted = FALSE;
--   Saves 80-90% index storage and memory footprint by ignoring deleted/inactive rows!
-- ============================================================================

-- ============================================================================
-- PART 1: SCHEMA TEARDOWN & DDL (TABLE CREATION)
-- ============================================================================

DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS salary_history CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- 1. Departments Table
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL UNIQUE,
    location VARCHAR(50) NOT NULL
);

-- 2. Employees Table (Hierarchical Self-Referencing for Org Chart / Recursive CTEs)
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    commission_pct NUMERIC(3, 2),
    manager_id INT REFERENCES employees(emp_id),
    dept_id INT REFERENCES departments(dept_id),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Salary Audit History (For tracking salary increments / Window functions)
CREATE TABLE salary_history (
    history_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employees(emp_id) ON DELETE CASCADE,
    old_salary NUMERIC(10, 2) NOT NULL,
    new_salary NUMERIC(10, 2) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Customers Table (E-commerce / Microservices Domain)
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Product Categories
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

-- 6. Products Table (Includes stock & soft-delete flag for microservices)
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT REFERENCES categories(category_id),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE -- Soft delete pattern
);

-- 7. Orders Table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- 8. Order Items Table
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL
);

-- 9. Payments Table
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('CREDIT_CARD', 'UPI', 'NET_BANKING', 'DEBIT_CARD')),
    amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS', 'FAILED', 'PENDING'))
);


-- ============================================================================
-- PART 2: DML (RICH TEST DATA INSERTION)
-- ============================================================================

-- Insert Departments (Includes an empty dept 'Research & Development' for anti-joins)
INSERT INTO departments (dept_id, dept_name, location) VALUES
(10, 'Engineering', 'Bengaluru'),
(20, 'Product', 'Bengaluru'),
(30, 'Sales', 'Mumbai'),
(40, 'Human Resources', 'Hyderabad'),
(50, 'Research & Development', 'Pune');

SELECT setval('departments_dept_id_seq', (SELECT MAX(dept_id) FROM departments));

-- Insert Employees (Multi-level hierarchy: CEO -> VP -> Director/Manager -> Lead -> Dev)
-- Note: Includes deliberate salary ties and duplicates for window function & deduplication tests.
INSERT INTO employees (emp_id, first_name, last_name, email, phone, hire_date, job_title, salary, commission_pct, manager_id, dept_id, is_active) VALUES
(1, 'Arjun', 'Mehta', 'arjun.mehta@techcorp.com', '9876543210', '2019-01-15', 'CEO', 250000.00, NULL, NULL, 20, TRUE),
(2, 'Rohit', 'Sharma', 'rohit.sharma@techcorp.com', '9876543211', '2019-06-01', 'VP of Engineering', 180000.00, NULL, 1, 10, TRUE),
(3, 'Priya', 'Nair', 'priya.nair@techcorp.com', '9876543212', '2020-02-10', 'Engineering Director', 150000.00, NULL, 2, 10, TRUE),
(4, 'Vikram', 'Rathore', 'vikram.rathore@techcorp.com', '9876543213', '2020-08-15', 'Engineering Manager', 130000.00, NULL, 3, 10, TRUE),
(5, 'Ananya', 'Deshmukh', 'ananya.d@techcorp.com', '9876543214', '2021-03-01', 'Lead Backend Engineer', 110000.00, NULL, 4, 10, TRUE),
(6, 'Karthik', 'Iyer', 'karthik.i@techcorp.com', '9876543215', '2021-07-15', 'Senior Java Developer', 95000.00, NULL, 4, 10, TRUE),
(7, 'Sneha', 'Patil', 'sneha.p@techcorp.com', '9876543216', '2022-01-10', 'Senior Java Developer', 95000.00, NULL, 4, 10, TRUE), -- Tied with Karthik
(8, 'Gaurav', 'Verma', 'gaurav.v@techcorp.com', '9876543217', '2022-05-20', 'Software Engineer', 75000.00, NULL, 5, 10, TRUE),
(9, 'Pooja', 'Hegde', 'pooja.h@techcorp.com', '9876543218', '2023-01-15', 'Junior Backend Developer', 55000.00, NULL, 5, 10, TRUE),
(10, 'Sameer', 'Khan', 'sameer.k@techcorp.com', '9876543219', '2020-04-01', 'Head of Sales', 140000.00, 0.15, 1, 30, TRUE),
(11, 'Ritu', 'Sen', 'ritu.sen@techcorp.com', '9876543220', '2021-09-01', 'Senior Sales Executive', 85000.00, 0.10, 10, 30, TRUE),
(12, 'Aditya', 'Mishra', 'aditya.m@techcorp.com', '9876543221', '2022-03-15', 'Sales Executive', 65000.00, 0.08, 10, 30, TRUE),
(13, 'Neha', 'Kapoor', 'neha.k@techcorp.com', '9876543222', '2020-11-01', 'HR Director', 120000.00, NULL, 1, 40, TRUE),
(14, 'Manish', 'Gupta', 'manish.g@techcorp.com', '9876543223', '2022-08-01', 'HR Specialist', 60000.00, NULL, 13, 40, TRUE),
-- Inactive employee (for soft delete / active status checks)
(15, 'Suresh', 'Raina', 'suresh.r@techcorp.com', '9876543224', '2021-01-10', 'Contractor Engineer', 50000.00, NULL, 4, 10, FALSE),
-- Intentional DUPLICATE record for testing deduplication queries (same email, different ID)
(16, 'Sneha', 'Patil Duplicate', 'sneha.p@techcorp.com', '9876543216', '2022-01-10', 'Senior Java Developer', 95000.00, NULL, 4, 10, TRUE);

SELECT setval('employees_emp_id_seq', (SELECT MAX(emp_id) FROM employees));

-- Insert Categories
INSERT INTO categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Furniture'),
(3, 'Office Supplies'),
(4, 'Books'),
(5, 'Fitness'); -- Category with no products sold yet

SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));

-- Insert Products
INSERT INTO products (product_id, product_name, category_id, unit_price, stock_quantity, is_active, is_deleted) VALUES
(101, 'MacBook Pro 16 M3', 1, 2499.00, 25, TRUE, FALSE),
(102, 'Dell 27-inch 4K Monitor', 1, 499.00, 40, TRUE, FALSE),
(103, 'Keychron Mechanical Keyboard', 1, 120.00, 80, TRUE, FALSE),
(104, 'Logitech MX Master 3S', 1, 99.00, 100, TRUE, FALSE),
(105, 'Ergonomic Mesh Chair', 2, 350.00, 15, TRUE, FALSE),
(106, 'Electric Standing Desk', 2, 650.00, 10, TRUE, FALSE),
(107, 'Designing Data-Intensive Applications', 4, 45.00, 150, TRUE, FALSE),
(108, 'Clean Code by Robert Martin', 4, 38.00, 90, TRUE, FALSE),
(109, 'Microservices Patterns by Chris Richardson', 4, 52.00, 60, TRUE, FALSE),
(110, 'Discontinued Smartwatch', 1, 199.00, 0, FALSE, TRUE), -- Soft-deleted product
(111, 'Adjustable Dumbbells Set', 5, 299.00, 20, TRUE, FALSE); -- Product never ordered

SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));

-- Insert Customers
-- Note: Includes active buyers and customer 206 who registered but never placed an order
INSERT INTO customers (customer_id, customer_name, email, city, state, created_at) VALUES
(201, 'Amit Patel', 'amit.patel@gmail.com', 'Bengaluru', 'Karnataka', '2024-01-10 10:00:00+05:30'),
(202, 'Deepa Rao', 'deepa.rao@yahoo.com', 'Hyderabad', 'Telangana', '2024-02-15 11:30:00+05:30'),
(203, 'Siddharth Joshi', 'siddharth.j@outlook.com', 'Pune', 'Maharashtra', '2024-03-01 09:15:00+05:30'),
(204, 'Kavita Sundaram', 'kavita.s@gmail.com', 'Chennai', 'Tamil Nadu', '2024-03-20 14:00:00+05:30'),
(205, 'Varun Dhawan', 'varun.d@gmail.com', 'Mumbai', 'Maharashtra', '2024-04-05 16:45:00+05:30'),
(206, 'Anil Kumble', 'anil.k@gmail.com', 'Bengaluru', 'Karnataka', '2024-05-12 18:00:00+05:30'); -- Zero orders

SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers));

-- Insert Orders (Spans multiple months across 2024 and 2025 for time-series analysis)
INSERT INTO orders (order_id, customer_id, order_date, status, total_amount) VALUES
(1001, 201, '2024-01-15', 'COMPLETED', 2998.00),
(1002, 202, '2024-01-20', 'COMPLETED', 598.00),
(1003, 203, '2024-02-10', 'COMPLETED', 1000.00),
(1004, 201, '2024-02-14', 'COMPLETED', 135.00),
(1005, 204, '2024-03-05', 'CANCELLED', 2499.00),
(1006, 205, '2024-03-15', 'COMPLETED', 749.00),
(1007, 201, '2024-03-22', 'COMPLETED', 650.00),
(1008, 203, '2024-04-10', 'COMPLETED', 120.00),
(1009, 202, '2024-04-18', 'REFUNDED', 499.00),
(1010, 204, '2024-05-01', 'COMPLETED', 388.00),
-- Customer 201 ordering on consecutive dates (for consecutive days analysis):
(1011, 201, '2024-06-01', 'COMPLETED', 99.00),
(1012, 201, '2024-06-02', 'COMPLETED', 120.00),
(1013, 201, '2024-06-03', 'COMPLETED', 45.00),
-- Recent orders:
(1014, 205, '2024-07-10', 'COMPLETED', 2499.00),
(1015, 203, '2024-07-25', 'PENDING', 350.00);

SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));

-- Insert Order Items
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
(1, 1001, 101, 1, 2499.00),
(2, 1001, 102, 1, 499.00),
(3, 1002, 104, 1, 99.00),
(4, 1002, 102, 1, 499.00),
(5, 1003, 105, 2, 350.00),
(6, 1003, 106, 1, 300.00),
(7, 1004, 107, 1, 45.00),
(8, 1004, 108, 1, 38.00),
(9, 1004, 109, 1, 52.00),
(10, 1005, 101, 1, 2499.00),
(11, 1006, 102, 1, 499.00),
(12, 1006, 103, 1, 120.00),
(13, 1006, 104, 1, 99.00),
(14, 1006, 108, 1, 31.00),
(15, 1007, 106, 1, 650.00),
(16, 1008, 103, 1, 120.00),
(17, 1009, 102, 1, 499.00),
(18, 1010, 105, 1, 350.00),
(19, 1010, 108, 1, 38.00),
(20, 1011, 104, 1, 99.00),
(21, 1012, 103, 1, 120.00),
(22, 1013, 107, 1, 45.00),
(23, 1014, 101, 1, 2499.00),
(24, 1015, 105, 1, 350.00);

SELECT setval('order_items_order_item_id_seq', (SELECT MAX(order_item_id) FROM order_items));

-- Insert Payments
INSERT INTO payments (payment_id, order_id, payment_date, payment_method, amount, status) VALUES
(501, 1001, '2024-01-15 10:15:00+05:30', 'CREDIT_CARD', 2998.00, 'SUCCESS'),
(502, 1002, '2024-01-20 11:45:00+05:30', 'UPI', 598.00, 'SUCCESS'),
(503, 1003, '2024-02-10 14:00:00+05:30', 'NET_BANKING', 1000.00, 'SUCCESS'),
(504, 1004, '2024-02-14 15:30:00+05:30', 'UPI', 135.00, 'SUCCESS'),
(505, 1005, '2024-03-05 14:05:00+05:30', 'CREDIT_CARD', 2499.00, 'FAILED'),
(506, 1006, '2024-03-15 17:00:00+05:30', 'UPI', 749.00, 'SUCCESS'),
(507, 1007, '2024-03-22 18:20:00+05:30', 'CREDIT_CARD', 650.00, 'SUCCESS'),
(508, 1008, '2024-04-10 09:30:00+05:30', 'DEBIT_CARD', 120.00, 'SUCCESS'),
(509, 1009, '2024-04-18 12:00:00+05:30', 'UPI', 499.00, 'SUCCESS'),
(510, 1010, '2024-05-01 19:00:00+05:30', 'NET_BANKING', 388.00, 'SUCCESS'),
(511, 1011, '2024-06-01 11:00:00+05:30', 'UPI', 99.00, 'SUCCESS'),
(512, 1012, '2024-06-02 12:00:00+05:30', 'UPI', 120.00, 'SUCCESS'),
(513, 1013, '2024-06-03 13:00:00+05:30', 'UPI', 45.00, 'SUCCESS'),
(514, 1014, '2024-07-10 16:30:00+05:30', 'CREDIT_CARD', 2499.00, 'SUCCESS');

SELECT setval('payments_payment_id_seq', (SELECT MAX(payment_id) FROM payments));


-- ============================================================================
-- PART 3: TOP 40+ SQL INTERVIEW QUESTIONS & SOLUTIONS FOR 3 YOE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 0: ESSENTIAL EASY-LEVEL INTERVIEW QUESTIONS (SCREENING ROUNDS)
-- ----------------------------------------------------------------------------
-- Interviewers frequently ask these in the first 10-15 minutes of a 3 YOE backend
-- round to test fundamental fluency with joins, null safety, string ops, and aggregation.
-- Master these so you solve them effortlessly and save maximum time for Medium/Hard questions!

-- EQ1. [Easy] Pattern Matching & Case-Insensitive Search
-- Question: Find all active employees whose first name starts with 'A' or ends with 'a' (case-insensitive).
-- Interview Concept: LIKE vs ILIKE in PostgreSQL; why LIKE is case-sensitive in PostgreSQL unlike MySQL.
SELECT emp_id, first_name, last_name, email, job_title
FROM employees
WHERE is_active = TRUE
  AND (first_name ILIKE 'A%' OR first_name ILIKE '%a');


-- EQ2. [Easy] The NULL Comparison Trap (IS NULL vs = NULL)
-- Question: Find the top executive (CEO) who has NO reporting manager, displaying manager as 'None'.
-- Interview Trap: "Why does WHERE manager_id = NULL return 0 rows?"
-- Answer: In SQL three-valued logic, '= NULL' evaluates to UNKNOWN. You must always use 'IS NULL'.
SELECT 
    emp_id, 
    first_name || ' ' || last_name AS full_name, 
    job_title,
    COALESCE(manager_id::TEXT, 'None') AS manager_id
FROM employees
WHERE manager_id IS NULL;


-- EQ3. [Easy] Total Compensation & The NULL Arithmetic Trap
-- Question: Calculate each employee's total compensation (salary + commission amount).
-- Trap: If commission_pct is NULL, 'salary * commission_pct' becomes NULL!
-- In SQL, any arithmetic with NULL yields NULL. Always wrap nullable columns with COALESCE().
SELECT 
    emp_id,
    first_name || ' ' || last_name AS full_name,
    salary,
    COALESCE(commission_pct, 0.00) AS commission_pct,
    salary + (salary * COALESCE(commission_pct, 0.00)) AS total_compensation
FROM employees
WHERE is_active = TRUE;


-- EQ4. [Easy] Basic Inner Join with String Manipulation
-- Question: Display employee full name in UPPERCASE, job title, department name, and city location.
-- Concept: INNER JOIN drops unassigned rows; string concatenation with '||' and UPPER().
SELECT 
    UPPER(e.first_name || ' ' || e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.is_active = TRUE;


-- EQ5. [Easy] Company-Wide Salary Statistics (Basic Aggregations)
-- Question: Find total employee count, minimum salary, maximum salary, and average salary.
-- Concept: Aggregate functions ignore NULL values (except COUNT(*)).
SELECT 
    COUNT(*) AS total_employees,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    ROUND(AVG(salary), 2) AS avg_salary,
    SUM(salary) AS total_payroll
FROM employees
WHERE is_active = TRUE;


-- EQ6. [Easy] The COUNT(*) vs COUNT(column) Trap with LEFT JOIN
-- Question: List all departments and their employee count, INCLUDING departments with 0 employees.
-- Classic Interview Trap:
-- - COUNT(*) counts rows returned. For empty departments, the LEFT JOIN produces 1 row with NULLs,
--   so COUNT(*) incorrectly reports 1 employee!
-- - COUNT(e.emp_id) ignores NULL values and correctly reports 0 employees!
SELECT 
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS active_employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.is_active = TRUE
GROUP BY d.dept_id, d.dept_name, d.location
ORDER BY active_employee_count DESC;


-- EQ7. [Easy] Scalar Subquery: Above Average Salaries
-- Question: Find all employees who earn strictly more than the company-wide average salary.
-- Concept: Single scalar subquery in WHERE clause.
SELECT 
    emp_id, 
    first_name || ' ' || last_name AS full_name, 
    salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees WHERE is_active = TRUE)
  AND is_active = TRUE
ORDER BY salary DESC;


-- EQ8. [Easy] Date Filtering with Range & Date Parts
-- Question: Find all orders placed in Q1 2024 (Jan 1, 2024 to Mar 31, 2024).
-- Best Practice: Use explicit range >= and <= or BETWEEN.
-- Note: BETWEEN is inclusive of both endpoints.
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY order_date ASC;


-- EQ9. [Easy] DISTINCT vs COUNT(DISTINCT)
-- Question: Find all distinct cities where customers reside, and the total count of distinct cities.
-- Concept: Removing duplicates from projected set.
-- Query 1: List distinct cities
SELECT DISTINCT city 
FROM customers 
ORDER BY city;

-- Query 2: Count unique cities
SELECT COUNT(DISTINCT city) AS unique_customer_cities 
FROM customers;


-- EQ10. [Easy] Top N Query using ORDER BY and LIMIT
-- Question: Find the top 3 highest-earning employees in the company.
-- Concept: ORDER BY column DESC LIMIT N.
-- Follow-up Question: "What is the limitation of LIMIT 3 if multiple employees share the 3rd rank?"
-- Answer: LIMIT arbitrarily cuts off tied candidates. Use DENSE_RANK() if ties must be included!
SELECT emp_id, first_name, last_name, salary
FROM employees
WHERE is_active = TRUE
ORDER BY salary DESC
LIMIT 3;


-- EQ11. [Easy] UNION vs UNION ALL Comparison
-- Question: Combine customer emails and employee emails into a single result set.
-- Interview Distinction:
-- - UNION ALL simply appends result sets (Fast, O(1), preserves duplicates).
-- - UNION performs a deduplication sort (Unique node in execution plan, O(N log N) overhead).
-- Always default to UNION ALL in microservices unless deduplication is strictly required!
SELECT email, 'EMPLOYEE' AS source_type FROM employees
UNION ALL
SELECT email, 'CUSTOMER' AS source_type FROM customers;


-- EQ12. [Easy] Simple Conditional Classification with CASE WHEN
-- Question: Classify employees into 'Junior' (< 70k), 'Mid-Level' (70k - 120k), or 'Senior' (> 120k).
-- Concept: Basic CASE WHEN expression evaluated row-by-row.
SELECT 
    emp_id,
    first_name || ' ' || last_name AS full_name,
    salary,
    CASE 
        WHEN salary < 70000.00 THEN 'Junior'
        WHEN salary BETWEEN 70000.00 AND 120000.00 THEN 'Mid-Level'
        ELSE 'Senior'
    END AS seniority_tier
FROM employees
WHERE is_active = TRUE
ORDER BY salary DESC;


-- ----------------------------------------------------------------------------
-- SECTION A: WINDOW FUNCTIONS & RANKING (Most Tested Topic for 3 YOE!)
-- ----------------------------------------------------------------------------

-- Q1. [Medium] Find the N-th Highest Salary (e.g., 3rd highest) across the entire company.
-- Microservices Context: Compensation reporting, tiered pricing tier lookup.
-- Key Concept: Why DENSE_RANK() must be used instead of ROW_NUMBER() or LIMIT/OFFSET.
WITH RankedSalaries AS (
    SELECT 
        emp_id, 
        first_name, 
        last_name, 
        salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
    FROM employees
    WHERE is_active = TRUE
)
SELECT emp_id, first_name, last_name, salary
FROM RankedSalaries
WHERE salary_rank = 3;


-- Q2. [Medium-Hard] Find the Top 2 Highest-Paid Employees in EACH Department.
-- Microservices Context: Department budget allocation, leaderboards.
-- Key Concept: PARTITION BY with DENSE_RANK().
WITH DeptSalaryRank AS (
    SELECT 
        e.emp_id,
        e.first_name,
        e.last_name,
        d.dept_name,
        e.salary,
        DENSE_RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
    WHERE e.is_active = TRUE
)
SELECT dept_name, first_name, last_name, salary, rnk
FROM DeptSalaryRank
WHERE rnk <= 2
ORDER BY dept_name, rnk;


-- Q3. [Easy-Medium] Show the exact difference between ROW_NUMBER(), RANK(), and DENSE_RANK()
--     on Engineering department salaries (contains tied salaries of 95,000).
-- Interviewer favorite: "When would you choose RANK() over DENSE_RANK()?"
SELECT 
    emp_id,
    first_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK()       OVER (ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees
WHERE dept_id = 10 AND is_active = TRUE;
-- Notice:
-- - ROW_NUMBER gives sequential numbers without ties (1, 2, 3, 4...).
-- - RANK skips rank numbers after ties (1, 2, 3, 4, 4, 6... skipped 5!).
-- - DENSE_RANK does not skip numbers after ties (1, 2, 3, 4, 4, 5...).


-- Q4. [Medium] Calculate the Running Total (Cumulative Revenue) by order date for COMPLETED orders.
-- Microservices Context: Analytics dashboard showing day-by-day revenue accumulation.
SELECT 
    order_id,
    order_date,
    total_amount,
    SUM(total_amount) OVER (
        ORDER BY order_date, order_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM orders
WHERE status = 'COMPLETED'
ORDER BY order_date;


-- Q5. [Hard] Month-Over-Month (MoM) Revenue Growth Percentage.
-- Microservices Context: Financial microservice calculating monthly financial health indicators.
-- Key Concept: DATE_TRUNC(), LAG() window function, and NULL handling for first month.
WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', order_date)::DATE AS sales_month,
        SUM(total_amount) AS current_month_revenue
    FROM orders
    WHERE status = 'COMPLETED'
    GROUP BY DATE_TRUNC('month', order_date)
),
MoM_Comparison AS (
    SELECT 
        sales_month,
        current_month_revenue,
        LAG(current_month_revenue, 1) OVER (ORDER BY sales_month) AS prev_month_revenue
    FROM MonthlySales
)
SELECT 
    sales_month,
    current_month_revenue,
    COALESCE(prev_month_revenue, 0) AS prev_month_revenue,
    ROUND(
        ((current_month_revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0)) * 100.0, 
        2
    ) AS mom_growth_pct
FROM MoM_Comparison
ORDER BY sales_month;


-- Q6. [Medium] Find employees who earn MORE than the average salary of their own department.
-- Microservices Context: Anomaly detection, compensation calibration service.
-- Approach 1: Window Function (Optimal, single pass over table):
WITH EmpWithDeptAvg AS (
    SELECT 
        emp_id,
        first_name,
        last_name,
        dept_id,
        salary,
        AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg_salary
    FROM employees
    WHERE is_active = TRUE
)
SELECT 
    emp_id,
    first_name,
    last_name,
    salary,
    ROUND(dept_avg_salary, 2) AS dept_avg_salary
FROM EmpWithDeptAvg
WHERE salary > dept_avg_salary;


-- Q7. [Medium-Hard] Find Customers who placed orders on 3 or more CONSECUTIVE days.
-- Microservices Context: Gamification, daily streak rewards, fraud / bot pattern detection.
-- Key Concept: Using LAG() with 1 and 2 offsets.
WITH DistinctDailyOrders AS (
    SELECT DISTINCT customer_id, order_date
    FROM orders
    WHERE status = 'COMPLETED'
),
OrderLags AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date, 1) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_day_1,
        LAG(order_date, 2) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_day_2
    FROM DistinctDailyOrders
)
SELECT DISTINCT customer_id
FROM OrderLags
WHERE order_date = prev_day_1 + INTERVAL '1 day'
  AND prev_day_1 = prev_day_2 + INTERVAL '1 day';


-- Q8. [Medium] Divide active customers into 4 quartiles based on their total spend using NTILE(4).
-- Microservices Context: Customer tier classification (Bronze, Silver, Gold, Platinum).
WITH CustomerSpend AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'COMPLETED'
    GROUP BY c.customer_id, c.customer_name
)
SELECT 
    customer_id,
    customer_name,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS spend_quartile,
    CASE NTILE(4) OVER (ORDER BY total_spent DESC)
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        ELSE 'Bronze'
    END AS tier
FROM CustomerSpend
ORDER BY total_spent DESC;


-- ----------------------------------------------------------------------------
-- SECTION B: ADVANCED JOINS, SET OPERATIONS & ANTI-JOINS
-- ----------------------------------------------------------------------------

-- Q9. [Medium] Find all customers who have registered but NEVER placed any completed order.
-- Microservices Context: Churn prevention, re-engagement notification dispatch service.
-- Interviewer follow-up: Compare NOT EXISTS vs LEFT JOIN ... WHERE NULL vs NOT IN.

-- Approach A: NOT EXISTS (Recommended in production; handles NULLs safely and short-circuits)
SELECT c.customer_id, c.customer_name, c.email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id AND o.status = 'COMPLETED'
);

-- Approach B: LEFT JOIN ... WHERE IS NULL
SELECT c.customer_id, c.customer_name, c.email
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'COMPLETED'
WHERE o.order_id IS NULL;

-- CAUTION NOTE for 3 YOE: Never use 'NOT IN' if the subquery column can have NULL values!
-- In SQL, `x NOT IN (1, 2, NULL)` evaluates to UNKNOWN, returning 0 rows!


-- Q10. [Easy-Medium] Find all departments that currently have ZERO active employees.
-- Microservices Context: Resource cleanup, department consolidation.
SELECT d.dept_id, d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.is_active = TRUE
WHERE e.emp_id IS NULL;


-- Q11. [Medium] Self-Join: Find all pairs of employees working in the SAME department
--      who have the EXACT same salary (Avoid duplicate mirrored pairs like (A,B) and (B,A)).
SELECT 
    e1.dept_id,
    e1.emp_id AS emp1_id,
    e1.first_name || ' ' || e1.last_name AS emp1_name,
    e2.emp_id AS emp2_id,
    e2.first_name || ' ' || e2.last_name AS emp2_name,
    e1.salary
FROM employees e1
JOIN employees e2 ON e1.dept_id = e2.dept_id 
                AND e1.salary = e2.salary 
                AND e1.emp_id < e2.emp_id -- Avoid self-pairing and mirror pairs
WHERE e1.is_active = TRUE AND e2.is_active = TRUE;


-- Q12. [Medium] Find products that have NEVER been ordered.
SELECT p.product_id, p.product_name, c.category_name, p.unit_price
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
);


-- ----------------------------------------------------------------------------
-- SECTION C: AGGREGATIONS, GROUPING & CONDITIONAL LOGIC (CASE & FILTER)
-- ----------------------------------------------------------------------------

-- Q13. [Medium] Pivot Table / Conditional Aggregation:
--      For every customer, display their total COMPLETED orders, CANCELLED orders,
--      and total money spent on COMPLETED orders in a single row.
-- Microservices Context: Customer summary endpoint (/api/v1/customers/{id}/summary).
-- Key Concept: PostgreSQL FILTER (WHERE ...) clause vs standard CASE WHEN.
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) FILTER (WHERE o.status = 'COMPLETED') AS completed_orders_count,
    COUNT(o.order_id) FILTER (WHERE o.status = 'CANCELLED') AS cancelled_orders_count,
    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'COMPLETED'), 0.00) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;


-- Q14. [Medium] Find customers who have purchased products from BOTH 'Electronics' AND 'Books'.
-- Microservices Context: Cross-category affinity recommendations, upsell targeting.
-- Key Concept: HAVING COUNT(DISTINCT ...) pattern.
SELECT 
    c.customer_id,
    c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE cat.category_name IN ('Electronics', 'Books') AND o.status = 'COMPLETED'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT cat.category_name) = 2;


-- Q15. [Easy-Medium] Find departments that have at least 2 active employees
--      AND whose average salary is greater than 80,000.
-- Key Concept: WHERE filters rows before grouping; HAVING filters aggregated groups.
SELECT 
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
WHERE e.is_active = TRUE
GROUP BY d.dept_id, d.dept_name
HAVING COUNT(e.emp_id) >= 2 AND AVG(e.salary) > 80000.00;


-- Q16. [Easy-Medium] Find the 2nd Highest Salary WITHOUT using window functions.
-- (Classic interview constraint question).
-- Approach: Subquery with MAX()
SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees WHERE is_active = TRUE)
  AND is_active = TRUE;


-- ----------------------------------------------------------------------------
-- SECTION D: RECURSIVE CTES & HIERARCHICAL QUERIES (Org Charts / BOM)
-- ----------------------------------------------------------------------------

-- Q17. [Hard] Generate the Full Organization Hierarchy from the CEO down to junior developers.
--      Display Employee Name, Manager Name, Hierarchy Level (1 for CEO, 2 for VP...),
--      and full reporting path (e.g., 'Arjun Mehta -> Rohit Sharma -> Priya Nair').
-- Microservices Context: Approval workflow chains, access permission inheritance.
WITH RECURSIVE OrgChart AS (
    -- Anchor Member: Top-level executive (CEO with no manager)
    SELECT 
        emp_id,
        first_name || ' ' || last_name AS emp_name,
        manager_id,
        CAST(NULL AS VARCHAR(100)) AS manager_name,
        1 AS level,
        CAST(first_name || ' ' || last_name AS TEXT) AS reporting_path
    FROM employees
    WHERE manager_id IS NULL AND is_active = TRUE

    UNION ALL

    -- Recursive Member: Subordinates reporting to the previous level
    SELECT 
        e.emp_id,
        e.first_name || ' ' || e.last_name AS emp_name,
        e.manager_id,
        o.emp_name AS manager_name,
        o.level + 1 AS level,
        o.reporting_path || ' -> ' || (e.first_name || ' ' || e.last_name) AS reporting_path
    FROM employees e
    JOIN OrgChart o ON e.manager_id = o.emp_id
    WHERE e.is_active = TRUE
)
SELECT emp_id, emp_name, manager_name, level, reporting_path
FROM OrgChart
ORDER BY level, emp_id;


-- Q18. [Hard] Find all direct and indirect subordinates under Engineering Director 'Priya Nair' (emp_id = 3).
WITH RECURSIVE Subordinates AS (
    SELECT emp_id, first_name, last_name, job_title, manager_id, 1 AS depth
    FROM employees
    WHERE emp_id = 3

    UNION ALL

    SELECT e.emp_id, e.first_name, e.last_name, e.job_title, e.manager_id, s.depth + 1
    FROM employees e
    JOIN Subordinates s ON e.manager_id = s.emp_id
    WHERE e.is_active = TRUE
)
SELECT emp_id, first_name || ' ' || last_name AS full_name, job_title, depth
FROM Subordinates
WHERE emp_id != 3 -- Exclude Priya herself
ORDER BY depth, emp_id;


-- ----------------------------------------------------------------------------
-- SECTION E: DATA DEDUPLICATION & STRING / DATE MANIPULATIONS
-- ----------------------------------------------------------------------------

-- Q19. [Medium-Hard] Find duplicate employees by email and delete the duplicate records,
--      keeping ONLY the record with the lowest emp_id.
-- Microservices Context: Data migration cleanup, message retry deduplication.

-- Step 1: Detect duplicates
SELECT email, COUNT(*) AS count_records, ARRAY_AGG(emp_id) AS duplicate_ids
FROM employees
GROUP BY email
HAVING COUNT(*) > 1;

-- Step 2: Delete duplicate records safely using CTE and ctid or emp_id
-- (Runnable query: removes emp_id 16 which is a duplicate of emp_id 7)
DELETE FROM employees
WHERE emp_id IN (
    SELECT emp_id
    FROM (
        SELECT 
            emp_id,
            ROW_NUMBER() OVER (PARTITION BY email ORDER BY emp_id ASC) AS row_num
        FROM employees
    ) ranked
    WHERE ranked.row_num > 1
);


-- Q20. [Medium] Aggregate all employee names in each department into a comma-separated list.
-- Microservices Context: Grouping child entities into parent responses without N+1 queries.
-- Key Concept: STRING_AGG() with ORDER BY.
SELECT 
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    STRING_AGG(e.first_name || ' ' || e.last_name, ', ' ORDER BY e.salary DESC) AS employee_roster
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
WHERE e.is_active = TRUE
GROUP BY d.dept_id, d.dept_name;


-- Q21. [Easy-Medium] Extract email domain and calculate employee tenure in years and months.
-- Key Concept: SPLIT_PART() and AGE().
SELECT 
    emp_id,
    first_name || ' ' || last_name AS full_name,
    email,
    SPLIT_PART(email, '@', 2) AS email_domain,
    hire_date,
    AGE(CURRENT_DATE, hire_date) AS exact_tenure,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS tenure_years
FROM employees
WHERE is_active = TRUE;


-- ----------------------------------------------------------------------------
-- SECTION F: BACKEND & MICROSERVICES PRODUCTION PATTERNS
-- ----------------------------------------------------------------------------

-- Q22. [Hard] Keyset Pagination (Cursor-based Pagination) vs OFFSET Pagination.
-- Microservices Context: High-performance REST API /api/v1/orders?pageSize=5&lastSeenId=1005
-- Why OFFSET 100000 is an anti-pattern: PostgreSQL must read & discard 100,000 rows ($O(N)$ disk I/O).
-- Keyset pagination uses indexed B-Tree range scan ($O(\log N)$).

-- Keyset pagination query (Fetch next 5 orders after order_id 1004):
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
WHERE order_id > 1004 -- Cursor: Last seen ID from previous page
ORDER BY order_id ASC
LIMIT 5;


-- Q23. [Medium] Idempotent Upsert (INSERT ... ON CONFLICT).
-- Microservices Context: Kafka consumer receiving duplicate user registration events.
INSERT INTO customers (customer_id, customer_name, email, city, state, created_at)
VALUES (207, 'Rahul Dravid', 'rahul.d@wall.com', 'Bengaluru', 'Karnataka', CURRENT_TIMESTAMP)
ON CONFLICT (email) 
DO UPDATE SET 
    customer_name = EXCLUDED.customer_name,
    city = EXCLUDED.city,
    state = EXCLUDED.state;


-- Q24. [Medium-Hard] Pessimistic Locking for Inventory Management (Preventing Overselling).
-- Microservices Context: Order Service reserving stock in a Spring `@Transactional` method.
-- Spring Data JPA equivalent: `@Lock(LockModeType.PESSIMISTIC_WRITE)`
BEGIN;

-- Lock the specific product row so concurrent transactions wait until this finishes
SELECT product_id, product_name, stock_quantity, unit_price
FROM products
WHERE product_id = 101
FOR UPDATE;

-- Update stock if sufficient:
UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 101 AND stock_quantity >= 1;

COMMIT;


-- Q25. [Medium-Hard] Solving the JPA N+1 Query Problem using PostgreSQL JSON Aggregation.
-- Microservices Context: Return a customer and all their orders in a SINGLE database roundtrip.
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'order_id', o.order_id,
                'order_date', o.order_date,
                'status', o.status,
                'total_amount', o.total_amount
            ) ORDER BY o.order_date DESC
        ) FILTER (WHERE o.order_id IS NOT NULL), 
        '[]'::JSON
    ) AS orders_json
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email;


-- Q26. [Medium] Soft Delete with Partial Unique Index.
-- Microservices Context: When a product is soft-deleted (`is_deleted = TRUE`), allow re-using the
-- name, but enforce strict uniqueness across all ACTIVE products (`is_deleted = FALSE`).

-- Step 1: Create partial unique index
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_product_name 
ON products (product_name) 
WHERE is_deleted = FALSE;

-- Step 2: Querying only active records:
SELECT product_id, product_name, unit_price, stock_quantity
FROM products
WHERE is_deleted = FALSE;


-- ----------------------------------------------------------------------------
-- SECTION G: PERFORMANCE TUNING & QUERY OPTIMIZATION CHECKLIST (3 YOE)
-- ----------------------------------------------------------------------------
-- When asked: "How would you optimize a slow PostgreSQL query in Spring Boot?"
--
-- 1. Run EXPLAIN (ANALYZE, BUFFERS) <query>;
--    - Look for "Seq Scan" on large tables (missing index).
--    - Look for high "Shared Hit / Read Buffers" (disk I/O bottleneck).
--    - Verify "Actual Rows" vs "Estimated Rows" (outdated statistics; run ANALYZE tablename).
--
-- 2. Index Column Ordering in Composite Indexes:
--    - Rule: (Equality columns FIRST, Range columns LAST).
--    - Example: For `WHERE status = 'COMPLETED' AND order_date >= '2024-01-01'`:
--      Index should be: CREATE INDEX idx_orders_status_date ON orders(status, order_date);
--
-- 3. Avoid Functions on Indexed Columns:
--    - BAD:  WHERE DATE_TRUNC('day', created_at) = '2024-01-15' (Invalidates standard index!)
--    - GOOD: WHERE created_at >= '2024-01-15 00:00:00' AND created_at < '2024-01-16 00:00:00'
--
-- 4. Connection Pooling:
--    - Tune HikariCP pool size: `maximumPoolSize = (core_count * 2) + effective_spindle_count`.
-- ============================================================================
