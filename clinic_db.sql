-- clinic_db.sql
-- MySQL schema for a Clinic Booking System
CREATE DATABASE clinic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinic_db;

SET sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- =====================
-- Table: specialties
-- =====================
CREATE TABLE specialties (
    specialty_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) ENGINE=InnoDB;

-- =====================
-- Table: doctors
-- =====================
CREATE TABLE doctors (
    doctor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    specialty_id INT UNSIGNED,
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctor_specialty FOREIGN KEY (specialty_id)
        REFERENCES specialties (specialty_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================
-- Table: patients
-- =====================
CREATE TABLE patients (
    patient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    date_of_birth DATE,
    gender ENUM('male','female','other') DEFAULT 'other',
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(30),
    address TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =====================
-- Table: rooms
-- =====================
CREATE TABLE rooms (
    room_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL UNIQUE,
    floor INT,
    description VARCHAR(255)
) ENGINE=InnoDB;

-- =====================
-- Table: appointments
-- =====================
CREATE TABLE appointments (
    appointment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    room_id INT UNSIGNED,
    appointment_start DATETIME NOT NULL,
    appointment_end DATETIME,
    status ENUM('scheduled','checked_in','in_progress','completed','cancelled','no_show') NOT NULL DEFAULT 'scheduled',
    reason VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctors (doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_appointment_room FOREIGN KEY (room_id)
        REFERENCES rooms (room_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    INDEX idx_appointment_patient (patient_id),
    INDEX idx_appointment_doctor (doctor_id),
    INDEX idx_appointment_time (appointment_start)
) ENGINE=InnoDB;

-- =====================
-- Table: treatments
-- =====================
CREATE TABLE treatments (
    treatment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB;

-- =====================
-- Table: appointment_treatments (Many-to-Many)
-- =====================
CREATE TABLE appointment_treatments (
    appointment_id INT UNSIGNED NOT NULL,
    treatment_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    notes VARCHAR(255),
    PRIMARY KEY (appointment_id, treatment_id),
    CONSTRAINT fk_at_appointment FOREIGN KEY (appointment_id)
        REFERENCES appointments (appointment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_at_treatment FOREIGN KEY (treatment_id)
        REFERENCES treatments (treatment_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================
-- Table: medications
-- =====================
CREATE TABLE medications (
    medication_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    manufacturer VARCHAR(150),
    dosage_form VARCHAR(100),
    strength VARCHAR(60),
    UNIQUE KEY uniq_medication (name, strength, dosage_form)
) ENGINE=InnoDB;

-- =====================
-- Table: prescriptions
-- =====================
CREATE TABLE prescriptions (
    prescription_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT UNSIGNED, -- optional link to appointment
    patient_id INT UNSIGNED NOT NULL,
    prescribed_by INT UNSIGNED, -- doctor_id
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    CONSTRAINT fk_prescription_appointment FOREIGN KEY (appointment_id)
        REFERENCES appointments (appointment_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_prescription_patient FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_prescription_doctor FOREIGN KEY (prescribed_by)
        REFERENCES doctors (doctor_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    INDEX idx_prescription_patient (patient_id)
) ENGINE=InnoDB;

-- =====================
-- Table: prescription_items (Prescription ⇄ Medication many-to-many)
-- =====================
CREATE TABLE prescription_items (
    prescription_id INT UNSIGNED NOT NULL,
    medication_id INT UNSIGNED NOT NULL,
    dosage VARCHAR(100) NOT NULL,      -- e.g., "250 mg"
    frequency VARCHAR(100) NOT NULL,   -- e.g., "Twice a day"
    duration VARCHAR(100),             -- e.g., "5 days"
    notes VARCHAR(255),
    PRIMARY KEY (prescription_id, medication_id),
    CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id)
        REFERENCES prescriptions (prescription_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_pi_medication FOREIGN KEY (medication_id)
        REFERENCES medications (medication_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================
-- Table: invoices
-- One invoice per appointment (simplified)
-- =====================
CREATE TABLE invoices (
    invoice_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT UNSIGNED UNIQUE, -- one invoice per appointment
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid TINYINT(1) NOT NULL DEFAULT 0,
    notes TEXT,
    CONSTRAINT fk_invoice_appointment FOREIGN KEY (appointment_id)
        REFERENCES appointments (appointment_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================
-- Table: payments
-- Payments for invoices
-- =====================
CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT UNSIGNED NOT NULL,
    paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL,
    method ENUM('cash','card','insurance','other') NOT NULL DEFAULT 'cash',
    reference VARCHAR(200),
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoices (invoice_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_payment_invoice (invoice_id)
) ENGINE=InnoDB;

-- =====================
-- Optional: users (clinic staff) table
-- =====================
CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(80) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120),
    email VARCHAR(150) UNIQUE,
    role ENUM('admin','reception','nurse','doctor','billing') NOT NULL DEFAULT 'reception',
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =====================
-- Sample data (optional) - a few inserts to illustrate structure
-- Comment out or remove in production if you don't want sample rows
-- =====================

INSERT INTO specialties (name, description) VALUES
  ('General Practice', 'Primary care and consultations'),
  ('Pediatrics', 'Children healthcare'),
  ('Dermatology', 'Skin related treatments');

INSERT INTO doctors (first_name, last_name, email, phone, specialty_id) VALUES
  ('Alice', 'Mwangi', 'alice.mwangi@example.com', '+254700111222', 1),
  ('John', 'Otieno', 'john.otieno@example.com', '+254700333444', 2);

INSERT INTO patients (first_name, last_name, date_of_birth, gender, email, phone) VALUES
  ('Grace', 'Kimani', '1990-05-15', 'female', 'grace.kimani@example.com', '+254700555666'),
  ('Samuel', 'Wanyama', '1985-11-02', 'male', 'samuel.wanyama@example.com', '+254700777888');

INSERT INTO rooms (room_number, floor, description) VALUES
  ('101', 1, 'Consultation Room 1'),
  ('102', 1, 'Consultation Room 2');

INSERT INTO treatments (code, name, description, price) VALUES
  ('T100','Basic Consultation','Standard patient consultation', 10.00),
  ('T200','Skin Biopsy','Minor skin biopsy procedure', 75.00);

INSERT INTO medications (name, manufacturer, dosage_form, strength) VALUES
  ('Amoxicillin','Pharma Ltd','Capsule','500 mg'),
  ('Ibuprofen','HealthCorp','Tablet','200 mg');

-- Example appointment, appointment_treatments, prescription, invoice/payment
INSERT INTO appointments (patient_id, doctor_id, room_id, appointment_start, appointment_end, status, reason)
 VALUES (1, 1, 1, '2025-09-30 09:00:00', '2025-09-30 09:20:00', 'scheduled', 'Fever and cough');

INSERT INTO appointment_treatments (appointment_id, treatment_id, quantity, unit_price, notes)
 VALUES (1, 1, 1, 10.00, 'Initial consult');

INSERT INTO prescriptions (appointment_id, patient_id, prescribed_by, notes)
 VALUES (1, 1, 1, 'Prescribed antibiotics');

INSERT INTO prescription_items (prescription_id, medication_id, dosage, frequency, duration, notes)
 VALUES (1, 1, '500 mg', 'Three times a day', '5 days', 'Take after meals');

INSERT INTO invoices (appointment_id, total_amount, paid, notes) VALUES (1, 20.00, 0, 'Consultation + med');

-- commit a sample payment
INSERT INTO payments (invoice_id, amount, method, reference) VALUES (1, 20.00, 'cash', 'receipt-0001');

-- End of clinic_db.sql
