// Copyright (C) 2026 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "pipeline/facade/direct_facade.hpp"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

void print_usage(const char* program_name) {
    std::cerr << "Usage: " << program_name << " <pipeline.yaml> <input1> [input2] ...\n\n"
              << "Arguments:\n"
              << "  pipeline.yaml   Path to YAML pipeline configuration\n"
              << "  inputN          Input in format \"key=value\"\n\n"
              << "Examples:\n"
              << "  " << program_name << " config.yaml \"prompt=Hello, how are you?\"\n"
              << "  " << program_name << " config.yaml \"prompt=Describe this\" \"image=/path/to/img.jpg\"\n";
}

// Simple YAML parser to extract pipeline_params output names
std::vector<std::string> parse_pipeline_param_names(const std::string& yaml_path) {
    std::vector<std::string> param_names;
    std::ifstream file(yaml_path);
    if (!file.is_open()) {
        return param_names;
    }

    std::string line;
    bool in_pipeline_params = false;
    bool in_outputs = false;

    while (std::getline(file, line)) {
        // Trim leading spaces
        size_t start = line.find_first_not_of(" \t");
        if (start == std::string::npos) {
            continue;
        }
        std::string trimmed = line.substr(start);

        // Check if we're entering pipeline_params section
        if (trimmed.find("pipeline_params:") == 0) {
            in_pipeline_params = true;
            continue;
        }

        // Check if we're leaving pipeline_params (another module starts)
        if (in_pipeline_params && trimmed.find(":") != std::string::npos &&
            start < 2 && trimmed.find("type:") == std::string::npos &&
            trimmed.find("outputs:") == std::string::npos) {
            in_pipeline_params = false;
            in_outputs = false;
        }

        // Check if we're in outputs section
        if (in_pipeline_params && trimmed.find("outputs:") == 0) {
            in_outputs = true;
            continue;
        }

        // Extract parameter name
        if (in_outputs && trimmed.find("- name:") == 0) {
            size_t colon = trimmed.find(':');
            if (colon != std::string::npos) {
                std::string name = trimmed.substr(colon + 1);
                // Trim spaces and quotes
                start = name.find_first_not_of(" \t\"");
                if (start != std::string::npos) {
                    size_t end = name.find_first_of(" \t\"", start);
                    param_names.push_back(name.substr(start, end - start));
                }
            }
        }
    }

    return param_names;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        print_usage(argv[0]);
        return 1;
    }

    const std::string yaml_path = argv[1];

    // Validate YAML file exists
    if (!std::filesystem::exists(yaml_path)) {
        std::cerr << "Error: YAML file not found: " << yaml_path << "\n";
        return 1;
    }

    std::cout << "=== Simple Pipeline Example ===\n";
    std::cout << "YAML config: " << yaml_path << "\n";

    try {
        // Get all pipeline parameter names from YAML
        auto param_names = parse_pipeline_param_names(yaml_path);

        // Initialize all parameters to empty
        ov::AnyMap inputs;
        for (const auto& name : param_names) {
            inputs[name] = {};
        }

        // Parse command-line inputs (format: key=value)
        std::cout << "Inputs:\n";
        for (int i = 2; i < argc; ++i) {
            std::string arg = argv[i];
            auto eq_pos = arg.find('=');
            if (eq_pos != std::string::npos && eq_pos > 0) {
                std::string key = arg.substr(0, eq_pos);
                std::string value = arg.substr(eq_pos + 1);
                inputs[key] = value;
                std::cout << "  " << key << " = " << value << "\n";
            } else {
                std::cerr << "Warning: ignoring invalid argument (expected key=value): " << arg << "\n";
            }
        }
        std::cout << "\n";

        // Construct pipeline from YAML
        std::cout << "Constructing pipeline...\n";
        ov::pipeline::DirectFacade facade(yaml_path);
        std::cout << "Pipeline constructed successfully.\n\n";

        // Run inference
        std::cout << "Running inference...\n";
        facade.generate(inputs);

        // Get output
        std::cout << "\n--- Output ---\n";
        ov::AnyMap outputs = facade.get_outputs();

        for (const auto& [name, value] : outputs) {
            if (value.is<std::string>()) {
                std::cout << value.as<std::string>() << "\n";
            }
        }

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
