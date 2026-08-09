import os
import glob
import pandas as pd
from src.database import DatabaseManager

class SQLAnalyticsRunner:
    """Runs all 16 SQL analytical queries and displays formatted results."""
    
    def __init__(self, db_manager=None):
        self.db_manager = db_manager or DatabaseManager()
        if not self.db_manager.conn:
            self.db_manager.connect()

    def run_all_queries(self, queries_dir="queries"):
        query_files = sorted(glob.glob(os.path.join(queries_dir, "*.sql")))
        results = {}

        print("Executing SQL queries...\n")

        for filepath in query_files:
            filename = os.path.basename(filepath)
            q_name = os.path.splitext(filename)[0]

            with open(filepath, "r") as f:
                query_sql = f.read()

            try:
                df_result = self.db_manager.execute_query(query_sql)
                results[q_name] = df_result

                print(f"--- Query: {q_name} ---")
                if not df_result.empty:
                    print(df_result.head(10).to_string(index=False))
                    if len(df_result) > 10:
                        print(f"... ({len(df_result) - 10} more rows)")
                else:
                    print("(No records returned)")
                print("\n" + "-" * 50 + "\n")
            except Exception as e:
                print(f"Error in {q_name}: {e}\n")
                results[q_name] = None

        return results

if __name__ == "__main__":
    runner = SQLAnalyticsRunner()
    runner.run_all_queries()
