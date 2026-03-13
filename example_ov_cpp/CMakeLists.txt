cmake_minimum_required(VERSION 3.20)

set(TARGET_NAME "module_genai_app")

project(${TARGET_NAME})

option(ENABLE_MODEL_WEIGHTS_MANAGEMENT
    "Enable explicit load/release model weights calls (compiled_model.load_model_weights / release_model_weights)"
    OFF)

find_package(OpenVINO REQUIRED)
find_package(OpenVINOGenAI REQUIRED)
find_package(OpenCV REQUIRED)

if(OpenCV_FOUND)
    message(STATUS "OpenCV found. Version: ${OpenCV_VERSION}")
else()
    message(FATAL_ERROR "OpenCV not found! Check your installation and environment.")
endif()

# Auto load all cpp files
file(GLOB CPP_SOURCES "*.cpp")
add_executable(${TARGET_NAME} ${CPP_SOURCES})

target_compile_definitions(${TARGET_NAME} PRIVATE
    ENABLE_MODEL_WEIGHTS_MANAGEMENT=$<BOOL:${ENABLE_MODEL_WEIGHTS_MANAGEMENT}>)

target_include_directories(${TARGET_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_BINARY_DIR}" "${OpenCV_INCLUDE_DIRS}")

target_link_libraries(${TARGET_NAME} PRIVATE openvino::genai ${OpenCV_LIBS})