// Detailed lab results for The Craftsmen Clinic, stored as MongoDB documents.
// Run from the portfolio-4-nosql folder:
//   mongosh --quiet --file Asogwa_Chidubem_301928798_P4_LabResults.js
// Safe to re-run: it drops and rebuilds the collection each time.
//
// Each document is the full result of one completed lab order. lab_order_id,
// appointment_id and patient_id match the rows in PostgreSQL (Portfolios 1-2),
// so the two databases describe the same clinic.

db = db.getSiblingDB("craftsmen_clinic");
db.lab_results.drop();

// 1. Collection with a validator ---------------------------------------------
// MongoDB does not force a structure by default. This validator requires the
// fields every result must have, but leaves "results" free to take a
// different shape for each type of test.
db.createCollection("lab_results", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["lab_order_id", "appointment_id", "patient", "test", "reported_at", "abnormal", "results"],
      properties: {
        lab_order_id:   { bsonType: "number" },
        appointment_id: { bsonType: "number" },
        patient: {
          bsonType: "object",
          required: ["patient_id", "name"],
          properties: { patient_id: { bsonType: "number" }, name: { bsonType: "string" } }
        },
        test:        { bsonType: "string" },
        reported_at: { bsonType: "date" },
        abnormal:    { bsonType: "bool" },
        results:     { bsonType: "object" }
      }
    }
  }
});

// 2. Six results, five different shapes --------------------------------------
db.lab_results.insertMany([
  {
    lab_order_id: 1, appointment_id: 6,
    patient: { patient_id: 2, name: "Jordan Lee" },
    test: "Full Blood Count",
    reported_at: ISODate("2026-11-02T13:05:00Z"),
    abnormal: false,
    summary: "Within normal range",
    results: {
      haemoglobin:      { value: 13.8, unit: "g/dL",    range: "12.0-17.5", flag: "normal" },
      white_cell_count: { value: 6.2,  unit: "x10^9/L", range: "4.0-11.0",  flag: "normal" },
      platelets:        { value: 245,  unit: "x10^9/L", range: "150-400",   flag: "normal" }
    }
  },
  {
    lab_order_id: 34236, appointment_id: 106185,
    patient: { patient_id: 1234, name: "Ibrahim Ogunleye" },
    test: "Malaria Parasite Test",
    reported_at: ISODate("2025-12-05T10:30:00Z"),
    abnormal: false,
    summary: "Negative",
    results: { method: "Thick and thin blood film", parasites_seen: false }
  },
  {
    lab_order_id: 1023, appointment_id: 1089,
    patient: { patient_id: 12160, name: "Nnamdi Onyeka" },
    test: "Malaria Parasite Test",
    reported_at: ISODate("2024-11-04T11:05:00Z"),
    abnormal: true,
    summary: "Positive",
    results: {
      method: "Thick and thin blood film",
      parasites_seen: true,
      species: "Plasmodium falciparum",
      parasite_density_per_ul: 2400
    },
    comments: "Clinician informed by phone"
  },
  {
    lab_order_id: 1001, appointment_id: 1016,
    patient: { patient_id: 15966, name: "Amaka Ogunleye" },
    test: "Urinalysis",
    reported_at: ISODate("2024-11-04T09:40:00Z"),
    abnormal: true,
    summary: "Slightly elevated",
    results: {
      appearance: "clear", ph: 6.0, protein: "trace", glucose: "negative", leukocytes: "1+",
      microscopy: ["few epithelial cells", "occasional pus cells"]
    }
  },
  {
    lab_order_id: 16630, appointment_id: 50406,
    patient: { patient_id: 1234, name: "Ibrahim Ogunleye" },
    test: "Fasting Blood Sugar",
    reported_at: ISODate("2025-05-08T11:00:00Z"),
    abnormal: true,
    summary: "Below normal range",
    fasting_hours: 10,
    results: {
      glucose: { value: 3.4, unit: "mmol/L", range: "3.9-5.5", flag: "low" }
    }
  },
  {
    lab_order_id: 30860, appointment_id: 95509,
    patient: { patient_id: 1234, name: "Ibrahim Ogunleye" },
    test: "Lipid Profile",
    reported_at: ISODate("2025-10-27T12:20:00Z"),
    abnormal: false,
    summary: "Within normal range",
    results: {
      total_cholesterol: { value: 4.6, unit: "mmol/L", range: "below 5.2", flag: "normal" },
      hdl:               { value: 1.3, unit: "mmol/L", range: "above 1.0", flag: "normal" },
      ldl:               { value: 2.7, unit: "mmol/L", range: "below 3.4", flag: "normal" },
      triglycerides:     { value: 1.3, unit: "mmol/L", range: "below 1.7", flag: "normal" }
    }
  }
]);
print("Inserted documents: " + db.lab_results.countDocuments());

// Prints each document on one line, so the output stays short and readable.
function show(docs) {
  docs.forEach(doc => print("  " + JSON.stringify(doc)));
}

// Small helper: the main stages of a query plan, e.g. "FETCH > IXSCAN".
function planStages(explained) {
  let node = explained.queryPlanner.winningPlan;
  node = node.queryPlan || node;
  const stages = [];
  while (node) {
    stages.push(node.stage);
    node = node.inputStage || (node.inputStages && node.inputStages[0]);
  }
  return stages.join(" > ");
}

// 3. Queries -----------------------------------------------------------------
print("\n=== Q1. Lab history for patient 1234, newest first ===");
show(db.lab_results
  .find({ "patient.patient_id": 1234 }, { _id: 0, test: 1, reported_at: 1, summary: 1 })
  .sort({ reported_at: -1 })
  .toArray());

print("\n=== Q2. Every abnormal result, for clinician follow-up ===");
show(db.lab_results
  .find({ abnormal: true }, { _id: 0, "patient.name": 1, test: 1, summary: 1 })
  .toArray());

print("\n=== Q3. Query inside a test-specific field: malaria parasites seen ===");
show(db.lab_results
  .find({ "results.parasites_seen": true },
        { _id: 0, "patient.name": 1, "results.species": 1, "results.parasite_density_per_ul": 1 })
  .toArray());

print("\n=== Q4. Aggregation: results and abnormal results per test ===");
show(db.lab_results.aggregate([
  { $group: { _id: "$test", results: { $sum: 1 }, abnormal: { $sum: { $cond: ["$abnormal", 1, 0] } } } },
  { $sort: { _id: 1 } }
]).toArray());

// 4. Validation ----------------------------------------------------------------
print("\n=== Validation: a result with no patient is rejected ===");
try {
  db.lab_results.insertOne({
    lab_order_id: 99999, appointment_id: 99999,
    test: "Full Blood Count", reported_at: new Date(), abnormal: false, results: {}
  });
  print("Inserted (validation did not work)");
} catch (e) {
  print("Rejected: " + e.message);
}

// 5. Index -----------------------------------------------------------------------
print("\n=== Index: Q1 before and after indexing patient_id ===");
const q1 = () => db.lab_results.find({ "patient.patient_id": 1234 }).sort({ reported_at: -1 });

let before = q1().explain("executionStats");
print("Before: plan " + planStages(before) +
      ", documents examined " + before.executionStats.totalDocsExamined);

db.lab_results.createIndex({ "patient.patient_id": 1, reported_at: -1 });

let after = q1().explain("executionStats");
print("After:  plan " + planStages(after) +
      ", documents examined " + after.executionStats.totalDocsExamined);
