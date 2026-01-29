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

#define TEST_TRANSFORMER_MODEL 0

// Return GPU USM memory usage in MB, or -1 if could not query
inline int get_gpu_usm(ov::Core &core)
{
    try
    {
        std::map<std::string, uint64_t> properties;
        properties = core.get_property("GPU", ov::intel_gpu::memory_statistics);
        return properties["usm_device"] / 1024 / 1024;
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

#if TEST_TRANSFORMER_MODEL
    infer_request.set_tensor("hidden_states", inputs[0]);
    infer_request.set_tensor("encoder_hidden_states", inputs[1]);
    infer_request.set_tensor("timestep", inputs[2]);
#else
    // Set the input tensor
    infer_request.set_input_tensor(inputs[0]);
#endif

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

std::vector<ov::Tensor> load_input_tensors(ov::Core &core)
{
    std::vector<ov::Tensor> inputs;
#if TEST_TRANSFORMER_MODEL
    // hidden_states[1,16,16,16,16]
    ov::Shape input_shape = {1, 16, 16, 16, 16};
    ov::element::Type input_type = ov::element::f32;
    ov::Tensor input_tensor(input_type, input_shape);
    float *input_data = input_tensor.data<float>();
    for (size_t i = 0; i < input_tensor.get_size(); ++i)
    {
        input_data[i] = static_cast<float>(i) / input_tensor.get_size();
    }
    inputs.push_back(input_tensor);

    // encoder_hidden_states[1,101,2560]
    ov::Shape enc_shape = {1, 101, 2560};
    ov::element::Type enc_type = ov::element::f32;
    ov::Tensor enc_tensor(enc_type, enc_shape);
    float *enc_data = enc_tensor.data<float>();
    for (size_t i = 0; i < enc_tensor.get_size(); ++i)
    {
        enc_data[i] = static_cast<float>(i) / enc_tensor.get_size();
    }
    inputs.push_back(enc_tensor);

    // timestep[1]
    ov::Shape time_shape = {1};
    ov::element::Type time_type = ov::element::f32;
    ov::Tensor time_tensor(time_type, time_shape);
    float *time_data = time_tensor.data<float>();
    for (size_t i = 0; i < time_tensor.get_size(); ++i)
    {
        time_data[i] = static_cast<float>(i) / time_tensor.get_size();
    }
    inputs.push_back(time_tensor);
#else
    // Create a dummy input tensor with the expected shape and type
    ov::Shape input_shape = {1, 16, 64, 64};
    ov::element::Type input_type = ov::element::f32;
    ov::Tensor input_tensor(input_type, input_shape);

    // Fill the input tensor with some data (e.g., random values)
    float *input_data = input_tensor.data<float>();
    for (size_t i = 0; i < input_tensor.get_size(); ++i)
    {
        input_data[i] = static_cast<float>(i) / input_tensor.get_size();
    }
    inputs.push_back(input_tensor);
#endif
    return inputs;
}

int test_call_ov_directly(int argc, char *argv[])
{
    std::cout << "== Test call OpenVINO directly ==" << std::endl;
    // z-image vae decoder model path
    std::string model_path = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/vae_decoder/openvino_model.xml";
    std::string model_path_bin = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/vae_decoder/openvino_model.bin";

#if TEST_TRANSFORMER_MODEL
    model_path = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/transformer/openvino_model.xml";
#endif

    ov::AnyMap cfg;
    // cff = {
    //     {ov::enable_weightless(true)},
    //     {ov::cache_dir("./my_cache_dir")}};
    // cfg[ov::enable_weightless.name()] = true;
    cfg[ov::cache_dir.name()] = std::string("./my_cache_dir");
    cfg[ov::weights_path.name()] = model_path_bin;

    ov::Core core;
    auto model = core.read_model(model_path);

    auto t1 = std::chrono::high_resolution_clock::now();
    auto compiled_model = core.compile_model(model, "GPU", cfg);
    auto t2 = std::chrono::high_resolution_clock::now();
    PRINT_TM(t1, t2, "--> CompileModel time");
    ov::Tensor output_tensor, expected_tensor;

    std::vector<ov::Tensor> inputs = load_input_tensors(core);
    expected_tensor = ov_infer(compiled_model, core, inputs);

    for (size_t i = 0; i < 2; i++)
    {
        compiled_model.load_model_weights();
        output_tensor = ov_infer(compiled_model, core, inputs);
        compiled_model.release_model_weights();
        print_output(output_tensor);
    }

    auto is_same = compare_output(output_tensor, expected_tensor);
    std::cout << "  **** Compare output with expected tensor: " << (is_same ? "[Pass]" : "[Fail]") << std::endl;

    return EXIT_SUCCESS;
}