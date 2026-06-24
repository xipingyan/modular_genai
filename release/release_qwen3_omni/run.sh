# python3 -m venv python-env
# pip install transformers openvino-tokenizers

source ./install/setupvars.sh
config_yaml=./config_chat_cb.yaml

chat_json=./case1_comprehensive.json
echo "===> Running benchmark with conversation: ${chat_json}"
pipeline_benchmark $config_yaml --conversation "$chat_json" --warmup 0 --iter 1 --max-frames 12
