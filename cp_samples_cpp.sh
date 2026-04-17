#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_CP_CPP_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}"

if [[ ! -f "./python-env/bin/activate" ]]; then
    echo "[ERROR] Missing venv activate script: ./python-env/bin/activate" >&2
    exit 1
fi
if [[ ! -f "./source_ov.sh" ]]; then
    echo "[ERROR] Missing OpenVINO env script: ./source_ov.sh" >&2
    exit 1
fi

source ./python-env/bin/activate

# OpenVINO's setup scripts are not always compatible with `set -u` (nounset).
set +u
source ./source_ov.sh
set -u

CP_REPOS_DIR="${SCRIPT_DIR_RUN_CP_CPP_SAMPLES}/composable_pipeline"

if [[ -z "${OPENVINO_TOKENIZERS_PATH:-}" ]]; then
    TOKENIZERS_SO="${CP_REPOS_DIR}/build/openvino_genai/libopenvino_tokenizers.so"
    if [[ -f "$TOKENIZERS_SO" ]]; then
        export OPENVINO_TOKENIZERS_PATH="$TOKENIZERS_SO"
    fi
fi

cd "${CP_REPOS_DIR}"
QWEN2_5="${QWEN2_5:-0}"
QWEN3_OMNI="${QWEN3_OMNI:-1}"

echo "Running Composable Pipeline samples with settings:"
echo "  QWEN2_5=$QWEN2_5"
echo "  QWEN3_OMNI=$QWEN3_OMNI"

# export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1       # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
export OPENVINO_LOG_LEVEL=3   # Set OpenVINO log level.

app=./build/samples/yaml_pipeline_sample

if [[ "$QWEN2_5" == "1" ]]; then
    prompt="Please describe the image"
    img=./tests/cpp/test_data/cat_120_100.png

    cfg=samples/config_yaml/Qwen2.5-VL-3B-Instruct/config_prompt_image_cb.yaml
    "$app" "$cfg" "image=$img" "prompt=$prompt"
fi

# Run MD Omni Sample
if [[ "$QWEN3_OMNI" == "1" ]]; then
    video=./tests/cpp/test_data/rainning_480p_16khz_2s.mp4
    image=./tests/cpp/test_data/london.jpg
    # https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-Omni/demo/cough.wav
    audio=./tests/cpp/test_data/thunder-and-rain-sounds.wav
    prompt="You are a weather bot. I'm showing you my current location and a forecast report. Look at the window (video) and listen to the environment. Is the forecast accurate? Respond with a summary and a voice alert."

    cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_tts_int4.yaml
    cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video.yaml
    cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_split_llm_cb.yaml
    cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_runtime_split_llm_cb_cpu.yaml
    $app "$cfg" \
        "videos=$video" \
        "images=$image" \
        "prompts=$prompt" \
        "audios=$audio" \
        "use_audio_in_video=0"

    # cfg=./samples/config_yaml/Qwen3_omni/config_prompt_image_bus_cb.yaml
    # $app "$cfg" "images=$image" "prompts=$prompt"
    
    # # prompt -> tts
    # # =============================================================================
    # cfg=./samples/cpp/module_genai/config_yaml/Qwen3-Omni/config_prompt_tts_int4.yaml
    # prompt="你好，明天天气怎么样？如果天气不错，一起出去打羽毛球怎么样？"
    # "$app" -cfg "$cfg" -prompt "$prompt" \
    #     -tts 1 \
    #     -cache_dir "$cache_dir" \
    #     -warmup 1 -perf 1

    # # prompt -> text
    # # =============================================================================
    # cfg=./samples/cpp/module_genai/config_yaml/Qwen3-Omni/config_prompt.yaml
    # prompt="中国最发达的城市是哪个？使用json格式回答，例如：{'answer': '郑州'}，只回答json，不要其他多余的文字。"
    # prompt="中国最发达的城市是哪个？简单介绍一下这个城市。"
    # "$app" -cfg "$cfg" -prompt "$prompt" -tts 0 \
    #     -cache_dir "$cache_dir" \
    #     -warmup 0 -perf 1
fi
