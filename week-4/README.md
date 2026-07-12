# Assignment Week 4 - Local Data Pipeline (Azure Data Factory Simulation)

#  Azure Data Factory Simulation

This project is a **local simulation of an Azure Data Factory (ADF) pipeline** developed using Python.

The original assignment required the following Azure services:

- Azure Resource Group
- Azure Storage Account
- Azure Blob Storage
- Azure Data Factory (ADF)
- IAM Role Configuration

Due to an Azure Student verification issue, Azure cloud resources were unavailable. Therefore, the complete pipeline was implemented locally while preserving the same ETL workflow and logical architecture used in Azure Data Factory.

## Azure Data Factory Workflow

In Azure Data Factory, the pipeline would be implemented as follows:

```text
Resource Group
       │
       ▼
Storage Account
       │
       ▼
Blob Container (Source)
       │
       ▼
Get Metadata Activity
       │
       ▼
Copy Data Activity
       │
       ▼
Blob Container (Destination)
       │
       ▼
Monitor Pipeline Execution
```

## Local Implementation Workflow

The same workflow was recreated locally using Python:

```text
Superstore.csv
        │
        ▼
data/source
        │
        ▼
get_metadata.py
        │
        ▼
metadata.json
        │
        ▼
copy_data.py
        │
        ▼
data/destination
        │
        ▼
validate.py
        │
        ▼
pipeline.py
```

## Azure Components vs Local Implementation

| Azure Data Factory Component | Local Implementation |
|-----------------------------|----------------------|
| Azure Resource Group | Local project folder (`Assignment_week_4`) |
| Azure Storage Account | Local file system |
| Azure Blob Storage (Source Container) | `data/source/` |
| Azure Blob Storage (Destination Container) | `data/destination/` |
| Get Metadata Activity | `get_metadata.py` |
| Metadata Output | `output/metadata.json` |
| Copy Data Activity | `copy_data.py` |
| Pipeline Validation | `validate.py` |
| Azure Data Factory Pipeline | `pipeline.py` |
| Azure Monitor | Terminal execution logs and validation output |
| IAM Role Assignment | Not applicable in the local environment |

## ETL Process Implemented

### Extract
- Read the `Superstore.csv` dataset from the source folder.
- Extract file metadata such as file name, size, creation time, and modification time.

### Transform
- Validate the dataset structure.
- Compare source and destination datasets.
- Verify file integrity using an MD5 hash.

### Load
- Copy the dataset from the source folder to the destination folder.
- Store metadata in a JSON file.
- Generate validation results after pipeline execution.

## Conclusion

Although Azure services were unavailable, this project follows the same ETL pipeline design used in Azure Data Factory. The implementation demonstrates the core concepts of metadata extraction, data movement, validation, and pipeline orchestration using Python in a local environment.

# Author

Aryan Dash

B.Tech Computer Science & Engineering

SOA University
