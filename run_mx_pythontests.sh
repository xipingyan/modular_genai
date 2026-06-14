#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_MX_PY_TEST="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_MX_PY_TEST}/openvino.pipeline.mx"

if [[ ! -f "./pytest_env/bin/activate" ]]; then
    echo "[ERROR] Missing venv activate script: ./pytest_env/bin/activate" >&2
    exit 1
fi

source ./pytest_env/bin/activate

rm -rf .pytest_cache/
source build/install/setupvars.sh 
python -m pytest tests/python_tests/ -v