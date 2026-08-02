# Week 7 - Python Data Exploration and Data Cleaning using Pandas

## Objective

The objective of this assignment is to learn Python basics and perform basic data exploration and data cleaning using the Pandas library.

## Tasks Performed

- Loaded the CSV dataset into a Pandas DataFrame.
- Explored the dataset using:
  - `head()`
  - `tail()`
  - `shape`
  - `columns`
  - `dtypes`
  - `info()`
- Checked for missing values using `isnull().sum()`.
- Verified that the dataset contained no missing values.
- Checked for duplicate records and removed duplicates.
- Filtered rows based on the **Technology** category.
- Selected required columns for analysis.
- Created a derived **Price** column.
- Created a **Total_Amount** column using:
  ```
  Total_Amount = Price × Quantity
  ```
- Saved the cleaned dataset as **cleaned_superstore.csv**.

## Files Included

- `Week7_Assignment.ipynb`
- `cleaned_superstore.csv`
- `README.md`

## Technologies Used

- Python
- Pandas
- Jupyter Notebook

## Outcome

Successfully performed data exploration, cleaning, filtering, duplicate removal, derived column creation, and exported the cleaned dataset as a new CSV file.
