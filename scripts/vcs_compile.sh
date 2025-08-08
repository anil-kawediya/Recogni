#!/bin/bash
# VCS Compile Only Script

set -e

echo "Running VCS compilation only..."
cd "$(dirname "$0")/.."

tclsh << 'EOF'
source vcs_flow.tcl
create_directories
discover_files
if {[pre_simulation_checks]} {
    compile_design
} else {
    puts "Pre-simulation checks failed"
    exit 1
}
EOF

echo "VCS compilation completed successfully!"
