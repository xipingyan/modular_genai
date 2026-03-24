#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR_RUN_GENAI_SAMPLES="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "${SCRIPT_DIR_RUN_GENAI_SAMPLES}"

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

cd "${SCRIPT_DIR_RUN_GENAI_SAMPLES}/openvino.genai"
RUN_VLM="${RUN_VLM:-0}"
RUN_OMNI="${RUN_OMNI:-0}"
RUN_GEN_IMG="${RUN_GEN_IMG:-0}"
RUN_GEN_VIDEO="${RUN_GEN_VIDEO:-0}"

echo "Running GenAI samples with settings:"
echo "  RUN_VLM=$RUN_VLM"
echo "  RUN_OMNI=$RUN_OMNI"
echo "  RUN_GEN_IMG=$RUN_GEN_IMG"
echo "  RUN_GEN_VIDEO=$RUN_GEN_VIDEO"

# export DEVICE=GPU             # Specific device for testing, default is CPU
# export ENABLE_PROFILE=1         # Dump profiling data. default 0.
# export DUMP_YAML=1            # Dump pipeline to YAML file. default 0.
# export DUMP_PERFORMANCE=1     # Dump performance metrics after generation. default 0.
# export OPENVINO_LOG_LEVEL=3   # Set OpenVINO log level.

# Run MD Visual Language Chat Sample
if [[ "$RUN_VLM" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_visual_language_chat
    cfg=./samples/cpp/module_genai/config_yaml/Qwen2.5-VL-3B-Instruct/config.yaml
    prompt="Please describe the image"
    img=./tests/module_genai/cpp/test_data/cat_120_100.png

    "$app" -cfg "$cfg" -prompt "$prompt" -img "$img"
fi

# Run MD Omni Sample
if [[ "$RUN_OMNI" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_omni
    img=./tests/module_genai/cpp/test_data/scene_120_100.png
    cache_dir=./cache_dir_qwen3_omni

    # cfg=./samples/cpp/module_genai/config_yaml/Qwen3-Omni/config_prompt_image_cpu.yaml
    # prompt="Please describe the scene"
    # img=./tests/module_genai/cpp/test_data/cars-1200-674.jpg
    # "$app" -cfg "$cfg" -prompt "$prompt" -img "$img" -warmup 1 -perf 1 -device CPU

    # # video+image+audio prompt -> text + tts
    # video=./tests/module_genai/cpp/test_data/rainning_480p_16khz_2s.mp4
    # image=./tests/module_genai/cpp/test_data/london.jpg
    # # https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-Omni/demo/cough.wav
    # audio=./tests/module_genai/cpp/test_data/thunder-and-rain-sounds.wav
    # cfg=./samples/cpp/module_genai/config_yaml/Qwen3-Omni/config_prompt_audio_image_video_tts_int4.yaml
    # prompt="You are a weather bot. I'm showing you my current location and a forecast report. Look at the window (video) and listen to the environment. Is the forecast accurate? Respond with a summary and a voice alert."
    # # "$app" -h
    # "$app" -cfg "$cfg" -video "$video" -img "$image" -audio "$audio" -prompt "$prompt" \
    #     -use_audio_in_video 0 -tts 1 \
    #     -cache_dir "$cache_dir" \
    #     -warmup 1 -perf 1

    # prompt -> tts
    cfg=./samples/cpp/module_genai/config_yaml/Qwen3-Omni/config_prompt_tts_int4.yaml
    prompt="你好，明天天气怎么样？如果天气不错，一起出去打羽毛球怎么样？"  # "Hello, how's the weather today?" in Chinese
    "$app" -cfg "$cfg" -prompt "$prompt" \
        -tts 1 \
        -cache_dir "$cache_dir" \
        -warmup 1 -perf 1
fi

# Run MD Image Generation Sample
if [[ "$RUN_GEN_IMG" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_image_generation
    cfg=./samples/cpp/module_genai/config_yaml/Z-Image-Turbo-fp16-ov/config.yaml
    cfg=./samples/cpp/module_genai/config_yaml/Z-Image-Turbo-fp16-ov/config_tiling.yaml
    prompt="A beautiful landscape painting by Claude Monet"

    "$app" -cfg "$cfg" -prompt "$prompt" --height 512 --width 512 --num_inference_steps 9 --guidance_scale 2.5 --max_sequence_length 512
fi

# Run MD Video Generation Sample
if [[ "$RUN_GEN_VIDEO" == "1" ]]; then
    app=./build/samples/cpp/module_genai/md_video_generation
    cfg=./samples/cpp/module_genai/config_yaml/Wan2.1-T2V-1.3B-Diffusers/config.yaml
    # cfg=./samples/cpp/module_genai/config_yaml/Wan2.1-T2V-1.3B-Diffusers/config_split_transformer.yaml
    prompt="A cat and a dog baking a cake together in a kitchen. The cat is carefully measuring flour, while the dog is stirring the batter with a wooden spoon. The kitchen is cozy, with sunlight streaming through the window."
    neg_prompt="Bright tones, overexposed, static, blurred details, subtitles, style, works, paintings, images, static, overall gray, worst quality, low quality, JPEG compression residue, ugly, incomplete, extra fingers, poorly drawn hands, poorly drawn faces, deformed, disfigured, misshapen limbs, fused fingers, still picture, messy background, three legs, many people in the background, walking backwards"

    "$app" -cfg "$cfg" -prompt "$prompt" --negative_prompt $neg_prompt --num_frames 16 --height 240 --width 240 --steps 9
fi