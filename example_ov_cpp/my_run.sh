SCRIPT_DIR_EXAMPLE_OV_CPP_RUN="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_EXAMPLE_OV_CPP_RUN}

source ../python-env/bin/activate
source ../source_ov.sh

cd ${SCRIPT_DIR_EXAMPLE_OV_CPP_RUN}

./build/module_genai_app ./config_test.yaml