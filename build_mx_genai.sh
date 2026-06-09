
SCRIPT_DIR_BUILD_GENAI="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_BUILD_GENAI}

source ./python-env/bin/activate
source ./source_mx_ov.sh

echo $SCRIPT_DIR_BUILD_GENAI

cd openvino.pipeline.mx/thirdparty/openvino.genai


echo "================================"
echo "== Start to build OpenVINO GenAI with new arch OpenVINO."

BUILD_TYPE=Release
# BUILD_TYPE=Debug

cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
  -DENABLE_SYSTEM_OPENCL=OFF
  -DOpenVINO_DIR=../openvino/build/install/runtime/cmake/ \
  -DCMAKE_PREFIX_PATH=../openvino/build/install/developer_package/cmake/ \
  -S ./ -B ./build/
cmake --build ./build/ --config $BUILD_TYPE -j 200
cmake --install ./build/ --config $BUILD_TYPE --prefix ./build/install