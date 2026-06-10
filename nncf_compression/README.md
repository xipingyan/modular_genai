# 安装依赖
pip install -r requirements.txt

# 运行压缩

./compress.sh input_model.xml output_model_int4.xml

# 或指定模式

./compress.sh input_model.xml output_model_int4.xml --mode INT4_ASYM