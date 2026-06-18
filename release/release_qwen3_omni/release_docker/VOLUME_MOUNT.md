# Docker Volume Mount 方案说明

## 📋 方案对比

### 方案 A：模型打包到镜像（旧方案）

```dockerfile
COPY Qwen3-Omni-4B-Instruct-multilingual-int4/ ./Qwen3-Omni-4B-Instruct-multilingual-int4/
```

**优点**：
- ✅ 开箱即用，无需额外配置
- ✅ 镜像包含所有内容

**缺点**：
- ❌ 镜像体积巨大（~11GB）
- ❌ 每次构建都复制 8.6GB 模型（慢）
- ❌ 无法灵活切换模型
- ❌ 推送/拉取镜像耗时（传输 11GB）
- ❌ 占用大量镜像存储空间

### 方案 B：模型运行时挂载（新方案，**推荐**）

```dockerfile
RUN mkdir -p /opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4
```

```bash
docker run -v $(pwd)/model:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro ...
```

**优点**：
- ✅ 镜像体积小（~2-3GB，减少 **73%**）
- ✅ 构建速度快（无需复制模型）
- ✅ 灵活切换不同模型
- ✅ 推送/拉取镜像快
- ✅ 节省存储空间
- ✅ 多个容器可共享同一模型（只读挂载）

**缺点**：
- ⚠️ 需要在运行时指定模型路径（已通过脚本简化）

---

## 🎯 实际效果

| 指标 | 方案 A（打包） | 方案 B（挂载） | 改进 |
|------|---------------|---------------|------|
| 镜像大小 | ~11GB | ~2-3GB | **73% ↓** |
| 构建时间 | ~8 分钟 | ~3 分钟 | **63% ↓** |
| 推送/拉取时间 | ~10-20 分钟 | ~2-3 分钟 | **85% ↓** |
| 存储占用 | 每个版本 11GB | 2-3GB + 模型共享 | **节省大量空间** |
| 模型切换 | 需要重建镜像 | 挂载不同目录 | **秒级切换** |

---

## 💡 使用场景

### 场景 1：开发测试

```bash
# 使用本地模型
cd ~/mygithub/modular_genai/release/release_qwen3_omni
./release_docker/docker-run.sh
```

### 场景 2：切换不同模型

```bash
# 测试 int4 模型
docker run -v /models/qwen3-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro ...

# 测试 int8 模型
docker run -v /models/qwen3-int8:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro ...
```

### 场景 3：生产部署

```bash
# 模型存储在共享 NFS 上
docker run -v /nfs/shared/models/qwen3:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro ...
```

### 场景 4：CI/CD

```bash
# 镜像小，快速推送到 registry
docker push myregistry/pipeline-mx:latest  # 只需传输 2-3GB

# 模型单独管理，无需每次构建
```

---

## 🔧 实现细节

### Dockerfile 变化

**之前**：
```dockerfile
COPY --chown=pipelineuser:pipelineuser Qwen3-Omni-4B-Instruct-multilingual-int4/ ./Qwen3-Omni-4B-Instruct-multilingual-int4/
```

**现在**：
```dockerfile
# 创建挂载点目录
RUN mkdir -p /opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4 && \
    chown -R pipelineuser:pipelineuser /opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4
```

### .dockerignore 变化

**新增**：
```
# 排除大模型目录（运行时挂载）
Qwen3-Omni-4B-Instruct-multilingual-int4/
```

### 运行脚本

提供 `docker-run.sh` 简化挂载：

```bash
#!/bin/bash
MODEL_DIR="$PARENT_DIR/Qwen3-Omni-4B-Instruct-multilingual-int4"

sudo docker run --rm -it \
    --device /dev/dri:/dev/dri \
    --device /dev/accel/accel0:/dev/accel/accel0 \
    --group-add video \
    --group-add render \
    -v "$MODEL_DIR:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro" \
    pipeline-mx-qwen3-omni:latest
```

---

## 🚀 迁移步骤

### 1. 重新构建镜像

```bash
cd ~/mygithub/modular_genai/release/release_qwen3_omni

# 设置代理（如需要）
export http_proxy=http://proxy-shz.intel.com:912
export https_proxy=http://proxy-shz.intel.com:912

# 构建新镜像（不包含模型）
./release_docker/docker-build.sh
```

**预期效果**：
- 构建时间：~3 分钟（vs 之前 ~8 分钟）
- 镜像大小：~2-3GB（vs 之前 ~11GB）

### 2. 使用新的运行方式

**方式 A：使用脚本（推荐）**
```bash
./release_docker/docker-run.sh
```

**方式 B：手动指定**
```bash
sudo docker run --rm \
  --device /dev/dri:/dev/dri \
  --device /dev/accel/accel0:/dev/accel/accel0 \
  --group-add video --group-add render \
  -v $(pwd)/Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  pipeline-mx-qwen3-omni:latest
```

### 3. 清理旧镜像（可选）

```bash
# 查看所有镜像
sudo docker images

# 删除旧的大镜像
sudo docker rmi <old-image-id>

# 清理悬空镜像
sudo docker image prune
```

---

## ⚠️ 注意事项

### 1. 模型路径必须正确

容器内固定路径：`/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4`

挂载时确保主机路径正确：
```bash
# ✅ 正确
-v /path/to/model:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro

# ❌ 错误（容器内路径不匹配）
-v /path/to/model:/opt/models:ro
```

### 2. 只读挂载（推荐）

使用 `:ro` 标志防止容器修改模型：
```bash
-v /path/to/model:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro
                                                                             ^^^
```

### 3. 文件权限

如果遇到权限问题：
```bash
# 检查模型目录权限
ls -la Qwen3-Omni-4B-Instruct-multilingual-int4/

# 如需要，调整权限（容器内用户 UID 是 1000）
sudo chown -R 1000:1000 Qwen3-Omni-4B-Instruct-multilingual-int4/
```

### 4. 相对路径 vs 绝对路径

```bash
# ✅ 推荐：使用绝对路径
-v /home/user/models/qwen3:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro

# ✅ 或使用 $(pwd)
-v $(pwd)/Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro

# ❌ 避免相对路径（可能不工作）
-v ./model:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro
```

---

## 📚 最佳实践

### 1. 模型集中管理

```
/data/models/
├── qwen3-omni-int4/        # 8.6GB
├── qwen3-omni-int8/        # 更大
└── qwen3-omni-fp16/        # 最大
```

不同容器挂载不同模型，节省空间。

### 2. 配置文件也可以挂载

```bash
docker run \
  -v $(pwd)/Qwen3-Omni-4B-Instruct-multilingual-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro \
  -v $(pwd)/my_config.yaml:/opt/pipeline_mx/config_chat_cb.yaml:ro \
  pipeline-mx-qwen3-omni:latest
```

### 3. 结合 docker-compose

```yaml
version: '3'
services:
  pipeline:
    image: pipeline-mx-qwen3-omni:latest
    devices:
      - /dev/dri:/dev/dri
      - /dev/accel/accel0:/dev/accel/accel0
    group_add:
      - video
      - render
    volumes:
      - /data/models/qwen3-int4:/opt/pipeline_mx/Qwen3-Omni-4B-Instruct-multilingual-int4:ro
```

---

## 🎓 总结

**Volume mount 方案**是 Docker 最佳实践：

1. **镜像轻量化** - 只包含代码和依赖，不包含数据
2. **灵活性** - 运行时决定使用哪个模型
3. **效率** - 构建快、分发快、存储省
4. **可维护性** - 模型和代码独立管理

对于大模型场景（~8.6GB），volume mount 是**唯一合理的选择**。

---

**最后更新**: 2026-06-18  
**作者**: Pipeline.MX Team  
**许可**: Apache-2.0
