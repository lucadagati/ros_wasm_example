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

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo -e "${YELLOW}⚠${NC} requirements.txt not found, skipping Python dependencies"
else
    # Filter out ROS2 packages (they can't be installed via pip)
    # Create a temporary requirements file without ROS2 packages
    TEMP_REQUIREMENTS=$(mktemp)
    grep -v -E "^(rclpy|std_msgs|rosbridge_suite|#.*ROS)" requirements.txt > "$TEMP_REQUIREMENTS" 2>/dev/null || true
    
    # Check if there are any packages to install
    if [ ! -s "$TEMP_REQUIREMENTS" ] || [ "$(grep -v '^#' "$TEMP_REQUIREMENTS" | grep -v '^$' | wc -l)" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No pip-installable packages in requirements.txt"
        echo -e "${YELLOW}ℹ${NC} Note: ROS2 packages (rclpy, std_msgs, rosbridge_suite) are installed with ROS2"
        rm -f "$TEMP_REQUIREMENTS"
    else
        # Try to install using apt first (for system packages)
        if command_exists apt; then
            echo "Checking for system packages..."
            if grep -q "python-pptx\|python3-pptx" "$TEMP_REQUIREMENTS" 2>/dev/null; then
                if apt list --installed 2>/dev/null | grep -q "python3-pptx"; then
                    echo -e "${GREEN}✓${NC} python3-pptx already installed"
                else
                    echo "Installing python3-pptx via apt..."
                    sudo apt update
                    sudo apt install -y python3-pptx 2>/dev/null || echo -e "${YELLOW}⚠${NC} python3-pptx not available via apt"
                fi
            fi
        fi
        
        # Try pip with different methods
        if command_exists pip3; then
            echo "Installing Python packages via pip..."
            
            # Method 1: User installation (preferred)
            if pip3 install --user -r "$TEMP_REQUIREMENTS" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Python packages installed (user)"
            # Method 2: Break system packages (if user installation fails)
            elif pip3 install --break-system-packages -r "$TEMP_REQUIREMENTS" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Python packages installed (--break-system-packages)"
            # Method 3: Virtual environment (safest)
            elif [ ! -d "venv" ]; then
                echo "Creating virtual environment..."
                python3 -m venv venv
                source venv/bin/activate
                pip install -r "$TEMP_REQUIREMENTS"
                echo -e "${GREEN}✓${NC} Python packages installed in virtual environment"
                echo -e "${YELLOW}⚠${NC} Remember to activate: source venv/bin/activate"
            else
                echo -e "${YELLOW}⚠${NC} Virtual environment exists, activating..."
                source venv/bin/activate
                pip install -r "$TEMP_REQUIREMENTS"
                echo -e "${GREEN}✓${NC} Python packages installed in virtual environment"
            fi
            print_status "Python dependencies installed"
        else
            echo -e "${YELLOW}⚠${NC} pip3 not found. Installing..."
            sudo apt update
            sudo apt install -y python3-pip python3-venv
            
            # Create virtual environment
            if [ ! -d "venv" ]; then
                python3 -m venv venv
            fi
            source venv/bin/activate
            pip install -r "$TEMP_REQUIREMENTS"
            echo -e "${GREEN}✓${NC} Python packages installed in virtual environment"
            echo -e "${YELLOW}⚠${NC} Remember to activate: source venv/bin/activate"
            print_status "Python dependencies installed"
        fi
        
        rm -f "$TEMP_REQUIREMENTS"
    fi
    
    # Note about ROS2 packages
    if grep -q -E "^(rclpy|std_msgs|rosbridge_suite)" requirements.txt 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}ℹ${NC} Note: ROS2 packages (rclpy, std_msgs, rosbridge_suite) are installed automatically"
        echo "  when you install ROS2. They are not available via pip."
        echo "  See requirements-ros2.txt for reference."
    fi
fi

echo ""
echo "Step 4: ROS2 Installation (Optional)..."
echo "----------------------------------------"

# Detect Ubuntu version and corresponding ROS2 version
if command_exists lsb_release; then
    UBUNTU_VERSION=$(lsb_release -rs)
    UBUNTU_CODENAME=$(lsb_release -cs)
    
    # Map Ubuntu versions to ROS2 versions
    case "$UBUNTU_CODENAME" in
        jammy)
            ROS2_VERSION="humble"
            ROS2_FULL_NAME="ROS2 Humble"
            ;;
        noble)
            ROS2_VERSION="jazzy"
            ROS2_FULL_NAME="ROS2 Jazzy"
            ;;
        *)
            echo -e "${YELLOW}⚠${NC} Ubuntu $UBUNTU_CODENAME detected"
            echo "  ROS2 installation may not be supported for this version"
            ROS2_VERSION=""
            ;;
    esac
else
    echo -e "${YELLOW}⚠${NC} Cannot detect Ubuntu version"
    ROS2_VERSION=""
fi

if [ -z "$ROS2_VERSION" ]; then
    echo -e "${YELLOW}⚠${NC} ROS2 installation skipped (unsupported Ubuntu version)"
    echo "  You can install ROS2 manually if needed"
else
    read -p "Do you want to install $ROS2_FULL_NAME? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "/opt/ros/$ROS2_VERSION/setup.bash" ]; then
            echo -e "${GREEN}✓${NC} $ROS2_FULL_NAME already installed"
        else
            echo "Installing $ROS2_FULL_NAME..."
            echo "  This will take several minutes..."
            
            # Install prerequisites
            sudo apt update
            sudo apt install -y software-properties-common curl gnupg lsb-release
            
            # Add ROS2 repository
            sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ros2-latest.list > /dev/null
            
            # Update package list
            sudo apt update
            
            # Install ROS2
            if sudo apt install -y ros-${ROS2_VERSION}-desktop ros-${ROS2_VERSION}-rosbridge-suite 2>/dev/null; then
                # Setup ROS2 environment
                if [ -f "$HOME/.bashrc" ]; then
                    if ! grep -q "ros-${ROS2_VERSION}/setup.bash" "$HOME/.bashrc"; then
                        echo "" >> "$HOME/.bashrc"
                        echo "# $ROS2_FULL_NAME" >> "$HOME/.bashrc"
                        echo "source /opt/ros/${ROS2_VERSION}/setup.bash" >> "$HOME/.bashrc"
                    fi
                fi
                
                print_status "$ROS2_FULL_NAME installed"
                echo -e "${GREEN}✓${NC} ROS2 packages (rclpy, std_msgs, rosbridge_suite) are now available"
            else
                echo -e "${RED}✗${NC} Failed to install $ROS2_FULL_NAME"
                echo "  You may need to check ROS2 compatibility with your Ubuntu version"
                echo "  Or install ROS2 manually following: https://docs.ros.org/en/${ROS2_VERSION}/Installation.html"
            fi
        fi
    else
        echo -e "${YELLOW}⚠${NC} ROS2 installation skipped"
        echo "  You can install it later if needed for testing"
    fi
fi

echo ""
echo "Step 5: Building WASM modules..."
echo "----------------------------------------"

if [ -f "build.sh" ]; then
    chmod +x build.sh
    echo "Running build script..."
    # Make sure Emscripten is activated
    if [ -d "$EMSDK_DIR" ]; then
        source "$EMSDK_DIR/emsdk_env.sh" > /dev/null 2>&1
    fi
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
if [ -d "venv" ]; then
    echo "2. Activate Python virtual environment:"
    echo "   source venv/bin/activate"
    echo ""
    echo "3. Build WASM modules:"
    echo "   ./build.sh"
    echo ""
    echo "4. Start the system:"
    echo "   ./start_all.sh"
else
    echo "2. Build WASM modules:"
    echo "   ./build.sh"
    echo ""
    echo "3. Start the system:"
    echo "   ./start_all.sh"
fi
echo ""
echo "5. Open in browser:"
echo "   http://localhost:8000/publisher.html"
echo "   http://localhost:8000/subscriber.html"
echo ""
echo "For ROS2 (if installed):"
echo "   source /opt/ros/humble/setup.bash"
echo "   ./start_rosbridge.sh"
echo ""

