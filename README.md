# modular_genai
This is a POC of modular GenAI. The purpose is fast and easy to enable new model to GenAI.


# Convert model
Dependencies:
```
pip install openvino-tokenizers openvino nncf optimum[intel]
pip install -U huggingface_hub
```

```
model_id='Qwen/Qwen2.5-VL-3B-Instruct'
optimum-cli export openvino --model $model_id --task image-text-to-text $model_id/INT4 --weight-format int4 --trust-remote-code
```

# Setup

VENV:
```
python -m venv python-env
source python-env/bin/activate
pip install numpy
```

```
<!-- OV -->
git clone https://github.com/openvinotoolkit/openvino.git --branch 2025.4.0
cd openvino && mkdir build && cd build
git submodule update --init
cmake -DCMAKE_INSTALL_PREFIX=install ..
make -j20 && make install

<!-- OR download 2025.4 (default) -->
wget https://storage.openvinotoolkit.org/repositories/openvino/packages/2025.4/linux/openvino_toolkit_ubuntu22_2025.4.0.20398.8fdad55727d_x86_64.tgz
tar -xf openvino_toolkit_ubuntu22_2025.4.0.20398.8fdad55727d_x86_64.tgz

<!-- Update source_ov.sh based on your OV. -->
```

Build GenAI
```
sudo apt-get install libyaml-cpp-dev

git clone https://github.com/xipingyan/openvino.genai.git
cd openvino.genai
git checkout -b xp/modular_genai remotes/origin/xp/modular_genai
git submodule update --init
../build_genai.sh
```
