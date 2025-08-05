/**
 * Example C++ Testbench for VCS Flow
 * This is a sample testbench that would interface with VCS simulation
 */

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstdlib>
#include <chrono>

class VCSTestbench {
private:
    std::string test_name;
    std::vector<std::string> test_vectors;
    std::ofstream log_file;

public:
    VCSTestbench(const std::string& name) : test_name(name) {
        log_file.open("logs/testbenches/" + test_name + "_cpp.log");
        if (!log_file.is_open()) {
            std::cerr << "Warning: Could not open log file for " << test_name << std::endl;
        }
    }

    ~VCSTestbench() {
        if (log_file.is_open()) {
            log_file.close();
        }
    }

    void log(const std::string& message) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        
        if (log_file.is_open()) {
            log_file << "[" << std::ctime(&time_t);
            log_file.seekp(-1, std::ios_base::cur); // Remove newline
            log_file << "] " << message << std::endl;
        }
        std::cout << "[" << test_name << "] " << message << std::endl;
    }

    void generate_stimulus() {
        log("Generating test stimulus...");
        
        // Generate some example test vectors
        for (int i = 0; i < 100; i++) {
            std::string vector = "vector_" + std::to_string(i) + "_data_" + 
                               std::to_string(rand() % 1000);
            test_vectors.push_back(vector);
        }
        
        log("Generated " + std::to_string(test_vectors.size()) + " test vectors");
    }

    void prepare_vcs_interface() {
        log("Preparing VCS interface files...");
        
        // Create stimulus file for VCS
        std::ofstream stimulus_file("tb/stimulus_" + test_name + ".txt");
        if (stimulus_file.is_open()) {
            for (const auto& vector : test_vectors) {
                stimulus_file << vector << std::endl;
            }
            stimulus_file.close();
            log("Stimulus file created: tb/stimulus_" + test_name + ".txt");
        }
        
        // Create configuration file
        std::ofstream config_file("tb/config_" + test_name + ".txt");
        if (config_file.is_open()) {
            config_file << "# Test configuration for " << test_name << std::endl;
            config_file << "test_duration=1000ns" << std::endl;
            config_file << "clock_period=10ns" << std::endl;
            config_file << "reset_duration=50ns" << std::endl;
            config_file << "stimulus_file=tb/stimulus_" + test_name + ".txt" << std::endl;
            config_file.close();
            log("Configuration file created: tb/config_" + test_name + ".txt");
        }
    }

    bool validate_setup() {
        log("Validating testbench setup...");
        
        // Check if RTL files exist
        std::vector<std::string> rtl_files = {
            "rtl/CPUtop.v",
            "rtl/SIMDadd.v", 
            "rtl/SIMDmultiply.v",
            "rtl/SIMDshifter.v"
        };
        
        bool all_found = true;
        for (const auto& file : rtl_files) {
            std::ifstream f(file);
            if (!f.good()) {
                log("ERROR: RTL file not found: " + file);
                all_found = false;
            } else {
                log("Found RTL file: " + file);
            }
        }
        
        return all_found;
    }

    int run() {
        log("Starting testbench execution...");
        
        if (!validate_setup()) {
            log("ERROR: Setup validation failed");
            return 1;
        }
        
        generate_stimulus();
        prepare_vcs_interface();
        
        log("Testbench preparation completed successfully");
        log("Ready for VCS simulation flow");
        
        return 0;
    }
};

int main(int argc, char* argv[]) {
    std::string test_name = "example_testbench";
    
    if (argc > 1) {
        test_name = argv[1];
    }
    
    std::cout << "=== C++ Testbench: " << test_name << " ===" << std::endl;
    
    VCSTestbench tb(test_name);
    int result = tb.run();
    
    if (result == 0) {
        std::cout << "Testbench completed successfully!" << std::endl;
    } else {
        std::cout << "Testbench failed with error code: " << result << std::endl;
    }
    
    return result;
}
