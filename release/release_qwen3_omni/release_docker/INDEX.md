# release_docker/ 文件索引

本目录包含 Pipeline.MX Qwen3-Omni Docker 镜像的所有构建文件和文档。

## 📋 文件清单

### 核心文件

| 文件 | 用途 | 说明 |
|------|------|------|
| `Dockerfile` | Docker镜像定义 | 优化的多层构建，支持Intel GPU/NPU |
| `.dockerignore` | 构建排除规则 | 排除Docker文件和模型目录 |
| `docker-build.sh` | 构建脚本 | 自动检测代理，启用BuildKit |
| `docker-run.sh` | 运行脚本 | 自动处理GID和模型挂载 |

### 文档文件

| 文件 | 内容 | 适用读者 |
|------|------|----------|
| **`SETUP_SUMMARY.md`** | **设置总结** | **快速参考（推荐）** |
| `README.Docker.md` | 使用文档 | 用户 |
| `README.md` | 快速开始 | 新用户 |
| `build_guide_skill.md` | 构建技能指南 | 开发者/DevOps |
| `VOLUME_MOUNT.md` | Volume挂载方案 | 高级用户 |

## 🚀 快速开始

### 首次使用

```bash
# 1. 阅读设置总结
cat SETUP_SUMMARY.md

# 2. 构建镜像
export http_proxy=http://proxy-shz.intel.com:912
export https_proxy=http://proxy-shz.intel.com:912
./docker-build.sh

# 3. 运行容器
./docker-run.sh
```

### 故障排查

1. **GPU不工作** → 查看 `SETUP_SUMMARY.md` "常见问题"章节
2. **构建失败** → 查看 `build_guide_skill.md` "故障排查"章节
3. **使用问题** → 查看 `README.Docker.md`

## 📚 文档导航

### 按角色

**新用户（第一次使用）**：
1. `README.md` - 快速开始
2. `SETUP_SUMMARY.md` - 了解整体架构
3. `README.Docker.md` - 详细使用说明

**开发者（需要修改）**：
1. `SETUP_SUMMARY.md` - 设计决策和架构
2. `build_guide_skill.md` - 构建技能和最佳实践
3. `Dockerfile` - 实际实现

**DevOps（CI/CD集成）**：
1. `docker-build.sh` - 构建脚本
2. `SETUP_SUMMARY.md` - 依赖清单
3. `build_guide_skill.md` - 缓存优化

### 按主题

**GPU支持**：
- `SETUP_SUMMARY.md` → "关键依赖清单"
- `build_guide_skill.md` → "实战案例"
- `README.Docker.md` → "验证 GPU/NPU 访问"

**性能优化**：
- `SETUP_SUMMARY.md` → "性能指标"
- `VOLUME_MOUNT.md` → "方案对比"
- `build_guide_skill.md` → "构建加速技巧"

**Ubuntu 24.04特殊说明**：
- `SETUP_SUMMARY.md` → "Ubuntu 24.04 兼容性"
- `build_guide_skill.md` → "实战案例"

## 🔧 常用命令

```bash
# 构建
./docker-build.sh

# 运行（自动配置）
./docker-run.sh

# 运行（自定义配置）
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --group-add $(getent group video | cut -d: -f3) \
  --group-add $(getent group render | cut -d: -f3) \
  -v $(pwd)/../Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  pipeline-mx-qwen3-omni:latest

# 交互式shell
./docker-run.sh /bin/bash

# 查看镜像
sudo docker images pipeline-mx-qwen3-omni:latest

# 查看镜像层
sudo docker history pipeline-mx-qwen3-omni:latest
```

## 📝 文件详细说明

### SETUP_SUMMARY.md （推荐首读）
完整的设置总结，包括：
- 最终文件结构
- 关键设计决策
- 快速开始指南
- 依赖清单
- 常见问题解决
- 性能指标
- 经验教训

### build_guide_skill.md （技能文档）
Docker构建最佳实践和技能，包括：
- 核心原则（层顺序、缓存优化）
- 实战案例（GPU问题调试全过程）
- 故障排查（网络、权限、依赖）
- 检查清单

### VOLUME_MOUNT.md （架构决策）
模型Volume Mount方案的详细说明：
- 方案对比（打包 vs 挂载）
- 实际效果数据
- 使用场景
- 实现细节

### README.Docker.md （使用手册）
完整的使用文档：
- 多种运行方式
- 高级用法
- 环境变量
- 故障排查
- 镜像导出/导入

## 🎯 推荐阅读路径

### 路径A：快速上手（10分钟）
1. `README.md` (2分钟)
2. `SETUP_SUMMARY.md` - "快速开始"章节 (3分钟)
3. 运行 `./docker-build.sh` 和 `./docker-run.sh` (5分钟)

### 路径B：深入理解（30分钟）
1. `SETUP_SUMMARY.md` 完整阅读 (10分钟)
2. `build_guide_skill.md` - "实战案例"章节 (10分钟)
3. `Dockerfile` 和脚本阅读 (10分钟)

### 路径C：问题排查（变长）
1. `SETUP_SUMMARY.md` - "常见问题"章节
2. `build_guide_skill.md` - "故障排查"章节
3. 根据具体问题查看相关文档

## 💡 提示

- 📌 所有文档都包含具体的命令和配置，可以直接复制使用
- 🔍 使用 `grep` 在文档中搜索关键词：`grep -r "GPU" *.md`
- 📝 遇到新问题？请更新 `SETUP_SUMMARY.md` 的"常见问题"章节

## 🔗 外部链接

- [Pipeline.MX 主项目](../../)
- [GPU安装skill](~/mygithub/frameworks.ai.openvino.llm.prc-skills/skills/install_intel_gpu_cm_env/)
- [Intel GPU PPA](https://launchpad.net/~kobuk-team/+archive/ubuntu/intel-graphics)

---

**维护**: Pipeline.MX Team  
**日期**: 2026-06-18  
**版本**: 1.0
