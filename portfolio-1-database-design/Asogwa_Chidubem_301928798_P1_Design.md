# The Craftsmen Clinic — database design

## Case study

The Craftsmen Clinic is a fictional outpatient clinic in Nigeria. It has a General Medicine unit, a Dermatology unit, an in-house laboratory and a small pharmacy. Patients book appointments with a clinician. During a visit, the clinician records one or more diagnoses, can issue a prescription that the pharmacy dispenses from its stock, and can order laboratory tests. All records in this portfolio are synthetic; no real patient data is used.

## Users of the database

| User | What they do with the database |
| --- | --- |
| Receptionist | Registers patients and books, reschedules or cancels appointments |
| Clinician | Views their schedule, records diagnoses, issues prescriptions, orders lab tests |
| Lab scientist | Sees ordered tests and updates their status and result summary |
| Pharmacist | Dispenses prescribed medicines and manages stock levels |
| Clinic administrator | Manages departments, staff records, the medicine list and lab test prices |

## Key operations

1. Register a new patient.
2. Book an appointment without double-booking a clinician.
3. Record a diagnosis for an appointment using an ICD-10 code.
4. Issue a prescription with one or more medicines, and keep pharmacy stock from going negative.
5. Order a lab test and move it through ordered → in progress → completed.
6. Retrieve a patient's full history: appointments, diagnoses, prescriptions and lab orders.

## Entities

| Table | What it stores |
| --- | --- |
| department | The clinic's units (General Medicine, Dermatology) |
| patient | Registered patients |
| clinician | Doctors, each belonging to one department |
| appointment | A patient's booked visit with a clinician |
| diagnosis | Diagnoses recorded during an appointment |
| medication | Medicines the pharmacy stocks, with current stock level |
| prescription | A prescription issued during an appointment |
| prescription_item | Each medicine on a prescription, with dosage and quantity |
| lab_test | The catalogue of tests the laboratory offers, with prices in naira |
| lab_order | A lab test ordered during an appointment, and its status |

## Relational schema

Primary keys are in **bold**; foreign keys are marked with → and the table they reference.

- department(**department_id**, name)
- patient(**patient_id**, given_name, family_name, date_of_birth, phone, active)
- clinician(**clinician_id**, department_id → department, display_name, specialty, active)
- appointment(**appointment_id**, patient_id → patient, clinician_id → clinician, starts_at, status, reason)
- diagnosis(**diagnosis_id**, appointment_id → appointment, icd10_code, description, recorded_at)
- medication(**medication_id**, name, form, stock_quantity)
- prescription(**prescription_id**, appointment_id → appointment, issued_at)
- prescription_item(**prescription_id** → prescription, **medication_id** → medication, dosage, quantity)
- lab_test(**lab_test_id**, name, price)
- lab_order(**lab_order_id**, appointment_id → appointment, lab_test_id → lab_test, ordered_at, status, result_summary)

## Relationships

- A department has many clinicians; each clinician belongs to exactly one department.
- A patient has many appointments; each appointment is for exactly one patient.
- A clinician has many appointments; each appointment is with exactly one clinician.
- An appointment can have many diagnoses, prescriptions and lab orders.
- Prescriptions and medications are many-to-many: one prescription lists several medicines, and one medicine appears on many prescriptions. prescription_item resolves this.
- Appointments and lab tests are also many-to-many, resolved by lab_order.

## Business rules and the constraints that enforce them

| Rule | Constraint |
| --- | --- |
| Department, medicine and lab test names are unique | uq_department_name, uq_medication_name, uq_lab_test_name |
| A clinician must belong to an existing department | fk_clinician_department |
| Appointments must reference a registered patient and an existing clinician | fk_appointment_patient, fk_appointment_clinician |
| A clinician cannot be booked twice at the same start time | uq_appointment_clinician_slot |
| Appointment status is booked, cancelled or completed | chk_appointment_status |
| Diagnosis codes follow the ICD-10 format (e.g. J06.9) | chk_diagnosis_icd10_format |
| Pharmacy stock can never be negative | chk_medication_stock_nonnegative |
| A prescribed quantity is at least one, and a medicine appears once per prescription | chk_prescription_item_quantity_positive, pk_prescription_item |
| Lab order status is ordered, in_progress, completed or cancelled | chk_lab_order_status |
| Lab test prices cannot be negative | chk_lab_test_price_nonnegative |
| Patients with appointment history cannot be deleted | fk_appointment_patient (default delete restriction) |
| Deleting a prescription removes its items | fk_prescription_item_prescription (ON DELETE CASCADE) |

## Assumptions and scope

- Appointments have a fixed start time. Durations and overlapping time ranges are out of scope; a PostgreSQL exclusion constraint on a time range would be the next step.
- Each clinician works in one department.
- Detailed lab results are not stored here. Their fields differ from test to test, so they are modelled as documents in MongoDB in Portfolio 4. lab_order keeps only a short summary.
- Billing and payments are out of scope for this portfolio.
- IDs are assigned explicitly in the sample data so the examples in later portfolios stay readable.
