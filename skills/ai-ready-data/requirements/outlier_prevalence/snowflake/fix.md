# Fix: outlier_prevalence

Remediation guidance for datasets with high outlier prevalence.

## Context

Outliers detected by z-score may be legitimate extreme values, data entry errors, or upstream processing artifacts. Before removing or adjusting outliers, determine the root cause. Blindly removing statistical outliers can distort distributions and introduce bias in training data.

## Fix: Investigate outliers

Use the diagnostic query to identify specific outlier rows and their z-scores. Common root causes:
- **Data entry errors** — fix at the source or correct the values
- **Unit mismatches** — values recorded in different units (e.g., cents vs dollars)
- **Processing artifacts** — sentinel values like -1, 9999, or 0 used as placeholders

## Fix: Clamp outlier values (symmetric)

If outliers are confirmed as errors and the correct value is unknown, clamp to the nearest boundary. This clamps both the upper and lower tail to `mean ± stddev_threshold * stddev`. Evaluates the table statistics in a single pass to keep the UPDATE cheap.

```sql
WITH bounds AS (
    SELECT
        AVG({{ column }}) - {{ stddev_threshold }} * STDDEV({{ column }}) AS lower_bound,
        AVG({{ column }}) + {{ stddev_threshold }} * STDDEV({{ column }}) AS upper_bound
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
)
UPDATE {{ database }}.{{ schema }}.{{ asset }} t
SET t.{{ column }} = CASE
    WHEN t.{{ column }} < b.lower_bound THEN b.lower_bound
    WHEN t.{{ column }} > b.upper_bound THEN b.upper_bound
END
FROM bounds b
WHERE t.{{ column }} IS NOT NULL
  AND (t.{{ column }} < b.lower_bound OR t.{{ column }} > b.upper_bound);
```

## Fix: Exclude outliers from AI consumption

If outliers are legitimate but should be excluded from training:

```sql
CREATE OR REPLACE VIEW {{ database }}.{{ schema }}.{{ asset }}_clean AS
SELECT * FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE ABS(({{ column }} - (SELECT AVG({{ column }}) FROM {{ database }}.{{ schema }}.{{ asset }}))
    / NULLIF((SELECT STDDEV({{ column }}) FROM {{ database }}.{{ schema }}.{{ asset }}), 0)) <= {{ stddev_threshold }}
```
