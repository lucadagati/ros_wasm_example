# Quick Start: microROS in WASM

## Current Status

✅ **Infrastructure Ready:**
- Emscripten toolchain configured
- Custom RMW implementation (using our DDS)
- Build scripts prepared
- Wrapper code structure

⏳ **Next Steps:**
- Clone microROS repository
- Port rcl/rclc components
- Integrate with our DDS layer

## Quick Start

### 1. Clone microROS

```bash
# Option 1: SSH (recommended)
git clone --recursive git@github.com:micro-ROS/micro-ROS.git microros

# Option 2: HTTPS (requires credentials)
git clone --recursive https://github.com/micro-ROS/micro-ROS.git microros
```

### 2. Setup Build Environment

```bash
# Activate Emscripten
source emsdk/emsdk_env.sh

# Run porting script
./port_microros.sh
```

### 3. Build microROS for WASM

```bash
./build_microros_full.sh
```

## Strategy: Hybrid Approach

Instead of porting full microROS stack, we use:

1. **microROS API** (rcl/rclc) - Official ROS2 API
2. **Our DDS Layer** - Already implemented and working
3. **Custom RMW** - Bridge between rcl and our DDS

**Benefits:**
- ✅ Official ROS2 API
- ✅ Reuse our working DDS
- ✅ Faster implementation
- ✅ Less complexity

## Architecture

```
WASM Runtime
  ↓
microROS (rcl/rclc)  ← Official ROS2 API
  ↓
Custom RMW           ← Our implementation
  ↓
Minimal DDS          ← Our working DDS layer
  ↓
WASI Networking      ← Real sockets
  ↓
Network
```

## Files Structure

```
wasm_test/
├── microros/              # microROS source (clone here)
├── cmake/
│   └── EmscriptenToolchain.cmake
├── src/
│   ├── dds_minimal_wasm.cpp      # Our DDS layer
│   ├── rmw_custom_wasm.cpp       # Custom RMW
│   └── microros_wrapper_wasm.cpp # microROS wrapper
├── build_microros_full.sh        # Build script
└── port_microros.sh              # Setup script
```

## Timeline

- **Week 1**: Clone, setup, study microROS structure
- **Week 2-3**: Port rcl (ROS Client Library)
- **Week 4**: Port rclc (ROS Client Library C)
- **Week 5**: Integrate with our DDS
- **Week 6**: Testing and refinement

## Resources

- microROS: https://github.com/micro-ROS/micro-ROS
- microROS Docs: https://micro.ros.org/
- Our DDS: `src/dds_minimal_wasm.cpp`
- Our RMW: `src/rmw_custom_wasm.cpp`

