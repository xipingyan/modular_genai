#!/bin/bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

# Source OpenVINO environment
source ../install/setupvars.sh

# Create build directory
mkdir -p build
cd build

# Configure and build
cmake ..
cmake --build . -j$(nproc)

echo ""
echo "Build completed successfully!"
echo "Executable: $(pwd)/simple_pipeline"
