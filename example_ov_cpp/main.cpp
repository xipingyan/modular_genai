// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <openvino/genai/visual_language/pipeline.hpp>
#include <filesystem>
#include <chrono>

int main(int argc, char *argv[])
{
    try
    {
        test_genai_module_pipeline(argc, argv);
    }
    catch (const std::exception &error)
    {
        std::cerr << "Catch exceptions: " << error.what() << '\n';
    }
    return EXIT_SUCCESS;
}