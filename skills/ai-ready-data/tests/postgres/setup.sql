-- =============================================================================
-- AI-Ready Data Assessment — PostgreSQL Test Harness: Setup
-- =============================================================================
-- Creates the ai_ready_test schema with controlled fixtures exercising all
-- requirement factors (Clean, Contextual, Consumable, Current, Correlated,
-- Compliant). Each table is designed with deterministic data so that check
-- queries return predictable scores.
-- =============================================================================

BEGIN;

DROP SCHEMA IF EXISTS ai_ready_test CASCADE;
CREATE SCHEMA ai_ready_test;
SET search_path TO ai_ready_test;

-- =============================================================================
-- CLEAN factor fixtures
-- =============================================================================

-- ---- data_completeness ----
-- 100 rows: value_col 90 non-null / 10 null, all_null_col all null
CREATE TABLE test_completeness (
    id SERIAL PRIMARY KEY,
    value_col TEXT,
    all_null_col TEXT
);
INSERT INTO test_completeness (value_col, all_null_col)
SELECT
    CASE WHEN g <= 90 THEN 'val_' || g ELSE NULL END,
    NULL
FROM generate_series(1, 100) g;

-- ---- uniqueness ----
-- 100 rows: 95 unique (key_a, key_b) combos, 5 duplicates
CREATE TABLE test_uniqueness (
    id SERIAL PRIMARY KEY,
    key_a INT NOT NULL,
    key_b INT NOT NULL
);
INSERT INTO test_uniqueness (key_a, key_b)
SELECT g, g FROM generate_series(1, 95) g;
INSERT INTO test_uniqueness (key_a, key_b)
SELECT g, g FROM generate_series(1, 5) g;

-- ---- schema_conformity ----
-- 10 columns: 2 VARCHAR columns with date-like names, 1 DOUBLE PRECISION with count-like name
CREATE TABLE test_schema_conformity (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    amount NUMERIC(10,2),
    created_date VARCHAR(50),     -- should be TIMESTAMP
    updated_at VARCHAR(50),       -- should be TIMESTAMP
    item_count DOUBLE PRECISION,  -- should be INTEGER
    status TEXT,
    is_active BOOLEAN,
    notes TEXT
);
INSERT INTO test_schema_conformity (name, description, amount, created_date, updated_at, item_count, status, is_active, notes)
SELECT
    'item_' || g,
    'Description for item ' || g,
    (g * 1.5)::NUMERIC(10,2),
    '2024-01-' || LPAD(((g % 28) + 1)::TEXT, 2, '0'),
    '2024-06-' || LPAD(((g % 28) + 1)::TEXT, 2, '0'),
    g * 1.0,
    CASE WHEN g % 3 = 0 THEN 'active' WHEN g % 3 = 1 THEN 'inactive' ELSE 'pending' END,
    g % 2 = 0,
    'Note ' || g
FROM generate_series(1, 100) g;

-- ---- encoding_validity ----
-- 100 text rows: 97 clean, 3 with U+FFFD replacement character
CREATE TABLE test_encoding (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL
);
INSERT INTO test_encoding (content)
SELECT 'Clean text content row ' || g FROM generate_series(1, 97) g;
INSERT INTO test_encoding (content)
SELECT 'Garbled text ' || CHR(65533) || ' row ' || g FROM generate_series(98, 100) g;

-- ---- syntactic_validity ----
-- 100 rows: 95 valid JSON, 5 malformed
CREATE TABLE test_syntactic (
    id SERIAL PRIMARY KEY,
    payload TEXT NOT NULL
);
INSERT INTO test_syntactic (payload)
SELECT '{"key": "value_' || g || '", "num": ' || g || '}' FROM generate_series(1, 95) g;
INSERT INTO test_syntactic (payload)
SELECT '{invalid json ' || g FROM generate_series(96, 100) g;

-- ---- value_range_validity ----
-- 100 rows: 90 within [0,100], 10 outside
CREATE TABLE test_range (
    id SERIAL PRIMARY KEY,
    amount NUMERIC NOT NULL
);
INSERT INTO test_range (amount)
SELECT (g * 1.0) FROM generate_series(1, 90) g;
INSERT INTO test_range (amount)
SELECT -10.0 * g FROM generate_series(1, 5) g;
INSERT INTO test_range (amount)
SELECT 100.0 + (20.0 * g) FROM generate_series(1, 5) g;

-- ---- categorical_validity ----
-- 100 rows: 92 valid, 8 invalid
CREATE TABLE test_categorical (
    id SERIAL PRIMARY KEY,
    status TEXT NOT NULL
);
INSERT INTO test_categorical (status)
SELECT CASE
    WHEN g % 3 = 0 THEN 'active'
    WHEN g % 3 = 1 THEN 'inactive'
    ELSE 'pending'
END FROM generate_series(1, 92) g;
INSERT INTO test_categorical (status)
SELECT 'invalid_status_' || g FROM generate_series(1, 8) g;

-- ---- referential_integrity ----
-- Parent with IDs 1-20, child with 95 valid + 5 orphans (no FK constraint)
CREATE TABLE test_ref_integrity_parent (
    id INT PRIMARY KEY
);
INSERT INTO test_ref_integrity_parent (id)
SELECT g FROM generate_series(1, 20) g;

CREATE TABLE test_ref_integrity_child (
    id SERIAL PRIMARY KEY,
    parent_id INT NOT NULL
);
INSERT INTO test_ref_integrity_child (parent_id)
SELECT (g % 20) + 1 FROM generate_series(1, 95) g;
INSERT INTO test_ref_integrity_child (parent_id)
SELECT 100 + g FROM generate_series(1, 5) g;

-- ---- cross_column_consistency ----
-- 100 rows: 90 where start_date <= end_date, 10 violated
CREATE TABLE test_cross_column (
    id SERIAL PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);
INSERT INTO test_cross_column (start_date, end_date)
SELECT
    DATE '2024-01-01' + (g || ' days')::INTERVAL,
    DATE '2024-01-01' + ((g + 30) || ' days')::INTERVAL
FROM generate_series(1, 90) g;
INSERT INTO test_cross_column (start_date, end_date)
SELECT
    DATE '2024-06-01' + (g || ' days')::INTERVAL,
    DATE '2024-01-01'
FROM generate_series(1, 10) g;

-- ---- outlier_prevalence ----
-- 100 rows: 95 in normal range, 5 extreme outliers
CREATE TABLE test_outliers (
    id SERIAL PRIMARY KEY,
    measurement NUMERIC NOT NULL
);
INSERT INTO test_outliers (measurement)
SELECT 50 + (RANDOM() * 10 - 5)::NUMERIC(10,2) FROM generate_series(1, 95) g;
INSERT INTO test_outliers (measurement)
VALUES (9999), (-9999), (50000), (-50000), (100000);

-- ---- distribution_conformity ----
-- 100 rows: roughly normal distribution
CREATE TABLE test_distribution (
    id SERIAL PRIMARY KEY,
    feature_val NUMERIC NOT NULL
);
INSERT INTO test_distribution (feature_val)
SELECT
    ROUND((50 + 10 * (RANDOM() + RANDOM() + RANDOM() - 1.5))::NUMERIC, 2)
FROM generate_series(1, 100) g;

-- =============================================================================
-- CONTEXTUAL factor fixtures
-- =============================================================================

-- ---- semantic_documentation ----
-- test_documented: all columns have comments
CREATE TABLE test_documented (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email TEXT,
    score NUMERIC
);
COMMENT ON COLUMN test_documented.id IS 'Primary key identifier';
COMMENT ON COLUMN test_documented.name IS 'Full legal name of the entity';
COMMENT ON COLUMN test_documented.email IS 'Contact email address';
COMMENT ON COLUMN test_documented.score IS 'Composite quality score 0-100';

-- test_undocumented: no comments
CREATE TABLE test_undocumented (
    id SERIAL,
    name TEXT,
    value NUMERIC,
    status TEXT
);

-- ---- constraint_declaration ----
-- test_constrained: PK, NOT NULL, UNIQUE
CREATE TABLE test_constrained (
    id INT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL,
    value NUMERIC
);

-- test_unconstrained: no constraints at all
CREATE TABLE test_unconstrained (
    col_a TEXT,
    col_b TEXT,
    col_c TEXT,
    col_d NUMERIC
);

-- ---- entity_identifier_declaration ----
-- test_with_pk: has primary key
CREATE TABLE test_with_pk (
    id INT PRIMARY KEY,
    label TEXT
);

-- test_no_pk: no primary key or unique constraint
CREATE TABLE test_no_pk (
    label TEXT,
    value NUMERIC
);

-- ---- relationship_declaration ----
-- test_with_fk: references test_with_pk
CREATE TABLE test_with_fk (
    id SERIAL PRIMARY KEY,
    pk_ref INT REFERENCES test_with_pk(id),
    detail TEXT
);

-- test_no_fk: standalone
CREATE TABLE test_no_fk (
    id SERIAL,
    detail TEXT
);

-- ---- temporal_scope_declaration ----
-- test_temporal: has temporal columns
CREATE TABLE test_temporal (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_from DATE,
    valid_to DATE,
    name TEXT
);
INSERT INTO test_temporal (valid_from, valid_to, name)
SELECT
    DATE '2024-01-01' + (g || ' days')::INTERVAL,
    DATE '2024-12-31',
    'entity_' || g
FROM generate_series(1, 50) g;

-- test_no_temporal: no temporal columns
CREATE TABLE test_no_temporal (
    id SERIAL,
    name TEXT,
    value NUMERIC
);

-- ---- unit_of_measure_declaration ----
-- test_with_units: numeric columns with unit comments
CREATE TABLE test_with_units (
    id SERIAL PRIMARY KEY,
    weight_kg NUMERIC,
    height_cm NUMERIC,
    temperature_celsius NUMERIC
);
COMMENT ON COLUMN test_with_units.weight_kg IS 'Weight in kilograms (kg)';
COMMENT ON COLUMN test_with_units.height_cm IS 'Height in centimeters (cm)';
COMMENT ON COLUMN test_with_units.temperature_celsius IS 'Temperature in degrees Celsius (°C)';

-- test_no_units: numeric columns without unit comments
CREATE TABLE test_no_units (
    id SERIAL,
    metric_a NUMERIC,
    metric_b NUMERIC,
    metric_c NUMERIC
);

-- =============================================================================
-- CONSUMABLE factor fixtures
-- =============================================================================

-- ---- access_optimization ----
-- test_indexed: B-tree index
CREATE TABLE test_indexed (
    id SERIAL PRIMARY KEY,
    lookup_key VARCHAR(50) NOT NULL,
    data TEXT
);
CREATE INDEX idx_test_indexed_lookup ON test_indexed (lookup_key);
INSERT INTO test_indexed (lookup_key, data)
SELECT 'key_' || g, 'data_' || g FROM generate_series(1, 100) g;

-- test_no_index: no index
CREATE TABLE test_no_index (
    col_a TEXT,
    col_b TEXT,
    col_c NUMERIC
);
INSERT INTO test_no_index (col_a, col_b, col_c)
SELECT 'a_' || g, 'b_' || g, g FROM generate_series(1, 100) g;

-- ---- search_optimization ----
-- test_gin_search: GIN index on JSONB
CREATE TABLE test_gin_search (
    id SERIAL PRIMARY KEY,
    metadata JSONB NOT NULL DEFAULT '{}'
);
CREATE INDEX idx_test_gin_search_meta ON test_gin_search USING GIN (metadata);
INSERT INTO test_gin_search (metadata)
SELECT ('{"tag": "item_' || g || '", "score": ' || g || '}')::JSONB FROM generate_series(1, 100) g;

-- test_no_search: no GIN/GiST index
CREATE TABLE test_no_search (
    id SERIAL PRIMARY KEY,
    metadata TEXT
);
INSERT INTO test_no_search (metadata)
SELECT '{"tag": "item_' || g || '"}' FROM generate_series(1, 100) g;

-- ---- point_lookup_availability ----
-- test_with_pk_lookup: PK enables point lookup
CREATE TABLE test_with_pk_lookup (
    id INT PRIMARY KEY,
    value TEXT
);
INSERT INTO test_with_pk_lookup (id, value)
SELECT g, 'val_' || g FROM generate_series(1, 100) g;

-- test_heap_only: no unique index
CREATE TABLE test_heap_only (
    data TEXT,
    value NUMERIC
);
INSERT INTO test_heap_only (data, value)
SELECT 'row_' || g, g FROM generate_series(1, 100) g;

-- ---- embedding_coverage (pgvector-dependent) ----
-- Conditionally create tables with vector columns if pgvector is available
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS vector;
    CREATE TABLE ai_ready_test.test_embeddings (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL,
        embedding vector(384)
    );
    INSERT INTO ai_ready_test.test_embeddings (content, embedding)
    SELECT
        'Document content for item ' || g,
        (SELECT ('[' || string_agg(ROUND(RANDOM()::NUMERIC, 4)::TEXT, ',') || ']')
         FROM generate_series(1, 384))::vector
    FROM generate_series(1, 50) g;
    RAISE NOTICE 'pgvector available — test_embeddings created with vector(384) column';
EXCEPTION WHEN OTHERS THEN
    CREATE TABLE ai_ready_test.test_embeddings (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL
    );
    INSERT INTO ai_ready_test.test_embeddings (content)
    SELECT 'Document content for item ' || g FROM generate_series(1, 50) g;
    RAISE NOTICE 'pgvector NOT available — test_embeddings created without vector column (embedding checks will reflect gap)';
END $$;

-- test_no_embeddings: text content, no vector column
CREATE TABLE test_no_embeddings (
    id SERIAL PRIMARY KEY,
    body TEXT NOT NULL
);
INSERT INTO test_no_embeddings (body)
SELECT 'Text body for record ' || g FROM generate_series(1, 50) g;

-- ---- native_format_availability ----
-- test_jsonb_native: proper JSONB storage
CREATE TABLE test_jsonb_native (
    id SERIAL PRIMARY KEY,
    doc JSONB NOT NULL
);
INSERT INTO test_jsonb_native (doc)
SELECT ('{"id": ' || g || ', "data": "value_' || g || '"}')::JSONB FROM generate_series(1, 50) g;

-- test_text_json: JSON stored as TEXT (suboptimal)
CREATE TABLE test_text_json (
    id SERIAL PRIMARY KEY,
    doc TEXT NOT NULL
);
INSERT INTO test_text_json (doc)
SELECT '{"id": ' || g || ', "data": "value_' || g || '"}' FROM generate_series(1, 50) g;

-- ---- chunk_readiness ----
-- test_chunked: has chunk_size column
CREATE TABLE test_chunked (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    chunk_size INT NOT NULL DEFAULT 512
);
INSERT INTO test_chunked (content, chunk_size)
SELECT 'Chunk content ' || g, 512 FROM generate_series(1, 50) g;

-- test_not_chunked: no chunk metadata
CREATE TABLE test_not_chunked (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL
);
INSERT INTO test_not_chunked (content)
SELECT 'Raw document content ' || g FROM generate_series(1, 50) g;

-- ---- eval_coverage ----
-- test_eval_data: base data table
CREATE TABLE test_eval_data (
    id SERIAL PRIMARY KEY,
    feature_a NUMERIC,
    feature_b NUMERIC,
    label TEXT
);
INSERT INTO test_eval_data (feature_a, feature_b, label)
SELECT g * 1.1, g * 2.2, CASE WHEN g % 2 = 0 THEN 'positive' ELSE 'negative' END
FROM generate_series(1, 100) g;

-- test_customers_eval: eval dataset (naming convention *_eval)
CREATE TABLE test_customers_eval (
    id SERIAL PRIMARY KEY,
    input_text TEXT,
    expected_output TEXT,
    actual_output TEXT
);
INSERT INTO test_customers_eval (input_text, expected_output, actual_output)
SELECT 'input_' || g, 'expected_' || g, 'actual_' || g FROM generate_series(1, 50) g;

-- =============================================================================
-- CURRENT factor fixtures
-- =============================================================================

-- ---- data_freshness ----
-- test_fresh_data: will be ANALYZEd to create freshness signal
CREATE TABLE test_fresh_data (
    id SERIAL PRIMARY KEY,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    value TEXT
);
INSERT INTO test_fresh_data (value)
SELECT 'fresh_' || g FROM generate_series(1, 100) g;

-- test_stale_data: not analyzed (no freshness signal)
CREATE TABLE test_stale_data (
    id SERIAL,
    value TEXT
);
INSERT INTO test_stale_data (value)
SELECT 'stale_' || g FROM generate_series(1, 100) g;

-- Run ANALYZE on fresh table only
ANALYZE ai_ready_test.test_fresh_data;

-- ---- temporal_referential_integrity ----
-- 100 rows: 90 valid timestamps, 10 null
CREATE TABLE test_temporal_refs (
    id SERIAL PRIMARY KEY,
    event_timestamp TIMESTAMP
);
INSERT INTO test_temporal_refs (event_timestamp)
SELECT TIMESTAMP '2024-01-01' + ((g || ' hours')::INTERVAL) FROM generate_series(1, 90) g;
INSERT INTO test_temporal_refs (event_timestamp)
SELECT NULL FROM generate_series(1, 10) g;

-- ---- change_detection ----
-- Trigger-based CDC simulation
CREATE TABLE test_cdc_tracked (
    id SERIAL PRIMARY KEY,
    name TEXT,
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE OR REPLACE FUNCTION ai_ready_test.trg_set_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER set_modified
    BEFORE UPDATE ON test_cdc_tracked
    FOR EACH ROW EXECUTE FUNCTION ai_ready_test.trg_set_modified();
INSERT INTO test_cdc_tracked (name)
SELECT 'tracked_' || g FROM generate_series(1, 50) g;

-- Table without change tracking
CREATE TABLE test_no_cdc (
    id SERIAL,
    name TEXT
);
INSERT INTO test_no_cdc (name)
SELECT 'untracked_' || g FROM generate_series(1, 50) g;

-- ---- point_in_time_correctness ----
-- Table with valid_from/valid_to for SCD support
CREATE TABLE test_pit_correct (
    id SERIAL PRIMARY KEY,
    entity_id INT NOT NULL,
    value TEXT,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP
);
INSERT INTO test_pit_correct (entity_id, value, valid_from, valid_to)
SELECT
    g,
    'v1_' || g,
    TIMESTAMP '2024-01-01',
    TIMESTAMP '2024-06-30'
FROM generate_series(1, 50) g;

-- =============================================================================
-- CORRELATED factor fixtures
-- =============================================================================

-- ---- data_provenance ----
-- test_with_provenance: comment with provenance keywords
CREATE TABLE test_with_provenance (
    id SERIAL PRIMARY KEY,
    data TEXT
);
COMMENT ON TABLE test_with_provenance IS 'Source: upstream_system, extracted via ETL pipeline from CRM database daily';
INSERT INTO test_with_provenance (data)
SELECT 'provenance_data_' || g FROM generate_series(1, 50) g;

-- test_no_provenance: no provenance comment
CREATE TABLE test_no_provenance (
    id SERIAL PRIMARY KEY,
    data TEXT
);
INSERT INTO test_no_provenance (data)
SELECT 'data_' || g FROM generate_series(1, 50) g;

-- ---- lineage_completeness ----
-- View creates pg_depend entry for test_with_provenance
CREATE VIEW v_test_lineage AS
SELECT id, data FROM test_with_provenance WHERE id > 0;

-- ---- record_level_traceability ----
-- test_traceable: has correlation_id UUID column
CREATE TABLE test_traceable (
    id SERIAL PRIMARY KEY,
    correlation_id UUID NOT NULL DEFAULT gen_random_uuid(),
    data TEXT
);
INSERT INTO test_traceable (data)
SELECT 'traced_' || g FROM generate_series(1, 50) g;

-- test_no_trace: no trace column
CREATE TABLE test_no_trace (
    id SERIAL PRIMARY KEY,
    data TEXT
);
INSERT INTO test_no_trace (data)
SELECT 'untraced_' || g FROM generate_series(1, 50) g;

-- ---- agent_attribution ----
-- Table with agent/pipeline tag comment
CREATE TABLE test_agent_attributed (
    id SERIAL PRIMARY KEY,
    data TEXT,
    modified_by TEXT DEFAULT 'agent:data_pipeline_v2'
);
COMMENT ON TABLE test_agent_attributed IS 'Managed by agent:data_pipeline_v2 [query_tag: etl_daily]';
INSERT INTO test_agent_attributed (data)
SELECT 'agent_data_' || g FROM generate_series(1, 50) g;

-- ---- transformation_documentation ----
-- Table with transformation documentation in comment
CREATE TABLE test_transform_documented (
    id SERIAL PRIMARY KEY,
    feature_value NUMERIC
);
COMMENT ON TABLE test_transform_documented IS 'Derived via transformation: normalize(raw_value) -> z-score. Input: raw_metrics, Output: normalized features';

-- ---- pipeline_execution_audit ----
-- Audit log table
CREATE TABLE test_pipeline_audit (
    id SERIAL PRIMARY KEY,
    pipeline_name TEXT NOT NULL,
    run_id UUID NOT NULL DEFAULT gen_random_uuid(),
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    status TEXT NOT NULL DEFAULT 'running',
    input_params JSONB,
    output_summary JSONB,
    row_count INT
);
INSERT INTO test_pipeline_audit (pipeline_name, status, completed_at, row_count)
SELECT
    'pipeline_' || g,
    'completed',
    CURRENT_TIMESTAMP,
    g * 1000
FROM generate_series(1, 10) g;

-- ---- dependency_graph_completeness ----
-- Create a materialized view depending on test_eval_data
CREATE MATERIALIZED VIEW mv_test_dependency AS
SELECT id, feature_a, label FROM test_eval_data WHERE feature_a > 50;

-- =============================================================================
-- COMPLIANT factor fixtures
-- =============================================================================

-- ---- row_access_policy ----
-- test_rls_enabled: RLS enabled with policy
CREATE TABLE test_rls_enabled (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL,
    data TEXT
);
ALTER TABLE test_rls_enabled ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON test_rls_enabled
    USING (tenant_id = current_setting('app.current_tenant', true)::INT);
INSERT INTO test_rls_enabled (tenant_id, data)
SELECT (g % 5) + 1, 'tenant_data_' || g FROM generate_series(1, 100) g;

-- test_rls_disabled: no RLS
CREATE TABLE test_rls_disabled (
    id SERIAL PRIMARY KEY,
    data TEXT
);
INSERT INTO test_rls_disabled (data)
SELECT 'open_data_' || g FROM generate_series(1, 100) g;

-- ---- column_masking / anonymization ----
-- test_pii_masked: email column with privilege revoked from PUBLIC
CREATE TABLE test_pii_masked (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email_address TEXT
);
INSERT INTO test_pii_masked (name, email_address)
SELECT 'User ' || g, 'user' || g || '@example.com' FROM generate_series(1, 50) g;
REVOKE SELECT (email_address) ON test_pii_masked FROM PUBLIC;

-- test_pii_exposed: email column with no restrictions
CREATE TABLE test_pii_exposed (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email TEXT
);
INSERT INTO test_pii_exposed (name, email)
SELECT 'User ' || g, 'user' || g || '@example.com' FROM generate_series(1, 50) g;

-- ---- classification ----
-- test_classified: comment with classification marker
CREATE TABLE test_classified (
    id SERIAL PRIMARY KEY,
    data TEXT
);
COMMENT ON TABLE test_classified IS 'Contains personal data [classification: pii] - handle with care';

-- test_unclassified: no classification
CREATE TABLE test_unclassified (
    id SERIAL PRIMARY KEY,
    data TEXT
);

-- ---- retention_policy ----
-- test_with_retention: comment with retention metadata
CREATE TABLE test_with_retention (
    id SERIAL PRIMARY KEY,
    data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE test_with_retention IS 'retention_days: 90 — auto-purge after 90 days per data governance policy';

-- test_no_retention: no retention policy
CREATE TABLE test_no_retention (
    id SERIAL PRIMARY KEY,
    data TEXT
);

-- ---- consent_coverage ----
-- Table with consent metadata
CREATE TABLE test_with_consent (
    id SERIAL PRIMARY KEY,
    user_id INT,
    consent_status TEXT NOT NULL DEFAULT 'granted',
    consent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    legal_basis TEXT DEFAULT 'legitimate_interest'
);
COMMENT ON TABLE test_with_consent IS 'Personal data with consent tracking [consent: gdpr_article_6]';
INSERT INTO test_with_consent (user_id, consent_status, legal_basis)
SELECT g, 'granted', 'consent' FROM generate_series(1, 50) g;

-- ---- access_audit_coverage ----
-- Simulate audit log for access events
CREATE TABLE test_access_audit_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    action TEXT NOT NULL,
    performed_by TEXT NOT NULL,
    performed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    query_hash TEXT
);
INSERT INTO test_access_audit_log (table_name, action, performed_by)
SELECT
    'test_eval_data',
    CASE WHEN g % 3 = 0 THEN 'SELECT' WHEN g % 3 = 1 THEN 'INSERT' ELSE 'UPDATE' END,
    'service_account_' || (g % 3)
FROM generate_series(1, 100) g;

-- =============================================================================
-- ANALYZE tables that should appear "fresh"
-- =============================================================================

ANALYZE ai_ready_test.test_completeness;
ANALYZE ai_ready_test.test_uniqueness;
ANALYZE ai_ready_test.test_indexed;
ANALYZE ai_ready_test.test_documented;
ANALYZE ai_ready_test.test_constrained;
ANALYZE ai_ready_test.test_with_pk;
ANALYZE ai_ready_test.test_rls_enabled;
ANALYZE ai_ready_test.test_classified;
ANALYZE ai_ready_test.test_with_provenance;
ANALYZE ai_ready_test.test_traceable;

COMMIT;

-- Final confirmation
DO $$
DECLARE
    tbl_count INT;
BEGIN
    SELECT COUNT(*) INTO tbl_count
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'ai_ready_test' AND c.relkind = 'r';
    RAISE NOTICE 'ai_ready_test setup complete: % tables created', tbl_count;
END $$;
