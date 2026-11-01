# The Craftsmen Clinic — ER diagram

```mermaid
erDiagram
    department ||--o{ clinician : employs
    patient ||--o{ appointment : books
    clinician ||--o{ appointment : attends
    appointment ||--o{ diagnosis : records
    appointment ||--o{ prescription : issues
    prescription ||--o{ prescription_item : contains
    medication ||--o{ prescription_item : "listed in"
    appointment ||--o{ lab_order : requests
    lab_test ||--o{ lab_order : "ordered as"

    department {
        bigint department_id PK
        text name UK
    }
    patient {
        bigint patient_id PK
        text given_name
        text family_name
        date date_of_birth
        text phone "optional"
        boolean active
    }
    clinician {
        bigint clinician_id PK
        bigint department_id FK
        text display_name
        text specialty
        boolean active
    }
    appointment {
        bigint appointment_id PK
        bigint patient_id FK
        bigint clinician_id FK
        timestamptz starts_at
        text status "booked, cancelled, completed"
        text reason "optional"
    }
    diagnosis {
        bigint diagnosis_id PK
        bigint appointment_id FK
        text icd10_code
        text description
        timestamptz recorded_at
    }
    medication {
        bigint medication_id PK
        text name UK
        text form
        integer stock_quantity "never negative"
    }
    prescription {
        bigint prescription_id PK
        bigint appointment_id FK
        timestamptz issued_at
    }
    prescription_item {
        bigint prescription_id PK, FK
        bigint medication_id PK, FK
        text dosage
        integer quantity "at least 1"
    }
    lab_test {
        bigint lab_test_id PK
        text name UK
        numeric price "naira"
    }
    lab_order {
        bigint lab_order_id PK
        bigint appointment_id FK
        bigint lab_test_id FK
        timestamptz ordered_at
        text status "ordered, in_progress, completed, cancelled"
        text result_summary "optional"
    }
```

**How to read it:** PK is a primary key, FK a foreign key and UK a unique value. `||--o{` means "exactly one on this side, zero or many on the other". For example, one department employs zero or many clinicians, and each clinician belongs to exactly one department.

prescription_item has a composite primary key (prescription_id, medication_id). It turns the many-to-many relationship between prescriptions and medications into two one-to-many relationships. lab_order does the same for appointments and lab tests.

The double-booking rule (one clinician, one start time) is a composite unique constraint on appointment and is listed in the design document.

![ER diagram](../images/Asogwa_Chidubem_301928798_ERDiagram.png)
