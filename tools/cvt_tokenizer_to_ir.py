# ===============================
# python -m venv cvt_env
# source cvt_env/bin/activate
# uv pip install transformers openvino openvino_tokenizers
# ===============================

from transformers import AutoTokenizer
from openvino_tokenizers import convert_tokenizer
from openvino import save_model

def z_img_tokenizer_convert_tokenizer(model_dir_str, tokenizer_path_str, detokenizer_path_str):
    t = AutoTokenizer.from_pretrained(model_dir_str)
    tok, detok = convert_tokenizer(t, with_detokenizer=True)
    save_model(tok, tokenizer_path_str)
    save_model(detok, detokenizer_path_str)
    print('Tokenizer conversion successful')

if __name__ == "__main__":
    # model_dir_str = "openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/tokenizer/"
    model_dir_str = "./"
    tokenizer_path_str = "openvino_tokenizer.xml"
    detokenizer_path_str = "openvino_detokenizer.xml"
    
    z_img_tokenizer_convert_tokenizer(model_dir_str, tokenizer_path_str, detokenizer_path_str)