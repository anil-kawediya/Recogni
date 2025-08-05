#!/bin/tcl
#==============================================================================
# VCS Simulation Flow Script
# Author: Generated for moderate beginner level
# Description: Complete VCS flow with RTL, constraints, testbenches
#==============================================================================
#
#
# project/
#  ├── rtl/          # Place your RTL files here
#  ├── tb/           # Place your testbenches here  
#  ├── constraints/  # Place your timing constraints here
#  └── sim/
#     ├── reports/  # Generated reports
#     ├── logs/     # Compilation and simulation logs
#     └── work/     # VCS work directory
#
#

# Set script variables and paths
set SCRIPT_DIR [file dirname [info script]]
set PROJECT_ROOT [file normalize $SCRIPT_DIR/..]
set SIM_DIR $PROJECT_ROOT/sim
set RTL_DIR $PROJECT_ROOT/rtl
set TB_DIR $PROJECT_ROOT/tb
set CONSTRAINTS_DIR $PROJECT_ROOT/constraints
set REPORTS_DIR $SIM_DIR/reports
set LOGS_DIR $SIM_DIR/logs
set WORK_DIR $SIM_DIR/work

# Create directory structure
proc create_directories {} {
    global SIM_DIR RTL_DIR TB_DIR CONSTRAINTS_DIR REPORTS_DIR LOGS_DIR WORK_DIR
    
    puts "Creating directory structure..."
    foreach dir [list $SIM_DIR $RTL_DIR $TB_DIR $CONSTRAINTS_DIR $REPORTS_DIR $LOGS_DIR $WORK_DIR] {
        if {![file exists $dir]} {
            file mkdir $dir
            puts "  Created: $dir"
        }
    }
}

# File discovery and validation
proc discover_files {} {
    global RTL_DIR TB_DIR CONSTRAINTS_DIR
    global rtl_files tb_files constraint_files
    
    puts "\n=== File Discovery ==="
    
    # Find RTL files (.v, .sv, .vhd)
    set rtl_files {}
    foreach ext {*.v *.sv *.vhd} {
        set files [glob -nocomplain -directory $RTL_DIR $ext]
        set rtl_files [concat $rtl_files $files]
    }
    puts "Found [llength $rtl_files] RTL files:"
    foreach file $rtl_files {
        puts "  [file tail $file]"
    }
    
    # Find testbench files
    set tb_files {}
    foreach ext {*.v *.sv} {
        set files [glob -nocomplain -directory $TB_DIR $ext]
        set tb_files [concat $tb_files $files]
    }
    puts "Found [llength $tb_files] testbench files:"
    foreach file $tb_files {
        puts "  [file tail $file]"
    }
    
    # Find constraint files (.sdc, .xdc)
    set constraint_files {}
    foreach ext {*.sdc *.xdc} {
        set files [glob -nocomplain -directory $CONSTRAINTS_DIR $ext]
        set constraint_files [concat $constraint_files $files]
    }
    puts "Found [llength $constraint_files] constraint files:"
    foreach file $constraint_files {
        puts "  [file tail $file]"
    }
    
    # Validation
    if {[llength $rtl_files] == 0} {
        puts "WARNING: No RTL files found in $RTL_DIR"
    }
    if {[llength $tb_files] == 0} {
        puts "WARNING: No testbench files found in $TB_DIR"
    }
}

# Pre-simulation checks
proc pre_simulation_checks {} {
    global rtl_files tb_files
    
    puts "\n=== Pre-Simulation Checks ==="
    
    # Check file accessibility
    set missing_files {}
    foreach file [concat $rtl_files $tb_files] {
        if {![file readable $file]} {
            lappend missing_files $file
        }
    }
    
    if {[llength $missing_files] > 0} {
        puts "ERROR: Cannot read the following files:"
        foreach file $missing_files {
            puts "  $file"
        }
        return 0
    }
    
    # Check for common RTL issues (basic syntax check)
    puts "Performing basic syntax checks..."
    foreach file $rtl_files {
        if {[check_file_syntax $file] == 0} {
            puts "WARNING: Potential syntax issues in [file tail $file]"
        }
    }
    
    puts "Pre-simulation checks completed."
    return 1
}

# Basic syntax checker
proc check_file_syntax {filename} {
    set fp [open $filename r]
    set content [read $fp]
    close $fp
    
    # Basic checks for common issues
    set issues 0
    
    # Check for unmatched begin/end
    set begin_count [regexp -all {begin} $content]
    set end_count [regexp -all {end} $content]
    if {$begin_count != $end_count} {
        puts "  WARNING: Unmatched begin/end in [file tail $filename]"
        incr issues
    }
    
    # Check for missing semicolons (basic check)
    if {[regexp -all {\)\s*$} $content] > 0} {
        puts "  INFO: Possible missing semicolons in [file tail $filename]"
    }
    
    return [expr {$issues == 0}]
}

# VCS compilation
proc compile_design {} {
    global rtl_files tb_files constraint_files WORK_DIR LOGS_DIR
    
    puts "\n=== VCS Compilation ==="
    
    # Prepare VCS command
    set vcs_cmd "vcs"
    
    # Add compilation options
    lappend vcs_cmd "-sverilog"
    lappend vcs_cmd "-timescale=1ns/1ps"
    lappend vcs_cmd "-debug_access+all"
    lappend vcs_cmd "-lca"
    lappend vcs_cmd "-kdb"
    lappend vcs_cmd "+lint=TFIPC-L"
    lappend vcs_cmd "-full64"
    lappend vcs_cmd "-work $WORK_DIR"
    lappend vcs_cmd "-o simv"
    
    # Add files
    foreach file $rtl_files {
        lappend vcs_cmd $file
    }
    foreach file $tb_files {
        lappend vcs_cmd $file
    }
    
    # Add constraints if present
    if {[llength $constraint_files] > 0} {
        foreach file $constraint_files {
            lappend vcs_cmd "+define+CONSTRAINTS_FILE=\"$file\""
        }
    }
    
    # Execute compilation
    set log_file "$LOGS_DIR/compile.log"
    puts "Compiling with command:"
    puts "  [join $vcs_cmd " "]"
    puts "Log file: $log_file"
    
    if {[catch {exec {*}$vcs_cmd >& $log_file} result]} {
        puts "ERROR: Compilation failed. Check $log_file for details."
        return 0
    }
    
    puts "Compilation successful!"
    return 1
}

# Run simulation
proc run_simulation {} {
    global LOGS_DIR REPORTS_DIR
    
    puts "\n=== Running Simulation ==="
    
    if {![file exists "simv"]} {
        puts "ERROR: Compiled executable 'simv' not found!"
        return 0
    }
    
    # Prepare simulation command
    set sim_cmd "./simv"
    lappend sim_cmd "+vcs+finish+100000"
    lappend sim_cmd "-l $LOGS_DIR/simulation.log"
    
    # Add coverage options
    lappend sim_cmd "-cm line+cond+fsm+tgl+branch"
    lappend sim_cmd "-cm_dir $REPORTS_DIR/coverage.vdb"
    
    puts "Running simulation with command:"
    puts "  [join $sim_cmd " "]"
    
    if {[catch {exec {*}$sim_cmd} result]} {
        puts "Simulation completed with issues. Check logs for details."
    } else {
        puts "Simulation completed successfully!"
    }
    
    return 1
}

# Generate reports
proc generate_reports {} {
    global REPORTS_DIR LOGS_DIR
    
    puts "\n=== Generating Reports ==="
    
    # Coverage report
    if {[file exists "$REPORTS_DIR/coverage.vdb"]} {
        puts "Generating coverage report..."
        set cov_cmd "urg -dir $REPORTS_DIR/coverage.vdb -report $REPORTS_DIR/coverage_report"
        if {[catch {exec {*}$cov_cmd} result]} {
            puts "WARNING: Coverage report generation failed"
        } else {
            puts "Coverage report generated: $REPORTS_DIR/coverage_report"
        }
    }
    
    # Parse simulation log for errors/warnings
    parse_simulation_log
    
    # Generate summary report
    generate_summary_report
}

# Parse simulation log
proc parse_simulation_log {} {
    global LOGS_DIR REPORTS_DIR
    
    set log_file "$LOGS_DIR/simulation.log"
    if {![file exists $log_file]} {
        puts "WARNING: Simulation log not found"
        return
    }
    
    puts "Parsing simulation log..."
    set fp [open $log_file r]
    set content [read $fp]
    close $fp
    
    # Count errors and warnings
    set error_count [regexp -all -nocase {error} $content]
    set warning_count [regexp -all -nocase {warning} $content]
    
    # Write parsed report
    set report_file "$REPORTS_DIR/simulation_summary.txt"
    set fp [open $report_file w]
    puts $fp "=== Simulation Summary ==="
    puts $fp "Errors found: $error_count"
    puts $fp "Warnings found: $warning_count"
    puts $fp ""
    
    # Extract specific error/warning lines
    set lines [split $content "\n"]
    puts $fp "=== Error/Warning Details ==="
    foreach line $lines {
        if {[regexp -nocase {error|warning} $line]} {
            puts $fp $line
        }
    }
    close $fp
    
    puts "Simulation summary: $report_file"
}

# Generate comprehensive summary
proc generate_summary_report {} {
    global REPORTS_DIR rtl_files tb_files constraint_files
    
    set summary_file "$REPORTS_DIR/flow_summary.txt"
    set fp [open $summary_file w]
    
    puts $fp "=== VCS Flow Summary Report ==="
    puts $fp "Generated: [clock format [clock seconds]]"
    puts $fp ""
    puts $fp "=== File Statistics ==="
    puts $fp "RTL files processed: [llength $rtl_files]"
    puts $fp "Testbench files: [llength $tb_files]"
    puts $fp "Constraint files: [llength $constraint_files]"
    puts $fp ""
    
    # File sizes
    puts $fp "=== File Details ==="
    foreach file $rtl_files {
        set size [file size $file]
        puts $fp "RTL: [file tail $file] ($size bytes)"
    }
    foreach file $tb_files {
        set size [file size $file]
        puts $fp "TB:  [file tail $file] ($size bytes)"
    }
    
    puts $fp ""
    puts $fp "=== Output Files ==="
    if {[file exists "simv"]} {
        puts $fp "Executable: simv (size: [file size simv] bytes)"
    }
    if {[file exists "$REPORTS_DIR/coverage.vdb"]} {
        puts $fp "Coverage database: coverage.vdb"
    }
    
    close $fp
    puts "Flow summary report: $summary_file"
}

# Cleanup function
proc cleanup {} {
    puts "\n=== Cleanup ==="
    
    # Remove temporary files
    set temp_files [glob -nocomplain *.vpd *.fsdb ucli.key vc_hdrs.h]
    foreach file $temp_files {
        if {[file exists $file]} {
            file delete $file
            puts "Removed: $file"
        }
    }
    
    # Optional: clean work directory
    puts "Cleanup completed."
}

# Main execution flow
proc main {} {
    puts "=== VCS Simulation Flow Started ==="
    puts "Timestamp: [clock format [clock seconds]]"
    
    # Initialize
    create_directories
    discover_files
    
    # Pre-checks
    if {![pre_simulation_checks]} {
        puts "ERROR: Pre-simulation checks failed. Aborting."
        return 1
    }
    
    # Compilation
    if {![compile_design]} {
        puts "ERROR: Compilation failed. Aborting."
        return 1
    }
    
    # Simulation
    if {![run_simulation]} {
        puts "ERROR: Simulation failed."
        return 1
    }
    
    # Post-processing
    generate_reports
    
    puts "\n=== VCS Flow Completed Successfully ==="
    puts "Check the following directories for outputs:"
    puts "  Reports: $::REPORTS_DIR"
    puts "  Logs: $::LOGS_DIR"
    
    return 0
}

# Execute main flow if script is run directly
if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    set exit_code [main]
    
    # Optional cleanup
    if {[info exists env(VCS_CLEANUP)] && $env(VCS_CLEANUP) eq "1"} {
        cleanup
    }
    
    exit $exit_code
}