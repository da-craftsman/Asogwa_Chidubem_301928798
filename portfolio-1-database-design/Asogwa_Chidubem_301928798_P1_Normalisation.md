# The Craftsmen Clinic — normalisation

This walkthrough starts from how a visit might be written on a single paper form, then normalises it step by step. It uses appointment 6 from the sample data: Jordan Lee's visit to Dr. Casey Rowan, which produced a diagnosis, a prescription with two medicines, and two lab tests.

The worked example focuses on the prescription part of the visit. The lab tests follow exactly the same pattern, summarised at the end.

## Unnormalised form (UNF): the paper visit form

| appointment_id | starts_at | patient | clinician | department | medicines prescribed |
| --- | --- | --- | --- | --- | --- |
| 6 | 2026-11-02 10:00 | Jordan Lee (born 1993-09-25) | Dr. Casey Rowan, Family Medicine | General Medicine | Paracetamol 500mg tablet, 1 tablet every 8 hours for 3 days, qty 9; Amoxicillin 500mg capsule, 1 capsule every 8 hours for 5 days, qty 15 |

Problems:

- **Repeating group:** the medicines cell holds a list. Finding every patient given Amoxicillin means searching inside text.
- **Combined values:** one cell holds a name and a date of birth; another holds a clinician's name and specialty.

## First normal form (1NF): one value per cell, no repeating groups

Each medicine gets its own row, and every cell holds a single value.

| appointment_id | starts_at | patient_id | given_name | family_name | date_of_birth | clinician_id | clinician_name | department_id | department_name | medication_id | medication_name | form | dosage | quantity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 6 | 2026-11-02 10:00 | 2 | Jordan | Lee | 1993-09-25 | 3 | Dr. Casey Rowan | 1 | General Medicine | 1 | Paracetamol 500mg | tablet | 1 tablet every 8 hours for 3 days | 9 |
| 6 | 2026-11-02 10:00 | 2 | Jordan | Lee | 1993-09-25 | 3 | Dr. Casey Rowan | 1 | General Medicine | 2 | Amoxicillin 500mg | capsule | 1 capsule every 8 hours for 5 days | 15 |

**Primary key:** (appointment_id, medication_id). Neither column alone identifies a row.

The table is now in 1NF, but it still has anomalies:

- **Update anomaly:** Jordan's details and Dr. Rowan's department are repeated on every row. Changing the department name means updating many rows, and missing one leaves the data contradicting itself.
- **Insert anomaly:** the pharmacy cannot add a new medicine to the system until someone is prescribed it, because medication_id is part of the key.
- **Delete anomaly:** if this were the only appointment where Amoxicillin was prescribed, deleting it would also delete the only record that the clinic stocks Amoxicillin.

## Second normal form (2NF): no partial dependencies

A table is in 2NF when every non-key column depends on the whole primary key, not just part of it. The functional dependencies are:

- appointment_id → starts_at, patient_id, given_name, family_name, date_of_birth, clinician_id, clinician_name, department_id, department_name
- medication_id → medication_name, form
- (appointment_id, medication_id) → dosage, quantity

The first two depend on only part of the key, so they are partial dependencies. Splitting them out gives three tables.

**appointment_2nf** (key: appointment_id)

| appointment_id | starts_at | patient_id | given_name | family_name | date_of_birth | clinician_id | clinician_name | department_id | department_name |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 6 | 2026-11-02 10:00 | 2 | Jordan | Lee | 1993-09-25 | 3 | Dr. Casey Rowan | 1 | General Medicine |

**medication** (key: medication_id)

| medication_id | name | form |
| --- | --- | --- |
| 1 | Paracetamol 500mg | tablet |
| 2 | Amoxicillin 500mg | capsule |

**prescription_line** (key: appointment_id, medication_id)

| appointment_id | medication_id | dosage | quantity |
| --- | --- | --- | --- |
| 6 | 1 | 1 tablet every 8 hours for 3 days | 9 |
| 6 | 2 | 1 capsule every 8 hours for 5 days | 15 |

The insert and delete anomalies for medicines are gone: a medicine now exists in its own table whether or not anyone has been prescribed it.

## Third normal form (3NF): no transitive dependencies

A table is in 3NF when non-key columns depend only on the key, not on another non-key column. appointment_2nf still has transitive dependencies:

- appointment_id → patient_id → given_name, family_name, date_of_birth
- appointment_id → clinician_id → clinician_name, department_id
- clinician_id → department_id → department_name

Patient details describe the patient, not the appointment. Splitting each chain into its own table gives:

**patient**

| patient_id | given_name | family_name | date_of_birth |
| --- | --- | --- | --- |
| 2 | Jordan | Lee | 1993-09-25 |

**clinician**

| clinician_id | display_name | department_id |
| --- | --- | --- |
| 3 | Dr. Casey Rowan | 1 |

**department**

| department_id | name |
| --- | --- |
| 1 | General Medicine |

**appointment**

| appointment_id | patient_id | clinician_id | starts_at |
| --- | --- | --- | --- |
| 6 | 2 | 3 | 2026-11-02 10:00 |

Now each fact is stored once. Renaming General Medicine is a single-row update, and Jordan's date of birth lives in one place no matter how many appointments Jordan books.

## From 3NF to the final design

One further decision is a modelling choice rather than a normalisation rule. In the final schema, prescription_line becomes two tables:

- **prescription**(prescription_id, appointment_id, issued_at) records the prescription as a thing of its own, with its own issue time. This allows a second or amended prescription for the same appointment.
- **prescription_item**(prescription_id, medication_id, dosage, quantity) holds each medicine on it, keyed by (prescription_id, medication_id).

## The same pattern for lab tests

Lab tests on the paper form were also a list. Applying the same steps:

- 1NF gives one row per test ordered, keyed by (appointment_id, lab_test_id).
- The test name and price depend only on lab_test_id, which is a partial dependency, so they move to **lab_test**.
- What remains becomes **lab_order**, with its own lab_order_id, status and result summary.

## Result

All ten tables in the final schema are in 3NF. They also meet Boyce–Codd normal form (BCNF): every column that determines other columns is a candidate key. For example, in appointment both appointment_id and (clinician_id, starts_at) are candidate keys, and in department both department_id and name are.

Joining the final tables on their keys reproduces the original 1NF rows exactly, so no information was lost in the decomposition. [JoinCheck.sql](Asogwa_Chidubem_301928798_P1_JoinCheck.sql) runs that join for appointment 6 and returns the same two rows ([screenshot](screenshots/Asogwa_Chidubem_301928798_P1_03_JoinCheck.png)).
