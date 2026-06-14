
set -eo pipefail

SCRIPT_DIR_BUILD_PIPELINE_MX="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

source ./python-env/bin/activate

echo "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

cd openvino.pipeline.mx

BUILD_TYPE=Release
# BUILD_TYPE=Debug

python scripts/bootstrap_deps.py --openvino --build-dir build --build-type $BUILD_TYPE --stb
# cmake --preset minimal
cmake --preset full
cmake --build build --config "$BUILD_TYPE" -j$(nproc)
cmake --install ./build/ --config "$BUILD_TYPE" --prefix ./build/install
