-- =============================================================================
-- AI-Ready Data Assessment — Snowflake Test Harness: Setup
-- =============================================================================
-- Creates the AI_READY_TEST schema with controlled fixtures exercising all
-- requirement factors (Clean, Contextual, Consumable, Current, Correlated,
-- Compliant). Each table is designed with deterministic data so that check
-- queries return predictable scores.
--
-- Run with: snow sql -f setup.sql -d <YOUR_DATABASE> [-c <connection>]
-- =============================================================================

DROP SCHEMA IF EXISTS AI_READY_TEST CASCADE;
CREATE SCHEMA AI_READY_TEST;
USE SCHEMA AI_READY_TEST;

-- =============================================================================
-- CLEAN factor fixtures
-- =============================================================================

-- ---- data_completeness ----
-- 100 rows: value_col 90 non-null / 10 null, all_null_col all null
CREATE TABLE test_completeness (
    id INT AUTOINCREMENT,
    value_col VARCHAR,
    all_null_col VARCHAR
);
INSERT INTO test_completeness (value_col, all_null_col)
SELECT
    CASE WHEN g <= 90 THEN 'val_' || g ELSE NULL END,
    NULL
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- ---- uniqueness ----
-- 100 rows: 95 unique (key_a, key_b) combos, 5 duplicates
CREATE TABLE test_uniqueness (
    id INT AUTOINCREMENT,
    key_a INT NOT NULL,
    key_b INT NOT NULL
);
INSERT INTO test_uniqueness (key_a, key_b)
SELECT g, g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 95)));
INSERT INTO test_uniqueness (key_a, key_b)
SELECT g, g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 5)));

-- ---- encoding_validity ----
-- 100 text rows: 97 clean, 3 with U+FFFD replacement character
CREATE TABLE test_encoding (
    id INT AUTOINCREMENT,
    content VARCHAR NOT NULL
);
INSERT INTO test_encoding (content)
SELECT 'Clean text content row ' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 97)));
INSERT INTO test_encoding (content)
SELECT 'Garbled text ' || CHR(65533) || ' row ' || (97 + g)
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 3)));

-- ---- syntactic_validity ----
-- 100 rows: 95 valid JSON, 5 malformed
CREATE TABLE test_syntactic (
    id INT AUTOINCREMENT,
    payload VARCHAR NOT NULL
);
INSERT INTO test_syntactic (payload)
SELECT '{"key": "value_' || g || '", "num": ' || g || '}'
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 95)));
INSERT INTO test_syntactic (payload)
SELECT '{invalid json ' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 5)));

-- ---- value_range_validity ----
-- 100 rows: 90 within [0,100], 10 outside
CREATE TABLE test_range (
    id INT AUTOINCREMENT,
    amount NUMBER NOT NULL
);
INSERT INTO test_range (amount)
SELECT g * 1.0
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 90)));
INSERT INTO test_range (amount)
SELECT -10.0 * g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 5)));
INSERT INTO test_range (amount)
SELECT 100.0 + (20.0 * g)
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 5)));

-- ---- categorical_validity ----
-- 100 rows: 92 valid, 8 invalid
CREATE TABLE test_categorical (
    id INT AUTOINCREMENT,
    status VARCHAR NOT NULL
);
INSERT INTO test_categorical (status)
SELECT CASE
    WHEN MOD(g, 3) = 0 THEN 'active'
    WHEN MOD(g, 3) = 1 THEN 'inactive'
    ELSE 'pending'
END
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 92)));
INSERT INTO test_categorical (status)
SELECT 'invalid_status_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 8)));

-- ---- referential_integrity ----
-- Parent with IDs 1-20, child with 95 valid + 5 orphans (no FK constraint)
CREATE TABLE test_ref_integrity_parent (
    id INT PRIMARY KEY
);
INSERT INTO test_ref_integrity_parent (id)
SELECT g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 20)));

CREATE TABLE test_ref_integrity_child (
    id INT AUTOINCREMENT,
    parent_id INT NOT NULL
);
INSERT INTO test_ref_integrity_child (parent_id)
SELECT MOD(g - 1, 20) + 1
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 95)));
INSERT INTO test_ref_integrity_child (parent_id)
SELECT 100 + g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 5)));

-- ---- cross_column_consistency ----
-- 100 rows: 90 where start_date <= end_date, 10 violated
CREATE TABLE test_cross_column (
    id INT AUTOINCREMENT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);
INSERT INTO test_cross_column (start_date, end_date)
SELECT
    DATEADD(day, g, '2024-01-01'::DATE),
    DATEADD(day, g + 30, '2024-01-01'::DATE)
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 90)));
INSERT INTO test_cross_column (start_date, end_date)
SELECT
    DATEADD(day, g, '2024-06-01'::DATE),
    '2024-01-01'::DATE
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 10)));

-- =============================================================================
-- CONTEXTUAL factor fixtures
-- =============================================================================

-- ---- semantic_documentation ----
-- test_documented: all columns have comments
CREATE TABLE test_documented (
    id INT AUTOINCREMENT,
    name VARCHAR,
    email VARCHAR,
    score NUMBER
);
COMMENT ON COLUMN test_documented.id IS 'Primary key identifier';
COMMENT ON COLUMN test_documented.name IS 'Full legal name of the entity';
COMMENT ON COLUMN test_documented.email IS 'Contact email address';
COMMENT ON COLUMN test_documented.score IS 'Composite quality score 0-100';

-- test_undocumented: no comments
CREATE TABLE test_undocumented (
    id INT AUTOINCREMENT,
    name VARCHAR,
    value NUMBER,
    status VARCHAR
);

-- ---- constraint_declaration ----
-- test_constrained: PK, NOT NULL, UNIQUE (PK/UNIQUE are metadata-only in Snowflake)
CREATE TABLE test_constrained (
    id INT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    value NUMBER
);

-- test_unconstrained: no constraints at all
CREATE TABLE test_unconstrained (
    col_a VARCHAR,
    col_b VARCHAR,
    col_c VARCHAR,
    col_d NUMBER
);

-- ---- entity_identifier_declaration ----
-- test_with_pk: has primary key
CREATE TABLE test_with_pk (
    id INT PRIMARY KEY,
    label VARCHAR
);

-- test_no_pk: no primary key or unique constraint
CREATE TABLE test_no_pk (
    label VARCHAR,
    value NUMBER
);

-- =============================================================================
-- CONSUMABLE factor fixtures
-- =============================================================================

-- ---- access_optimization ----
-- test_clustered: has clustering key
CREATE TABLE test_clustered (
    id INT AUTOINCREMENT,
    lookup_key VARCHAR(50) NOT NULL,
    data VARCHAR
);
ALTER TABLE test_clustered CLUSTER BY (lookup_key);
INSERT INTO test_clustered (lookup_key, data)
SELECT 'key_' || g, 'data_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- test_no_cluster: no clustering key
CREATE TABLE test_no_cluster (
    col_a VARCHAR,
    col_b VARCHAR,
    col_c NUMBER
);
INSERT INTO test_no_cluster (col_a, col_b, col_c)
SELECT 'a_' || g, 'b_' || g, g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- ---- search_optimization (Enterprise edition required) ----
CREATE TABLE test_search_opt (
    id INT AUTOINCREMENT,
    metadata VARIANT
);
INSERT INTO test_search_opt (metadata)
SELECT PARSE_JSON('{"tag": "item_' || g || '", "score": ' || g || '}')
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

CREATE TABLE test_no_search (
    id INT AUTOINCREMENT,
    metadata VARCHAR
);
INSERT INTO test_no_search (metadata)
SELECT '{"tag": "item_' || g || '"}'
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- Enable search optimization (Enterprise edition only — fails gracefully on Standard)
EXECUTE IMMEDIATE $$
BEGIN
    ALTER TABLE AI_READY_TEST.test_search_opt ADD SEARCH OPTIMIZATION;
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Search optimization not available — requires Enterprise edition';
END;
$$;

-- ---- point_lookup_availability ----
-- test_with_cluster_lookup: clustering key enables fast lookups
CREATE TABLE test_with_cluster_lookup (
    id INT PRIMARY KEY,
    value VARCHAR
);
ALTER TABLE test_with_cluster_lookup CLUSTER BY (id);
INSERT INTO test_with_cluster_lookup (id, value)
SELECT g, 'val_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- test_heap_only: no clustering or optimization
CREATE TABLE test_heap_only (
    data VARCHAR,
    value NUMBER
);
INSERT INTO test_heap_only (data, value)
SELECT 'row_' || g, g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- =============================================================================
-- CURRENT factor fixtures
-- =============================================================================

-- ---- data_freshness ----
-- Both tables are freshly created; last_altered will be within any threshold.
-- Snowflake has no equivalent to PostgreSQL's ANALYZE for simulating staleness.
CREATE TABLE test_fresh_data (
    id INT AUTOINCREMENT,
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    value VARCHAR
);
INSERT INTO test_fresh_data (value)
SELECT 'fresh_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

CREATE TABLE test_stale_data (
    id INT AUTOINCREMENT,
    value VARCHAR
);
INSERT INTO test_stale_data (value)
SELECT 'stale_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- ---- temporal_referential_integrity ----
-- 100 rows: 90 valid timestamps, 10 null
CREATE TABLE test_temporal_refs (
    id INT AUTOINCREMENT,
    event_timestamp TIMESTAMP_NTZ
);
INSERT INTO test_temporal_refs (event_timestamp)
SELECT DATEADD(hour, g, '2024-01-01'::TIMESTAMP_NTZ)
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 90)));
INSERT INTO test_temporal_refs (event_timestamp)
SELECT NULL
FROM TABLE(GENERATOR(ROWCOUNT => 10));

-- ---- change_detection ----
-- test_cdc_tracked: change tracking enabled
CREATE TABLE test_cdc_tracked (
    id INT AUTOINCREMENT,
    name VARCHAR,
    modified_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
ALTER TABLE test_cdc_tracked SET CHANGE_TRACKING = TRUE;
INSERT INTO test_cdc_tracked (name)
SELECT 'tracked_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- test_no_cdc: no change tracking
CREATE TABLE test_no_cdc (
    id INT AUTOINCREMENT,
    name VARCHAR
);
INSERT INTO test_no_cdc (name)
SELECT 'untracked_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- =============================================================================
-- CORRELATED factor fixtures
-- =============================================================================

-- ---- data_provenance ----
-- test_with_provenance: comment with provenance keywords
CREATE TABLE test_with_provenance (
    id INT AUTOINCREMENT,
    data VARCHAR
);
COMMENT ON TABLE test_with_provenance IS 'Source: upstream_system, extracted via ETL pipeline from CRM database daily';
INSERT INTO test_with_provenance (data)
SELECT 'provenance_data_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- test_no_provenance: no provenance comment
CREATE TABLE test_no_provenance (
    id INT AUTOINCREMENT,
    data VARCHAR
);
INSERT INTO test_no_provenance (data)
SELECT 'data_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- ---- record_level_traceability ----
-- test_traceable: has correlation_id column
CREATE TABLE test_traceable (
    id INT AUTOINCREMENT,
    correlation_id VARCHAR DEFAULT UUID_STRING(),
    data VARCHAR
);
INSERT INTO test_traceable (data)
SELECT 'traced_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- test_no_trace: no trace column
CREATE TABLE test_no_trace (
    id INT AUTOINCREMENT,
    data VARCHAR
);
INSERT INTO test_no_trace (data)
SELECT 'untraced_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- =============================================================================
-- COMPLIANT factor fixtures (Enterprise edition features)
-- =============================================================================

-- ---- row_access_policy ----
CREATE TABLE test_rap_enabled (
    id INT AUTOINCREMENT,
    tenant_id INT NOT NULL,
    data VARCHAR
);
INSERT INTO test_rap_enabled (tenant_id, data)
SELECT MOD(g, 5) + 1, 'tenant_data_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

CREATE TABLE test_rap_disabled (
    id INT AUTOINCREMENT,
    data VARCHAR
);
INSERT INTO test_rap_disabled (data)
SELECT 'open_data_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- Create and attach row access policy (Enterprise edition only)
EXECUTE IMMEDIATE $$
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE ROW ACCESS POLICY AI_READY_TEST.rap_test_policy AS (val INT) RETURNS BOOLEAN -> TRUE';
    EXECUTE IMMEDIATE 'ALTER TABLE AI_READY_TEST.test_rap_enabled ADD ROW ACCESS POLICY AI_READY_TEST.rap_test_policy ON (tenant_id)';
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Row access policy not available — requires Enterprise edition';
END;
$$;

-- ---- classification ----
CREATE TABLE test_classified (
    id INT AUTOINCREMENT,
    data VARCHAR
);
INSERT INTO test_classified (data)
SELECT 'classified_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

CREATE TABLE test_unclassified (
    id INT AUTOINCREMENT,
    data VARCHAR
);
INSERT INTO test_unclassified (data)
SELECT 'unclassified_' || g
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS g FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- Create tag and apply classification (Enterprise edition only)
EXECUTE IMMEDIATE $$
BEGIN
    CREATE TAG IF NOT EXISTS AI_READY_TEST.data_classification;
    ALTER TABLE AI_READY_TEST.test_classified SET TAG AI_READY_TEST.data_classification = 'pii';
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Tags not available — requires Enterprise edition';
END;
$$;

-- ---- retention_policy ----
CREATE TABLE test_with_retention (
    id INT AUTOINCREMENT,
    data VARCHAR,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE test_no_retention (
    id INT AUTOINCREMENT,
    data VARCHAR
);

-- Create retention tag and apply (Enterprise edition only)
EXECUTE IMMEDIATE $$
BEGIN
    CREATE TAG IF NOT EXISTS AI_READY_TEST.retention_days;
    ALTER TABLE AI_READY_TEST.test_with_retention SET TAG AI_READY_TEST.retention_days = '90';
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Tags not available — requires Enterprise edition';
END;
$$;

-- =============================================================================
-- Confirmation
-- =============================================================================

SELECT
    'AI_READY_TEST setup complete' AS status,
    COUNT(*) AS tables_created
FROM information_schema.tables
WHERE table_schema = 'AI_READY_TEST'
    AND table_type = 'BASE TABLE';
