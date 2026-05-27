-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 01: Create Table and Insert 5 Million Rows
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
-- 
-- USAGE: psql -d bloat_lab -f 01-create-table.sql
--
-- PREREQUISITES:
--   createdb bloat_lab
--
-- TIME: ~2-5 minutes for 5M rows
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_freespacemap;

-- Drop table if exists (safe for re-running)
DROP TABLE IF EXISTS user_sessions CASCADE;

-- Create table simulating a SaaS session store
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    ip_address INET,
    device_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Insert 5 million rows with realistic data distribution
INSERT INTO user_sessions (
    user_id, session_token, ip_address, device_info
)
SELECT
    (random() * 100000)::int,
    md5(random()::text),
    ('192.168.' || (random()*255)::int || '.' || (random()*255)::int)::inet,
    jsonb_build_object(
        'browser', (ARRAY['Chrome','Firefox','Safari','Edge'])[ceil(random()*4)],
        'os', (ARRAY['Windows','macOS','Linux','iOS','Android'])[ceil(random()*5)],
        'version', (random()*100)::int
    )
FROM generate_series(1, 5000000);

-- Update statistics
ANALYZE user_sessions;

-- Verify insert
SELECT 
    'user_sessions' AS table_name,
    count(*) AS row_count,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    pg_size_pretty(pg_indexes_size('user_sessions')) AS index_size,
    pg_size_pretty(pg_total_relation_size('user_sessions')) AS total_size
FROM user_sessions;
