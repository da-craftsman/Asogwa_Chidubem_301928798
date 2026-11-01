-- Loads realistic volume into The Craftsmen Clinic for query optimisation.
-- Run after the Portfolio 1 schema and sample data:
--   psql -d clinic -f Asogwa_Chidubem_301928798_P2_SeedData.sql
-- All generated IDs start at 1000, so the hand-written sample records
-- (patients 1-2, clinicians 3-4, appointments 5-6) are untouched.
-- setseed makes random() return the same sequence every run, so the data
-- (and therefore the results) can be reproduced.
BEGIN;
SELECT setseed(0.42);

-- Three more departments and three more lab tests.
INSERT INTO portfolio.department (department_id, name) VALUES
  (3, 'Paediatrics'),
  (4, 'Obstetrics and Gynaecology'),
  (5, 'Ear, Nose and Throat');

INSERT INTO portfolio.lab_test (lab_test_id, name, price) VALUES
  (3, 'Urinalysis',          3000.00),
  (4, 'Fasting Blood Sugar', 2000.00),
  (5, 'Lipid Profile',       8000.00);

-- 15,000 patients (IDs 1000-15999) with random names and birth dates.
INSERT INTO portfolio.patient (patient_id, given_name, family_name, date_of_birth, phone)
SELECT 1000 + g,
       (ARRAY['Chinedu','Amaka','Tunde','Ngozi','Emeka','Aisha','Ifeoma','Bola','Kelechi','Zainab',
              'Obinna','Funmi','Uche','Halima','Seun','Chioma','Ibrahim','Yetunde','Nnamdi','Folake'])
         [1 + floor(random() * 20)::int],
       (ARRAY['Okafor','Adeyemi','Eze','Bello','Nwosu','Ogunleye','Okonkwo','Abubakar','Chukwu','Balogun',
              'Obi','Lawal','Nwachukwu','Adebayo','Uzor','Musa','Onyeka','Afolabi','Igwe','Danjuma'])
         [1 + floor(random() * 20)::int],
       DATE '1945-01-01' + floor(random() * (DATE '2024-12-31' - DATE '1945-01-01'))::int,
       '+234 000 ' || lpad(g::text, 7, '0')   -- obviously fake numbers
FROM generate_series(0, 14999) AS g;

-- 30 clinicians (IDs 1000-1029), six per department.
INSERT INTO portfolio.clinician (clinician_id, department_id, display_name, specialty)
SELECT 1000 + g,
       1 + g % 5,
       'Dr. ' || (ARRAY['Adaeze','Kunle','Ebere','Musa','Ronke','Ike','Hauwa','Dayo','Nkem','Sani'])[1 + g % 10]
              || ' ' || (ARRAY['Okeke','Ajayi','Mbah','Yusuf','Eze','Bakare'])[1 + g / 5],
       (ARRAY['Family Medicine','Dermatology','Paediatrics','Obstetrics and Gynaecology','Otolaryngology'])[1 + g % 5]
FROM generate_series(0, 29) AS g;

-- 200,000 appointments over two years of weekdays.
-- Step 1 builds every possible slot (each clinician, each weekday, 08:00-16:30
-- in 30-minute steps, Lagos time). Step 2 picks 200,000 of them at random,
-- so no clinician is ever double-booked.
INSERT INTO portfolio.appointment (appointment_id, patient_id, clinician_id, starts_at, status, reason)
WITH slots AS (
  SELECT c.clinician_id,
         (d::date + TIME '08:00' + s * INTERVAL '30 minutes') AT TIME ZONE 'Africa/Lagos' AS starts_at
  FROM portfolio.clinician AS c
  CROSS JOIN generate_series(DATE '2024-11-04', DATE '2026-11-27', INTERVAL '1 day') AS d
  CROSS JOIN generate_series(0, 17) AS s
  WHERE c.clinician_id >= 1000
    AND extract(isodow FROM d) < 6
),
picked AS (
  SELECT clinician_id, starts_at FROM slots ORDER BY random() LIMIT 200000
)
SELECT 999 + row_number() OVER (ORDER BY starts_at, clinician_id),
       1000 + floor(random() * 15000)::int,
       clinician_id,
       starts_at,
       CASE WHEN starts_at >= TIMESTAMPTZ '2026-11-02 00:00+01' THEN 'booked'
            WHEN random() < 0.10 THEN 'cancelled'
            ELSE 'completed' END,
       (ARRAY['Routine check-up','Fever','Skin rash','Follow-up','Antenatal visit',
              'Ear pain','Cough','Headache','Child immunisation','Blood pressure review'])
         [1 + floor(random() * 10)::int]
FROM picked;

-- A diagnosis for about 70% of completed appointments.
INSERT INTO portfolio.diagnosis (diagnosis_id, appointment_id, icd10_code, description, recorded_at)
SELECT 999 + row_number() OVER (ORDER BY appointment_id),
       appointment_id,
       (ARRAY['J06.9','B54','L30.9','I10','E11.9','H66.9','R51','Z00.0','O26.9','J20.9'])[k],
       (ARRAY['Acute upper respiratory infection','Malaria, unspecified','Dermatitis, unspecified',
              'Essential hypertension','Type 2 diabetes','Otitis media','Headache',
              'General medical examination','Pregnancy-related condition','Acute bronchitis'])[k],
       starts_at + INTERVAL '20 minutes'
FROM (
  SELECT appointment_id, starts_at, 1 + floor(random() * 10)::int AS k
  FROM portfolio.appointment
  WHERE status = 'completed' AND appointment_id >= 1000 AND random() < 0.70
) AS chosen;

-- Lab orders for about 35% of completed appointments. Orders from the last
-- ten days are still pending, which is what the lab works from each morning.
INSERT INTO portfolio.lab_order (lab_order_id, appointment_id, lab_test_id, ordered_at, status, result_summary)
SELECT 999 + row_number() OVER (ORDER BY appointment_id),
       appointment_id,
       1 + floor(random() * 5)::int,
       starts_at + INTERVAL '15 minutes',
       CASE WHEN starts_at >= TIMESTAMPTZ '2026-10-22 00:00+01'
            THEN (ARRAY['ordered','in_progress'])[1 + floor(random() * 2)::int]
            ELSE 'completed' END,
       CASE WHEN starts_at >= TIMESTAMPTZ '2026-10-22 00:00+01' THEN NULL
            ELSE (ARRAY['Within normal range','Slightly elevated','Below normal range','Positive','Negative'])
                   [1 + floor(random() * 5)::int] END
FROM portfolio.appointment
WHERE status = 'completed' AND appointment_id >= 1000 AND random() < 0.35;

COMMIT;

-- Refresh the planner's statistics so it knows how big the tables now are.
ANALYZE;

-- Row counts after loading.
SELECT table_name, row_count FROM (
  SELECT 1 AS ord, 'patient' AS table_name, count(*) AS row_count FROM portfolio.patient
  UNION ALL SELECT 2, 'clinician',   count(*) FROM portfolio.clinician
  UNION ALL SELECT 3, 'appointment', count(*) FROM portfolio.appointment
  UNION ALL SELECT 4, 'diagnosis',   count(*) FROM portfolio.diagnosis
  UNION ALL SELECT 5, 'lab_order',   count(*) FROM portfolio.lab_order
  UNION ALL SELECT 6, 'lab_order (pending)', count(*) FROM portfolio.lab_order
            WHERE status IN ('ordered', 'in_progress')
) AS counts
ORDER BY ord;
