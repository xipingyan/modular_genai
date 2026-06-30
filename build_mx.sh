
set -eo pipefail

SCRIPT_DIR_BUILD_PIPELINE_MX="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

source ./python-env/bin/activate

echo "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

cd openvino.pipeline.mx

BUILD_TYPE=Release
# BUILD_TYPE=Debug

# Bootstrap all dependencies (auto-detects platform)
python scripts/bootstrap_deps.py --build-dir build --build-type $BUILD_TYPE

# Configure, build, and install
cmake --preset full -DCMAKE_BUILD_TYPE=$BUILD_TYPE
cmake --build build --config $BUILD_TYPE -j$(nproc)
cmake --install build --config $BUILD_TYPE --prefix build/install
