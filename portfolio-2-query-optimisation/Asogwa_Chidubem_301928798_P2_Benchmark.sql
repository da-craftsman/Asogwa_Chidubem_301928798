-- Measures the four Portfolio 2 queries before and after indexing.
-- Run from the portfolio-2-query-optimisation folder:
--   psql -d clinic -f Asogwa_Chidubem_301928798_P2_Benchmark.sql
-- Safe to re-run: it removes the Portfolio 2 indexes first, so every run
-- starts from the same "before" state.
\pset pager off
\set ON_ERROR_STOP on

-- Parallel workers are switched off so before and after plans are compared
-- like for like on the same single process.
SET max_parallel_workers_per_gather = 0;

\! mkdir -p plans

-- 1. Start from a clean state -------------------------------------------------
DROP SCHEMA IF EXISTS benchmark CASCADE;
DROP INDEX IF EXISTS portfolio.idx_appointment_patient_starts,
                     portfolio.idx_diagnosis_appointment,
                     portfolio.idx_lab_order_appointment,
                     portfolio.idx_lab_order_pending,
                     portfolio.idx_appointment_starts;
ANALYZE;

-- 2. Helper tables and functions ---------------------------------------------
CREATE SCHEMA benchmark;

CREATE TABLE benchmark.query (
  query_id int  PRIMARY KEY,
  label    text NOT NULL,
  sql      text NOT NULL
);

CREATE TABLE benchmark.result (
  query_id      int     NOT NULL REFERENCES benchmark.query,
  stage         text    NOT NULL,
  median_ms     numeric NOT NULL,
  shared_blocks bigint  NOT NULL,
  PRIMARY KEY (query_id, stage)
);

-- The same four queries as Asogwa_Chidubem_301928798_P2_Queries.sql.
INSERT INTO benchmark.query VALUES
(1, 'Q1 Patient history', $q$
SELECT a.appointment_id, (a.starts_at AT TIME ZONE 'Africa/Lagos')::date AS visit_date, a.status,
       c.display_name AS clinician, d.name AS department, dg.icd10_code, lt.name AS lab_test, lo.status AS lab_status
FROM portfolio.appointment a
JOIN portfolio.clinician c       ON c.clinician_id = a.clinician_id
JOIN portfolio.department d      ON d.department_id = c.department_id
LEFT JOIN portfolio.diagnosis dg ON dg.appointment_id = a.appointment_id
LEFT JOIN portfolio.lab_order lo ON lo.appointment_id = a.appointment_id
LEFT JOIN portfolio.lab_test lt  ON lt.lab_test_id = lo.lab_test_id
WHERE a.patient_id = 1234
ORDER BY a.starts_at DESC
$q$),
(2, 'Q2 Clinician schedule', $q$
SELECT (a.starts_at AT TIME ZONE 'Africa/Lagos')::time AS local_time, p.given_name || ' ' || p.family_name AS patient,
       a.status, a.reason
FROM portfolio.appointment a
JOIN portfolio.patient p ON p.patient_id = a.patient_id
WHERE a.clinician_id = 1005
  AND a.starts_at >= TIMESTAMPTZ '2026-10-20 00:00+01'
  AND a.starts_at <  TIMESTAMPTZ '2026-10-21 00:00+01'
ORDER BY a.starts_at
$q$),
(3, 'Q3 Lab worklist', $q$
SELECT lo.lab_order_id, (lo.ordered_at AT TIME ZONE 'Africa/Lagos')::timestamp(0) AS ordered_at_local,
       lt.name AS lab_test, lo.status, p.given_name || ' ' || p.family_name AS patient
FROM portfolio.lab_order lo
JOIN portfolio.lab_test lt    ON lt.lab_test_id = lo.lab_test_id
JOIN portfolio.appointment a  ON a.appointment_id = lo.appointment_id
JOIN portfolio.patient p      ON p.patient_id = a.patient_id
WHERE lo.status IN ('ordered', 'in_progress')
ORDER BY lo.ordered_at
LIMIT 20
$q$),
(4, 'Q4 Department report', $q$
SELECT d.name AS department, count(*) AS appointments,
       count(*) FILTER (WHERE a.status = 'completed') AS completed,
       count(*) FILTER (WHERE a.status = 'cancelled') AS cancelled,
       round(100.0 * count(*) FILTER (WHERE a.status = 'cancelled') / count(*), 1) AS cancel_rate_pct
FROM portfolio.appointment a
JOIN portfolio.clinician c  ON c.clinician_id = a.clinician_id
JOIN portfolio.department d ON d.department_id = c.department_id
WHERE a.starts_at >= TIMESTAMPTZ '2026-01-01 00:00+01'
  AND a.starts_at <  TIMESTAMPTZ '2027-01-01 00:00+01'
GROUP BY d.name
ORDER BY d.name
$q$);

-- Runs every query several times with EXPLAIN ANALYZE and records the median
-- execution time (one slow run can't distort a median) and the number of
-- 8 kB pages the query touched (shared buffers hit + read).
CREATE FUNCTION benchmark.measure(p_stage text, p_runs int DEFAULT 7)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  q      record;
  plan   json;
  times  numeric[];
  blocks bigint;
BEGIN
  FOR q IN SELECT * FROM benchmark.query ORDER BY query_id LOOP
    times := '{}';
    FOR i IN 1..p_runs LOOP
      EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || q.sql INTO plan;
      times  := times || (plan -> 0 ->> 'Execution Time')::numeric;
      blocks := (plan -> 0 -> 'Plan' ->> 'Shared Hit Blocks')::bigint
              + (plan -> 0 -> 'Plan' ->> 'Shared Read Blocks')::bigint;
    END LOOP;
    INSERT INTO benchmark.result VALUES (
      q.query_id, p_stage,
      (SELECT round(percentile_cont(0.5) WITHIN GROUP (ORDER BY t)::numeric, 3) FROM unnest(times) AS t),
      blocks);
  END LOOP;
END $$;

-- Returns the readable execution plan of one query, for saving to a file.
CREATE FUNCTION benchmark.plan(p_query_id int)
RETURNS SETOF text LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) '
    || (SELECT sql FROM benchmark.query WHERE query_id = p_query_id);
END $$;

-- 3. Before: no Portfolio 2 indexes ------------------------------------------
\t on
\a
\o plans/Q1_patient_history_before.txt
SELECT benchmark.plan(1);
\o plans/Q2_clinician_schedule_before.txt
SELECT benchmark.plan(2);
\o plans/Q3_lab_worklist_before.txt
SELECT benchmark.plan(3);
\o plans/Q4_department_report_before.txt
SELECT benchmark.plan(4);
\o
\t off
\a
SELECT benchmark.measure('before');

-- 4. Add the indexes ----------------------------------------------------------
-- Q1: PostgreSQL does not index foreign key columns automatically.
-- Find a patient's appointments, already in date order.
CREATE INDEX idx_appointment_patient_starts ON portfolio.appointment (patient_id, starts_at DESC);
-- Look up the diagnoses and lab orders for each of those appointments.
CREATE INDEX idx_diagnosis_appointment ON portfolio.diagnosis (appointment_id);
CREATE INDEX idx_lab_order_appointment ON portfolio.lab_order (appointment_id);

-- Q2: no new index. The double-booking constraint uq_appointment_clinician_slot
-- already created an index on (clinician_id, starts_at).

-- Q3: a partial index holding only pending orders, already sorted by order time.
CREATE INDEX idx_lab_order_pending ON portfolio.lab_order (ordered_at)
  WHERE status IN ('ordered', 'in_progress');

-- Q4: a test. The report reads a whole year, about 44% of the table.
CREATE INDEX idx_appointment_starts ON portfolio.appointment (starts_at);

ANALYZE;

-- 5. After --------------------------------------------------------------------
\t on
\a
\o plans/Q1_patient_history_after.txt
SELECT benchmark.plan(1);
\o plans/Q2_clinician_schedule_after.txt
SELECT benchmark.plan(2);
\o plans/Q3_lab_worklist_after.txt
SELECT benchmark.plan(3);
\o plans/Q4_department_report_after.txt
SELECT benchmark.plan(4);
\o
\t off
\a
SELECT benchmark.measure('after');

-- 6. Results ------------------------------------------------------------------
\echo '=== Median execution time (7 runs) and pages touched, before and after indexing ==='
SELECT q.label AS query,
       b.median_ms AS before_ms,
       a.median_ms AS after_ms,
       round(b.median_ms / NULLIF(a.median_ms, 0), 1) AS times_faster,
       b.shared_blocks AS before_pages,
       a.shared_blocks AS after_pages
FROM benchmark.query q
JOIN benchmark.result b ON b.query_id = q.query_id AND b.stage = 'before'
JOIN benchmark.result a ON a.query_id = q.query_id AND a.stage = 'after'
ORDER BY q.query_id;

\echo '=== Index sizes: a partial index compared with a full one on the same column ==='
CREATE INDEX idx_lab_order_ordered_full ON portfolio.lab_order (ordered_at);
SELECT i.indexrelname AS index_name,
       i.relname      AS table_name,
       pg_size_pretty(pg_relation_size(i.indexrelid)) AS size
FROM pg_stat_user_indexes i
WHERE i.schemaname = 'portfolio' AND i.indexrelname LIKE 'idx_%'
ORDER BY pg_relation_size(i.indexrelid) DESC;
DROP INDEX portfolio.idx_lab_order_ordered_full;   -- comparison only, not kept

\echo '=== Physical order of appointment rows (1 = stored in this column''s order, 0 = random) ==='
SELECT attname AS column_name, round(correlation::numeric, 3) AS correlation
FROM pg_stats
WHERE schemaname = 'portfolio' AND tablename = 'appointment'
  AND attname IN ('starts_at', 'patient_id')
ORDER BY attname DESC;
