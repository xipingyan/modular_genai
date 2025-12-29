
from optimum.intel import OVZImagePipeline
import torch

use_quantized_models=False
device="GPU"
model_dir = "../../openvino.genai/samples/cpp/module_genai/ut_pipelines/Z-Image-Turbo-fp16-ov"

ov_pipe = OVZImagePipeline.from_pretrained(model_dir, device=device, ov_config={"ACTIVATIONS_SCALE_FACTOR": 128.0,} if device == "GPU" else {})

prompt = "Young Chinese woman in red Hanfu, intricate embroidery. Impeccable makeup, red floral forehead pattern. Elaborate high bun, golden phoenix headdress, red flowers, beads. Holds round folding fan with lady, trees, bird. Neon lightning-bolt lamp (⚡️), bright yellow glow, above extended left palm. Soft-lit outdoor night background, silhouetted tiered pagoda (西安大雁塔), blurred colorful distant lights."

image = ov_pipe(
    prompt=prompt,
    height=512,
    width=512,
    num_inference_steps=9,  # This actually results in 8 DiT forwards
    guidance_scale=0.0,  # Guidance should be 0 for the Turbo models
    generator=torch.Generator("cpu").manual_seed(42),
).images[0]

image.save("z_image_output.png")