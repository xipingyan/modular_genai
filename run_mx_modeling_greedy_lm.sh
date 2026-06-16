#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_MODELING_GREEDY_LM="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_MODELING_GREEDY_LM}"

APP=./openvino.pipeline.mx/thirdparty/openvino.genai/bin/intel64/Release/greedy_causal_lm
TorchModel=/home/xiping/mygithub/download_model/models/models/google/gemma-4-12B-it/gemma-4-12B-it/


# $APP $TorchModel "what is openvino?" CPU 1 1 64 int4_asym 128
$APP $TorchModel --prompt-file ./openvino.pipeline.mx/tests/test_data/perf_input_txt/input_1k.txt GPU 1 1 64 int4_asym 128

$APP $TorchModel --prompt-file ./openvino.pipeline.mx/tests/test_data/perf_input_txt/input_4k.txt GPU 1 1 64 int4_asym 128

$APP $TorchModel --prompt-file ./openvino.pipeline.mx/tests/test_data/perf_input_txt/input_8k.txt GPU 1 1 64 int4_asym 128
