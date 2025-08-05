#!/bin/bash
# Comprehensive Cleanup Script for VCS Flow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "VCS Flow Cleanup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --all           Clean everything (build + VCS + logs + generated files)"
    echo "  --build         Clean CMake build directory only"
    echo "  --vcs           Clean VCS outputs only"
    echo "  --logs          Clean all log files only"
    echo "  --generated     Clean generated stimulus/config files only"
    echo "  --temp          Clean temporary files only"
    echo "  --dry-run       Show what would be cleaned without actually doing it"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --all              # Clean everything"
    echo "  $0 --logs --generated # Clean logs and generated files"
    echo "  $0 --dry-run --all    # Preview what would be cleaned"
}

# Dry run mode
DRY_RUN=false
CLEAN_BUILD=false
CLEAN_VCS=false
CLEAN_LOGS=false
CLEAN_GENERATED=false
CLEAN_TEMP=false

# Function to remove files/directories
cleanup_item() {
    local item="$1"
    local description="$2"
    
    if [[ -e "$item" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "Would remove: $item ($description)"
        else
            rm -rf "$item"
            print_success "Removed: $item ($description)"
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then
            print_info "Not found (OK): $item ($description)"
        fi
    fi
}

# Function to clean files matching a pattern
cleanup_pattern() {
    local pattern="$1"
    local description="$2"
    local base_dir="${3:-.}"
    
    if [[ "$DRY_RUN" == true ]]; then
        local found_files=$(find "$base_dir" -name "$pattern" 2>/dev/null || true)
        if [[ -n "$found_files" ]]; then
            print_info "Would remove files matching '$pattern' in $base_dir:"
            echo "$found_files" | while read -r file; do
                print_info "  - $file"
            done
        else
            print_info "No files matching '$pattern' found in $base_dir"
        fi
    else
        local count=$(find "$base_dir" -name "$pattern" -delete -print 2>/dev/null | wc -l || echo "0")
        if [[ "$count" -gt 0 ]]; then
            print_success "Removed $count files matching '$pattern' ($description)"
        fi
    fi
}

# Clean build artifacts
clean_build() {
    print_info "Cleaning build artifacts..."
    
    cleanup_item "build" "CMake build directory"
    cleanup_item "CMakeCache.txt" "CMake cache"
    cleanup_item "CMakeFiles" "CMake files directory"
    cleanup_item "cmake_install.cmake" "CMake install script"
    cleanup_item "CPackConfig.cmake" "CPack config"
    cleanup_item "CPackSourceConfig.cmake" "CPack source config"
    cleanup_item "install_manifest.txt" "Install manifest"
    cleanup_pattern "*.ninja" "Ninja build files"
    cleanup_pattern "build.ninja" "Ninja build file"
    cleanup_pattern "rules.ninja" "Ninja rules file"
}

# Clean VCS outputs
clean_vcs() {
    print_info "Cleaning VCS outputs..."
    
    # VCS simulation executables and databases
    cleanup_item "simv" "VCS simulation executable"
    cleanup_item "simv.daidir" "VCS simulation database"
    cleanup_item "csrc" "VCS C source directory"
    cleanup_item "ucli.key" "VCS license key"
    cleanup_item "vc_hdrs.h" "VCS headers"
    cleanup_item "64" "VCS 64-bit directory"
    cleanup_item "AN.DB" "VCS analysis database"
    cleanup_item ".vlogansetup.env" "VCS setup environment"
    cleanup_item ".vlogansetup.args" "VCS setup arguments"
    
    # VCS coverage and debug files
    cleanup_pattern "*.vpd" "VCS waveform files"
    cleanup_pattern "*.fsdb" "FSDB waveform files"
    cleanup_pattern "*.vcd" "VCD waveform files"
    cleanup_pattern "urgReport" "Coverage reports"
    cleanup_pattern "*.cov" "Coverage files"
    cleanup_pattern "novas.conf" "Novas configuration"
    cleanup_pattern "novas.rc" "Novas RC file"
    cleanup_pattern "nWaveLog" "nWave log directory"
    
    # Clean sim directory contents
    cleanup_item "sim/work" "VCS work directory"
    cleanup_item "sim/logs" "VCS log directory"
    cleanup_item "sim/reports" "VCS reports directory"
    
    # Recreate empty directories
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p sim/{work,logs,reports}
        print_success "Recreated empty sim directories"
    else
        print_info "Would recreate empty sim directories"
    fi
}

# Clean log files
clean_logs() {
    print_info "Cleaning log files..."
    
    # Testbench logs in new location
    cleanup_pattern "*.log" "Testbench log files" "logs/testbenches"
    cleanup_item "logs/testbenches" "Testbench logs directory"
    
    # VCS logs
    cleanup_pattern "*.log" "VCS log files" "logs/vcs"
    cleanup_pattern "*.log" "VCS simulation logs" "sim/logs"
    cleanup_pattern "vcs.log" "VCS compilation logs"
    cleanup_pattern "compile.log" "Compilation logs"
    cleanup_pattern "elaborate.log" "Elaboration logs"
    cleanup_pattern "simulate.log" "Simulation logs"
    
    # General logs
    cleanup_pattern "*.out" "Output files"
    cleanup_pattern "transcript" "Transcript files"
    cleanup_pattern "vsim.wlf" "ModelSim waveform files"
    
    # Recreate empty log directories
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p logs/testbenches logs/vcs sim/logs
        print_success "Recreated empty log directories"
    else
        print_info "Would recreate empty log directories"
    fi
}

# Clean generated files
clean_generated() {
    print_info "Cleaning generated files..."
    
    # Testbench generated files
    cleanup_pattern "stimulus_*.txt" "Stimulus files" "tb"
    cleanup_pattern "config_*.txt" "Configuration files" "tb"
    cleanup_pattern "test_*.txt" "Test files" "tb"
    cleanup_pattern "vectors_*.txt" "Test vector files" "tb"
    cleanup_pattern "expected_*.txt" "Expected result files" "tb"
    cleanup_pattern "actual_*.txt" "Actual result files" "tb"
    
    # VCS generated files
    cleanup_pattern "*.do" "Do files" "sim"
    cleanup_pattern "*.tcl" "Generated TCL scripts" "sim"
    cleanup_pattern "*.f" "File lists" "sim"
    
    # Temporary generated files
    cleanup_pattern "temp_*.txt" "Temporary files"
    cleanup_pattern "tmp_*.txt" "Temporary files"
}

# Clean temporary files
clean_temp() {
    print_info "Cleaning temporary files..."
    
    cleanup_pattern "*.tmp" "Temporary files"
    cleanup_pattern "*.temp" "Temporary files"
    cleanup_pattern ".*~" "Backup files"
    cleanup_pattern "*~" "Backup files"
    cleanup_pattern "*.swp" "Vim swap files"
    cleanup_pattern "*.swo" "Vim swap files"
    cleanup_pattern ".DS_Store" "macOS metadata files"
    cleanup_pattern "Thumbs.db" "Windows thumbnail files"
    cleanup_pattern "core" "Core dump files"
    cleanup_pattern "*.pid" "Process ID files"
    cleanup_pattern "*.lock" "Lock files"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CLEAN_BUILD=true
            CLEAN_VCS=true
            CLEAN_LOGS=true
            CLEAN_GENERATED=true
            CLEAN_TEMP=true
            shift
            ;;
        --build)
            CLEAN_BUILD=true
            shift
            ;;
        --vcs)
            CLEAN_VCS=true
            shift
            ;;
        --logs)
            CLEAN_LOGS=true
            shift
            ;;
        --generated)
            CLEAN_GENERATED=true
            shift
            ;;
        --temp)
            CLEAN_TEMP=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# If no specific options, default to help
if [[ "$CLEAN_BUILD" == false && "$CLEAN_VCS" == false && "$CLEAN_LOGS" == false && "$CLEAN_GENERATED" == false && "$CLEAN_TEMP" == false ]]; then
    show_usage
    exit 0
fi

# Confirmation for destructive operations
if [[ "$DRY_RUN" == false ]]; then
    echo ""
    print_warning "This will permanently delete files. Are you sure? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
    echo ""
fi

# Execute cleanup operations
echo "=== VCS Flow Cleanup Script ==="
if [[ "$DRY_RUN" == true ]]; then
    print_warning "DRY RUN MODE - No files will actually be deleted"
fi
echo ""

# Check if we're in the right directory
if [[ ! -f "CMakeLists.txt" ]] || [[ ! -f "vcs_flow.tcl" ]]; then
    print_error "Please run this script from the project root directory"
    print_error "Expected files: CMakeLists.txt, vcs_flow.tcl"
    exit 1
fi

# Execute selected cleanup operations
[[ "$CLEAN_BUILD" == true ]] && clean_build
[[ "$CLEAN_VCS" == true ]] && clean_vcs
[[ "$CLEAN_LOGS" == true ]] && clean_logs
[[ "$CLEAN_GENERATED" == true ]] && clean_generated
[[ "$CLEAN_TEMP" == true ]] && clean_temp

echo ""
if [[ "$DRY_RUN" == true ]]; then
    print_success "Dry run completed! Use without --dry-run to actually clean files."
else
    print_success "Cleanup completed successfully!"
fi
