-- Puts the Portfolio 3 demo data back to its starting state.
-- Run before each scenario:  psql -d clinic -f Asogwa_Chidubem_301928798_P3_Reset.sql
-- Rows created by Portfolio 3 use IDs from 900000 upwards, so they are easy to remove.
DELETE FROM portfolio.prescription_item WHERE prescription_id >= 900000;
DELETE FROM portfolio.prescription      WHERE prescription_id >= 900000;
DELETE FROM portfolio.lab_order         WHERE lab_order_id    >= 900000;
DELETE FROM portfolio.diagnosis         WHERE diagnosis_id    >= 900000;
DELETE FROM portfolio.appointment       WHERE appointment_id  >= 900000;
UPDATE portfolio.appointment SET status = 'booked' WHERE appointment_id = 5;
UPDATE portfolio.medication SET stock_quantity = 500 WHERE medication_id = 1;  -- Paracetamol
UPDATE portfolio.medication SET stock_quantity = 200 WHERE medication_id = 2;  -- Amoxicillin
