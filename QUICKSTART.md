# 🚀 Quick Start Guide

Guida rapida per iniziare in 5 minuti!

## Opzione 1: Demo Rapida (Senza WASM)

Se vuoi vedere subito come funziona la comunicazione ROS senza compilare i moduli WASM:

### 1. Avvia ROS Bridge

```bash
./start_rosbridge.sh
```

### 2. Avvia Web Server (in un altro terminale)

```bash
./start_webserver.sh
```

### 3. Apri i browser

- Publisher: http://localhost:8000/simple_publisher.html
- Subscriber: http://localhost:8000/simple_subscriber.html

### 4. Usa l'interfaccia

**Nel Publisher:**
1. Clicca "Connetti"
2. Clicca "Avvia"

**Nel Subscriber:**
1. Clicca "Connetti"
2. Clicca "Iscriviti"

✅ Funziona! Ora vedi la comunicazione in tempo reale!

---

## Opzione 2: Versione Completa con WASM

Per usare i veri moduli WebAssembly con C++:

### Prerequisiti

1. **Installa Emscripten** (una volta sola):

```bash
# Download
git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
cd ~/emsdk

# Installa
./emsdk install latest
./emsdk activate latest

# Attiva (da fare ogni volta che apri un nuovo terminale)
source ~/emsdk/emsdk_env.sh
```

2. **Installa ROS2** (se non lo hai già):

Ubuntu/Debian:
```bash
sudo apt update
sudo apt install ros-humble-desktop ros-humble-rosbridge-suite
```

### Compilazione e Avvio

```bash
# 1. Torna alla directory del progetto
cd /home/lucadag/wasm_test

# 2. Attiva Emscripten
source ~/emsdk/emsdk_env.sh

# 3. Compila i moduli WASM
./build.sh

# 4. Avvia tutto
./start_all.sh
```

### Usa l'interfaccia

Apri:
- Publisher: http://localhost:8000/publisher.html
- Subscriber: http://localhost:8000/subscriber.html

**Nel Publisher:**
1. Clicca "🔌 Connetti a ROS"
2. Clicca "▶️ Avvia Pubblicazione"

**Nel Subscriber:**
1. Clicca "🔌 Connetti a ROS"
2. Clicca "📡 Iscriviti al Topic"

🎉 Ora hai due moduli WASM che comunicano tramite ROS!

---

## Opzione 3: Con Make

Se preferisci usare Make:

```bash
# Test sistema
make test

# Compila
make build

# Avvia
make start
```

---

## Opzione 4: Con Docker

Se hai Docker installato:

```bash
# Build container
docker-compose build

# Avvia
docker-compose up -d

# Entra nel container
docker exec -it wasm-ros-communication bash

# Dentro il container
cd /workspace
./build.sh
./start_all.sh
```

---

## Verifica ROS (Opzionale)

In un terminale separato, puoi monitorare i messaggi ROS:

```bash
# Source ROS
source /opt/ros/humble/setup.bash

# Lista topics
ros2 topic list

# Mostra messaggi
ros2 topic echo /sensor/temperature

# Info topic
ros2 topic info /sensor/temperature
```

---

## Troubleshooting Veloce

### "emcc: command not found"
```bash
source ~/emsdk/emsdk_env.sh
```

### "ros2: command not found"
```bash
source /opt/ros/humble/setup.bash
```

### "Failed to connect to ROS Bridge"
Assicurati che `./start_rosbridge.sh` sia in esecuzione

### Porta già in uso
```bash
# Trova processo sulla porta 9090
lsof -i :9090
# Uccidi il processo
kill -9 <PID>
```

---

## Cosa Sta Succedendo?

1. **ROS Bridge** crea un WebSocket server sulla porta 9090
2. **Publisher** genera dati (temperatura) in WASM e li pubblica sul topic `/sensor/temperature`
3. **ROS** inoltra i messaggi attraverso il sistema
4. **Subscriber** riceve i messaggi e li processa in WASM
5. L'interfaccia web mostra tutto in tempo reale!

```
Browser 1 (WASM) → ROS Bridge → ROS Topics → ROS Bridge → Browser 2 (WASM)
```

---

## File Importanti

- `publisher.html` / `subscriber.html` - Versione completa con WASM
- `simple_publisher.html` / `simple_subscriber.html` - Versione JavaScript pura
- `src/*.cpp` - Codice C++ dei moduli WASM
- `build.sh` - Compila C++ → WASM
- `start_rosbridge.sh` - Avvia server ROS
- `start_webserver.sh` - Avvia server HTTP
- `README.md` - Documentazione completa

---

## Prossimi Passi

- 📖 Leggi `README.md` per capire l'architettura
- 🔧 Modifica `src/publisher_module.cpp` per cambiare la logica del sensore
- 🔧 Modifica `src/subscriber_module.cpp` per cambiare la logica di controllo
- 🎨 Personalizza le interfacce HTML
- 📊 Aggiungi più sensori/attuatori
- 🌐 Deploy su un server reale

---

**Hai domande? Controlla README.md per la documentazione completa!**

