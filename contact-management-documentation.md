# Patient Contact Management System

## Overview

This MySQL script facilitates the batch updating of patient contact information (phone numbers and addresses) in Nigeria Medical Record system. It implements sophisticated business logic to handle updates, maintain data integrity, and generate detailed reports on the process.

## Features

- **Dual Update Capability**: Simultaneously processes both phone numbers and addresses
- **Data Validation**: Enforces validation rules for phone numbers
- **Smart Matching**: Prevents redundant updates when new data matches existing records
- **Audit Trail**: Maintains a comprehensive history of all changes
- **Detailed Reporting**: Generates reports on successful, skipped, and failed updates
- **Data Integrity**: Preserves location and demographic data during updates
- **Compatibility**: Works with older MySQL versions (pre-8.0)

## Database Schema

The script interacts with the following tables:

### Main Tables
1. **patient_identifier**: Stores unique identifiers for patients
   - Key fields: `patient_identifier_id`, `patient_id`, `identifier`, `identifier_type`

2. **person_attribute**: Stores patient attributes including phone numbers
   - Key fields: `person_attribute_id`, `person_id`, `value`, `person_attribute_type_id`

3. **person_address**: Stores patient address information
   - Key fields: `person_address_id`, `person_id`, `address1`, `address2`, `city_village`, `state_province`, `country`

4. **location**: Stores default location information
   - Used to provide default values for new address entries

### Temporary Tables Created by the Script
1. **contact_update_staging**: Holds input data and processing status
2. **update_report**: Stores the results of the update operations

## Business Logic

### Phone Number Updates

1. **Validation**:
   - Phone numbers must be 11 digits
   - Must start with '0'
   - Must not be empty

2. **Update Process**:
   - Compare new phone number with existing records
   - If identical, skip the update
   - If different, void the existing record by:
     - Setting `voided = 1`
     - Updating `voided_by`, `date_voided`, and `void_reason`
   - Create a new record with the updated phone number
   - Set `person_attribute_type_id = 8` for phone numbers

### Address Updates

1. **Validation**:
   - Address must not be empty
   - Patient ID must be valid

2. **Update Process**:
   - Compare new address with existing address in both `address1` and `address2` fields
   - If identical, skip the update
   - If different, void the existing address by:
     - Setting `voided = 1` and `preferred = 0`
     - Updating `voided_by` and `date_voided`
   - Create a new address record:
     - Set `preferred = 1`
     - Place new address in `address2` field
     - Preserve existing demographic data (city, state, country)
     - When previous data is unavailable, use defaults from location table

## Input Format

The script accepts patient data via CSV file with the following format:

```
art_id,new_phone,new_address
ART001,08012345678,123 New Street
ART002,,456 Elm Street
ART003,07012345678,
```

- **art_id**: The patient's ART identifier
- **new_phone**: The new phone number (leave blank if no update needed)
- **new_address**: The new address (leave blank if no update needed)

## Output Reports

The script generates two types of reports:

1. **Detailed Update Report**:
   - Shows each update attempt with status
   - Includes old and new values
   - Records time of processing

2. **Summary Statistics Report**:
   - Provides counts of successful, skipped, and failed updates
   - Separates phone and address statistics
   - Identifies various failure reasons

## Usage Instructions

### Prerequisites

- MySQL server (version 5.7 or later recommended)
- Appropriate database permissions
- Input CSV file

### Step-by-Step Guide

1. **Prepare Input Data**:
   - Create a CSV file with patient updates
   - Include headers: `art_id,new_phone,new_address`
   - Place the file in an accessible directory (default: `C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/contact_updates.csv`)

2. **Customize File Path**:
   - Modify the `LOAD DATA INFILE` path to match your CSV location

3. **Execute the Script**:
   - Run the script using MySQL command line or GUI tool
   - Review the output reports to confirm successful processing

4. **Review Results**:
   - Query the `update_report` table for detailed results
   - Run the summary statistics query for an overview

## Data Flow

```
CSV Input → contact_update_staging → Validation → 
Patient Lookup → Match Checking → Update Processing → 
update_report → Final Reports
```

## Error Handling

The script handles several error conditions:

- Invalid ART IDs: Marks updates as "failed, invalid ART ID"
- Invalid phone formats: Flags with specific error messages
- Empty fields: Marks as "no update needed"
- Duplicate data: Identifies and skips with "skipped, matches current"

## Future Development

This system will be enhanced with a Python-based user interface to improve usability. The planned Python application will:

1. Provide a graphical interface for data entry
2. Support single-patient updates as well as batch processing
3. Offer real-time validation and feedback
4. Generate downloadable reports
5. Maintain audit logs of all updates

## Technical Considerations

- The script is designed for compatibility with older MySQL versions (pre-8.0)
- It avoids Common Table Expressions (CTEs), window functions, and other features not available in older MySQL versions
- Transaction blocks ensure data integrity during processing
- Careful error handling prevents partial updates

## Security Considerations

- The script assumes appropriate database permissions are in place
- Input validation helps prevent SQL injection 
- Records are voided rather than deleted to maintain audit trails
- User IDs are recorded for all changes

## Maintenance

Regular maintenance tasks include:

- Reviewing error logs and reports
- Monitoring database size as voided records accumulate
- Updating validation rules as needed
- Optimizing queries if performance issues arise

---

Created: March 2025  
License: [Insert your license information]  
Author: [Your name or organization]
