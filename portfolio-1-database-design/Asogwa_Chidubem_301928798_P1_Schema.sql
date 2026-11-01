-- The Craftsmen Clinic: tables, keys and business rules.
-- Run once in a fresh database:
--   psql -d clinic -f Asogwa_Chidubem_301928798_P1_Schema.sql
BEGIN;

CREATE SCHEMA portfolio;

-- Departments the clinic is organised into.
CREATE TABLE portfolio.department (
  department_id  bigint NOT NULL,
  name           text   NOT NULL,
  CONSTRAINT pk_department PRIMARY KEY (department_id),
  CONSTRAINT uq_department_name UNIQUE (name)
);

CREATE TABLE portfolio.patient (
  patient_id     bigint  NOT NULL,
  given_name     text    NOT NULL,
  family_name    text    NOT NULL,
  date_of_birth  date    NOT NULL,
  phone          text,
  active         boolean NOT NULL DEFAULT true,
  CONSTRAINT pk_patient PRIMARY KEY (patient_id),
  CONSTRAINT chk_patient_dob_realistic CHECK (date_of_birth > DATE '1900-01-01')
);

-- Every clinician belongs to exactly one department.
CREATE TABLE portfolio.clinician (
  clinician_id   bigint  NOT NULL,
  department_id  bigint  NOT NULL,
  display_name   text    NOT NULL,
  specialty      text    NOT NULL,
  active         boolean NOT NULL DEFAULT true,
  CONSTRAINT pk_clinician PRIMARY KEY (clinician_id),
  CONSTRAINT fk_clinician_department FOREIGN KEY (department_id)
    REFERENCES portfolio.department (department_id)
);

-- A clinician cannot be booked twice at the same start time.
CREATE TABLE portfolio.appointment (
  appointment_id bigint      NOT NULL,
  patient_id     bigint      NOT NULL,
  clinician_id   bigint      NOT NULL,
  starts_at      timestamptz NOT NULL,
  status         text        NOT NULL DEFAULT 'booked',
  reason         text,
  CONSTRAINT pk_appointment PRIMARY KEY (appointment_id),
  CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id)
    REFERENCES portfolio.patient (patient_id),
  CONSTRAINT fk_appointment_clinician FOREIGN KEY (clinician_id)
    REFERENCES portfolio.clinician (clinician_id),
  CONSTRAINT uq_appointment_clinician_slot UNIQUE (clinician_id, starts_at),
  CONSTRAINT chk_appointment_status
    CHECK (status IN ('booked', 'cancelled', 'completed'))
);

-- One appointment can produce several diagnoses (ICD-10 coded).
CREATE TABLE portfolio.diagnosis (
  diagnosis_id   bigint      NOT NULL,
  appointment_id bigint      NOT NULL,
  icd10_code     text        NOT NULL,
  description    text        NOT NULL,
  recorded_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_diagnosis PRIMARY KEY (diagnosis_id),
  CONSTRAINT fk_diagnosis_appointment FOREIGN KEY (appointment_id)
    REFERENCES portfolio.appointment (appointment_id),
  CONSTRAINT chk_diagnosis_icd10_format
    CHECK (icd10_code ~ '^[A-Z][0-9]{2}(\.[0-9A-Z]{1,4})?$')
);

-- Medicines the clinic pharmacy stocks.
CREATE TABLE portfolio.medication (
  medication_id  bigint  NOT NULL,
  name           text    NOT NULL,
  form           text    NOT NULL,
  stock_quantity integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_medication PRIMARY KEY (medication_id),
  CONSTRAINT uq_medication_name UNIQUE (name),
  CONSTRAINT chk_medication_stock_nonnegative CHECK (stock_quantity >= 0)
);

-- A prescription is issued during one appointment.
CREATE TABLE portfolio.prescription (
  prescription_id bigint      NOT NULL,
  appointment_id  bigint      NOT NULL,
  issued_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_prescription PRIMARY KEY (prescription_id),
  CONSTRAINT fk_prescription_appointment FOREIGN KEY (appointment_id)
    REFERENCES portfolio.appointment (appointment_id)
);

-- Resolves the many-to-many link between prescriptions and medications.
-- Items belong to their prescription, so they are removed with it.
CREATE TABLE portfolio.prescription_item (
  prescription_id bigint  NOT NULL,
  medication_id   bigint  NOT NULL,
  dosage          text    NOT NULL,
  quantity        integer NOT NULL,
  CONSTRAINT pk_prescription_item PRIMARY KEY (prescription_id, medication_id),
  CONSTRAINT fk_prescription_item_prescription FOREIGN KEY (prescription_id)
    REFERENCES portfolio.prescription (prescription_id) ON DELETE CASCADE,
  CONSTRAINT fk_prescription_item_medication FOREIGN KEY (medication_id)
    REFERENCES portfolio.medication (medication_id),
  CONSTRAINT chk_prescription_item_quantity_positive CHECK (quantity > 0)
);

-- Catalogue of tests the laboratory offers (prices in naira).
CREATE TABLE portfolio.lab_test (
  lab_test_id    bigint        NOT NULL,
  name           text          NOT NULL,
  price          numeric(10,2) NOT NULL,
  CONSTRAINT pk_lab_test PRIMARY KEY (lab_test_id),
  CONSTRAINT uq_lab_test_name UNIQUE (name),
  CONSTRAINT chk_lab_test_price_nonnegative CHECK (price >= 0)
);

-- A test ordered during an appointment. Detailed results, whose fields
-- differ from test to test, are modelled in MongoDB in Portfolio 4.
CREATE TABLE portfolio.lab_order (
  lab_order_id   bigint      NOT NULL,
  appointment_id bigint      NOT NULL,
  lab_test_id    bigint      NOT NULL,
  ordered_at     timestamptz NOT NULL DEFAULT now(),
  status         text        NOT NULL DEFAULT 'ordered',
  result_summary text,
  CONSTRAINT pk_lab_order PRIMARY KEY (lab_order_id),
  CONSTRAINT fk_lab_order_appointment FOREIGN KEY (appointment_id)
    REFERENCES portfolio.appointment (appointment_id),
  CONSTRAINT fk_lab_order_test FOREIGN KEY (lab_test_id)
    REFERENCES portfolio.lab_test (lab_test_id),
  CONSTRAINT chk_lab_order_status
    CHECK (status IN ('ordered', 'in_progress', 'completed', 'cancelled'))
);

COMMIT;
