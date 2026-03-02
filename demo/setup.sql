-- =============================================================================
-- AI-Ready Data Assessment — Demo Environment Setup
-- Target: SNOWFLAKE_LEARNING_DB.AIRDF_DEMO
--
-- Creates a realistic e-commerce dataset with intentional data quality issues
-- so the ai-ready-data skill produces a mix of PASS and FAIL results during
-- a serving-profile assessment.
--
-- Designed gaps (will FAIL assessment):
--   - Nulls in key columns                    → data_completeness
--   - Duplicate orders                        → uniqueness
--   - Dates stored as VARCHAR                 → schema_conformity
--   - Out-of-range prices                     → value_range_validity
--   - Invalid status values                   → categorical_validity
--   - No column comments                      → semantic_documentation
--   - No primary keys                         → entity_identifier_declaration
--   - No constraints                          → constraint_declaration
--   - No change tracking                      → change_detection
--   - No clustering keys                      → access_optimization
--   - No search optimization                  → search_optimization
--   - PII columns without masking policies    → field_masking
--   - No tags                                 → classification
--   - Orphan foreign keys                     → referential_integrity
--   - Encoding errors in text                 → encoding_validity
--
-- Clean areas (will PASS or nearly pass):
--   - Most rows are valid                     → high baseline quality
--   - Column names follow conventions         → schema_type_coverage
--   - Temporal columns present                → temporal_scope_declaration (partial)
--   - Numeric columns have unit-hinted names  → unit_of_measure_declaration (partial)
-- =============================================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;

CREATE SCHEMA IF NOT EXISTS AIRDF_DEMO;
USE SCHEMA AIRDF_DEMO;

-- =============================================================================
-- CUSTOMERS
-- Issues: nulls in email, encoding errors in name, PII columns unmasked
-- =============================================================================

CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID     NUMBER(38,0),
    FIRST_NAME      VARCHAR(100),
    LAST_NAME       VARCHAR(100),
    EMAIL           VARCHAR(255),
    PHONE           VARCHAR(50),
    ADDRESS         VARCHAR(500),
    CITY            VARCHAR(100),
    STATE           VARCHAR(50),
    COUNTRY         VARCHAR(100),
    CREATED_AT      TIMESTAMP_NTZ,
    UPDATED_AT      TIMESTAMP_NTZ
);

INSERT INTO CUSTOMERS VALUES
(1,  'Alice',    'Johnson',   'alice@example.com',      '555-0101', '123 Main St',      'Seattle',       'WA', 'US', '2024-01-15 08:30:00', '2025-11-01 10:00:00'),
(2,  'Bob',      'Smith',     'bob@example.com',        '555-0102', '456 Oak Ave',       'Portland',      'OR', 'US', '2024-02-20 14:15:00', '2025-10-15 09:30:00'),
(3,  'Carol',    'Williams',  NULL,                     '555-0103', '789 Pine Rd',       'San Francisco', 'CA', 'US', '2024-03-10 11:45:00', '2025-09-20 16:45:00'),
(4,  'David',    'Br' || CHR(65533) || 'wn',  'david@example.com', '555-0104', '321 Elm Blvd',  'Denver',  'CO', 'US', '2024-04-05 09:00:00', '2025-12-01 08:00:00'),
(5,  'Eve',      'Davis',     'eve@example.com',        NULL,       '654 Cedar Ln',      'Austin',        'TX', 'US', '2024-05-12 16:30:00', '2025-11-10 14:20:00'),
(6,  'Frank',    'Miller',    'frank@example.com',      '555-0106', '987 Birch Dr',      'Chicago',       'IL', 'US', '2024-06-18 10:00:00', '2025-10-05 11:15:00'),
(7,  'Grace',    'Wilson',    NULL,                     '555-0107', '147 Maple Way',     'Miami',         'FL', 'US', '2024-07-22 13:20:00', '2025-11-20 17:00:00'),
(8,  'Henry',    'Moore',     'henry@example.com',      '555-0108', '258 Walnut Ct',     'Boston',        'MA', 'US', '2024-08-30 07:45:00', '2025-09-01 12:30:00'),
(9,  'Iris',     'Taylor',    'iris@example.com',       '555-0109', NULL,                'Nashville',     'TN', 'US', '2024-09-14 15:10:00', '2025-12-10 09:00:00'),
(10, 'Jack',     'Anderson',  'jack@example.com',       '555-0110', '369 Spruce Pl',     'Phoenix',       'AZ', 'US', '2024-10-01 12:00:00', '2025-11-25 10:45:00'),
(11, 'Karen',    'Thomas',    NULL,                     '555-0111', '741 Poplar St',     'Philadelphia',  'PA', 'US', '2024-10-15 09:30:00', '2025-10-20 15:00:00'),
(12, 'Leo',      'Jackson',   'leo@example.com',        '555-0112', '852 Ash Ave',       'San Diego',     'CA', 'US', '2024-11-03 14:00:00', '2025-11-30 08:20:00'),
(13, 'Mia',      'White',     'mia@example.com',        '555-0113', '963 Fir Blvd',      'Dallas',        'TX', 'US', '2024-11-20 11:30:00', '2025-12-05 13:45:00'),
(14, 'Noah',     'Harris',    NULL,                     NULL,       '159 Redwood Rd',    'Atlanta',       'GA', 'US', '2024-12-01 08:15:00', '2025-10-10 16:30:00'),
(15, 'Olivia',   'Martin',    'olivia@example.com',     '555-0115', '753 Sycamore Ln',   'Minneapolis',   'MN', 'US', '2024-12-18 16:45:00', '2025-11-15 07:50:00'),
(16, 'Paul',     'Garcia',    'paul@example.com',       '555-0116', '846 Magnolia Dr',   'Detroit',       'MI', 'US', '2025-01-05 10:20:00', '2025-12-15 11:00:00'),
(17, 'Quinn',    'Martinez',  'quinn@example.com',      '555-0117', '937 Dogwood Way',   'Charlotte',     'NC', 'US', '2025-01-22 13:50:00', '2025-09-25 14:10:00'),
(18, 'Rachel',   'Robinson',  NULL,                     '555-0118', '148 Willow Ct',     'San Antonio',   'TX', 'US', '2025-02-10 09:40:00', '2025-10-30 09:30:00'),
(19, 'Sam',      'Clark',     'sam@example.com',        '555-0119', '259 Chestnut Pl',   'Columbus',      'OH', 'US', '2025-03-01 15:25:00', '2025-11-05 16:20:00'),
(20, 'Tina',     'Lewis',     'tina@example.com',       '555-0120', '361 Hawthorn St',   'Indianapolis',  'IN', 'US', '2025-03-18 12:10:00', '2025-12-20 10:00:00');


-- =============================================================================
-- PRODUCTS
-- Issues: negative price (out of range), one VARCHAR _ID column (schema conformity)
-- =============================================================================

CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID      NUMBER(38,0),
    SKU             VARCHAR(50),
    PRODUCT_NAME    VARCHAR(200),
    CATEGORY        VARCHAR(100),
    SUBCATEGORY     VARCHAR(100),
    PRICE_USD       FLOAT,
    WEIGHT_KG       FLOAT,
    SUPPLIER_ID     VARCHAR(50),
    IS_ACTIVE       BOOLEAN,
    CREATED_AT      TIMESTAMP_NTZ,
    UPDATED_AT      TIMESTAMP_NTZ
);

INSERT INTO PRODUCTS VALUES
(101, 'SKU-A001', 'Wireless Headphones',    'Electronics',   'Audio',        79.99,  0.25, 'SUP-001', TRUE,  '2024-01-01 00:00:00', '2025-06-15 00:00:00'),
(102, 'SKU-A002', 'Bluetooth Speaker',      'Electronics',   'Audio',        49.99,  0.80, 'SUP-001', TRUE,  '2024-01-15 00:00:00', '2025-07-01 00:00:00'),
(103, 'SKU-B001', 'Running Shoes',          'Apparel',       'Footwear',     129.99, 0.65, 'SUP-002', TRUE,  '2024-02-01 00:00:00', '2025-08-10 00:00:00'),
(104, 'SKU-B002', 'Winter Jacket',          'Apparel',       'Outerwear',    199.99, 1.20, 'SUP-002', TRUE,  '2024-02-15 00:00:00', '2025-05-20 00:00:00'),
(105, 'SKU-C001', 'Organic Coffee Beans',   'Grocery',       'Beverages',    18.99,  0.50, 'SUP-003', TRUE,  '2024-03-01 00:00:00', '2025-09-01 00:00:00'),
(106, 'SKU-C002', 'Protein Bars (12pk)',    'Grocery',       'Snacks',       24.99,  0.72, 'SUP-003', TRUE,  '2024-03-15 00:00:00', '2025-04-15 00:00:00'),
(107, 'SKU-D001', 'Yoga Mat',              'Sports',        'Fitness',       34.99,  1.50, 'SUP-004', TRUE,  '2024-04-01 00:00:00', '2025-10-20 00:00:00'),
(108, 'SKU-D002', 'Dumbbell Set 20kg',     'Sports',        'Fitness',       89.99, 20.00, 'SUP-004', TRUE,  '2024-04-15 00:00:00', '2025-03-30 00:00:00'),
(109, 'SKU-E001', 'LED Desk Lamp',         'Home',          'Lighting',      45.99,  1.10, 'SUP-005', TRUE,  '2024-05-01 00:00:00', '2025-08-25 00:00:00'),
(110, 'SKU-E002', 'Standing Desk',         'Home',          'Furniture',    449.99, 35.00, 'SUP-005', TRUE,  '2024-05-15 00:00:00', '2025-11-01 00:00:00'),
(111, 'SKU-F001', 'Stainless Water Bottle', 'Accessories',  'Drinkware',     22.99,  0.30, 'SUP-006', TRUE,  '2024-06-01 00:00:00', '2025-07-10 00:00:00'),
(112, 'SKU-F002', 'Laptop Backpack',       'Accessories',   'Bags',          64.99,  0.90, 'SUP-006', TRUE,  '2024-06-15 00:00:00', '2025-06-05 00:00:00'),
(113, 'SKU-G001', 'Defective Widget',      'Electronics',   'Gadgets',      -10.00,  0.10, 'SUP-007', FALSE, '2024-07-01 00:00:00', '2025-01-01 00:00:00'),
(114, 'SKU-G002', 'Mystery Box',           'Electronics',   'Gadgets',     9999.99,  0.05, 'SUP-007', FALSE, '2024-07-15 00:00:00', '2025-02-01 00:00:00'),
(115, 'SKU-H001', 'Ergonomic Keyboard',    'Electronics',   'Peripherals',   89.99,  0.85, 'SUP-001', TRUE,  '2024-08-01 00:00:00', '2025-10-15 00:00:00');


-- =============================================================================
-- ORDERS
-- Issues: duplicates, dates as VARCHAR (schema conformity), invalid statuses,
--         orphan customer references, encoding errors in notes
-- =============================================================================

CREATE OR REPLACE TABLE ORDERS (
    ORDER_ID        NUMBER(38,0),
    CUSTOMER_ID     NUMBER(38,0),
    ORDER_DATE      VARCHAR(30),        -- intentionally VARCHAR instead of DATE
    SHIP_DATE       VARCHAR(30),        -- intentionally VARCHAR instead of DATE
    STATUS          VARCHAR(50),
    TOTAL_AMOUNT    FLOAT,
    SHIPPING_USD    FLOAT,
    DISCOUNT_PCT    FLOAT,
    CHANNEL         VARCHAR(50),
    NOTES           VARCHAR(1000),
    CREATED_AT      TIMESTAMP_NTZ,
    UPDATED_AT      TIMESTAMP_NTZ
);

INSERT INTO ORDERS VALUES
(1001, 1,  '2025-01-10', '2025-01-13', 'DELIVERED',   159.98, 9.99,  0.00,  'WEB',    'Standard delivery',                              '2025-01-10 10:00:00', '2025-01-13 15:00:00'),
(1002, 2,  '2025-01-15', '2025-01-18', 'DELIVERED',   49.99,  5.99,  0.10,  'WEB',    'Gift wrapped',                                   '2025-01-15 11:30:00', '2025-01-18 09:00:00'),
(1003, 3,  '2025-02-01', '2025-02-04', 'DELIVERED',   129.99, 0.00,  0.05,  'MOBILE', NULL,                                             '2025-02-01 14:20:00', '2025-02-04 16:00:00'),
(1004, 4,  '2025-02-14', NULL,         'PROCESSING',  199.99, 12.99, 0.00,  'WEB',    'Valentine' || CHR(65533) || 's day rush',         '2025-02-14 09:00:00', '2025-02-14 09:00:00'),
(1005, 5,  '2025-03-01', '2025-03-03', 'DELIVERED',   18.99,  3.99,  0.00,  'MOBILE', 'Leave at door',                                  '2025-03-01 16:45:00', '2025-03-03 12:00:00'),
(1006, 6,  '2025-03-15', '2025-03-17', 'DELIVERED',   89.98,  0.00,  0.15,  'WEB',    NULL,                                             '2025-03-15 08:30:00', '2025-03-17 10:30:00'),
(1007, 7,  '2025-04-01', '2025-04-05', 'DELIVERED',   34.99,  5.99,  0.00,  'STORE',  'In-store pickup',                                '2025-04-01 12:00:00', '2025-04-05 14:00:00'),
(1008, 8,  '2025-04-20', NULL,         'CANCELLED',   449.99, 0.00,  0.20,  'WEB',    'Customer requested cancel',                      '2025-04-20 10:15:00', '2025-04-21 08:00:00'),
(1009, 9,  '2025-05-05', '2025-05-07', 'DELIVERED',   22.99,  3.99,  0.00,  'MOBILE', NULL,                                             '2025-05-05 15:30:00', '2025-05-07 11:00:00'),
(1010, 10, '2025-05-20', '2025-05-22', 'DELIVERED',   64.99,  7.99,  0.05,  'WEB',    'Signature required',                             '2025-05-20 09:45:00', '2025-05-22 16:30:00'),
(1011, 11, '2025-06-01', NULL,         'SHIPPED',     129.99, 0.00,  0.00,  'WEB',    'Express shipping',                               '2025-06-01 11:00:00', '2025-06-02 08:00:00'),
(1012, 12, '2025-06-15', '2025-06-18', 'DELIVERED',   89.99,  5.99,  0.10,  'MOBILE', NULL,                                             '2025-06-15 14:20:00', '2025-06-18 13:00:00'),
(1013, 13, '2025-07-01', '2025-07-03', 'DELIVERED',   45.99,  3.99,  0.00,  'WEB',    'Fragile item',                                   '2025-07-01 10:30:00', '2025-07-03 15:45:00'),
(1014, 14, '2025-07-20', '2025-07-23', 'DELIVERED',   24.99,  5.99,  0.00,  'STORE',  NULL,                                             '2025-07-20 16:00:00', '2025-07-23 09:30:00'),
(1015, 15, '2025-08-05', NULL,         'PROCESSING',  199.98, 0.00,  0.05,  'WEB',    'Two items backordered',                           '2025-08-05 08:00:00', '2025-08-05 08:00:00'),
(1016, 1,  '2025-08-20', '2025-08-22', 'DELIVERED',   79.99,  5.99,  0.00,  'MOBILE', NULL,                                             '2025-08-20 13:15:00', '2025-08-22 10:00:00'),
(1017, 2,  '2025-09-01', '2025-09-04', 'DELIVERED',   159.98, 0.00,  0.10,  'WEB',    'Birthday gift',                                  '2025-09-01 09:00:00', '2025-09-04 14:30:00'),
(1018, 16, '2025-09-15', NULL,         'REFUNDED',    89.99,  9.99,  0.00,  'WEB',    'Damaged in transit',                              '2025-09-15 11:45:00', '2025-09-20 16:00:00'),
(1019, 17, '2025-10-01', '2025-10-03', 'DELIVERED',   34.99,  3.99,  0.00,  'MOBILE', NULL,                                             '2025-10-01 14:30:00', '2025-10-03 12:15:00'),
(1020, 18, '2025-10-15', '2025-10-17', 'DELIVRD',     49.99,  5.99,  0.00,  'WEB',    'Typo status test',                               '2025-10-15 10:00:00', '2025-10-17 09:00:00'),

-- Duplicate orders (same ORDER_ID, tests uniqueness)
(1001, 1,  '2025-01-10', '2025-01-13', 'DELIVERED',   159.98, 9.99,  0.00,  'WEB',    'Standard delivery',                              '2025-01-10 10:00:00', '2025-01-13 15:00:00'),
(1002, 2,  '2025-01-15', '2025-01-18', 'DELIVERED',   49.99,  5.99,  0.10,  'WEB',    'Gift wrapped',                                   '2025-01-15 11:30:00', '2025-01-18 09:00:00'),

-- Orphan references (customer_id 999 does not exist)
(1021, 999, '2025-11-01', '2025-11-03', 'DELIVERED',   22.99, 3.99, 0.00,  'WEB',    'Orphan customer reference',                       '2025-11-01 08:00:00', '2025-11-03 10:00:00'),
(1022, 998, '2025-11-10', NULL,         'PENDING',     64.99, 5.99, 0.00,  'MOBILE', NULL,                                             '2025-11-10 15:00:00', '2025-11-10 15:00:00'),

-- Invalid status
(1023, 19, '2025-11-20', NULL,         'YOLO',        18.99,  3.99,  0.00,  'WEB',    NULL,                                             '2025-11-20 12:00:00', '2025-11-20 12:00:00');


-- =============================================================================
-- ORDER_ITEMS
-- Issues: no primary key, no constraints, null product references
-- =============================================================================

CREATE OR REPLACE TABLE ORDER_ITEMS (
    ORDER_ITEM_ID   NUMBER(38,0),
    ORDER_ID        NUMBER(38,0),
    PRODUCT_ID      NUMBER(38,0),
    QUANTITY        FLOAT,              -- intentionally FLOAT instead of INTEGER
    UNIT_PRICE_USD  FLOAT,
    LINE_TOTAL_USD  FLOAT,
    CREATED_AT      TIMESTAMP_NTZ
);

INSERT INTO ORDER_ITEMS VALUES
(1, 1001, 101, 2,  79.99,  159.98, '2025-01-10 10:00:00'),
(2, 1002, 102, 1,  49.99,  49.99,  '2025-01-15 11:30:00'),
(3, 1003, 103, 1,  129.99, 129.99, '2025-02-01 14:20:00'),
(4, 1004, 104, 1,  199.99, 199.99, '2025-02-14 09:00:00'),
(5, 1005, 105, 1,  18.99,  18.99,  '2025-03-01 16:45:00'),
(6, 1006, 107, 1,  34.99,  34.99,  '2025-03-15 08:30:00'),
(7, 1006, 111, 1,  22.99,  22.99,  '2025-03-15 08:30:00'),
(8, 1007, 107, 1,  34.99,  34.99,  '2025-04-01 12:00:00'),
(9, 1008, 110, 1,  449.99, 449.99, '2025-04-20 10:15:00'),
(10, 1009, 111, 1,  22.99,  22.99,  '2025-05-05 15:30:00'),
(11, 1010, 112, 1,  64.99,  64.99,  '2025-05-20 09:45:00'),
(12, 1011, 103, 1,  129.99, 129.99, '2025-06-01 11:00:00'),
(13, 1012, 108, 1,  89.99,  89.99,  '2025-06-15 14:20:00'),
(14, 1013, 109, 1,  45.99,  45.99,  '2025-07-01 10:30:00'),
(15, 1014, 106, 1,  24.99,  24.99,  '2025-07-20 16:00:00'),
(16, 1015, 101, 1,  79.99,  79.99,  '2025-08-05 08:00:00'),
(17, 1015, 104, 1,  199.99, 199.99, '2025-08-05 08:00:00'),
(18, 1016, 101, 1,  79.99,  79.99,  '2025-08-20 13:15:00'),
(19, 1017, 101, 1,  79.99,  79.99,  '2025-09-01 09:00:00'),
(20, 1017, 102, 1,  49.99,  49.99,  '2025-09-01 09:00:00'),
(21, 1018, 108, 1,  89.99,  89.99,  '2025-09-15 11:45:00'),
(22, 1019, 107, 1,  34.99,  34.99,  '2025-10-01 14:30:00'),
(23, 1020, 102, 1,  49.99,  49.99,  '2025-10-15 10:00:00'),
-- Null product reference
(24, 1021, NULL, 1,  22.99,  22.99,  '2025-11-01 08:00:00'),
-- Incorrect line total (quantity * unit price ≠ line total → cross-field inconsistency)
(25, 1022, 112, 3,  64.99,  64.99,  '2025-11-10 15:00:00'),
(26, 1023, 105, 1,  18.99,  18.99,  '2025-11-20 12:00:00');


-- =============================================================================
-- PRODUCT_REVIEWS
-- Issues: JSON stored as VARCHAR (syntactic validity test), some invalid JSON
-- =============================================================================

CREATE OR REPLACE TABLE PRODUCT_REVIEWS (
    REVIEW_ID       NUMBER(38,0),
    PRODUCT_ID      NUMBER(38,0),
    CUSTOMER_ID     NUMBER(38,0),
    RATING          NUMBER(1,0),
    REVIEW_TEXT     VARCHAR(2000),
    REVIEW_JSON     VARCHAR(4000),      -- intentionally VARCHAR holding JSON
    CREATED_AT      TIMESTAMP_NTZ
);

INSERT INTO PRODUCT_REVIEWS VALUES
(1, 101, 1,  5, 'Amazing headphones, great noise cancellation!',
    '{"rating": 5, "verified": true, "helpful_votes": 12}', '2025-02-01 10:00:00'),
(2, 102, 2,  4, 'Good speaker for the price. Bass could be better.',
    '{"rating": 4, "verified": true, "helpful_votes": 8}',  '2025-02-15 14:00:00'),
(3, 103, 3,  5, 'Most comfortable running shoes I have owned.',
    '{"rating": 5, "verified": true, "helpful_votes": 25}', '2025-03-10 09:30:00'),
(4, 107, 7,  3, 'Decent mat but started peeling after a month.',
    '{"rating": 3, "verified": true, "helpful_votes": 5}',  '2025-05-20 16:00:00'),
(5, 110, 8,  4, 'Solid desk, easy assembly. Wobbles slightly.',
    '{"rating": 4, "verified": false, "helpful_votes": 3}', '2025-06-01 11:00:00'),
(6, 109, 13, 5, 'Perfect lighting for late-night coding sessions.',
    '{"rating": 5, "verified": true, "helpful_votes": 18}', '2025-08-10 20:00:00'),
(7, 115, 19, 4, 'Great keyboard. Wrist rest is a nice touch.',
    '{"rating": 4, "verified": true, "helpful_votes": 7}',  '2025-09-05 13:30:00'),
(8, 104, 17, 2, 'Zipper broke after one season. Disappointing.',
    '{"rating": 2, "verified": true, "helpful_votes": 30}', '2025-04-10 08:45:00'),
-- Invalid JSON
(9, 105, 5,  4, 'Great coffee, smooth flavor.',
    '{"rating": 4, "verified": true, helpful_votes: 2}',    '2025-07-15 07:00:00'),
-- Missing JSON
(10, 111, 10, 5, 'Keeps drinks cold for 24 hours!',
    NULL,                                                     '2025-10-01 15:00:00');


-- =============================================================================
-- SUPPLIER_CONTRACTS
-- Issues: end_date < start_date (cross-field), no temporal column comments
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLIER_CONTRACTS (
    CONTRACT_ID     NUMBER(38,0),
    SUPPLIER_ID     VARCHAR(50),
    SUPPLIER_NAME   VARCHAR(200),
    START_DATE      DATE,
    END_DATE        DATE,
    ANNUAL_VALUE_USD FLOAT,
    STATUS          VARCHAR(50),
    REGION          VARCHAR(100),
    CREATED_AT      TIMESTAMP_NTZ
);

INSERT INTO SUPPLIER_CONTRACTS VALUES
(1, 'SUP-001', 'TechAudio Corp',         '2024-01-01', '2025-12-31', 500000.00, 'ACTIVE',   'North America', '2024-01-01 00:00:00'),
(2, 'SUP-002', 'SportStyle Inc',          '2024-03-01', '2025-12-31', 350000.00, 'ACTIVE',   'North America', '2024-03-01 00:00:00'),
(3, 'SUP-003', 'GreenGrocer Supply',      '2024-06-01', '2025-06-01', 120000.00, 'EXPIRED',  'North America', '2024-06-01 00:00:00'),
(4, 'SUP-004', 'FitGear Manufacturing',   '2024-02-01', '2026-01-31', 280000.00, 'ACTIVE',   'Asia Pacific',  '2024-02-01 00:00:00'),
(5, 'SUP-005', 'HomeComfort Ltd',         '2024-04-01', '2026-03-31', 600000.00, 'ACTIVE',   'Europe',        '2024-04-01 00:00:00'),
(6, 'SUP-006', 'AccessoryWorld',          '2024-07-01', '2025-12-31', 200000.00, 'ACTIVE',   'North America', '2024-07-01 00:00:00'),
-- Cross-field issue: end_date before start_date
(7, 'SUP-007', 'BargainBin Wholesale',    '2025-01-01', '2024-06-30', 50000.00,  'INACTIVE', 'North America', '2025-01-01 00:00:00');


-- =============================================================================
-- INVENTORY_SNAPSHOTS
-- Issues: large table (>10k via generator) with no clustering key,
--         demonstrates access_optimization gap
-- =============================================================================

CREATE OR REPLACE TABLE INVENTORY_SNAPSHOTS (
    SNAPSHOT_DATE   DATE,
    PRODUCT_ID      NUMBER(38,0),
    WAREHOUSE_ID    VARCHAR(20),
    QUANTITY_ON_HAND NUMBER(38,0),
    QUANTITY_RESERVED NUMBER(38,0),
    REORDER_POINT   NUMBER(38,0),
    UPDATED_AT      TIMESTAMP_NTZ
);

INSERT INTO INVENTORY_SNAPSHOTS
SELECT
    DATEADD(day, -MOD(SEQ4(), 365), CURRENT_DATE()) AS SNAPSHOT_DATE,
    101 + MOD(SEQ4(), 15) AS PRODUCT_ID,
    'WH-' || LPAD(MOD(SEQ4(), 5) + 1, 3, '0') AS WAREHOUSE_ID,
    ABS(MOD(RANDOM(), 500)) AS QUANTITY_ON_HAND,
    ABS(MOD(RANDOM(), 50)) AS QUANTITY_RESERVED,
    50 + MOD(SEQ4(), 100) AS REORDER_POINT,
    DATEADD(hour, MOD(SEQ4(), 24), DATEADD(day, -MOD(SEQ4(), 365), CURRENT_TIMESTAMP())) AS UPDATED_AT
FROM TABLE(GENERATOR(ROWCOUNT => 15000));


-- =============================================================================
-- MARKETING_EVENTS
-- Issues: mixed-quality data, some encoding problems in event_payload
-- =============================================================================

CREATE OR REPLACE TABLE MARKETING_EVENTS (
    EVENT_ID        NUMBER(38,0),
    CUSTOMER_ID     NUMBER(38,0),
    EVENT_TYPE      VARCHAR(50),
    EVENT_DATE      TIMESTAMP_NTZ,
    CAMPAIGN_ID     VARCHAR(50),
    CHANNEL         VARCHAR(50),
    EVENT_PAYLOAD   VARCHAR(4000),
    CREATED_AT      TIMESTAMP_NTZ
);

INSERT INTO MARKETING_EVENTS VALUES
(1,  1,  'EMAIL_OPEN',    '2025-01-12 08:30:00', 'CAMP-2025-01', 'EMAIL',  '{"subject": "New Year Sale", "opened": true}',                '2025-01-12 08:30:00'),
(2,  1,  'CLICK',         '2025-01-12 08:35:00', 'CAMP-2025-01', 'EMAIL',  '{"url": "/sale", "cta": "Shop Now"}',                         '2025-01-12 08:35:00'),
(3,  2,  'EMAIL_OPEN',    '2025-01-12 09:00:00', 'CAMP-2025-01', 'EMAIL',  '{"subject": "New Year Sale", "opened": true}',                '2025-01-12 09:00:00'),
(4,  3,  'AD_VIEW',       '2025-02-01 14:00:00', 'CAMP-2025-02', 'SOCIAL', '{"platform": "instagram", "ad_id": "IG-1234"}',               '2025-02-01 14:00:00'),
(5,  5,  'AD_CLICK',      '2025-03-01 16:00:00', 'CAMP-2025-03', 'SOCIAL', '{"platform": "facebook", "ad_id": "FB-5678"}',                '2025-03-01 16:00:00'),
(6,  6,  'PAGE_VIEW',     '2025-03-15 08:00:00', 'CAMP-2025-03', 'WEB',    '{"page": "/products/audio", "duration_seconds": 45}',         '2025-03-15 08:00:00'),
(7,  8,  'PURCHASE',      '2025-04-20 10:15:00', 'CAMP-2025-04', 'WEB',    '{"order_id": 1008, "value": 449.99}',                         '2025-04-20 10:15:00'),
(8,  10, 'EMAIL_BOUNCE',  '2025-05-20 09:00:00', 'CAMP-2025-05', 'EMAIL',  '{"reason": "invalid_address"}',                               '2025-05-20 09:00:00'),
(9,  12, 'UNSUBSCRIBE',   '2025-06-15 14:00:00', 'CAMP-2025-05', 'EMAIL',  '{"reason": "too_frequent"}',                                  '2025-06-15 14:00:00'),
(10, 15, 'AD_VIEW',       '2025-08-05 07:30:00', 'CAMP-2025-06', 'SEARCH', '{"keyword": "standing desk", "position": 2}',                 '2025-08-05 07:30:00'),
-- Encoding error in payload
(11, 16, 'EMAIL_OPEN',    '2025-09-15 11:00:00', 'CAMP-2025-07', 'EMAIL',  '{"subject": "Fall Collection ' || CHR(0) || '"}',             '2025-09-15 11:00:00'),
(12, 20, 'PAGE_VIEW',     '2025-10-01 13:00:00', 'CAMP-2025-08', 'WEB',    '{"page": "/checkout", "duration_seconds": 120}',              '2025-10-01 13:00:00');


-- =============================================================================
-- Verify setup
-- =============================================================================

SELECT 'CUSTOMERS'          AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL
SELECT 'PRODUCTS',                         COUNT(*)              FROM PRODUCTS
UNION ALL
SELECT 'ORDERS',                           COUNT(*)              FROM ORDERS
UNION ALL
SELECT 'ORDER_ITEMS',                      COUNT(*)              FROM ORDER_ITEMS
UNION ALL
SELECT 'PRODUCT_REVIEWS',                  COUNT(*)              FROM PRODUCT_REVIEWS
UNION ALL
SELECT 'SUPPLIER_CONTRACTS',               COUNT(*)              FROM SUPPLIER_CONTRACTS
UNION ALL
SELECT 'INVENTORY_SNAPSHOTS',              COUNT(*)              FROM INVENTORY_SNAPSHOTS
UNION ALL
SELECT 'MARKETING_EVENTS',                 COUNT(*)              FROM MARKETING_EVENTS
ORDER BY table_name;
