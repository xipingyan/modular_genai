
set -eo pipefail

SCRIPT_DIR_BUILD_PIPELINE_MX="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

source ./python-env/bin/activate
source ./source_mx_ov.sh

echo "${SCRIPT_DIR_BUILD_PIPELINE_MX}"

cd openvino.pipeline.mx

# Download and prepare OpenVINO GenAI dependencies.
python scripts/bootstrap_deps.py --stb

BUILD_TYPE=Release
BUILD_TYPE=Debug

# echo "================================"
# echo "== Start to build OpenVINO GenAI with new arch OpenVINO."
# -DCMAKE_BUILD_TYPE="$BUILD_TYPE"

# IMPORTANT:
# Force composable_pipeline to build openvino.genai from submodule source.
# Otherwise CMake may find a cached/prebuilt OpenVINOGenAI package and skip
# recompiling changes under thirdparty/openvino.genai/src/...
unset OpenVINOGenAI_DIR
cmake --preset full -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DOpenVINO_DIR=$OV_PATH_CMAKE -B build -DOpenCV_DIR=/usr/lib/x86_64-linux-gnu/cmake/opencv4 \
	-DCMAKE_DISABLE_FIND_PACKAGE_OpenVINOGenAI=OFF \
	-DENABLE_PROFILING_ITT=ON \
	-DOpenVINOGenAI_DIR=/__force_use_submodule_openvino_genai__

# cmake --preset full -DOpenVINO_DIR=$OV_PATH_CMAKE -B build -DOpenCV_DIR=/usr/lib/x86_64-linux-gnu/cmake/opencv4

cmake --build build --config "$BUILD_TYPE" -j 20
cmake --install ./build/ --config "$BUILD_TYPE" --prefix ./build/install
