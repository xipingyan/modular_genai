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

CP_REPOS_DIR="${SCRIPT_DIR_RUN_MX_TEST}/openvino.pipeline.mx"

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

# ./bin/intel64/Release/pipeline_tests --gtest_filter="*LLMEmbeddingFusionModuleIntegrationTest*"
# ./bin/intel64/Release/pipeline_tests 
# --gtest_filter="*ImagePreprocesModuleTest*"

# ./bin/intel64/Release/pipeline_tests --gtest_filter="*Component_GenAI_LLMPipeline*"
# ./bin/intel64/Release/pipeline_tests --gtest_filter="*Component_GenAI_VLMPipeline*"
# ./bin/intel64/Release/pipeline_tests --gtest_filter="*Component_GenAI_CBPipeline*"
# ./bin/intel64/Release/pipeline_tests --gtest_filter="*Component_GenAI_WhisperPipeline*"
./bin/intel64/Release/pipeline_tests --gtest_filter="ModuleTestSuite/ClipTextEncoderModuleTest.ModuleTest*"

# [  SKIPPED ] Qwen3VLVisionPreprocessFactory.FactoryReturnsNonNull
# [  SKIPPED ] Qwen3VLVisionPreprocessFactory.FactoryReturnsCorrectType
# [  SKIPPED ] Qwen3VLVisionPreprocess.PreprocessRejectsSimultaneousImagesAndVideos
# [  SKIPPED ] Qwen3VLVisionPreprocess.PreprocessSingleImage_ProducesPixelValues
# [  SKIPPED ] Qwen3VLImagePreprocessModule.ConstructionSucceeds
# [  SKIPPED ] Qwen3VLImagePreprocessModule.SingleImage_ProducesSourceSize
# [  SKIPPED ] Qwen3VLVisionEncoderConstruction.ModelTypeGateAcceptsQwen3VL
# [  SKIPPED ] Qwen3VLVisionEncoderConstruction.Qwen3VLVisionEncoderInitializesWithSafetensors
# [  SKIPPED ] Qwen3VLSDPABackendTest.SDPABackendInitializesForQwen3VL
# [  SKIPPED ] Qwen3VLSDPABackendTest.SDPABackendUsesInputIdsPath
# [  SKIPPED ] Qwen3VLSDPABackendTest.SDPABackendNameIsSDPA
# [  SKIPPED ] Qwen3VLConfigTest.FromJsonFile_RealModel
# [  SKIPPED ] Qwen3VLYamlPipeline.PipelineConstructsFromYaml
# [  SKIPPED ] Qwen3VLYamlPipeline.PipelineGeneratesOutput

# unit test for GenAI Whisper pipeline
# ==================================================
# ./bin/intel64/Release/pipeline_tests --gtest_filter="*GenAiWhisperFacade*"
# ./bin/intel64/Release/pipeline_tests --gtest_filter="*GenAiText2SpeechFacade*"

# ./bin/intel64/Release/pipeline_tests --gtest_filter="PipelineTest.ValidConfigFromFile"


# ./bin/intel64/Release/pipeline_tests --gtest_filter="Paths/Component_GenAI_VLMPipeline.Construction_And_Routing/UpstreamPath"
# "Paths/Component_GenAI_VLMPipeline.*"
