# Hospital / Clinic System — normalisation

The example uses the saved sample records. The full set of fields is in the design and schema.

## Starting grouped records

| patient_id | appointment records (list) |
| --- | --- |
| 1 | [5] |
| 2 | [6] |


The record IDs are grouped in a list. In 1NF, each record has its own row and each cell holds one value.

## 1NF: one value per cell

| appointment.appointment_id | appointment.patient_id | appointment.clinician_id | appointment.status | patient.patient_id | patient.given_name | clinician.clinician_id | clinician.display_name |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 5 | 1 | 3 | booked | 1 | Avery | 3 | Dr. Casey Rowan |
| 6 | 2 | 3 | completed | 2 | Jordan | 3 | Dr. Casey Rowan |

Key: appointment_id.

## 2NF: depend on the whole key

appointment: clinician_id is a proper part of candidate key (clinician_id, starts_at), and determines clinician details.

## clinician_example

| clinician.clinician_id | clinician.display_name |
| --- | --- |
| 3 | Dr. Casey Rowan |

## appointment_example

| appointment.appointment_id | appointment.patient_id | appointment.clinician_id | appointment.status | patient.patient_id | patient.given_name |
| --- | --- | --- | --- | --- | --- |
| 5 | 1 | 3 | booked | 1 | Avery |
| 6 | 2 | 3 | completed | 2 | Jordan |

## 3NF: store each entity’s details once

The entity keys determine their own descriptions. Related records keep foreign keys rather than repeating those descriptions.

## patient

| patient_id | given_name | family_name | date_of_birth | active |
| --- | --- | --- | --- | --- |
| 1 | Avery | Morgan | 1988-04-12 | true |
| 2 | Jordan | Lee | 1993-09-25 | true |

## clinician

| clinician_id | display_name | specialty | active |
| --- | --- | --- | --- |
| 3 | Dr. Casey Rowan | Family Medicine | true |
| 4 | Dr. Taylor Quinn | Dermatology | true |

## appointment

| appointment_id | patient_id | clinician_id | starts_at | status | reason |
| --- | --- | --- | --- | --- | --- |
| 5 | 1 | 3 | 2026-11-02T09:00:00+00:00 | booked | Routine visit |
| 6 | 2 | 3 | 2026-11-02T10:00:00+00:00 | completed | NULL |

## Dependencies

- patient: (patient_id) → given_name, family_name, date_of_birth, active
- clinician: (clinician_id) → display_name, specialty, active
- appointment: (appointment_id) → patient_id, clinician_id, starts_at, status, reason

Joining the decomposed sample tables reproduces the original 2 example rows. The design assumes the declared keys describe the relevant business dependencies.
