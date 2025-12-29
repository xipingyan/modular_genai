# README

# Download zimage OV model

```
source ../../../../../python-env/bin/activate
pip install modelscope
cd ../openvino.genai/samples/cpp/module_genai/ut_pipelines/
modelscope download --model snake7gun/Z-Image-Turbo-fp16-ov --local_dir ./
```

#### optimum_ov

Test z-image based on optimum-intel. ModulePipeline will follow this branch to implement z-image.

Refer: optimum_ov/README.md

#### pytorch_tiling

Test tiling feature based on pytorch original model.