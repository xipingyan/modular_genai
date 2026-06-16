# python3 -m venv python-env
# pip install transformers openvino-tokenizers

source python-env/bin/activate
source ./install/setupvars.sh
config_yaml=./Gemma4/config_modeling_text_img_audio_cb_st.yaml

# ================ prompt + image case ================
# image=./GoldenGate.png
# prompt_image="What is shown in this image?"
# ./install/samples/cpp/yaml_pipeline_sample $config_yaml "image=$image" "prompt=$prompt_image"

# ================ prompt + audio case ================
# # audio_prompt="Transcribe the following speech segment in its original language. Follow these specific instructions for formatting the answer:\n* Only output the transcription, with no newlines.\n* When transcribing numbers, write the digits, i.e. write 1.7 and not one point seven, and write 3 instead of three."
# audio_prompt="Transcribe the following speech segment in its original language."
# audio=./journal1.wav
# ./install/samples/cpp/yaml_pipeline_sample $config_yaml "audio=$audio" "prompt=$audio_prompt"

# ================ prompt only ================
prompt="How do black holes work?"
./install/samples/cpp/yaml_pipeline_sample $config_yaml "prompt=$prompt"