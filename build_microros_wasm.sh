#!/bin/bash

# Build script for ROS nodes in WASM
# Compiles ROS nodes that run INSIDE WASM runtime using minimal DDS

set -e

echo "=========================================="
echo "Building ROS nodes for WASM"
echo "=========================================="
echo ""

# Check if Emscripten is available
if ! command -v emcc &> /dev/null; then
    echo "ERROR: Emscripten not found!"
    echo "Run: source \$HOME/emsdk/emsdk_env.sh"
    exit 1
fi

echo "✓ Emscripten found: $(which emcc)"
echo ""

# Create output directory
mkdir -p wasm_output

# Build ROS Publisher node (includes DDS) - Minimal DDS version
echo "Building ROS Publisher node (WASM) - Minimal DDS..."
echo "----------------------------------------"
emcc src/ros_publisher_wasm.cpp \
    -I. \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_NAME="createROSPublisherModule" \
    -s EXPORTED_FUNCTIONS='["_malloc","_free"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","addOnPostRun"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAXIMUM_MEMORY=128MB \
    -s ENVIRONMENT=web,worker \
    -O2 \
    --bind \
    -o wasm_output/ros_publisher.js

# Build microROS Publisher node (using microROS API)
echo "Building microROS Publisher node (WASM)..."
echo "----------------------------------------"
emcc src/microros_publisher_wasm.cpp \
    -I. \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_NAME="createMicroROSPublisherModule" \
    -s EXPORTED_FUNCTIONS='["_malloc","_free"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","addOnPostRun"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAXIMUM_MEMORY=128MB \
    -s ENVIRONMENT=web,worker \
    -O2 \
    --bind \
    -o wasm_output/microros_publisher.js

if [ -f wasm_output/ros_publisher.wasm ]; then
    SIZE=$(du -h wasm_output/ros_publisher.wasm | cut -f1)
    echo "✓ ROS Publisher node built: wasm_output/ros_publisher.js"
    echo "  WASM module: wasm_output/ros_publisher.wasm ($SIZE)"
else
    echo "✗ Failed to build ROS Publisher node"
    exit 1
fi
echo ""

# Build ROS Subscriber node (includes DDS) - Minimal DDS version
echo "Building ROS Subscriber node (WASM) - Minimal DDS..."
echo "----------------------------------------"
emcc src/ros_subscriber_wasm.cpp \
    -I. \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_NAME="createROSSubscriberModule" \
    -s EXPORTED_FUNCTIONS='["_malloc","_free"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","addOnPostRun"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAXIMUM_MEMORY=128MB \
    -s ENVIRONMENT=web,worker \
    -O2 \
    --bind \
    -o wasm_output/ros_subscriber.js

# Build microROS Subscriber node (using microROS API)
echo "Building microROS Subscriber node (WASM)..."
echo "----------------------------------------"
emcc src/microros_subscriber_wasm.cpp \
    -I. \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_NAME="createMicroROSSubscriberModule" \
    -s EXPORTED_FUNCTIONS='["_malloc","_free"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","addOnPostRun"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s MAXIMUM_MEMORY=128MB \
    -s ENVIRONMENT=web,worker \
    -O2 \
    --bind \
    -o wasm_output/microros_subscriber.js

if [ -f wasm_output/ros_subscriber.wasm ]; then
    SIZE=$(du -h wasm_output/ros_subscriber.wasm | cut -f1)
    echo "✓ ROS Subscriber node built: wasm_output/ros_subscriber.js"
    echo "  WASM module: wasm_output/ros_subscriber.wasm ($SIZE)"
else
    echo "✗ Failed to build ROS Subscriber node"
    exit 1
fi
echo ""

echo "=========================================="
echo "Build complete!"
echo "=========================================="
echo ""
echo "WASM modules:"
echo "  • Minimal DDS Publisher:  wasm_output/ros_publisher.{js,wasm}"
echo "  • Minimal DDS Subscriber: wasm_output/ros_subscriber.{js,wasm}"
echo "  • microROS Publisher:     wasm_output/microros_publisher.{js,wasm}"
echo "  • microROS Subscriber:     wasm_output/microros_subscriber.{js,wasm}"
echo ""
echo "Note: microROS modules use microROS API (rcl/rclc) but need full porting"
echo "      Currently using placeholder implementations"
echo ""
echo "Next steps:"
echo "  1. Complete microROS porting (rcl/rclc)"
echo "  2. Integrate with our DDS layer"
echo "  3. Test microROS nodes"
echo ""

