#!/bin/bash
# VCS Simulate Only Script

set -e

echo "Running VCS simulation only..."
cd "$(dirname "$0")/.."

tclsh << 'EOF'
source vcs_flow.tcl
run_simulation
generate_reports
EOF

echo "VCS simulation completed successfully!"
