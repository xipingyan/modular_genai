// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <filesystem>
#include <chrono>
#include <openvino/runtime/core.hpp>
#include "openvino/runtime/intel_gpu/properties.hpp"
#include <thread>
#include <cstdlib>
#include "utils_test_model.hpp"

// Return GPU USM memory usage in MB, or -1 if could not query
inline int get_gpu_usm(ov::Core &core)
{
    try
    {
        std::map<std::string, uint64_t> properties;
        properties = core.get_property("GPU", ov::intel_gpu::memory_statistics);
        return properties["usm_device"] / 1024 / 1024;
        // return properties["usm_device"];
    }
    catch (const std::exception &e)
    {
        std::cout << "Could not query VRAM usage: " << e.what() << std::endl;
    }
    return -1;
}

ov::Tensor ov_infer(ov::CompiledModel &compiled_model, ov::Core &core, const std::vector<ov::Tensor>& inputs)
{
    auto infer_request = compiled_model.create_infer_request();

    auto remoteContext = compiled_model.get_context();

    // set input tensor
    for (size_t i = 0; i < inputs.size(); i++)
    {
        infer_request.set_input_tensor(inputs[i]);
    }

    for (size_t i = 0; i < 1; i++)
    {
        // Get GPU VRAM memory usage before inference (use string property key for compatibility)
        // std::cout << "  1 usm_device = " << get_gpu_usm(core) << " MB" << std::endl;

        // auto remoteTensor = remoteContext.create_tensor(ov::element::f32, {1, 16, 64 * 2, 64 * 2});
        // infer_request.set_input_tensor(remoteTensor);

        // std::cout << "  2 usm_device = " << get_gpu_usm(core) << " MB" << std::endl;

        // Run inference
        auto t1 = std::chrono::high_resolution_clock::now();
        infer_request.infer();
        auto t2 = std::chrono::high_resolution_clock::now();
        std::cout << "      Inference " << i << " time: " << std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count() << " ms" << std::endl;

        // std::cout << "  brefor remove: remoteTensor. " << std::endl;
        // std::this_thread::sleep_for(std::chrono::seconds(1));
        // remoteTensor = ov::RemoteTensor();
        // std::cout << "  After remove: remoteTensor. " << std::endl;
        // std::this_thread::sleep_for(std::chrono::seconds(1));

        // std::cout << "      3 usm_device = " << get_gpu_usm(core) << " MB" << std::endl;
    }

    // Get the output tensor
    ov::Tensor output_tensor = infer_request.get_output_tensor();
    std::cout << "Output tensor shape: " << output_tensor.get_shape() << std::endl;
    std::cout << "Output tensor element type: " << output_tensor.get_element_type() << std::endl;

    ov::Tensor output_clone = ov::Tensor(output_tensor.get_element_type(), output_tensor.get_shape());
    std::memcpy(output_clone.data<float>(), output_tensor.data<float>(), output_tensor.get_byte_size());
    return output_clone;
}

#ifndef PRINT_TM // Define PRINT_TM if not defined
#define PRINT_TM(T1, T2, MSG)                                                                                             \
    {                                                                                                                      \
        std::cout << "  " << MSG << ": " << std::chrono::duration_cast<std::chrono::milliseconds>(T2 - T1).count() << " ms" << std::endl; \
    }
#endif

inline bool compare_output(ov::Tensor &output_tensor, ov::Tensor &expected_tensor)
{
    // Verify output tensor value matches expected tensor
    int top = 5;
    int top_idx = 0;
    for (size_t d = 0; d < output_tensor.get_size(); d++)
    {
        if (fabs(output_tensor.data<float>()[d] - expected_tensor.data<float>()[d]) > 1.e-5)
        {
            std::cerr << "  [Fail] Output tensor value at index " << d << " does not match expected value!";
            if (top_idx < top)
            {
                std::cerr << "    output_tensor[" << d << "] = " << output_tensor.data<float>()[d]
                          << ", expected_tensor[" << d << "] = " << expected_tensor.data<float>()[d] << std::endl;
                top_idx++;
            }
            else
                return false;
        }
    }
    return true;
}

inline bool print_output(ov::Tensor &output_tensor)
{
    // Verify output tensor value matches expected tensor
    int top = 5;
    int top_idx = 0;
    for (size_t d = 0; d < output_tensor.get_size(); d++)
    {
        if (top_idx < top)
        {
            std::cout << "    output_tensor[" << d << "] = " << output_tensor.data<float>()[d] << std::endl;
            top_idx++;
        }
        else
            break;
    }
    return true;
}

int test_call_ov_directly(int argc, char *argv[])
{
    std::cout << "== Test call OpenVINO directly ==" << std::endl;
    ov::Core core;

    // TestModel::PTR test_model = TestModel::create(TestModelType::VAE_DECODER, core);
    TestModel::PTR test_model = TestModel::create(TestModelType::QWEN2_5_VL_TEXT_EMB_MODEL, core);

    ov::AnyMap cfg;
    // cff = {
    //     {ov::enable_weightless(true)},
    //     {ov::cache_dir("./my_cache_dir")}};
    // cfg[ov::enable_weightless.name()] = true;
    cfg[ov::cache_dir.name()] = std::string("./my_cache_dir");
    cfg[ov::weights_path.name()] = test_model->get_model_path_bin();

    auto model = test_model->get_model();
    auto compiled_model = core.compile_model(model, "GPU", cfg);
    ov::Tensor output_tensor;

    std::vector<ov::Tensor> inputs = test_model->get_input();
    std::vector<ov::Tensor> inputs_rt;
    for (const auto& input : inputs)
    {
        auto remoteContext = compiled_model.get_context();
        auto remoteTensor = remoteContext.create_tensor(input.get_element_type(), input.get_shape());
        remoteTensor.copy_from(input);
        inputs_rt.push_back(remoteTensor);
    }

    auto expected_tensor = ov_infer(compiled_model, core, inputs_rt);

#if ENABLE_MODEL_WEIGHTS_MANAGEMENT
    // std::cout << "      Before: release_model_weights = " << get_gpu_usm(core) << " MB" << std::endl;
    compiled_model.release_model_weights();
    // std::cout << "      After: release_model_weights = " << get_gpu_usm(core) << " MB" << std::endl;

    for (size_t i = 0; i < 4; i++)
    {
        std::cout << "===> " << i << std::endl;
        auto t1 = std::chrono::high_resolution_clock::now();
        compiled_model.load_model_weights();
        auto t2 = std::chrono::high_resolution_clock::now();
        PRINT_TM(t1, t2, "Load model weights time");
        std::this_thread::sleep_for(std::chrono::milliseconds(2000));

        output_tensor = ov_infer(compiled_model, core, inputs_rt);

        auto t3 = std::chrono::high_resolution_clock::now();
        compiled_model.release_model_weights();
        auto t4 = std::chrono::high_resolution_clock::now();
        PRINT_TM(t3, t4, "Release model weights time");
        std::this_thread::sleep_for(std::chrono::milliseconds(2000));

        print_output(output_tensor);
    }

    auto is_same = compare_output(output_tensor, expected_tensor);
    std::cout << "  **** Compare output with expected tensor: " << (is_same ? "[Pass]" : "[Fail]") << std::endl;
#else
    std::cout << "Model weights management is disabled. Skipping load_model_weights and release_model_weights calls." << std::endl;
#endif // ENABLE_MODEL_WEIGHTS_MANAGEMENT

    return EXIT_SUCCESS;
}