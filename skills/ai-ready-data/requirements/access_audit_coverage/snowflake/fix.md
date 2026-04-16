# Fix: access_audit_coverage

Remediation guidance for tables without recorded access audit events.

## Context

Snowflake's `access_history` is automatic and immutable — there is no DDL or DML to "enable" auditing on individual tables. If tables show as unaudited, the cause is one of:

1. **No queries have touched the table** in the lookback window. This is expected for dormant or archive tables. No action needed unless the table should be actively consumed by AI workloads.
2. **Missing IMPORTED PRIVILEGES.** The role running the assessment needs `IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE` to read `account_usage.access_history`. Grant this to the assessment role.
3. **Latency.** Recently created tables or tables accessed within the last ~2 hours may not appear yet. Re-run the check after the latency window.

## Fix: Grant access to audit views

```sql
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE {{ role }};
```