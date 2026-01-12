SCRIPT_DIR_GENAI_MODULE_PY="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_GENAI_MODULE_PY}

source ../../../python-env/bin/activate
source ../../../source_ov.sh

GENAI_ROOT_DIR=${SCRIPT_DIR_GENAI_MODULE_PY}/../../../openvino.genai/install/python/
export PYTHONPATH=${GENAI_ROOT_DIR}:$PYTHONPATH
export LD_LIBRARY_PATH=${GENAI_ROOT_DIR}/../runtime/lib/intel64/:$LD_LIBRARY_PATH

cd ${SCRIPT_DIR_GENAI_MODULE_PY}

model_dir=${SCRIPT_DIR_GENAI_MODULE_PY}/../../../openvino.genai/samples/cpp/module_genai/ut_pipelines/Z-Image-Turbo-fp16-ov/

python test_z_image_pipeline.py $model_dir CPU True
