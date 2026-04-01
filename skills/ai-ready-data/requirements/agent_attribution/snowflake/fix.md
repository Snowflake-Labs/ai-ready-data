# Fix: agent_attribution

Establish query tagging conventions for pipelines and agents that write to this schema.

## Context

Snowflake's `QUERY_TAG` is a session-level parameter that attaches a free-text label to every query in the session. Setting it before write operations ensures those operations appear in `query_history` with meaningful attribution.

This is not a one-time DDL fix — it requires changes to pipeline and agent code. The remediation is organizational: every pipeline, agent, or process that writes to this schema should set `QUERY_TAG` at session start.

## Fix: Set QUERY_TAG in pipeline sessions

Each pipeline or agent should execute this at the start of its session, before any write operations:

```sql
ALTER SESSION SET QUERY_TAG = '{{ query_tag }}';
```

A good `QUERY_TAG` format includes the pipeline or agent name and a run identifier, e.g. `pipeline=daily_load;run_id=2024-01-15-001` or `agent=cortex_analyst;session=abc123`.

## Fix: Verify tagging is working

After deploying query tags, re-run the check after the 45-minute `query_history` latency window to confirm the score improves.
