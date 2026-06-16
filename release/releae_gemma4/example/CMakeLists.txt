# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.23)
project(SimplePipelineExample LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find the installed pipeline package
# Assumes install directory is at ../install
set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../install/runtime/cmake" ${CMAKE_PREFIX_PATH})

find_package(pipeline REQUIRED)

# Build simple_pipeline executable
add_executable(simple_pipeline simple_pipeline.cpp)
target_link_libraries(simple_pipeline PRIVATE pipeline::pipeline)

message(STATUS "Simple pipeline example configured successfully")
