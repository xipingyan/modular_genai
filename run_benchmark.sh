#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_PIPELINE_BENCHMARK="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_PIPELINE_BENCHMARK}/openvino.pipeline.mx"

${SCRIPT_DIR_PIPELINE_BENCHMARK}/source_mx_ov.sh
source ${SCRIPT_DIR_PIPELINE_BENCHMARK}/openvino.pipeline.mx/build/install/setupvars.sh

# export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
# export OPENVINO_LOG_LEVEL=3   # Set OpenVINO log level.

# ===========================================================
# Run benchmark: Qwen3-omni config with image input
config_yaml=./samples/config_yaml/Qwen3_omni/config_image_cb.yaml
# pipeline_benchmark $config_yaml "prompts=How many cars in the image?" "images=./tests/test_data/cars-1200-674.jpg" --warmup 1 --iter 2
pipeline_benchmark $config_yaml "prompts=How many images input?" "images=./tests/test_data/cars-1200-674.jpg,./tests/test_data/cat_120_100.png" --warmup 1 --iter 1

# config_yaml=./samples/config_yaml/Qwen3_omni/config_image_video_audio_cb.yaml
# pipeline_benchmark $config_yaml "prompts=Transcribe the input audio." "audios=./tests/test_data/thunder-and-rain-sounds.wav" --warmup 0 --iter 1


# # ===========================================================
# # Run benchmark: Qwen3-omni config with chat input
# config_yaml=./tests/data/tiny_models/tiny_llm_phi_2_chat_cb_with_yaml/config.yaml
# chat_json=./samples/cpp/benchmark/examples/simple_chat.json
# pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 1 --iter 2

# ===========================================================
# Run benchmark: Qwen3-omni config with chat input
config_yaml=./samples/config_yaml/Qwen3_omni/config_chat_cb.yaml
# chat_json=./samples/cpp/benchmark/examples/multimodal_chat.json
# pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1

chat_json=./samples/cpp/benchmark/examples/case1_comprehensive.json
echo "===> Running benchmark with conversation: ${chat_json}"
pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1 --max-frames 32

chat_json=./samples/cpp/benchmark/examples/case2_video_audio_focus.json
echo "===> Running benchmark with conversation: ${chat_json}"
pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1
chat_json=./samples/cpp/benchmark/examples/image_comparison.json
echo "===> Running benchmark with conversation: ${chat_json}"
pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1
chat_json=./samples/cpp/benchmark/examples/multi_images_ordering.json
echo "===> Running benchmark with conversation: ${chat_json}"
pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1

chat_json=./samples/cpp/benchmark/examples/text_only_baseline.json
echo "===> Running benchmark with conversation: ${chat_json}"
pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1
