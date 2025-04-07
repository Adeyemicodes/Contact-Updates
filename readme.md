# Patient Contact Management System

## Overview

A robust healthcare data management solution for updating patient contact information in the Nigeria Medical Record System (NMRS). This script facilitates batch updates to patient phone numbers, addresses, and birthdates while maintaining complete data integrity and audit trails.

![OpenMRS Compatible](https://img.shields.io/badge/OpenMRS-Compatible-brightgreen)
![MySQL 5.7](https://img.shields.io/badge/MySQL-5.7%20Compatible-blue)

## Key Features

- **Comprehensive Updates**: Update phone numbers, addresses, and birthdates in a single batch process
- **Data Validation**: Built-in validation for phone numbers and birthdates
- **Smart Processing**: Skips unnecessary updates when new values match existing data
- **Complete Audit Trail**: Maintains history of all changes with original values
- **Detailed Reporting**: Generates comprehensive reports on update operations
- **MySQL 5.7 Compatible**: Works with older MySQL versions
- **Dynamic Schema Adaptation**: Automatically checks and adds required columns

## Prerequisites

- MySQL 5.7 or higher
- Database with OpenMRS schema
- Appropriate database permissions
- CSV file for batch updates (optional)

## Quick Start

1. Download the script: `Patient Contact Management System.sql`
2. Modify CSV file path (line 74) or use manual data insertion option
3. Execute script in MySQL environment
4. Review generated reports

## CSV Format

The script accepts CSV files with the following columns:

```
art_id,new_phone,new_address,new_birthdate
6277,08161536864,some address,1985-03-15
13350,07088078791,,1990-06-22
4842,,okay address: GH A,
5234,08122232422,UMUOKA, AMAZU,
```

- Not all fields are required for each entry
- The script will only update fields with values

## Usage Examples

### Example 1: Update Phone Numbers and Addresses

```sql
-- Manual data insertion
INSERT INTO contact_update_staging (art_id, new_phone, new_address) 
VALUES 
    ('ART001', '08012345678', NULL),
    ('ART002', NULL, 'New Address 123'),
    ('ART003', '07012345678', 'New Address 456');
```

### Example 2: Update Patient Birthdates

```sql
-- Manual data insertion with birthdates
INSERT INTO contact_update_staging (art_id, new_birthdate) 
VALUES 
    ('ART001', '1985-03-15'),
    ('ART002', '1990-06-22');
```

## Reporting

The script generates comprehensive reports including:
- Individual update status for each field and patient
- Summary statistics by update type
- Date-range filtering capabilities

## Documentation

Detailed documentation is available in the following files:

- [Contact Management Documentation](contact-management-documentation.md) - Technical details about the SQL implementation
- [LICENSE](LICENSE) - MIT License with healthcare-specific disclaimers

## Healthcare Compliance Notice

This software is designed as a tool for managing patient contact information. Users are responsible for ensuring their implementation complies with all applicable healthcare regulations and privacy laws. See the [LICENSE](LICENSE) file for a complete healthcare implementation disclaimer.

## Future Development

The roadmap includes developing a Python-based graphical user interface that will:
- Provide more user-friendly data entry
- Support single-patient updates
- Offer enhanced reporting and visualization
- Implement additional validation and security features

## Contributing

Contributions to improve the system are welcome. Please review the documentation and adhere to the established patterns when submitting pull requests.

## License

This project is licensed under the MIT License with additional healthcare-specific disclaimers - see the [LICENSE](LICENSE) file for details.

---

Created by Adeyemi Adegoke  
Email: aadegoke007@gmail.com  
Repository: [https://github.com/Adeyemicodes/Contact-Updates](https://github.com/Adeyemicodes/Contact-Updates)