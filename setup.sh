#!/bin/bash
# Setup script for microROS in WASM project
# Installs all required tools and dependencies

set -e

echo "=========================================="
echo "microROS in WASM - Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run this script as root${NC}"
   exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

echo "Step 1: Checking system dependencies..."
echo "----------------------------------------"

# Check Python 3
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Python 3 found: $PYTHON_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Python 3 not found. Installing..."
    sudo apt update
    sudo apt install -y python3 python3-pip
    print_status "Python 3 installed"
fi

# Check Git
if command_exists git; then
    echo -e "${GREEN}✓${NC} Git found"
else
    echo -e "${YELLOW}⚠${NC} Git not found. Installing..."
    sudo apt update
    sudo apt install -y git
    print_status "Git installed"
fi

# Check build tools
if command_exists make && command_exists gcc; then
    echo -e "${GREEN}✓${NC} Build tools found"
else
    echo -e "${YELLOW}⚠${NC} Build tools not found. Installing..."
    sudo apt update
    sudo apt install -y build-essential cmake
    print_status "Build tools installed"
fi

echo ""
echo "Step 2: Installing Emscripten SDK..."
echo "----------------------------------------"

EMSDK_DIR="$HOME/emsdk"
if [ -d "$EMSDK_DIR" ]; then
    echo -e "${GREEN}✓${NC} Emscripten SDK directory exists: $EMSDK_DIR"
    echo "  Activating existing installation..."
    source "$EMSDK_DIR/emsdk_env.sh" 2>/dev/null || true
else
    echo "Cloning Emscripten SDK..."
    git clone https://github.com/emscripten-core/emsdk.git "$EMSDK_DIR"
    print_status "Emscripten SDK cloned"
    
    echo "Installing Emscripten..."
    cd "$EMSDK_DIR"
    ./emsdk install latest
    ./emsdk activate latest
    source ./emsdk_env.sh
    print_status "Emscripten installed and activated"
    
    cd - > /dev/null
fi

# Verify Emscripten
if command_exists emcc; then
    EMC_VERSION=$(emcc --version | head -n1)
    echo -e "${GREEN}✓${NC} Emscripten found: $EMC_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Activating Emscripten..."
    source "$EMSDK_DIR/emsdk_env.sh"
    if command_exists emcc; then
        echo -e "${GREEN}✓${NC} Emscripten activated"
    else
        echo -e "${RED}✗${NC} Failed to activate Emscripten"
        exit 1
    fi
fi

# Add Emscripten to shell profile
SHELL_PROFILE=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
fi

if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q "emsdk_env.sh" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# Emscripten SDK" >> "$SHELL_PROFILE"
        echo "source $EMSDK_DIR/emsdk_env.sh > /dev/null 2>&1" >> "$SHELL_PROFILE"
        echo -e "${GREEN}✓${NC} Added Emscripten to $SHELL_PROFILE"
    fi
fi

echo ""
echo "Step 3: Installing Python dependencies..."
echo "----------------------------------------"

if command_exists pip3; then
    echo "Installing Python packages..."
    pip3 install --user -r requirements.txt 2>/dev/null || \
    pip3 install --break-system-packages -r requirements.txt 2>/dev/null || \
    sudo pip3 install -r requirements.txt
    print_status "Python dependencies installed"
else
    echo -e "${YELLOW}⚠${NC} pip3 not found. Installing..."
    sudo apt update
    sudo apt install -y python3-pip
    pip3 install --user -r requirements.txt 2>/dev/null || \
    pip3 install --break-system-packages -r requirements.txt 2>/dev/null || \
    sudo pip3 install -r requirements.txt
    print_status "Python dependencies installed"
fi

echo ""
echo "Step 4: ROS2 Installation (Optional)..."
echo "----------------------------------------"

read -p "Do you want to install ROS2 Humble? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "/opt/ros/humble/setup.bash" ]; then
        echo -e "${GREEN}✓${NC} ROS2 Humble already installed"
    else
        echo "Installing ROS2 Humble..."
        echo "  This will take several minutes..."
        
        # Check Ubuntu version
        UBUNTU_VERSION=$(lsb_release -rs)
        if [ "$(echo "$UBUNTU_VERSION >= 22.04" | bc)" -eq 1 ]; then
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository universe
            sudo apt update && sudo apt install -y curl gnupg lsb-release
            
            sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2-latest.list > /dev/null
            
            sudo apt update
            sudo apt install -y ros-humble-desktop ros-humble-rosbridge-suite
            
            # Setup ROS2 environment
            if [ -f "$HOME/.bashrc" ]; then
                if ! grep -q "ros-humble/setup.bash" "$HOME/.bashrc"; then
                    echo "" >> "$HOME/.bashrc"
                    echo "# ROS2 Humble" >> "$HOME/.bashrc"
                    echo "source /opt/ros/humble/setup.bash" >> "$HOME/.bashrc"
                fi
            fi
            
            print_status "ROS2 Humble installed"
        else
            echo -e "${RED}✗${NC} ROS2 Humble requires Ubuntu 22.04 or later"
            echo "  Current version: Ubuntu $UBUNTU_VERSION"
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} ROS2 installation skipped"
    echo "  You can install it later if needed for testing"
fi

echo ""
echo "Step 5: Building WASM modules..."
echo "----------------------------------------"

if [ -f "build.sh" ]; then
    chmod +x build.sh
    echo "Running build script..."
    ./build.sh
    print_status "WASM modules built"
else
    echo -e "${YELLOW}⚠${NC} build.sh not found"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Source Emscripten (if not in your shell profile):"
echo "   source $EMSDK_DIR/emsdk_env.sh"
echo ""
echo "2. Build WASM modules:"
echo "   ./build.sh"
echo ""
echo "3. Start the system:"
echo "   ./start_all.sh"
echo ""
echo "4. Open in browser:"
echo "   http://localhost:8000/publisher.html"
echo "   http://localhost:8000/subscriber.html"
echo ""
echo "For ROS2 (if installed):"
echo "   source /opt/ros/humble/setup.bash"
echo "   ./start_rosbridge.sh"
echo ""

