# microROS Porting Guide to WASM

## Overview

This guide documents the process of porting microROS to WebAssembly (WASM).

## Prerequisites

1. **Emscripten SDK** - For compiling to WASM
2. **microROS Source** - Clone from GitHub
3. **Build Tools** - CMake, make, etc.
4. **Dependencies** - rcutils, rosidl, etc.

## microROS Architecture

```
microROS
├── rcl (ROS Client Library)
│   ├── Core ROS2 API
│   ├── Node management
│   └── Publisher/Subscriber
├── rclc (ROS Client Library C)
│   ├── C convenience API
│   ├── Executor
│   └── Simplified API
└── rmw (ROS Middleware)
    ├── Middleware abstraction
    ├── DDS implementation
    └── Transport layer
```

## Porting Strategy

### Phase 1: Setup Build Environment

1. **Clone microROS**
   ```bash
   git clone --recursive https://github.com/micro-ROS/micro-ROS.git
   ```

2. **Configure Emscripten Toolchain**
   - Create Emscripten CMake toolchain file
   - Set compiler flags
   - Configure linker settings

3. **Port Dependencies**
   - rcutils (utilities)
   - rosidl (IDL support)
   - FastDDS or custom DDS

### Phase 2: Port rcl (ROS Client Library)

**Location**: `microros/micro_ros_msgs/rcl/`

**Steps**:
1. Configure CMake for Emscripten
2. Port system calls (use WASI)
3. Adapt memory management
4. Build static library

**Key Files**:
- `rcl/src/rcl/` - Core implementation
- `rcl/include/rcl/` - Headers

**Challenges**:
- Threading (WASM is single-threaded)
- Memory management
- System calls (WASI)

### Phase 3: Port rclc (ROS Client Library C)

**Location**: `microros/micro_ros_msgs/rclc/`

**Steps**:
1. Depends on rcl
2. Port executor
3. Adapt callback system
4. Build static library

**Key Features**:
- `rclc_executor` - Executor for callbacks
- Simplified API
- C-friendly interface

### Phase 4: Port rmw (ROS Middleware)

**Location**: `microros/micro_ros_msgs/rmw/`

**Options**:
- **Option A**: Port FastDDS
- **Option B**: Use our minimal DDS
- **Option C**: Create custom rmw implementation

**Recommended**: Option B (use our minimal DDS)
- Already implemented
- Simpler
- Sufficient for proof-of-concept

### Phase 5: Integration

1. **Link Components**
   - Link rcl, rclc, rmw
   - Link with our DDS layer
   - Create unified WASM module

2. **Create Wrapper**
   - JavaScript bindings
   - API exposure
   - Error handling

3. **Testing**
   - Test node creation
   - Test publisher/subscriber
   - Test communication

## Build Configuration

### CMake Toolchain for Emscripten

Create `cmake/Emscripten.cmake`:

```cmake
set(CMAKE_SYSTEM_NAME Emscripten)
set(CMAKE_C_COMPILER emcc)
set(CMAKE_CXX_COMPILER em++)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -s WASM=1")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s WASM=1")
```

### Compiler Flags

```bash
-s WASM=1                    # Generate WASM
-s MODULARIZE=1              # Modular output
-s EXPORT_NAME="createModule" # Module name
-s ALLOW_MEMORY_GROWTH=1     # Dynamic memory
-s MAXIMUM_MEMORY=128MB      # Max memory
-O2                          # Optimization
```

## Dependencies to Port

1. **rcutils** - Utilities
   - String handling
   - Time functions
   - Logging

2. **rosidl** - IDL support
   - Message type generation
   - Serialization

3. **FastDDS** (optional)
   - Full DDS implementation
   - Complex, large codebase

## Integration with Our DDS Layer

Our minimal DDS can be used as the rmw implementation:

```cpp
// Custom rmw implementation using our DDS
rmw_ret_t rmw_publish(
    const rmw_publisher_t* publisher,
    const void* ros_message,
    rmw_publisher_allocation_t* allocation)
{
    // Use our DDSPublisherWASM
    // Serialize message
    // Send via our DDS layer
}
```

## Testing Strategy

1. **Unit Tests**
   - Test each component
   - Test in WASM runtime

2. **Integration Tests**
   - Test full stack
   - Test communication

3. **Performance Tests**
   - Memory usage
   - Message throughput
   - Latency

## Timeline Estimate

- **Phase 1 (Setup)**: 1 week
- **Phase 2 (rcl)**: 2 weeks
- **Phase 3 (rclc)**: 1 week
- **Phase 4 (rmw)**: 1 week
- **Phase 5 (Integration)**: 1 week
- **Total**: 6 weeks

## Alternative: Hybrid Approach

Instead of porting full microROS, we can:

1. **Use microROS API** (rcl/rclc headers)
2. **Implement custom backend** (our DDS)
3. **Bridge the gap** (wrapper layer)

This reduces complexity while maintaining API compatibility.

## Resources

- microROS: https://github.com/micro-ROS/micro-ROS
- microROS Docs: https://micro.ros.org/
- Emscripten: https://emscripten.org/
- WASI: https://wasi.dev/

## Next Steps

1. Run `./port_microros.sh` to clone microROS
2. Study microROS build system
3. Create Emscripten toolchain
4. Start porting rcl

