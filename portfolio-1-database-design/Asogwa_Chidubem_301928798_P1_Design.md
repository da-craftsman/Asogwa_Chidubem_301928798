# Hospital / Clinic System — database design

My case study records patient, clinician, appointment.

## Users

- Clinic reception staff scheduling appointments
- Clinicians reviewing their appointment schedules
- Database students testing relational and event models

## Main operations

- Create appointments for existing patients and clinicians.
- Filter appointments by patient, status, or date range.
- Count appointments by clinician and day.
- Benchmark the appointment date-range filter on 50000 synthetic rows with and without a B-tree index on starts_at; verify identical results and compare repeated runs under the same conditions.

## Entities

| Entity | Information stored |
| --- | --- |
| patient | Stores a synthetic patient profile referenced by appointments. |
| clinician | Stores a synthetic clinician profile referenced by appointments. |
| appointment | Records a scheduled patient visit with a clinician. |

## patient

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| patient_id | BIGINT | PK | Yes |
| given_name | TEXT |  | Yes |
| family_name | TEXT |  | Yes |
| date_of_birth | DATE |  | Yes |
| active | BOOLEAN |  | Yes |


## clinician

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| clinician_id | BIGINT | PK | Yes |
| display_name | TEXT |  | Yes |
| specialty | TEXT |  | Yes |
| active | BOOLEAN |  | Yes |


## appointment

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| appointment_id | BIGINT | PK | Yes |
| patient_id | BIGINT | FK | Yes |
| clinician_id | BIGINT | FK | Yes |
| starts_at | TIMESTAMPTZ |  | Yes |
| status | TEXT |  | Yes |
| reason | TEXT |  | No |
- patient_id → patient.patient_id
- clinician_id → clinician.clinician_id
- Unique key: (clinician_id, starts_at).

## Relationships and business rules

- Every patient record must have a given name and family name.
- Appointment status must be booked, cancelled, or completed.
- A clinician cannot have two appointments with the same start timestamp.
- Each appointment patient_id must reference an existing patient patient_id.
- Each appointment clinician_id must reference an existing clinician clinician_id.

## Assumptions

- Each appointment refers to exactly one existing patient and one existing clinician.
- A clinician may have no more than one appointment at an identical start timestamp; appointment duration and overlapping intervals are outside this exercise.
- Appointment status is limited to booked, cancelled, or completed.
- For the worked normalization example, use appointment as the root and its patient_id and clinician_id as separate foreign keys. Keep patient and clinician descriptive attributes in their own tables; do not repeat ancestor roles in this example.
- The benchmark uses a fixed synthetic dataset and compares query plans with and without the specified index; it does not prescribe particular timing results.

