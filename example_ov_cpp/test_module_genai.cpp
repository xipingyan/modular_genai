// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <openvino/genai/module_genai/pipeline.hpp>
#include <filesystem>
#include <chrono>

static std::filesystem::path get_config_ymal_path(int argc, char *argv[])
{
    if (argc > 1)
    {
        return std::string(argv[1]);
    }
    return "config.yaml";
}

static bool print_subword(std::string &&subword)
{
    return !(std::cout << subword << std::flush);
}

int test_module_genai_pipeline_z_img(int argc, char *argv[])
{
    std::cout << "== Init ModulePipeline" << std::endl;
    std::filesystem::path config_path = get_config_ymal_path(argc, argv);
    std::cout << "  == config_fn: " << config_path << std::endl;
    ov::genai::module::ModulePipeline pipe(config_path);

    std::string prompt = "A beautiful landscape painting by Claude Monet";
    int width = 512;
    int height = 512;
    int num_inference_steps = 9;
    float guidance_scale = 2.0;
    int max_sequence_length = 512;

    ov::AnyMap inputs;
    inputs["prompt"] = prompt;
    inputs["width"] = width;
    inputs["height"] = height;
    inputs["num_inference_steps"] = num_inference_steps;
    inputs["guidance_scale"] = guidance_scale;
    inputs["max_sequence_length"] = max_sequence_length;

    for (int loop = 0; loop < 3; loop++)
    {
        std::cout << "== Loop: [" << loop << "] " << std::endl;
        pipe.generate(inputs);
    }

    ov::Tensor generated_image = pipe.get_output("generated_image").as<ov::Tensor>();

    std::string output_name = "./generated_image.bmp";
    std::cout << "Generated image shape: " << generated_image.get_shape() << ", output_name: " << output_name << std::endl;
    save_image_bmp("generated_image.bmp", generated_image);
    return EXIT_SUCCESS;
}

int test_genai_module_pipeline(int argc, char *argv[])
{
    std::cout << "== Init ModulePipeline" << std::endl;
    auto config_fn = get_config_ymal_path(argc, argv);
    std::cout << "  == config_fn: " << config_fn << std::endl;
    ov::genai::module::ModulePipeline pipe(config_fn);

    std::string prompt = "Please describle this image";
    std::string img_path = "./test_data/home.jpg";
    img_path = "../openvino.genai/tests/module_genai/cpp/test_data/cat_120_100.png";
    ov::Tensor image = utils::load_image(img_path);

    // std::cout << "question:\n";
    // std::getline(std::cin, prompt);
    for (int l = 0; l < 10; l++)
    {
        std::cout << "== Loop: [" << l << "] " << std::endl;
        std::cout << "Input image1_data first value: " << (int)image.data<uint8_t>()[0] << ", data type: " << image.get_element_type() << std::endl;
        // pipe.start_chat();

        ov::AnyMap inputs;
        inputs["prompts_data"] = prompt;
        inputs["image1_data"] = image;
        inputs["image2_data"] = image;

        auto t1 = std::chrono::high_resolution_clock::now();
        pipe.generate(inputs);
        // auto aa = pipe.generate(inputs, ov::genai::streamer(print_subword));
        auto t2 = std::chrono::high_resolution_clock::now();
        std::cout << "time =" << std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count() << " ms" << std::endl;

        // pipe.finish_chat();

        auto output_raw_data = pipe.get_output("raw_data").as<ov::Tensor>();
        // std::cout << "Output raw data first value: " << output_raw_data.data<float>()[0] << std::endl;
        std::cout << "output_raw_data shape: " << output_raw_data.get_shape() << std::endl;

        auto output_source_size = pipe.get_output("source_size").as<std::vector<int>>();
        std::cout << "output_source_size shape: [h=" << output_source_size[0] << ", w=" << output_source_size[1] << "]" << std::endl;
    }
    return EXIT_SUCCESS;
}