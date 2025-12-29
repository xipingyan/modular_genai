# Optimum intel 

Refer: 
[1]: https://github.com/openvinotoolkit/openvino_notebooks/pull/3194
[2]: https://github.com/openvino-dev-samples/openvino_notebooks/blob/zimage/notebooks/z-image-turbo/z-image-turbo.ipynb

#### Dependencies

```
python -m venv py_zimage
source py_zimage/bin/activate
pip install gradio>=4.19 torch==2.8 torchvision==0.23.0 nncf>=2.15.0 --extra-index-url https://download.pytorch.org/whl/cpu
pip install git+https://github.com/huggingface/diffusers
pip install git+https://github.com/openvino-dev-samples/optimum-intel.git@zimage
pip install openvino>=2025.4
```

#### Run

