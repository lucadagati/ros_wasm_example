#!/bin/bash

# Script di test per verificare che tutto funzioni correttamente

echo "🧪 Test del Sistema WASM-ROS"
echo "=============================="
echo ""

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Funzione di test
test_command() {
    local name=$1
    local cmd=$2
    
    echo -n "Test: $name ... "
    
    if eval $cmd > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 1: Verifica Emscripten
test_command "Emscripten installato" "command -v emcc"

# Test 2: Verifica ROS2
test_command "ROS2 installato" "command -v ros2"

# Test 3: Verifica Python3
test_command "Python3 installato" "command -v python3"

# Test 4: Verifica file sorgenti
test_command "File publisher_module.cpp esiste" "[ -f src/publisher_module.cpp ]"
test_command "File subscriber_module.cpp esiste" "[ -f src/subscriber_module.cpp ]"

# Test 5: Verifica HTML
test_command "File publisher.html esiste" "[ -f public/publisher.html ]"
test_command "File subscriber.html esiste" "[ -f public/subscriber.html ]"

# Test 6: Verifica script eseguibili
test_command "build.sh è eseguibile" "[ -x build.sh ]"
test_command "start_rosbridge.sh è eseguibile" "[ -x start_rosbridge.sh ]"
test_command "start_webserver.sh è eseguibile" "[ -x start_webserver.sh ]"

# Test 7: Verifica porte libere
test_command "Porta 8000 disponibile" "! lsof -Pi :8000 -sTCP:LISTEN -t > /dev/null"
test_command "Porta 9090 disponibile" "! lsof -Pi :9090 -sTCP:LISTEN -t > /dev/null"

# Test 8: Verifica compilazione (se Emscripten disponibile)
if command -v emcc &> /dev/null; then
    echo ""
    echo "🔨 Test compilazione WASM..."
    
    if [ ! -f public/publisher_module.wasm ]; then
        echo -e "${YELLOW}⚠️  Moduli WASM non trovati, provo a compilare...${NC}"
        ./build.sh > /tmp/wasm_build.log 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Compilazione riuscita${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ Compilazione fallita${NC}"
            echo "Log: /tmp/wasm_build.log"
            ((FAILED++))
        fi
    else
        echo -e "${GREEN}✅ Moduli WASM già compilati${NC}"
        ((PASSED++))
    fi
fi

# Test 9: Verifica ROS topics (se ROS è in esecuzione)
if command -v ros2 &> /dev/null; then
    source /opt/ros/humble/setup.bash 2>/dev/null || source /opt/ros/foxy/setup.bash 2>/dev/null
    
    test_command "ROS2 topic list funziona" "ros2 topic list"
fi

echo ""
echo "=============================="
echo "📊 Risultati:"
echo -e "  ${GREEN}Passati: $PASSED${NC}"
echo -e "  ${RED}Falliti: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Tutti i test sono passati!${NC}"
    echo ""
    echo "Prossimi passi:"
    echo "  1. ./build.sh          # Compila i moduli WASM"
    echo "  2. ./start_all.sh      # Avvia il sistema completo"
    echo "  oppure:"
    echo "  make build && make start"
    exit 0
else
    echo -e "${RED}⚠️  Alcuni test sono falliti${NC}"
    echo ""
    echo "Risolvi i problemi e riprova."
    echo "Consulta il README.md per le istruzioni di installazione."
    exit 1
fi

