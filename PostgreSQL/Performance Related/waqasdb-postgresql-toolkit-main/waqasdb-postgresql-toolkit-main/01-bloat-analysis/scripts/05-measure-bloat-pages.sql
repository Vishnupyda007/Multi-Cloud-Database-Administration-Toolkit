cat > 01-bloat-analysis/scripts/05-measure-bloat-pages.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 05: Measure Bloat at Page Level (Deep Analysis)
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 05-measure-bloat-pages.sql
--
-- PURPOSE: Inspect EVERY 8KB page on disk using pg_freespacemap.
--          This reveals internal fragmentation that tuple-level
--          analysis cannot show.
--
-- Each PostgreSQL page = 8,192 bytes (8 KB)
-- "avail" = free bytes available inside that page
-- avail = 0 means page is fully packed (healthy)
-- avail = 8192 means page is completely empty (waste)
-- ============================================================

-- 1. Raw Free Space Distribution (All Pages)
SELECT
    avail,
    count(*) AS pages,
    ROUND(count(*) * 8.0 / 1024, 2) AS size_mb
FROM pg_freespace('user_sessions')
GROUP BY avail
ORDER BY avail;

-- 2. Categorized Page Health Summary
SELECT
    CASE
        WHEN avail = 0 THEN '1-FULL: Fully Packed (0 bytes free)'
        WHEN avail <= 1024 THEN '2-MINOR: Minor Gaps (1-1024 bytes)'
        WHEN avail <= 2048 THEN '3-MODERATE: Moderate Holes (1-2 KB free)'
        WHEN avail <= 4096 THEN '4-HEAVY: Heavy Damage (2-4 KB free)'
        WHEN avail <= 6144 THEN '5-SEVERE: Severely Empty (4-6 KB free)'
        ELSE '6-NEAR_EMPTY: Near Empty Pages (6-8 KB free)'
    END AS page_health,
    count(*) AS pages,
    ROUND(count(*) * 8.0 / 1024, 2) AS size_mb,
    ROUND(count(*) * 100.0 /
        (SELECT count(*) FROM pg_freespace('user_sessions')), 2
    ) AS pct_of_table
FROM pg_freespace('user_sessions')
GROUP BY 1
ORDER BY 1;

-- 3. Summary Statistics
SELECT
    count(*) AS total_pages,
    ROUND(count(*) * 8.0 / 1024, 2) AS total_size_mb,
    count(*) FILTER (WHERE avail = 0) AS fully_packed,
    count(*) FILTER (WHERE avail > 0 AND avail <= 2048) AS minor_to_moderate,
    count(*) FILTER (WHERE avail > 2048 AND avail <= 4096) AS heavy_damage,
    count(*) FILTER (WHERE avail > 4096) AS more_than_half_empty,
    ROUND(count(*) FILTER (WHERE avail = 0) * 100.0 / count(*), 2) AS pct_fully_packed,
    ROUND(count(*) FILTER (WHERE avail > 4096) * 100.0 / count(*), 2) AS pct_half_empty
FROM pg_freespace('user_sessions');
EOF