# modular_genai
This is a POC of modular GenAI. The purpose is fast and easy to enable new model to GenAI.


# Setup

```
<!-- OV -->
git clone https://github.com/openvinotoolkit/openvino.git --branch 2025.4.0
cd openvino && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=install ..
make -j20 && make install

<!-- OR download 2025.4 -->
wget https://storage.openvinotoolkit.org/repositories/openvino/packages/2025.4/linux/openvino_toolkit_ubuntu22_2025.4.0.20398.8fdad55727d_x86_64.tgz
tar -xf openvino_toolkit_ubuntu22_2025.4.0.20398.8fdad55727d_x86_64.tgz

<!-- Update source_ov.sh based on your OV. -->
```

Build GenAI
```
./build_genai.sh
```
