-- Deliberately invalid statements for The Craftsmen Clinic.
-- Run with: psql -d clinic -e -f Asogwa_Chidubem_301928798_P1_ConstraintTests.sql
-- Every statement should fail at the named constraint; the sample data stays unchanged.

-- 1. Two patients cannot share an ID. Expected: pk_patient
INSERT INTO portfolio.patient (patient_id, given_name, family_name, date_of_birth)
VALUES (1, 'Riley', 'Park', '1990-06-18');

-- 2. A patient must have a first name. Expected: NOT NULL on given_name
INSERT INTO portfolio.patient (patient_id, given_name, family_name, date_of_birth)
VALUES (104, NULL, 'Reed', '1985-02-14');

-- 3. A clinician must belong to a department that exists. Expected: fk_clinician_department
INSERT INTO portfolio.clinician (clinician_id, department_id, display_name, specialty)
VALUES (10, 99, 'Dr. Sam Ellis', 'Paediatrics');

-- 4. No double booking: Dr. Rowan already has 09:00 on 2 Nov. Expected: uq_appointment_clinician_slot
INSERT INTO portfolio.appointment (appointment_id, patient_id, clinician_id, starts_at)
VALUES (101, 2, 3, '2026-11-02T09:00:00Z');

-- 5. Appointments must be for a registered patient. Expected: fk_appointment_patient
INSERT INTO portfolio.appointment (appointment_id, patient_id, clinician_id, starts_at)
VALUES (102, 9001, 4, '2026-11-04T09:00:00Z');

-- 6. Only booked, cancelled or completed are valid statuses. Expected: chk_appointment_status
INSERT INTO portfolio.appointment (appointment_id, patient_id, clinician_id, starts_at, status)
VALUES (103, 2, 4, '2026-11-05T09:00:00Z', 'pending');

-- 7. Diagnoses must use a valid ICD-10 code format. Expected: chk_diagnosis_icd10_format
INSERT INTO portfolio.diagnosis (diagnosis_id, appointment_id, icd10_code, description)
VALUES (2, 6, 'flu', 'Influenza');

-- 8. Pharmacy stock can never go below zero. Expected: chk_medication_stock_nonnegative
UPDATE portfolio.medication SET stock_quantity = -5 WHERE medication_id = 1;

-- 9. A prescribed quantity must be at least one. Expected: chk_prescription_item_quantity_positive
INSERT INTO portfolio.prescription_item (prescription_id, medication_id, dosage, quantity)
VALUES (1, 1, 'none', 0);

-- 10. The same medicine cannot appear twice on one prescription. Expected: pk_prescription_item
INSERT INTO portfolio.prescription_item (prescription_id, medication_id, dosage, quantity)
VALUES (1, 2, '2 capsules daily', 10);

-- 11. Lab orders only use the defined workflow statuses. Expected: chk_lab_order_status
INSERT INTO portfolio.lab_order (lab_order_id, appointment_id, lab_test_id, status)
VALUES (3, 6, 1, 'lost');

-- 12. A patient with appointment history cannot be deleted. Expected: fk_appointment_patient
DELETE FROM portfolio.patient WHERE patient_id = 2;
