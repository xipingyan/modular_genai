#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_MX_TEST="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_MX_TEST}"

if [[ ! -f "./python-env/bin/activate" ]]; then
    echo "[ERROR] Missing venv activate script: ./python-env/bin/activate" >&2
    exit 1
fi
source ./python-env/bin/activate

PIPELINEMX_REPOS_DIR="${SCRIPT_DIR_RUN_MX_TEST}/openvino.pipeline.mx"
source ${PIPELINEMX_REPOS_DIR}/build/install/setupvars.sh


if [[ -z "${OPENVINO_TOKENIZERS_PATH:-}" ]]; then
    TOKENIZERS_SO="${PIPELINEMX_REPOS_DIR}/build/openvino_genai/libopenvino_tokenizers.so"
    if [[ -f "$TOKENIZERS_SO" ]]; then
        export OPENVINO_TOKENIZERS_PATH="$TOKENIZERS_SO"
    fi
fi

cd "${PIPELINEMX_REPOS_DIR}"

# export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
# export OPENVINO_LOG_LEVEL=3   # Set OpenVINO log level.
# export PIPELINE_OV_RELEASE_DIR=none  # Force MX path.

export MODEL_DIR=${PIPELINEMX_REPOS_DIR}/tests/test_models
export TINY_MODEL_DIR=${PIPELINEMX_REPOS_DIR}/tests/data/tiny_models
export DATA_DIR=${PIPELINEMX_REPOS_DIR}/tests/test_data

export BUILD_TYPE=Release
# export BUILD_TYPE=Debug

test_app=./bin/intel64/${BUILD_TYPE}/pipeline_tests

$test_app 
# --gtest_filter="GenAiOmniFacade.YamlPath_Generate*"

# unit test for GenAI Whisper pipeline.
# ==================================================
# $test_app --gtest_filter="*GenAiWhisperFacade*"