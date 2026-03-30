-- =============================================================================
-- AI-Ready Data Assessment — Scan + Agents Demo Setup
-- Target: SNOWFLAKE_LEARNING_DB (3 schemas)
--
-- Creates three schemas with intentionally different data readiness levels
-- for demonstrating the estate scan → deep assessment → remediation flow.
--
-- SCAN_ANALYTICS  — Well-governed analytics data (high readiness)
--   ✓ Column comments on all columns
--   ✓ Primary keys on all tables
--   ✓ Clustering key on large table
--   ✓ Change tracking enabled
--   ✓ Tags applied
--
-- SCAN_MARKETING  — Partially governed marketing data (medium readiness)
--   ~ Column comments on some columns
--   ~ Primary keys on some tables
--   ~ Change tracking on one table
--   ✗ No clustering keys
--   ✗ No tags
--   ~ PII column (EMAIL) without masking
--
-- SCAN_SUPPORT    — Raw support system data (low readiness)
--   ✗ No column comments
--   ✗ No primary keys or constraints
--   ✗ No clustering keys
--   ✗ No change tracking
--   ✗ No tags
--   ✗ PII columns without masking
--   + Nulls in key columns, duplicate IDs, dates as VARCHAR,
--     out-of-range scores, invalid statuses, invalid JSON,
--     encoding errors, orphan foreign keys, cross-field issues
-- =============================================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;


-- #############################################################################
-- SCHEMA 1: SCAN_ANALYTICS — Well-governed (HIGH readiness)
-- #############################################################################

CREATE SCHEMA IF NOT EXISTS SCAN_ANALYTICS;
USE SCHEMA SCAN_ANALYTICS;

CREATE TAG IF NOT EXISTS DATA_DOMAIN
    ALLOWED_VALUES 'revenue', 'product', 'customer'
    COMMENT = 'Business domain classification for data governance';

-- -----------------------------------------------------------------------------
-- DAILY_REVENUE — 15,000 generated rows, clustered, fully documented
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE DAILY_REVENUE (
    REVENUE_DATE        DATE          NOT NULL  COMMENT 'Business date for the revenue aggregation',
    CHANNEL             VARCHAR(50)   NOT NULL  COMMENT 'Sales channel: WEB, MOBILE, STORE',
    REVENUE_USD         FLOAT         NOT NULL  COMMENT 'Total revenue in USD for the date and channel',
    ORDER_COUNT         NUMBER(38,0)  NOT NULL  COMMENT 'Number of completed orders',
    AVG_ORDER_VALUE_USD FLOAT         NOT NULL  COMMENT 'Average order value in USD (revenue divided by orders)',
    CONSTRAINT PK_DAILY_REVENUE PRIMARY KEY (REVENUE_DATE, CHANNEL)
) COMMENT = 'Daily revenue aggregation by sales channel — source of truth for executive dashboards';

INSERT INTO DAILY_REVENUE
SELECT
    DATEADD(day, -MOD(SEQ4(), 730), CURRENT_DATE())              AS REVENUE_DATE,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'WEB' WHEN 1 THEN 'MOBILE' ELSE 'STORE' END AS CHANNEL,
    ROUND(ABS(MOD(RANDOM(), 50000)) + 1000, 2)                  AS REVENUE_USD,
    ABS(MOD(RANDOM(), 200)) + 10                                 AS ORDER_COUNT,
    ROUND((ABS(MOD(RANDOM(), 300)) + 30), 2)                     AS AVG_ORDER_VALUE_USD
FROM TABLE(GENERATOR(ROWCOUNT => 15000));

ALTER TABLE DAILY_REVENUE CLUSTER BY (REVENUE_DATE);

-- -----------------------------------------------------------------------------
-- PRODUCT_PERFORMANCE — monthly product metrics, fully documented
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE PRODUCT_PERFORMANCE (
    PRODUCT_ID   NUMBER(38,0)  NOT NULL  COMMENT 'Product identifier from the product catalog',
    PRODUCT_NAME VARCHAR(200)  NOT NULL  COMMENT 'Display name of the product',
    PERIOD_MONTH DATE          NOT NULL  COMMENT 'First day of the reporting month',
    UNITS_SOLD   NUMBER(38,0)  NOT NULL  COMMENT 'Total units sold in the period',
    REVENUE_USD  FLOAT         NOT NULL  COMMENT 'Total revenue in USD for the product and period',
    RETURN_RATE  FLOAT         NOT NULL  COMMENT 'Fraction of units returned (0.0–1.0)',
    CONSTRAINT PK_PRODUCT_PERFORMANCE PRIMARY KEY (PRODUCT_ID, PERIOD_MONTH)
) COMMENT = 'Monthly product performance metrics for merchandising analytics';

INSERT INTO PRODUCT_PERFORMANCE VALUES
(101, 'Wireless Headphones', '2025-01-01', 342, 27354.58, 0.02),
(101, 'Wireless Headphones', '2025-02-01', 289, 23109.11, 0.03),
(101, 'Wireless Headphones', '2025-03-01', 415, 33190.85, 0.01),
(102, 'Bluetooth Speaker',   '2025-01-01', 198,  9898.02, 0.04),
(102, 'Bluetooth Speaker',   '2025-02-01', 221, 11044.79, 0.03),
(102, 'Bluetooth Speaker',   '2025-03-01', 256, 12797.44, 0.02),
(103, 'Running Shoes',       '2025-01-01', 567, 73705.33, 0.05),
(103, 'Running Shoes',       '2025-02-01', 432, 56155.68, 0.04),
(103, 'Running Shoes',       '2025-03-01', 389, 50557.11, 0.06),
(107, 'Yoga Mat',            '2025-01-01', 145,  5073.55, 0.01),
(107, 'Yoga Mat',            '2025-02-01', 178,  6228.22, 0.02),
(107, 'Yoga Mat',            '2025-03-01', 201,  7032.99, 0.01),
(110, 'Standing Desk',       '2025-01-01',  45, 20249.55, 0.03),
(110, 'Standing Desk',       '2025-02-01',  52, 23399.48, 0.02),
(110, 'Standing Desk',       '2025-03-01',  38, 17099.62, 0.04);

-- -----------------------------------------------------------------------------
-- CUSTOMER_SEGMENTS — small dimension table, fully documented
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE CUSTOMER_SEGMENTS (
    SEGMENT_ID     NUMBER(38,0)  NOT NULL  COMMENT 'Unique segment identifier',
    SEGMENT_NAME   VARCHAR(100)  NOT NULL  COMMENT 'Human-readable segment label',
    CUSTOMER_COUNT NUMBER(38,0)  NOT NULL  COMMENT 'Number of customers currently in this segment',
    AVG_LTV_USD    FLOAT         NOT NULL  COMMENT 'Average customer lifetime value in USD',
    DESCRIPTION    VARCHAR(500)  NOT NULL  COMMENT 'Business definition of the segment criteria',
    CONSTRAINT PK_CUSTOMER_SEGMENTS PRIMARY KEY (SEGMENT_ID)
) COMMENT = 'Customer segmentation for targeting and lifetime value analysis';

INSERT INTO CUSTOMER_SEGMENTS VALUES
(1, 'High Value', 1250, 4500.00, 'Customers with LTV > $2000 and 3+ orders in the last 12 months'),
(2, 'Growth',     3400, 1200.00, 'Customers with 1-2 orders showing increasing AOV trend'),
(3, 'At Risk',     890,  800.00, 'Previously active customers with no order in 6+ months'),
(4, 'New',        2100,  350.00, 'Customers acquired in the last 90 days'),
(5, 'Dormant',    1560,  200.00, 'No activity in 12+ months — candidates for win-back campaigns');

-- Enable change tracking on all analytics tables
ALTER TABLE DAILY_REVENUE SET CHANGE_TRACKING = TRUE;
ALTER TABLE PRODUCT_PERFORMANCE SET CHANGE_TRACKING = TRUE;
ALTER TABLE CUSTOMER_SEGMENTS SET CHANGE_TRACKING = TRUE;

-- Apply classification tags
ALTER TABLE DAILY_REVENUE SET TAG SCAN_ANALYTICS.DATA_DOMAIN = 'revenue';
ALTER TABLE PRODUCT_PERFORMANCE SET TAG SCAN_ANALYTICS.DATA_DOMAIN = 'product';
ALTER TABLE CUSTOMER_SEGMENTS SET TAG SCAN_ANALYTICS.DATA_DOMAIN = 'customer';


-- #############################################################################
-- SCHEMA 2: SCAN_MARKETING — Partially governed (MEDIUM readiness)
-- #############################################################################

CREATE SCHEMA IF NOT EXISTS SCAN_MARKETING;
USE SCHEMA SCAN_MARKETING;

-- -----------------------------------------------------------------------------
-- CAMPAIGNS — has PK, some comments
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE CAMPAIGNS (
    CAMPAIGN_ID   VARCHAR(50)   NOT NULL  COMMENT 'Unique campaign identifier',
    CAMPAIGN_NAME VARCHAR(200)  NOT NULL  COMMENT 'Display name for internal tracking',
    CHANNEL       VARCHAR(50)   NOT NULL,
    START_DATE    DATE          NOT NULL  COMMENT 'Campaign launch date',
    END_DATE      DATE,
    BUDGET_USD    FLOAT,
    STATUS        VARCHAR(50)   NOT NULL,
    CREATED_AT    TIMESTAMP_NTZ NOT NULL,
    CONSTRAINT PK_CAMPAIGNS PRIMARY KEY (CAMPAIGN_ID)
) COMMENT = 'Marketing campaigns with budget and scheduling metadata';

INSERT INTO CAMPAIGNS VALUES
('CAMP-2025-01', 'New Year Sale',         'EMAIL',  '2025-01-01', '2025-01-31', 15000.00, 'COMPLETED', '2024-12-15 10:00:00'),
('CAMP-2025-02', 'Valentine''s Promo',    'SOCIAL', '2025-02-01', '2025-02-14',  8000.00, 'COMPLETED', '2025-01-20 09:00:00'),
('CAMP-2025-03', 'Spring Collection',     'SOCIAL', '2025-03-01', '2025-03-31', 12000.00, 'COMPLETED', '2025-02-15 14:00:00'),
('CAMP-2025-04', 'Flash Sale',            'WEB',    '2025-04-15', '2025-04-17',  5000.00, 'COMPLETED', '2025-04-01 08:00:00'),
('CAMP-2025-05', 'Customer Appreciation', 'EMAIL',  '2025-05-01', '2025-06-30', 20000.00, 'COMPLETED', '2025-04-20 11:00:00'),
('CAMP-2025-06', 'Back to School',        'SEARCH', '2025-08-01', '2025-08-31', 18000.00, 'ACTIVE',    '2025-07-15 10:30:00'),
('CAMP-2025-07', 'Fall Collection',       'EMAIL',  '2025-09-15', '2025-10-15', 10000.00, 'ACTIVE',    '2025-09-01 09:00:00'),
('CAMP-2025-08', 'Holiday Preview',       'WEB',    '2025-10-01', NULL,         25000.00, 'PLANNED',   '2025-09-15 16:00:00');

-- -----------------------------------------------------------------------------
-- CAMPAIGN_METRICS — no PK, no comments
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE CAMPAIGN_METRICS (
    METRIC_DATE DATE,
    CAMPAIGN_ID VARCHAR(50),
    IMPRESSIONS NUMBER(38,0),
    CLICKS      NUMBER(38,0),
    CONVERSIONS NUMBER(38,0),
    SPEND_USD   FLOAT,
    REVENUE_USD FLOAT
);

INSERT INTO CAMPAIGN_METRICS VALUES
('2025-01-05', 'CAMP-2025-01', 45000, 2250, 180, 1500.00,  8500.00),
('2025-01-15', 'CAMP-2025-01', 52000, 2600, 210, 2000.00, 10200.00),
('2025-01-25', 'CAMP-2025-01', 38000, 1900, 140, 1200.00,  6800.00),
('2025-02-05', 'CAMP-2025-02', 28000, 1680,  95,  800.00,  4200.00),
('2025-02-12', 'CAMP-2025-02', 35000, 2100, 130, 1000.00,  5800.00),
('2025-03-10', 'CAMP-2025-03', 62000, 3100, 220, 1800.00, 11000.00),
('2025-03-20', 'CAMP-2025-03', 58000, 2900, 195, 1600.00,  9500.00),
('2025-04-16', 'CAMP-2025-04', 95000, 5700, 450, 2500.00, 22000.00),
('2025-05-15', 'CAMP-2025-05', 40000, 2000, 160, 1500.00,  7200.00),
('2025-06-01', 'CAMP-2025-05', 42000, 2100, 170, 1600.00,  7800.00),
('2025-08-10', 'CAMP-2025-06', 72000, 3600, 280, 2200.00, 14000.00),
('2025-08-20', 'CAMP-2025-06', 68000, 3400, 260, 2000.00, 13200.00);

-- -----------------------------------------------------------------------------
-- SUBSCRIBERS — has PK, has comment, has PII (EMAIL) without masking
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE SUBSCRIBERS (
    SUBSCRIBER_ID NUMBER(38,0)  NOT NULL,
    EMAIL         VARCHAR(255)  NOT NULL,
    FIRST_NAME    VARCHAR(100),
    SUBSCRIBED_AT TIMESTAMP_NTZ NOT NULL,
    PREFERENCES   VARCHAR(500),
    IS_ACTIVE     BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_SUBSCRIBERS PRIMARY KEY (SUBSCRIBER_ID)
) COMMENT = 'Email marketing subscriber list';

INSERT INTO SUBSCRIBERS VALUES
(1,  'alice@example.com', 'Alice', '2024-06-01 10:00:00', 'electronics,apparel', TRUE),
(2,  'bob@example.com',   'Bob',   '2024-07-15 14:00:00', 'sports',              TRUE),
(3,  'carol@example.com', 'Carol', '2024-08-20 09:30:00', NULL,                  TRUE),
(4,  'david@example.com', 'David', '2024-09-10 11:00:00', 'electronics,home',    FALSE),
(5,  'eve@example.com',   'Eve',   '2024-10-05 16:00:00', 'grocery,accessories', TRUE),
(6,  'frank@example.com', 'Frank', '2024-11-12 08:45:00', NULL,                  TRUE),
(7,  'grace@example.com', 'Grace', '2024-12-01 13:20:00', 'apparel,sports',      TRUE),
(8,  'henry@example.com', 'Henry', '2025-01-18 10:30:00', 'electronics',         TRUE),
(9,  'iris@example.com',  'Iris',  '2025-02-25 15:00:00', 'home,grocery',        TRUE),
(10, 'jack@example.com',  'Jack',  '2025-03-30 09:00:00', NULL,                  TRUE);

-- Only one table has change tracking
ALTER TABLE CAMPAIGNS SET CHANGE_TRACKING = TRUE;


-- #############################################################################
-- SCHEMA 3: SCAN_SUPPORT — Raw data (LOW readiness, agents drill-down target)
--
-- Customer support / helpdesk system with intentional data quality issues
-- across all six assessment factors.
-- #############################################################################

CREATE SCHEMA IF NOT EXISTS SCAN_SUPPORT;
USE SCHEMA SCAN_SUPPORT;

-- -----------------------------------------------------------------------------
-- CUSTOMERS — PII, duplicates, encoding errors, NULLs
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID NUMBER(38,0),
    FULL_NAME   VARCHAR(200),
    EMAIL       VARCHAR(255),
    PHONE       VARCHAR(50),
    PLAN        VARCHAR(50),
    ADDRESS     VARCHAR(500),
    CITY        VARCHAR(100),
    COUNTRY     VARCHAR(100),
    CREATED_AT  TIMESTAMP_NTZ,
    UPDATED_AT  TIMESTAMP_NTZ
);

INSERT INTO CUSTOMERS VALUES
(1,  'Alice Johnson',    'alice.j@example.com',   '555-0101', 'PREMIUM',  '123 Main St',      'Seattle',       'US', '2024-01-15 08:30:00', '2025-11-01 10:00:00'),
(2,  'Bob Smith',        'bob.s@example.com',     '555-0102', 'BASIC',    '456 Oak Ave',       'Portland',      'US', '2024-02-20 14:15:00', '2025-10-15 09:30:00'),
(3,  'Carol Williams',   NULL,                    '555-0103', 'PREMIUM',  '789 Pine Rd',       'San Francisco', 'US', '2024-03-10 11:45:00', '2025-09-20 16:45:00'),
(4,  'David Brown',      'david.b@example.com',   '555-0104', 'BASIC',    '321 Elm Blvd',      'Denver',        'US', '2024-04-05 09:00:00', '2025-12-01 08:00:00'),
(5,  'Eve Davis',        'eve.d@example.com',     NULL,       'PREMIUM',  '654 Cedar Ln',      'Austin',        'US', '2024-05-12 16:30:00', '2025-11-10 14:20:00'),
(6,  'Frank Miller',     'frank.m@example.com',   '555-0106', 'BASIC',    '987 Birch Dr',      'Chicago',       'US', '2024-06-18 10:00:00', '2025-10-05 11:15:00'),
(7,  'Grace Wilson',     NULL,                    '555-0107', 'ENTERPRISE','147 Maple Way',     'Miami',         'US', '2024-07-22 13:20:00', '2025-11-20 17:00:00'),
(8,  'Henry Moore',      'henry.m@example.com',   '555-0108', 'BASIC',    '258 Walnut Ct',     'Boston',        'US', '2024-08-30 07:45:00', '2025-09-01 12:30:00'),
(9,  'Iris Taylor',      'iris.t@example.com',    '555-0109', 'PREMIUM',  NULL,                'Nashville',     'US', '2024-09-14 15:10:00', '2025-12-10 09:00:00'),
(10, 'Jack Anderson',    'jack.a@example.com',    '555-0110', 'BASIC',    '369 Spruce Pl',     'Phoenix',       'US', '2024-10-01 12:00:00', '2025-11-25 10:45:00'),
(11, 'Karen Thomas',     NULL,                    '555-0111', 'PREMIUM',  '741 Poplar St',     'Philadelphia',  'US', '2024-10-15 09:30:00', '2025-10-20 15:00:00'),
(12, 'Leo Jackson',      'leo.j@example.com',     '555-0112', 'BASIC',    '852 Ash Ave',       'San Diego',     'US', '2024-11-03 14:00:00', '2025-11-30 08:20:00'),
(13, 'Mia White',        'mia.w@example.com',     '555-0113', 'ENTERPRISE','963 Fir Blvd',     'Dallas',        'US', '2024-11-20 11:30:00', '2025-12-05 13:45:00'),
(14, 'Noah Harris',      NULL,                    NULL,       'BASIC',    '159 Redwood Rd',    'Atlanta',       'US', '2024-12-01 08:15:00', '2025-10-10 16:30:00'),
(15, 'Olivia Martin',    'olivia.m@example.com',  '555-0115', 'PREMIUM',  '753 Sycamore Ln',   'Minneapolis',   'US', '2024-12-18 16:45:00', '2025-11-15 07:50:00'),

-- Duplicates (same CUSTOMER_ID)
(1,  'Alice Johnson',    'alice.j@example.com',   '555-0101', 'PREMIUM',  '123 Main St',      'Seattle',       'US', '2024-01-15 08:30:00', '2025-11-01 10:00:00'),
(2,  'Bob Smith',        'bob.s@example.com',     '555-0102', 'BASIC',    '456 Oak Ave',       'Portland',      'US', '2024-02-20 14:15:00', '2025-10-15 09:30:00');

-- Encoding error in one customer name
UPDATE CUSTOMERS SET FULL_NAME = 'David Br' || CHR(65533) || 'wn'
WHERE CUSTOMER_ID = 4 AND CITY = 'Denver';

-- -----------------------------------------------------------------------------
-- SUPPORT_AGENTS — PII (email, phone), NULLs, encoding error
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE SUPPORT_AGENTS (
    AGENT_ID   NUMBER(38,0),
    FIRST_NAME VARCHAR(100),
    LAST_NAME  VARCHAR(100),
    EMAIL      VARCHAR(255),
    PHONE      VARCHAR(50),
    TEAM       VARCHAR(100),
    HIRE_DATE  DATE,
    IS_ACTIVE  BOOLEAN,
    CREATED_AT TIMESTAMP_NTZ,
    UPDATED_AT TIMESTAMP_NTZ
);

INSERT INTO SUPPORT_AGENTS VALUES
(101, 'Sarah',   'Chen',     'sarah.c@company.com',   '555-9001', 'Tier 1',     '2023-03-15', TRUE,  '2023-03-15 00:00:00', '2025-10-01 00:00:00'),
(102, 'Mike',    'Patel',    'mike.p@company.com',    '555-9002', 'Tier 1',     '2023-06-01', TRUE,  '2023-06-01 00:00:00', '2025-09-15 00:00:00'),
(103, 'Jenny',   'Rodriguez','jenny.r@company.com',   '555-9003', 'Tier 2',     '2022-11-20', TRUE,  '2022-11-20 00:00:00', '2025-11-01 00:00:00'),
(104, 'Alex',    'Kim',      NULL,                    '555-9004', 'Tier 2',     '2024-01-10', TRUE,  '2024-01-10 00:00:00', '2025-10-15 00:00:00'),
(105, 'Taylor',  'O''Brien', 'taylor.o@company.com',  NULL,       'Escalation', '2021-08-05', TRUE,  '2021-08-05 00:00:00', '2025-11-20 00:00:00'),
(106, 'Jordan',  'Lee',      'jordan.l@company.com',  '555-9006', 'Tier 1',     '2024-06-15', FALSE, '2024-06-15 00:00:00', '2025-08-01 00:00:00');

-- Encoding error in one agent name
UPDATE SUPPORT_AGENTS SET LAST_NAME = 'O' || CHR(65533) || 'Brien' WHERE AGENT_ID = 105;

-- -----------------------------------------------------------------------------
-- TICKETS — dates as VARCHAR, NULLs, duplicates, orphan customer/agent refs,
--           invalid statuses, out-of-range satisfaction scores, encoding errors
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE TICKETS (
    TICKET_ID          NUMBER(38,0),
    CUSTOMER_ID        NUMBER(38,0),
    AGENT_ID           NUMBER(38,0),
    CREATED_DATE       VARCHAR(30),
    RESOLVED_DATE      VARCHAR(30),
    STATUS             VARCHAR(50),
    PRIORITY           VARCHAR(20),
    CHANNEL            VARCHAR(50),
    CATEGORY           VARCHAR(100),
    SUBJECT            VARCHAR(500),
    DESCRIPTION        VARCHAR(4000),
    SATISFACTION_SCORE FLOAT,
    CREATED_AT         TIMESTAMP_NTZ,
    UPDATED_AT         TIMESTAMP_NTZ
);

INSERT INTO TICKETS VALUES
(5001, 1,  101, '2025-01-05 09:00', '2025-01-05 11:30', 'RESOLVED',    'HIGH',   'EMAIL', 'Billing',   'Charged twice for order',            'I was charged twice for my recent order. Please refund the duplicate charge.',    5,    '2025-01-05 09:00:00', '2025-01-05 11:30:00'),
(5002, 2,  102, '2025-01-08 14:00', '2025-01-09 10:00', 'RESOLVED',    'MEDIUM', 'CHAT',  'Shipping',  'Package not delivered',               'My package shows delivered but I never received it. Tracking: TRK-88291.',       4,    '2025-01-08 14:00:00', '2025-01-09 10:00:00'),
(5003, 3,  101, '2025-01-12 10:30', '2025-01-12 16:00', 'RESOLVED',    'LOW',    'EMAIL', 'Product',   'Product does not match description',  'The color of the jacket is different from the listing photo.',                    3,    '2025-01-12 10:30:00', '2025-01-12 16:00:00'),
(5004, 4,  103, '2025-01-20 08:00', '2025-01-22 09:00', 'RESOLVED',    'HIGH',   'PHONE', 'Account',   'Cannot reset password',               'I have tried resetting my password three times. The link does not work.',         4,    '2025-01-20 08:00:00', '2025-01-22 09:00:00'),
(5005, 5,  NULL,'2025-02-01 11:00', NULL,                'OPEN',        'MEDIUM', 'CHAT',  'Billing',   NULL,                                  'I need to update my credit card on file.',                                       NULL, '2025-02-01 11:00:00', '2025-02-01 11:00:00'),
(5006, 6,  104, '2025-02-10 13:00', '2025-02-10 14:00', 'RESOLVED',    'LOW',    'EMAIL', 'Product',   'Missing assembly instructions',        'The standing desk arrived without assembly instructions.',                       5,    '2025-02-10 13:00:00', '2025-02-10 14:00:00'),
(5007, 7,  102, '2025-02-18 09:30', '2025-02-20 16:00', 'RESOLVED',    'HIGH',   'PHONE', 'Returns',   'Defective headphones',                'Left ear stopped working after two weeks. Requesting replacement.',              2,    '2025-02-18 09:30:00', '2025-02-20 16:00:00'),
(5008, 8,  105, '2025-03-01 10:00', NULL,                'IN_PROGRESS', 'MEDIUM', 'EMAIL', 'Shipping',  'Order delayed',                       'My order has been in processing for 10 days. When will it ship?',                NULL, '2025-03-01 10:00:00', '2025-03-05 08:00:00'),
(5009, 9,  101, '2025-03-10 14:30', '2025-03-10 15:00', 'RESOLVED',    'LOW',    'CHAT',  'General',   'How to track my order',               'Where can I find the tracking number for my recent order?',                      5,    '2025-03-10 14:30:00', '2025-03-10 15:00:00'),
(5010, 10, 103, '2025-03-15 08:00', '2025-03-18 11:00', 'RESOLVED',    'HIGH',   'PHONE', 'Billing',   'Refund not received',                 'I returned my order two weeks ago and still have not received the refund.',      1,    '2025-03-15 08:00:00', '2025-03-18 11:00:00'),
(5011, 11, 104, '2025-04-01 09:00', '2025-04-02 10:00', 'RESOLVED',    'MEDIUM', 'EMAIL', 'Product',   'Wrong item received',                 'I ordered a yoga mat but received a dumbbell set instead.',                      3,    '2025-04-01 09:00:00', '2025-04-02 10:00:00'),
(5012, 12, NULL,'2025-04-10 15:00', NULL,                'OPEN',        'LOW',    'CHAT',  'General',   'Loyalty points inquiry',              NULL,                                                                             NULL, '2025-04-10 15:00:00', '2025-04-10 15:00:00'),
(5013, 1,  102, '2025-04-20 11:00', '2025-04-20 13:00', 'RESOLVED',    'MEDIUM', 'EMAIL', 'Returns',   'Return label not working',            'The return shipping label shows an error when I try to print it.',               4,    '2025-04-20 11:00:00', '2025-04-20 13:00:00'),
(5014, 3,  105, '2025-05-01 10:00', '2025-05-03 09:00', 'RESOLVED',    'HIGH',   'PHONE', 'Account',   'Account locked',                      'My account was locked after too many login attempts.',                           3,    '2025-05-01 10:00:00', '2025-05-03 09:00:00'),
(5015, 14, 101, '2025-05-12 08:30', NULL,                'ESCALATED',   'HIGH',   'PHONE', 'Billing',   'Unauthorized charges',                'There are charges on my account that I did not make. Possible fraud.',           NULL, '2025-05-12 08:30:00', '2025-05-12 08:30:00'),
(5016, 15, 103, '2025-05-20 14:00', '2025-05-21 10:00', 'RESOLVED',    'MEDIUM', 'CHAT',  'Shipping',  'Change shipping address',             'I need to change the shipping address for order 1015.',                          5,    '2025-05-20 14:00:00', '2025-05-21 10:00:00'),
(5017, 2,  104, '2025-06-01 09:00', '2025-06-01 11:00', 'RESOLVED',    'LOW',    'EMAIL', 'Product',   'Product care instructions',           'How do I clean my leather backpack without damaging it?',                        5,    '2025-06-01 09:00:00', '2025-06-01 11:00:00'),
(5018, 6,  102, '2025-06-15 13:30', NULL,                'IN_PROGRESS', 'MEDIUM', 'PHONE', 'Returns',   'Return window extension',             'I am past the 30-day return window but the item is defective.',                  NULL, '2025-06-15 13:30:00', '2025-06-15 13:30:00'),

-- Duplicate tickets (same TICKET_ID — tests uniqueness)
(5001, 1,  101, '2025-01-05 09:00', '2025-01-05 11:30', 'RESOLVED',    'HIGH',   'EMAIL', 'Billing',   'Charged twice for order',            'I was charged twice for my recent order. Please refund the duplicate charge.',    5,    '2025-01-05 09:00:00', '2025-01-05 11:30:00'),
(5002, 2,  102, '2025-01-08 14:00', '2025-01-09 10:00', 'RESOLVED',    'MEDIUM', 'CHAT',  'Shipping',  'Package not delivered',               'My package shows delivered but I never received it. Tracking: TRK-88291.',       4,    '2025-01-08 14:00:00', '2025-01-09 10:00:00'),

-- Orphan customer references (customer_id 999/998 not in CUSTOMERS)
(5019, 999, 101, '2025-07-01 10:00', '2025-07-01 12:00', 'RESOLVED',   'LOW',    'EMAIL', 'General',   'Orphan customer ticket',              'This customer does not exist in the customers table.',                           3,    '2025-07-01 10:00:00', '2025-07-01 12:00:00'),
(5020, 998, NULL,'2025-07-10 14:00', NULL,                'OPEN',        'MEDIUM', 'CHAT',  'Billing',   NULL,                                  'Another orphan customer reference.',                                             NULL, '2025-07-10 14:00:00', '2025-07-10 14:00:00'),

-- Invalid statuses
(5021, 13, 103, '2025-07-20 09:00', NULL,                'YOLO',        'HIGH',   'EMAIL', 'Product',   'Status test',                         'This ticket has an invalid status value.',                                       NULL, '2025-07-20 09:00:00', '2025-07-20 09:00:00'),
(5022, 5,  104, '2025-08-01 11:00', NULL,                'WAT',         'LOW',    'CHAT',  'General',   NULL,                                  'Another invalid status.',                                                        NULL, '2025-08-01 11:00:00', '2025-08-01 11:00:00'),

-- Out-of-range satisfaction scores
(5023, 8,  101, '2025-08-10 09:00', '2025-08-10 10:00', 'RESOLVED',    'LOW',    'EMAIL', 'General',   'Quick question',                      'Just a quick question about my account.',                                        -1,   '2025-08-10 09:00:00', '2025-08-10 10:00:00'),
(5024, 10, 103, '2025-08-15 14:00', '2025-08-15 15:30', 'RESOLVED',    'MEDIUM', 'CHAT',  'Product',   'Size guide request',                  'Where can I find the size guide for running shoes?',                             11,   '2025-08-15 14:00:00', '2025-08-15 15:30:00');

-- Encoding errors (inject into non-duplicate rows)
UPDATE TICKETS SET SUBJECT = 'Cannot reset p' || CHR(65533) || 'ssword'
WHERE TICKET_ID = 5004;
UPDATE TICKETS SET DESCRIPTION = 'My order has been in proc' || CHR(0) || 'essing for 10 days.'
WHERE TICKET_ID = 5008;

-- -----------------------------------------------------------------------------
-- TICKET_MESSAGES — NULLs, encoding errors, orphan ticket refs, invalid JSON
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE TICKET_MESSAGES (
    MESSAGE_ID    NUMBER(38,0),
    TICKET_ID     NUMBER(38,0),
    SENDER_TYPE   VARCHAR(20),
    MESSAGE_TEXT  VARCHAR(4000),
    METADATA_JSON VARCHAR(4000),
    CREATED_AT    TIMESTAMP_NTZ
);

INSERT INTO TICKET_MESSAGES VALUES
(1,  5001, 'CUSTOMER', 'I was charged twice for my order. Please help.',                        '{"channel": "email", "automated": false}',             '2025-01-05 09:00:00'),
(2,  5001, 'AGENT',    'I can see the duplicate charge. Initiating refund now.',                 '{"channel": "email", "automated": false}',             '2025-01-05 09:45:00'),
(3,  5001, 'SYSTEM',   'Refund of $79.99 processed. Reference: REF-20250105-001.',              '{"channel": "system", "automated": true}',             '2025-01-05 10:30:00'),
(4,  5002, 'CUSTOMER', 'My package says delivered but it is not here.',                          '{"channel": "chat", "automated": false}',              '2025-01-08 14:00:00'),
(5,  5002, 'AGENT',    'I have opened an investigation with the carrier.',                       '{"channel": "chat", "automated": false}',              '2025-01-08 14:15:00'),
(6,  5003, 'CUSTOMER', 'The jacket color is completely different from the photo.',                '{"channel": "email", "automated": false}',             '2025-01-12 10:30:00'),
(7,  5003, 'AGENT',    'I apologize. We will send a prepaid return label.',                      '{"channel": "email", "automated": false}',             '2025-01-12 11:00:00'),
(8,  5004, 'CUSTOMER', 'Password reset is broken.',                                              '{"channel": "phone", "automated": false}',             '2025-01-20 08:00:00'),
(9,  5004, 'AGENT',    'I have manually reset your password. You should receive an email soon.',  '{"channel": "phone", "automated": false}',             '2025-01-20 08:30:00'),
(10, 5005, 'CUSTOMER', 'Need to update my payment method.',                                      '{"channel": "chat", "automated": false}',              '2025-02-01 11:00:00'),
(11, 5007, 'CUSTOMER', 'Left earphone is dead.',                                                 '{"channel": "phone", "automated": false}',             '2025-02-18 09:30:00'),
(12, 5007, 'AGENT',    'We will send a replacement unit via express shipping.',                   '{"channel": "phone", "automated": false}',             '2025-02-18 10:00:00'),
(13, 5008, 'CUSTOMER', 'Still waiting for my order to ship.',                                    NULL,                                                    '2025-03-01 10:00:00'),
(14, 5008, 'AGENT',    NULL,                                                                     '{"channel": "email", "automated": false}',             '2025-03-03 09:00:00'),
(15, 5010, 'CUSTOMER', 'Where is my refund?',                                                    '{"channel": "phone", "automated": false}',             '2025-03-15 08:00:00'),
(16, 5010, 'AGENT',    'Refund takes 5-7 business days. I see it was processed on March 3rd.',   '{"channel": "phone", "automated": false}',             '2025-03-15 08:20:00'),
(17, 5012, 'CUSTOMER', 'How many loyalty points do I have?',                                     '{"channel": "chat", "automated": false}',              '2025-04-10 15:00:00'),
(18, 5015, 'CUSTOMER', 'I did not authorize these charges!',                                     '{"channel": "phone", "automated": false}',             '2025-05-12 08:30:00'),
(19, 5015, 'AGENT',    'I am escalating this to our fraud investigation team immediately.',       '{"channel": "phone", "automated": false}',             '2025-05-12 08:45:00'),

-- Invalid JSON
(20, 5011, 'SYSTEM',   'Replacement item shipped.',                                              '{"channel": "system", "automated": true, status: "shipped"}', '2025-04-02 09:00:00'),
(21, 5017, 'AGENT',    'Here are the care instructions for leather products.',                    '{channel: email}',                                    '2025-06-01 09:30:00'),

-- NULL message
(22, 5018, 'AGENT',    NULL,                                                                     NULL,                                                    '2025-06-15 14:00:00'),

-- Orphan ticket ref (ticket 9999 does not exist)
(23, 9999, 'SYSTEM',   'Auto-generated message for nonexistent ticket.',                          '{"channel": "system", "automated": true}',             '2025-07-15 00:00:00');

-- Encoding error in a message
UPDATE TICKET_MESSAGES SET MESSAGE_TEXT = 'Left e' || CHR(65533) || 'rphone is dead.'
WHERE MESSAGE_ID = 11;

-- -----------------------------------------------------------------------------
-- KNOWLEDGE_BASE — VARCHAR JSON, invalid JSON, NULLs, bad categories
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE KNOWLEDGE_BASE (
    ARTICLE_ID    NUMBER(38,0),
    TITLE         VARCHAR(500),
    BODY          VARCHAR(16000),
    CATEGORY      VARCHAR(100),
    TAGS_JSON     VARCHAR(4000),
    VIEW_COUNT    FLOAT,
    HELPFUL_VOTES FLOAT,
    CREATED_AT    TIMESTAMP_NTZ,
    UPDATED_AT    TIMESTAMP_NTZ
);

INSERT INTO KNOWLEDGE_BASE VALUES
(1, 'How to track your order',              'Log into your account and navigate to Order History. Click on the order number to see tracking details.', 'Shipping',      '{"tags": ["tracking", "orders", "shipping"]}',        1250, 342, '2024-06-01 00:00:00', '2025-08-15 00:00:00'),
(2, 'Return policy overview',               'Items can be returned within 30 days of delivery. Items must be in original condition with tags attached.', 'Returns',    '{"tags": ["returns", "policy", "refunds"]}',           2100, 567, '2024-06-15 00:00:00', '2025-09-01 00:00:00'),
(3, 'How to reset your password',           'Click Forgot Password on the login page. Enter your email and follow the instructions in the reset email.', 'Account',   '{"tags": ["password", "account", "security"]}',        3400, 890, '2024-07-01 00:00:00', '2025-10-01 00:00:00'),
(4, 'Payment methods accepted',             'We accept Visa, Mastercard, American Express, PayPal, and Apple Pay.',                                      'Billing',   '{"tags": ["payment", "billing", "methods"]}',           800, 201, '2024-07-15 00:00:00', '2025-07-15 00:00:00'),
(5, 'Shipping times by region',             NULL,                                                                                                         'Shipping',  '{"tags": ["shipping", "delivery", "times"]}',           650, 178, '2024-08-01 00:00:00', '2025-06-01 00:00:00'),
(6, 'How to contact support',               'You can reach us via email, phone, or live chat. See our contact page for hours and details.',              'General',    '{"tags": ["contact", "support", "help"]}',              950, 256, '2024-08-15 00:00:00', '2025-11-01 00:00:00'),
(7, 'Product warranty information',          'Most products come with a 1-year manufacturer warranty. Electronics carry a 2-year extended warranty.',    'Product',    '{"tags": ["warranty", "product", "coverage"]}',         420, 134, '2024-09-01 00:00:00', '2025-05-01 00:00:00'),
(8, 'Loyalty program FAQ',                  'Earn 1 point per dollar spent. Points can be redeemed at checkout. 100 points = $1 discount.',             'General',    '{"tags": ["loyalty", "points", "rewards"]}',           1800, 445, '2024-09-15 00:00:00', '2025-10-15 00:00:00'),

-- Invalid JSON
(9, 'Size guide for apparel',               'Refer to the size chart on each product page. Measurements are in inches.',                                 'Product',    '{"tags": ["sizing", "apparel", fit]}',                  300,  89, '2024-10-01 00:00:00', '2025-04-01 00:00:00'),
(10,'International shipping',               'We ship to 40+ countries. Duties and taxes are the responsibility of the buyer.',                           'Shipping',    NULL,                                                    550, 145, '2024-10-15 00:00:00', '2025-08-01 00:00:00'),

-- Invalid category
(11,'Troubleshooting Bluetooth devices',    'Ensure Bluetooth is enabled on your device. Remove the pairing and re-pair.',                               'MISC_JUNK',  '{"tags": ["bluetooth", "troubleshoot"]}',                200,  45, '2024-11-01 00:00:00', '2025-03-01 00:00:00'),
(12,'Bulk order discounts',                  NULL,                                                                                                        'DEPRECATED', '{"tags": ["bulk", "discount"]}',                          75,  12, '2024-11-15 00:00:00', '2025-02-01 00:00:00');

-- -----------------------------------------------------------------------------
-- SLA_DEFINITIONS — cross-field issue (end_date < start_date)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE SLA_DEFINITIONS (
    SLA_ID                  NUMBER(38,0),
    PRIORITY                VARCHAR(20),
    TARGET_RESPONSE_HOURS   NUMBER(38,0),
    TARGET_RESOLUTION_HOURS NUMBER(38,0),
    EFFECTIVE_START         DATE,
    EFFECTIVE_END           DATE,
    STATUS                  VARCHAR(50),
    CREATED_AT              TIMESTAMP_NTZ
);

INSERT INTO SLA_DEFINITIONS VALUES
(1, 'HIGH',     1,   4,  '2024-01-01', '2025-12-31', 'ACTIVE',   '2024-01-01 00:00:00'),
(2, 'MEDIUM',   4,  24,  '2024-01-01', '2025-12-31', 'ACTIVE',   '2024-01-01 00:00:00'),
(3, 'LOW',      8,  72,  '2024-01-01', '2025-12-31', 'ACTIVE',   '2024-01-01 00:00:00'),
(4, 'CRITICAL', 0,   2,  '2024-06-01', '2025-12-31', 'ACTIVE',   '2024-06-01 00:00:00'),
-- Cross-field issue: effective_end before effective_start
(5, 'HIGH',     1,   4,  '2025-07-01', '2025-01-31', 'INACTIVE', '2025-07-01 00:00:00');

-- -----------------------------------------------------------------------------
-- TICKET_EVENTS — 15,000 generated rows, no clustering key
-- Triggers access_optimization failure for large table without clustering
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE TICKET_EVENTS (
    EVENT_ID        NUMBER(38,0),
    TICKET_ID       NUMBER(38,0),
    EVENT_TYPE      VARCHAR(50),
    EVENT_TIMESTAMP TIMESTAMP_NTZ,
    AGENT_ID        NUMBER(38,0),
    DETAILS         VARCHAR(4000),
    CREATED_AT      TIMESTAMP_NTZ
);

INSERT INTO TICKET_EVENTS
SELECT
    SEQ4()                                                                     AS EVENT_ID,
    5001 + MOD(SEQ4(), 24)                                                     AS TICKET_ID,
    CASE MOD(SEQ4(), 6)
        WHEN 0 THEN 'CREATED'
        WHEN 1 THEN 'ASSIGNED'
        WHEN 2 THEN 'COMMENTED'
        WHEN 3 THEN 'STATUS_CHANGE'
        WHEN 4 THEN 'ESCALATED'
        ELSE 'RESOLVED'
    END                                                                        AS EVENT_TYPE,
    DATEADD(minute, MOD(SEQ4(), 525600), '2024-01-01 00:00:00'::TIMESTAMP_NTZ) AS EVENT_TIMESTAMP,
    101 + MOD(SEQ4(), 6)                                                       AS AGENT_ID,
    '{"event": "' || CASE MOD(SEQ4(), 6)
        WHEN 0 THEN 'created'
        WHEN 1 THEN 'assigned'
        WHEN 2 THEN 'commented'
        WHEN 3 THEN 'status_change'
        WHEN 4 THEN 'escalated'
        ELSE 'resolved'
    END || '", "seq": ' || SEQ4()::VARCHAR || '}'                              AS DETAILS,
    DATEADD(minute, MOD(SEQ4(), 525600), '2024-01-01 00:00:00'::TIMESTAMP_NTZ) AS CREATED_AT
FROM TABLE(GENERATOR(ROWCOUNT => 15000));


-- =============================================================================
-- Verify setup
-- =============================================================================

SELECT 'SCAN_ANALYTICS' AS schema_name, table_name, row_count
FROM SNOWFLAKE_LEARNING_DB.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'SCAN_ANALYTICS' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'SCAN_MARKETING', table_name, row_count
FROM SNOWFLAKE_LEARNING_DB.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'SCAN_MARKETING' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'SCAN_SUPPORT', table_name, row_count
FROM SNOWFLAKE_LEARNING_DB.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'SCAN_SUPPORT' AND table_type = 'BASE TABLE'
ORDER BY schema_name, table_name;
