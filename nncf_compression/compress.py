#!/usr/bin/env python3
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

import argparse
from pathlib import Path

import openvino as ov
from nncf import compress_weights, CompressWeightsMode


def main():
    parser = argparse.ArgumentParser(description="Compress OpenVINO IR model to INT4 using NNCF")
    parser.add_argument("input", type=Path, help="Path to input OpenVINO IR model (.xml)")
    parser.add_argument("output", type=Path, help="Path to save compressed model (.xml)")
    parser.add_argument("--mode", type=str, default="INT4_SYM",
                        choices=["INT4_SYM", "INT4_ASYM", "INT8_SYM", "INT8_ASYM"],
                        help="Compression mode (default: INT4_SYM)")
    args = parser.parse_args()

    if not args.input.exists():
        raise FileNotFoundError(f"Input model not found: {args.input}")

    args.output.parent.mkdir(parents=True, exist_ok=True)

    print(f"Loading model: {args.input}")
    core = ov.Core()
    ov_model = core.read_model(str(args.input))

    mode = getattr(CompressWeightsMode, args.mode)
    print(f"Compressing with mode: {args.mode}")
    compressed_model = compress_weights(ov_model, mode=mode)

    print(f"Saving compressed model: {args.output}")
    ov.save_model(compressed_model, str(args.output))
    print("Done.")


if __name__ == "__main__":
    main()
