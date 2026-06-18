# Docker 构建技能指南 (Build Skills)

这份文档总结了构建高效、可维护的 Docker 镜像的最佳实践和技能，基于 Pipeline.MX Qwen3-Omni 项目的实际经验。

## 📋 目录

- [核心原则](#核心原则)
- [层缓存优化](#层缓存优化)
- [网络与代理配置](#网络与代理配置)
- [用户与权限管理](#用户与权限管理)
- [构建加速技巧](#构建加速技巧)
- [目录组织](#目录组织)
- [故障排查](#故障排查)

---

## 核心原则

### 1. 层顺序：从稳定到易变

按照修改频率组织 Dockerfile 层，将最不常变化的放在前面：

```dockerfile
# ✅ 正确顺序（从稳定到易变）
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y ...    # Layer 1: 系统依赖（很少变）
COPY install/ ./install/                         # Layer 2: 编译产物（偶尔变）
COPY models/ ./models/                           # Layer 3: 模型（偶尔变）
COPY config.yaml ./                              # Layer 4: 配置（经常变）

# ❌ 错误顺序
COPY config.yaml ./                              # 配置在前 → 每次修改都重建所有层
COPY models/ ./models/
RUN apt-get install ...
```

**为什么？**
- Docker 从第一个改变的层开始重建
- 稳定层在前 = 更多缓存命中 = 更快构建

### 2. 层数优化：合并 vs 分离

**合并原则**：相关且同时变化的操作
```dockerfile
# ✅ 合并：同时安装所有系统包
RUN apt-get update && apt-get install -y \
    libopencv-core406t64 \
    libopencv-imgproc406t64 \
    libgstreamer1.0-0 \
    && rm -rf /var/lib/apt/lists/*
```

**分离原则**：独立且变化频率不同的操作
```dockerfile
# ✅ 分离：Intel GPU runtime 独立一层（很少更新）
RUN apt-get install -y intel-opencl-icd intel-level-zero-gpu

# ✅ 分离：应用代码独立一层（频繁更新）
COPY app/ ./app/
```

### 3. 最小化层大小

```dockerfile
# ✅ 清理 APT 缓存
RUN apt-get update && apt-get install -y wget \
    && rm -rf /var/lib/apt/lists/*

# ✅ 清理构建工件
RUN make build && make install && make clean

# ❌ 分层清理无效（前面的层已经包含了缓存）
RUN apt-get install -y wget
RUN rm -rf /var/lib/apt/lists/*  # 不会减小镜像大小！
```

---

## 层缓存优化

### 1. BuildKit Cache Mounts（推荐）

最强大的缓存技术 - APT 缓存在多次构建间持久化：

```dockerfile
# ✅ 使用 cache mount
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    libopencv-core406t64 \
    libgstreamer1.0-0

# 效果：
# - 首次构建：正常下载包（~5 分钟）
# - 第二次构建：使用缓存（~10 秒）✨
# - 即使修改 Dockerfile：包缓存仍然保留
```

**关键点**：
- `sharing=locked`：防止并发构建冲突
- 不需要 `rm -rf /var/lib/apt/lists/*`（cache mount 自动管理）
- 需要启用 BuildKit：`export DOCKER_BUILDKIT=1`

### 2. 多阶段构建

分离构建环境和运行环境：

```dockerfile
# ❌ 单阶段：构建工具进入最终镜像
FROM ubuntu:24.04
RUN apt-get install -y gcc make cmake  # 运行时不需要
COPY src/ ./
RUN make build
CMD ["./app"]

# ✅ 多阶段：只保留运行时必需的
FROM ubuntu:24.04 AS builder
RUN apt-get install -y gcc make cmake
COPY src/ ./
RUN make build

FROM ubuntu:24.04
COPY --from=builder /app/build/app /usr/local/bin/
CMD ["app"]
```

### 3. COPY 顺序优化

```dockerfile
# ❌ 一次性复制所有代码
COPY . /app/

# ✅ 先复制依赖文件，再复制代码
COPY requirements.txt /app/
RUN pip install -r requirements.txt  # 缓存层
COPY src/ /app/src/                  # 代码变化不影响依赖层
```

### 4. .dockerignore

排除不必要的文件，减小构建上下文：

```
# .dockerignore
.git/
*.log
__pycache__/
node_modules/
*.tmp
release_docker/    # 排除 Docker 相关文件本身
```

---

## 网络与代理配置

### 1. 代理处理

支持企业代理环境：

```dockerfile
# Dockerfile
ARG http_proxy
ARG https_proxy
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
```

```bash
# 构建脚本自动检测
PROXY_ARGS=""
if [ -n "${http_proxy:-}" ]; then
    PROXY_ARGS="--build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy"
fi

docker build $PROXY_ARGS -t myimage .
```

### 2. 网络模式

```bash
# ✅ host 网络：绕过 Docker bridge 的网络问题
docker build --network=host -t myimage .

# ⚠️ 注意：仅构建时使用，运行时仍然独立网络
```

### 3. 镜像源配置

**方案 A：动态镜像（仅在需要时）**
```dockerfile
# 仅在特定地区需要时取消注释
# RUN sed -i 's@archive.ubuntu.com@mirrors.aliyun.com@g' /etc/apt/sources.list.d/ubuntu.sources
```

**方案 B：构建参数**
```dockerfile
ARG APT_MIRROR=archive.ubuntu.com
RUN sed -i "s@archive.ubuntu.com@${APT_MIRROR}@g" /etc/apt/sources.list.d/ubuntu.sources
```

```bash
docker build --build-arg APT_MIRROR=mirrors.aliyun.com -t myimage .
```

---

## 用户与权限管理

### 1. 非 root 用户（安全最佳实践）

```dockerfile
# ✅ 创建非 root 用户
RUN groupadd -r appuser && \
    useradd -r -g appuser appuser

USER appuser
WORKDIR /home/appuser
```

### 2. 处理 GPU/设备访问

```dockerfile
# ✅ 预先创建设备组
RUN groupadd -r render || true && \
    groupadd -r video || true && \
    useradd -m -u 1000 -g appuser -G video,render appuser

# 运行时映射设备
# docker run --device /dev/dri --group-add video --group-add render
```

### 3. 处理已存在的 UID/GID

```dockerfile
# ✅ 容错处理
RUN groupadd -f -g 1000 appuser || true && \
    useradd -m -u 1000 -g 1000 appuser 2>/dev/null || \
    (id -u 1000 >/dev/null 2>&1 && usermod -a -G video,render $(id -un 1000) || true)
```

### 4. 文件所有权

```dockerfile
# ✅ 在 COPY 时设置所有权（最高效）
COPY --chown=appuser:appuser app/ /opt/app/

# ❌ 先复制后修改（额外的层）
COPY app/ /opt/app/
RUN chown -R appuser:appuser /opt/app/
```

---

## 构建加速技巧

### 1. 并行下载

```dockerfile
# ✅ APT 并行下载
RUN echo 'Acquire::Queue-Mode "host"; Acquire::http::Pipeline-Depth "5";' \
    > /etc/apt/apt.conf.d/99parallel

RUN apt-get update && apt-get install -y ...
```

### 2. 减少 RUN 层数

```dockerfile
# ❌ 多个 RUN（多层，慢）
RUN apt-get update
RUN apt-get install -y pkg1
RUN apt-get install -y pkg2

# ✅ 合并 RUN（单层，快）
RUN apt-get update && apt-get install -y \
    pkg1 \
    pkg2
```

### 3. 使用特定的基础镜像标签

```dockerfile
# ❌ latest 标签（不可预测，破坏缓存）
FROM ubuntu:latest

# ✅ 具体版本（稳定，缓存友好）
FROM ubuntu:24.04
```

### 4. 本地构建缓存

```bash
# 启用 inline cache
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t myimage .

# 从注册表拉取作为缓存
docker pull myregistry/myimage:latest
docker build --cache-from myregistry/myimage:latest -t myimage .
```

---

## 目录组织

### 推荐结构

```
project_root/
├── release_docker/              # Docker 相关文件（独立目录）
│   ├── Dockerfile               # 主 Dockerfile
│   ├── Dockerfile.offline       # 离线构建版本（可选）
│   ├── docker-build.sh          # 构建脚本
│   ├── .dockerignore            # 排除规则
│   ├── BUILD_GUIDE.md           # 本文件
│   └── README.Docker.md         # 使用文档
├── app/                         # 应用代码
├── models/                      # 模型文件（大文件）
├── config/                      # 配置文件（小文件，频繁改）
└── run.sh                       # 运行脚本
```

### 为什么分离 release_docker/？

1. **清晰分离**：Docker 文件不干扰应用代码
2. **缓存优化**：`.dockerignore` 排除 `release_docker/` 避免触发重建
3. **版本控制**：易于管理多个 Dockerfile 变体

---

## 故障排查

### 1. 网络超时

**症状**：`Could not connect to archive.ubuntu.com`

**解决方案**：
```bash
# 方案 A：使用代理
export http_proxy=http://proxy-server:port
docker build --network=host --build-arg http_proxy=$http_proxy .

# 方案 B：使用镜像源
# 在 Dockerfile 中添加：
RUN sed -i 's@archive.ubuntu.com@mirrors.aliyun.com@g' /etc/apt/sources.list.d/ubuntu.sources
```

### 2. 组/用户冲突

**症状**：`groupadd: GID '1000' already exists`

**解决方案**：
```dockerfile
RUN groupadd -f -g 1000 mygroup || true
```

### 3. 依赖安装慢

**症状**：APT 安装需要 5 分钟

**解决方案**：
```dockerfile
# 使用 BuildKit cache mount
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y ...
```

### 4. 缓存未命中

**症状**：每次构建都从头开始

**检查清单**：
- 文件时间戳是否改变？（即使内容相同）
- COPY 是否包含了不必要的文件？（使用 `.dockerignore`）
- 前面的层是否有变化？（一层变化，后续全部重建）

---

## 实战示例：Pipeline.MX Dockerfile

### 最终优化版本

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Layer 1: 系统依赖（BuildKit cache mount 加速）
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg ca-certificates \
    libopencv-core406t64 libopencv-imgproc406t64 \
    libgstreamer1.0-0 libgomp1 libglib2.0-0

# Layer 2: Intel GPU runtime（独立层，很少变化）
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
    gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] \
    https://repositories.intel.com/gpu/ubuntu noble client" | \
    tee /etc/apt/sources.list.d/intel-graphics.list && \
    apt-get update && apt-get install -y intel-opencl-icd

# Layer 3: 用户设置（容错处理）
RUN groupadd -r render || true && \
    groupadd -r video || true && \
    useradd -m -u 1000 -g 1000 -G video,render appuser && \
    mkdir -p /opt/app && chown -R 1000:1000 /opt/app

WORKDIR /opt/app

# Layer 4-7: 应用文件（按变化频率排序）
COPY --chown=appuser:appuser install/ ./install/
COPY --chown=appuser:appuser models/ ./models/
COPY --chown=appuser:appuser data/ ./data/
COPY --chown=appuser:appuser config.yaml ./

USER appuser

ENV LD_LIBRARY_PATH=/opt/app/install/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/app/install/bin:${PATH}

CMD ["./run.sh"]
```

### 构建脚本

```bash
#!/bin/bash
set -e

# 自动检测代理
PROXY_ARGS=""
if [ -n "${http_proxy:-}" ]; then
    echo "📡 Using proxy: $http_proxy"
    PROXY_ARGS="--build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy"
fi

# 启用 BuildKit
export DOCKER_BUILDKIT=1

# 构建
sudo docker build \
    --network=host \
    --progress=plain \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    $PROXY_ARGS \
    -f release_docker/Dockerfile \
    -t myapp:latest \
    .

echo "✅ Build completed!"
```

---

## 性能指标

基于 Pipeline.MX 项目的实际测试：

| 场景 | 优化前 | 优化后 | 改进 |
|------|--------|--------|------|
| 首次构建 | 8 分钟 | 6 分钟 | 25% ↓ |
| 修改配置重建 | 3 分钟 | 15 秒 | **92% ↓** |
| APT 包安装 | 5 分钟 | 10 秒 | **97% ↓** |
| 重新运行相同构建 | 2 分钟 | 5 秒 | **96% ↓** |

**关键技术**：
- BuildKit cache mounts → APT 加速 97%
- 层顺序优化 → 配置修改加速 92%
- 合并层 + .dockerignore → 上下文减小 50%

---

## 检查清单

构建高质量 Docker 镜像的检查清单：

### 🎯 必须做
- [ ] 使用具体版本的基础镜像（不用 `latest`）
- [ ] 按修改频率排序层（稳定 → 易变）
- [ ] 使用 `.dockerignore` 排除不必要文件
- [ ] 非 root 用户运行（安全）
- [ ] 清理 APT 缓存（减小镜像）

### ⚡ 建议做
- [ ] 使用 BuildKit cache mounts（APT 加速）
- [ ] 支持代理自动检测（企业环境）
- [ ] 合并相关的 RUN 命令（减少层数）
- [ ] 使用 `--chown` 在 COPY 时设置所有权
- [ ] 多阶段构建（分离构建/运行环境）

### 🚀 可选做
- [ ] 并行 APT 下载配置
- [ ] 离线构建版本（air-gapped 环境）
- [ ] Health check（生产环境）
- [ ] 镜像签名（安全要求）

---

## 参考资源

### Docker 官方文档
- [Dockerfile 最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [BuildKit](https://docs.docker.com/build/buildkit/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)

### 工具
- `docker build --progress=plain` - 显示详细构建日志
- `docker history <image>` - 查看镜像层历史
- `docker image inspect <image>` - 检查镜像元数据
- `dive <image>` - 分析镜像层大小（第三方工具）

---

## 总结

**三个核心原则**：

1. **缓存友好**：稳定的在前，易变的在后
2. **网络容错**：支持代理，使用 cache mount
3. **安全最小化**：非 root 用户，清理不必要文件

**一个黄金法则**：

> 每次修改 Dockerfile，问自己："这会破坏多少层的缓存？"

遵循这些原则，你的 Docker 构建将：
- ✅ 快速（缓存命中率高）
- ✅ 稳定（网络容错）
- ✅ 安全（最小权限）
- ✅ 可维护（清晰的层结构）

---

## 🎓 实战案例：Pipeline.MX + Intel GPU (Ubuntu 24.04)

基于实际构建 Pipeline.MX Docker 镜像的经验总结。

### 问题：OpenVINO无法检测到Intel GPU

**症状**：
```
[GPU] Can't get PERFORMANCE_HINT property as no supported devices found
```

**调试过程**：

1. **检查权限** ✅ 
   - `--device /dev/dri` 正确映射
   - `--group-add 44 --group-add 992` (使用数字GID，不是组名)
   - 设备可读可写

2. **检查OpenCL ICD Loader** ❌
   - **问题**：缺少 `ocl-icd-libopencl1` 包
   - **修复**：添加到Dockerfile
   ```dockerfile
   RUN apt-get install -y ocl-icd-libopencl1
   ```

3. **检查DRM库** ❌
   - **问题**：缺少 `libdrm2`, `libdrm-intel1`
   - **修复**：添加到Dockerfile
   ```dockerfile
   RUN apt-get install -y libdrm2 libdrm-intel1 libdrm-common
   ```

4. **检查OpenCL驱动版本** ❌ **（关键问题）**
   - **问题**：Ubuntu 24.04 使用 `libigc2`，Intel官方仓库的包可能不兼容
   - **发现**：宿主机使用PPA版本 `intel-opencl-icd=26.18.38308.4-1~24.04~ppa1`
   - **修复**：使用 `kobuk-team/intel-graphics` PPA
   ```dockerfile
   RUN add-apt-repository -y ppa:kobuk-team/intel-graphics && \
       apt-get install -y intel-opencl-icd=26.18.38308.4-1~24.04~ppa1
   ```

### 最终Dockerfile关键配置

```dockerfile
FROM ubuntu:24.04

# 1. 安装OpenCL ICD Loader和DRM库
RUN apt-get update && apt-get install -y \
    ocl-icd-libopencl1 \
    libdrm2 \
    libdrm-intel1 \
    libdrm-common

# 2. 使用PPA安装Intel GPU驱动（Ubuntu 24.04兼容）
RUN apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:kobuk-team/intel-graphics && \
    apt-get update && \
    apt-get install -y \
    intel-opencl-icd=26.18.38308.4-1~24.04~ppa1 \
    intel-level-zero-gpu

# 3. 创建用户组（处理已存在的GID）
RUN groupadd -r render 2>/dev/null || true && \
    groupadd -r video 2>/dev/null || true && \
    useradd -m -u 1000 -g 1000 -G video,render pipelineuser
```

### 运行时配置

**关键点**：使用**数字GID**而不是组名

```bash
# 获取宿主机的GID
VIDEO_GID=$(getent group video | cut -d: -f3)    # 通常是 44
RENDER_GID=$(getent group render | cut -d: -f3)  # 通常是 992

# 运行容器
docker run \
  --device /dev/dri:/dev/dri \
  --group-add $VIDEO_GID \
  --group-add $RENDER_GID \
  -v /sys:/sys:ro \
  myimage
```

**为什么不能用组名？**
- 容器内的 `video`/`render` 组的GID可能与宿主机不同
- 设备文件 `/dev/dri/*` 的GID是宿主机的值
- 必须使用宿主机的GID才能访问设备

### 验证步骤

```bash
# 1. 验证镜像包含正确的包
docker run --rm myimage dpkg -l | grep -E 'ocl-icd|intel-opencl|libdrm'

# 2. 验证容器内能看到设备
docker run --rm --device /dev/dri myimage ls -la /dev/dri/

# 3. 验证OpenCL能检测到GPU（需要代理）
docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add 44 --group-add 992 \
  -e http_proxy=http://proxy:port \
  myimage \
  bash -c "apt-get update && apt-get install -y clinfo && clinfo -l"

# 期望输出：
# Platform #0: Intel(R) OpenCL Graphics
#  `-- Device #0: Intel(R) Arc(TM) B390 GPU
```

### Ubuntu 24.04 特殊注意事项

| 组件 | Ubuntu 22.04 | Ubuntu 24.04 | 注意 |
|------|--------------|--------------|------|
| libigc | libigc1 | libigc2 | **不兼容** |
| OpenCL源 | Intel官方仓库 | PPA (kobuk-team) | **必须用PPA** |
| intel-opencl-icd | 25.x | 26.18.38308.4-1~24.04~ppa1 | **指定版本** |

**参考**：`~/mygithub/frameworks.ai.openvino.llm.prc-skills/skills/install_intel_gpu_cm_env/UBUNTU_24.04_INSTALL.md`

### 性能优化建议

1. **模型使用Volume Mount**（不打包到镜像）
   - 镜像大小：11GB → 2-3GB
   - 构建时间：8分钟 → 3分钟
   - 灵活切换不同模型

2. **BuildKit Cache Mounts**
   ```dockerfile
   RUN --mount=type=cache,target=/var/cache/apt \
       apt-get update && apt-get install -y ...
   ```
   - APT安装：5分钟 → 10秒（第二次）

3. **代理配置**
   ```bash
   docker build \
     --build-arg http_proxy=http://proxy:port \
     --build-arg https_proxy=http://proxy:port \
     ...
   ```

---

**最后更新**: 2026-06-18  
**作者**: Pipeline.MX Team  
**许可**: Apache-2.0  
**验证环境**: Ubuntu 24.04, Intel Arc B390 GPU, Pipeline.MX 0.2.x
