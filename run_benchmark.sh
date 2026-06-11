#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_PIPELINE_BENCHMARK="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_PIPELINE_BENCHMARK}/openvino.pipeline.mx"

${SCRIPT_DIR_PIPELINE_BENCHMARK}/source_mx_ov.sh
source ${SCRIPT_DIR_PIPELINE_BENCHMARK}/openvino.pipeline.mx/build/install/setupvars.sh

# pipeline_benchmark is now in PATH thanks to setupvars.sh
config_yaml=./samples/config_yaml/Qwen3_omni/config_chat_cb.yaml
pipeline_benchmark $config_yaml "prompts=How many cars in the image?" "images=./tests/test_data/cars-1200-674.jpg"
