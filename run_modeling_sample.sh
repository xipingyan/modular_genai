#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_MODELING_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_MODELING_SAMPLES}"

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

OV_TOKENIZERS_LIB_PATH=${SCRIPT_DIR_RUN_MODELING_SAMPLES}/openvino.genai/build/src/cpp/src/modeling/samples/libopenvino_tokenizers.so
if [ ! -f ${OV_TOKENIZERS_LIB_PATH} ]; then
    echo "libopenvino_tokenizers.so not found in build dir, copying..."
    cp ${SCRIPT_DIR_RUN_MODELING_SAMPLES}/openvino.genai/build/openvino_genai/libopenvino_tokenizers.so ${OV_TOKENIZERS_LIB_PATH}
fi

cd "${SCRIPT_DIR_RUN_MODELING_SAMPLES}"
QWEN3_OMNI="${QWEN3_OMNI:-0}"

echo "Running GenAI samples with settings:"
echo "  QWEN3_OMNI=$QWEN3_OMNI"

# export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1         # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
# export OPENVINO_LOG_LEVEL=3   # Set OpenVINO log level.

# Run MD Omni Sample
if [[ "$QWEN3_OMNI" == "1" ]]; then
    # modeling_qwen3_omni
    # modeling_qwen3_omni_tts_min
    app=./openvino.genai/build/src/cpp/src/modeling/samples/modeling_qwen3_omni_tts_min
    model_path=./openvino.genai/tests/module_genai/cpp/test_models/Qwen3-Omni-4B-Instruct-multilingual/
    model_path=./openvino.genai/tests/module_genai/cpp/test_models/src_model_qwen3_omni_4b/Qwen3-Omni-4B-Instruct-multilingual/
    prompt="Describe this image and provide a speech response."
    output_audio="case2_output.wav"
    input_image=./openvino.genai/tests/module_genai/cpp/test_data/scene_120_100.png

    "$app" $model_path \
        2 \
        "$prompt" \
        "$output_audio" \
        "$input_image" \
        none \
        CPU \
        32 \
        fp32
fi
