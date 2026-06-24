#!/bin/bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

# Source environment
source ./install/setupvars.sh
source ./python-env/bin/activate

# Path to executables
SIMPLE_EXECUTABLE="./example/build/simple_pipeline"
FULL_SAMPLE="./install/samples/cpp/yaml_pipeline_sample"
CONFIG_YAML="./Gemma4/config_modeling_text_img_audio_cb_st.yaml"

if [ ! -f "$SIMPLE_EXECUTABLE" ]; then
    echo "Error: Executable not found. Please run build.sh first."
    exit 1
fi

echo "========================================"
echo "Test Case 1: Prompt Only (Simple Example)"
echo "========================================"
PROMPT="How do black holes work?"
$SIMPLE_EXECUTABLE $CONFIG_YAML "prompt=$PROMPT"

echo ""
echo "========================================"
echo "Test Case 2: Prompt with Image"
echo "========================================"
IMAGE="./GoldenGate.png"
PROMPT_IMAGE="What is shown in this image?"
if [ -f "$FULL_SAMPLE" ] && [ -f "$IMAGE" ]; then
    $FULL_SAMPLE $CONFIG_YAML "image=$IMAGE" "prompt=$PROMPT_IMAGE"
else
    echo "Note: Full sample or image not available. Skipping image test."
fi

echo ""
echo "========================================"
echo "Test Case 3: Prompt with Audio"
echo "========================================"
AUDIO="./journal1.wav"
AUDIO_PROMPT="Transcribe the following speech segment in its original language."
if [ -f "$FULL_SAMPLE" ] && [ -f "$AUDIO" ]; then
    $FULL_SAMPLE $CONFIG_YAML "audio=$AUDIO" "prompt=$AUDIO_PROMPT"
else
    echo "Note: Full sample or audio not available. Skipping audio test."
fi

echo ""
echo "========================================"
echo "All tests completed!"
echo "======================================"
