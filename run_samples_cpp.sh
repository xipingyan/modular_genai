#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_GENAI_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_GENAI_SAMPLES}"

if [[ ! -f "./python-env/bin/activate" ]]; then
    echo "[ERROR] Missing venv activate script: ./python-env/bin/activate" >&2
    exit 1
fi
if [[ ! -f "./source_ov.sh" ]]; then
    echo "[ERROR] Missing OpenVINO env script: ./source_ov.sh" >&2
    exit 1
fi

source ./python-env/bin/activate

# OpenVINO's setup scripts are not always compatible with `set -u` (nounset).
set +u
source ./source_ov.sh
set -u

cd "${SCRIPT_DIR_RUN_GENAI_SAMPLES}/openvino.genai"
RUN_VLM="${RUN_VLM:-0}"
RUN_GEN_IMG="${RUN_GEN_IMG:-0}"
RUN_GEN_VIDEO="${RUN_GEN_VIDEO:-0}"

echo "Running GenAI samples with settings:"
echo "  RUN_VLM=$RUN_VLM"
echo "  RUN_GEN_IMG=$RUN_GEN_IMG"
echo "  RUN_GEN_VIDEO=$RUN_GEN_VIDEO"

export OPENVINO_LOG_LEVEL=2

# Run MD Visual Language Chat Sample
if [[ "$RUN_VLM" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_visual_language_chat
    cfg=./samples/cpp/module_genai/config_yaml/Qwen2.5-VL-3B-Instruct/config.yaml
    prompt="Please describe the image"
    img=./tests/module_genai/cpp/test_data/cat_120_100.png

    "$app" -cfg "$cfg" -prompt "$prompt" -img "$img"
fi

# Run MD Image Generation Sample
if [[ "$RUN_GEN_IMG" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_image_generation
    cfg=./samples/cpp/module_genai/config_yaml/Z-Image-Turbo-fp16-ov/config.yaml
    cfg=./samples/cpp/module_genai/config_yaml/Z-Image-Turbo-fp16-ov/config_tiling.yaml
    prompt="A beautiful landscape painting by Claude Monet"

    "$app" -cfg "$cfg" -prompt "$prompt" --height 512 --width 512 --num_inference_steps 9 --guidance_scale 2.5 --max_sequence_length 512
fi

# Run MD Video Generation Sample
if [[ "$RUN_GEN_VIDEO" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_video_generation
    cfg=./samples/cpp/module_genai/config_yaml/Wan2.1-T2V-1.3B-Diffusers/config.yaml
    # cfg=./samples/cpp/module_genai/config_yaml/Wan2.1-T2V-1.3B-Diffusers/config_split_transformer.yaml
    prompt="A cat and a dog baking a cake together in a kitchen. The cat is carefully measuring flour, while the dog is stirring the batter with a wooden spoon. The kitchen is cozy, with sunlight streaming through the window."

    "$app" -cfg "$cfg" -prompt "$prompt" --height 128 --width 128 --num_frames 10 --num_inference_steps 9 --fps 5
fi