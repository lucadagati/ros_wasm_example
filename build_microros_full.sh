#!/bin/bash

# Build script for full microROS in WASM
# This compiles microROS (rcl/rclc/rmw) to WASM

set -e

echo "=========================================="
echo "Building microROS for WASM"
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

# Check if microROS is cloned
MICROROS_DIR="microros"
if [ ! -d "$MICROROS_DIR" ]; then
    echo "ERROR: microROS not found!"
    echo "Run: ./port_microros.sh"
    exit 1
fi

echo "✓ microROS directory found: $MICROROS_DIR/"
echo ""

# Create output directory
mkdir -p wasm_output/microros

echo "=========================================="
echo "Porting microROS Components"
echo "=========================================="
echo ""

echo "This is a complex process that requires:"
echo "  1. Porting rcl (ROS Client Library)"
echo "  2. Porting rclc (ROS Client Library C)"
echo "  3. Porting rmw (ROS Middleware)"
echo "  4. Porting dependencies (rcutils, rosidl, etc.)"
echo "  5. Configuring build system for Emscripten"
echo ""

echo "Estimated time: 4-6 weeks"
echo ""

echo "For now, we'll create the build structure..."
echo ""

# Create build directory structure
mkdir -p build/microros/{rcl,rclc,rmw}

echo "Build structure created:"
echo "  • build/microros/rcl/"
echo "  • build/microros/rclc/"
echo "  • build/microros/rmw/"
echo ""

echo "Next steps:"
echo "  1. Configure CMake for Emscripten"
echo "  2. Port dependencies"
echo "  3. Build each component"
echo "  4. Link together"
echo ""

echo "See MICROROS_PORTING_GUIDE.md for detailed steps"
echo ""

