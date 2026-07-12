# Local Data Pipeline Summary

## Objective

Build a local ETL pipeline that simulates Azure Data Factory functionality.

## Pipeline Flow

Source CSV
↓
Get Metadata
↓
Copy Data
↓
Validate Data
↓
Pipeline Completed

## Activities

### 1. Get Metadata
- Retrieved file name
- File size
- Creation time
- Modification time
- Absolute path

### 2. Copy Data
- Copied Superstore.csv from source to destination

### 3. Validation
- Compared row count
- Compared column count
- Verified file integrity using MD5 hash

## Result

Pipeline executed successfully.

Source and destination files matched without data loss.

## Technologies Used

- Python
- Pandas
- JSON
- hashlib
- shutil
- os