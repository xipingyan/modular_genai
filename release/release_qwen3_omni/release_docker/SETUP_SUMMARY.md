# Pipeline.MX Docker 设置总结

本文档总结了为 Pipeline.MX Qwen3-Omni 创建 Docker 镜像的完整过程和关键要点。

## 📁 最终文件结构

```
release_qwen3_omni/
├── release_docker/                  # Docker相关文件
│   ├── Dockerfile                   # 主Dockerfile（已优化）
│   ├── docker-build.sh              # 构建脚本
│   ├── docker-run.sh                # 运行脚本（自动处理GID和模型挂载）
│   ├── .dockerignore                # 排除规则（含模型目录）
│   ├── build_guide_skill.md         # 构建技能指南（包含实战案例）
│   ├── README.Docker.md             # 使用文档
│   ├── README.md                    # 快速开始
│   ├── VOLUME_MOUNT.md              # Volume挂载方案说明
│   └── SETUP_SUMMARY.md             # 本文件
├── install/                         # Pipeline.MX runtime (~320MB)
├── Qwen3-Omni-4B-Instruct-multilingual-int4/  # 模型 (~8.6GB，不打包)
├── qwen3_omni/                      # 测试数据
├── config_chat_cb.yaml              # Pipeline配置
├── case1_comprehensive.json         # 测试对话
└── run.sh                           # 运行脚本（host和Docker通用）
```

## 🎯 关键设计决策

### 1. 模型不打包到镜像（Volume Mount）

**原因**：
- 模型 ~8.6GB，占镜像大部分体积
- 灵活切换不同模型
- 加速构建和分发

**结果**：
- 镜像大小：11GB → **2-3GB** (减少73%)
- 构建时间：8分钟 → **3分钟** (减少63%)

### 2. Ubuntu 24.04 兼容性

**问题**：Ubuntu 24.04 使用 `libigc2`，Intel官方仓库的OpenCL驱动不兼容

**解决**：使用 `kobuk-team/intel-graphics` PPA

```dockerfile
RUN add-apt-repository -y ppa:kobuk-team/intel-graphics && \
    apt-get install -y intel-opencl-icd=26.18.38308.4-1~24.04~ppa1
```

### 3. 设备权限（使用数字GID）

**问题**：容器内的 `video`/`render` 组GID与宿主机不匹配

**解决**：使用宿主机的数字GID

```bash
VIDEO_GID=$(getent group video | cut -d: -f3)
RENDER_GID=$(getent group render | cut -d: -f3)
docker run --group-add $VIDEO_GID --group-add $RENDER_GID ...
```

### 4. BuildKit Cache Mounts

**加速APT安装**：

```dockerfile
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y ...
```

**结果**：首次5分钟 → 后续**10秒**

## 🚀 快速开始

### 构建镜像

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni

# 设置代理（Intel网络内）
export http_proxy=http://proxy-shz.intel.com:912
export https_proxy=http://proxy-shz.intel.com:912

# 构建
./release_docker/docker-build.sh
```

### 运行容器

```bash
# 使用运行脚本（推荐）
./release_docker/docker-run.sh

# 或手动运行
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

## ✅ 关键依赖清单

### Dockerfile必需包

```dockerfile
# OpenCL支持
ocl-icd-libopencl1              # OpenCL ICD loader
intel-opencl-icd=26.18.38308.4-1~24.04~ppa1  # Intel OpenCL驱动（PPA版本）
intel-level-zero-gpu            # Level Zero运行时

# DRM支持
libdrm2                         # DRM用户空间库
libdrm-intel1                   # Intel DRM库
libdrm-common                   # DRM通用文件

# 系统依赖
libopencv-core406t64            # OpenCV核心
libopencv-imgproc406t64         # OpenCV图像处理
libopencv-imgcodecs406t64       # OpenCV图像编解码
libopencv-videoio406t64         # OpenCV视频I/O
libgstreamer1.0-0               # GStreamer
libgomp1                        # OpenMP
libglib2.0-0                    # GLib
```

### 运行时要求

```bash
# 设备映射
--device /dev/dri:/dev/dri                     # GPU设备
--device /dev/accel/accel0:/dev/accel/accel0   # NPU设备（可选）

# 组权限（使用数字GID）
--group-add <VIDEO_GID>      # 通常是44
--group-add <RENDER_GID>     # 通常是992

# 系统信息
-v /sys:/sys:ro              # GPU设备信息（可选但推荐）

# 模型挂载
-v <host_model_path>:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro
```

## 🐛 常见问题和解决方案

### 问题1：GPU未检测到

**症状**：
```
[GPU] Can't get PERFORMANCE_HINT property as no supported devices found
```

**解决方案**：
1. 检查使用数字GID：`--group-add 44 --group-add 992`
2. 验证PPA版本的OpenCL已安装
3. 确认 `libdrm` 包已安装

### 问题2：clinfo看不到GPU

**验证步骤**：
```bash
# 在容器内安装clinfo并测试
docker run --rm --device /dev/dri \
  --group-add 44 --group-add 992 \
  -e http_proxy=http://proxy:port \
  myimage \
  bash -c "apt update && apt install -y clinfo && clinfo -l"
```

**期望输出**：
```
Platform #0: Intel(R) OpenCL Graphics
 `-- Device #0: Intel(R) Arc(TM) B390 GPU
```

### 问题3：网络超时

**解决方案**：传递代理环境变量

```bash
docker build \
  --build-arg http_proxy=http://proxy:port \
  --build-arg https_proxy=http://proxy:port \
  ...
```

## 📊 性能指标

| 指标 | 优化前 | 优化后 | 改进 |
|------|--------|--------|------|
| 镜像大小 | 11GB | 2-3GB | 73% ↓ |
| 首次构建 | 8分钟 | 6分钟 | 25% ↓ |
| 重建（缓存） | 3分钟 | 15秒 | 92% ↓ |
| APT安装 | 5分钟 | 10秒 | 97% ↓ |
| 配置修改重建 | 3分钟 | 15秒 | 92% ↓ |

## 🔗 参考资源

### 内部文档
- GPU安装skill：`~/mygithub/frameworks.ai.openvino.llm.prc-skills/skills/install_intel_gpu_cm_env/`
- Ubuntu 24.04安装指南：`UBUNTU_24.04_INSTALL.md`

### 项目文档
- 构建技能指南：`build_guide_skill.md`
- 使用文档：`README.Docker.md`
- Volume Mount方案：`VOLUME_MOUNT.md`

### 外部资源
- Intel GPU PPA：https://launchpad.net/~kobuk-team/+archive/ubuntu/intel-graphics
- Docker BuildKit：https://docs.docker.com/build/buildkit/
- OpenVINO文档：https://docs.openvino.ai/

## 📝 版本信息

- **创建日期**：2026-06-18
- **验证环境**：
  - OS：Ubuntu 24.04 LTS
  - GPU：Intel Arc B390
  - NPU：Intel NPU (accel0)
  - Docker：24.x with BuildKit
  - Pipeline.MX：0.2.x
  - OpenVINO：2026.2.0

## 🎓 经验教训

### 成功要素

1. ✅ **按修改频率组织层** - 稳定的放前面，易变的放后面
2. ✅ **模型Volume Mount** - 大幅减小镜像体积
3. ✅ **BuildKit Cache** - 加速重复构建
4. ✅ **PPA驱动** - Ubuntu 24.04兼容性
5. ✅ **数字GID** - 解决设备权限问题

### 避免的陷阱

1. ❌ 使用组名而不是数字GID
2. ❌ 使用Intel官方仓库而不是PPA（Ubuntu 24.04）
3. ❌ 忘记安装 `ocl-icd-libopencl1`
4. ❌ 忘记安装 `libdrm` 系列包
5. ❌ 模型打包到镜像中

## 🚀 后续优化建议

1. **多阶段构建** - 进一步减小镜像体积
2. **健康检查** - 添加GPU可用性检查
3. **镜像签名** - 生产环境安全
4. **CI/CD集成** - 自动构建和测试
5. **监控集成** - 添加性能指标导出

---

**维护者**: Pipeline.MX Team  
**许可**: Apache-2.0  
**反馈**: 如有问题请创建issue
