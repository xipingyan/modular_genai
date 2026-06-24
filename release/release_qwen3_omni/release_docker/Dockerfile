# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Dockerfile for Pipeline.MX Qwen3-Omni Release
# Supports Intel iGPU and NPU inference
#
# Build from parent directory:
#   cd ~/mygithub/modular_genai/release/release_qwen3_omni
#   sudo docker build -f release_docker/Dockerfile -t pipeline-mx-qwen3-omni:latest .

FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Layer 1: Install base system dependencies + all runtime deps in ONE layer (faster, better caching)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    libopencv-core406t64 \
    libopencv-imgproc406t64 \
    libopencv-imgcodecs406t64 \
    libopencv-videoio406t64 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer-plugins-good1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libgomp1 \
    libdc1394-25 \
    libglib2.0-0

# Layer 2: Install OpenCL ICD Loader and DRM libraries (required for GPU)
# REBUILD: 2026-06-18v2 - Added ocl-icd-libopencl1, libdrm2, libdrm-intel1
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ocl-icd-libopencl1 \
    libdrm2 \
    libdrm-intel1 \
    libdrm-common

# Layer 2.5: Add kobuk-team PPA for Ubuntu 24.04 compatible GPU drivers
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:kobuk-team/intel-graphics && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    intel-opencl-icd=26.18.38308.4-1~24.04~ppa1 \
    intel-level-zero-gpu

# Layer 3: Create user and set up directory structure (cached)
# Create video and render groups first (may already exist)
RUN groupadd -r render 2>/dev/null || true
RUN groupadd -r video 2>/dev/null || true

# Create pipelineuser (force creation, handle conflicts)
RUN set -x && \
    (groupadd -g 1000 pipelineuser 2>/dev/null || \
     groupmod -n pipelineuser $(getent group 1000 | cut -d: -f1) 2>/dev/null || \
     true) && \
    (useradd -m -u 1000 -g 1000 -G video,render pipelineuser 2>/dev/null || \
     (userdel -f $(getent passwd 1000 | cut -d: -f1) 2>/dev/null || true && \
      useradd -m -u 1000 -g 1000 -G video,render pipelineuser)) && \
    mkdir -p /opt/pipeline_mx && \
    chown -R 1000:1000 /opt/pipeline_mx

# Set working directory
WORKDIR /opt/pipeline_mx

# Layer 4: Copy install directory (cached unless install/ changes)
COPY --chown=pipelineuser:pipelineuser install/ ./install/

# Layer 5: Create model directory placeholder (model will be mounted at runtime)
RUN mkdir -p /opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4 && \
    chown -R pipelineuser:pipelineuser /opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4

# Layer 6: Copy test data directories (cached unless test data changes)
COPY --chown=pipelineuser:pipelineuser qwen3_omni/ ./qwen3_omni/

# Layer 7: Copy configuration and test files (least cached - frequently modified)
COPY --chown=pipelineuser:pipelineuser config_chat_cb.yaml ./
COPY --chown=pipelineuser:pipelineuser case1_comprehensive.json ./
COPY --chown=pipelineuser:pipelineuser GoldenGate.png ./
COPY --chown=pipelineuser:pipelineuser run.sh ./

# Switch to non-root user
USER pipelineuser

# Set environment variables (mirrors setupvars.sh logic)
ENV PIPELINE_MX_DIR=/opt/pipeline_mx/install
ENV Pipeline_DIR=/opt/pipeline_mx/install/runtime/cmake
ENV LD_LIBRARY_PATH=/opt/pipeline_mx/install/runtime/lib/intel64:/opt/pipeline_mx/install/runtime/3rdparty/tbb/lib
ENV PYTHONPATH=/opt/pipeline_mx/install/python
ENV PATH=/opt/pipeline_mx/install/samples/cpp:${PATH}
ENV OPENVINO_TOKENIZERS_PATH=/opt/pipeline_mx/install/runtime/lib/intel64/libopenvino_tokenizers.so

# Default command: run the benchmark with the provided configuration
CMD ["pipeline_benchmark", "config_chat_cb.yaml", "--conversation", "case1_comprehensive.json", "--warmup", "0", "--iter", "1", "--max-frames", "12"]
