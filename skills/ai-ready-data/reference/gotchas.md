# Snowflake Gotchas

Critical SQL patterns, pitfalls, and permissions for Snowflake operations. Read this before executing any SQL.

---

## Column Naming in SHOW Commands

`SHOW TABLES`, `SHOW STREAMS`, etc. return columns with **lowercase quoted names**. Always use double quotes when referencing them in `RESULT_SCAN`:

```sql
-- Correct
SELECT "change_tracking", "search_optimization" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))

-- Wrong (will fail)
SELECT change_tracking, SEARCH_OPTIMIZATION FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
```

`SHOW TABLES` + `RESULT_SCAN` must run in the **same session**. If the session resets between the two statements, `RESULT_SCAN` will fail.

---

## change_tracking Is NOT in information_schema

The `change_tracking` status is **not available** in `information_schema.tables`. You must use:

```sql
SHOW TABLES IN SCHEMA {database}.{schema};
SELECT "change_tracking" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
```

---

## account_usage Latency

Views in `snowflake.account_usage` have **~2 hour latency** for new objects:

- `tag_references` — new tags won't appear immediately
- `policy_references` — new masking/row access policies won't appear immediately

Warn the user if freshly created objects don't show up in these views.

---

## tag_references Has No `deleted` Column

`snowflake.account_usage.tag_references` does **not** have a `deleted` column. Don't filter on it.

---

## policy_references Column Names

In `snowflake.account_usage.policy_references`:
- Use `ref_column_name`, **not** `column_name`
- Use `ref_entity_name`, **not** `table_name`

---

## Masking Policies: IS_ROLE_IN_SESSION

**Always** use `IS_ROLE_IN_SESSION()` in masking policies. **Never** use `CURRENT_ROLE()`.

`CURRENT_ROLE()` does not respect role hierarchy — a user with ACCOUNTADMIN active but checking via an inherited role will be masked. This is a major security anti-pattern.

```sql
-- Correct
CASE WHEN IS_ROLE_IN_SESSION('ADMIN_ROLE') THEN val ELSE '***' END

-- Wrong (breaks role hierarchy)
CASE WHEN CURRENT_ROLE() = 'ADMIN_ROLE' THEN val ELSE '***' END
```

---

## last_altered Reflects DDL, Not DML

`information_schema.tables.last_altered` updates on **schema changes** (ALTER TABLE, column adds/drops), **not** on data changes (INSERT, UPDATE, DELETE). A table receiving daily loads may show a stale `last_altered` if no DDL has occurred.

For true data freshness, prefer:
- **Streams** — `SYSTEM$STREAM_HAS_DATA()` detects actual row changes
- **Dynamic tables** — `DATA_TIMESTAMP` in `SHOW DYNAMIC TABLES` reflects last refresh
- **Explicit timestamp columns** — `MAX(updated_at)` on the table itself

---

## No ALTER COLUMN SET DEFAULT

Snowflake does **not** support `ALTER TABLE ... ALTER COLUMN ... SET DEFAULT`. Defaults must be set at table creation time or handled via application logic.

---

## Semantic View Syntax

Semantic views use `TABLES`, `RELATIONSHIPS`, `FACTS`, `DIMENSIONS`, `METRICS` clauses. There is **no** `COLUMNS` clause — don't use it.

---

## Required Permissions

| Access | Minimum Grant |
|--------|--------------|
| `information_schema.*` | USAGE on schema |
| `snowflake.account_usage.tag_references` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `snowflake.account_usage.policy_references` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `snowflake.account_usage.access_history` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `SNOWFLAKE.CORTEX.*` | USAGE on SNOWFLAKE.CORTEX schema |
| `SNOWFLAKE.CORE.*` (DMFs) | USAGE on SNOWFLAKE.CORE schema |

### Grant Pattern

```sql
-- For governance views (tags, policies)
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE {role};

-- For Cortex functions
GRANT USAGE ON SCHEMA SNOWFLAKE.CORTEX TO ROLE {role};
```
