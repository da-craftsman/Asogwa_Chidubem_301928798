-- Commit, rollback and savepoints at The Craftsmen Clinic (single session).
-- Run with: psql -d clinic -e -f Asogwa_Chidubem_301928798_P3_CommitRollback.sql
-- -e prints each statement, so the output shows what ran and what happened.
\pset pager off
-- Reset quietly first, so the script can be run any number of times.
\set ECHO none
\set QUIET on
\ir Asogwa_Chidubem_301928798_P3_Reset.sql
\set QUIET off
\set ECHO queries

\echo
\echo '=== Starting state: appointment 5 is booked; pharmacy stock is full ==='
SELECT appointment_id, status FROM portfolio.appointment WHERE appointment_id = 5;
SELECT medication_id, name, stock_quantity FROM portfolio.medication ORDER BY medication_id;

\echo
\echo '=== 1. COMMIT: completing a visit is one unit of work ==='
-- Marking the visit complete, recording the diagnosis, issuing the prescription
-- and taking the tablets out of stock must all happen, or none of them.
BEGIN;
UPDATE portfolio.appointment SET status = 'completed' WHERE appointment_id = 5;
INSERT INTO portfolio.diagnosis (diagnosis_id, appointment_id, icd10_code, description)
VALUES (900001, 5, 'B54', 'Malaria, unspecified');
INSERT INTO portfolio.prescription (prescription_id, appointment_id) VALUES (900001, 5);
INSERT INTO portfolio.prescription_item (prescription_id, medication_id, dosage, quantity)
VALUES (900001, 1, '2 tablets every 8 hours for 3 days', 18);
UPDATE portfolio.medication SET stock_quantity = stock_quantity - 18 WHERE medication_id = 1;
COMMIT;

SELECT a.appointment_id, a.status, d.icd10_code, pi.quantity AS tablets_prescribed, m.stock_quantity AS paracetamol_stock
FROM portfolio.appointment a
JOIN portfolio.diagnosis d          ON d.appointment_id = a.appointment_id
JOIN portfolio.prescription p       ON p.appointment_id = a.appointment_id
JOIN portfolio.prescription_item pi ON pi.prescription_id = p.prescription_id
JOIN portfolio.medication m         ON m.medication_id = pi.medication_id
WHERE a.appointment_id = 5;

\echo
\echo '=== 2. ROLLBACK: a prescription larger than the stock fails, and nothing is kept ==='
BEGIN;
INSERT INTO portfolio.prescription (prescription_id, appointment_id) VALUES (900002, 6);
INSERT INTO portfolio.prescription_item (prescription_id, medication_id, dosage, quantity)
VALUES (900002, 2, '1 capsule every 8 hours for 5 days', 250);
-- Only 200 capsules in stock: 200 - 250 = -50 breaks chk_medication_stock_nonnegative.
UPDATE portfolio.medication SET stock_quantity = stock_quantity - 250 WHERE medication_id = 2;
-- After an error, PostgreSQL refuses every further statement until ROLLBACK.
SELECT 'still working?' AS test;
ROLLBACK;

-- The prescription inserted before the error is gone too, and stock is unchanged.
SELECT (SELECT count(*) FROM portfolio.prescription WHERE prescription_id = 900002) AS prescription_900002_rows,
       (SELECT stock_quantity FROM portfolio.medication WHERE medication_id = 2)     AS amoxicillin_stock;

\echo
\echo '=== 3. SAVEPOINT: undo one mistaken step, keep the rest of the transaction ==='
BEGIN;
INSERT INTO portfolio.lab_order (lab_order_id, appointment_id, lab_test_id)
VALUES (900001, 5, 2);   -- Malaria Parasite Test
SAVEPOINT before_second_test;
INSERT INTO portfolio.lab_order (lab_order_id, appointment_id, lab_test_id)
VALUES (900002, 5, 99);  -- mistake: lab test 99 does not exist
ROLLBACK TO SAVEPOINT before_second_test;
INSERT INTO portfolio.lab_order (lab_order_id, appointment_id, lab_test_id)
VALUES (900002, 5, 1);   -- corrected: Full Blood Count
COMMIT;

SELECT lo.lab_order_id, lt.name AS lab_test, lo.status
FROM portfolio.lab_order lo
JOIN portfolio.lab_test lt ON lt.lab_test_id = lo.lab_test_id
WHERE lo.appointment_id = 5
ORDER BY lo.lab_order_id;
