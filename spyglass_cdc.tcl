
# Project and environment setup
# RTL and library file inclusion
# Include directories
# Top module setting
# Multiple clock definitions and clock groups
# CDC-specific options and waivers
# Lint and CDC analysis
# Report generation (summary, detailed, waiver, and schematic)
# Exit

# 1. Project setup
set_project spyglass_cdc_proj

# 2. Add RTL source files
add_file -verilog ./src/top.v
add_file -verilog ./src/core.v
add_file -verilog ./src/peripheral.v
add_file -verilog ./src/arbiter.v
# ...add more RTL files as needed...

# 3. Add library files (uncomment and update as needed)
# add_file -library ./lib/tech.lib

# 4. Set include directories
set_option incdir "./include ./src/common"

# 5. Set the top module
set_option top top

# 6. Define clocks (update names and periods as per your design)
define_clock -name clk_sys -period 10
define_clock -name clk_periph -period 20
define_clock -name clk_async -period 33.33
define_clock -name clk_dbg -period 50

# 7. Define clock groups (for CDC analysis)
define_clock_group -name group_sys -clocks {clk_sys}
define_clock_group -name group_periph -clocks {clk_periph}
define_clock_group -name group_async -clocks {clk_async}
define_clock_group -name group_dbg -clocks {clk_dbg}

# 8. Set CDC-specific options
set_option enable_cdc true
set_option cdc_auto_clock_grouping true
set_option cdc_report_waivers true
set_option cdc_enable_schematic true

# 9. Apply waivers if needed (example, update as required)
# add_waiver -cdc -rule CDC-100 -object "top.u_async_fifo" -comment "Known safe async FIFO"

# 10. Run lint checks (recommended before CDC)
run_goal lint/lint_rtl

# 11. Run CDC analysis
run_goal cdc/cdc_rtl

# 12. Generate CDC reports
report_goal cdc/cdc_rtl -reportdir ./reports/cdc
report_goal cdc/cdc_rtl -type summary -reportdir ./reports/cdc
report_goal cdc/cdc_rtl -type waiver -reportdir ./reports/cdc
report_goal cdc/cdc_rtl -type schematic -reportdir ./reports/cdc

# 13. Optionally, generate lint reports
report_goal lint/lint_rtl -reportdir ./reports/lint

# 14. Exit SpyGlass
exit
