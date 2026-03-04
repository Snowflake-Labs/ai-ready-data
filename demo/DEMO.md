# AI-Ready Data Assessment — Demo Guide

End-to-end walkthrough: install the skill, provision a demo dataset in Snowflake, run an assessment, remediate failures, and tear down.

## Prerequisites

| Requirement | How to check |
|---|---|
| Snowflake account with `SNOWFLAKE_LEARNING_DB` access | `/sql SELECT CURRENT_ACCOUNT()` in Cortex Code |
| Cortex Code CLI installed | `cortex --version` |
| Connection configured in `~/.snowflake/connections.toml` | `cortex -c <connection>` connects successfully |
| Node.js / npx available | `npx --version` |
| Role with CREATE SCHEMA on `SNOWFLAKE_LEARNING_DB` | Ask your admin or use ACCOUNTADMIN for the demo |
| `IMPORTED PRIVILEGES` on the SNOWFLAKE database (for governance checks) | `/sql SHOW GRANTS ON DATABASE SNOWFLAKE` |

If `SNOWFLAKE_LEARNING_DB` does not exist, create it first:

```sql
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_LEARNING_DB;
```

---

## Step 1: Install the Skill

Install into Cortex Code CLI from this repo (local path or GitHub):

```bash
# From a local clone
npx add-skill ./path/to/ai-ready-data-agent -a cortex

# Or from GitHub (once published)
npx add-skill your-org/ai-ready-data -a cortex
```

Verify it was installed:

```
cortex
/skill list
```

You should see `ai-ready-data` in the list.

---

## Step 2: Provision the Demo Environment

Start Cortex Code with your Snowflake connection:

```bash
cortex -c <your-connection> -w /path/to/ai-ready-data-agent
```

Then ask Cortex Code to run the setup script:

```
Run the SQL in demo/setup.sql
```

Alternatively, paste the contents of `demo/setup.sql` after the `/sql` command.

The script creates `SNOWFLAKE_LEARNING_DB.AIRDF_DEMO` with 8 tables:

| Table | Rows | Description |
|---|---|---|
| CUSTOMERS | 20 | Core entity with PII (email, phone, address) |
| PRODUCTS | 15 | Product catalog with pricing |
| ORDERS | 25 | Transactions — includes duplicates, orphans, invalid statuses |
| ORDER_ITEMS | 26 | Line items linking orders to products |
| PRODUCT_REVIEWS | 10 | Reviews with JSON payloads (some invalid) |
| SUPPLIER_CONTRACTS | 7 | Contracts with date ranges |
| INVENTORY_SNAPSHOTS | 15,000 | Large generated table — no clustering key |
| MARKETING_EVENTS | 12 | Behavioral events with JSON payloads |

The final query in the script prints row counts for all tables. Confirm all 8 appear.

---

## Step 3: Run the Assessment

Trigger the skill:

```
Assess SNOWFLAKE_LEARNING_DB.AIRDF_DEMO for RAG readiness
```

The agent will:

1. Load `assessments/rag.yaml` (6 stages, one per factor of AI-ready data)
2. Discover the 8 tables in `AIRDF_DEMO`
3. Ask you to confirm scope and offer override options (skip/set/add)
4. Run check SQL for each requirement, stage by stage
5. Present a scored report

You can also try other assessments:

```
Assess SNOWFLAKE_LEARNING_DB.AIRDF_DEMO for feature serving readiness
Assess SNOWFLAKE_LEARNING_DB.AIRDF_DEMO for training readiness
Assess SNOWFLAKE_LEARNING_DB.AIRDF_DEMO for agents readiness
```

### What to expect

The demo data is designed to produce failures across every stage, giving you material to demonstrate the full lifecycle:

| Stage (Factor) | Expected | Why |
|---|---|---|
| Clean | FAIL | Nulls, duplicates, encoding errors, bad types, invalid categories, orphan FKs |
| Contextual | FAIL | No column comments, no primary keys, no constraints |
| Consumable | FAIL | No embeddings, no vector indexes, no chunks, no clustering |
| Current | FAIL | No change tracking, no streams |
| Correlated | Partial | Query history may show some agent attribution |
| Compliant | FAIL | PII columns without masking, no tags, no row access policies |

After the report, the agent offers four options:
- **remediate** — fix failing stages
- **export** — get results as JSON
- **tell-me-more** — run diagnostic SQL on specific failures
- **done** — stop

---

## Step 4: Explore Diagnostics

Pick a failing requirement and ask for details:

```
Tell me more about data_completeness
```

The agent runs the diagnostic SQL and shows which columns have nulls, how many, and in which tables. This is useful for demonstrating the drill-down workflow before committing to fixes.

---

## Step 5: Remediate

Start the remediation loop:

```
Remediate the Clean stage
```

The agent will:

1. Show which requirements are failing
2. Load fix SQL for each one
3. Present a remediation plan with the exact SQL it will run
4. Wait for your approval before executing
5. Re-run the check SQL to show before/after scores

Good requirements to remediate live in the demo (the agent will handle this automatically, but these make the best talking points):

| Requirement | What the fix does |
|---|---|
| `data_completeness` | Fill nulls with defaults or delete incomplete rows |
| `uniqueness` | Deduplicate the ORDERS table |
| `encoding_validity` | Replace encoding errors (U+FFFD, null bytes) |
| `entity_identifier_declaration` | Add primary key constraints |
| `semantic_documentation` | Add column and table comments |
| `change_detection` | Enable change tracking on tables |
| `access_optimization` | Add clustering key to INVENTORY_SNAPSHOTS |

After each stage remediation, the agent shows the improvement and moves to the next failing stage.

---

## Step 6: Tear Down

When finished:

```
Run the SQL in demo/teardown.sql
```

Or manually:

```
/sql DROP SCHEMA IF EXISTS SNOWFLAKE_LEARNING_DB.AIRDF_DEMO CASCADE;
```

This removes all tables, views, streams, tags, masking policies, and anything else created during the demo. Safe to run multiple times.

---

## Tips for a Live Demo

- **Start with the assessment.** The stage-by-stage report is the visual anchor. Let it finish before jumping into remediation.
- **Pick Clean for the first remediation.** It has the most tangible before/after (nulls disappear, duplicates removed, encoding fixed).
- **Show a diagnostic drill-down** before remediating to demonstrate the two-phase workflow (understand, then fix).
- **Consumable stage (RAG checks)** — skip `embedding_coverage` and `vector_index_coverage` unless you have Cortex embedding functions available. Those checks require `SNOWFLAKE.CORTEX` access. This is a good opportunity to demonstrate the `skip` override.
- **Compliant stage** checks that use `snowflake.account_usage` views (tags, policies) have ~2 hour latency for newly created objects. If you create tags/policies during remediation, the checks may still show FAIL until the views catch up. Mention this as a known Snowflake behavior.
- **Re-run the full assessment** after remediating a couple of stages to show the overall score improving.

---

## File Reference

| File | Purpose |
|---|---|
| `demo/setup.sql` | Creates the demo schema and loads data with intentional issues |
| `demo/teardown.sql` | Drops the entire demo schema |
| `demo/DEMO.md` | This guide |
