# PostgreSQL

PostgreSQL platform reference for the AI-ready data assessment framework.

## Capabilities

- Standard `information_schema` for tables, columns, constraints, key usage
- `pg_catalog` system catalogs for deep metadata introspection
- `pg_description` / `col_description()` / `obj_description()` for object comments
- `pg_seclabel` for security labels (closest analog to Snowflake tags)
- Row Level Security (RLS) via `CREATE POLICY` / `pg_policy`
- Column-level privileges for access control (no native masking policies)
- `pgvector` extension for vector column types and similarity indexes (HNSW, IVFFlat)
- `pg_depend` for object-level dependency tracking and lineage
- Logical replication publications for change detection / CDC
- Materialized views as analog to Snowflake dynamic tables
- `pg_stat_user_tables` for table-level activity statistics
- `pg_stat_statements` extension for query history analysis
- `pgaudit` extension for access audit logging
- Event triggers for DDL change tracking
- GIN, GiST, BRIN indexes for search and access optimization
- Native CHECK constraints, ENUM types, and enforced foreign keys

## SQL Dialect

PostgreSQL syntax differs from Snowflake in several key areas:

- Use `COUNT(*) FILTER (WHERE cond)` instead of `COUNT_IF(cond)`.
- Use `CASE WHEN cond THEN a ELSE b END` instead of `IFF(cond, a, b)`.
- Use `schema.table` instead of `database.schema.table` — PostgreSQL operates in a single-database context.
- Use `information_schema.*` directly — no database prefix needed.
- `::FLOAT` and `::NUMERIC` are both valid for casting.
- Use `EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ts)) / 3600` instead of `DATEDIFF('hour', ts, CURRENT_TIMESTAMP())`.
- Use `CURRENT_TIMESTAMP - INTERVAL '7 days'` instead of `DATEADD(day, -7, CURRENT_TIMESTAMP())`.
- Use `TABLESAMPLE BERNOULLI(pct)` instead of `TABLESAMPLE (N ROWS)` — PostgreSQL sampling is percentage-based.
- Use `LENGTH(col)` (same as Snowflake) for string length.
- Use `NULLIF(x, 0)` (same as Snowflake) for safe division.

## Metadata Access

- `information_schema` covers tables, columns, constraints, key_column_usage, referential_constraints, table_constraints, and column_privileges.
- Table and column comments are **not** in `information_schema.tables` or `information_schema.columns`. Use `pg_catalog`:
  ```sql
  -- Table comment
  SELECT obj_description(c.oid) FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relname = 'table_name' AND n.nspname = 'schema_name';

  -- Column comment
  SELECT col_description(attrelid, attnum)
  FROM pg_attribute
  WHERE attrelid = 'schema_name.table_name'::regclass AND attname = 'column_name';
  ```
- `pg_stat_user_tables` provides activity stats: `seq_scan`, `idx_scan`, `n_tup_ins`, `n_tup_upd`, `n_tup_del`, `last_analyze`, `last_autoanalyze`.
- `pg_indexes` provides index metadata including index definition text.
- `pg_depend` tracks object dependencies (views on tables, functions on types, etc.).
- `pg_policy` lists Row Level Security policies.
- `pg_seclabel` stores security labels (requires a label provider).
- `pg_matviews` lists materialized views and their definitions.
- `pg_views` lists views and their definitions.
- `pg_event_trigger` lists event triggers (DDL tracking).
- `pg_publication_tables` lists tables in logical replication publications.

## Extensions

Some checks depend on optional extensions. If an extension is not installed, the check degrades gracefully to N/A.

| Extension | Purpose | Check Dependencies |
|---|---|---|
| `pgvector` | Vector column types, HNSW/IVFFlat indexes | `embedding_coverage`, `embedding_dimension_consistency`, `vector_index_coverage` |
| `pgaudit` | Immutable audit logging | `access_audit_coverage` (enhanced mode) |
| `pg_stat_statements` | Query history analysis | `agent_attribution`, `pipeline_execution_audit`, `batch_throughput_sufficiency` |

Detect extensions with:
```sql
SELECT extname FROM pg_extension WHERE extname = 'pgvector';
```

## Row Level Security

PostgreSQL has native RLS. Enable per-table, then create policies:
```sql
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;
CREATE POLICY my_policy ON my_table FOR SELECT USING (tenant_id = current_setting('app.tenant_id'));
```

Check RLS status via `pg_class.relrowsecurity` and policies via `pg_policy`.

## Column-Level Access Control

PostgreSQL has no native masking policies. The closest equivalents are:
- Column-level `GRANT` / `REVOKE` on SELECT
- Views that mask sensitive columns
- The `postgresql_anonymizer` extension for declarative masking

Check column privileges via `information_schema.column_privileges`.

## Limitations

- No native time travel — use temporal table patterns (`valid_from`/`valid_to`), audit triggers, or SCD type 2.
- No native semantic views — use `COMMENT ON` for documentation.
- No native governance tags — use `pg_seclabel` (security labels) or structured comments.
- No per-query tagging (`QUERY_TAG`) — use `application_name` session parameter.
- No `load_history` — use `pg_stat_user_tables` activity counters or `pg_stat_statements`.
- `TABLESAMPLE` is percentage-based, not row-count-based.
- No `SHOW TABLES` + `RESULT_SCAN` pattern — use `pg_catalog` directly.

## Idempotency Guards

Before executing non-idempotent operations, run guard queries:

| Operation | Guard | Skip If |
|---|---|---|
| CREATE INDEX | `SELECT 1 FROM pg_indexes WHERE schemaname = '{schema}' AND indexname = '{index_name}'` | Has rows |
| CREATE POLICY | `SELECT 1 FROM pg_policy WHERE polname = '{policy_name}'` | Has rows |
| ALTER TABLE ENABLE ROW LEVEL SECURITY | `SELECT relrowsecurity FROM pg_class WHERE oid = '{schema}.{table}'::regclass` | Already `true` |
| COMMENT ON | No guard needed | COMMENT ON is idempotent (overwrites) |
| SECURITY LABEL | No guard needed | SECURITY LABEL is idempotent (overwrites) |
| ADD CONSTRAINT | `SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = '{name}' AND table_schema = '{schema}'` | Has rows |
| CREATE EXTENSION | `CREATE EXTENSION IF NOT EXISTS {ext}` | Safe with IF NOT EXISTS |
| CREATE PUBLICATION | `SELECT 1 FROM pg_publication WHERE pubname = '{name}'` | Has rows |

## Required Permissions

| Access | Minimum Grant |
|--------|--------------|
| `information_schema.*` | USAGE on schema + SELECT on tables |
| `pg_catalog.*` | Available to all roles by default |
| `pg_stat_user_tables` | Available to table owner or `pg_read_all_stats` |
| `pg_stat_statements` | `pg_read_all_stats` role or superuser |
| `pg_seclabel` | Available to all roles (read); SECURITY LABEL requires provider-specific privileges |
| `pg_policy` | Available to all roles by default |
| `pg_extension` | Available to all roles by default |
| CREATE POLICY | Table owner or superuser |
| CREATE INDEX | Table owner or superuser |
| COMMENT ON | Table owner or superuser |

```sql
GRANT pg_read_all_stats TO {role};
GRANT USAGE ON SCHEMA {schema} TO {role};
GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {role};
```
