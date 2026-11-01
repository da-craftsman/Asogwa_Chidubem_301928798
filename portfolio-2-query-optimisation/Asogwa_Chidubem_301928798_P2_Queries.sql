-- Four everyday queries for The Craftsmen Clinic.
-- Run after the seed data:
--   psql -d clinic -f Asogwa_Chidubem_301928798_P2_Queries.sql
\pset pager off

\echo '=== Q1. Patient history: every visit for patient 1234, newest first ==='
SELECT a.appointment_id,
       (a.starts_at AT TIME ZONE 'Africa/Lagos')::date AS visit_date,
       a.status,
       c.display_name AS clinician,
       d.name         AS department,
       dg.icd10_code,
       lt.name        AS lab_test,
       lo.status      AS lab_status
FROM portfolio.appointment a
JOIN portfolio.clinician c       ON c.clinician_id = a.clinician_id
JOIN portfolio.department d      ON d.department_id = c.department_id
LEFT JOIN portfolio.diagnosis dg ON dg.appointment_id = a.appointment_id
LEFT JOIN portfolio.lab_order lo ON lo.appointment_id = a.appointment_id
LEFT JOIN portfolio.lab_test lt  ON lt.lab_test_id = lo.lab_test_id
WHERE a.patient_id = 1234
ORDER BY a.starts_at DESC;

\echo '=== Q2. Clinician schedule: Dr. 1005 on Tuesday 20 October 2026 ==='
SELECT (a.starts_at AT TIME ZONE 'Africa/Lagos')::time AS local_time,
       p.given_name || ' ' || p.family_name AS patient,
       a.status,
       a.reason
FROM portfolio.appointment a
JOIN portfolio.patient p ON p.patient_id = a.patient_id
WHERE a.clinician_id = 1005
  AND a.starts_at >= TIMESTAMPTZ '2026-10-20 00:00+01'
  AND a.starts_at <  TIMESTAMPTZ '2026-10-21 00:00+01'
ORDER BY a.starts_at;

\echo '=== Q3. Lab worklist: the 20 oldest pending lab orders ==='
SELECT lo.lab_order_id,
       (lo.ordered_at AT TIME ZONE 'Africa/Lagos')::timestamp(0) AS ordered_at_local,
       lt.name   AS lab_test,
       lo.status,
       p.given_name || ' ' || p.family_name AS patient
FROM portfolio.lab_order lo
JOIN portfolio.lab_test lt    ON lt.lab_test_id = lo.lab_test_id
JOIN portfolio.appointment a  ON a.appointment_id = lo.appointment_id
JOIN portfolio.patient p      ON p.patient_id = a.patient_id
WHERE lo.status IN ('ordered', 'in_progress')
ORDER BY lo.ordered_at
LIMIT 20;

\echo '=== Q4. Department report: appointments and cancellation rate in 2026 ==='
SELECT d.name AS department,
       count(*) AS appointments,
       count(*) FILTER (WHERE a.status = 'completed') AS completed,
       count(*) FILTER (WHERE a.status = 'cancelled') AS cancelled,
       round(100.0 * count(*) FILTER (WHERE a.status = 'cancelled') / count(*), 1) AS cancel_rate_pct
FROM portfolio.appointment a
JOIN portfolio.clinician c  ON c.clinician_id = a.clinician_id
JOIN portfolio.department d ON d.department_id = c.department_id
WHERE a.starts_at >= TIMESTAMPTZ '2026-01-01 00:00+01'
  AND a.starts_at <  TIMESTAMPTZ '2027-01-01 00:00+01'
GROUP BY d.name
ORDER BY d.name;
