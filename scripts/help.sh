#!/bin/bash
# VCS Flow Help Information

echo ""
echo "Available targets:"
echo "  build_all_testbenches - Compile all C/C++ testbenches"
echo "  vcs_flow             - Run complete VCS flow (compile + simulate)"
echo "  vcs_compile_only     - VCS compilation only"
echo "  vcs_simulate_only    - VCS simulation only"
echo "  clean_vcs           - Clean VCS generated files"
echo "  clean_logs          - Clean all log files"
echo "  clean_generated     - Clean generated stimulus/config files"
echo "  clean_all           - Clean everything (build + VCS + logs + generated)"
echo "  clean               - Clean all build outputs"
echo ""
echo "Testbench executables will be in: $(dirname "$0")/../build/testbenches"
echo "VCS reports will be in: $(dirname "$0")/../sim/reports"
echo "Logs will be in: $(dirname "$0")/../logs/"
echo ""
