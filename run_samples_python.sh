#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_GENAI_PY_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_GENAI_PY_SAMPLES}"

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

GENAI_ROOT_DIR=${SCRIPT_DIR_RUN_GENAI_PY_SAMPLES}/openvino.genai/install/python/
OV_PYTHON_DIR=${INTEL_OPENVINO_DIR}/python
export PYTHONPATH=${OV_PYTHON_DIR}:${GENAI_ROOT_DIR}:$PYTHONPATH
export LD_LIBRARY_PATH=${GENAI_ROOT_DIR}/../runtime/lib/intel64/:$LD_LIBRARY_PATH
export OV_TOKENIZER_PREBUILD_EXTENSION_PATH=${GENAI_ROOT_DIR}/../runtime/lib/intel64/libopenvino_tokenizers.so

cd "${SCRIPT_DIR_RUN_GENAI_PY_SAMPLES}/openvino.genai"
RUN_VLM="${RUN_VLM:-0}"
RUN_GEN_IMG="${RUN_GEN_IMG:-0}"

echo "Running GenAI samples with settings:"
echo "  RUN_VLM=$RUN_VLM"
echo "  RUN_GEN_IMG=$RUN_GEN_IMG"

# Run MD Visual Language Chat Sample
if [[ "$RUN_VLM" == "1" ]]; then
    app=./samples/python/module_genai/md_visual_language_chat.py
    cfg=./samples/cpp/module_genai/config_yaml/Qwen2.5-VL-3B-Instruct/config.yaml
    prompt="Please describe the image"
    img=./tests/module_genai/cpp/test_data/cat_120_100.png

    python "$app" --cfg "$cfg" --prompt "$prompt" --img "$img"
fi

# Run MD Image Generation Sample
if [[ "$RUN_GEN_IMG" == "1" ]]; then
    app=./samples/python/module_genai/md_image_generation.py
    prompt="A beautiful landscape painting by Claude Monet"

    python "$app" \
        --model_path ./tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov \
        --device GPU \
        --prompt "$prompt" \
        --height 512 \
        --width 512 \
        --steps 9
fi