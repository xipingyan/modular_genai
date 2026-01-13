import argparse
import json
import PIL.Image
from optimum.intel import OVZImagePipeline
from diffusers.image_processor import VaeImageProcessor
from diffusers.pipelines.z_image.pipeline_z_image import calculate_shift, retrieve_timesteps
from openvino import Tensor
from typing import Callable, Dict, Any, List, Optional, Union
import torch
import inspect
import PIL
import openvino_genai
import yaml
import numpy as np
from tensor_utils import dump_tensor

class TestOVZImagePipeline(OVZImagePipeline):
    def set_callbacks(self, callbacks: Dict[str, Callable[..., Any]]) -> None:
        self.callbacks = callbacks

        if "text_encoder" in callbacks:
            original_encode_prompt = self.auto_model_class.encode_prompt
            def wrapped_encode_prompt(*args, **kwargs):
                return callbacks["text_encoder"](self, original_encode_prompt, *args, **kwargs)
            self.auto_model_class.encode_prompt = wrapped_encode_prompt

        if "vae_decoder" in callbacks:
            original_decode = self.vae.decode
            def wrapped_decode(*args, **kwargs):
                return callbacks["vae_decoder"](self, original_decode, *args, **kwargs)
            self.vae.decode = wrapped_decode

    @torch.no_grad()
    def __call__(
        self,
        prompt: str,
        height: Optional[int] = None,
        width: Optional[int] = None,
        num_inference_steps: int = 50,
        device: str = "CPU",
        negative_prompt: Optional[str] = None,
        guidance_scale: float = 5.0,
        cfg_normalization: bool = False,
        cfg_truncation: float = 1.0,
        num_images_per_prompt: Optional[int] = 1,
        max_sequence_length: int = 512,
        dump_input_output: bool = False) -> None:

        height = height or 512
        width = width or 512
        vae_scale = self.vae_scale_factor * 2
        batch_size = 1
        self.vae_scale_factor = (
            2 ** (len(self.vae.config.block_out_channels) - 1) if hasattr(self, "vae") and self.vae is not None else 8
        )
        self.scaling_factor = self.vae.config.scaling_factor
        self.shift_factor = self.vae.config.shift_factor
        self.image_processor = VaeImageProcessor(vae_scale_factor=self.vae_scale_factor * 2)
        self.dump_input_output = dump_input_output
        self.device_ = device
        if height % vae_scale != 0:
            raise ValueError(
                f"Height must be divisible by {vae_scale} (got {height}). "
                f"Please adjust the height to a multiple of {vae_scale}."
            )
        if width % vae_scale != 0:
            raise ValueError(
                f"Width must be divisible by {vae_scale} (got {width}). "
                f"Please adjust the width to a multiple of {vae_scale}."
            )
        
        # Text Encoder
        (prompt_embeds, negative_prompt_embeds) = self.auto_model_class.encode_prompt(
            self,
            prompt = prompt,
            negative_prompt = negative_prompt,
            do_classifier_free_guidance = guidance_scale > 1.0,
            device = "cpu",
            max_sequence_length = max_sequence_length)
                
        # Denoiser loop
        seed = 42
        num_channels_latents = self.transformer.in_channels
        latents = self.auto_model_class.prepare_latents(
            self,
            batch_size * num_images_per_prompt,
            num_channels_latents,
            height,
            width,
            torch.float32,
            "cpu",
            torch.Generator(device="cpu").manual_seed(seed))
        original_latents = latents.clone()
                        
        if num_images_per_prompt > 1:
            prompt_embeds = [pe for pe in prompt_embeds for _ in range(num_images_per_prompt)]
            if guidance_scale > 1.0 and negative_prompt_embeds:
                negative_prompt_embeds = [npe for npe in negative_prompt_embeds for _ in range(num_images_per_prompt)]

        actual_batch_size = batch_size * num_images_per_prompt
        image_seq_len = (latents.shape[2] // 2) * (latents.shape[3] // 2)
        mu = calculate_shift(
            image_seq_len,
            self.scheduler.config.get("base_image_seq_len", 256),
            self.scheduler.config.get("max_image_seq_len", 4096),
            self.scheduler.config.get("base_shift", 0.5),
            self.scheduler.config.get("max_shift", 1.15),
        )
        self.scheduler.sigma_min = 0.0
        scheduler_kwargs = {"mu": mu}
        timesteps, num_inference_steps = retrieve_timesteps(
            self.scheduler,
            num_inference_steps,
            "cpu",
            sigmas=None,
            **scheduler_kwargs,
        )
        self._num_timesteps = len(timesteps)

        for i, t in enumerate(timesteps):
            # broadcast to batch dimension in a way that's compatible with ONNX/Core ML
            timestep = t.expand(latents.shape[0])
            timestep = (1000 - timestep) / 1000
            # Normalized time for time-aware config (0 at start, 1 at end)
            t_norm = timestep[0].item()

            # Handle cfg truncation
            current_guidance_scale = guidance_scale
            if (
                guidance_scale > 1.0
                and cfg_truncation is not None
                and float(cfg_truncation) <= 1
            ):
                if t_norm > cfg_truncation:
                    current_guidance_scale = 0.0

            # Run CFG only if configured AND scale is non-zero
            apply_cfg = guidance_scale > 1.0 and current_guidance_scale > 0

            if apply_cfg:
                latents_typed = latents.to(self.transformer.dtype)
                latent_model_input = latents_typed.repeat(2, 1, 1, 1)
                prompt_embeds_model_input = prompt_embeds + negative_prompt_embeds
                timestep_model_input = timestep.repeat(2)
            else:
                latent_model_input = latents.to(self.transformer.dtype)
                prompt_embeds_model_input = prompt_embeds
                timestep_model_input = timestep

            latent_model_input = latent_model_input.unsqueeze(2)
            latent_model_input_list = list(latent_model_input.unbind(dim=0))

            model_out_list = self.transformer(
                latent_model_input_list, timestep_model_input, prompt_embeds_model_input, return_dict=False
            )[0]

            if apply_cfg:
                # Perform CFG
                pos_out = model_out_list[:actual_batch_size]
                neg_out = model_out_list[actual_batch_size:]

                noise_pred = []
                for j in range(actual_batch_size):
                    pos = pos_out[j].float()
                    neg = neg_out[j].float()

                    pred = pos + current_guidance_scale * (pos - neg)

                    # Renormalization
                    if cfg_normalization and float(cfg_normalization) > 0.0:
                        ori_pos_norm = torch.linalg.vector_norm(pos)
                        new_pos_norm = torch.linalg.vector_norm(pred)
                        max_new_norm = ori_pos_norm * float(cfg_normalization)
                        if new_pos_norm > max_new_norm:
                            pred = pred * (max_new_norm / new_pos_norm)

                    noise_pred.append(pred)

                noise_pred = torch.stack(noise_pred, dim=0)
            else:
                noise_pred = torch.stack([t.float() for t in model_out_list], dim=0)

            noise_pred = noise_pred.squeeze(2)
            noise_pred = -noise_pred

            # compute the previous noisy sample x_t -> x_t-1
            latents = self.scheduler.step(noise_pred.to(torch.float32), t, latents, return_dict=False)[0]
            assert latents.dtype == torch.float32
        
        if self.callbacks is not None and "denoiser_loop" in self.callbacks:
            self.callbacks["denoiser_loop"](
                self,
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

        # VAE Decode
        latents = latents.to(self.vae.dtype)
        latents = (latents / self.vae.config.scaling_factor) + self.vae.config.shift_factor

        image = self.vae.decode(latents, return_dict=False)[0]
        # image = image_processor.postprocess(image, output_type="numpy")


        # pil_image = image_processor.numpy_to_pil(image)
        # pil_image[0].save("zimage_output.png")

    def set_model_path(self, model_path: str) -> None:
        self.model_path = model_path

    def set_device(self, device: str) -> None:
        self.device_ = device

def text_encoder_wrapper(
        obj,
        original_encode_prompt,
        *args, **kwargs):
    print("Text Encoder:")
    (prompt_embeds, negative_prompt_embeds) = original_encode_prompt(*args, **kwargs)
    # TODO: Add module pipeline result check
    if obj.dump_input_output == True or obj.dump_input_output == "True":
        dump_tensor(prompt_embeds[0], "text_encoder_output_prompt_embeds")

    cfg = {
        'global_context': {
            'model_type': 'zimage'
        },
        'pipeline_modules': {
            'text_encoder': {
                'type': 'ClipTextEncoderModule',
                'device': obj.device_,
                'description': 'Encode positive prompt and negative prompt',
                'inputs': [
                    {
                        'name': 'prompt',
                        'type': 'String'
                    },
                    {
                        'name': 'guidance_scale',
                        'type': 'Float'
                    },
                    {
                        'name': 'max_sequence_length',
                        'type': 'Int'
                    }
                ],
                'outputs': [
                    {
                        'name': 'prompt_embeds',
                        'type': 'VecOVTensor'
                    }
                ],
                'params': {
                    'model_path': obj.model_path,
                }
            }
        }
    }

    module_pipeline = openvino_genai.ModulePipeline(config_yaml_content=yaml.dump(cfg))
    module_pipeline.generate(
        prompt=kwargs['prompt'],
        guidance_scale= 1.0 if kwargs['do_classifier_free_guidance'] else 0.0,
        max_sequence_length=kwargs['max_sequence_length'])
    module_output = torch.from_numpy(module_pipeline.get_output("prompt_embeds")[0].data)
    print("    Result check:", "PASS" if torch.allclose(prompt_embeds[0], module_output, atol=1e-5) else "FAIL")

    return prompt_embeds, negative_prompt_embeds

def denoiser_loop_callback(
        obj,
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
        'global_context': {
            'model_type': 'zimage'
        },
        'pipeline_modules': {
            'denoiser_loop': {
                'type': 'ZImageDenoiserLoopModule',
                'device': obj.device_,
                'description': 'Z-Image denoiser loop.',
                'inputs': [
                    {
                        'name': 'latents',
                        'type': 'OVTensor',
                        'source': "pipeline_params.latents"
                    },
                    {
                        'name': 'prompt_embed',
                        'type': 'OVTensor',
                        'source': "pipeline_params.prompt_embed"
                    },
                    {
                        'name': 'num_inference_steps',
                        'type': 'Int',
                        'source': "pipeline_params.num_inference_steps"
                    },
                    {
                        'name': 'guidance_scale',
                        'type': 'Float',
                        'source': "pipeline_params.guidance_scale"
                    }
                ],
                'outputs': [
                    {
                        'name': 'latents',
                        'type': 'OVTensor'
                    }
                ],
                'params': {
                    'model_path': args.model_path
                }
            }
        }
    }

    if obj.dump_input_output == True or obj.dump_input_output == "True":
        dump_tensor(prompt_embeds[0], "denoiser_loop_input_prompt_embed")
        dump_tensor(init_latents, "denoiser_loop_input_init_latents")
        dump_tensor(latents, "denoiser_loop_output_latents")

    module_pipeline = openvino_genai.ModulePipeline(config_yaml_content=yaml.dump(cfg))
    module_pipeline.generate(
        latents=Tensor(init_latents.detach().cpu().contiguous().numpy()),
        prompt_embed=Tensor(prompt_embeds[0].detach().cpu().contiguous().numpy()),
        num_inference_steps=num_inference_steps,
        guidance_scale=guidance_scale)
    module_output = torch.from_numpy(module_pipeline.get_output("latents").data)
    print("    Result check:", "PASS" if torch.allclose(latents, module_output, atol=1e-5) else "FAIL")

def vae_decoder_wrapper(
        obj,
        original_vae_decode,
        *args, **kwargs):
    print("VAE Decoder:")
    latents = args[0].clone()
    latents = (latents + obj.shift_factor) / obj.scaling_factor
    image = original_vae_decode(latents, **kwargs)[0]

    if obj.dump_input_output == True or obj.dump_input_output == "True":
        dump_tensor(latents, "vae_decoder_input_latents")
        dump_tensor(image, "vae_decoder_output_image")

    cfg = {
        'global_context': {
            'model_type': 'zimage'
        },
        'pipeline_modules': {
            'vae_decoder': {
                'type': 'VAEDecoderModule',
                'device': obj.device_,
                'description': 'VAE image decoder.',
                'inputs': [
                    {
                        'name': 'latents',
                        'type': 'OVTensor',
                        'source': "pipeline_params.latents"
                    }
                ],
                'outputs': [
                    {
                        'name': 'image',
                        'type': 'OVTensor'
                    }
                ],
                'params': {
                    'model_path': obj.model_path,
                    'enable_postprocess': 'true'
                }
            }
        }
    }

    module_pipeline = openvino_genai.ModulePipeline(config_yaml_content=yaml.dump(cfg))
    module_pipeline.generate(
        latents=Tensor(args[0].detach().cpu().contiguous().numpy()))
    module_output = torch.from_numpy(module_pipeline.get_output("image").data).to(torch.uint8)
    image = torch.from_numpy(np.array(obj.image_processor.postprocess(image, output_type="pil")))

    print("    Result check:", "PASS" if torch.allclose(image.float(), module_output.float(), atol=10) else "FAIL")
    return image

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('model_path', default="../../../openvino.genai/samples/cpp/module_genai/ut_pipelines/Z-Image-Turbo-fp16-ov", help="Path to the directory of z image model")
    parser.add_argument("device", default="CPU", help="Device to use")
    parser.add_argument("dump_input_output", default=False, help="Dump input/output tensors of each module")
    args = parser.parse_args()
    pipeline = TestOVZImagePipeline.from_pretrained(
        args.model_path,
        device=args.device,
        ov_config={})
    
    callbacks = {
        "text_encoder": text_encoder_wrapper,
        "denoiser_loop": denoiser_loop_callback,
        "vae_decoder": vae_decoder_wrapper
    }

    pipeline.set_callbacks(callbacks)
    pipeline.set_model_path(args.model_path)
    pipeline.set_device(args.device)

    pipeline(
        prompt="A beautiful landscape painting of mountains during sunset",
        height=128,
        width=128,
        num_inference_steps=2,
        device=args.device,
        guidance_scale=0.0,
        dump_input_output=args.dump_input_output)

