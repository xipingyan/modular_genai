#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_CP_CPP_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}"

if [[ ! -f "./python-env/bin/activate" ]]; then
    echo "[ERROR] Missing venv activate script: ./python-env/bin/activate" >&2
    exit 1
fi
if [[ ! -f "./source_mx_ov.sh" ]]; then
    echo "[ERROR] Missing OpenVINO env script: ./source_mx_ov.sh" >&2
    exit 1
fi

source ./python-env/bin/activate

# OpenVINO's setup scripts are not always compatible with `set -u` (nounset).
set +u
source ./source_mx_ov.sh
set -u

MX_REPOS_DIR="${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}/openvino.pipeline.mx"

if [[ -z "${OPENVINO_TOKENIZERS_PATH:-}" ]]; then
    TOKENIZERS_SO="${MX_REPOS_DIR}/build/openvino_genai/libopenvino_tokenizers.so"
    if [[ -f "$TOKENIZERS_SO" ]]; then
        export OPENVINO_TOKENIZERS_PATH="$TOKENIZERS_SO"
    fi
fi

cd "${MX_REPOS_DIR}"

export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
# export OPENVINO_LOG_LEVEL=3   # Set OpenVINO log level.
# export WARMUP=1               # Run one warmup iteration before measuring performance.

BUILD_TYPE=Release
BUILD_TYPE=Debug
app=./bin/intel64/${BUILD_TYPE}/yaml_pipeline_sample

# # MX API
# # ===========================================================
# # Qwen3-omni
# cfg_yaml=./samples/config_yaml/Qwen3_omni/config_image_cb.yaml
# $app "$cfg_yaml" "images=./tests/test_data/cars-1200-674.jpg" "prompts=describe the image"

# MX API：Gemma4 ov
# ===========================================================
cfg_yaml=./samples/config_yaml/Gemma4/config_image_audio_sdpa.yaml
# cfg_yaml=./samples/config_yaml/Gemma4/config_image_audio_cb.yaml

prompt_img="prompt_img=What is shown in this image? answer in one sentence."
$app "$cfg_yaml" "image=./tests/test_data/GoldenGate.png" "prompt=$prompt_img"

# prompt_audio="Transcribe the following speech segment."
# $app "$cfg_yaml" "audio=./tests/test_data/journal1.wav" "prompt=$prompt_audio"

# MX API：Gemma4 modeling
# ===========================================================
# ======= Text =========
# cfg_yaml=./samples/config_yaml/Gemma4/config_modeling_text_sdpa.yaml
# prompt='Write a short joke about saving RAM.'
# $app "$cfg_yaml" "prompt=$prompt"

# # ======= VLM =========
# cfg_yaml=./samples/config_yaml/Gemma4/config_modeling_image_sdpa.yaml
# prompt_img="What is shown in this image?"
# input_img='./tests/test_data/GoldenGate.png'
# $app "$cfg_yaml" "image=${input_img}" "prompt=$prompt_img"

# # ======= audio =========
# cfg_yaml=./samples/config_yaml/Gemma4/config_modeling_audio_sdpa.yaml
# prompt_audio="Transcribe the following speech segment."
# # prompt_audio='Transcribe the following speech segment in its original language. Follow these specific instructions for formatting the answer:\n* Only output the transcription, with no newlines.\n* When transcribing numbers, write the digits, i.e. write 1.7 and not one point seven, and write 3 instead of three.'
# input_audio='./tests/test_data/journal1.wav'
# $app "$cfg_yaml" "audio=${input_audio}" "prompt=$prompt_audio"

# # # ======= full =========
# input_img=./tests/test_data/GoldenGate.png
# input_audio=./tests/test_data/test.wav
# prompt_audio='transcribe the audio'
# prompt_img="describle this image"

# echo "=== SDPA ==="
# cfg_yaml=./samples/config_yaml/Gemma4/config_modeling_text_img_sdpa.yaml
# # $app "$cfg_yaml" "image=${input_img}" "prompt=$prompt_img"
# $app "$cfg_yaml" "audio=${input_audio}" "prompt=$prompt_audio"

# echo ""
# echo "=== CB ==="
# cfg_yaml=./samples/config_yaml/Gemma4/config_modeling_text_img_audio_cb.yaml
# $app "$cfg_yaml" "image=${input_img}" "prompt=$prompt_img"
# # $app "$cfg_yaml" "prompt=what is openvino?"

# # qwen2.5 tiny test
# cfg_yaml=./samples/config_yaml/Qwen2.5-VL-3B-Instruct/config_prompt_image_cb.yaml
# $app "$cfg_yaml" "image=./tests/test_data/dog_120_120.png" "prompt=describe the image"

# # MX API LLM
# cfg_yaml=./tests/data/tiny_models/tiny_llm_phi_2_with_yaml/config.yaml
# $app "$cfg_yaml" "prompt=Say hi, just respond with Hello."


# app_genai=./bin/intel64/Release/genai_compatible/cpp/genai_visual_language_chat
# # Shadow API tests
# # ================================================================================
# MODEL_DIR="../composable_pipeline/tests/test_models/qwen2.5-vl-3b-instruct/"
# IMAGE_FILE_OR_DIR="../openvino.mx/tests/test_data/cars-1200-674.jpg"
# PROMPT_LOOKUP="0"
# $app_genai "$MODEL_DIR" "$IMAGE_FILE_OR_DIR" "$DEVICE" "$PROMPT_LOOKUP"
