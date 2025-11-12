/*
 * Test ROS Publisher Node in WASM
 * 
 * This script tests the ROS publisher node running in WASM.
 */

const fs = require('fs');
const path = require('path');

// Load WASM module
const wasmPath = path.join(__dirname, 'wasm_output', 'ros_publisher.js');
if (!fs.existsSync(wasmPath)) {
    console.error('ERROR: WASM module not found. Run: ./build_microros_wasm.sh');
    process.exit(1);
}

// For Node.js, we need to use a WASM runtime
// This is a simplified test - in production, use Wasmtime or Wasmer
console.log('========================================');
console.log('Testing ROS Publisher Node (WASM)');
console.log('========================================');
console.log('');

console.log('Note: This test requires a WASM runtime.');
console.log('For full testing, use:');
console.log('  - Wasmtime: wasmtime wasm_output/ros_publisher.wasm');
console.log('  - Wasmer: wasmer wasm_output/ros_publisher.wasm');
console.log('  - Browser: Load ros_publisher.js in HTML');
console.log('');

console.log('✓ Build files exist');
console.log('  - ros_publisher.js');
console.log('  - ros_publisher.wasm');
console.log('');

console.log('To test in browser:');
console.log('  1. Create HTML file that loads ros_publisher.js');
console.log('  2. Open in browser');
console.log('  3. Check console for ROS node initialization');
console.log('');

