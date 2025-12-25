export HF_ENDPOINT=https://hf-mirror.com

model_id="Tongyi-MAI/Z-Image-Turbo"
huggingface-cli download --resume-download $model_id --local-dir $model_id --token YOUR_HUGGINGFACE_TOKEN