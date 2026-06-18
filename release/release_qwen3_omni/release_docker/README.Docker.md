# Pipeline.MX Qwen3-Omni Docker 使用指南

这个目录包含 Pipeline.MX Qwen3-Omni 多模态推理的 Docker 构建文件。

## 📁 目录结构

```
release_qwen3_omni/
├── release_docker/          # Docker 构建文件（本目录）
│   ├── Dockerfile           # 优化的多层缓存 Dockerfile
│   ├── docker-build.sh      # 构建脚本（支持代理自动检测）
│   ├── .dockerignore        # 排除 Docker 文件
│   └── README.Docker.md     # 本文件
├── install/                 # Pipeline.MX 运行时 (~320MB)
├── Qwen3-Omni-4B-Instruct-multilingual-int4/  # 模型文件 (~8.6GB)
├── qwen3_omni/              # 测试数据
├── config_chat_cb.yaml      # Pipeline 配置
├── case1_comprehensive.json # 测试对话
└── run.sh                   # 运行脚本（host 和 Docker 都可用）
```

## 🚀 快速开始

### 1. 构建 Docker 镜像

从 `release_qwen3_omni` 目录运行：

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni

# 如果在 Intel 公司网络内，设置代理
export http_proxy=http://proxy-shz.intel.com:912
export https_proxy=http://proxy-shz.intel.com:912

# 运行构建脚本（自动检测代理）
./release_docker/docker-build.sh
```

或手动构建：

```bash
sudo docker build \
  --network=host \
  --build-arg http_proxy=http://proxy-shz.intel.com:912 \
  --build-arg https_proxy=http://proxy-shz.intel.com:912 \
  -f release_docker/Dockerfile \
  -t pipeline-mx-qwen3-omni:latest \
  .
```

**构建时间：**
- 首次构建：~5-8 分钟（下载依赖）
- 后续构建：~10-30 秒（使用缓存）

### 2. 运行 Docker 容器

**重要**：模型目录需要从主机挂载到容器（镜像不包含模型，减小体积）。

#### 方式 A：使用运行脚本（推荐，最简单）

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni
./release_docker/docker-run.sh
```

脚本会自动：
- ✅ 检查模型目录是否存在
- ✅ 挂载模型目录到容器
- ✅ 配置 GPU/NPU 设备
- ✅ 运行 pipeline_benchmark

#### 方式 B：手动运行（完整控制）

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni

# 获取宿主机的 video 和 render 组 GID
VIDEO_GID=$(getent group video | cut -d: -f3)
RENDER_GID=$(getent group render | cut -d: -f3)

sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add $VIDEO_GID \
  --group-add $RENDER_GID \
  -v $(pwd)/Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  pipeline-mx-qwen3-omni:latest
```

**重要说明**：
- ⚠️ 必须使用**数字GID**（不是组名），因为容器内的组GID可能与宿主机不同
- `-v` 参数挂载模型目录（`:ro` 表示只读）
- 宿主机常见GID：video=44, render=992（不同系统可能不同）

这会自动执行：
```bash
pipeline_benchmark config_chat_cb.yaml \
  --conversation case1_comprehensive.json \
  --warmup 0 --iter 1 --max-frames 12
```

#### 方式 C：进入容器运行 run.sh（交互式）

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni

sudo docker run -it --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add video \
  --group-add render \
  -v $(pwd)/Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  pipeline-mx-qwen3-omni:latest \
  /bin/bash
```

容器内（工作目录已经是 `/opt/pipeline_mx`）：

```bash
# 直接运行 run.sh
./run.sh

# 或手动运行
pipeline_benchmark config_chat_cb.yaml \
  --conversation case1_comprehensive.json \
  --warmup 0 --iter 1 --max-frames 12
```

#### 方式 D：只使用 iGPU（不使用 NPU）

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni

sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video \
  --group-add render \
  -v $(pwd)/Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  pipeline-mx-qwen3-omni:latest
```

#### 方式 E：使用不同的模型目录

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -v /path/to/your/model:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  pipeline-mx-qwen3-omni:latest
```

## 🎯 前提条件

- Docker 已安装
- Intel GPU（Arc, Iris Xe 或更新）
- Intel NPU（可选，用于 NPU 推理）
- 主机必须有 `/dev/dri`（iGPU）和 `/dev/accel/accel0`（NPU）设备
- Sudo 权限（或用户在 `docker` 组中）

## ⚡ 构建优化

Dockerfile 针对**最大缓存复用**进行了优化：

### 层缓存策略（从最少到最频繁修改）

1. **系统包** - 使用 BuildKit cache mount → 多次构建间共享 APT 缓存
2. **Intel GPU runtime** - 很少变化 → 始终缓存
3. **用户设置** - 从不变化 → 始终缓存
4. **install/ 目录** (~320MB) → 除非重新编译 Pipeline.MX
5. **模型目录** (~8.6GB) → 除非更换模型
6. **测试数据** (qwen3_omni/) → 除非更新测试文件
7. **配置文件** (YAML/JSON) → **快速重建**（修改配置时）

### 缓存效果

- **首次构建**: ~5-8 分钟（下载所有内容）
- **仅修改配置**: ~10-30 秒（只复制配置层）
- **更新测试数据**: ~1-2 分钟（复制测试数据 + 配置）
- **更换模型**: ~3-5 分钟（复制模型 + 测试数据 + 配置）
- **完全重建**: 只在 install/ 或系统包变化时

### 构建上下文优化

`.dockerignore` 文件排除 `release_docker/`，因此 Docker 相关文件不会触发不必要的重建。

## 🔧 高级用法

### 自定义配置

使用不同的 YAML 配置运行：

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -v $(pwd)/my_config.yaml:/opt/pipeline_mx/my_config.yaml \
  pipeline-mx-qwen3-omni:latest \
  pipeline_benchmark my_config.yaml --conversation case1_comprehensive.json
```

### 挂载自定义测试数据

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -v $(pwd)/my_test_data:/opt/pipeline_mx/my_test_data \
  pipeline-mx-qwen3-omni:latest \
  pipeline_benchmark config_chat_cb.yaml --conversation my_test_data/test.json
```

### 性能调优

启用性能指标输出：

```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  -e DUMP_PERFORMANCE=1 \
  -e OPENVINO_LOG_LEVEL=0 \
  pipeline-mx-qwen3-omni:latest
```

**推荐配置（精确性能测量）：**
```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add video --group-add render \
  -e DUMP_PERFORMANCE=1 \
  -e OPENVINO_LOG_LEVEL=0 \
  pipeline-mx-qwen3-omni:latest
```

这确保最小开销 - 只打印性能指标，没有调试日志。

### 交互式调试

探索容器内容：

```bash
sudo docker run -it --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  pipeline-mx-qwen3-omni:latest \
  /bin/bash
```

容器内，所有文件位于 `/opt/pipeline_mx/`：

```bash
ls -la /opt/pipeline_mx/
# install/  Qwen3-Omni-4B-Instruct-multilingual-int4/  qwen3_omni/
# config_chat_cb.yaml  case1_comprehensive.json  GoldenGate.png  run.sh

# 检查设备访问
ls -la /dev/dri/        # 应显示 card1, renderD128
ls -la /dev/accel/      # 应显示 accel0（如果有 NPU）

# 运行 benchmark
./run.sh
```

## 🔍 验证 GPU/NPU 访问

### 检查主机设备

```bash
# iGPU 设备
ls -la /dev/dri/
# 应显示: card1, renderD128

# NPU 设备
ls -la /dev/accel/
# 应显示: accel0

# GPU 硬件
lspci | grep -i "VGA\|display"
```

### 容器内验证

```bash
sudo docker run -it --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add video --group-add render \
  pipeline-mx-qwen3-omni:latest \
  /bin/bash

# 容器内：
ls -la /dev/dri/        # 应显示 card1, renderD128
ls -la /dev/accel/      # 应显示 accel0
id                      # 应显示 groups: video, render
```

## 📦 镜像信息

- **基础镜像**: Ubuntu 24.04
- **预期大小**: ~2-3GB（**不包含模型**）
  - 基础 OS + 依赖: ~1.5GB
  - Install 包: ~320MB
  - ~~Qwen3-Omni 模型: ~8.6GB~~（通过 volume 挂载）
- **架构**: x86_64 (intel64)
- **用户**: 非 root 用户 `pipelineuser` (UID 1000)
- **工作目录**: `/opt/pipeline_mx`
- **模型挂载**: `/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4` (需要运行时挂载)

## 🐛 故障排查

### /dev/dri 权限被拒绝

确保主机用户在 `video` 和 `render` 组中：

```bash
sudo usermod -aG video,render $USER
```

注销并重新登录以使更改生效。

### GPU 未检测到

**症状**：`Can't get PERFORMANCE_HINT property as no supported devices found`

**原因**：容器内用户无法访问 `/dev/dri` 设备（权限问题）

**解决方案**：使用正确的组GID

```bash
# 1. 检查宿主机设备的组ID
ls -ln /dev/dri/

# 输出示例：
# crw-rw----+ 1 0  44 226,   1 card1       (video GID=44)
# crw-rw----+ 1 0 992 226, 128 renderD128  (render GID=992)

# 2. 使用数字GID运行容器
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add 44 \
  --group-add 992 \
  ... 其他参数
```

或使用更新的 `docker-run.sh` 脚本（自动获取GID）。

**验证 GPU runtime**：

```bash
clinfo  # 应列出 Intel GPU 设备
```

如果 `clinfo` 不可用：
```bash
sudo apt install clinfo
```

### NPU 不可访问

检查主机上的 NPU 驱动安装：

```bash
ls -la /dev/accel/accel0
lspci | grep -i accelerator
```

### 构建失败（网络超时）

如果在 Intel 公司网络内，确保设置代理：

```bash
export http_proxy=http://proxy-shz.intel.com:912
export https_proxy=http://proxy-shz.intel.com:912
./release_docker/docker-build.sh
```

如果在 Intel 网络外，Dockerfile 会自动使用默认 Ubuntu 镜像（无需代理）。

### Docker 需要 sudo

一次性配置，将用户添加到 `docker` 组：

```bash
sudo usermod -aG docker $USER
```

注销并重新登录，然后可以无 sudo 运行 `docker` 命令。

### 容器内缺少共享库

Pipeline.MX install/ 目录已包含所有必要的 OpenVINO、genai 和 TBB 库。只有系统库（OpenCV、GStreamer）从 Ubuntu 包安装。

如果遇到 "library not found" 错误：
1. 检查 `LD_LIBRARY_PATH` 是否正确设置
2. 在容器内运行 `ldd /opt/pipeline_mx/install/samples/cpp/pipeline_benchmark`

## 📋 环境变量

容器中预配置的环境变量：

- `PIPELINE_MX_DIR`: `/opt/pipeline_mx/install`
- `Pipeline_DIR`: `/opt/pipeline_mx/install/runtime/cmake`
- `LD_LIBRARY_PATH`: Pipeline.MX runtime + TBB 库
- `PYTHONPATH`: Pipeline.MX Python 绑定
- `PATH`: Pipeline.MX 示例二进制文件
- `OPENVINO_TOKENIZERS_PATH`: Tokenizers 扩展

性能相关（可选）：
- `DUMP_PERFORMANCE`: 设置为 `1` 启用性能指标输出
- `OPENVINO_LOG_LEVEL`: 控制日志级别（0=OFF, 1=ERR, 2=WARN, 3=INFO, 4=DEBUG）

## 📚 更多信息

### 在容器内使用 Python API

```bash
sudo docker run -it --rm \
  --device /dev/dri:/dev/dri \
  --group-add video --group-add render \
  pipeline-mx-qwen3-omni:latest \
  python3 -c "import pipeline; print(pipeline.__version__)"
```

### 保存容器修改为新镜像

如果在容器内进行了修改并想保存：

```bash
# 1. 运行容器并进行修改
sudo docker run -it --name my-pipeline-test \
  --device /dev/dri:/dev/dri \
  pipeline-mx-qwen3-omni:latest /bin/bash

# 2. 在容器内进行修改...

# 3. 在另一个终端，提交更改
sudo docker commit my-pipeline-test pipeline-mx-qwen3-omni:custom

# 4. 清理
sudo docker rm my-pipeline-test
```

### 导出/导入镜像

导出镜像到 tar 文件（用于离线部署）：

```bash
sudo docker save pipeline-mx-qwen3-omni:latest | gzip > pipeline-mx-qwen3-omni.tar.gz
```

在另一台机器上导入：

```bash
gunzip -c pipeline-mx-qwen3-omni.tar.gz | sudo docker load
```

### 清理旧镜像

```bash
# 列出所有镜像
sudo docker images

# 删除旧镜像
sudo docker rmi <image-id>

# 清理悬空镜像
sudo docker image prune
```

## 📄 许可证

Copyright (C) 2026 Intel Corporation  
SPDX-License-Identifier: Apache-2.0

## 🤝 贡献

如有问题或改进建议，请在项目仓库中创建 issue。
