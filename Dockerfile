# Dockerfile per ambiente completo WASM-ROS
# Fornisce un ambiente pre-configurato con tutte le dipendenze

FROM ubuntu:22.04

# Evita prompt interattivi durante l'installazione
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Installa dipendenze di base
RUN apt-get update && apt-get install -y \
    wget \
    git \
    python3 \
    python3-pip \
    curl \
    cmake \
    build-essential \
    software-properties-common \
    lsb-release \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Installa ROS2 Humble
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt-get update \
    && apt-get install -y \
    ros-humble-ros-base \
    ros-humble-rosbridge-suite \
    && rm -rf /var/lib/apt/lists/*

# Installa Emscripten SDK
WORKDIR /opt
RUN git clone https://github.com/emscripten-core/emsdk.git \
    && cd emsdk \
    && ./emsdk install latest \
    && ./emsdk activate latest

# Setup environment
ENV PATH="/opt/emsdk:/opt/emsdk/upstream/emscripten:${PATH}"
ENV EMSDK="/opt/emsdk"
ENV EM_CONFIG="/opt/emsdk/.emscripten"

# Source ROS2
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

# Crea directory di lavoro
WORKDIR /workspace
COPY . /workspace/

# Espone le porte
EXPOSE 8000 9090

# Script di avvio
RUN chmod +x /workspace/*.sh

CMD ["/bin/bash"]

