-- Show related appointment, patient, clinician records (up to 20).
SELECT t0."appointment_id" AS "appointment_appointment_id",
       t0."starts_at" AS "appointment_starts_at",
       t1."patient_id" AS "patient_patient_id",
       t1."given_name" AS "patient_given_name",
       t2."clinician_id" AS "clinician_clinician_id",
       t2."display_name" AS "clinician_display_name"
FROM portfolio."appointment" t0
JOIN portfolio."patient" t1 ON t0."patient_id" = t1."patient_id"
JOIN portfolio."clinician" t2 ON t0."clinician_id" = t2."clinician_id"
ORDER BY t0."appointment_id", t1."patient_id", t2."clinician_id"
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT t0."appointment_id" AS "appointment_appointment_id",
       t0."starts_at" AS "appointment_starts_at",
       t1."patient_id" AS "patient_patient_id",
       t1."given_name" AS "patient_given_name",
       t2."clinician_id" AS "clinician_clinician_id",
       t2."display_name" AS "clinician_display_name"
FROM portfolio."appointment" t0
JOIN portfolio."patient" t1 ON t0."patient_id" = t1."patient_id"
JOIN portfolio."clinician" t2 ON t0."clinician_id" = t2."clinician_id"
ORDER BY t0."appointment_id", t1."patient_id", t2."clinician_id"
LIMIT 20;

-- Find patient records where given_name matches "Avery" (up to 20).
SELECT * FROM portfolio."patient"
WHERE "given_name" IS NOT DISTINCT FROM 'Avery'
ORDER BY "patient_id"
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM portfolio."patient"
WHERE "given_name" IS NOT DISTINCT FROM 'Avery'
ORDER BY "patient_id"
LIMIT 20;

-- Count appointment records for each patient_id (up to 20 groups).
SELECT "patient_id", count(*) AS record_count
FROM portfolio."appointment"
GROUP BY "patient_id"
ORDER BY record_count DESC, "patient_id" NULLS LAST
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT "patient_id", count(*) AS record_count
FROM portfolio."appointment"
GROUP BY "patient_id"
ORDER BY record_count DESC, "patient_id" NULLS LAST
LIMIT 20;
