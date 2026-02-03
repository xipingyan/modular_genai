SCRIPT_DIR_EXAMPLE_OV_CPP_RUN="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_DIR_EXAMPLE_OV_CPP_RUN}

# export OV_GPU_DisableOnednn=1
rm -rf ./my_cache_dir/*.weights_cache 

source ../python-env/bin/activate
source ../source_ov.sh

cd ${SCRIPT_DIR_EXAMPLE_OV_CPP_RUN}

# export DEVICE=GPU             # Specific device for testing, default is CPU
export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export OPENVINO_LOG_LEVEL=2   # Set OpenVINO log level.

# ./build/module_genai_app ../models/Qwen2.5-VL-3B-Instruct/INT4/config_test.yaml
./build/module_genai_app ../models/Z-Image-Turbo-fp16-ov/config.yaml