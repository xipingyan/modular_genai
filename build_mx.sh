
set -eo pipefail

SCRIPT_DIR_BUILD_PIPELINE_MX="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

source ./python-env/bin/activate

echo "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

cd openvino.pipeline.mx

# Bootstrap all dependencies (auto-detects platform)
python scripts/bootstrap_deps.py

# Configure, build, and install
cmake --preset full
cmake --build build -j$(nproc)
cmake --install build --prefix build/install
