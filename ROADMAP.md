# Roadmap: ROS Inside WASM - Complete Implementation

## Goal

**Demonstrate that ROS executes inside WASM runtime and two ROS nodes in separate WASM environments can communicate directly.**

## Current Status

### ❌ What We Have Now (Prototype)
- WASM modules with business logic only
- JavaScript bridge (roslib.js)
- External ROS Bridge process
- **ROS does NOT run inside WASM**

### ✅ What We Need (Target)
- microROS compiled to WASM
- ROS2 DDS transport in WASM
- Two WASM runtimes with ROS nodes
- Direct WASM-to-WASM communication via ROS2 DDS
- **ROS executes completely inside WASM**

## Implementation Phases

### Phase 0: Research & Planning ✅
- [x] Understand microROS architecture
- [x] Research WASI networking
- [x] Create implementation plan
- [x] Document target architecture

### Phase 1: microROS Porting to WASM (4-6 weeks)

#### 1.1 Setup Build Environment
- [ ] Install WASI-SDK or configure Emscripten for microROS
- [ ] Clone microROS repository
- [ ] Understand microROS build system
- [ ] Test basic C compilation to WASM

#### 1.2 Port microROS Core
- [ ] Port rcl (ROS Client Library) to WASM
- [ ] Port rclc (ROS Client Library C) to WASM
- [ ] Port rmw (ROS Middleware) to WASM
- [ ] Test ROS node creation in WASM

#### 1.3 Port ROS2 DDS Layer
- [ ] Port FastDDS or implement minimal DDS
- [ ] Implement UDP/TCP networking via WASI
- [ ] Test DDS discovery in WASM
- [ ] Test DDS communication between WASM runtimes

**Deliverable**: microROS running in WASM, can create nodes

### Phase 2: Publisher/Subscriber Implementation (2-3 weeks)

#### 2.1 Publisher Node in WASM
- [ ] Create publisher node using microROS in WASM
- [ ] Implement message publishing via ROS2 DDS
- [ ] Test publisher in WASM runtime

#### 2.2 Subscriber Node in WASM
- [ ] Create subscriber node using microROS in WASM
- [ ] Implement message subscription via ROS2 DDS
- [ ] Test subscriber in WASM runtime

#### 2.3 End-to-End Test
- [ ] Deploy two WASM runtimes (Wasmtime/Wasmer)
- [ ] Publisher in Runtime 1, Subscriber in Runtime 2
- [ ] Test direct communication via ROS2 DDS
- [ ] Verify no external ROS process needed

**Deliverable**: Two ROS nodes in separate WASM runtimes communicating directly

### Phase 3: Kubernetes Deployment (1-2 weeks)

#### 3.1 Container Images
- [ ] Create Docker image with Wasmtime/Wasmer
- [ ] Package WASM modules in containers
- [ ] Test local deployment

#### 3.2 Kubernetes Manifests
- [ ] Create Pod manifests for publisher
- [ ] Create Pod manifests for subscriber
- [ ] Configure networking for ROS2 DDS
- [ ] Deploy on K8s cluster

#### 3.3 Testing
- [ ] Test communication between K8s pods
- [ ] Verify ROS2 DDS discovery works
- [ ] Monitor performance and latency

**Deliverable**: ROS nodes in WASM running on Kubernetes

## Alternative: Simplified Proof of Concept

If full microROS porting is too complex, we can create a **minimal ROS2 DDS implementation**:

### Minimal Approach (2-3 weeks)

1. **Implement minimal DDS layer**:
   - UDP multicast for discovery
   - Simple publisher/subscriber
   - String messages only

2. **Create ROS-like API in WASM**:
   - Node creation
   - Topic publishing
   - Topic subscription
   - Message callbacks

3. **Test communication**:
   - Two WASM runtimes
   - Direct DDS communication
   - Proof that ROS can run in WASM

**Advantage**: Faster to implement, proves the concept
**Disadvantage**: Not full ROS2 compatibility

## Technical Challenges

### 1. Networking in WASM
- **Challenge**: WASI sockets are still evolving
- **Solution**: Use runtime-specific extensions or polyfills

### 2. DDS Discovery
- **Challenge**: Multicast may not work in all environments
- **Solution**: Use unicast discovery or static configuration

### 3. Memory Management
- **Challenge**: WASM linear memory limitations
- **Solution**: Efficient memory usage, dynamic growth

### 4. Real-time Constraints
- **Challenge**: WASM may not meet hard real-time requirements
- **Solution**: Accept soft real-time, optimize for latency

## Success Criteria

### Minimum Viable Product (MVP)
- [ ] microROS compiles to WASM
- [ ] ROS node can be created in WASM
- [ ] Publisher can publish messages from WASM
- [ ] Subscriber can receive messages in WASM
- [ ] Two WASM runtimes communicate via ROS2 DDS
- [ ] No external ROS process required

### Full Implementation
- [ ] All microROS features work in WASM
- [ ] Full ROS2 DDS compatibility
- [ ] Deployed on Kubernetes
- [ ] Performance benchmarks
- [ ] Documentation complete

## Timeline Estimate

- **Phase 1 (microROS porting)**: 4-6 weeks
- **Phase 2 (Publisher/Subscriber)**: 2-3 weeks
- **Phase 3 (K8s deployment)**: 1-2 weeks
- **Total**: 7-11 weeks for full implementation

**Simplified approach**: 2-3 weeks for proof of concept

## Next Immediate Steps

1. **Decide approach**: Full microROS vs minimal implementation
2. **Setup environment**: WASI-SDK + microROS sources
3. **First milestone**: Compile microROS base to WASM
4. **Iterate**: Add functionality step by step

## Resources

- microROS: https://github.com/micro-ROS/micro-ROS
- microROS documentation: https://micro.ros.org/
- WASI: https://wasi.dev/
- WASI sockets: https://github.com/WebAssembly/WASI/blob/main/phases/snapshot/docs/wasi-sockets.md
- Wasmtime: https://wasmtime.dev/
- Wasmer: https://wasmer.io/

