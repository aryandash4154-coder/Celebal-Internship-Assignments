"""
Zip Archive Generator for Global Retail Data Modelling Project
Ensures all file entries inside the ZIP archive use strict UNIX-style '/' path separators.
"""

import os
import zipfile
from pathlib import Path

# Paths
ROOT_DIR = Path(__file__).resolve().parent.parent
ARTIFACT_DIR = Path(r"C:\Users\91993\.gemini\antigravity\brain\b6601432-4a1a-4c73-9877-a4c9632b10fd")

# Exclude patterns
EXCLUDE_DIRS = {'.git', '__pycache__', '.pytest_cache', '.venv', 'venv'}
EXCLUDE_FILES = {'warehouse.db'}
EXCLUDE_EXTS = {'.pyc', '.zip'}

def create_zip(output_path):
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(ROOT_DIR):
            # Exclude unwanted directories
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
            
            for file in sorted(files):
                file_path = Path(root) / file
                
                if file in EXCLUDE_FILES or file_path.suffix in EXCLUDE_EXTS:
                    continue

                # Relative path from project root
                rel_path = file_path.relative_to(ROOT_DIR)
                
                # Convert path to UNIX forward slashes
                arcname = rel_path.as_posix()
                
                zipf.write(file_path, arcname=arcname)
                print(f"  [+] Added: {arcname}")

def main():
    print("Building clean ZIP Archive with UNIX '/' path separators...")
    
    # Target 1: Workspace root
    ws_zip = ROOT_DIR / "global_retail_data_modelling.zip"
    create_zip(ws_zip)
    print(f"\n[SUCCESS] Project ZIP created at workspace: {ws_zip}")
    
    # Target 2: Artifacts directory
    art_zip = ARTIFACT_DIR / "global_retail_data_modelling.zip"
    create_zip(art_zip)
    print(f"[SUCCESS] Project ZIP created at artifact dir: {art_zip}")

if __name__ == "__main__":
    main()
