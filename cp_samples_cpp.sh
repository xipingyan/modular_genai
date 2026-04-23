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
# export WARMUP=1                # Run one warmup iteration before measuring performance.

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

    # cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_tts_int4.yaml
    # cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video.yaml
    # cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_split_llm_cb.yaml
    # cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_runtime_split_llm_cb_cpu.yaml
    # cfg=./samples/config_yaml/Qwen3_omni/config_prompt_audio_image_video_runtime_split_llm_sd_eagle3_cpu.yaml
    # $app "$cfg" \
    #     "videos=$video" \
    #     "images=$image" \
    #     "prompts=$prompt" \
    #     "audios=$audio" \
    #     "use_audio_in_video=0"

    cfg=./samples/config_yaml/Qwen3_omni/config_prompt_image_split_llm_sd_eagle3_cpu.yaml
    image=./tests/cpp/test_data/qwen3_omni_4b_inputs/driving_448x448.png
    image=./tests/cpp/test_data/qwen3_omni_4b_inputs/driving_512x384.png
    prompt="你是一位专业的智能座舱视觉分析助手，擅长对车内拍摄的图像进行全面、细致的分析。请你观察这张车内拍摄的照片，先对图片做简要描述(重要)。并从以下多个维度进行详细分析和描述：一、驾驶员状态分析：1.驾驶员是否在画面中可见？如果可见，请描述其大致姿态（坐姿是否端正、身体是否前倾或后仰）。2.驾驶员的双手位置：是否握住方向盘？单手还是双手？手部是否在操作手机或其他设备？3.驾驶员的头部朝向和视线方向：是否目视前方？是否存在分心驾驶的迹象（如低头看手机、转头与乘客交谈、闭眼打瞌睡等）？4.驾驶员是否佩戴安全带？安全带是否正确系好？5.驾驶员的面部表情和精神状态：是否有疲劳、困倦、打哈欠等异常表现？二、乘客状态分析：1.车内是否有其他乘客？如果有，请描述乘客数量和大致位置（副驾、后排左、后排中、后排右）。2.乘客是否佩戴安全带？3.是否有儿童乘客？如果有，是否使用了儿童安全座椅？4.乘客是否有异常行为（如站立、将身体伸出车窗等不安全的动作）？三、车内环境分析：1.车内的整体光照条件如何？是白天还是夜间？是否有阳光直射或逆光影响画面清晰度？2.中控台和仪表盘的状态：是否能看到车速、转速、导航等信息？档位处于什么状态？3.车内是否有明显的物品摆放？比如手机支架、水杯、挂饰、遮阳板、纸巾盒等。4.车内是否整洁？是否有影响驾驶安全的物品散落在踏板区域或仪表台上？四、安全隐患识别：请综合以上分析，列出你在画面中发现的所有潜在安全隐患，并按风险等级（高/中/低）进行分类。对于每个隐患，给出简要的改进建议。五、总结：请用三到五句话对这张照片进行整体总结，重点说明驾驶员的专注度、车内乘员的安全防护状况，以及你认为当前最需要立即关注和改进的问题。请以结构化的格式输出你的分析结果，确保条理清晰、描述准确。如果某些信息因拍摄角度或画面遮挡而无法判断，请说明"
    $app "$cfg" \
        "images=$image" \
        "prompts=$prompt"

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
