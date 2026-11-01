-- Rebuilds the 1NF rows for appointment 6 by joining the normalised tables.
-- If the decomposition lost nothing, this returns the same two rows as the 1NF table.
-- Run with: psql -d clinic -f Asogwa_Chidubem_301928798_P1_JoinCheck.sql
SELECT a.appointment_id,
       a.starts_at,
       p.given_name,
       p.family_name,
       c.display_name AS clinician,
       d.name         AS department,
       m.name         AS medication,
       m.form,
       pi.dosage,
       pi.quantity
FROM portfolio.appointment a
JOIN portfolio.patient p            ON p.patient_id = a.patient_id
JOIN portfolio.clinician c          ON c.clinician_id = a.clinician_id
JOIN portfolio.department d         ON d.department_id = c.department_id
JOIN portfolio.prescription pr      ON pr.appointment_id = a.appointment_id
JOIN portfolio.prescription_item pi ON pi.prescription_id = pr.prescription_id
JOIN portfolio.medication m         ON m.medication_id = pi.medication_id
WHERE a.appointment_id = 6
ORDER BY m.medication_id;
