import torch
import numpy as np
import json
import os


def dump_tensor(tensor: torch.Tensor, file_name: str) -> None:
    if not os.path.exists("data"):
        os.makedirs("data")
    tensor = tensor.detach().cpu().contiguous()
    tensor.numpy().tofile(f"data/{file_name}.bin")
    meta_data = {
        "dtype": str(tensor.dtype),
        "shape": list(tensor.shape)
    }
    with open(f"data/{file_name}.json", "w") as f:
        json.dump(meta_data, f)