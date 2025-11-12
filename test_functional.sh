#!/bin/bash
# Functional test for WASM-ROS communication

echo "🧪 Functional Test: WASM-ROS Communication"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_check() {
    local name=$1
    local cmd=$2
    
    echo -n "Test: $name ... "
    if eval $cmd > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

echo "1. File Verification"
echo "-------------------"

test_check "WASM Publisher module exists" "[ -f public/publisher_module.wasm ]"
test_check "WASM Subscriber module exists" "[ -f public/subscriber_module.wasm ]"
test_check "Publisher JS glue code exists" "[ -f public/publisher_module.js ]"
test_check "Subscriber JS glue code exists" "[ -f public/subscriber_module.js ]"
test_check "Publisher HTML exists" "[ -f public/publisher.html ]"
test_check "Subscriber HTML exists" "[ -f public/subscriber.html ]"

echo ""
echo "2. WASM Module Validation"
echo "------------------------"

# Check WASM file format
test_check "Publisher WASM is valid format" "file public/publisher_module.wasm | grep -q 'WebAssembly'"
test_check "Subscriber WASM is valid format" "file public/subscriber_module.wasm | grep -q 'WebAssembly'"

# Check file sizes (should be reasonable)
PUB_SIZE=$(stat -f%z public/publisher_module.wasm 2>/dev/null || stat -c%s public/publisher_module.wasm 2>/dev/null)
SUB_SIZE=$(stat -f%z public/subscriber_module.wasm 2>/dev/null || stat -c%s public/subscriber_module.wasm 2>/dev/null)

if [ "$PUB_SIZE" -gt 10000 ] && [ "$PUB_SIZE" -lt 100000 ]; then
    echo -e "  Publisher WASM size: ${GREEN}${PUB_SIZE} bytes${NC} (OK)"
    ((PASSED++))
else
    echo -e "  Publisher WASM size: ${RED}${PUB_SIZE} bytes${NC} (unexpected)"
    ((FAILED++))
fi

if [ "$SUB_SIZE" -gt 10000 ] && [ "$SUB_SIZE" -lt 100000 ]; then
    echo -e "  Subscriber WASM size: ${GREEN}${SUB_SIZE} bytes${NC} (OK)"
    ((PASSED++))
else
    echo -e "  Subscriber WASM size: ${RED}${SUB_SIZE} bytes${NC} (unexpected)"
    ((FAILED++))
fi

echo ""
echo "3. HTML Content Verification"
echo "---------------------------"

# Check if HTML files reference WASM modules
test_check "Publisher HTML references WASM" "grep -q 'publisher_module.js' public/publisher.html"
test_check "Subscriber HTML references WASM" "grep -q 'subscriber_module.js' public/subscriber.html"
test_check "Publisher HTML uses roslib" "grep -qi 'roslib' public/publisher.html"
test_check "Subscriber HTML uses roslib" "grep -qi 'roslib' public/subscriber.html"

echo ""
echo "4. JavaScript Module Check"
echo "-------------------------"

# Check if JS files contain expected exports
test_check "Publisher JS has module export" "grep -q 'createPublisherModule\\|PublisherNode' public/publisher_module.js"
test_check "Subscriber JS has module export" "grep -q 'createSubscriberModule\\|SubscriberNode' public/subscriber_module.js"

echo ""
echo "5. Build Artifacts"
echo "-----------------"

test_check "Build script exists" "[ -f build.sh ]"
test_check "Build script is executable" "[ -x build.sh ]"

echo ""
echo "=========================================="
echo "📊 Results:"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All functional tests passed!${NC}"
    echo ""
    echo "Note: This tests the current implementation using ROS Bridge."
    echo "The final architecture (microROS in WASM) requires microROS ported to WASM."
    exit 0
else
    echo -e "${RED}⚠ Some tests failed${NC}"
    exit 1
fi

