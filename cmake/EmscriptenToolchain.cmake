# Emscripten Toolchain for microROS
# This file configures CMake to use Emscripten for WASM compilation

set(CMAKE_SYSTEM_NAME Emscripten)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)

# Find Emscripten
if(DEFINED ENV{EMSCRIPTEN})
    set(EMSCRIPTEN_ROOT_PATH $ENV{EMSCRIPTEN})
elseif(EXISTS "$ENV{HOME}/emsdk/upstream/emscripten")
    set(EMSCRIPTEN_ROOT_PATH "$ENV{HOME}/emsdk/upstream/emscripten")
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../emsdk/upstream/emscripten")
    set(EMSCRIPTEN_ROOT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../emsdk/upstream/emscripten")
else()
    message(FATAL_ERROR "Emscripten not found. Set EMSCRIPTEN environment variable or install emsdk")
endif()

# Set compilers
set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc")
set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT_PATH}/em++")
set(CMAKE_ASM_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc")

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -s WASM=1 -s MODULARIZE=1")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s WASM=1 -s MODULARIZE=1")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -s WASM=1 -s MODULARIZE=1 -s EXPORT_NAME='createModule'")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -s ALLOW_MEMORY_GROWTH=1")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -s MAXIMUM_MEMORY=128MB")

# Disable features not available in WASM
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")

# Find programs
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

message(STATUS "Emscripten toolchain configured: ${EMSCRIPTEN_ROOT_PATH}")

