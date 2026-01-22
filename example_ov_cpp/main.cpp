// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <filesystem>
#include <chrono>

#include <openvino/genai/module_genai/pipeline.hpp>

void test_list_config() {
    auto all_modules = ov::genai::module::ListAllModules();
    ov::genai::module::PrintModuleConfig(all_modules[0]);

    std::cout << "*** Start to print all modules' config. ***" << std::endl;
    ov::genai::module::PrintAllModulesConfig();
}

int main(int argc, char *argv[])
{
    // test_genai_module_pipeline(argc, argv);
    // test_genai_vlm_pipeline(argc, argv);
    // test_list_config();
    test_call_ov_directly(argc, argv);
    return EXIT_SUCCESS;
}