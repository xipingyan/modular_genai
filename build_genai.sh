
SCRIPT_DIR_BUILD_GENAI="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_BUILD_GENAI}

source ./python-env/bin/activate
source ./source_ov.sh

echo $SCRIPT_DIR_BUILD_GENAI

cd openvino.genai
# cmake -DCMAKE_BUILD_TYPE=Release -S ./ -B ./build/
# cmake --build ./build/ --config Release -j 200
# cmake --install ./build/ --config Release --prefix ./install

# # Debug
# cmake -DCMAKE_BUILD_TYPE=Debug -S ./ -B ./build/
# cmake --build ./build/ --config Debug -j 200
# cmake --install ./build/ --config Debug --prefix ./install

echo "================================"
echo "== Start to build OpenVINO GenAI with new arch OpenVINO."

# cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_DYNAMIC_LOAD_MODEL_WEIGHTS=OFF \
#     -DENABLE_OPENVINO_NEW_ARCH=OFF -DOpenVINO_DIR=$OV_PATH -DENABLE_SYSTEM_OPENCL=OFF \
#     -DENABLE_MODELING_PRIVATE=ON \
#     -S ./ -B ./build/
cmake --build ./build/ --config Debug -j 200
cmake --install ./build/ --config Debug --prefix ./build/install