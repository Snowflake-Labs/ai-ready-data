# Fix: lineage_completeness

No automated remediation is available for this requirement.

## Context

Lineage completeness depends on queries flowing through Snowflake's `ACCESS_HISTORY`, which is populated automatically when tables are read or written. There is no DDL or DML that directly "adds" lineage to a table.

To improve this score:

1. **Run workloads through Snowflake** — lineage is captured when queries reference tables. If ETL or analytics jobs bypass Snowflake (e.g., external tools reading exported files), those tables will lack lineage records.
2. **Wait for latency** — `ACCESS_HISTORY` has approximately 2-hour latency. Recently loaded or queried tables may not yet appear.
3. **Verify permissions** — the querying role needs IMPORTED PRIVILEGES on the `SNOWFLAKE` database to read `account_usage.access_history`.
4. **Extend the lookback window** — if tables are accessed infrequently, the 7-day check window may miss them. The diagnostic query uses a 30-day window for broader coverage.