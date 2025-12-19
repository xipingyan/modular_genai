SCRIPT_DIR_EXAMPLE_OV_CPP_RUN="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_EXAMPLE_OV_CPP_RUN}

source ../python-env/bin/activate
source ../source_ov.sh

cd ${SCRIPT_DIR_EXAMPLE_OV_CPP_RUN}

./build/module_genai_app ../models/Qwen2.5-VL-3B-Instruct/INT4/config_test.yaml