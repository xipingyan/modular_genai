# Pipeline.MX Qwen3-Omni Docker Guide

This directory contains Docker build files for Pipeline.MX Qwen3-Omni multimodal inference.

## 📁 Directory Structure

```
release_qwen3_omni/
├── release_docker/          # Docker build files (this directory)
│   ├── Dockerfile           # Multi-stage optimized Dockerfile
│   ├── docker-build.sh      # Build script with cache optimization
│   ├── .dockerignore        # Exclude Docker files from context
│   └── README.md            # This file
├── install/                 # Pipeline.MX runtime (~320MB)
├── Qwen3-Omni-4B-Instruct-multilingual-int4/  # Model files (~8.6GB)
├── qwen3_omni/              # Test data
├── config_chat_cb.yaml      # Pipeline configuration
├── case1_comprehensive.json # Test conversation
└── run.sh                   # Host run script
```

## 🚀 Quick Start

### Build the Docker Image

From the `release_qwen3_omni` directory:

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni
./release_docker/docker-build.sh
```

Or manually:

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni
sudo docker build -f release_docker/Dockerfile -t pipeline-mx-qwen3-omni:latest .
```

### Run with Intel iGPU

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video \
  --group-add render \
  pipeline-mx-qwen3-omni:latest
```

### Run with Intel NPU (in addition to GPU)

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add video \
  --group-add render \
  pipeline-mx-qwen3-omni:latest
```

## 🎯 Prerequisites

- Docker installed on your system
- Intel GPU with compute runtime support (Arc, Iris Xe, or newer)
- Intel NPU (optional, for NPU inference)
- Host must have `/dev/dri` (for iGPU) and `/dev/accel/accel0` (for NPU) devices available
- Sudo access (or user in `docker` group)

## ⚡ Build Optimization

The Dockerfile is optimized for **maximum cache reuse**:

### Layer Strategy (from least to most frequently changed)

1. **System packages** (rarely changes) → cached across all builds
2. **Intel GPU runtime** (rarely changes) → cached across all builds
3. **OpenCV/GStreamer** (rarely changes) → cached across all builds
4. **User setup** (never changes) → always cached
5. **install/ directory** (~320MB) → cached unless you rebuild Pipeline.MX
6. **Model directory** (~8.6GB) → cached unless you change the model
7. **Test data** (qwen3_omni/) → cached unless you update test files
8. **Config files** (YAML/JSON) → **rebuilt quickly** when you modify configs

### Cache Benefits

- **First build**: ~5-10 minutes (downloads everything)
- **Config-only changes**: ~10-30 seconds (only copies config layer)
- **Test data changes**: ~1-2 minutes (copies test data + configs)
- **Model updates**: ~3-5 minutes (copies model + test data + configs)
- **Full rebuild**: Only when install/ or system packages change

### Build Context Optimization

The `.dockerignore` file excludes `release_docker/` from the build context, so Docker-related files don't trigger unnecessary rebuilds.

## 🔧 Advanced Usage

### Custom Configuration

Run with a different YAML config:

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -v $(pwd)/my_config.yaml:/opt/pipeline_mx/my_config.yaml \
  pipeline-mx-qwen3-omni:latest \
  pipeline_benchmark my_config.yaml --conversation case1_comprehensive.json
```

### Interactive Shell

Explore the container:

```bash
sudo docker run -it --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  pipeline-mx-qwen3-omni:latest \
  /bin/bash
```

Inside the container, all files are in `/opt/pipeline_mx/`:

```bash
ls -la /opt/pipeline_mx/
# install/  Qwen3-Omni-4B-Instruct-multilingual-int4/  qwen3_omni/
# config_chat_cb.yaml  case1_comprehensive.json  GoldenGate.png  run.sh
```

### Mount Custom Test Data

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -v $(pwd)/my_test_data:/opt/pipeline_mx/my_test_data \
  pipeline-mx-qwen3-omni:latest \
  pipeline_benchmark config_chat_cb.yaml --conversation my_test_data/test.json
```

### Performance Tuning

Enable performance metrics output:

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -e DUMP_PERFORMANCE=1 \
  -e OPENVINO_LOG_LEVEL=0 \
  pipeline-mx-qwen3-omni:latest
```

## 🔍 Verify GPU/NPU Access

Check device access inside container:

```bash
sudo docker run -it --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add video --group-add render \
  pipeline-mx-qwen3-omni:latest \
  /bin/bash

# Inside container:
ls -la /dev/dri/        # Should show card1, renderD128
ls -la /dev/accel/      # Should show accel0 (if NPU available)
```

## 📦 Image Information

- **Base image**: Ubuntu 24.04
- **Expected size**: ~10-11GB
  - Base OS + dependencies: ~1.5GB
  - Install package: ~320MB
  - Qwen3-Omni model: ~8.6GB
- **Architecture**: x86_64 (intel64)
- **User**: Non-root user `pipelineuser` (UID 1000)
- **Working directory**: `/opt/pipeline_mx`

## 🐛 Troubleshooting

### Permission denied on /dev/dri

Ensure your host user is in the `video` and `render` groups:

```bash
sudo usermod -aG video,render $USER
```

Log out and log back in for changes to take effect.

### GPU not detected

Verify Intel GPU compute runtime on host:

```bash
clinfo  # Should list Intel GPU devices
```

### NPU not accessible

Check NPU driver installation on host:

```bash
ls -la /dev/accel/accel0
lspci | grep -i accelerator
```

### Build fails with network timeout

The Dockerfile uses Aliyun mirrors for faster downloads in China. If you're outside China, you can modify `Dockerfile` to use default Ubuntu mirrors:

```dockerfile
# Comment out or remove these lines:
# RUN sed -i 's@archive.ubuntu.com@mirrors.aliyun.com@g' /etc/apt/sources.list.d/ubuntu.sources && \
#     sed -i 's@security.ubuntu.com@mirrors.aliyun.com@g' /etc/apt/sources.list.d/ubuntu.sources
```

### Docker requires sudo

Add your user to the `docker` group (one-time setup):

```bash
sudo usermod -aG docker $USER
```

Log out and log back in, then you can run `docker` without `sudo`.

## 📝 Environment Variables

Preconfigured in the container:

- `PIPELINE_MX_DIR`: `/opt/pipeline_mx/install`
- `Pipeline_DIR`: `/opt/pipeline_mx/install/runtime/cmake`
- `LD_LIBRARY_PATH`: Pipeline.MX runtime + TBB libraries
- `PYTHONPATH`: Pipeline.MX Python bindings
- `PATH`: Pipeline.MX sample binaries
- `OPENVINO_TOKENIZERS_PATH`: Tokenizers extension

## 📄 License

Copyright (C) 2026 Intel Corporation  
SPDX-License-Identifier: Apache-2.0
