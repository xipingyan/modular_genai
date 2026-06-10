#!/bin/bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_model.xml> <output_model.xml> [--mode INT4_SYM|INT4_ASYM|INT8_SYM|INT8_ASYM]"
    exit 1
fi

python3 "${SCRIPT_DIR}/compress.py" "$@"
