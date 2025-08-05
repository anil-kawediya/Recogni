#!/bin/bash

# VCS Flow Build and Run Script
# Convenience script for CMake + VCS workflow

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Check for required tools
check_dependencies() {
    # Check for CMake
    if ! command -v cmake &> /dev/null; then
        print_error "CMake is required but not installed"
        exit 1
    fi
    
    # Check for Ninja (preferred) or Make
    if command -v ninja &> /dev/null; then
        BUILD_TOOL="ninja"
        BUILD_GENERATOR="Ninja"
        print_info "Using Ninja build system for faster builds"
    elif command -v make &> /dev/null; then
        BUILD_TOOL="make"
        BUILD_GENERATOR="Unix Makefiles"
        print_warning "Ninja not found, falling back to Make (slower)"
    else
        print_error "Neither Ninja nor Make found. Please install one of them."
        exit 1
    fi
    
    # Check for Tcl (required for VCS flow)
    if ! command -v tclsh &> /dev/null; then
        print_warning "tclsh not found - VCS flow may not work"
    fi
}

# Show usage
show_usage() {
    echo "VCS Flow Build Script (with Ninja support)"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup       - Initial setup (create build directory, configure CMake)"
    echo "  build       - Build all testbenches"
    echo "  vcs         - Run complete VCS flow (build + VCS compile + simulate)"
    echo "  compile     - VCS compile only"
    echo "  simulate    - VCS simulate only"
    echo "  clean       - Clean all build outputs"
    echo "  clean-vcs   - Clean VCS outputs only"
    echo "  clean-logs  - Clean all log files"
    echo "  clean-all   - Clean everything (build + VCS + logs + generated files)"
    echo "  help        - Show available CMake targets"
    echo "  deps        - Check dependencies"
    echo ""
    echo "Options:"
    echo "  --debug     - Use debug build configuration"
    echo "  --release   - Use release build configuration (default)"
    echo "  --verbose   - Verbose output"
    echo "  --jobs N    - Use N parallel jobs for building"
    echo "  --make      - Force use of Make instead of Ninja"
    echo ""
    echo "Examples:"
    echo "  $0 deps                    # Check dependencies"
    echo "  $0 setup --debug          # Setup with debug build"
    echo "  $0 build --jobs 8         # Build with 8 parallel jobs"
    echo "  $0 vcs                     # Run complete flow"
    echo "  $0 clean-logs             # Clean only log files"
    echo "  $0 clean-all              # Clean everything"
}

# Default values
BUILD_TYPE="Release"
VERBOSE=""
JOBS=""
BUILD_DIR="build"
BUILD_TOOL="ninja"  # Default to ninja
BUILD_GENERATOR="Ninja"
FORCE_MAKE=false

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        setup|build|vcs|compile|simulate|clean|clean-vcs|clean-logs|clean-all|help|deps)
            COMMAND="$1"
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --jobs)
            JOBS="-j$2"
            shift 2
            ;;
        --make)
            FORCE_MAKE=true
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

# Check if command was provided
if [[ -z "$COMMAND" ]]; then
    print_error "No command specified"
    show_usage
    exit 1
fi

# Check dependencies first
if [[ "$FORCE_MAKE" == true ]]; then
    BUILD_TOOL="make"
    BUILD_GENERATOR="Unix Makefiles"
    print_info "Forced to use Make build system"
elif [[ "$COMMAND" != "deps" ]]; then
    check_dependencies
fi

# Get project root directory (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# Check if we're in the project root
if [[ ! -f "CMakeLists.txt" ]] || [[ ! -f "vcs_flow.tcl" ]]; then
    print_error "Cannot find project root directory"
    print_error "Expected files: CMakeLists.txt, vcs_flow.tcl"
    print_error "Script directory: $SCRIPT_DIR"
    print_error "Project root: $PROJECT_ROOT"
    exit 1
fi

# Execute commands
case $COMMAND in
    deps)
        print_info "Checking dependencies..."
        check_dependencies
        
        # Check VCS
        if command -v vcs &> /dev/null; then
            VCS_VERSION=$(vcs -V 2>&1 | head -1)
            print_success "VCS found: $VCS_VERSION"
        else
            print_warning "VCS not found in PATH"
        fi
        
        print_success "Dependency check completed!"
        ;;
        
    setup)
        print_info "Setting up build environment..."
        print_info "Build type: $BUILD_TYPE"
        print_info "Build tool: $BUILD_TOOL"
        
        # Create build directory
        if [[ ! -d "$BUILD_DIR" ]]; then
            mkdir -p "$BUILD_DIR"
            print_success "Created build directory: $BUILD_DIR"
        else
            print_info "Build directory already exists: $BUILD_DIR"
        fi
        
        # Create log directories
        mkdir -p logs/testbenches logs/vcs
        mkdir -p sim/{reports,logs,work}
        
        # Configure CMake with appropriate generator
        cd "$BUILD_DIR"
        print_info "Configuring CMake with $BUILD_GENERATOR generator..."
        cmake -G "$BUILD_GENERATOR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" ..
        cd ..
        
        print_success "Setup completed successfully!"
        print_info "Use '$0 build' to compile testbenches"
        print_info "Use '$0 vcs' to run complete VCS flow"
        ;;
        
    build)
        print_info "Building all testbenches with $BUILD_TOOL..."
        
        if [[ ! -d "$BUILD_DIR" ]]; then
            print_error "Build directory not found. Run '$0 setup' first."
            exit 1
        fi
        
        cd "$BUILD_DIR"
        if [[ "$BUILD_TOOL" == "ninja" ]]; then
            ninja $JOBS build_all_testbenches
        else
            make $JOBS build_all_testbenches
        fi
        cd ..
        
        print_success "Testbenches built successfully!"
        print_info "Executables in: $BUILD_DIR/testbenches/"
        ;;
        
    vcs)
        print_info "Running complete VCS flow with $BUILD_TOOL..."
        
        if [[ ! -d "$BUILD_DIR" ]]; then
            print_error "Build directory not found. Run '$0 setup' first."
            exit 1
        fi
        
        cd "$BUILD_DIR"
        if [[ "$BUILD_TOOL" == "ninja" ]]; then
            ninja $JOBS vcs_flow
        else
            make $JOBS vcs_flow
        fi
        cd ..
        
        print_success "VCS flow completed!"
        print_info "Check sim/reports/ for results"
        ;;
        
    compile)
        print_info "Running VCS compilation only with $BUILD_TOOL..."
        
        if [[ ! -d "$BUILD_DIR" ]]; then
            print_error "Build directory not found. Run '$0 setup' first."
            exit 1
        fi
        
        cd "$BUILD_DIR"
        if [[ "$BUILD_TOOL" == "ninja" ]]; then
            ninja vcs_compile_only
        else
            make vcs_compile_only
        fi
        cd ..
        
        print_success "VCS compilation completed!"
        ;;
        
    simulate)
        print_info "Running VCS simulation only with $BUILD_TOOL..."
        
        if [[ ! -f "simv" ]]; then
            print_warning "VCS executable 'simv' not found. Consider running compile first."
        fi
        
        if [[ ! -d "$BUILD_DIR" ]]; then
            print_error "Build directory not found. Run '$0 setup' first."
            exit 1
        fi
        
        cd "$BUILD_DIR"
        if [[ "$BUILD_TOOL" == "ninja" ]]; then
            ninja vcs_simulate_only
        else
            make vcs_simulate_only
        fi
        cd ..
        
        print_success "VCS simulation completed!"
        ;;
        
    clean)
        print_info "Cleaning build outputs..."
        "$SCRIPT_DIR/cleanup.sh" --build
        print_success "Build outputs cleaned!"
        ;;
        
    clean-vcs)
        print_info "Cleaning VCS outputs only..."
        "$SCRIPT_DIR/cleanup.sh" --vcs
        print_success "VCS outputs cleaned!"
        ;;
        
    clean-logs)
        print_info "Cleaning log files only..."
        "$SCRIPT_DIR/cleanup.sh" --logs
        print_success "Log files cleaned!"
        ;;
        
    clean-all)
        print_info "Cleaning everything..."
        "$SCRIPT_DIR/cleanup.sh" --all
        print_success "Everything cleaned!"
        ;;
        
    help)
        print_info "Available targets:"
        
        if [[ -d "$BUILD_DIR" ]]; then
            cd "$BUILD_DIR"
            if [[ "$BUILD_TOOL" == "ninja" ]]; then
                ninja help_targets
            else
                make help_targets
            fi
            cd "$PROJECT_ROOT"
        else
            print_warning "Build directory not found. Run '$0 setup' first to see all targets."
        fi
        ;;
        
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

print_success "Command '$COMMAND' completed successfully!"
