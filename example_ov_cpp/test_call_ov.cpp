// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <filesystem>
#include <chrono>
#include <openvino/runtime/core.hpp>
#include "openvino/runtime/intel_gpu/properties.hpp"

int test_call_ov_directly(int argc, char *argv[])
{
    std::cout << "== Test call OpenVINO directly ==" << std::endl;
    // z-image vae decoder model path
    std::string model_path = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/vae_decoder/openvino_model.xml";

    ov::Core core;
    auto model = core.read_model(model_path);
    auto compiled_model = core.compile_model(model, "GPU");
    auto infer_request = compiled_model.create_infer_request();

    // Create a dummy input tensor with the expected shape and type
    ov::Shape input_shape = {1, 16, 64, 64};
    ov::element::Type input_type = ov::element::f32;
    ov::Tensor input_tensor(input_type, input_shape);

    // Fill the input tensor with some data (e.g., random values)
    float* input_data = input_tensor.data<float>();
    for (size_t i = 0; i < input_tensor.get_size(); ++i) {
        input_data[i] = static_cast<float>(i) / input_tensor.get_size();
    }

    // Set the input tensor
    infer_request.set_input_tensor(input_tensor);

    for (size_t i = 0; i < 10; i++)
    {
        // Get GPU VRAM memory usage before inference (use string property key for compatibility)
        try {
            std::map<std::string, uint64_t> properties;
            properties = core.get_property("GPU", ov::intel_gpu::memory_statistics);
            std::cout << "  usm_device = " << properties["usm_device"] / 1024 / 1024 << " MB" << std::endl;
            std::cout << "  usm_host = " << properties["usm_host"] / 1024 / 1024 << " MB" << std::endl;
        } catch (const std::exception& e) {
            std::cout << "Could not query VRAM usage: " << e.what() << std::endl;
        }
        // Run inference
        auto t1 = std::chrono::high_resolution_clock::now();
        infer_request.infer();
        auto t2 = std::chrono::high_resolution_clock::now();
        std::cout << "Inference " << i << " time: " << std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count() << " ms" << std::endl;
    }

    // Get the output tensor
    ov::Tensor output_tensor = infer_request.get_output_tensor();
    std::cout << "Output tensor shape: " << output_tensor.get_shape() << std::endl;
    std::cout << "Output tensor element type: " << output_tensor.get_element_type() << std::endl;

    return EXIT_SUCCESS;
}