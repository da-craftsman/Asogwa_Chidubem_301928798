# Hospital / Clinic System — SQL queries

## 1. Show related appointment, patient, clinician records (up to 20).

```sql
SELECT t0."appointment_id" AS "appointment_appointment_id",
       t0."starts_at" AS "appointment_starts_at",
       t1."patient_id" AS "patient_patient_id",
       t1."given_name" AS "patient_given_name",
       t2."clinician_id" AS "clinician_clinician_id",
       t2."display_name" AS "clinician_display_name"
FROM portfolio."appointment" t0
JOIN portfolio."patient" t1 ON t0."patient_id" = t1."patient_id"
JOIN portfolio."clinician" t2 ON t0."clinician_id" = t2."clinician_id"
ORDER BY t0."appointment_id", t1."patient_id", t2."clinician_id"
LIMIT 20;
```

| appointment_appointment_id | appointment_starts_at | patient_patient_id | patient_given_name | clinician_clinician_id | clinician_display_name |
| --- | --- | --- | --- | --- | --- |
| 5 | 2026-11-02T09:00:00+00:00 | 1 | Avery | 3 | Dr. Casey Rowan |
| 6 | 2026-11-02T10:00:00+00:00 | 2 | Jordan | 3 | Dr. Casey Rowan |

## 2. Find patient records where given_name matches "Avery" (up to 20).

```sql
SELECT * FROM portfolio."patient"
WHERE "given_name" IS NOT DISTINCT FROM 'Avery'
ORDER BY "patient_id"
LIMIT 20;
```

| patient_id | given_name | family_name | date_of_birth | active |
| --- | --- | --- | --- | --- |
| 1 | Avery | Morgan | 1988-04-12 | true |

## 3. Count appointment records for each patient_id (up to 20 groups).

```sql
SELECT "patient_id", count(*) AS record_count
FROM portfolio."appointment"
GROUP BY "patient_id"
ORDER BY record_count DESC, "patient_id" NULLS LAST
LIMIT 20;
```

| patient_id | record_count |
| --- | --- |
| 1 | 1 |
| 2 | 1 |


## Index comparison

| Phase | Median (ms) | Three runs (ms) | Plan nodes | Buffer hits |
| --- | --- | --- | --- | --- |
| Before index | 2.401 | 2.401, 4.626, 2.351 | Sort → Seq Scan | 274 |
| After index | 0.319 | 0.401, 0.3, 0.319 | Sort → Bitmap Heap Scan → Bitmap Index Scan | 55 |

The median execution time changed from 2.401 ms to 0.319 ms. The measured plan used p2_filter_idx. The results matched in both phases. An index adds storage and write-maintenance costs; timings depend on the selected lookup and environment.

## Execution plans

### Before index, run 1

```text
Sort (actual time=2.347..2.35 rows=50 loops=1)
  Seq Scan on appointment (actual time=0.016..2.303 rows=50 loops=1)
Planning Time: 0.34 ms
Execution Time: 2.401 ms
```

### Before index, run 2

```text
Sort (actual time=4.583..4.586 rows=50 loops=1)
  Seq Scan on appointment (actual time=0.021..4.523 rows=50 loops=1)
Planning Time: 0.461 ms
Execution Time: 4.626 ms
```

### Before index, run 3

```text
Sort (actual time=2.316..2.319 rows=50 loops=1)
  Seq Scan on appointment (actual time=0.015..2.279 rows=50 loops=1)
Planning Time: 0.384 ms
Execution Time: 2.351 ms
```

### After index, run 1

```text
Sort (actual time=0.322..0.326 rows=50 loops=1)
  Bitmap Heap Scan on appointment (actual time=0.043..0.272 rows=50 loops=1)
    Bitmap Index Scan using p2_filter_idx (actual time=0.023..0.023 rows=50 loops=1)
Planning Time: 0.728 ms
Execution Time: 0.401 ms
```

### After index, run 2

```text
Sort (actual time=0.242..0.244 rows=50 loops=1)
  Bitmap Heap Scan on appointment (actual time=0.035..0.205 rows=50 loops=1)
    Bitmap Index Scan using p2_filter_idx (actual time=0.018..0.018 rows=50 loops=1)
Planning Time: 0.559 ms
Execution Time: 0.3 ms
```

### After index, run 3

```text
Sort (actual time=0.258..0.261 rows=50 loops=1)
  Bitmap Heap Scan on appointment (actual time=0.032..0.221 rows=50 loops=1)
    Bitmap Index Scan using p2_filter_idx (actual time=0.017..0.017 rows=50 loops=1)
Planning Time: 0.553 ms
Execution Time: 0.319 ms
```

## Reproduce

Use a fresh database with the Portfolio 1 schema and sample data. Run Asogwa_Chidubem_301928798_P2_Queries.sql, then Asogwa_Chidubem_301928798_P2_Optimisation.sql. The optimisation script creates a separate performance table and runs EXPLAIN (ANALYZE, BUFFERS).

[Query screenshot](screenshots/Asogwa_Chidubem_301928798_P2_QueryResults.png) · [Index comparison](screenshots/Asogwa_Chidubem_301928798_P2_IndexComparison.png)

## References

- [PostgreSQL — EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html)

