
SCRIPT_DIR_BUILD_GENAI="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd "${SCRIPT_DIR_BUILD_GENAI}"

source ./python-env/bin/activate
source ./source_ov.sh

echo "${SCRIPT_DIR_BUILD_GENAI}"

cd composable_pipeline

# BUILD_TYPE=Release
BUILD_TYPE=Debug

# Build OpenVINO GenAI submodule (required for extension ops like SpecialTokensSplit)
GENAI_ROOT="${SCRIPT_DIR_BUILD_GENAI}/composable_pipeline/thirdparty/openvino.genai"
GENAI_BUILD="${GENAI_ROOT}/build"
GENAI_INSTALL="${GENAI_BUILD}/install"

cmake -S "${GENAI_ROOT}" -B "${GENAI_BUILD}" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DOpenVINO_DIR="$OV_PATH"
cmake --build "${GENAI_BUILD}" --config "$BUILD_TYPE" -j 30
cmake --install "${GENAI_BUILD}" --config "$BUILD_TYPE" --prefix "${GENAI_INSTALL}"

echo "================================"
echo "== Start to build OpenVINO GenAI with new arch OpenVINO."
# cmake --preset minimal -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DOpenVINO_DIR=$OV_PATH -DENABLE_MODELING_PRIVATE=ON 
cmake --preset samples -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DOpenVINO_DIR="$OV_PATH" -DENABLE_CB=ON -DOpenVINOGenAI_DIR="${GENAI_INSTALL}/runtime/cmake" -DENABLE_MODELING_PRIVATE=ON 
cmake --build build --config "$BUILD_TYPE" -j 30
cmake --install ./build/ --config "$BUILD_TYPE" --prefix ./build/install
