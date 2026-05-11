-- =============================================================================
-- AI-Ready Data Assessment — PostgreSQL Test Harness: Validation
-- =============================================================================
-- Runs representative check queries against the ai_ready_test schema and
-- asserts expected scores. Each block outputs:
--   requirement | expected | actual | status (PASS/FAIL)
--
-- Tolerance: ABS(actual - expected) < 0.02 = PASS
-- =============================================================================

SET search_path TO ai_ready_test, public;

-- Helper function for JSON validity checks
CREATE OR REPLACE FUNCTION pg_temp.is_valid_json(val text) RETURNS boolean AS $$
BEGIN
    IF val IS NULL THEN RETURN TRUE; END IF;
    PERFORM val::jsonb;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

\echo '============================================================'
\echo 'AI-Ready Data Assessment — Test Validation Results'
\echo '============================================================'
\echo ''

-- =============================================================================
-- CLEAN factor
-- =============================================================================

\echo '--- CLEAN factor ---'

-- Requirement: data_completeness (value_col → 0.90)
WITH check_result AS (
    SELECT
        1.0 - (COUNT(*) FILTER (WHERE value_col IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
    FROM ai_ready_test.test_completeness
)
SELECT
    'data_completeness (value_col)' AS requirement,
    0.90 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: data_completeness (all_null_col → 0.00)
WITH check_result AS (
    SELECT
        1.0 - (COUNT(*) FILTER (WHERE all_null_col IS NULL) * 1.0 / NULLIF(COUNT(*), 0)) AS value
    FROM ai_ready_test.test_completeness
)
SELECT
    'data_completeness (all_null_col)' AS requirement,
    0.00 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.00) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: uniqueness (key_a, key_b → 0.95)
WITH check_result AS (
    SELECT
        1.0 - (SUM(CASE WHEN rn > 1 THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0)) AS value
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY key_a, key_b ORDER BY 1) AS rn
        FROM ai_ready_test.test_uniqueness
    ) sub
)
SELECT
    'uniqueness' AS requirement,
    0.95 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.95) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: encoding_validity (content → 0.97)
WITH check_result AS (
    SELECT
        SUM(CASE
            WHEN content NOT LIKE '%' || CHR(65533) || '%'
                AND content !~ '[\x01-\x08\x0B\x0C\x0E-\x1F]'
            THEN 1 ELSE 0
        END)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM ai_ready_test.test_encoding
    WHERE content IS NOT NULL
)
SELECT
    'encoding_validity' AS requirement,
    0.97 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.97) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: syntactic_validity (payload → 0.95)
WITH check_result AS (
    SELECT
        SUM(CASE WHEN pg_temp.is_valid_json(payload::text) THEN 1 ELSE 0 END)::NUMERIC
            / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM ai_ready_test.test_syntactic
)
SELECT
    'syntactic_validity' AS requirement,
    0.95 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.95) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: value_range_validity (amount in [0,100] → 0.90)
WITH check_result AS (
    SELECT
        SUM(CASE WHEN amount >= 0 AND amount <= 100 THEN 1 ELSE 0 END)::NUMERIC
            / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM ai_ready_test.test_range
    WHERE amount IS NOT NULL
)
SELECT
    'value_range_validity' AS requirement,
    0.90 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: categorical_validity (status → 0.92)
WITH check_result AS (
    SELECT
        SUM(CASE WHEN status IN ('active','inactive','pending') THEN 1 ELSE 0 END)::NUMERIC
            / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM ai_ready_test.test_categorical
    WHERE status IS NOT NULL
)
SELECT
    'categorical_validity' AS requirement,
    0.92 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.92) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: referential_integrity (child→parent → 0.95)
WITH check_result AS (
    SELECT
        1.0 - (COUNT(*) FILTER (
            WHERE target.id IS NULL AND source.parent_id IS NOT NULL
        )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0)) AS value
    FROM ai_ready_test.test_ref_integrity_child source
    LEFT JOIN ai_ready_test.test_ref_integrity_parent target
        ON source.parent_id = target.id
)
SELECT
    'referential_integrity' AS requirement,
    0.95 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.95) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: cross_column_consistency (start_date <= end_date → 0.90)
WITH check_result AS (
    SELECT
        SUM(CASE WHEN start_date <= end_date THEN 1 ELSE 0 END)::NUMERIC
            / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM ai_ready_test.test_cross_column
)
SELECT
    'cross_column_consistency' AS requirement,
    0.90 AS expected,
    ROUND(value::NUMERIC, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

\echo ''

-- =============================================================================
-- CONTEXTUAL factor
-- =============================================================================

\echo '--- CONTEXTUAL factor ---'

-- Requirement: semantic_documentation (schema-level column comment coverage)
-- test_documented has 4 columns all commented; test_undocumented has 4 with none
-- Expected: 4 commented out of 8 total = 0.50 (across just these two tables)
WITH check_result AS (
    SELECT
        COUNT(*) FILTER (
            WHERE col_description(a.attrelid, a.attnum) IS NOT NULL
              AND col_description(a.attrelid, a.attnum) != ''
        ) AS commented_columns,
        COUNT(*) AS total_columns
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'ai_ready_test'
      AND c.relname IN ('test_documented', 'test_undocumented')
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
)
SELECT
    'semantic_documentation' AS requirement,
    0.50 AS expected,
    ROUND(commented_columns::NUMERIC / NULLIF(total_columns::NUMERIC, 0), 4) AS actual,
    CASE
        WHEN ABS(commented_columns::NUMERIC / NULLIF(total_columns::NUMERIC, 0) - 0.50) < 0.02
        THEN 'PASS' ELSE 'FAIL'
    END AS status
FROM check_result;

-- Requirement: constraint_declaration (schema-level)
-- test_constrained: id (PK, NOT NULL), code (NOT NULL, UNIQUE), name (NOT NULL), value (nullable) → 3 constrained
-- test_unconstrained: 4 cols, all nullable, no keys → 0 constrained
-- Expected: 3 out of 8 = 0.375
WITH check_result AS (
    WITH columns_in_scope AS (
        SELECT c.table_schema, c.table_name, c.column_name, c.is_nullable
        FROM information_schema.columns c
        INNER JOIN information_schema.tables t
            ON c.table_schema = t.table_schema AND c.table_name = t.table_name
        WHERE c.table_schema = 'ai_ready_test'
            AND t.table_name IN ('test_constrained', 'test_unconstrained')
            AND t.table_type = 'BASE TABLE'
    ),
    constrained_columns AS (
        SELECT DISTINCT kcu.table_schema, kcu.table_name, kcu.column_name
        FROM information_schema.key_column_usage kcu
        WHERE kcu.table_schema = 'ai_ready_test'
            AND kcu.table_name IN ('test_constrained', 'test_unconstrained')
    )
    SELECT
        COUNT(*) FILTER (WHERE c.is_nullable = 'NO' OR cc.column_name IS NOT NULL)::NUMERIC
            / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM columns_in_scope c
    LEFT JOIN constrained_columns cc
        ON c.table_schema = cc.table_schema
        AND c.table_name = cc.table_name
        AND c.column_name = cc.column_name
)
SELECT
    'constraint_declaration' AS requirement,
    0.375 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.375) < 0.06 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: entity_identifier_declaration
-- Across test_with_pk (has PK) and test_no_pk (no PK) → 0.50
WITH check_result AS (
    WITH tables_in_scope AS (
        SELECT t.table_schema, t.table_name
        FROM information_schema.tables t
        WHERE t.table_schema = 'ai_ready_test'
            AND t.table_name IN ('test_with_pk', 'test_no_pk')
            AND t.table_type = 'BASE TABLE'
    ),
    tables_with_pk AS (
        SELECT DISTINCT tc.table_name
        FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'ai_ready_test'
            AND tc.table_name IN ('test_with_pk', 'test_no_pk')
            AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    )
    SELECT
        (SELECT COUNT(*) FROM tables_with_pk)::NUMERIC
            / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
)
SELECT
    'entity_identifier_declaration' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

\echo ''

-- =============================================================================
-- CONSUMABLE factor
-- =============================================================================

\echo '--- CONSUMABLE factor ---'

-- Requirement: access_optimization
-- test_indexed (has B-tree index) vs test_no_index (no index)
-- PK indexes also count, so test_indexed has 2 indexes. test_no_index has 0.
-- But the check counts distinct tables with ANY index → 1 out of 2 = 0.50
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_indexed', 'test_no_index')
          AND c.relkind = 'r'
    ),
    indexed_tables AS (
        SELECT COUNT(DISTINCT tablename) AS cnt
        FROM pg_indexes
        WHERE schemaname = 'ai_ready_test'
          AND tablename IN ('test_indexed', 'test_no_index')
    )
    SELECT indexed_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
    FROM table_count, indexed_tables
)
SELECT
    'access_optimization' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: point_lookup_availability
-- test_with_pk_lookup (has PK → unique index) vs test_heap_only (no unique index)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_with_pk_lookup', 'test_heap_only')
          AND c.relkind = 'r'
    ),
    pk_tables AS (
        SELECT COUNT(DISTINCT c.oid) AS cnt
        FROM pg_index i
        JOIN pg_class c ON c.oid = i.indrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_with_pk_lookup', 'test_heap_only')
          AND (i.indisprimary OR i.indisunique)
    )
    SELECT pk_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
    FROM table_count, pk_tables
)
SELECT
    'point_lookup_availability' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: search_optimization
-- test_gin_search (has GIN index) vs test_no_search (no GIN)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_gin_search', 'test_no_search')
          AND c.relkind = 'r'
    ),
    search_optimized AS (
        SELECT COUNT(DISTINCT tablename) AS cnt
        FROM pg_indexes
        WHERE schemaname = 'ai_ready_test'
          AND tablename IN ('test_gin_search', 'test_no_search')
          AND (indexdef ILIKE '%USING gin%' OR indexdef ILIKE '%USING gist%')
    )
    SELECT search_optimized.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
    FROM table_count, search_optimized
)
SELECT
    'search_optimization' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

\echo ''

-- =============================================================================
-- CURRENT factor
-- =============================================================================

\echo '--- CURRENT factor ---'

-- Requirement: data_freshness (24-hour threshold)
-- test_fresh_data was ANALYZEd during setup → fresh
-- test_stale_data was NOT analyzed → stale
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    SELECT
        COUNT(*) FILTER (
            WHERE EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - GREATEST(
                COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMPTZ),
                COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMPTZ)
            ))) / 3600 <= 24
        )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM pg_stat_user_tables s
    WHERE s.schemaname = 'ai_ready_test'
      AND s.relname IN ('test_fresh_data', 'test_stale_data')
)
SELECT
    'data_freshness' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: temporal_referential_integrity (event_timestamp → 0.90)
WITH check_result AS (
    SELECT
        COUNT(*) FILTER (WHERE
            event_timestamp IS NOT NULL
            AND event_timestamp <= CURRENT_TIMESTAMP
            AND event_timestamp >= TIMESTAMP '1900-01-01'
        )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
    FROM ai_ready_test.test_temporal_refs
)
SELECT
    'temporal_referential_integrity' AS requirement,
    0.90 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.90) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

\echo ''

-- =============================================================================
-- CORRELATED factor
-- =============================================================================

\echo '--- CORRELATED factor ---'

-- Requirement: data_provenance
-- test_with_provenance has provenance comment, test_no_provenance does not
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    WITH tables_in_scope AS (
        SELECT c.oid, c.relname, obj_description(c.oid) AS comment
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_with_provenance', 'test_no_provenance')
          AND c.relkind = 'r'
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
        (SELECT COUNT(*) FROM tables_with_provenance)::NUMERIC
            / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
)
SELECT
    'data_provenance' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: lineage_completeness
-- test_with_provenance has a view dependent (v_test_lineage), test_no_provenance does not
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    WITH tables_in_scope AS (
        SELECT c.oid, c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_with_provenance', 'test_no_provenance')
          AND c.relkind = 'r'
    ),
    tables_with_dependents AS (
        SELECT DISTINCT t.relname
        FROM tables_in_scope t
        JOIN pg_depend d ON d.refobjid = t.oid
        JOIN pg_class dc ON dc.oid = d.objid
        WHERE dc.relkind IN ('v', 'm')
          AND d.deptype = 'n'
          AND d.objid <> t.oid
    )
    SELECT
        (SELECT COUNT(*) FROM tables_with_dependents)::NUMERIC
            / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
)
SELECT
    'lineage_completeness' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: record_level_traceability
-- test_traceable has correlation_id, test_no_trace does not
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM information_schema.tables
        WHERE table_schema = 'ai_ready_test'
          AND table_name IN ('test_traceable', 'test_no_trace')
          AND table_type = 'BASE TABLE'
    ),
    traceable_tables AS (
        SELECT COUNT(DISTINCT c.table_name) AS cnt
        FROM information_schema.columns c
        JOIN information_schema.tables t
            ON c.table_name = t.table_name AND c.table_schema = t.table_schema
        WHERE c.table_schema = 'ai_ready_test'
          AND t.table_name IN ('test_traceable', 'test_no_trace')
          AND t.table_type = 'BASE TABLE'
          AND LOWER(c.column_name) IN (
              'correlation_id', 'trace_id', 'request_id', 'event_id',
              'source_id', 'origin_id', 'record_id', 'lineage_id'
          )
    )
    SELECT traceable_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
    FROM table_count, traceable_tables
)
SELECT
    'record_level_traceability' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

\echo ''

-- =============================================================================
-- COMPLIANT factor
-- =============================================================================

\echo '--- COMPLIANT factor ---'

-- Requirement: row_access_policy
-- test_rls_enabled (RLS on) vs test_rls_disabled (RLS off)
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_rls_enabled', 'test_rls_disabled')
          AND c.relkind = 'r'
    ),
    rls_tables AS (
        SELECT COUNT(*) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_rls_enabled', 'test_rls_disabled')
          AND c.relkind = 'r'
          AND c.relrowsecurity = true
    )
    SELECT rls_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
    FROM table_count, rls_tables
)
SELECT
    'row_access_policy' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: classification
-- test_classified (has [classification: pii] comment) vs test_unclassified (no comment)
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    WITH table_count AS (
        SELECT COUNT(*) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_classified', 'test_unclassified')
          AND c.relkind = 'r'
    ),
    classified_tables AS (
        SELECT COUNT(DISTINCT c.oid) AS cnt
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_seclabel sl
            ON sl.objoid = c.oid
           AND sl.classoid = 'pg_class'::regclass
           AND sl.objsubid = 0
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_classified', 'test_unclassified')
          AND c.relkind = 'r'
          AND (
              sl.label IS NOT NULL
              OR (
                  obj_description(c.oid) IS NOT NULL
                  AND (
                      LOWER(obj_description(c.oid)) LIKE '%[classification:%'
                      OR LOWER(obj_description(c.oid)) LIKE '%[pii:%'
                      OR LOWER(obj_description(c.oid)) LIKE '%[sensitivity:%'
                      OR LOWER(obj_description(c.oid)) LIKE '%[data_class:%'
                  )
              )
          )
    )
    SELECT classified_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
    FROM table_count, classified_tables
)
SELECT
    'classification' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

-- Requirement: retention_policy
-- test_with_retention (has retention comment) vs test_no_retention (no comment)
-- Expected: 0.50 (1 out of 2)
WITH check_result AS (
    WITH tables_in_scope AS (
        SELECT c.oid, c.relname, c.relkind
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'ai_ready_test'
          AND c.relname IN ('test_with_retention', 'test_no_retention')
          AND c.relkind IN ('r', 'p')
    ),
    tables_with_retention AS (
        SELECT DISTINCT t.oid
        FROM tables_in_scope t
        LEFT JOIN pg_partitioned_table pt ON pt.partrelid = t.oid
        WHERE
            (
                obj_description(t.oid) IS NOT NULL
                AND (
                    LOWER(obj_description(t.oid)) LIKE '%retention%'
                    OR LOWER(obj_description(t.oid)) LIKE '%ttl%'
                    OR LOWER(obj_description(t.oid)) LIKE '%expire%'
                    OR LOWER(obj_description(t.oid)) LIKE '%purge%'
                    OR LOWER(obj_description(t.oid)) LIKE '%archive%'
                    OR LOWER(obj_description(t.oid)) LIKE '%lifecycle%'
                )
            )
            OR (t.relkind = 'p' AND pt.partstrat = 'r')
    )
    SELECT
        (SELECT COUNT(*) FROM tables_with_retention)::NUMERIC
            / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
)
SELECT
    'retention_policy' AS requirement,
    0.50 AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.50) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;

\echo ''
\echo '============================================================'
\echo 'Validation complete. Review FAIL results above.'
\echo '============================================================'
