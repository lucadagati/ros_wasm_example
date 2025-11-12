#!/bin/bash

# Script per avviare tutto il sistema in terminali separati

echo "🚀 Avvio completo del sistema WASM-ROS..."
echo ""

# Verifica che i file WASM siano stati compilati
if [ ! -f "public/publisher_module.wasm" ] || [ ! -f "public/subscriber_module.wasm" ]; then
    echo "⚠️  Moduli WASM non trovati, eseguo la compilazione..."
    ./build.sh
    if [ $? -ne 0 ]; then
        echo "❌ Compilazione fallita. Risolvi gli errori e riprova."
        exit 1
    fi
fi

echo "📋 Avvio componenti del sistema..."
echo ""

# Funzione per controllare se un comando è disponibile
check_terminal() {
    if command -v $1 &> /dev/null; then
        return 0
    fi
    return 1
}

# Scegli il terminale disponibile
TERMINAL=""
if check_terminal gnome-terminal; then
    TERMINAL="gnome-terminal"
elif check_terminal xterm; then
    TERMINAL="xterm"
elif check_terminal konsole; then
    TERMINAL="konsole"
fi

if [ -z "$TERMINAL" ]; then
    echo "⚠️  Nessun emulatore di terminale trovato."
    echo "Avvia manualmente in 2 terminali separati:"
    echo "  Terminal 1: ./start_rosbridge.sh"
    echo "  Terminal 2: ./start_webserver.sh"
    echo ""
    echo "Quindi apri nel browser:"
    echo "  http://localhost:8000/publisher.html"
    echo "  http://localhost:8000/subscriber.html"
    exit 1
fi

# Avvia ROS Bridge
if [ "$TERMINAL" = "gnome-terminal" ]; then
    gnome-terminal -- bash -c "./start_rosbridge.sh; exec bash"
    echo "✅ ROS Bridge avviato in nuovo terminale"
elif [ "$TERMINAL" = "xterm" ]; then
    xterm -e "./start_rosbridge.sh" &
    echo "✅ ROS Bridge avviato in nuovo terminale"
elif [ "$TERMINAL" = "konsole" ]; then
    konsole -e "./start_rosbridge.sh" &
    echo "✅ ROS Bridge avviato in nuovo terminale"
fi

sleep 2

# Avvia Web Server
if [ "$TERMINAL" = "gnome-terminal" ]; then
    gnome-terminal -- bash -c "./start_webserver.sh; exec bash"
    echo "✅ Web Server avviato in nuovo terminale"
elif [ "$TERMINAL" = "xterm" ]; then
    xterm -e "./start_webserver.sh" &
    echo "✅ Web Server avviato in nuovo terminale"
elif [ "$TERMINAL" = "konsole" ]; then
    konsole -e "./start_webserver.sh" &
    echo "✅ Web Server avviato in nuovo terminale"
fi

sleep 1

echo ""
echo "🎉 Sistema avviato!"
echo ""
echo "📖 Prossimi passi:"
echo "   1. Apri http://localhost:8000/publisher.html nel browser"
echo "   2. Apri http://localhost:8000/subscriber.html in un'altra tab"
echo "   3. Clicca 'Connetti a ROS' in entrambe le pagine"
echo "   4. Nel Publisher, clicca 'Avvia Pubblicazione'"
echo "   5. Nel Subscriber, clicca 'Iscriviti al Topic'"
echo "   6. Osserva la comunicazione tra i due ambienti WASM!"
echo ""

