/* 
 * ============================================================================
 * Patient Contact Management System
 * ============================================================================
 * 
 * Description:  MySQL script for updating patient phone numbers and addresses
 *               Compatible with MySQL 5.7 and older versions
 * 
 * Version:      2.1.0
 * Created:      March 2024
 * Last Updated: March 5, 2025
 * 
 * Author:       [Adeyemi]
 * Organization: [CCFN]
 * Contact:      [aadegoke007@gmail.com]
 * Repository:   [https://github.com/Adeyemicodes/Contact-Updates.git]
 * 
 * License:      MIT License with Healthcare Implementation Disclaimer
 *               See LICENSE file on the github repository for complete terms
 * 
 * Usage:        1. Configure CSV input path
 *               2. Execute in MySQL environment
 *               3. Review generated reports
 * 
 * This script is part of the Patient Contact Management System.
 * Copyright (c) 2025 [Adeyemi Adegoke]. All rights reserved.
 * ============================================================================
 */


-- Step 1: Create staging table for input data and status tracking
CREATE TABLE IF NOT EXISTS contact_update_staging (
    id INT AUTO_INCREMENT PRIMARY KEY,
    art_id VARCHAR(50) NOT NULL,
    new_phone VARCHAR(50),
    new_address VARCHAR(255),
    patient_id INT,
    phone_status VARCHAR(100),
    address_status VARCHAR(100),
    date_created DATETIME DEFAULT NOW()
);

-- Step 2: Create temporary table for final report
CREATE TABLE IF NOT EXISTS update_report (
    art_id VARCHAR(50),
    patient_id INT,
    update_type VARCHAR(20),
    old_value VARCHAR(255),
    new_value VARCHAR(255),
    status VARCHAR(100),
    date_processed DATETIME
);

-- Step 3: Clean staging and report tables before new run
TRUNCATE TABLE contact_update_staging;
TRUNCATE TABLE update_report;

-- Step 4: Option 1 - Insert data into staging table manually (placeholder - replace with actual data)
-- Uncomment this section if you prefer manual insertion
/*
INSERT INTO contact_update_staging (art_id, new_phone, new_address) 
VALUES 
    ('ART001', '08012345678', NULL),
    ('ART002', NULL, 'New Address 123'),
    ('ART003', '07012345678', 'New Address 456');
*/

-- Step 4: Option 2 - Load data from CSV file in secure directory
-- Use this option to load data from external CSV file
-- Format of CSV should be: art_id,new_phone,new_address (headers optional)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/contact_updates.csv'
INTO TABLE contact_update_staging
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS -- Skip header row if present
(art_id, new_phone, new_address)
SET date_created = NOW();

-- Step 5: Update patient_ids from identifier table
UPDATE contact_update_staging s
JOIN patient_identifier pi ON s.art_id = pi.identifier 
SET s.patient_id = pi.patient_id
WHERE pi.identifier_type = 4 
AND pi.voided = 0;

-- Step 6: Validate phone numbers and mark invalid ones
UPDATE contact_update_staging
SET phone_status = 
    CASE 
        WHEN new_phone IS NULL OR TRIM(new_phone) = '' THEN 'no update needed'
        WHEN patient_id IS NULL THEN 'failed, invalid ART ID'
        WHEN LENGTH(TRIM(new_phone)) != 11 THEN 'failed, phone number shorter or longer than the standard'
        WHEN LEFT(TRIM(new_phone), 1) != '0' THEN 'failed, phone number must start with 0'
        ELSE 'pending'
    END;

-- Step 7: Process phone number updates
BEGIN;

-- Find current phone numbers for comparison
UPDATE contact_update_staging s
LEFT JOIN (
    SELECT person_id, value 
    FROM person_attribute 
    WHERE person_attribute_type_id = 8 
    AND voided = 0
) current_phone ON current_phone.person_id = s.patient_id
SET s.phone_status = 
    CASE 
        WHEN s.phone_status = 'pending' AND s.new_phone = current_phone.value THEN 'skipped, matches current'
        WHEN s.phone_status = 'pending' THEN 'ready for update'
        ELSE s.phone_status
    END;

-- Void existing phone numbers
UPDATE person_attribute pa
JOIN contact_update_staging s ON pa.person_id = s.patient_id
SET 
    pa.changed_by = 1,
    pa.date_changed = NOW(),
    pa.voided = 1,
    pa.voided_by = 1,
    pa.date_voided = NOW(),
    pa.void_reason = CONCAT('New value: ', s.new_phone)
WHERE s.phone_status = 'ready for update'
AND pa.person_attribute_type_id = 8
AND pa.voided = 0;

-- Insert new phone numbers
INSERT INTO person_attribute (
    person_id,
    value,
    person_attribute_type_id,
    creator,
    date_created,
    voided,
    uuid
)
SELECT 
    patient_id,
    new_phone,
    8,
    1,
    NOW(),
    0,
    UUID()
FROM contact_update_staging
WHERE phone_status = 'ready for update';

-- Update final phone status
UPDATE contact_update_staging
SET phone_status = 'updated successfully'
WHERE phone_status = 'ready for update';

COMMIT;

-- Step 8: Process address updates - IMPROVED LOGIC

-- Mark address updates status with fixed comparison logic
BEGIN;

-- First, properly mark the address status
UPDATE contact_update_staging s
SET s.address_status = 
    CASE 
        WHEN s.new_address IS NULL OR TRIM(s.new_address) = '' THEN 'no update needed'
        WHEN s.patient_id IS NULL THEN 'failed, invalid ART ID'
        ELSE 'pending'
    END;

-- Compare with existing addresses (checking both address1 and address2)
UPDATE contact_update_staging s
LEFT JOIN (
    SELECT 
        person_id, 
        address1, 
        address2,
        TRIM(COALESCE(address2, address1)) AS current_address
    FROM person_address 
    WHERE voided = 0 AND preferred = 1
) current_addr ON current_addr.person_id = s.patient_id
SET s.address_status = 
    CASE 
        WHEN s.address_status = 'pending' AND 
             TRIM(s.new_address) = current_addr.current_address THEN 'skipped, matches current'
        WHEN s.address_status = 'pending' THEN 'ready for update'
        ELSE s.address_status
    END;

-- Void existing addresses that need updating
UPDATE person_address pa
JOIN contact_update_staging s ON pa.person_id = s.patient_id
SET 
    pa.preferred = 0,
    pa.voided = 1,
    pa.voided_by = 1,
    pa.date_voided = NOW(),
    pa.date_changed = NOW(),
    pa.changed_by = 1
WHERE s.address_status = 'ready for update'
AND pa.voided = 0
AND pa.preferred = 1;

-- Get location defaults from location table
-- Insert new addresses using location table defaults
INSERT INTO person_address (
    person_id,
    preferred,
    address2,
    city_village,
    state_province,
    country,
    creator,
    date_created,
    voided,
    date_changed,
    changed_by,
    uuid
)
SELECT 
    s.patient_id,
    1,
    s.new_address,
    COALESCE(
        pa.city_village, 
        (SELECT city_village FROM location WHERE location_id = 53)
    ),
    COALESCE(
        pa.state_province, 
        (SELECT state_province FROM location WHERE location_id = 53)
    ),
    COALESCE(
        pa.country, 
        (SELECT country FROM location WHERE location_id = 53)
    ),
    1,
    NOW(),
    0,
    NOW(),
    1,
    UUID()
FROM contact_update_staging s
LEFT JOIN (
    SELECT 
        person_id,
        city_village,
        state_province,
        country
    FROM person_address
    WHERE preferred = 1
    ORDER BY date_changed DESC, person_address_id DESC
) pa ON pa.person_id = s.patient_id
WHERE s.address_status = 'ready for update';

-- Update final address status
UPDATE contact_update_staging
SET address_status = 'updated successfully'
WHERE address_status = 'ready for update';

COMMIT;

-- Step 9: Generate final report
INSERT INTO update_report
SELECT 
    art_id,
    patient_id,
    'Phone',
    (SELECT value FROM person_attribute 
     WHERE person_id = s.patient_id 
     AND person_attribute_type_id = 8 
     AND voided = 1 
     ORDER BY date_voided DESC LIMIT 1),
    new_phone,
    phone_status,
    NOW()
FROM contact_update_staging s
WHERE new_phone IS NOT NULL AND TRIM(new_phone) != ''
UNION ALL
SELECT 
    art_id,
    patient_id,
    'Address',
    (SELECT COALESCE(address2, address1) FROM person_address 
     WHERE person_id = s.patient_id 
     AND voided = 1 
     ORDER BY date_voided DESC LIMIT 1),
    new_address,
    address_status,
    NOW()
FROM contact_update_staging s
WHERE new_address IS NOT NULL AND TRIM(new_address) != '';

-- Step 10: Show final report
SELECT * FROM update_report
ORDER BY art_id, update_type;

-- Step 11: Create another view for overall statistics report
SELECT 
    'Phone Updates' AS update_category,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN phone_status = 'updated successfully' THEN 1 ELSE 0 END) AS successful_updates,
    SUM(CASE WHEN phone_status LIKE 'skipped%' THEN 1 ELSE 0 END) AS skipped_updates,
    SUM(CASE WHEN phone_status LIKE 'failed%' THEN 1 ELSE 0 END) AS failed_updates,
    SUM(CASE WHEN phone_status = 'no update needed' THEN 1 ELSE 0 END) AS no_update_needed
FROM contact_update_staging
WHERE new_phone IS NOT NULL
UNION ALL
SELECT 
    'Address Updates' AS update_category,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN address_status = 'updated successfully' THEN 1 ELSE 0 END) AS successful_updates,
    SUM(CASE WHEN address_status LIKE 'skipped%' THEN 1 ELSE 0 END) AS skipped_updates,
    SUM(CASE WHEN address_status LIKE 'failed%' THEN 1 ELSE 0 END) AS failed_updates,
    SUM(CASE WHEN address_status = 'no update needed' THEN 1 ELSE 0 END) AS no_update_needed
FROM contact_update_staging
WHERE new_address IS NOT NULL;

-- Optional: Clean up staging table after successful run
-- TRUNCATE TABLE contact_update_staging;