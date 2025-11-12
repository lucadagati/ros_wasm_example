#!/bin/bash

# Script per avviare il web server che serve i file HTML/WASM

echo "🌐 Avvio Web Server..."

PORT=8000

# Verifica che Python3 sia installato
if ! command -v python3 &> /dev/null; then
    echo "❌ Errore: Python3 non trovato!"
    exit 1
fi

cd public

echo "✅ Server HTTP avviato su http://localhost:$PORT"
echo ""
echo "📄 Pagine disponibili:"
echo "   Publisher:  http://localhost:$PORT/publisher.html"
echo "   Subscriber: http://localhost:$PORT/subscriber.html"
echo ""
echo "Premi Ctrl+C per fermare il server"
echo ""

python3 -m http.server $PORT

