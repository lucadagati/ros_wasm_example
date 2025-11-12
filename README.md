# microROS in WASM - ROS Nodes Running Inside WASM Runtime

**ROS executing inside WebAssembly runtime - Direct WASM-to-WASM communication**

This project implements microROS (ROS2) nodes that run **entirely inside WASM runtime**. Two WASM environments communicate directly via ROS2 DDS, without external ROS processes.

## Goal

**Demonstrate that ROS nodes can execute inside WASM runtime and communicate directly between WASM environments.**

## Architecture

```
WASM Runtime 1 (Wasmtime/Wasmer)
  ↓
microROS Core (compiled to WASM)
  ↓
ROS2 DDS Transport (compiled to WASM)
  ↓
ROS2 Network
  ↓
ROS2 DDS Transport (compiled to WASM)
  ↓
microROS Core (compiled to WASM)
  ↓
WASM Runtime 2 (Wasmtime/Wasmer)
```

**Key Points:**
- **ROS executes inside WASM**: microROS core, ROS2 DDS layer, and node logic are all compiled to WASM bytecode
- **No external ROS process**: All ROS operations execute in WASM runtime
- **Direct WASM-to-WASM communication**: Via ROS2 DDS protocol
- **Kubernetes orchestration**: WASM runtimes deployed as K8s pods

## Implementation Status

### ✅ What We're Building

- [x] Project structure and documentation
- [ ] microROS core ported to WASM
- [ ] ROS2 DDS transport in WASM
- [ ] ROS publisher node in WASM
- [ ] ROS subscriber node in WASM
- [ ] WASM-to-WASM communication via ROS2 DDS
- [ ] Kubernetes deployment

### Current Work

We are implementing a **minimal ROS2 DDS layer in WASM** to enable direct ROS communication between WASM runtimes.

## Prerequisites

1. **WASI-SDK or Emscripten** (to compile C++ to WASM)
2. **Wasmtime or Wasmer** (WASM runtime)
3. **Kubernetes** (for deployment, optional)

## Quick Start

### 1. Setup Environment

```bash
./setup.sh
```

This installs:
- Emscripten SDK
- Python dependencies
- Build tools

### 2. Build ROS Nodes for WASM

```bash
./build_microros_wasm.sh
```

This compiles microROS nodes to WASM.

### 3. Run WASM Runtimes

```bash
# Terminal 1: Publisher WASM
wasmtime wasm_output/microros_publisher.wasm

# Terminal 2: Subscriber WASM
wasmtime wasm_output/microros_subscriber.wasm
```

## Project Structure

```
wasm_test/
├── src/
│   ├── microros_node_wasm.cpp    # ROS nodes in WASM
│   └── dds_minimal_wasm.cpp      # Minimal DDS layer
├── wasm_output/                   # Compiled WASM modules
├── build_microros_wasm.sh         # Build script
├── setup.sh                       # Setup script
├── IMPLEMENTATION_PLAN.md         # Detailed implementation plan
├── ROADMAP.md                     # Project roadmap
└── README.md                      # This file
```

## Implementation Plan

See `IMPLEMENTATION_PLAN.md` for detailed steps to port microROS to WASM.

See `ROADMAP.md` for phased approach and timeline.

## Technologies

- **WebAssembly (WASM)**: Runtime for executing ROS code
- **microROS**: ROS2 for resource-constrained devices (compiled to WASM)
- **ROS2 DDS**: Data Distribution Service layer (compiled to WASM)
- **WASI**: WebAssembly System Interface for system calls
- **Kubernetes**: Orchestration platform for WASM runtimes
- **Wasmtime/Wasmer**: WASM runtime engines

## Documentation

- `IMPLEMENTATION_PLAN.md` - Detailed implementation steps
- `ROADMAP.md` - Project phases and timeline
- `CURRENT_STATUS.md` - Current vs target implementation
- `START_MICROROS_WASM.md` - Starting point for implementation

## License

MIT License
