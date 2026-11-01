-- Fictional sample records for The Craftsmen Clinic.
-- IDs for patients (1, 2), clinicians (3, 4) and appointments (5, 6) are kept
-- the same as before, because Portfolios 2 to 4 refer to them.
BEGIN;

INSERT INTO portfolio.department (department_id, name) VALUES
  (1, 'General Medicine'),
  (2, 'Dermatology');

INSERT INTO portfolio.patient (patient_id, given_name, family_name, date_of_birth, phone) VALUES
  (1, 'Avery',  'Morgan', '1988-04-12', '+234 800 000 0001'),
  (2, 'Jordan', 'Lee',    '1993-09-25', NULL);

INSERT INTO portfolio.clinician (clinician_id, department_id, display_name, specialty) VALUES
  (3, 1, 'Dr. Casey Rowan',  'Family Medicine'),
  (4, 2, 'Dr. Taylor Quinn', 'Dermatology');

INSERT INTO portfolio.appointment (appointment_id, patient_id, clinician_id, starts_at, status, reason) VALUES
  (5, 1, 3, '2026-11-02T09:00:00Z', 'booked',    'Routine visit'),
  (6, 2, 3, '2026-11-02T10:00:00Z', 'completed', 'Fever and sore throat');

-- Appointment 6 is completed, so it has a diagnosis, a prescription and lab orders.
INSERT INTO portfolio.diagnosis (diagnosis_id, appointment_id, icd10_code, description, recorded_at) VALUES
  (1, 6, 'J06.9', 'Acute upper respiratory infection', '2026-11-02T10:20:00Z');

INSERT INTO portfolio.medication (medication_id, name, form, stock_quantity) VALUES
  (1, 'Paracetamol 500mg', 'tablet',  500),
  (2, 'Amoxicillin 500mg', 'capsule', 200);

INSERT INTO portfolio.prescription (prescription_id, appointment_id, issued_at) VALUES
  (1, 6, '2026-11-02T10:25:00Z');

INSERT INTO portfolio.prescription_item (prescription_id, medication_id, dosage, quantity) VALUES
  (1, 1, '1 tablet every 8 hours for 3 days', 9),
  (1, 2, '1 capsule every 8 hours for 5 days', 15);

INSERT INTO portfolio.lab_test (lab_test_id, name, price) VALUES
  (1, 'Full Blood Count',      5000.00),
  (2, 'Malaria Parasite Test', 2500.00);

INSERT INTO portfolio.lab_order (lab_order_id, appointment_id, lab_test_id, ordered_at, status, result_summary) VALUES
  (1, 6, 1, '2026-11-02T10:22:00Z', 'completed', 'Within normal range'),
  (2, 6, 2, '2026-11-02T10:22:00Z', 'ordered',   NULL);

COMMIT;
