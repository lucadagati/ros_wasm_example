# Implementation Plan: ROS Inside WASM

## Current Status vs Target

### ❌ Current Implementation (Prototype)
```
WASM Module (C++) 
  → generateMessage() [solo logica business]
  → JavaScript (roslib.js)
  → ROS Bridge (processo ROS esterno)
  → ROS2 Topic
```

**Problema**: ROS NON esegue dentro WASM. Solo la logica di business è in WASM.

### ✅ Target Implementation (What You Want)
```
WASM Runtime (Wasmtime/Wasmer)
  → microROS Core (compilato in WASM)
  → ROS2 DDS Transport (compilato in WASM)
  → ROS2 Network (comunicazione diretta)
```

**Obiettivo**: ROS esegue completamente dentro WASM. Due nodi ROS in due ambienti WASM comunicano direttamente.

## What Needs to Be Done

### 1. Port microROS to WASM

**microROS** è la versione di ROS2 per dispositivi embedded. Deve essere compilato in WASM.

**Steps**:
- [ ] Ottenere sorgenti microROS (https://github.com/micro-ROS/micro-ROS)
- [ ] Configurare build system per WASM (Emscripten o WASI-SDK)
- [ ] Compilare microROS core in WASM
- [ ] Testare microROS base in WASM runtime

**Dependencies**:
- microROS core (C)
- rcl (ROS Client Library)
- rclc (ROS Client Library C)
- rmw (ROS Middleware)

### 2. Port ROS2 DDS Transport to WASM

**DDS (Data Distribution Service)** è il protocollo di comunicazione di ROS2.

**Options**:
- **Option A**: Portare FastDDS/RTI DDS a WASM
- **Option B**: Implementare un DDS layer minimale in WASM
- **Option C**: Usare un'implementazione DDS esistente compatibile WASM

**Requirements**:
- UDP/TCP networking via WASI
- Multicast support (se necessario)
- Serialization/deserialization in WASM

### 3. Implement WASI Networking

**WASI (WebAssembly System Interface)** permette a WASM di accedere alle risorse di sistema.

**Needed**:
- Socket API (WASI sockets)
- Network I/O
- DNS resolution

**Status**: WASI sockets è in sviluppo. Potrebbe essere necessario:
- Usare polyfill per networking
- Implementare custom host functions
- Usare runtime-specific extensions (Wasmtime, Wasmer)

### 4. Create ROS Publisher in WASM

**Structure**:
```cpp
// publisher_wasm.cpp
#include <rcl/rcl.h>
#include <rclc/rclc.h>
#include <std_msgs/msg/string.h>

// microROS node running in WASM
rcl_node_t node;
rcl_publisher_t publisher;
std_msgs__msg__String msg;

// Initialize ROS in WASM
void init_ros_wasm() {
    rcl_allocator_t allocator = rcl_get_default_allocator();
    rclc_support_t support;
    rclc_support_init(&support, 0, NULL, &allocator);
    rclc_node_init_default(&node, "wasm_publisher", "", &support);
    rclc_publisher_init_default(&publisher, &node, 
        ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String), 
        "/sensor/temperature");
}

// Publish from WASM
void publish_wasm(const char* data) {
    msg.data.data = (char*)data;
    msg.data.size = strlen(data);
    rcl_publish(&publisher, &msg, NULL);
}
```

### 5. Create ROS Subscriber in WASM

**Structure**:
```cpp
// subscriber_wasm.cpp
#include <rcl/rcl.h>
#include <rclc/rclc.h>
#include <std_msgs/msg/string.h>

rcl_node_t node;
rcl_subscription_t subscription;
std_msgs__msg__String msg;

// Callback executed in WASM
void subscription_callback(const void* msgin) {
    const std_msgs__msg__String* msg = (const std_msgs__msg__String*)msgin;
    // Process message in WASM
    process_message_wasm(msg->data.data, msg->data.size);
}

void init_ros_wasm() {
    // ... initialization ...
    rclc_subscription_init_default(&subscription, &node,
        ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String),
        "/sensor/temperature");
}

void spin_wasm() {
    rcl_wait_set_t wait_set;
    // ... setup wait set ...
    rcl_wait(&wait_set, RCL_MS_TO_NS(1000));
    if (rcl_take(&subscription, &msg, NULL, NULL) == RCL_RET_OK) {
        subscription_callback(&msg);
    }
}
```

### 6. Build System for WASM

**Emscripten or WASI-SDK**:
```bash
# Using Emscripten
emcc publisher_wasm.cpp \
    -I/path/to/microROS/include \
    -L/path/to/microROS/lib \
    -lmicro_ros \
    -s WASM=1 \
    -s EXPORTED_FUNCTIONS='["_init_ros_wasm","_publish_wasm"]' \
    -o publisher_wasm.js

# Or using WASI-SDK
clang --target=wasm32-wasi \
    -I/path/to/microROS/include \
    publisher_wasm.c \
    -o publisher_wasm.wasm
```

### 7. Deploy on WASM Runtime (Wasmtime/Wasmer)

**Wasmtime**:
```bash
wasmtime --wasi publisher_wasm.wasm
```

**Wasmer**:
```bash
wasmer run publisher_wasm.wasm
```

### 8. Kubernetes Deployment

**Pod 1 (Publisher)**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wasm-publisher
spec:
  containers:
  - name: wasmtime
    image: wasmtime/wasmtime:latest
    command: ["wasmtime", "--wasi", "/app/publisher.wasm"]
    volumeMounts:
    - name: wasm-code
      mountPath: /app
  volumes:
  - name: wasm-code
    configMap:
      name: publisher-wasm
```

## Implementation Phases

### Phase 1: Research & Setup (1-2 weeks)
- [ ] Research microROS architecture
- [ ] Research WASI networking capabilities
- [ ] Set up build environment (Emscripten/WASI-SDK)
- [ ] Test basic WASM compilation

### Phase 2: microROS Core Porting (2-4 weeks)
- [ ] Port microROS core to WASM
- [ ] Port rcl/rclc libraries
- [ ] Test basic ROS node creation in WASM

### Phase 3: DDS Transport (2-4 weeks)
- [ ] Port/implement DDS layer in WASM
- [ ] Implement networking via WASI
- [ ] Test DDS discovery and communication

### Phase 4: Publisher/Subscriber (1-2 weeks)
- [ ] Implement publisher node in WASM
- [ ] Implement subscriber node in WASM
- [ ] Test communication between two WASM runtimes

### Phase 5: Kubernetes Integration (1-2 weeks)
- [ ] Create K8s manifests
- [ ] Deploy WASM runtimes in pods
- [ ] Test end-to-end communication

## Alternative: Simplified Approach

Se portare microROS completo è troppo complesso, possiamo:

1. **Implementare un ROS2 DDS layer minimale**:
   - Solo publisher/subscriber
   - Messaggi semplici (String, Int32)
   - No servizi, no actions

2. **Usare un'implementazione DDS esistente**:
   - FastDDS (se portabile)
   - RTI DDS (se disponibile)
   - Custom minimal DDS

3. **Proof of Concept**:
   - Due nodi ROS minimi in WASM
   - Comunicazione diretta via DDS
   - Dimostrazione funzionante

## Resources

- microROS: https://github.com/micro-ROS/micro-ROS
- WASI: https://wasi.dev/
- Wasmtime: https://wasmtime.dev/
- Wasmer: https://wasmer.io/
- ROS2 DDS: https://docs.ros.org/en/humble/Concepts/About-DDS-and-ROS-2.html

## Next Steps

1. **Decidere approccio**: Port completo microROS vs implementazione minimale
2. **Setup ambiente**: Emscripten/WASI-SDK + microROS sources
3. **Primo test**: Compilare microROS base in WASM
4. **Iterare**: Aggiungere funzionalità step by step

