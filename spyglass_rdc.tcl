# SpyGlass RDC TCL script for a moderately complex design

# 1. Project setup
set_project spyglass_rdc_proj

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

# 7. Define resets (update names and polarities as per your design)
define_reset -name rst_sys_n -active_low
define_reset -name rst_periph -active_high
define_reset -name rst_async_n -active_low
define_reset -name rst_dbg -active_high

# 8. RDC-specific options
set_option enable_rdc true
set_option rdc_auto_reset_grouping true
set_option rdc_report_waivers true
set_option rdc_enable_schematic true

# 9. Apply waivers if needed (example, update as required)
# add_waiver -rdc -rule RDC-100 -object "top.u_async_fifo" -comment "Known safe async reset crossing"

# 10. Run lint checks (recommended before RDC)
run_goal lint/lint_rtl

# 11. Run RDC analysis
run_goal rdc/rdc_rtl

# 12. Generate RDC reports
report_goal rdc/rdc_rtl -reportdir ./reports/rdc
report_goal rdc/rdc_rtl -type summary -reportdir ./reports/rdc
report_goal rdc/rdc_rtl -type waiver -reportdir ./reports/rdc
report_goal rdc/rdc_rtl -type schematic -reportdir ./reports/rdc

# 13. Optionally, generate lint reports
report_goal lint/lint_rtl -reportdir ./reports/lint

# 14. Exit SpyGlass
exit
