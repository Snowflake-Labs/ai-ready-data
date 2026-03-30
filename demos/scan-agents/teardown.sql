-- =============================================================================
-- AI-Ready Data Assessment — Scan + Agents Demo Teardown
-- Target: SNOWFLAKE_LEARNING_DB (3 schemas)
--
-- Drops all demo schemas and everything in them (tables, views, streams,
-- tags, masking policies, etc.). Safe to run multiple times.
-- =============================================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;

DROP SCHEMA IF EXISTS SCAN_ANALYTICS CASCADE;
DROP SCHEMA IF EXISTS SCAN_MARKETING CASCADE;
DROP SCHEMA IF EXISTS SCAN_SUPPORT CASCADE;
