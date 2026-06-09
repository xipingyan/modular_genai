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

OV_TOKENIZERS_LIB_PATH=${SCRIPT_DIR_RUN_MODELING_SAMPLES}/openvino.pipeline.mx/build/openvino_genai/libopenvino_tokenizers.so
if [ ! -f ${OV_TOKENIZERS_LIB_PATH} ]; then
    echo "libopenvino_tokenizers.so not found in build dir, copying..."
    cp ${SCRIPT_DIR_RUN_MODELING_SAMPLES}/openvino.pipeline.mx/thirdparty/openvino.genai/build/openvino_genai/libopenvino_tokenizers.so ${OV_TOKENIZERS_LIB_PATH}
fi

cd "${SCRIPT_DIR_RUN_MODELING_SAMPLES}"

modeling_app=./openvino.pipeline.mx/thirdparty/openvino.genai/bin/intel64/Release/modeling_gemma4_mm

torch_model=/home/xiping/mygithub/profiling_ov_genai/models/models/google/gemma-4-12B-it
img_path=./openvino.pipeline.mx/tests/test_data/GoldenGate.png
audio_path=./openvino.pipeline.mx/tests/test_data/journal1.wav
prompt='Describe the content of the image and transcribe the audio. For the image, provide a detailed description of the scene, including objects, people, and their interactions.'
dst_dir=./gemma-4-12B-it_ov
mkdir -p ${dst_dir}

# $modeling_app -h
$modeling_app $torch_model --prompt "$prompt" --image $img_path --audio $audio_path --device GPU --max-new-tokens 20 --export-ir $dst_dir

mv ${dst_dir} ./openvino.pipeline.mx/tests/test_models/
