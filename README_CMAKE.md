# VCS Flow with CMake Build System

This project provides a CMake-based build system that compiles C/C++ testbenches and runs VCS simulation flow on RTL designs.

## Project Structure

```
Recogni/
├── CMakeLists.txt          # Main CMake configuration
├── vcs_flow.tcl           # VCS simulation flow script
├── build.sh               # Convenience build script
├── clean.sh               # Convenience cleanup script
├── scripts/               # All build and utility scripts
│   ├── build_vcs.sh       # Main build script
│   ├── cleanup.sh         # Comprehensive cleanup script
│   ├── vcs_compile.sh     # VCS compilation script
│   ├── vcs_simulate.sh    # VCS simulation script
│   └── help.sh           # Help information
├── rtl/                   # RTL source files (.v, .sv, .vhd)
│   ├── CPUtop.v
│   ├── SIMDadd.v
│   ├── SIMDmultiply.v
│   ├── SIMDshifter.v
│   └── processor_tb.v
├── tb/                    # C/C++ testbench sources
│   ├── example_testbench.cpp
│   └── processor_testbench.c
├── logs/                  # All log files (output)
│   ├── testbenches/      # Testbench execution logs
│   └── vcs/              # VCS compilation and simulation logs
├── sim/                   # VCS simulation outputs
│   ├── reports/          # Generated reports
│   ├── logs/            # VCS runtime logs
│   └── work/            # VCS work directory
└── build/                 # CMake build directory
    └── testbenches/       # Compiled testbench executables
```

## Prerequisites

- CMake 3.16 or later
- **Ninja build system** (recommended for speed) or Make
- GCC/Clang C/C++ compiler
- Synopsys VCS (for simulation)
- Tcl/Tk (for running VCS flow script)

### Installing Ninja (Recommended)

Ninja is significantly faster than Make for builds. To install:

# macOS with Homebrew:  brew install ninja
# Ubuntu/Debian: 	sudo apt-get install ninja-build
# CentOS/RHEL:  	sudo yum install ninja-build
# Fedora: 		sudo dnf install ninja-build
# Check if installed: 	ninja --version

## Quick Start

### 1. Check Dependencies
./build.sh deps

### 2. Create Build Directory
./build.sh setup

For debug build:
./build.sh setup --debug

### 3. Build All Testbenches (Fast with Ninja!)
./build.sh build

### 4. Run Complete VCS Flow
./build.sh vcs

## Available Build Targets

| Target                  | Description |
|-------------------------|-------------|
| `build_all_testbenches` | Compile all C/C++ testbenches in tb/ directory |
| `vcs_flow`              | Run complete VCS flow (compile + simulate) |
| `vcs_compile_only`      | VCS compilation only (no simulation) |
| `vcs_simulate_only`     | VCS simulation only (assumes already compiled) |
| `clean_vcs`             | Clean VCS generated files |
| `clean_logs`            | Clean all log files |
| `clean_generated`       | Clean generated stimulus/config files |
| `clean_all`             | Clean everything (build + VCS + logs + generated) |
| `help_targets`          | Display all available targets |

### Running Individual Targets

**Using the build script (recommended):**
# Check dependencies and build tools
./build.sh deps

# Build testbenches only (fast with Ninja!)
./build.sh build --jobs 8

# Compile RTL only (no simulation)
./build.sh compile

# Run simulation only (assumes RTL already compiled)
./build.sh simulate

# Cleanup commands
./build.sh clean-logs      # Clean only log files
./build.sh clean-vcs       # Clean only VCS outputs
./build.sh clean-all       # Clean everything

# Show help
./build.sh help

**Direct cleanup script usage:**
# Interactive cleanup with confirmation
./clean.sh --all             # Clean everything
./clean.sh --logs            # Clean only logs
./clean.sh --generated       # Clean only generated files
./clean.sh --vcs             # Clean only VCS outputs
./clean.sh --build           # Clean only build artifacts
./clean.sh --temp            # Clean only temporary files

# Preview what would be cleaned (safe)
./clean.sh --dry-run --all   # See what would be cleaned
./clean.sh --dry-run --logs  # Preview log cleanup

# Combine options
./clean.sh --logs --generated --temp  # Clean multiple categories

**Manual CMake/Ninja commands:**
cd build
ninja build_all_testbenches  # Fast!
ninja vcs_flow               # Complete flow
ninja vcs_compile_only       # VCS compile only
ninja vcs_simulate_only      # VCS simulate only
ninja clean_vcs             # Clean VCS outputs

**If using Make (slower):**
cd build
make build_all_testbenches  # Slower than Ninja
make vcs_flow               # Complete flow

## Testbench Development

### C/C++ Testbench Guidelines

1. **File Location**: Place all C/C++ testbench files in the `tb/` directory
2. **Supported Extensions**: `.c`, `.cpp`, `.cc`, `.cxx`
3. **Headers**: Place header files in `tb/` directory or subdirectories
4. **Naming**: Each source file creates an executable with the same base name

### Example Testbench Structure
// tb/my_testbench.cpp
#include <iostream>

int main() {
    // Your testbench logic
    std::cout << "Testbench running..." << std::endl;
    
    // Generate stimulus files for VCS
    // Validate RTL setup
    // Prepare simulation inputs
    
    return 0; // Success
}

### Testbench Integration with VCS

The testbenches should:
1. Generate stimulus files in `tb/` directory
2. Create configuration files for VCS
3. Validate RTL file availability
4. Log execution details

Example stimulus file creation:
std::ofstream stimulus("tb/stimulus_my_test.txt");
stimulus << "// Test vectors\n";
stimulus << "vector_data_0x1234\n";
stimulus.close();

## VCS Flow Integration

The CMake system integrates with the existing `vcs_flow.tcl` script:

1. **Dependencies**: VCS flow waits for testbench compilation
2. **Working Directory**: VCS runs from project root
3. **File Discovery**: Automatic discovery of RTL and testbench files
4. **Reporting**: Generated reports in `sim/reports/`

## Configuration Options

### Build Types
- **Debug**: `-g -O0 -DDEBUG`
- **Release**: `-O3 -DNDEBUG`

### Compiler Flags
- C standard: C11
- C++ standard: C++17
- Warnings: `-Wall -Wextra`

### Environment Variables

Set these environment variables to customize behavior:
# Enable VCS cleanup after simulation
export VCS_CLEANUP=1
# Set custom build type
export CMAKE_BUILD_TYPE=Debug
# Force use of specific build tool
export CMAKE_GENERATOR=Ninja        # Use Ninja (default if available)
export CMAKE_GENERATOR="Unix Makefiles"  # Force Make

## Cleanup Management

The project includes comprehensive cleanup functionality to manage all generated files, logs, and build artifacts.

### Cleanup Categories

| Category | Files Cleaned | Command |
|----------|---------------|---------|
| **Build** | CMake build directory, ninja files, binaries | `./clean.sh --build` |
| **VCS** | simv, simv.daidir, *.vpd, *.fsdb, coverage data | `./clean.sh --vcs` |
| **Logs** | All *.log files, testbench logs, VCS logs | `./clean.sh --logs` |
| **Generated** | stimulus_*.txt, config_*.txt, test vectors | `./clean.sh --generated` |
| **Temporary** | *.tmp, *~, *.swp, .DS_Store, core dumps | `./clean.sh --temp` |
| **Everything** | All of the above | `./clean.sh --all` |

### Safe Cleanup Workflow
# 1. Preview what will be cleaned (safe)
./clean.sh --dry-run --all

# 2. Clean specific categories as needed
./clean.sh --logs --generated    # Clean logs and generated files
./clean.sh --vcs                 # Clean VCS outputs only

# 3. Complete cleanup when needed
./clean.sh --all                 # Clean everything

### Integration with Build System

# Build script includes cleanup shortcuts
./build.sh clean-logs          # Quick log cleanup
./build.sh clean-vcs           # Quick VCS cleanup  
./build.sh clean-all           # Complete cleanup

# CMake targets for cleanup
ninja clean_logs                   # From build directory
ninja clean_vcs
ninja clean_all
```

## Performance Comparison

**Build Speed Comparison:**
- **Ninja**: ~2-5x faster than Make for parallel builds
- **Make**: Traditional but slower for larger projects

**Recommended Usage:**
# Fastest - Ninja with parallel jobs
./build.sh build --jobs $(nproc)

# Force Make if needed
./build.sh setup --make
./build.sh build

## Troubleshooting

### Common Issues

1. **No testbenches found**
   - Ensure C/C++ files are in `tb/` directory
   - Check file extensions are supported

2. **VCS compilation fails**
   - Verify VCS is in PATH
   - Check RTL file syntax
   - Review `sim/logs/compile.log`

3. **Testbench compilation errors**
   - Check C/C++ syntax
   - Verify header file paths
   - Review compiler output

### Debug Commands

# Verbose CMake output
cmake --build . --verbose

# Check discovered files
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON

# Manual testbench execution
./build/testbenches/example_testbench

# Manual VCS flow
tclsh vcs_flow.tcl

## Advanced Usage

### Custom Testbench Arguments

# Run specific testbench with arguments
./build/testbenches/processor_testbench custom_test_name

### Parallel Builds

# Use multiple cores for compilation
make -j4 build_all_testbenches

### Installation
# Install binaries and scripts
make install

## Output Files

After successful execution:

- **Testbench executables**: `build/testbenches/`
- **VCS simulation executable**: `simv` (in project root)
- **VCS reports**: `sim/reports/`
- **Simulation logs**: `sim/logs/`
- **Coverage database**: `sim/reports/coverage.vdb`

## Contributing

When adding new testbenches:
1. Place source files in `tb/` directory
2. Follow naming conventions
3. Include proper error handling
4. Generate appropriate stimulus files
5. Test with both Debug and Release builds
