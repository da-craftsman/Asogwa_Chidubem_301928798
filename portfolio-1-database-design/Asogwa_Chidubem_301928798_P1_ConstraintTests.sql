-- Run these deliberately invalid statements one at a time, outside a transaction.
-- Each should fail at the named constraint; the sample rows should remain unchanged.

-- 1. duplicate patient primary key. Expected: pk_patient, SQLSTATE 23505.
INSERT INTO portfolio."patient" ("patient_id", "given_name", "family_name", "date_of_birth", "active")
VALUES (1, 'Riley', 'Park', '1990-06-18', TRUE);

-- 2. duplicate clinician primary key. Expected: pk_clinician, SQLSTATE 23505.
INSERT INTO portfolio."clinician" ("clinician_id", "display_name", "specialty", "active")
VALUES (3, 'Dr. Sam Ellis', 'Pediatrics', TRUE);

-- 3. duplicate appointment primary key. Expected: pk_appointment, SQLSTATE 23505.
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason")
VALUES (5, 1, 4, '2026-11-03T11:00:00Z', 'booked', NULL);

-- 4. duplicate clinician slot. Expected: uq_appointment_0, SQLSTATE 23505.
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason")
VALUES (101, 2, 3, '2026-11-02T09:00:00Z', 'booked', 'Follow-up');

-- 5. missing patient reference. Expected: fk_appointment_0, SQLSTATE 23503.
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason")
VALUES (102, 9001, 4, '2026-11-04T09:00:00Z', 'booked', NULL);

-- 6. missing clinician reference. Expected: fk_appointment_1, SQLSTATE 23503.
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason")
VALUES (103, 1, 9002, '2026-11-04T10:00:00Z', 'booked', NULL);

-- 7. missing patient given name. Expected: given_name, SQLSTATE 23502.
INSERT INTO portfolio."patient" ("patient_id", "given_name", "family_name", "date_of_birth", "active")
VALUES (104, NULL, 'Reed', '1985-02-14', TRUE);

-- 8. invalid appointment status. Expected: appointment_status_valid, SQLSTATE 23514.
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason")
VALUES (105, 2, 4, '2026-11-05T09:00:00Z', 'pending', NULL);
