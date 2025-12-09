
SCRIPT_DIR_BUILD_GENAI="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_BUILD_GENAI}

source ./python-env/bin/activate
source ./source_ov.sh

echo $SCRIPT_DIR_BUILD_GENAI

cd openvino.genai
# cmake -DCMAKE_BUILD_TYPE=Release -S ./ -B ./build/
# cmake --build ./build/ --config Release -j 200
# cmake --install ./build/ --config Release --prefix ./install

# Debug
cmake -DCMAKE_BUILD_TYPE=Debug -S ./ -B ./build/
cmake --build ./build/ --config Debug -j 200
cmake --install ./build/ --config Debug --prefix ./install
