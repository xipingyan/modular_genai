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

```bash
python3 -m venv python-env
source python-env/bin/activate
pip install transformers openvino-tokenizers

./run.sh
```

#### Run example

Build and run the simple C++ example:

```bash
cd example

# Build the example
./build.sh

# Run the example with test cases
cd ..
./example/run_example.sh

# Or run manually with custom prompt
source ./install/setupvars.sh
./example/build/simple_pipeline ./Gemma4/config_modeling_text_img_audio_cb_st.yaml "prompt=How do black holes work?"
```
