# Week-6: Spark Architecture and Data Processing

## Objective

The objective of this assignment is to understand Apache Spark architecture and perform efficient data processing using PySpark. The assignment covers Spark architecture, lazy evaluation, DataFrame transformations, filtering, schema handling, file formats (CSV and Parquet), and performance optimization concepts.

---

## Technologies Used

- Python
- PySpark
- Jupyter Notebook
- Apache Spark

---

## Dataset

Custom dataset containing **200 records** with the following columns:

- product_id
- product_name
- category
- old_name
- price
- base_price
- status
- amount
- region
- priority
- user_id

---

## Tasks Performed

- Read CSV file using Spark
- Display DataFrame schema
- Filter data using conditions
- Select required columns
- Rename columns
- Cast data types
- Add new calculated column
- Handle null values
- Understand Spark DAG and Lazy Evaluation
- Compare CSV and Parquet
- Save processed data as CSV and Parquet

---

## Spark Concepts Covered

- Driver
- Cluster Manager
- Executors
- Lazy Evaluation
- DAG (Lineage Graph)
- Transformations
- Actions
- Predicate Pushdown
- Client Mode vs Cluster Mode

---

## Project Structure

```
Week-6/
│
├── data/
│   └── source.csv
│
├── output_csv/
│
├── output_parquet/
│
├── Week6_Spark_Architecture.ipynb
│
└── README.md
```

---

## Output

- Successfully loaded CSV data
- Performed DataFrame transformations
- Applied filters and selections
- Added calculated columns
- Saved processed data into CSV and Parquet formats

---

## Author

**Aryan Dash**

B.Tech Computer Science & Engineering

Celebal Technologies Internship
