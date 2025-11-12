#!/bin/bash

# Script per avviare ROS Bridge
# Permette la comunicazione tra i moduli WASM e ROS

echo "🚀 Avvio ROS Bridge WebSocket Server..."

# Verifica che ROS2 sia installato
if ! command -v ros2 &> /dev/null; then
    echo "❌ Errore: ROS2 non trovato!"
    echo ""
    echo "Opzioni:"
    echo "1. Installa ROS2 da: https://docs.ros.org/en/humble/Installation.html"
    echo "2. Oppure usa la versione Python standalone con rosbridge_server"
    echo ""
    echo "Per la versione Python standalone:"
    echo "  pip install tornado autobahn"
    echo "  pip install rosbridge_suite"
    echo "  rosbridge_websocket"
    exit 1
fi

# Source del workspace ROS2 (auto-detect version)
if [ -f "/opt/ros/jazzy/setup.bash" ]; then
    source /opt/ros/jazzy/setup.bash
    echo "✅ ROS2 Jazzy environment loaded"
elif [ -f "/opt/ros/humble/setup.bash" ]; then
    source /opt/ros/humble/setup.bash
    echo "✅ ROS2 Humble environment loaded"
elif [ -f "/opt/ros/foxy/setup.bash" ]; then
    source /opt/ros/foxy/setup.bash
    echo "✅ ROS2 Foxy environment loaded"
else
    echo "⚠️  ROS2 setup not found, trying anyway..."
fi

# Verifica che rosbridge_server sia installato
if ! ros2 pkg list | grep -q rosbridge_server; then
    echo "❌ rosbridge_server non installato!"
    echo "Installa con: sudo apt install ros-humble-rosbridge-suite"
    echo "O usa pip: pip install rosbridge_suite"
    exit 1
fi

echo "🌉 Avvio rosbridge_server sulla porta 9090..."
echo "📡 WebSocket URL: ws://localhost:9090"
echo ""
echo "Premi Ctrl+C per fermare il server"
echo ""

ros2 launch rosbridge_server rosbridge_websocket_launch.xml

