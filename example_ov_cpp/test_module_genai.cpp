// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <openvino/genai/module_genai/pipeline.hpp>
#include <filesystem>
#include <chrono>

static std::string get_config_ymal_path(int argc, char *argv[]) {
    if (argc > 1) {
        return std::string(argv[1]);
    }
    return "config.yaml";
}

static bool print_subword(std::string &&subword)
{
    return !(std::cout << subword << std::flush);
}

int test_genai_module_pipeline(int argc, char *argv[])
{
    std::cout << "== Init ModulePipeline" << std::endl;
    std::string config_fn = get_config_ymal_path(argc, argv);
    std::cout << "  == config_fn: " << config_fn << std::endl;
    ov::genai::module::ModulePipeline pipe(config_fn);

    std::string prompt = "Please describle this image";
    std::string img_path = "./test_data/home.jpg";
    img_path = "../openvino.genai/samples/cpp/module_genai/ut_test_data/cat_120_100.png";
    ov::Tensor image = utils::load_image("./test_data/home.jpg");

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