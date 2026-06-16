# How to run

#### Dependency

transformers openvino-tokenizers    <br>

Download https://huggingface.co/google/gemma-4-12B-it <br>

```
wget https://raw.githubusercontent.com/google-gemma/cookbook/refs/heads/main/apps/sample-data/GoldenGate.png
wget https://raw.githubusercontent.com/google-gemma/cookbook/refs/heads/main/apps/sample-data/journal1.wav

copy pipeline.mx's install package to .\install
```

#### Run sample from pipeline.mx

```
python3 -m venv python-env
source python-env/bin/activate
pip install transformers openvino-tokenizers

./run.sh
```