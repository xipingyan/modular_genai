# Z Image Test Enabling Guide

## Optimum-Intel Model Inference

In Optimum-Intel, the Z-Image model is inferenced by `OVZImagePipeline`. In `OVZImagePipeline`, the `OVModelTextEncoder` is used to encode prompts, the `OVModelTransformer` is used in denoising loop and the `OVModelVaeDecoder` is used to do vae decoding.

The `auto_model_class` of `OVZImagePipeline` is `ZImagePipeline`. This class is implemented in `diffusers` library. `OVZImagePipeline` will pass `OVModelTextEncoder`, `OVModelTransformer` and `OVModelVaeDecoder` to `ZImagePipeline`. The actual model inferring happens in `ZImagePipeline`.

When `ZImagePipeline` is inferring, firstly, `encode_prompt` is called to encode prompts and generates position prompts embeds and negative prompts embeds. Then, the transformer is used to denoise with generated prompts embeds. Finally, the vae decoder is called to decode the output of transformer and generates the output image.

## Test Class Structure

To check the accuracy of our module, we need to get the inputs and outputs of all according parts in `ZImagePipeline`. Some wrappers and callbacks are needed to add to `ZImagePipeline`.

Firstly, the test class is extended from Optimum-Intel class `OVZImagePipeline`. Then, we add some wrapper functions and callback functions to get related inputs and outputs.

### Prompts Encoding

The prompts encoding is done by `encode_prompt`, so defining a wrapper function and replace the `encode_prompt` of `ZImagePipeline` can get the required inputs and outputs.

```python
def text_encoder_wrapper(
        original_encode_prompt,
        *args, **kwargs):
    print("Text Encoder:")
    (prompt_embeds, negative_prompt_embeds) = original_encode_prompt(*args, **kwargs)
    # TODO: Add module pipeline result check
    return prompt_embeds, negative_prompt_embeds

original_encode_prompt = self.auto_model_class.encode_prompt
def wrapped_encode_prompt(*args, **kwargs):
    return text_encoder_wrapper(original_encode_prompt, *args, **kwargs)
self.auto_model_class.encode_prompt = wrapped_encode_prompt
```

To check the accuracy of prompts encoder, we need to add module pipeline which only contains encoder module and pass all inputs to encoder module and get outputs. Then, the outputs of module pipeline can be compared with the outputs of `ZImagePipeline`.

### Denoiser Loop

The denoiser Loop in `ZImagePipeline` is a series of code. Since it is not implemented in one function, we can not use the wrapper function. A callback function is needed to be inserted to the end of the denoiser loop in `ZImagePipeline`. In the callback function, all required inputs and the outputs of `ZImagePipeline` can be captured and used to check accuracy of module pipeline.

```python
def denoiser_loop_callback(
        prompt_embeds: List[torch.FloatTensor],
        negative_prompt_embeds: Optional[List[torch.FloatTensor]],
        latents: torch.FloatTensor,
        init_latents: torch.FloatTensor,
        width: int,
        height: int,
        num_inference_steps: int,
        num_images_per_prompt: int,
        seed: int,
        guidance_scale: float) -> None:
    print("Denoiser Loop:")

    cfg = {
        ...
    }
    module_pipeline = openvino_genai.ModulePipeline(config_yaml_content=yaml.dump(cfg))
    module_pipeline.generate(
        prompt_embed=Tensor(prompt_embeds[0].detach().cpu().contiguous().numpy()),
        width=width,
        height=height,
        num_inference_steps=num_inference_steps,
        num_images_per_prompt=num_images_per_prompt,
        seed=seed,
        guidance_scale=guidance_scale,
        init_latents=init_latents)
    module_output = torch.from_numpy(module_pipeline.get_output("latents").data)
    print("    Result check:", "PASS" if torch.allclose(latents, module_output, atol=1e-5) else "FAIL")


# In ZImagePipeline
denoiser_loop_callback(
    prompt_embeds, 
    negative_prompt_embeds,
    latents,
    original_latents,
    width=width,
    height=height,
    num_inference_steps=num_inference_steps,
    num_images_per_prompt=num_images_per_prompt,
    seed=seed,
    guidance_scale=guidance_scale)

```

### VAE Decoder

In `ZImagePipeline`, the VAE decoder operation is implemented in the `decode` method of VAE decoder. So the implementation of VAE decoder accuracy check is the same as prompts encoder.

## Test Usage:
```bash
bash run_test_z_image_pipeline.sh
```
The output:
```
Text Encoder:
Denoiser Loop:
    Result check: PASS
VAE Decoder:
    Result check: PASS
```
