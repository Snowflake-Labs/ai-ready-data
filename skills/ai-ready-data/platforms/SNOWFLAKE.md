# Snowflake

Snowflake is the baseline platform for this framework. All 61 requirements have Snowflake implementations.

## Capabilities

- Semantic views (CREATE SEMANTIC VIEW) for machine-readable schema documentation
- Native column masking policies
- Row access policies
- Vector column types and vector index introspection
- Lineage via `snowflake.account_usage.access_history`
- Governance tags via `snowflake.account_usage.tag_references`
- Change tracking on tables and streams
- Full SQL-based check and fix execution

## SQL Dialect

- Use `::FLOAT` for casting, `COUNT_IF()` for conditional counts, `NULLIF()` for safe division.
- `SHOW` commands return lowercase quoted column names. Always use double quotes in `RESULT_SCAN`:
  ```sql
  SELECT "change_tracking" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
  ```
- `SHOW` + `RESULT_SCAN` must run in the **same session**. If the session resets between statements, `RESULT_SCAN` fails.

## Metadata Access

- `information_schema` is available for tables, columns, constraints, and views.
- `change_tracking` status is **not** in `information_schema.tables` — must use `SHOW TABLES` + `RESULT_SCAN`.
- `snowflake.account_usage` views (`tag_references`, `policy_references`, `access_history`) have **~2 hour latency** for newly created objects. Warn users if fresh objects don't appear.
- `tag_references` has no `deleted` column — do not filter on it.
- `policy_references` uses `ref_column_name` and `ref_entity_name`, not `column_name` or `table_name`.
- `last_altered` in `information_schema.tables` reflects DDL changes (ALTER TABLE), not DML (INSERT/UPDATE). For true freshness, use streams, dynamic tables, or explicit timestamp columns.

## Masking Policies

Always use `IS_ROLE_IN_SESSION()` in masking policies. Never use `CURRENT_ROLE()` — it does not respect role hierarchy.

```sql
-- Correct
CASE WHEN IS_ROLE_IN_SESSION('ADMIN_ROLE') THEN val ELSE '***' END

-- Wrong
CASE WHEN CURRENT_ROLE() = 'ADMIN_ROLE' THEN val ELSE '***' END
```

## Semantic Views

Semantic views use `TABLES`, `RELATIONSHIPS`, `FACTS`, `DIMENSIONS`, `METRICS` clauses. There is **no** `COLUMNS` clause. `CREATE OR REPLACE` is safe — semantic views are declarative and idempotent.

For the full semantic view builder workflow, see `requirements/semantic_documentation/snowflake/semantic-view-builder.md`.

## Limitations

- `ALTER TABLE ... ALTER COLUMN ... SET DEFAULT` is not supported. Defaults must be set at table creation or handled in application logic.

## Idempotency Guards

Before executing non-idempotent operations, run guard queries to check if the desired state already exists:

| Operation | Guard | Skip If |
|---|---|---|
| CREATE TAG | `SHOW TAGS LIKE '{tag_name}' IN SCHEMA {schema}` | Has rows |
| CREATE MASKING POLICY | `SHOW MASKING POLICIES LIKE '{policy_name}' IN SCHEMA {schema}` | Has rows |
| CREATE STREAM | `SHOW STREAMS LIKE '{stream_name}' IN SCHEMA {schema}` | Has rows |
| ALTER COLUMN SET NOT NULL | `DESCRIBE TABLE {asset}` | Column already NOT NULL |
| CREATE SEMANTIC VIEW | No guard needed | `CREATE OR REPLACE` is safe |

## Skill Delegations

Some requirements delegate remediation to specialized workflows:

| Requirement | Delegate To | When |
|---|---|---|
| `semantic_documentation` | Semantic View Builder (`requirements/semantic_documentation/snowflake/semantic-view-builder.md`) | Contextual stage fails and tables lack semantic views |
| `column_masking` | `data-policy` skill | Before creating masking policies |
| `classification` | `sensitive-data-classification` skill | Before creating tags via SYSTEM$CLASSIFY |

## Required Permissions

| Access | Minimum Grant |
|--------|--------------|
| `information_schema.*` | USAGE on schema |
| `snowflake.account_usage.tag_references` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `snowflake.account_usage.policy_references` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `snowflake.account_usage.access_history` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `SNOWFLAKE.CORTEX.*` | USAGE on SNOWFLAKE.CORTEX schema |
| `SNOWFLAKE.CORE.*` (DMFs) | USAGE on SNOWFLAKE.CORE schema |

```sql
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE {role};
GRANT USAGE ON SCHEMA SNOWFLAKE.CORTEX TO ROLE {role};
```
