#!/bin/bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Docker build script with cache optimization
#
# Usage: Run from release_qwen3_omni directory:
#   cd ~/mygithub/modular_genai/release/release_qwen3_omni
#   ./release_docker/docker-build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Pipeline.MX Docker Build"
echo "=========================================="
echo "Build context: $PARENT_DIR"
echo "Dockerfile: $SCRIPT_DIR/Dockerfile"
echo ""

# Change to parent directory (release_qwen3_omni)
cd "$PARENT_DIR"

# Enable Docker BuildKit for better caching
export DOCKER_BUILDKIT=1

# Build with cache mount for apt packages
echo "🔨 Starting Docker build..."
echo ""

# Use Intel proxy if available
PROXY_ARGS=""
if [ -n "${http_proxy:-}" ] || [ -n "${HTTP_PROXY:-}" ]; then
    PROXY="${http_proxy:-$HTTP_PROXY}"
    echo "📡 Using proxy: $PROXY"
    PROXY_ARGS="--build-arg http_proxy=$PROXY --build-arg https_proxy=$PROXY --build-arg HTTP_PROXY=$PROXY --build-arg HTTPS_PROXY=$PROXY"
fi

sudo docker build \
    --network=host \
    --progress=plain \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    $PROXY_ARGS \
    -f release_docker/Dockerfile \
    -t pipeline-mx-qwen3-omni:latest \
    .

BUILD_STATUS=$?

echo ""
if [ $BUILD_STATUS -eq 0 ]; then
    echo "=========================================="
    echo "✅ Build completed successfully!"
    echo "=========================================="
    echo "Image: pipeline-mx-qwen3-omni:latest"
    echo ""
    echo "📊 Check image size:"
    echo "  sudo docker images pipeline-mx-qwen3-omni:latest"
    echo ""
    echo "🚀 To run with iGPU:"
    echo "  sudo docker run --rm \\"
    echo "    --device /dev/dri:/dev/dri \\"
    echo "    --group-add video \\"
    echo "    --group-add render \\"
    echo "    pipeline-mx-qwen3-omni:latest"
    echo ""
    echo "🚀 To run with iGPU + NPU:"
    echo "  sudo docker run --rm \\"
    echo "    --device /dev/dri:/dev/dri \\"
    echo "    --device /dev/accel/accel0:/dev/accel/accel0 \\"
    echo "    --group-add video \\"
    echo "    --group-add render \\"
    echo "    pipeline-mx-qwen3-omni:latest"
    echo ""
    echo "🐚 For interactive shell:"
    echo "  sudo docker run -it --rm \\"
    echo "    --device /dev/dri:/dev/dri \\"
    echo "    --group-add video --group-add render \\"
    echo "    pipeline-mx-qwen3-omni:latest /bin/bash"
    echo ""
else
    echo "=========================================="
    echo "❌ Build failed with exit code: $BUILD_STATUS"
    echo "=========================================="
    exit $BUILD_STATUS
fi
