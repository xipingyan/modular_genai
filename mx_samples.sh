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

# qwen2.5 tiny test
cfg_yaml=./samples/config_yaml/Qwen2.5-VL-3B-Instruct/config_prompt_image_cb.yaml
$app "$cfg_yaml" "image=./tests/test_data/dog_120_120.png" "prompt=describe the image"

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
