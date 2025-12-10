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
# ----------------------------------------------------------------------
# 全局配置 (GLOBAL CONFIGURATION) 待定，是否需要。
# ----------------------------------------------------------------------
global_context:
  default_device: "GPU"
  enable_shared_memory: True
  device_id: "GPU.0"

# ----------------------------------------------------------------------
# 模块定义 (MODULES DEFINITION) - 修正了 YAML 引用和参数格式
# ----------------------------------------------------------------------
pipeline_modules:

  # --- 0. Parameter 模块 ---
  prompts:
    type: "ParameterModule"
    outputs:
      - name: "prompts_data"
        type: "std::vector<std::string>"

  image:
    type: "ParameterModule"
    outputs:
      - name: "image1_data"
        type: "ov::Tensor"
      - name: "image2_data"
        type: "ov::Tensor"

  # --- 1. 图像预处理模块 (Image Preprocessing) ---
  image_preprocessor:
    type: "ImagePreprocessModule"
    device: "CPU"
    inputs:
      - name: "image_input_1"
        source: "image.image1_data"
      - name: "image_input_2"
        source: "image.image2_data"
    outputs:
      - name: "raw_data"
        type: "ov::Tensor"
      - name: "thw"
        type: "ov::Tensor"
    params:
      target_resolution: [224, 224]
      mean: [0.485, 0.456, 0.406]
      std: [0.229, 0.224, 0.225]

  # --- 2. 图像 Embedding 模块 (Image Embedding) ---
  image_encoder:
    type: "ImageEncoderModule"
    device: "GPU"
    inputs:
      - name: "image_input"
        source: "image_preprocessor.raw_data"
    outputs:
      - name: "image_embedding"
        type: "ov::RemoteTensor" # 图像 Embedding
      - name: "position_ids"
        type: "ov::Tensor"
    params:
      model_path: "models/vision_encoder.xml"
      input_name: "pixel_values"

  # --- 3. Prompt Embedding 模块 (Text Embedding) ---
  prompt_encoder:
    type: "TextEncoderModule"
    device: "GPU"
    inputs:
      - name: "prompts"
        source: "prompts.prompts_data"
    outputs:
      - name: "prompt_embedding"
        type: "ov::RemoteTensor" # Prompt Embedding
      - name: "mask"
        type: "ov::RemoteTensor"
    params:
      model_path: "models/text_encoder.xml"

  # --- 4. 特征修剪模块 (Feature Pruning) ---
  feature_pruner:
    type: "FeaturePrunerModule"
    description: "Prunes/Aligns image features based on textual context (prompt)."
    device: "GPU"
    inputs:
      - name: "image_features_in"
        source: "image_encoder.image_embedding"
      - name: "text_context_in"
        source: "prompt_encoder.prompt_embedding"
    outputs:
      - name: "pruned_image_embedding"
        type: "ov::RemoteTensor"
    params:
      model_path: "models/pruner_qformer.xml"
      pruning_ratio: 0.5 # 示例参数

  # --- 5. 特征合并模块 (Feature Fusion/Concatenation) ---
  feature_merger:
    type: "FeatureFusionModule"
    device: "CPU"
    inputs:
      - name: "text_feature"
        source: "prompt_encoder.prompt_embedding"
      - name: "image_feature"
        source: "feature_pruner.pruned_image_embedding"
    outputs:
      - name: "merged_input_embedding"
        type: "ov::Tensor"
    params:
      template: "template file or from xml"

  # --- 6. LLM 推理模块 (LLM Inference) ---
  llm_generator:
    type: "LLMInferenceModule"
    device: "GPU"
    inputs:
      - name: "context_embedding"
        source: "feature_merger.merged_input_embedding"
      - name: "attention_mask"
        source: "prompt_encoder.mask"
      - name: "position_ids"
        source: "image_encoder.position_ids"
    outputs:
      - name: "generated_tokens"
        type: "std::vector<int>"
      - name: "final_result_text"
        type: "std::string"
    params:
      model_path: "models/llm_7b_ov.xml"
      max_new_tokens: 256

  # --- 7. Result 模块 (结果整合和输出) ---
  pipeline_result:
    type: "ResultModule"
    description: "Collects final results and formats the output structure."
    device: "CPU"
    inputs:
      - name: "final_text"
        source: "llm_generator.final_result_text"
      - name: "token_sequence"
        source: "llm_generator.generated_tokens"
    outputs:
      - name: "text"
        type: "std::string"
      - name: "perf"
        type: "json"
    params:
      response_schema: "v1.0.0"
```
需要提供一个python脚本，将pipeline转换成pdf的graph显示，并简单校验链接关系。


GPU内存共享:  TBD   <br>
高性能:  TBD        <br>