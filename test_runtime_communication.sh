#!/bin/bash

# Test communication between multiple WASM runtimes
# This script tests ROS nodes running in separate WASM runtimes

set -e

echo "=========================================="
echo "Testing ROS Communication (WASM Runtimes)"
echo "=========================================="
echo ""

# Check if Wasmtime is available
if command -v wasmtime &> /dev/null; then
    RUNTIME="wasmtime"
    echo "✓ Using Wasmtime runtime"
elif command -v wasmer &> /dev/null; then
    RUNTIME="wasmer"
    echo "✓ Using Wasmer runtime"
else
    echo "⚠ No WASM runtime found (wasmtime/wasmer)"
    echo "  Testing with browser simulation instead"
    RUNTIME="browser"
fi
echo ""

# Check if WASM modules exist
if [ ! -f "wasm_output/ros_publisher.wasm" ] || [ ! -f "wasm_output/ros_subscriber.wasm" ]; then
    echo "ERROR: WASM modules not found!"
    echo "Run: ./build_microros_wasm.sh"
    exit 1
fi

echo "WASM modules found:"
echo "  • Publisher:  wasm_output/ros_publisher.wasm"
echo "  • Subscriber: wasm_output/ros_subscriber.wasm"
echo ""

if [ "$RUNTIME" = "browser" ]; then
    echo "=========================================="
    echo "Browser Testing"
    echo "=========================================="
    echo ""
    echo "To test in browser:"
    echo "  1. Start a local web server:"
    echo "     python3 -m http.server 8000"
    echo "  2. Open: http://localhost:8000/test_communication.html"
    echo "  3. Initialize both publisher and subscriber"
    echo "  4. Start publishing and observe communication"
    echo ""
    exit 0
fi

echo "=========================================="
echo "Standalone Runtime Testing"
echo "=========================================="
echo ""
echo "Note: Standalone testing requires:"
echo "  - WASI sockets support in runtime"
echo "  - Network access"
echo "  - Proper WASM module configuration"
echo ""
echo "For now, use browser testing (test_communication.html)"
echo "or implement a test server that bridges WASM runtimes"
echo ""

