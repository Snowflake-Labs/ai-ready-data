# Fix: outlier_prevalence

Remediation guidance for datasets with high outlier prevalence.

## Context

Outliers detected by z-score may be legitimate extreme values, data entry errors, or upstream processing artifacts. Before removing or adjusting outliers, determine the root cause. Blindly removing statistical outliers can distort distributions and introduce bias in training data.

## Remediation: Investigate outliers

Use the diagnostic query to identify specific outlier rows and their z-scores. Common root causes:
- **Data entry errors** — fix at the source or correct the values
- **Unit mismatches** — values recorded in different units (e.g., cents vs dollars)
- **Processing artifacts** — sentinel values like -1, 9999, or 0 used as placeholders

## Remediation: Clamp outlier values

If outliers are confirmed as errors and the correct value is unknown, clamp to the boundary:

```sql
UPDATE {{ schema }}.{{ asset }}
SET {{ column }} = sub.upper_bound
FROM (
    SELECT AVG({{ column }}) + {{ stddev_threshold }} * STDDEV({{ column }}) AS upper_bound
    FROM {{ schema }}.{{ asset }}
) sub
WHERE {{ column }} > sub.upper_bound
```

```sql
UPDATE {{ schema }}.{{ asset }}
SET {{ column }} = sub.lower_bound
FROM (
    SELECT AVG({{ column }}) - {{ stddev_threshold }} * STDDEV({{ column }}) AS lower_bound
    FROM {{ schema }}.{{ asset }}
) sub
WHERE {{ column }} < sub.lower_bound
```

## Remediation: Exclude outliers from AI consumption

If outliers are legitimate but should be excluded from training, create a filtered view:

```sql
CREATE OR REPLACE VIEW {{ schema }}.{{ asset }}_clean AS
SELECT *
FROM {{ schema }}.{{ asset }} t
CROSS JOIN (
    SELECT
        AVG({{ column }}) AS mean_val,
        STDDEV({{ column }}) AS stddev_val
    FROM {{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
) s
WHERE t.{{ column }} IS NOT NULL
    AND ABS(t.{{ column }} - s.mean_val) / NULLIF(s.stddev_val, 0) <= {{ stddev_threshold }}
```
