cmake_minimum_required(VERSION 3.16)
project(Recogni_VCS_Flow 
    LANGUAGES C CXX
    VERSION 1.0.0
    DESCRIPTION "VCS Flow with C/C++ Testbench Compilation"
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Project directories
set(PROJECT_ROOT ${CMAKE_SOURCE_DIR})
set(RTL_DIR ${PROJECT_ROOT}/rtl)
set(TB_DIR ${PROJECT_ROOT}/tb)
set(SCRIPTS_DIR ${PROJECT_ROOT}/scripts)
set(SIM_DIR ${PROJECT_ROOT}/sim)
set(BUILD_DIR ${PROJECT_ROOT}/build)
set(LOGS_DIR ${PROJECT_ROOT}/logs)

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")

# Create output directories
file(MAKE_DIRECTORY ${LOGS_DIR}/testbenches)
file(MAKE_DIRECTORY ${LOGS_DIR}/vcs)
file(MAKE_DIRECTORY ${SIM_DIR}/work)
file(MAKE_DIRECTORY ${SIM_DIR}/reports)

# Find testbench source files
file(GLOB_RECURSE C_TESTBENCHES "${TB_DIR}/*.c")
file(GLOB_RECURSE CXX_TESTBENCHES "${TB_DIR}/*.cpp")

# Build C testbenches
foreach(testbench_src ${C_TESTBENCHES})
    get_filename_component(testbench_name ${testbench_src} NAME_WE)
    add_executable(${testbench_name} ${testbench_src})
    set_target_properties(${testbench_name} 
        PROPERTIES 
        RUNTIME_OUTPUT_DIRECTORY ${BUILD_DIR}/testbenches
    )
    
    # Set compiler flags for this target
    target_compile_options(${testbench_name} PRIVATE -Wall -Wextra)
endforeach()

# Build C++ testbenches
foreach(testbench_src ${CXX_TESTBENCHES})
    get_filename_component(testbench_name ${testbench_src} NAME_WE)
    add_executable(${testbench_name} ${testbench_src})
    set_target_properties(${testbench_name} 
        PROPERTIES 
        RUNTIME_OUTPUT_DIRECTORY ${BUILD_DIR}/testbenches
    )
    
    # Set compiler flags for this target
    target_compile_options(${testbench_name} PRIVATE -Wall -Wextra)
endforeach()

# Create a target to build all testbenches
add_custom_target(build_all_testbenches
    DEPENDS ${C_TESTBENCHES} ${CXX_TESTBENCHES}
    COMMENT "Building all testbenches"
)

# VCS flow target
add_custom_target(vcs_flow
    COMMAND vcs -full64 -debug_access+all -kdb -lca -sverilog ${RTL_DIR}/*.v -o simv
    COMMAND ./simv | tee ${LOGS_DIR}/vcs/simulation.log
    WORKING_DIRECTORY ${PROJECT_ROOT}
    COMMENT "Running VCS flow on RTL"
    DEPENDS build_all_testbenches
)

# Clean VCS outputs
add_custom_target(clean_vcs
    COMMAND ${CMAKE_COMMAND} -E rm -rf simv simv.daidir csrc ucli.key vc_hdrs.h
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${SIM_DIR}/work ${SIM_DIR}/logs ${SIM_DIR}/reports
    COMMAND ${CMAKE_COMMAND} -E make_directory ${SIM_DIR}/work ${SIM_DIR}/logs ${SIM_DIR}/reports
    COMMAND ${CMAKE_COMMAND} -E echo "VCS outputs cleaned"
    WORKING_DIRECTORY ${PROJECT_ROOT}
    COMMENT "Cleaning VCS generated files"
)

# Clean logs only
add_custom_target(clean_logs
    COMMAND ${SCRIPTS_DIR}/cleanup.sh --logs
    WORKING_DIRECTORY ${PROJECT_ROOT}
    COMMENT "Cleaning all log files"
)

# Clean generated files only
add_custom_target(clean_generated
    COMMAND ${SCRIPTS_DIR}/cleanup.sh --generated
    WORKING_DIRECTORY ${PROJECT_ROOT}
    COMMENT "Cleaning generated stimulus and config files"
)

# Clean everything
add_custom_target(clean_all
    COMMAND ${SCRIPTS_DIR}/cleanup.sh --all
    WORKING_DIRECTORY ${PROJECT_ROOT}
    COMMENT "Cleaning everything (build + VCS + logs + generated)"
)

# Print build info
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Project root: ${PROJECT_ROOT}")
message(STATUS "Found C testbenches: ${C_TESTBENCHES}")
message(STATUS "Found C++ testbenches: ${CXX_TESTBENCHES}")
