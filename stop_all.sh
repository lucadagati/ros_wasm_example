#!/bin/bash

# Script per fermare tutti i servizi avviati da start_all.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Stopping WASM-ROS services...${NC}"
echo ""

# Stop ROS Bridge
if [ -f "/tmp/rosbridge.pid" ]; then
    ROS_PID=$(cat /tmp/rosbridge.pid)
    if ps -p $ROS_PID > /dev/null 2>&1; then
        # Kill main process and all children
        pkill -P $ROS_PID 2>/dev/null
        kill $ROS_PID 2>/dev/null
        sleep 1
        # Force kill if still running
        if ps -p $ROS_PID > /dev/null 2>&1; then
            kill -9 $ROS_PID 2>/dev/null
        fi
        echo -e "${GREEN}✓${NC} ROS Bridge stopped (PID: $ROS_PID)"
    else
        echo -e "${YELLOW}⚠${NC} ROS Bridge process not found"
    fi
    rm -f /tmp/rosbridge.pid
fi

# Kill any remaining ROS Bridge processes by port
ROS_PIDS=$(lsof -ti:9090 2>/dev/null)
if [ -n "$ROS_PIDS" ]; then
    for pid in $ROS_PIDS; do
        pkill -P $pid 2>/dev/null
        kill $pid 2>/dev/null
        sleep 0.5
        if ps -p $pid > /dev/null 2>&1; then
            kill -9 $pid 2>/dev/null
        fi
    done
    echo -e "${GREEN}✓${NC} ROS Bridge stopped (found by port)"
fi

# Stop Web Server
if [ -f "/tmp/webserver.pid" ]; then
    WEB_PID=$(cat /tmp/webserver.pid)
    if ps -p $WEB_PID > /dev/null 2>&1; then
        kill $WEB_PID 2>/dev/null
        echo -e "${GREEN}✓${NC} Web Server stopped (PID: $WEB_PID)"
    else
        echo -e "${YELLOW}⚠${NC} Web Server process not found"
    fi
    rm -f /tmp/webserver.pid
else
    # Try to find and kill by port
    WEB_PID=$(lsof -ti:8000 2>/dev/null)
    if [ -n "$WEB_PID" ]; then
        kill $WEB_PID 2>/dev/null
        echo -e "${GREEN}✓${NC} Web Server stopped (found by port)"
    fi
fi

# Clean up log files
rm -f /tmp/rosbridge.log /tmp/webserver.log

echo ""
echo -e "${GREEN}All services stopped${NC}"

