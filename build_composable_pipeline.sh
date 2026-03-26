
SCRIPT_DIR_BUILD_GENAI="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_BUILD_GENAI}

source ./python-env/bin/activate
source ./source_ov.sh

echo $SCRIPT_DIR_BUILD_GENAI

cd composable_pipeline

echo "================================"
echo "== Start to build OpenVINO GenAI with new arch OpenVINO."

BUILD_TYPE=Release
# BUILD_TYPE=Debug

cmake --preset minimal -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DOpenVINO_DIR=$OV_PATH -DENABLE_MODELING_PRIVATE=ON 
cmake --build build --config $BUILD_TYPE -j 30
cmake --install ./build/ --config $BUILD_TYPE --prefix ./build/install