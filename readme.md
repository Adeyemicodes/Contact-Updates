# Patient Contact Management System

A robust healthcare data management solution for updating patient contact information in the Nigeria Medical Record System (NMRS). This system efficiently processes both individual and batch updates of phone numbers and addresses while maintaining data integrity and audit trails.

## Key Features

- Dual update capability for phone numbers and addresses
- Smart matching logic to prevent redundant updates
- Comprehensive validation and error handling
- Detailed audit trails for all changes
- Compatible with MySQL 5.7 and older versions
- Generates detailed reports and statistics

## Overview

The Patient Contact Management System is designed to solve common challenges in maintaining accurate patient contact information in healthcare databases. It provides a structured approach to:

1. Update phone numbers and addresses in batch or individually
2. Validate data before processing updates
3. Maintain a comprehensive history of all changes
4. Generate reports on update status and statistics

The current implementation uses MySQL with plans for a Python-based UI that will make the system more accessible to healthcare workers.

## Technical Requirements

- MySQL 5.7 or compatible database system
- Database user with appropriate permissions
- Secure file access for CSV imports

## Documentation

Detailed documentation is available in the following files:

- [Patient Contact Management System Documentation](contact-management-documentation.md) - Technical details about the SQL implementation
- [Python Implementation Roadmap](python-future-roadmap.md) - Future development plans for a user-friendly interface
- [LICENSE](license.md) - MIT License with healthcare-specific disclaimers

## Usage

### Basic Steps

1. Prepare your CSV file with patient updates (format: art_id, new_phone, new_address)
2. Update the file path in the script to point to your CSV
3. Execute the script in your MySQL environment
4. Review the generated reports for update status

### Example

For a detailed walkthrough of usage and examples, please refer to the full documentation.

## Healthcare Compliance Notice

This software is designed as a tool for managing patient contact information. Users are responsible for ensuring their implementation complies with all applicable healthcare regulations and privacy laws. See the [LICENSE](license.md) file for a complete healthcare implementation disclaimer.

## Future Development

The roadmap includes developing a Python-based graphical user interface that will:

- Provide more user-friendly data entry
- Support single-patient updates
- Offer enhanced reporting and visualization
- Implement additional validation and security features

## Contributing

Contributions to improve the system are welcome. Please review the documentation and adhere to the established patterns when submitting pull requests.

## License

This project is licensed under the MIT License with additional healthcare-specific disclaimers - see the [LICENSE](license.md) file for details.

---

Created by [Adeyemi Adegoke]
