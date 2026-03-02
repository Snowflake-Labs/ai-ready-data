-- =============================================================================
-- AI-Ready Data Assessment — Demo Environment Teardown
-- Target: SNOWFLAKE_LEARNING_DB.AIRDF_DEMO
--
-- Drops the entire demo schema and everything in it (tables, views, streams,
-- tags, masking policies, etc.). Safe to run multiple times.
-- =============================================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;

DROP SCHEMA IF EXISTS AIRDF_DEMO CASCADE;
