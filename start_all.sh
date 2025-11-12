#!/bin/bash

# Script per avviare tutto il sistema WASM-ROS
# Gestisce ROS Bridge e Web Server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ROS_BRIDGE_PORT=9090
WEB_SERVER_PORT=8000
BACKGROUND_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--background)
            BACKGROUND_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -b, --background    Start services in background"
            echo "  -h, --help          Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}microROS in WASM - System Startup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to kill process on port
kill_port() {
    local port=$1
    local pid=$(lsof -ti:$port 2>/dev/null)
    if [ -n "$pid" ]; then
        echo -e "${YELLOW}⚠${NC} Port $port is in use (PID: $pid), killing..."
        kill -9 $pid 2>/dev/null || true
        sleep 1
    fi
}

# Check if WASM modules are compiled
if [ ! -f "public/publisher_module.wasm" ] || [ ! -f "public/subscriber_module.wasm" ]; then
    echo -e "${YELLOW}⚠${NC} WASM modules not found, compiling..."
    if [ -f "build.sh" ]; then
        ./build.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗${NC} Build failed. Fix errors and try again."
            exit 1
        fi
    else
        echo -e "${RED}✗${NC} build.sh not found!"
        exit 1
    fi
fi

# Check ports
if check_port $ROS_BRIDGE_PORT; then
    echo -e "${YELLOW}⚠${NC} Port $ROS_BRIDGE_PORT (ROS Bridge) is already in use"
    read -p "Kill existing process? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill_port $ROS_BRIDGE_PORT
    else
        echo -e "${RED}✗${NC} Cannot start ROS Bridge. Port $ROS_BRIDGE_PORT is in use."
        exit 1
    fi
fi

if check_port $WEB_SERVER_PORT; then
    echo -e "${YELLOW}⚠${NC} Port $WEB_SERVER_PORT (Web Server) is already in use"
    read -p "Kill existing process? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill_port $WEB_SERVER_PORT
    else
        echo -e "${RED}✗${NC} Cannot start Web Server. Port $WEB_SERVER_PORT is in use."
        exit 1
    fi
fi

# Detect ROS2 version
ROS2_VERSION=""
ROS2_SETUP=""
if [ -f "/opt/ros/jazzy/setup.bash" ]; then
    ROS2_VERSION="jazzy"
    ROS2_SETUP="/opt/ros/jazzy/setup.bash"
elif [ -f "/opt/ros/humble/setup.bash" ]; then
    ROS2_VERSION="humble"
    ROS2_SETUP="/opt/ros/humble/setup.bash"
elif [ -f "/opt/ros/foxy/setup.bash" ]; then
    ROS2_VERSION="foxy"
    ROS2_SETUP="/opt/ros/foxy/setup.bash"
fi

# Check ROS2 installation
if [ -z "$ROS2_VERSION" ]; then
    echo -e "${YELLOW}⚠${NC} ROS2 not found. Web server will start, but ROS Bridge requires ROS2."
    echo "  Install ROS2 with: ./setup.sh"
    ROS2_AVAILABLE=false
else
    ROS2_AVAILABLE=true
    echo -e "${GREEN}✓${NC} ROS2 $ROS2_VERSION detected"
fi

# Function to start ROS Bridge
start_rosbridge() {
    if [ "$ROS2_AVAILABLE" = false ]; then
        echo -e "${YELLOW}⚠${NC} Skipping ROS Bridge (ROS2 not installed)"
        return 1
    fi
    
    echo -e "${BLUE}Starting ROS Bridge on port $ROS_BRIDGE_PORT...${NC}"
    
    if [ "$BACKGROUND_MODE" = true ]; then
        # Start in background
        source "$ROS2_SETUP" > /dev/null 2>&1
        ros2 launch rosbridge_server rosbridge_websocket_launch.xml > /tmp/rosbridge.log 2>&1 &
        ROS_BRIDGE_PID=$!
        echo $ROS_BRIDGE_PID > /tmp/rosbridge.pid
        echo -e "${GREEN}✓${NC} ROS Bridge started in background (PID: $ROS_BRIDGE_PID)"
        echo "  Logs: /tmp/rosbridge.log"
    else
        # Start in new terminal or foreground
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal --title="ROS Bridge" -- bash -c "source $ROS2_SETUP && ros2 launch rosbridge_server rosbridge_websocket_launch.xml; exec bash" &
            echo -e "${GREEN}✓${NC} ROS Bridge started in new terminal"
        elif command -v xterm &> /dev/null; then
            xterm -title "ROS Bridge" -e "source $ROS2_SETUP && ros2 launch rosbridge_server rosbridge_websocket_launch.xml" &
            echo -e "${GREEN}✓${NC} ROS Bridge started in new terminal"
        elif command -v konsole &> /dev/null; then
            konsole -e "source $ROS2_SETUP && ros2 launch rosbridge_server rosbridge_websocket_launch.xml" &
            echo -e "${GREEN}✓${NC} ROS Bridge started in new terminal"
        else
            # No GUI terminal, start in background
            source "$ROS2_SETUP" > /dev/null 2>&1
            ros2 launch rosbridge_server rosbridge_websocket_launch.xml > /tmp/rosbridge.log 2>&1 &
            ROS_BRIDGE_PID=$!
            echo $ROS_BRIDGE_PID > /tmp/rosbridge.pid
            echo -e "${GREEN}✓${NC} ROS Bridge started in background (PID: $ROS_BRIDGE_PID)"
            echo "  Logs: /tmp/rosbridge.log"
        fi
    fi
    
    sleep 2
    return 0
}

# Function to start Web Server
start_webserver() {
    echo -e "${BLUE}Starting Web Server on port $WEB_SERVER_PORT...${NC}"
    
    if [ "$BACKGROUND_MODE" = true ]; then
        # Start in background
        cd public
        python3 -m http.server $WEB_SERVER_PORT > /tmp/webserver.log 2>&1 &
        WEB_SERVER_PID=$!
        echo $WEB_SERVER_PID > /tmp/webserver.pid
        cd ..
        echo -e "${GREEN}✓${NC} Web Server started in background (PID: $WEB_SERVER_PID)"
        echo "  Logs: /tmp/webserver.log"
    else
        # Start in new terminal or foreground
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal --title="Web Server" --working-directory="$(pwd)/public" -- bash -c "python3 -m http.server $WEB_SERVER_PORT; exec bash" &
            echo -e "${GREEN}✓${NC} Web Server started in new terminal"
        elif command -v xterm &> /dev/null; then
            xterm -title "Web Server" -e "cd $(pwd)/public && python3 -m http.server $WEB_SERVER_PORT" &
            echo -e "${GREEN}✓${NC} Web Server started in new terminal"
        elif command -v konsole &> /dev/null; then
            konsole -e "cd $(pwd)/public && python3 -m http.server $WEB_SERVER_PORT" &
            echo -e "${GREEN}✓${NC} Web Server started in new terminal"
        else
            # No GUI terminal, start in background
            cd public
            python3 -m http.server $WEB_SERVER_PORT > /tmp/webserver.log 2>&1 &
            WEB_SERVER_PID=$!
            echo $WEB_SERVER_PID > /tmp/webserver.pid
            cd ..
            echo -e "${GREEN}✓${NC} Web Server started in background (PID: $WEB_SERVER_PID)"
            echo "  Logs: /tmp/webserver.log"
        fi
    fi
    
    sleep 1
}

# Start services
echo ""
echo -e "${BLUE}Starting system components...${NC}"
echo ""

start_rosbridge
start_webserver

# Wait a bit for services to start
sleep 2

# Verify services are running
echo ""
echo -e "${BLUE}Verifying services...${NC}"

if check_port $WEB_SERVER_PORT; then
    echo -e "${GREEN}✓${NC} Web Server is running on port $WEB_SERVER_PORT"
else
    echo -e "${RED}✗${NC} Web Server failed to start"
fi

if [ "$ROS2_AVAILABLE" = true ]; then
    if check_port $ROS_BRIDGE_PORT; then
        echo -e "${GREEN}✓${NC} ROS Bridge is running on port $ROS_BRIDGE_PORT"
    else
        echo -e "${YELLOW}⚠${NC} ROS Bridge may not be running (check logs)"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}System Started Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Services:${NC}"
echo "  • Web Server:    http://localhost:$WEB_SERVER_PORT"
if [ "$ROS2_AVAILABLE" = true ]; then
    echo "  • ROS Bridge:    ws://localhost:$ROS_BRIDGE_PORT"
fi
echo ""
echo -e "${BLUE}Pages:${NC}"
echo "  • Publisher:     http://localhost:$WEB_SERVER_PORT/publisher.html"
echo "  • Subscriber:    http://localhost:$WEB_SERVER_PORT/subscriber.html"
echo ""

if [ "$BACKGROUND_MODE" = true ]; then
    echo -e "${BLUE}Background Mode:${NC}"
    echo "  • ROS Bridge PID: $(cat /tmp/rosbridge.pid 2>/dev/null || echo 'N/A')"
    echo "  • Web Server PID: $(cat /tmp/webserver.pid 2>/dev/null || echo 'N/A')"
    echo ""
    echo "To stop services:"
    echo "  ./stop_all.sh"
    echo "  or"
    echo "  kill \$(cat /tmp/rosbridge.pid) \$(cat /tmp/webserver.pid)"
    echo ""
else
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Open http://localhost:$WEB_SERVER_PORT/publisher.html in browser"
    echo "  2. Open http://localhost:$WEB_SERVER_PORT/subscriber.html in another tab"
    echo "  3. Click 'Connect to ROS' in both pages"
    echo "  4. In Publisher, click 'Start Publishing'"
    echo "  5. In Subscriber, click 'Subscribe to Topic'"
    echo "  6. Observe communication between WASM environments!"
    echo ""
fi
