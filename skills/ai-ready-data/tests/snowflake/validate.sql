-- =============================================================================
-- AI-Ready Data Assessment — Snowflake Test Harness: Validation
-- =============================================================================
-- Runs representative check queries against the AI_READY_TEST schema and
-- asserts expected scores. Each block outputs:
--   REQUIREMENT | EXPECTED | ACTUAL | STATUS (PASS/FAIL/SKIP)
--
-- Tolerance: ABS(actual - expected) < 0.02 = PASS
--
-- Run with: snow sql -f validate.sql -d <YOUR_DATABASE> [-c <connection>]
-- =============================================================================

USE SCHEMA AI_READY_TEST;

-- =============================================================================
-- CLEAN factor
-- =============================================================================

SELECT '--- CLEAN factor ---' AS section;

-- Requirement: data_completeness (value_col → 0.90)
WITH check_result AS (
    SELECT
        1.0 - (COUNT_IF(value_col IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
    FROM AI_READY_TEST.test_completeness
)
SELECT
    'data_completeness (value_col)' AS requirement,
    0.90 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: data_completeness (all_null_col → 0.00)
WITH check_result AS (
    SELECT
        1.0 - (COUNT_IF(all_null_col IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
    FROM AI_READY_TEST.test_completeness
)
SELECT
    'data_completeness (all_null_col)' AS requirement,
    0.00 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.00) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: uniqueness (key_a, key_b → 0.95)
WITH check_result AS (
    SELECT
        1.0 - (SUM(IFF(rn > 1, 1, 0)) * 1.0 / NULLIF(COUNT(*), 0)) AS value
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY key_a, key_b ORDER BY 1) AS rn
        FROM AI_READY_TEST.test_uniqueness
    )
)
SELECT
    'uniqueness' AS requirement,
    0.95 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.95) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: encoding_validity (content → 0.97)
WITH check_result AS (
    SELECT
        SUM(CASE
            WHEN content NOT LIKE '%' || CHR(65533) || '%'
                AND content NOT LIKE '%' || CHR(0) || '%'
                AND REGEXP_COUNT(content, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') = 0
            THEN 1 ELSE 0
        END)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM AI_READY_TEST.test_encoding
    WHERE content IS NOT NULL
)
SELECT
    'encoding_validity' AS requirement,
    0.97 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.97) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: syntactic_validity (payload → 0.95)
WITH check_result AS (
    SELECT
        SUM(CASE
            WHEN TRY_PARSE_JSON(payload) IS NOT NULL OR payload IS NULL
            THEN 1 ELSE 0
        END)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM AI_READY_TEST.test_syntactic
)
SELECT
    'syntactic_validity' AS requirement,
    0.95 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.95) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: value_range_validity (amount in [0,100] → 0.90)
WITH check_result AS (
    SELECT
        SUM(CASE WHEN amount >= 0 AND amount <= 100 THEN 1 ELSE 0 END)::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM AI_READY_TEST.test_range
    WHERE amount IS NOT NULL
)
SELECT
    'value_range_validity' AS requirement,
    0.90 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: categorical_validity (status → 0.92)
WITH check_result AS (
    SELECT
        SUM(CASE WHEN status IN ('active','inactive','pending') THEN 1 ELSE 0 END)::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM AI_READY_TEST.test_categorical
    WHERE status IS NOT NULL
)
SELECT
    'categorical_validity' AS requirement,
    0.92 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.92) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: referential_integrity (child→parent → 0.95)
WITH check_result AS (
    SELECT
        1.0 - (COUNT_IF(target.id IS NULL AND source.parent_id IS NOT NULL)::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0)) AS value
    FROM AI_READY_TEST.test_ref_integrity_child source
    LEFT JOIN AI_READY_TEST.test_ref_integrity_parent target
        ON source.parent_id = target.id
)
SELECT
    'referential_integrity' AS requirement,
    0.95 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.95) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: cross_column_consistency (start_date <= end_date → 0.90)
WITH check_result AS (
    SELECT
        1.0 - (COUNT_IF(NOT (start_date <= end_date))::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0)) AS value
    FROM AI_READY_TEST.test_cross_column
    WHERE start_date IS NOT NULL AND end_date IS NOT NULL
)
SELECT
    'cross_column_consistency' AS requirement,
    0.90 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- =============================================================================
-- CONTEXTUAL factor
-- =============================================================================

SELECT '--- CONTEXTUAL factor ---' AS section;

-- Requirement: semantic_documentation (column comment coverage → 0.50)
-- test_documented has 4 columns all commented; test_undocumented has 4 with none
WITH check_result AS (
    SELECT
        COUNT_IF(c.comment IS NOT NULL AND c.comment != '') AS commented_columns,
        COUNT(*) AS total_columns
    FROM information_schema.columns c
    JOIN information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = 'AI_READY_TEST'
        AND t.table_type = 'BASE TABLE'
        AND t.table_name IN ('TEST_DOCUMENTED', 'TEST_UNDOCUMENTED')
)
SELECT
    'semantic_documentation' AS requirement,
    0.50 AS expected,
    ROUND(commented_columns::FLOAT / NULLIF(total_columns::FLOAT, 0), 4) AS actual,
    CASE
        WHEN ABS(commented_columns::FLOAT / NULLIF(total_columns::FLOAT, 0) - 0.50) < 0.02
        THEN 'PASS' ELSE 'FAIL'
    END AS status
FROM check_result;

-- Requirement: constraint_declaration (schema-level → 0.375)
-- test_constrained: id (PK NOT NULL), code (NOT NULL UNIQUE), name (NOT NULL), value (nullable) → 3 constrained
-- test_unconstrained: 4 cols, all nullable, no keys → 0 constrained
-- Note: Snowflake lacks information_schema.key_column_usage. PK/UNIQUE columns
-- are already NOT NULL (PK implies NOT NULL), so IS_NULLABLE alone captures them.
WITH check_result AS (
    SELECT
        COUNT_IF(c.is_nullable = 'NO')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = 'AI_READY_TEST'
        AND t.table_name IN ('TEST_CONSTRAINED', 'TEST_UNCONSTRAINED')
        AND t.table_type = 'BASE TABLE'
)
SELECT
    'constraint_declaration' AS requirement,
    0.375 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.375) < 0.06 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: entity_identifier_declaration (PK/UNIQUE → 0.50)
WITH check_result AS (
    WITH tables_in_scope AS (
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_WITH_PK', 'TEST_NO_PK')
            AND table_type = 'BASE TABLE'
    ),
    tables_with_pk AS (
        SELECT DISTINCT tc.table_name
        FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'AI_READY_TEST'
            AND tc.table_name IN ('TEST_WITH_PK', 'TEST_NO_PK')
            AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    )
    SELECT
        (SELECT COUNT(*) FROM tables_with_pk)::FLOAT
            / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
)
SELECT
    'entity_identifier_declaration' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- =============================================================================
-- CONSUMABLE factor
-- =============================================================================

SELECT '--- CONSUMABLE factor ---' AS section;

-- Requirement: access_optimization (clustering key → 0.50)
-- Production check uses row_count > 10000 threshold; test uses all tables in scope.
WITH check_result AS (
    WITH large_tables AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_CLUSTERED', 'TEST_NO_CLUSTER')
            AND table_type = 'BASE TABLE'
    ),
    clustered AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_CLUSTERED', 'TEST_NO_CLUSTER')
            AND table_type = 'BASE TABLE'
            AND clustering_key IS NOT NULL
    )
    SELECT clustered.cnt::FLOAT / NULLIF(large_tables.cnt::FLOAT, 0) AS value
    FROM large_tables, clustered
)
SELECT
    'access_optimization' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Capture SHOW TABLES output for metadata checks (search_optimization,
-- change_detection, point_lookup_availability)
SHOW TABLES IN SCHEMA AI_READY_TEST;

CREATE OR REPLACE TEMPORARY TABLE _show_tables_result AS
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Requirement: search_optimization (Enterprise → 0.50, Standard → SKIP)
WITH check_result AS (
    SELECT
        COUNT_IF("search_optimization" = 'ON')::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM _show_tables_result
    WHERE "name" IN ('TEST_SEARCH_OPT', 'TEST_NO_SEARCH')
)
SELECT
    'search_optimization' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE
        WHEN ABS(value - 0.50) < 0.02 THEN 'PASS'
        WHEN value = 0.0 THEN 'SKIP (requires Enterprise edition)'
        ELSE 'FAIL'
    END AS status
FROM check_result;

-- Requirement: point_lookup_availability (clustering for fast lookups → 0.50)
-- check.md returns a placeholder 0.0; this test uses SHOW TABLES for actual results.
WITH check_result AS (
    SELECT
        COUNT_IF("cluster_by" != '')::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM _show_tables_result
    WHERE "name" IN ('TEST_WITH_CLUSTER_LOOKUP', 'TEST_HEAP_ONLY')
)
SELECT
    'point_lookup_availability' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- =============================================================================
-- CURRENT factor
-- =============================================================================

SELECT '--- CURRENT factor ---' AS section;

-- Requirement: data_freshness (24-hour threshold → 1.00)
-- Both tables are freshly created, so both are within threshold.
-- Snowflake cannot simulate staleness in a single-run test (no ANALYZE equivalent).
WITH check_result AS (
    SELECT
        COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= 24)::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM information_schema.tables
    WHERE table_schema = 'AI_READY_TEST'
        AND table_name IN ('TEST_FRESH_DATA', 'TEST_STALE_DATA')
        AND table_type = 'BASE TABLE'
)
SELECT
    'data_freshness' AS requirement,
    1.00 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 1.00) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: temporal_referential_integrity (event_timestamp → 0.90)
WITH check_result AS (
    SELECT
        COUNT_IF(
            event_timestamp IS NOT NULL
            AND event_timestamp <= CURRENT_TIMESTAMP()
            AND event_timestamp >= '1900-01-01'::TIMESTAMP_NTZ
        )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM AI_READY_TEST.test_temporal_refs
)
SELECT
    'temporal_referential_integrity' AS requirement,
    0.90 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: change_detection (change_tracking ON → 0.50)
WITH check_result AS (
    SELECT
        COUNT_IF("change_tracking" = 'ON')::FLOAT
            / NULLIF(COUNT(*)::FLOAT, 0) AS value
    FROM _show_tables_result
    WHERE "name" IN ('TEST_CDC_TRACKED', 'TEST_NO_CDC')
)
SELECT
    'change_detection' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- =============================================================================
-- CORRELATED factor
-- =============================================================================

SELECT '--- CORRELATED factor ---' AS section;

-- Requirement: data_provenance (table comments with provenance keywords → 0.50)
WITH check_result AS (
    WITH tables_in_scope AS (
        SELECT table_name, comment
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_WITH_PROVENANCE', 'TEST_NO_PROVENANCE')
            AND table_type = 'BASE TABLE'
    ),
    tables_with_provenance AS (
        SELECT * FROM tables_in_scope
        WHERE comment IS NOT NULL
            AND LENGTH(comment) > 20
            AND (
                LOWER(comment) LIKE '%source%'
                OR LOWER(comment) LIKE '%origin%'
                OR LOWER(comment) LIKE '%from%'
                OR LOWER(comment) LIKE '%upstream%'
                OR LOWER(comment) LIKE '%loaded%'
                OR LOWER(comment) LIKE '%extracted%'
            )
    )
    SELECT
        (SELECT COUNT(*) FROM tables_with_provenance)::FLOAT
            / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
)
SELECT
    'data_provenance' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: record_level_traceability (trace column names → 0.50)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_TRACEABLE', 'TEST_NO_TRACE')
            AND table_type = 'BASE TABLE'
    ),
    traceable_tables AS (
        SELECT COUNT(DISTINCT c.table_name) AS cnt
        FROM information_schema.columns c
        JOIN information_schema.tables t
            ON c.table_name = t.table_name AND c.table_schema = t.table_schema
        WHERE c.table_schema = 'AI_READY_TEST'
            AND t.table_name IN ('TEST_TRACEABLE', 'TEST_NO_TRACE')
            AND t.table_type = 'BASE TABLE'
            AND LOWER(c.column_name) IN (
                'correlation_id', 'trace_id', 'request_id', 'event_id',
                'source_id', 'origin_id', 'record_id', 'lineage_id'
            )
    )
    SELECT traceable_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
    FROM table_count, traceable_tables
)
SELECT
    'record_level_traceability' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- =============================================================================
-- COMPLIANT factor (account_usage — ~2 hour latency)
-- =============================================================================
-- These checks use snowflake.account_usage views which have ~2 hour propagation
-- delay. They will return 0.00 / SKIP if run immediately after setup.
-- Rerun after 2+ hours for accurate results.
--
-- Requires: GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE <your_role>;

SELECT '--- COMPLIANT factor (account_usage — may show SKIP if run immediately) ---' AS section;

-- Requirement: row_access_policy (RAP via policy_references → 0.50)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_RAP_ENABLED', 'TEST_RAP_DISABLED')
            AND table_type = 'BASE TABLE'
    ),
    rap_tables AS (
        SELECT COUNT(DISTINCT ref_entity_name) AS cnt
        FROM snowflake.account_usage.policy_references
        WHERE UPPER(ref_database_name) = UPPER(CURRENT_DATABASE())
            AND UPPER(ref_schema_name) = 'AI_READY_TEST'
            AND policy_kind = 'ROW_ACCESS_POLICY'
            AND UPPER(ref_entity_name) IN ('TEST_RAP_ENABLED', 'TEST_RAP_DISABLED')
    )
    SELECT rap_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
    FROM table_count, rap_tables
)
SELECT
    'row_access_policy' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE
        WHEN ABS(value - 0.50) < 0.02 THEN 'PASS'
        WHEN value = 0.0 THEN 'SKIP (account_usage latency — rerun after 2hr)'
        ELSE 'FAIL'
    END AS status
FROM check_result;

-- Requirement: classification (tag_references → 0.50)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_CLASSIFIED', 'TEST_UNCLASSIFIED')
            AND table_type = 'BASE TABLE'
    ),
    tagged_tables AS (
        SELECT COUNT(DISTINCT tr.object_name) AS cnt
        FROM snowflake.account_usage.tag_references tr
        JOIN information_schema.tables t
            ON UPPER(tr.object_name) = UPPER(t.table_name)
            AND t.table_schema = 'AI_READY_TEST'
            AND t.table_type = 'BASE TABLE'
        WHERE UPPER(tr.object_database) = UPPER(CURRENT_DATABASE())
            AND UPPER(tr.object_schema) = 'AI_READY_TEST'
            AND tr.domain = 'TABLE'
            AND UPPER(tr.object_name) IN ('TEST_CLASSIFIED', 'TEST_UNCLASSIFIED')
    )
    SELECT tagged_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
    FROM table_count, tagged_tables
)
SELECT
    'classification' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE
        WHEN ABS(value - 0.50) < 0.02 THEN 'PASS'
        WHEN value = 0.0 THEN 'SKIP (account_usage latency — rerun after 2hr)'
        ELSE 'FAIL'
    END AS status
FROM check_result;

-- Requirement: retention_policy (retention tag via tag_references → 0.50)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'AI_READY_TEST'
            AND table_name IN ('TEST_WITH_RETENTION', 'TEST_NO_RETENTION')
            AND table_type = 'BASE TABLE'
    ),
    tagged_retention AS (
        SELECT COUNT(DISTINCT tr.object_name) AS cnt
        FROM snowflake.account_usage.tag_references tr
        JOIN information_schema.tables t
            ON UPPER(tr.object_name) = UPPER(t.table_name)
            AND t.table_schema = 'AI_READY_TEST'
            AND t.table_type = 'BASE TABLE'
        WHERE UPPER(tr.object_database) = UPPER(CURRENT_DATABASE())
            AND UPPER(tr.object_schema) = 'AI_READY_TEST'
            AND tr.domain = 'TABLE'
            AND LOWER(tr.tag_name) IN ('retention_days', 'retention_policy', 'data_retention', 'ttl')
            AND UPPER(tr.object_name) IN ('TEST_WITH_RETENTION', 'TEST_NO_RETENTION')
    )
    SELECT tagged_retention.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
    FROM table_count, tagged_retention
)
SELECT
    'retention_policy' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE
        WHEN ABS(value - 0.50) < 0.02 THEN 'PASS'
        WHEN value = 0.0 THEN 'SKIP (account_usage latency — rerun after 2hr)'
        ELSE 'FAIL'
    END AS status
FROM check_result;

-- =============================================================================
-- Cleanup temp objects
-- =============================================================================

DROP TABLE IF EXISTS _show_tables_result;

SELECT '--- Validation complete. Review FAIL/SKIP results above. ---' AS section;
