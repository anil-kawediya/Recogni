

# Clock definitions (system, fast, and slow clocks)
# Input/output delays with setup/hold times
# Clock uncertainty and jitter modeling
# False paths for asynchronous signals
# Multicycle paths for multi-cycle operations
# Clock domain crossing constraints
# Power optimization constraints
# DFT (Design for Test) constraints

#==============================================================================
# Standard Timing Constraints (SDC Format)
# Compatible with VCS, Synopsys Design Compiler, and other tools
#==============================================================================

#------------------------------------------------------------------------------
# Clock Definitions
#------------------------------------------------------------------------------

# Main system clock - 100MHz (10ns period)
create_clock -name sys_clk -period 10.0 [get_ports clk]

# High-speed clock - 200MHz (5ns period) 
create_clock -name fast_clk -period 5.0 [get_ports fast_clk]

# Slow peripheral clock - 50MHz (20ns period)
create_clock -name slow_clk -period 20.0 [get_ports slow_clk]

# Generated clock example - divide by 2 from main clock
create_generated_clock -name div2_clk -source [get_ports clk] -divide_by 2 [get_pins clk_div/Q]

# PLL output clock example
create_generated_clock -name pll_clk -source [get_ports ref_clk] -multiply_by 4 [get_pins pll_inst/clk_out]

#------------------------------------------------------------------------------
# Clock Groups and Relationships
#------------------------------------------------------------------------------

# Asynchronous clock groups (no timing relationship)
set_clock_groups -asynchronous -group [get_clocks sys_clk] -group [get_clocks fast_clk]

# Synchronous clock groups (related clocks)
set_clock_groups -physically_exclusive -group [get_clocks sys_clk] -group [get_clocks div2_clk]

# Logically exclusive clocks (mux-selected clocks)
set_clock_groups -logically_exclusive -group [get_clocks clk_mode0] -group [get_clocks clk_mode1]

#------------------------------------------------------------------------------
# Input Delays
#------------------------------------------------------------------------------

# Input delay constraints relative to sys_clk
set_input_delay -clock sys_clk -max 3.0 [get_ports data_in*]
set_input_delay -clock sys_clk -min 1.0 [get_ports data_in*]

# Setup and hold times for control signals
set_input_delay -clock sys_clk -max 2.5 [get_ports {enable reset_n}]
set_input_delay -clock sys_clk -min 0.5 [get_ports {enable reset_n}]

# DDR-style input (both edges)
set_input_delay -clock sys_clk -max 2.0 -clock_fall [get_ports ddr_data*]
set_input_delay -clock sys_clk -min 0.8 -clock_fall [get_ports ddr_data*]

# Input delay for different clock domains
set_input_delay -clock fast_clk -max 1.5 [get_ports high_speed_in*]
set_input_delay -clock fast_clk -min 0.3 [get_ports high_speed_in*]

#------------------------------------------------------------------------------
# Output Delays
#------------------------------------------------------------------------------

# Output delay constraints
set_output_delay -clock sys_clk -max 4.0 [get_ports data_out*]
set_output_delay -clock sys_clk -min 1.5 [get_ports data_out*]

# Control signal outputs
set_output_delay -clock sys_clk -max 3.5 [get_ports {valid ready ack}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {valid ready ack}]

# High-frequency outputs
set_output_delay -clock fast_clk -max 2.0 [get_ports fast_out*]
set_output_delay -clock fast_clk -min 0.5 [get_ports fast_out*]

#------------------------------------------------------------------------------
# Clock Uncertainty and Jitter
#------------------------------------------------------------------------------

# Clock uncertainty (accounts for jitter, skew, etc.)
set_clock_uncertainty -setup 0.2 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.1 [get_clocks sys_clk]

# Different uncertainty for high-speed clocks
set_clock_uncertainty -setup 0.3 [get_clocks fast_clk]
set_clock_uncertainty -hold 0.15 [get_clocks fast_clk]

# Inter-clock uncertainty for clock domain crossing
set_clock_uncertainty -from [get_clocks sys_clk] -to [get_clocks fast_clk] -setup 0.5
set_clock_uncertainty -from [get_clocks sys_clk] -to [get_clocks fast_clk] -hold 0.25

#------------------------------------------------------------------------------
# Clock Latency (for more accurate modeling)
#------------------------------------------------------------------------------

# Source latency (from clock source to clock definition point)
set_clock_latency -source -max 1.0 [get_clocks sys_clk]
set_clock_latency -source -min 0.8 [get_clocks sys_clk]

# Network latency (from clock definition to registers)
set_clock_latency -max 0.5 [get_clocks sys_clk]
set_clock_latency -min 0.3 [get_clocks sys_clk]

#------------------------------------------------------------------------------
# Maximum Transition and Capacitance
#------------------------------------------------------------------------------

# Transition time constraints
set_max_transition 1.0 [current_design]
set_max_transition 0.5 [get_clocks sys_clk]

# Capacitance constraints
set_max_capacitance 0.1 [all_outputs]
set_max_capacitance 0.05 [get_ports clk*]

#------------------------------------------------------------------------------
# False Paths
#------------------------------------------------------------------------------

# Asynchronous reset paths
set_false_path -from [get_ports reset_n]
set_false_path -from [get_ports async_reset*]

# Test mode signals
set_false_path -from [get_ports test_mode]
set_false_path -from [get_ports scan_enable]

# Configuration/debug signals
set_false_path -from [get_ports config*]
set_false_path -to [get_ports debug_out*]

# Static control signals (set once and don't change)
set_false_path -from [get_ports mode_select*]

#------------------------------------------------------------------------------
# Multicycle Paths
#------------------------------------------------------------------------------

# 2-cycle paths (operations that take 2 clock cycles)
set_multicycle_path -setup 2 -from [get_pins mult_reg*/CK] -to [get_pins result_reg*/D]
set_multicycle_path -hold 1 -from [get_pins mult_reg*/CK] -to [get_pins result_reg*/D]

# Slow interface - 4 cycles for setup
set_multicycle_path -setup 4 -to [get_ports slow_interface*]
set_multicycle_path -hold 3 -to [get_ports slow_interface*]

#------------------------------------------------------------------------------
# Case Analysis (for mux-based clock selection)
#------------------------------------------------------------------------------

# Clock selection mux analysis
set_case_analysis 0 [get_ports clk_select[0]]
set_case_analysis 1 [get_ports clk_select[1]]

# Mode-dependent analysis
set_case_analysis 0 [get_ports test_mode]

#------------------------------------------------------------------------------
# Load and Drive Strength
#------------------------------------------------------------------------------

# Input drive strength (models external driver capability)
set_driving_cell -lib_cell BUFX4 -pin Y [get_ports data_in*]
set_driving_cell -lib_cell BUFX2 -pin Y [get_ports control_in*]

# Output loads (models external load)
set_load -pin_load 0.02 [get_ports data_out*]
set_load -pin_load 0.01 [get_ports status_out*]

#------------------------------------------------------------------------------
# Clock Gating Constraints
#------------------------------------------------------------------------------

# Clock gating setup/hold requirements
set_clock_gating_check -setup 0.2 [get_cells *gated_clk*]
set_clock_gating_check -hold 0.1 [get_cells *gated_clk*]

#------------------------------------------------------------------------------
# Power Optimization Constraints
#------------------------------------------------------------------------------

# Clock gating enable
set_clock_gating_style -sequential_cell latch -positive_edge_logic {and,or}

# Multi-threshold voltage constraints
set_threshold_voltage_group -name HVT [get_cells *memory*]
set_threshold_voltage_group -name LVT [get_cells *critical_path*]

#------------------------------------------------------------------------------
# DFT (Design for Test) Constraints
#------------------------------------------------------------------------------

# Scan chain constraints
set_dft_signal -view existing_dft -type ScanClock -timing {50 100} -port scan_clk
set_dft_signal -view existing_dft -type ScanEnable -active_state 1 -port scan_enable
set_dft_signal -view existing_dft -type Reset -active_state 0 -port scan_reset_n

#------------------------------------------------------------------------------
# Custom Constraints for Specific Paths
#------------------------------------------------------------------------------

# Critical path timing exception
set_max_delay 8.0 -from [get_pins critical_logic/data_reg*/CK] -to [get_pins output_reg*/D]
set_min_delay 2.0 -from [get_pins critical_logic/data_reg*/CK] -to [get_pins output_reg*/D]

# Bus turnaround time
set_max_delay 15.0 -from [get_ports bus_req] -to [get_ports bus_grant]

# Synchronizer constraints (for CDC)
set_max_delay 10.0 -datapath_only -from [get_cells sync_ff1_reg] -to [get_cells sync_ff2_reg]

#------------------------------------------------------------------------------
# Environment Constraints
#------------------------------------------------------------------------------

# Operating conditions
set_operating_conditions -max slow_1p0v_125c -min fast_1p2v_m40c

# Wire load models
set_wire_load_model -name ForQA [current_design]
set_wire_load_mode top

#------------------------------------------------------------------------------
# Timing Exceptions Summary
#------------------------------------------------------------------------------

# Report all timing exceptions for verification
# These commands are for verification only - comment out for actual synthesis

# report_clock -skew
# report_timing -max_paths 10 -nworst 2
# report_exceptions -all
# check_timing
# report_constraint -all_violators