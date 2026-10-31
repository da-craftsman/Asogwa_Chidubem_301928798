-- Fictional sample records for Hospital / Clinic System.
BEGIN;
SET LOCAL standard_conforming_strings = on;
INSERT INTO portfolio."patient" ("patient_id", "given_name", "family_name", "date_of_birth", "active") VALUES (1, 'Avery', 'Morgan', '1988-04-12', TRUE);
INSERT INTO portfolio."patient" ("patient_id", "given_name", "family_name", "date_of_birth", "active") VALUES (2, 'Jordan', 'Lee', '1993-09-25', TRUE);
INSERT INTO portfolio."clinician" ("clinician_id", "display_name", "specialty", "active") VALUES (3, 'Dr. Casey Rowan', 'Family Medicine', TRUE);
INSERT INTO portfolio."clinician" ("clinician_id", "display_name", "specialty", "active") VALUES (4, 'Dr. Taylor Quinn', 'Dermatology', TRUE);
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason") VALUES (5, 1, 3, '2026-11-02T09:00:00Z', 'booked', 'Routine visit');
INSERT INTO portfolio."appointment" ("appointment_id", "patient_id", "clinician_id", "starts_at", "status", "reason") VALUES (6, 2, 3, '2026-11-02T10:00:00Z', 'completed', NULL);
COMMIT;
