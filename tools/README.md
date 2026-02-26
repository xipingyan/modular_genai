# README

Some tool scripts

#### test_transformer_splitted.py

验证split的transformer模型与原始的模型相比，是否能得到一样的结果。

```
cp test_transformer_splitted.py ../openvino.genai/tests/module_genai/cpp/test_models/Wan2.1-T2V-1.3B-Diffusers/
cd ../openvino.genai/tests/module_genai/cpp/test_models/Wan2.1-T2V-1.3B-Diffusers/

python test_transformer_splitted.py --ir-dir ./transformer_splitted/ --device GPU
python test_transformer_splitted.py --ir-dir ./transformer_merged/ --device GPU
```

#### reduce_split_num.py

合并transformer中的一些被split的模型，对于wan2.1网络。

```
cp reduce_split_num.py ../openvino.genai/tests/module_genai/cpp/test_models/Wan2.1-T2V-1.3B-Diffusers/reduce_split_num.py
cd ../openvino.genai/tests/module_genai/cpp/test_models/Wan2.1-T2V-1.3B-Diffusers/
python reduce_split_num.py
```