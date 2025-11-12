#!/bin/bash

# Script to port microROS to WASM
# This sets up the microROS build environment for Emscripten

set -e

echo "=========================================="
echo "Porting microROS to WASM"
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

# Create microROS directory
MICROROS_DIR="microros"
if [ ! -d "$MICROROS_DIR" ]; then
    echo "Cloning microROS repository..."
    echo "Note: This may require authentication"
    echo ""
    echo "Option 1: Clone via HTTPS (requires credentials)"
    echo "  git clone --recursive https://github.com/micro-ROS/micro-ROS.git $MICROROS_DIR"
    echo ""
    echo "Option 2: Clone via SSH"
    echo "  git clone --recursive git@github.com:micro-ROS/micro-ROS.git $MICROROS_DIR"
    echo ""
    read -p "Attempt to clone now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try SSH first, then HTTPS
        if git clone --recursive git@github.com:micro-ROS/micro-ROS.git "$MICROROS_DIR" 2>/dev/null; then
            echo "✓ microROS cloned via SSH"
        elif git clone --recursive https://github.com/micro-ROS/micro-ROS.git "$MICROROS_DIR" 2>/dev/null; then
            echo "✓ microROS cloned via HTTPS"
        else
            echo "⚠ Failed to clone. Please clone manually:"
            echo "  git clone --recursive https://github.com/micro-ROS/micro-ROS.git $MICROROS_DIR"
            echo ""
            echo "Creating placeholder structure..."
            mkdir -p "$MICROROS_DIR"
            echo "# microROS" > "$MICROROS_DIR/README.md"
            echo "Clone microROS here: git clone --recursive https://github.com/micro-ROS/micro-ROS.git" >> "$MICROROS_DIR/README.md"
        fi
    else
        echo "Skipping clone. Create $MICROROS_DIR/ manually when ready."
        mkdir -p "$MICROROS_DIR"
        echo "# microROS" > "$MICROROS_DIR/README.md"
        echo "Clone microROS here: git clone --recursive https://github.com/micro-ROS/micro-ROS.git" >> "$MICROROS_DIR/README.md"
    fi
else
    echo "✓ microROS directory exists"
fi

echo ""
echo "microROS structure:"
echo "  • Repository: $MICROROS_DIR/"
echo "  • Main components: rcl, rclc, rmw"
echo ""

# Check microROS structure
if [ -d "$MICROROS_DIR/micro_ros_setup" ]; then
    echo "✓ microROS setup found"
else
    echo "⚠ microROS setup not found - may need to run setup"
fi

echo ""
echo "Next steps:"
echo "  1. Configure build system for Emscripten"
echo "  2. Port dependencies (rcutils, rosidl, etc.)"
echo "  3. Build rcl/rclc/rmw for WASM"
echo "  4. Integrate with our DDS layer"
echo ""

