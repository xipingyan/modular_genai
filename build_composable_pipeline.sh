
SCRIPT_DIR_BUILD_GENAI="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd "${SCRIPT_DIR_BUILD_GENAI}"

source ./python-env/bin/activate
source ./source_ov.sh

echo "${SCRIPT_DIR_BUILD_GENAI}"

cd composable_pipeline

# BUILD_TYPE=Release
BUILD_TYPE=Debug

# echo "================================"
# echo "== Start to build OpenVINO GenAI with new arch OpenVINO."
# -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
# cmake --preset full -DOpenVINO_DIR=/mnt/xiping/mygithub/modular_genai/openvino -B build
cmake --build build --config "$BUILD_TYPE" -j 30
# cmake --install ./build/ --config "$BUILD_TYPE" --prefix ./build/install
