# Patient Contact Management System Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Database Schema](#database-schema)
4. [Script Components](#script-components)
5. [Operational Workflow](#operational-workflow)
6. [Business Logic](#business-logic)
7. [Error Handling](#error-handling)
8. [Reporting Functions](#reporting-functions)
9. [Date Range Analysis](#date-range-analysis)
10. [Technical Considerations](#technical-considerations)
11. [CSV Format Specification](#csv-format-specification)
12. [Troubleshooting](#troubleshooting)
13. [Healthcare Compliance Considerations](#healthcare-compliance-considerations)
14. [Security Best Practices](#security-best-practices)
15. [Version History](#version-history)

## Introduction

The Patient Contact Management System is a MySQL script-based solution for managing patient contact information in OpenMRS-based healthcare systems. It enables healthcare administrators to update patient contact details (phone numbers, addresses, and birthdates) in batch operations while maintaining a complete audit trail.

### Purpose

This system addresses the need for efficient updates to patient contact information while:
- Preserving data integrity
- Creating an audit history of all changes
- Validating input data
- Generating comprehensive reports

### Target Environment

- **Database**: MySQL 5.7 or higher (backwards compatible)
- **Schema**: OpenMRS-compatible database structure
- **Intended Users**: Healthcare database administrators, IT staff, data managers

## System Architecture

The script operates directly on the OpenMRS database schema, interacting primarily with the following tables:

```
┌─────────────────────┐      ┌───────────────────┐      ┌─────────────────┐
│ patient_identifier  │      │ person_attribute  │      │ person_address  │
└─────────────────────┘      └───────────────────┘      └─────────────────┘
         │                            │                          │
         │                            │                          │
         └──────────────┬─────────────┴──────────────┬───────────┘
                        │                            │
                 ┌──────┴──────┐              ┌──────┴──────┐
                 │  Staging    │              │   Report    │
                 │    Table    │───────────→  │   Tables    │
                 └─────────────┘              └─────────────┘
```

The system employs a staging table approach to process updates in a controlled transaction environment.

## Database Schema

### Primary NMRS Tables

1. **patient_identifier**
   - Stores unique identifiers (ART IDs) for patients
   - Used to link ART IDs to internal patient_id
   - Key identifier_type = 4 for ART IDs

2. **person_attribute**
   - Stores patient attributes including phone numbers
   - The script updates attributes with type_id = 8 (phone numbers)
   - Maintains audit trail through voided/date_voided fields

3. **person**
   - Stores basic patient information including birthdates
   - The script updates the birthdate field
   - Updates date_changed field to track modifications

4. **person_address**
   - Stores patient address information
   - Updates are made to address2 field (preferred)
   - Preserves demographic information during updates

### System-Created Tables

1. **contact_update_staging**
   ```sql
   CREATE TABLE contact_update_staging (
       id INT AUTO_INCREMENT PRIMARY KEY,
       art_id VARCHAR(50) NOT NULL,
       new_phone VARCHAR(50),
       new_address VARCHAR(255),
       new_birthdate DATE,
       old_birthdate VARCHAR(20),
       patient_id INT,
       phone_status VARCHAR(100),
       address_status VARCHAR(100),
       birthdate_status VARCHAR(100),
       date_created DATETIME DEFAULT NOW()
   );
   ```

2. **update_report**
   ```sql
   CREATE TABLE update_report (
       art_id VARCHAR(50),
       patient_id INT,
       update_type VARCHAR(20),
       old_value VARCHAR(255),
       new_value VARCHAR(255),
       status VARCHAR(100),
       date_processed DATETIME
   );
   ```

## Script Components

The script is organized into the following functional components:

1. **Table Setup**: Creates necessary tables and ensures column existence
2. **Data Input**: Loads data from CSV or accepts manual input
3. **Patient Identification**: Maps ART IDs to internal patient IDs
4. **Validation**: Validates phone numbers, addresses, and birthdates
5. **Processing Logic**: Updates database records with transactional integrity
6. **Reporting**: Generates detailed reports on operations performed

## Operational Workflow

1. **Initial Setup**
   - Create/validate staging and report tables
   - Clear previous staging data

2. **Data Import**
   - Load from CSV or insert manually
   - Map ART IDs to patient_ids

3. **Validation**
   - Validate phone numbers (11 digits, starts with 0)
   - Validate birthdates (realistic dates, not future)
   - Mark records with appropriate status

4. **Phone Update Processing**
   - Compare with existing phone numbers
   - Skip if already matches
   - Void existing records for audit trail
   - Insert new records

5. **Birthdate Update Processing** (New in v2.3.0)
   - Store original birthdate values
   - Compare with existing birthdates
   - Skip if already matches
   - Update person table
   - Update date_changed field

6. **Address Update Processing**
   - Compare with existing addresses
   - Skip if already matches
   - Void existing records for audit trail
   - Insert new records with preserved demographics

7. **Report Generation**
   - Record all updates in report table
   - Generate summary statistics
   - Provide date-range filtering options

## Business Logic

### Phone Number Processing

1. **Validation Rules**:
   - Must be 11 digits
   - Must start with '0'
   - Cannot be empty

2. **Update Process**:
   ```
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
   │ Check if      │     │ Void existing │     │ Create new    │
   │ matches       │──→  │ record        │──→  │ record        │
   │ existing      │     │ (if exists)   │     │               │
   └───────────────┘     └───────────────┘     └───────────────┘
   ```

### Birthdate Processing (New Feature)

1. **Validation Rules**:
   - Cannot be in the future
   - Cannot be before 1900
   - Must be a valid date format

2. **Update Process**:
   ```
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
   │ Store         │     │ Check if      │     │ Update person │
   │ original      │──→  │ matches       │──→  │ table with    │
   │ value         │     │ existing      │     │ new date      │
   └───────────────┘     └───────────────┘     └───────────────┘
   ```

3. **Audit Trail**:
   - All old birthdates are stored for reporting
   - Updates include date_changed and changed_by columns

### Address Processing

1. **Validation**:
   - Address cannot be empty
   - Patient ID must be valid

2. **Update Process**:
   ```
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
   │ Check both    │     │ Void existing │     │ Create new    │
   │ address1 and  │──→  │ record        │──→  │ record with   │
   │ address2      │     │ (if exists)   │     │ demographics  │
   └───────────────┘     └───────────────┘     └───────────────┘
   ```

3. **Demographics Preservation**:
   - Demographic data (city, state, country) is preserved
   - Uses fallback values from location table if needed

## Error Handling

The script includes comprehensive error handling:

1. **Table Structure Validation**:
   - Checks for existence of old_birthdate column
   - Dynamically adds column if missing

2. **Data Validation**:
   - Marks invalid phone numbers with specific error messages
   - Validates ART IDs against patient database
   - Prevents update if birthdate is invalid

3. **Transactional Integrity**:
   - Uses transaction blocks (`BEGIN` and `COMMIT`)
   - Ensures atomicity of updates
   - Prevents partial updates

## Reporting Functions

The system generates three types of reports:

1. **Detail Report**:
   - Individual record of each update attempt
   - Shows old and new values
   - Includes status of each operation

2. **Summary Statistics**:
   - Aggregated counts by update type
   - Success, skipped, and failure counts
   - Total attempts metrics

3. **Date-Range Analysis**:
   - Filterable by date range
   - Grouped by date and update type
   - Success/failure breakdowns

## Date Range Analysis

The script includes functionality for date-based analysis using parameters:

```sql
-- Example usage:
SET @start_date = '2025-01-01';
SET @end_date = '2025-04-30';

-- Query will filter reports between these dates
SELECT 
    DATE_FORMAT(date_processed, '%Y-%m-%d') AS update_date,
    update_type,
    COUNT(*) AS total_updates,
    SUM(CASE WHEN status = 'updated successfully' THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN status LIKE 'skipped%' THEN 1 ELSE 0 END) AS skipped,
    SUM(CASE WHEN status LIKE 'failed%' THEN 1 ELSE 0 END) AS failed
FROM update_report
WHERE date_processed BETWEEN @start_date AND @end_date
GROUP BY update_date, update_type
ORDER BY update_date DESC, update_type;
```

## Technical Considerations

### MySQL Compatibility

The script is designed for compatibility with MySQL 5.7 and earlier, avoiding:
- Common Table Expressions (CTEs)
- Window functions
- Other features not available in older MySQL versions

### Performance Optimization

- Uses bulk operations for improved performance
- Incorporates appropriate indexes on lookup fields
- Uses subqueries efficiently

### Memory Management

- Processes updates in separate transactions to manage memory
- Prevents large transaction logs

## CSV Format Specification

The system accepts CSV files with the following structure:

```csv
art_id,new_phone,new_address,new_birthdate
6277,08161536864,some address,1985-03-15
13350,07088078791,,1990-06-22
4842,,okay address: GH A,
5234,08122232422,"UMUOKA, AMAZU",
```

**Rules**:
- Header row must be present (skipped during import)
- All columns must be present (values can be empty)
- Double quotes should enclose values with commas
- Dates should be in YYYY-MM-DD format

## Troubleshooting

### Common Issues and Solutions

1. **Unknown Column 'old_birthdate'**:
   - Indicates the column doesn't exist in the staging table
   - Solution: Ensure the ALTER TABLE statement runs successfully
   - The script now includes dynamic checks to prevent this error

2. **Invalid ART IDs**:
   - Check that ART IDs match those in the patient_identifier table
   - Verify identifier_type = 4 for ART IDs
   - Check for leading/trailing spaces in the CSV file

3. **CSV Import Errors**:
   - Check file path and permissions
   - Ensure CSV format matches expected structure
   - Check for special characters or encoding issues
   - Try saving the CSV in UTF-8 encoding

4. **MySQL Version Limitations**:
   - If using MySQL earlier than 5.7, some syntax may need adjustment
   - Particularly check dynamic SQL and prepared statement usage
   - The script is compatible with MySQL 5.7 and above

5. **Date Format Issues**:
   - Ensure dates are in YYYY-MM-DD format
   - Check for validity of dates (e.g., February 30th is invalid)
   - The script validates dates to prevent future dates or unrealistic past dates

## Healthcare Compliance Considerations

When implementing this system in healthcare settings, consider the following compliance requirements:

1. **Patient Privacy**:
   - Access to the system should be restricted to authorized personnel
   - Updates to patient information should be logged and auditable
   - Patient identifiers should be protected according to local healthcare regulations

2. **Data Protection**:
   - CSV files containing patient information should be stored securely
   - Files should be deleted after processing when possible
   - Database connections should use encryption when available

3. **Audit Requirements**:
   - The script maintains a complete audit trail of all changes
   - Additional logging may be required for compliance with specific regulations
   - Regular review of update reports is recommended

## Security Best Practices

To securely implement this system:

1. **Database Security**:
   - Use a dedicated database user with minimal required permissions
   - Avoid using root accounts for running the script
   - Secure MySQL server with appropriate authentication settings

2. **File Security**:
   - Place CSV files in a secure directory with restricted access
   - Consider encrypting CSV files when at rest
   - Implement a file cleanup routine after processing

3. **Application Security**:
   - When integrating with front-end applications, implement proper authentication
   - Validate all input data before processing
   - Consider using prepared statements for any additional custom queries

## Version History

### v2.3.0 (April 2025)
- Added dynamic column existence check for old_birthdate
- Fixed reporting issues for birthdate updates
- Improved transaction handling

### v2.2.0 (April 2025)
- Added birthdate update functionality
- Added reporting for birthdate changes
- Fixed issue with address comparison

### v2.1.0 (March 2025)
- Improved address comparison logic
- Added demographic data preservation
- Enhanced reporting capabilities

### v2.0.0 (March 2024)
- Initial release with phone and address update capabilities
- Basic reporting functions