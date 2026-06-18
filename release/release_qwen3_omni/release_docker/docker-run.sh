#!/bin/bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Docker run script with model volume mount
#
# Usage: Run from release_qwen3_omni directory:
#   cd ~/mygithub/modular_genai/release/release_qwen3_omni
#   ./release_docker/docker-run.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Pipeline.MX Docker Run"
echo "=========================================="
echo "Working directory: $PARENT_DIR"
echo ""

# Check if model directory exists
MODEL_DIR="$PARENT_DIR/Qwen3-Omni-4B-Instruct-multilingual-int4"
if [ ! -d "$MODEL_DIR" ]; then
    echo "❌ Error: Model directory not found at:"
    echo "   $MODEL_DIR"
    echo ""
    echo "Please ensure the model is available at this location."
    exit 1
fi

echo "✅ Found model directory: $MODEL_DIR"
echo ""

# Check for devices
if [ ! -e /dev/dri ]; then
    echo "⚠️  Warning: /dev/dri not found - iGPU may not be available"
fi

if [ ! -e /dev/accel/accel0 ]; then
    echo "⚠️  Warning: /dev/accel/accel0 not found - NPU may not be available"
fi

echo ""
echo "🚀 Starting container..."
echo ""

# Get host video and render group IDs
VIDEO_GID=$(getent group video | cut -d: -f3)
RENDER_GID=$(getent group render | cut -d: -f3)

echo "📋 Device group IDs:"
echo "   video: $VIDEO_GID"
echo "   render: $RENDER_GID"
echo ""

# Run container with model mounted
sudo docker run --rm -it \
    --device /dev/dri:/dev/dri \
    --device /dev/accel/accel0:/dev/accel/accel0 \
    --group-add $VIDEO_GID \
    --group-add $RENDER_GID \
    -v "$MODEL_DIR:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro" \
    pipeline-mx-qwen3-omni:latest \
    "$@"

echo ""
echo "✅ Container exited"
