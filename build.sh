#!/bin/bash

# Script per compilare i moduli C++ in WebAssembly
# Richiede Emscripten SDK installato

echo "🔨 Compilazione moduli WASM per ROS..."

# Verifica che emcc sia disponibile
if ! command -v emcc &> /dev/null; then
    echo "❌ Errore: Emscripten non trovato!"
    echo "Installa Emscripten SDK da: https://emscripten.org/docs/getting_started/downloads.html"
    echo ""
    echo "Quick install:"
    echo "  git clone https://github.com/emscripten-core/emsdk.git"
    echo "  cd emsdk"
    echo "  ./emsdk install latest"
    echo "  ./emsdk activate latest"
    echo "  source ./emsdk_env.sh"
    exit 1
fi

# Crea directory public se non esiste
mkdir -p public

echo "📦 Compilazione Publisher Module..."
emcc src/publisher_module.cpp \
    -o public/publisher_module.js \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_ES6=1 \
    -s EXPORT_NAME='createPublisherModule' \
    -s ENVIRONMENT='web' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -lembind \
    -O3

if [ $? -eq 0 ]; then
    echo "✅ Publisher module compilato con successo!"
else
    echo "❌ Errore nella compilazione del Publisher module"
    exit 1
fi

echo "📦 Compilazione Subscriber Module..."
emcc src/subscriber_module.cpp \
    -o public/subscriber_module.js \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_ES6=1 \
    -s EXPORT_NAME='createSubscriberModule' \
    -s ENVIRONMENT='web' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -lembind \
    -O3

if [ $? -eq 0 ]; then
    echo "✅ Subscriber module compilato con successo!"
else
    echo "❌ Errore nella compilazione del Subscriber module"
    exit 1
fi

echo ""
echo "🎉 Compilazione completata!"
echo "📁 File WASM generati in: public/"
ls -lh public/*.wasm public/*.js | grep -E "\.(wasm|js)$"

