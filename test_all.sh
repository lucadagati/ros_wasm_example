#!/bin/bash

# Comprehensive test script for microROS in WASM
# Tests both minimal DDS and microROS API versions

set -e

echo "=========================================="
echo "microROS in WASM - Comprehensive Tests"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /tmp/test_output.log 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Error output:"
        cat /tmp/test_output.log | sed 's/^/    /'
        ((TESTS_FAILED++))
        return 1
    fi
}

# Check if WASM modules exist
echo "1. Checking WASM modules..."
echo "----------------------------------------"

MODULES=(
    "wasm_output/ros_publisher.wasm:Minimal DDS Publisher"
    "wasm_output/ros_subscriber.wasm:Minimal DDS Subscriber"
    "wasm_output/microros_publisher.wasm:microROS Publisher"
    "wasm_output/microros_subscriber.wasm:microROS Subscriber"
)

for module_info in "${MODULES[@]}"; do
    IFS=':' read -r module_path module_name <<< "$module_info"
    if [ -f "$module_path" ]; then
        SIZE=$(du -h "$module_path" | cut -f1)
        echo -e "  ${GREEN}✓${NC} $module_name: $SIZE"
    else
        echo -e "  ${RED}✗${NC} $module_name: NOT FOUND"
        echo "    Run: ./build_microros_wasm.sh"
        exit 1
    fi
done

echo ""

# Check if JavaScript wrappers exist
echo "2. Checking JavaScript wrappers..."
echo "----------------------------------------"

JS_FILES=(
    "wasm_output/ros_publisher.js"
    "wasm_output/ros_subscriber.js"
    "wasm_output/microros_publisher.js"
    "wasm_output/microros_subscriber.js"
)

for js_file in "${JS_FILES[@]}"; do
    if [ -f "$js_file" ]; then
        echo -e "  ${GREEN}✓${NC} $(basename $js_file)"
    else
        echo -e "  ${RED}✗${NC} $(basename $js_file): NOT FOUND"
        exit 1
    fi
done

echo ""

# Test WASM module validity
echo "3. Testing WASM module validity..."
echo "----------------------------------------"

if command -v wasm-validate &> /dev/null; then
    for module_info in "${MODULES[@]}"; do
        IFS=':' read -r module_path module_name <<< "$module_info"
        run_test "$module_name validity" "wasm-validate $module_path"
    done
else
    echo -e "  ${YELLOW}⚠${NC} wasm-validate not found, skipping validation"
fi

echo ""

# Test Node.js module loading (if Node.js available)
echo "4. Testing Node.js module loading..."
echo "----------------------------------------"

if command -v node &> /dev/null; then
    # Test if modules can be loaded in Node.js
    run_test "Load ros_publisher.js" "node -e \"import('./wasm_output/ros_publisher.js').then(() => console.log('OK')).catch(e => {console.error(e); process.exit(1);})\""
    run_test "Load microros_publisher.js" "node -e \"import('./wasm_output/microros_publisher.js').then(() => console.log('OK')).catch(e => {console.error(e); process.exit(1);})\""
else
    echo -e "  ${YELLOW}⚠${NC} Node.js not found, skipping Node.js tests"
fi

echo ""

# Test file sizes
echo "5. Testing module sizes..."
echo "----------------------------------------"

for module_info in "${MODULES[@]}"; do
    IFS=':' read -r module_path module_name <<< "$module_info"
    SIZE=$(stat -f%z "$module_path" 2>/dev/null || stat -c%s "$module_path" 2>/dev/null)
    SIZE_KB=$((SIZE / 1024))
    
    if [ $SIZE_KB -lt 10 ]; then
        echo -e "  ${YELLOW}⚠${NC} $module_name: ${SIZE_KB}KB (suspiciously small)"
    elif [ $SIZE_KB -gt 1000 ]; then
        echo -e "  ${YELLOW}⚠${NC} $module_name: ${SIZE_KB}KB (very large)"
    else
        echo -e "  ${GREEN}✓${NC} $module_name: ${SIZE_KB}KB"
    fi
done

echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start test server: node test_server.js"
    echo "  2. Open browser: http://localhost:8080/test_microros.html"
    echo "  3. Or test minimal DDS: http://localhost:8080/test_communication.html"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

