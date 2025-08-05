#!/usr/bin/env python3

import glob
import sys

# Find all RTL files
rtl_files = glob.glob('**/*.rtl', recursive=True)

print(f"Checking {len(rtl_files)} RTL files for 'ANIL'...")

errors = []

for file in rtl_files:
    try:
        with open(file, 'r') as f:
            content = f.read()
            if 'ANIL' not in content:
                errors.append(file)
                print(f"ERROR: 'ANIL' not found in {file}")
            else:
                print(f"OK: 'ANIL' found in {file}")
    except Exception as e:
        errors.append(file)
        print(f"ERROR: Could not read {file}: {e}")

if errors:
    print(f"\nVALIDATION FAILED: {len(errors)} file(s) missing 'ANIL':")
    for error_file in errors:
        print(f"  - {error_file}")
    sys.exit(1)  # Exit with error code
else:
    print(f"\nAll RTL files contain 'ANIL' - validation passed!")
    sys.exit(0)  # Exit successfully