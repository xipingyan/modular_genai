#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_MX_TEST="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_MX_TEST}"

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

CP_REPOS_DIR="${SCRIPT_DIR_RUN_MX_TEST}/openvino.mx"

if [[ -z "${OPENVINO_TOKENIZERS_PATH:-}" ]]; then
    TOKENIZERS_SO="${CP_REPOS_DIR}/build/openvino_genai/libopenvino_tokenizers.so"
    if [[ -f "$TOKENIZERS_SO" ]]; then
        export OPENVINO_TOKENIZERS_PATH="$TOKENIZERS_SO"
    fi
fi

cd "${CP_REPOS_DIR}"

# export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
# export OPENVINO_LOG_LEVEL=3     # Set OpenVINO log level.

export MODEL_DIR=${CP_REPOS_DIR}/tests/test_models
export TINY_MODEL_DIR=${CP_REPOS_DIR}/tests/data/tiny_models
export DATA_DIR=${CP_REPOS_DIR}/tests/test_data

# ./build/tests/composable_pipeline_tests --gtest_filter="*LLMEmbeddingFusionModuleIntegrationTest*"
# ./build/tests/composable_pipeline_tests 
# --gtest_filter="*ImagePreprocesModuleTest*"

./build/tests/composable_pipeline_tests --gtest_filter="*Component_GenAI_LLMPipeline*"
# ./build/tests/composable_pipeline_tests --gtest_filter="*Component_GenAI_VLMPipeline*"
# ./build/tests/composable_pipeline_tests --gtest_filter="*Component_GenAI_CBPipeline*"

# ./build/tests/composable_pipeline_tests --gtest_filter="Paths/Component_GenAI_VLMPipeline.Construction_And_Routing/UpstreamPath"
# "Paths/Component_GenAI_VLMPipeline.*"
