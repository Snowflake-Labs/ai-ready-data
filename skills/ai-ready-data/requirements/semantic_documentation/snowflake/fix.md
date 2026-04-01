# Fix: semantic_documentation

Remediation strategies for tables lacking machine-readable semantic descriptions.

## Context

There are two remediation paths with very different outcomes. Present both options and recommend the semantic view path:

```
Your Contextual stage is failing. Two remediation paths:

  1. Semantic View (recommended)
     Creates a machine-readable model of your tables, relationships,
     metrics, and dimensions. Powers Text-to-SQL, Cortex Analyst,
     and agentic queries. This is the strongest fix.

  2. Column/Table Comments (lightweight)
     Adds human-readable descriptions to tables and columns.
     Improves documentation score but doesn't enable structured
     query generation.

Which approach?
```

If the user picks comments, fall back to the [add-comments](#remediation-add-comments) section.

If the user picks semantic view (or the profile is `agents`), proceed with the guided builder below.

---

## Remediation: create-semantic-view

Create a semantic view covering the target tables. This is the preferred remediation — it provides machine-readable metadata that powers Text-to-SQL, Cortex Analyst, and agent tool use.

Trigger this workflow when **any** of the following requirements fail in the Contextual stage:

- `semantic_documentation` — tables lack machine-readable descriptions
- `relationship_declaration` — cross-entity references have no declared join paths

### Step 1: Discover Schema

Run diagnostics to understand what the user has. Use the scope already established in the assessment.

```sql
SELECT c.table_name, c.column_name, c.data_type, c.comment,
       t.comment AS table_comment, t.row_count
FROM {database}.information_schema.columns c
JOIN {database}.information_schema.tables t
    ON c.table_catalog = t.table_catalog
    AND c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{schema}'
    AND t.table_type = 'BASE TABLE'
ORDER BY c.table_name, c.ordinal_position
```

```sql
SHOW PRIMARY KEYS IN SCHEMA {database}.{schema};

CREATE OR REPLACE TEMPORARY TABLE _pk_cols AS
SELECT "table_name" AS table_name, "column_name" AS column_name, 'PRIMARY KEY' AS constraint_type
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW IMPORTED KEYS IN SCHEMA {database}.{schema};

CREATE OR REPLACE TEMPORARY TABLE _fk_cols AS
SELECT "fk_table_name" AS table_name, "fk_column_name" AS column_name,
       "pk_table_name" AS ref_table, "pk_column_name" AS ref_column,
       'FOREIGN KEY' AS constraint_type
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SELECT table_name, column_name, constraint_type, NULL AS ref_table, NULL AS ref_column
FROM _pk_cols
UNION ALL
SELECT table_name, column_name, constraint_type, ref_table, ref_column
FROM _fk_cols
ORDER BY table_name;

DROP TABLE IF EXISTS _pk_cols;
DROP TABLE IF EXISTS _fk_cols;
```

Present a summary:

```
Your schema has {N} tables:

  Table              Rows       Columns   Keys
  ─────              ────       ───────   ────
  CUSTOMERS          1.2M       12        PK: customer_id
  ORDERS             8.4M       9         PK: order_id, FK → CUSTOMERS
  ORDER_ITEMS        22M        6         FK → ORDERS, FK → PRODUCTS
  PRODUCTS           50K        8         PK: product_id

  Detected relationships:
    ORDERS.customer_id → CUSTOMERS.customer_id
    ORDER_ITEMS.order_id → ORDERS.order_id
    ORDER_ITEMS.product_id → PRODUCTS.product_id
```

### Step 2: Interview — Tables and Roles

Ask the user to confirm or correct the table roles:

```
For each table, I need to know its role in your data model.
Here's my best guess based on the schema:

  CUSTOMERS      → dimension (entity attributes)
  ORDERS         → fact (transactional events)
  ORDER_ITEMS    → fact (transactional line items)
  PRODUCTS       → dimension (entity attributes)

Does this look right? Any corrections?
```

**Heuristics for guessing table roles:**

- Tables with timestamp columns + numeric measures → likely **fact** tables
- Tables with a single primary key + descriptive columns → likely **dimension** tables
- Tables that are FK targets from many others → likely **dimension** tables
- Tables with composite keys or many FK columns → likely **fact** or **bridge** tables

### Step 3: Interview — Relationships

Present the detected relationships and ask for confirmation/additions:

```
These relationships will define the join paths in your semantic view:

  ORDERS.customer_id → CUSTOMERS.customer_id
  ORDER_ITEMS.order_id → ORDERS.order_id
  ORDER_ITEMS.product_id → PRODUCTS.product_id

Any relationships to add, remove, or correct?
```

If no FK constraints exist, infer possible relationships from column name patterns (e.g., `customer_id` in ORDERS likely joins to `CUSTOMERS.customer_id`) and ask the user to confirm.

### Step 4: Interview — Metrics

Ask about key business metrics. Only ask for fact tables:

```
What metrics matter for your analysis? I'll look at your numeric columns:

  ORDERS:
    total_amount    → SUM? AVG?
    discount        → SUM?
    shipping_cost   → SUM?

  ORDER_ITEMS:
    quantity        → SUM?
    unit_price      → AVG?
    line_total      → SUM?

Which of these are important metrics, and what aggregation makes sense?
```

### Step 5: Interview — Dimensions and Descriptions

Ask the user to confirm dimension columns and provide descriptions for any columns that lack comments:

```
I'll use these as dimensions (filterable/groupable attributes):

  CUSTOMERS: region, segment, created_date
  PRODUCTS: category, subcategory, brand
  ORDERS: order_date, status, channel

Any to add or remove?
```

For columns lacking comments, ask the user to provide brief descriptions:

```
These columns don't have descriptions yet. Brief descriptions help
Cortex Analyst and agents understand your data:

  CUSTOMERS.segment     → ?
  CUSTOMERS.ltv_score   → ?
  ORDERS.channel        → ?
  PRODUCTS.subcategory  → ?
```

### Step 6: Generate and Review

Build the semantic view DDL from the interview answers. Present the full SQL for review:

```sql
CREATE OR REPLACE SEMANTIC VIEW {database}.{schema}.{semantic_view_name}

    TABLES (
        {database}.{schema}.CUSTOMERS
            AS customers
            COMMENT = 'Customer master data with demographics and segmentation',
        {database}.{schema}.ORDERS
            AS orders
            COMMENT = 'Order transactions with totals and status',
        ...
    )

    RELATIONSHIPS (
        orders (customer_id) REFERENCES customers (customer_id),
        order_items (order_id) REFERENCES orders (order_id),
        ...
    )

    FACTS (
        orders.total_amount COMMENT = 'Total order value including tax',
        order_items.quantity COMMENT = 'Number of units ordered',
        ...
    )

    DIMENSIONS (
        customers.region COMMENT = 'Geographic sales region',
        customers.segment COMMENT = 'Customer segmentation tier',
        orders.order_date COMMENT = 'Date the order was placed',
        ...
    )

    METRICS (
        total_revenue AS SUM(orders.total_amount) COMMENT = 'Sum of all order values',
        avg_order_value AS AVG(orders.total_amount) COMMENT = 'Average order value',
        ...
    )

    COMMENT = 'Semantic model for {schema} — covers customers, orders, and products'
```

**Checkpoint:** "Deploy this semantic view? You can also edit the SQL first."

### Step 7: Deploy and Verify

On approval:

1. Execute the `CREATE OR REPLACE SEMANTIC VIEW` statement.
2. Verify deployment:

```sql
SHOW SEMANTIC VIEWS LIKE '{semantic_view_name}' IN SCHEMA {database}.{schema};
```

```sql
SELECT sv.name, st.base_table_name, st.comment
FROM {database}.information_schema.semantic_views sv
JOIN {database}.information_schema.semantic_tables st
    ON sv.catalog = st.semantic_view_catalog
    AND sv.schema = st.semantic_view_schema
    AND sv.name = st.semantic_view_name
WHERE sv.schema = '{schema}'
```

3. Re-run the semantic documentation check to confirm the score improved.
4. Return to the main remediation workflow.

### Naming Convention

Default semantic view name: `SV_{SCHEMA}` (e.g., `SV_ANALYTICS`). If the user's scope covers specific tables rather than a full schema, use `SV_{primary_table}` (e.g., `SV_ORDERS`). Always let the user override the name.

### Syntax Reference

```sql
CREATE OR REPLACE SEMANTIC VIEW db.schema.view_name

    TABLES (
        db.schema.TABLE_NAME AS alias COMMENT = 'description',
        ...
    )

    RELATIONSHIPS (
        child_alias (fk_col) REFERENCES parent_alias (pk_col),
        ...
    )

    FACTS (
        alias.column COMMENT = 'description',
        ...
    )

    DIMENSIONS (
        alias.column COMMENT = 'description',
        ...
    )

    METRICS (
        metric_name AS AGG(alias.column) COMMENT = 'description',
        ...
    )

    COMMENT = 'overall description'
```

Key rules:
- `TABLES` lists base tables with aliases and optional comments.
- `RELATIONSHIPS` uses alias names, not fully qualified table names.
- `FACTS` are numeric columns on fact tables (measures).
- `DIMENSIONS` are categorical/temporal columns used for filtering and grouping.
- `METRICS` are named aggregations over facts.
- There is **no** `COLUMNS` clause — do not use one.
- `CREATE OR REPLACE` is safe for semantic views — they are declarative and idempotent.

---

## Remediation: add-comments

Add comments to tables and columns. This is a fallback for users who cannot or choose not to create semantic views. Comments improve human readability and basic tooling support but do not enable Text-to-SQL or Cortex Analyst.

```sql
COMMENT ON TABLE {{ database }}.{{ schema }}.{{ asset }} IS '{{ table_comment }}';
COMMENT ON COLUMN {{ database }}.{{ schema }}.{{ asset }}.{{ column }} IS '{{ column_comment }}'
```
