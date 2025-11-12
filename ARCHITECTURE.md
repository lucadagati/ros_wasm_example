# 🏗️ Architettura del Sistema

Documentazione tecnica dell'architettura WASM-ROS.

## Panoramica

Il sistema implementa una comunicazione distribuita tra due ambienti WebAssembly isolati utilizzando ROS come middleware di comunicazione.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Browser Environment                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────┐              ┌────────────────────┐    │
│  │  Tab 1: Publisher  │              │ Tab 2: Subscriber  │    │
│  ├────────────────────┤              ├────────────────────┤    │
│  │                    │              │                    │    │
│  │  ┌──────────────┐  │              │  ┌──────────────┐  │    │
│  │  │ WASM Module  │  │              │  │ WASM Module  │  │    │
│  │  │ (C++ Logic)  │  │              │  │ (C++ Logic)  │  │    │
│  │  └──────┬───────┘  │              │  └───────▲──────┘  │    │
│  │         │          │              │          │         │    │
│  │  ┌──────▼───────┐  │              │  ┌───────┴──────┐  │    │
│  │  │  JS Glue     │  │              │  │   JS Glue    │  │    │
│  │  │ (Emscripten) │  │              │  │ (Emscripten) │  │    │
│  │  └──────┬───────┘  │              │  └───────▲──────┘  │    │
│  │         │          │              │          │         │    │
│  │  ┌──────▼───────┐  │              │  ┌───────┴──────┐  │    │
│  │  │  roslib.js   │  │              │  │  roslib.js   │  │    │
│  │  └──────┬───────┘  │              │  └───────▲──────┘  │    │
│  └─────────┼──────────┘              └──────────┼─────────┘    │
│            │                                    │               │
│            │         WebSocket Connection       │               │
│            └─────────────────┬──────────────────┘               │
└──────────────────────────────┼──────────────────────────────────┘
                               │
                               │ ws://localhost:9090
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                     ROS Bridge Server                            │
├─────────────────────────────────────────────────────────────────┤
│  - WebSocket ↔ ROS Protocol Translation                         │
│  - JSON ↔ ROS Message Conversion                                │
│  - Topic/Service Management                                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ ROS2 DDS/RTPS
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                      ROS2 Core System                            │
├─────────────────────────────────────────────────────────────────┤
│  - Topic: /sensor/temperature (std_msgs/String)                 │
│  - DDS Discovery                                                 │
│  - Message Routing                                               │
│  - QoS Management                                                │
└─────────────────────────────────────────────────────────────────┘
```

## Componenti Principali

### 1. Moduli WebAssembly

#### Publisher Module (`publisher_module.cpp`)

**Responsabilità:**
- Simulare un sensore fisico (temperatura)
- Generare dati periodicamente
- Preparare messaggi in formato JSON

**Classe Principale: `PublisherNode`**
```cpp
class PublisherNode {
    int message_count;           // Contatore messaggi
    double sensor_value;         // Valore sensore corrente
    
    std::string generateMessage(); // Genera messaggio JSON
    int getMessageCount();
    double getSensorValue();
    void reset();
};
```

**Flusso di Esecuzione:**
1. JavaScript chiama `generateMessage()` ogni secondo
2. WASM genera valore sensore (20-30°C)
3. Formatta in JSON: `{"id": N, "sensor": "temperature", "value": X, "unit": "celsius"}`
4. Ritorna stringa a JavaScript
5. JavaScript pubblica su ROS topic

#### Subscriber Module (`subscriber_module.cpp`)

**Responsabilità:**
- Ricevere dati dal topic ROS
- Processare/analizzare dati
- Determinare azioni (es: attivare raffreddamento)

**Classe Principale: `SubscriberNode`**
```cpp
class SubscriberNode {
    int messages_received;                // Contatore
    std::vector<double> received_values;  // Storia valori
    double last_value;                    // Ultimo valore
    std::string last_message;            // Ultimo messaggio
    
    void processMessage(std::string);    // Processa messaggio
    double getAverageValue();            // Calcola media
    int getMessagesReceived();
};
```

**Flusso di Esecuzione:**
1. JavaScript riceve messaggio dal topic ROS
2. Passa stringa JSON a `processMessage()`
3. WASM parsa JSON, estrae valore
4. Applica logica (if temp > 25°C → allarme)
5. Aggiorna statistiche (media, contatori)
6. JavaScript legge risultati e aggiorna UI

### 2. Layer JavaScript/HTML

#### Interfaccia Publisher (`publisher.html`)

**Componenti:**
1. **Caricamento WASM:**
```javascript
const module = await import('./publisher_module.js');
await module.default();
publisherNode = new module.PublisherNode();
```

2. **Connessione ROS:**
```javascript
ros = new ROSLIB.Ros({ url: 'ws://localhost:9090' });
publisher = new ROSLIB.Topic({
    ros: ros,
    name: '/sensor/temperature',
    messageType: 'std_msgs/String'
});
```

3. **Loop Pubblicazione:**
```javascript
setInterval(() => {
    const messageData = publisherNode.generateMessage();
    const message = new ROSLIB.Message({ data: messageData });
    publisher.publish(message);
}, 1000);
```

#### Interfaccia Subscriber (`subscriber.html`)

**Componenti:**
1. **Caricamento WASM:** (analogo a publisher)

2. **Subscription ROS:**
```javascript
subscriber = new ROSLIB.Topic({
    ros: ros,
    name: '/sensor/temperature',
    messageType: 'std_msgs/String'
});

subscriber.subscribe(function(message) {
    subscriberNode.processMessage(message.data);
    // Aggiorna UI
});
```

### 3. ROS Bridge

**Funzione:** Traduttore bidirezionale WebSocket ↔ ROS

**Protocollo WebSocket:**
- **Port:** 9090
- **Format:** JSON
- **Operations:**
  - `advertise` - Crea publisher
  - `publish` - Pubblica messaggio
  - `subscribe` - Iscriviti a topic
  - `unsubscribe` - Annulla iscrizione

**Esempio Messaggio Publish:**
```json
{
  "op": "publish",
  "topic": "/sensor/temperature",
  "msg": {
    "data": "{\"id\":1,\"sensor\":\"temperature\",\"value\":22.5,\"unit\":\"celsius\"}"
  }
}
```

### 4. ROS2 Core

**Topic Configuration:**
- **Name:** `/sensor/temperature`
- **Type:** `std_msgs/String`
- **QoS:** Default (Reliable, Volatile)

**DDS Layer:**
- Discovery: Multicast/Unicast
- Transport: UDP/Shared Memory
- Serialization: CDR

## Flusso Dati Completo

### Pubblicazione (Publisher → Subscriber)

```
1. Timer JavaScript (1000ms)
   ↓
2. publisherNode.generateMessage() [WASM]
   ↓ return JSON string
3. new ROSLIB.Message({ data: json })
   ↓
4. publisher.publish(message)
   ↓
5. WebSocket send to ROS Bridge
   ↓
6. ROS Bridge converts to ROS message
   ↓
7. ROS2 DDS publishes to /sensor/temperature
   ↓
8. ROS2 DDS delivers to subscribers
   ↓
9. ROS Bridge receives from topic
   ↓
10. WebSocket sends to subscriber
    ↓
11. subscriber callback receives message
    ↓
12. subscriberNode.processMessage(json) [WASM]
    ↓
13. Update UI with results
```

**Latency Breakdown:**
- JavaScript Timer: ~1ms jitter
- WASM Call: <1ms
- WebSocket: 1-5ms (local)
- ROS Bridge: 1-3ms
- ROS2 DDS: 1-10ms (local)
- Total: ~5-20ms (local network)

## Compilazione WASM

### Emscripten Build Process

**Comando:**
```bash
emcc src/publisher_module.cpp \
    -o public/publisher_module.js \
    -s WASM=1 \                    # Genera WASM
    -s MODULARIZE=1 \              # ES6 module
    -s EXPORT_ES6=1 \              # Export ES6
    -s ENVIRONMENT='web' \         # Target browser
    -s ALLOW_MEMORY_GROWTH=1 \     # Dynamic memory
    -lembind \                     # C++ binding
    -O3                            # Optimization
```

**Output Files:**
- `publisher_module.js` - Glue code JavaScript
- `publisher_module.wasm` - Binary WebAssembly

**Binding Mechanism (embind):**
```cpp
EMSCRIPTEN_BINDINGS(publisher_module) {
    class_<PublisherNode>("PublisherNode")
        .constructor<>()
        .function("generateMessage", &PublisherNode::generateMessage);
}
```

Questo genera automaticamente:
- Type checking JavaScript
- Memory management
- String conversion (C++ ↔ JS)
- Exception handling

## Sicurezza

### Isolamento WASM

1. **Sandbox:** WASM esegue in sandbox sicuro
2. **Memory Safety:** No buffer overflow possibili
3. **No System Calls:** Nessun accesso diretto al sistema
4. **Controlled Import:** Solo funzioni JS esposte accessibili

### Comunicazione ROS

1. **WebSocket:** Non criptato di default (localhost OK)
2. **Production:** Usare WSS (WebSocket Secure)
3. **Authentication:** rosbridge supporta auth plugins
4. **CORS:** Configurare per production

## Performance

### Ottimizzazioni WASM

1. **Compilation:**
   - `-O3` - Massima ottimizzazione
   - LLVM backend ottimizzazioni aggressive

2. **Memory:**
   - Linear memory growth
   - Stack/Heap separati
   - Garbage collection JavaScript handle

3. **Calls:**
   - JavaScript ↔ WASM calls: ~10-50ns
   - Molto più veloce di JSON parse/stringify

### Ottimizzazioni ROS

1. **QoS:**
   - Best Effort per dati non critici
   - Reliable per dati importanti

2. **Serialization:**
   - std_msgs/String: semplice ma non ottimale
   - Considerare messaggi custom binari

3. **Bridge:**
   - Keep-alive connections
   - Message batching possibile

## Scalabilità

### Horizontal Scaling

**Multiple Publishers:**
```
Publisher 1 → 
Publisher 2 → ROS Bridge → Topic → Subscriber(s)
Publisher N →
```

**Multiple Subscribers:**
```
              → Subscriber 1
Topic → ROS Bridge → Subscriber 2
              → Subscriber N
```

### Deployment Scenarios

1. **Single Machine:**
   - Tutto su localhost
   - Best latency

2. **Local Network:**
   - ROS Bridge su server
   - Browsers connessi via LAN
   - <10ms latency

3. **Internet:**
   - WSS connection
   - Authentication required
   - 50-200ms latency

## Testing

### Unit Testing WASM

```bash
# Compile for Node.js
emcc src/publisher_module.cpp \
    -o test/publisher_test.js \
    -s ENVIRONMENT='node' \
    -lembind

# Run tests
node test/publisher_test.js
```

### Integration Testing

```bash
# Start ROS Bridge
./start_rosbridge.sh &

# Run test publisher
ros2 topic pub /sensor/temperature std_msgs/String \
    "data: '{\"id\":1,\"value\":25.5}'" -r 1

# Monitor
ros2 topic echo /sensor/temperature
```

### Performance Testing

```bash
# Message rate
ros2 topic hz /sensor/temperature

# Latency
ros2 topic delay /sensor/temperature

# Bandwidth
ros2 topic bw /sensor/temperature
```

## Estensioni Future

### 1. Binary Messages
- Usare `std_msgs/ByteMultiArray` invece di String
- Serializzare in WASM con Protocol Buffers
- 10x più efficiente

### 2. Bidirectional Control
- Publisher riceve comandi (ROS Services)
- Dynamic parameter adjustment

### 3. Multiple Topics
- Più sensori su topics diversi
- Topic namespacing
- QoS per tipo di dato

### 4. State Management
- Shared state via ROS Parameters
- Persistent storage
- Session recovery

### 5. Visualization
- Real-time charts (Chart.js/D3.js)
- 3D visualization (Three.js)
- RViz integration

---

**Per domande o contributi, consulta README.md**

