#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_CP_CPP_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}"

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

# Load OpenVINO GenAI runtime (for extension ops like SpecialTokensSplit).
GENAI_INSTALL="${GENAI_INSTALL:-${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}/composable_pipeline/thirdparty/openvino.genai/build/install}"
if [[ -f "${GENAI_INSTALL}/setupvars.sh" ]]; then
    set +u
    # shellcheck disable=SC1090
    source "${GENAI_INSTALL}/setupvars.sh"
    set -u
elif [[ -d "${GENAI_INSTALL}/runtime/lib" ]]; then
    export LD_LIBRARY_PATH="${GENAI_INSTALL}/runtime/lib:${LD_LIBRARY_PATH:-}"
fi

if [[ -z "${OPENVINO_TOKENIZERS_PATH:-}" ]]; then
    TOKENIZERS_SO="${GENAI_INSTALL}/runtime/lib/intel64/libopenvino_tokenizers.so"
    if [[ -f "$TOKENIZERS_SO" ]]; then
        export OPENVINO_TOKENIZERS_PATH="$TOKENIZERS_SO"
    fi
fi

cd "${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}/composable_pipeline"

# export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
export OPENVINO_LOG_LEVEL=3     # Set OpenVINO log level.

export MODEL_DIR=${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}/composable_pipeline/tests/test_models
# export MODEL_DIR=${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}/openvino.genai/tests/module_genai/cpp/test_models

# ./build/tests/composable_pipeline_tests --gtest_filter="*LLMEmbeddingFusionModuleIntegrationTest*"
./build/tests/composable_pipeline_tests --gtest_filter="*LLMInferenceCBModuleIntegrationTest*"

# ./build/tests/composable_pipeline_tests --gtest_filter="*LLMInferenceModuleTest*"