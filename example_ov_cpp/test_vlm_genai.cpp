// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "load_image.hpp"
#include "my_utils.hpp"
#include <openvino/genai/visual_language/pipeline.hpp>
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

int test_genai_vlm_pipeline(int argc, char *argv[])
{
    std::cout << "== Init VLM Pipeline" << std::endl;
    std::string model_path = "/mnt/xiping/ai_nas/profiling_qwen2b_vl_instruction/models/ov/Qwen2.5-VL-3B-Instruct/INT4";
    std::cout << "  == model_path: " << model_path << std::endl;

    ov::AnyMap cfg;
    // cfg["ATTENTION_BACKEND"] = "SDPA";
    cfg["ATTENTION_BACKEND"] = "PA";

    ov::genai::VLMPipeline pipe(model_path, "GPU", cfg);
    std::string prompt = "Please describle this image";
    std::string img_path = "../openvino.genai/samples/cpp/module_genai/ut_test_data/cat_120_100.png";
    // prompt = "描述这张图像";
    ov::Tensor image = utils::load_image(img_path);

    ov::genai::GenerationConfig generation_config;
    generation_config.max_new_tokens = 16;
    generation_config.do_sample = false;
    generation_config.top_p = 1.0f;
    generation_config.top_k = 50;
    generation_config.temperature = 1.0f;
    generation_config.repetition_penalty = 1.0f;

    // std::cout << "question:\n";
    // std::getline(std::cin, prompt);
    for (int l = 0; l < 10; l++)
    {
        std::cout << "== Loop: [" << l << "] " << std::endl;
        std::cout << "Input image1_data first value: " << (int)image.data<uint8_t>()[0] << ", data type: " << image.get_element_type() << std::endl;
        // pipe.start_chat();

        auto t1 = std::chrono::high_resolution_clock::now();
        auto aa = pipe.generate(prompt, ov::genai::image(image), ov::genai::generation_config(generation_config));
        auto t2 = std::chrono::high_resolution_clock::now();

        // pipe.finish_chat();
        std::cout << "result: text =" << aa.texts[0].c_str() << ", score=" << aa.scores[0] << ", tm=" << std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count() << " ms" << std::endl;
        std::cout << aa.perf_metrics.get_ttft().mean << " ms (TTFT)" << std::endl;
        std::cout << aa.perf_metrics.get_tpot().mean << " ms (TPOT)" << std::endl;
    }
    return EXIT_SUCCESS;
}