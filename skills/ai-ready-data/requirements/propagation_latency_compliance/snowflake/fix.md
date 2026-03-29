# Fix: propagation_latency_compliance

Fraction of data pipelines where end-to-end propagation latency meets the defined freshness SLA.

## Remediation Guidance

1. **Resume suspended dynamic tables** — If the diagnostic shows `SUSPENDED` scheduling state, resume the table:
   ```sql
   ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.<table_name> RESUME;
   ```

2. **Adjust target lag** — If actual lag consistently exceeds the target, the warehouse may be undersized or the target unrealistic. Increase the target lag to match operational reality, or scale up the warehouse:
   ```sql
   ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.<table_name> SET TARGET_LAG = '10 minutes';
   ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.<table_name> SET WAREHOUSE = <larger_warehouse>;
   ```

3. **Create dynamic tables for unmanaged pipelines** — If data is loaded via external ETL with no latency tracking, consider wrapping downstream transformations in dynamic tables to gain declarative freshness guarantees:
   ```sql
   CREATE OR REPLACE DYNAMIC TABLE {{ database }}.{{ schema }}.<table_name>
       TARGET_LAG = '5 minutes'
       WAREHOUSE = <warehouse>
   AS
       SELECT * FROM {{ database }}.{{ schema }}.<source_table>;
   ```

4. **Monitor with DYNAMIC_TABLE_REFRESH_HISTORY** — For ongoing compliance tracking:
   ```sql
   SELECT *
   FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
       NAME => '{{ database }}.{{ schema }}.<table_name>'
   ))
   ORDER BY REFRESH_START_TIME DESC
   LIMIT 20;
   ```
