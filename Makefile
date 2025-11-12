# Makefile per compilare e gestire il progetto WASM-ROS

.PHONY: all build clean serve rosbridge install help test

# Colori per output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
BLUE=\033[0;34m
NC=\033[0m # No Color

all: build

help:
	@echo "$(BLUE)🚀 WASM-ROS Communication System$(NC)"
	@echo ""
	@echo "$(GREEN)Comandi disponibili:$(NC)"
	@echo "  make build      - Compila i moduli WASM"
	@echo "  make clean      - Pulisce i file compilati"
	@echo "  make serve      - Avvia il web server"
	@echo "  make rosbridge  - Avvia ROS Bridge"
	@echo "  make all        - Compila tutto"
	@echo "  make install    - Installa dipendenze"
	@echo "  make test       - Testa la connessione ROS"
	@echo "  make help       - Mostra questo messaggio"
	@echo ""

build:
	@echo "$(BLUE)🔨 Compilazione moduli WASM...$(NC)"
	@./build.sh
	@echo "$(GREEN)✅ Compilazione completata!$(NC)"

clean:
	@echo "$(YELLOW)🧹 Pulizia file compilati...$(NC)"
	@rm -f public/*.wasm public/*.js public/*.map
	@echo "$(GREEN)✅ Pulizia completata!$(NC)"

serve:
	@echo "$(BLUE)🌐 Avvio web server...$(NC)"
	@./start_webserver.sh

rosbridge:
	@echo "$(BLUE)🌉 Avvio ROS Bridge...$(NC)"
	@./start_rosbridge.sh

install:
	@echo "$(BLUE)📦 Installazione dipendenze...$(NC)"
	@echo "Verifica Emscripten..."
	@command -v emcc >/dev/null 2>&1 || { echo "$(RED)❌ Emscripten non trovato!$(NC)"; exit 1; }
	@echo "$(GREEN)✅ Emscripten OK$(NC)"
	@echo "Verifica ROS2..."
	@command -v ros2 >/dev/null 2>&1 || { echo "$(YELLOW)⚠️  ROS2 non trovato$(NC)"; }
	@echo "Verifica Python3..."
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)❌ Python3 non trovato!$(NC)"; exit 1; }
	@echo "$(GREEN)✅ Python3 OK$(NC)"
	@echo "$(GREEN)✅ Dipendenze verificate!$(NC)"

test:
	@echo "$(BLUE)🧪 Test connessione ROS...$(NC)"
	@command -v ros2 >/dev/null 2>&1 || { echo "$(RED)❌ ROS2 non disponibile$(NC)"; exit 1; }
	@bash -c "source /opt/ros/humble/setup.bash 2>/dev/null || source /opt/ros/foxy/setup.bash 2>/dev/null; ros2 topic list"

rebuild: clean build

start: build
	@echo "$(BLUE)🚀 Avvio sistema completo...$(NC)"
	@./start_all.sh

