#!/bin/bash

# Build script for microROS in WASM
# Compiles ROS nodes that run INSIDE WASM runtime

set -e

echo "Building microROS nodes for WASM..."

# Check if Emscripten is available
if ! command -v emcc &> /dev/null; then
    echo "ERROR: Emscripten not found!"
    echo "Run: source \$HOME/emsdk/emsdk_env.sh"
    exit 1
fi

# Create output directory
mkdir -p wasm_output

# Build microROS node (publisher)
echo "Building ROS Publisher node (WASM)..."
emcc src/microros_node_wasm.cpp \
    -I. \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_NAME="createMicroROSModule" \
    -s EXPORTED_FUNCTIONS='["_malloc","_free"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAXIMUM_MEMORY=128MB \
    -O2 \
    -o wasm_output/microros_node.js

echo "✓ ROS Publisher node built: wasm_output/microros_node.js"
echo "✓ WASM module: wasm_output/microros_node.wasm"

# Build minimal DDS layer
echo "Building minimal DDS layer (WASM)..."
emcc src/dds_minimal_wasm.cpp \
    -I. \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_NAME="createDDSModule" \
    -s EXPORTED_FUNCTIONS='["_malloc","_free"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAXIMUM_MEMORY=128MB \
    -O2 \
    -o wasm_output/dds_minimal.js

echo "✓ Minimal DDS layer built: wasm_output/dds_minimal.js"
echo "✓ WASM module: wasm_output/dds_minimal.wasm"

echo ""
echo "Build complete!"
echo "WASM modules are in: wasm_output/"

