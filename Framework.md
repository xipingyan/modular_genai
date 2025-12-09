# Framework

设计将遵循以下原则：<br>
模块化: 将整个pipeline拆分成多个模块，模块参数可配，同类型算法，尽量放到一个模块中，例如：图像预处理，图像ebmedding，prompt embedding，特征处理，特征合并，LLM等。  <br>
配置驱动: 可以配置每个模块的参数，可以通过配置搭建pipeline。    <br>
GPU内存共享: 使用gpu时，尽量使用remote tensor，减少cpu/gpu之间的copy。  <br>
高性能: 不同模块之间，是否可以并行。    <br>

#### 模块化

基类
```
class IBaseModule {
public:
    virtual ~IBaseModule() = default;
    
    // initialize 
    virtual bool initialize(...) = 0;
    
    virtual void run(inputs, outputs) = 0;
};
```

图像预处理
```
class ImagePreprocessModule : public IBaseModule {
public:    
    void run(inputs, outputs) override;
};
```

Pipeline:
```
class PipelineExecutor {
private:
    std::unordered_map<std::string, std::unique_ptr<IBaseModule>> modules_;
    
    // dependencies
    std::map<std::string, std::vector<std::string>> dependencies_;
    
public:
    PipelineExecutor(const std::string& config_path);

    ModuleOutput run(const std::string& module_name, const ModuleInput& input) {
        for(;;) {
            ...
        }
    }
};
```

配置驱动
```
// 模块配置示例（JSON格式）
{
    "pipeline": {
        "modules": ["text_embed", "image_preprocess", "llm"],
        "execution_order": "parallel",
        "batch_size": 32
    },
    
    "modules": {
        "text_embed": {
            "type": "clip_text",
            "model_path": "./models/clip_text.xml",
            "device": "GPU.1",
            "precision": "FP16",
            "max_seq_length": 77,
            "gpu_memory": {
                "input_buffer": "shared",
                "output_buffer": "shared",
                "cache_size": 1024
            }
        },
        
        "image_preprocess": {
            "type": "resize_normalize",
            "target_size": [224, 224],
            "mean": [0.485, 0.456, 0.406],
            "std": [0.229, 0.224, 0.225],
            "gpu_accelerated": true
        },
        
        "llm": {
            "type": "llama2",
            "model_path": "./models/llama2.xml",
            "device": "GPU.0",
            "context_window": 4096,
            "kv_cache": true,
            "streaming": true,
            "gpu_memory": {
                "kv_cache_shared": true,
                "beam_search": 4
            }
        }
    },
    
    "gpu_context": {
        "shared_memory_pool": true,
        "devices": ["GPU.0", "GPU.1"],
        "memory_allocator": "caching",
        "interop": {
            "opengl": false,
            "directx": true
        }
    }
}
```

GPU内存共享:  TBD   <br>
高性能:  TBD        <br>