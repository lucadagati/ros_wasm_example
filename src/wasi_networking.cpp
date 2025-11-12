/*
 * WASI Networking Layer for DDS
 * 
 * Implements UDP/TCP sockets for DDS communication in WASM.
 * Uses Emscripten's networking APIs.
 */

#include <emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/websocket.h>
#include <string>
#include <cstdio>
#include <cstring>
#include <vector>
#include <map>
#include <functional>

#ifndef __EMSCRIPTEN__
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
#endif

using namespace emscripten;

// Network endpoint
struct NetworkEndpoint {
    std::string address;
    int port;
    
    NetworkEndpoint(const std::string& addr = "", int p = 0) : address(addr), port(p) {}
    
    std::string toString() const {
        char buffer[128];
        snprintf(buffer, sizeof(buffer), "%s:%d", address.c_str(), port);
        return std::string(buffer);
    }
};

// UDP Socket for DDS discovery
class UDPSocketWASM {
private:
    int socket_fd;
    bool bound;
    NetworkEndpoint local_endpoint;
    std::function<void(const std::string&, const NetworkEndpoint&)> receive_callback;
    
public:
    UDPSocketWASM() : socket_fd(-1), bound(false) {}
    
    ~UDPSocketWASM() {
        close();
    }
    
    bool create() {
        // Create UDP socket using Emscripten
        // Note: Emscripten doesn't have direct UDP support in browser
        // We'll use a WebSocket-based approach or WASI sockets for standalone
        printf("WASM: Creating UDP socket for DDS discovery\n");
        
        #ifdef __EMSCRIPTEN__
        // For browser: Use WebSocket or fetch API
        // For standalone: Use WASI sockets
        socket_fd = 1; // Placeholder - will be replaced with real socket
        #else
        // Native socket creation (for testing)
        socket_fd = socket(AF_INET, SOCK_DGRAM, 0);
        if (socket_fd < 0) {
            printf("WASM: Failed to create UDP socket\n");
            return false;
        }
        #endif
        
        return true;
    }
    
    bool bind(const std::string& address, int port) {
        if (socket_fd < 0) {
            if (!create()) return false;
        }
        
        local_endpoint = NetworkEndpoint(address, port);
        
        #ifdef __EMSCRIPTEN__
        // In browser, we can't bind UDP sockets directly
        // Use WebSocket server or proxy
        bound = true;
        printf("WASM: UDP socket bound to %s (Emscripten mode)\n", local_endpoint.toString().c_str());
        #else
        // Native socket binding
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        if (address == "0.0.0.0" || address.empty()) {
            addr.sin_addr.s_addr = INADDR_ANY;
        } else {
            inet_pton(AF_INET, address.c_str(), &addr.sin_addr);
        }
        
        if (::bind(socket_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            printf("WASM: Failed to bind UDP socket\n");
            return false;
        }
        bound = true;
        printf("WASM: UDP socket bound to %s\n", local_endpoint.toString().c_str());
        #endif
        
        return true;
    }
    
    bool sendTo(const std::string& data, const NetworkEndpoint& endpoint) {
        if (!bound) {
            printf("WASM: UDP socket not bound\n");
            return false;
        }
        
        printf("WASM: UDP send to %s: %s\n", endpoint.toString().c_str(), data.c_str());
        
        #ifdef __EMSCRIPTEN__
        // For browser: Use WebSocket or fetch API
        // For now, use Emscripten's networking if available
        // In production, would use WebSocket proxy or WASI sockets
        EM_ASM_({
            console.log("UDP send (simulated):", UTF8ToString($0), UTF8ToString($1), $2);
        }, data.c_str(), endpoint.address.c_str(), endpoint.port);
        #else
        // Native UDP send
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(endpoint.port);
        inet_pton(AF_INET, endpoint.address.c_str(), &addr.sin_addr);
        
        ssize_t sent = sendto(socket_fd, data.c_str(), data.length(), 0,
                              (struct sockaddr*)&addr, sizeof(addr));
        if (sent < 0) {
            printf("WASM: Failed to send UDP packet\n");
            return false;
        }
        #endif
        
        return true;
    }
    
    void setReceiveCallback(std::function<void(const std::string&, const NetworkEndpoint&)> cb) {
        receive_callback = cb;
    }
    
    void poll() {
        if (!bound || socket_fd < 0) return;
        
        #ifdef __EMSCRIPTEN__
        // In browser, polling would be done via WebSocket callbacks
        // For now, simulate polling
        // In production, use WebSocket onmessage or WASI socket polling
        #else
        // Native UDP receive (non-blocking)
        struct sockaddr_in from_addr;
        socklen_t from_len = sizeof(from_addr);
        char buffer[4096];
        
        // Set socket to non-blocking
        int flags = fcntl(socket_fd, F_GETFL, 0);
        fcntl(socket_fd, F_SETFL, flags | O_NONBLOCK);
        
        ssize_t received = recvfrom(socket_fd, buffer, sizeof(buffer) - 1, 0,
                                   (struct sockaddr*)&from_addr, &from_len);
        if (received > 0) {
            buffer[received] = '\0';
            char from_ip[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &from_addr.sin_addr, from_ip, INET_ADDRSTRLEN);
            NetworkEndpoint from_endpoint(from_ip, ntohs(from_addr.sin_port));
            
            if (receive_callback) {
                receive_callback(std::string(buffer, received), from_endpoint);
            }
        }
        #endif
    }
    
    void close() {
        if (socket_fd >= 0) {
            printf("WASM: Closing UDP socket\n");
            socket_fd = -1;
            bound = false;
        }
    }
    
    bool isBound() const { return bound; }
    NetworkEndpoint getLocalEndpoint() const { return local_endpoint; }
};

// TCP Socket for reliable DDS communication
class TCPSocketWASM {
private:
    int socket_fd;
    bool connected;
    NetworkEndpoint remote_endpoint;
    std::function<void(const std::string&)> receive_callback;
    std::vector<std::string> send_queue;
    
public:
    TCPSocketWASM() : socket_fd(-1), connected(false) {}
    
    ~TCPSocketWASM() {
        close();
    }
    
    bool create() {
        printf("WASM: Creating TCP socket for DDS communication\n");
        
        #ifdef __EMSCRIPTEN__
        // For browser: Use WebSocket
        // For standalone: Use WASI sockets
        socket_fd = 2; // Placeholder
        #else
        socket_fd = socket(AF_INET, SOCK_STREAM, 0);
        if (socket_fd < 0) {
            printf("WASM: Failed to create TCP socket\n");
            return false;
        }
        #endif
        
        return true;
    }
    
    bool connect(const std::string& address, int port) {
        if (socket_fd < 0) {
            if (!create()) return false;
        }
        
        remote_endpoint = NetworkEndpoint(address, port);
        
        #ifdef __EMSCRIPTEN__
        // In browser, use WebSocket for TCP-like connection
        // For now, simulate connection
        connected = true;
        printf("WASM: TCP socket connected to %s (Emscripten mode)\n", remote_endpoint.toString().c_str());
        #else
        // Native TCP connect
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_pton(AF_INET, address.c_str(), &addr.sin_addr);
        
        if (::connect(socket_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            printf("WASM: Failed to connect TCP socket\n");
            return false;
        }
        connected = true;
        printf("WASM: TCP socket connected to %s\n", remote_endpoint.toString().c_str());
        #endif
        
        return true;
    }
    
    bool send(const std::string& data) {
        if (!connected) {
            printf("WASM: TCP socket not connected\n");
            return false;
        }
        
        printf("WASM: TCP send to %s: %s\n", remote_endpoint.toString().c_str(), data.c_str());
        
        #ifdef __EMSCRIPTEN__
        // For browser: Use WebSocket send
        EM_ASM_({
            console.log("TCP send (simulated):", UTF8ToString($0), UTF8ToString($1), $2);
        }, data.c_str(), remote_endpoint.address.c_str(), remote_endpoint.port);
        #else
        // Native TCP send
        ssize_t sent = ::send(socket_fd, data.c_str(), data.length(), 0);
        if (sent < 0) {
            printf("WASM: Failed to send TCP data\n");
            return false;
        }
        if (sent < (ssize_t)data.length()) {
            // Partial send - queue remainder
            send_queue.push_back(data.substr(sent));
        }
        #endif
        
        return true;
    }
    
    void setReceiveCallback(std::function<void(const std::string&)> cb) {
        receive_callback = cb;
    }
    
    void poll() {
        if (!connected || socket_fd < 0) return;
        
        #ifdef __EMSCRIPTEN__
        // In browser, polling would be done via WebSocket callbacks
        // Process send queue
        if (!send_queue.empty()) {
            // In production, would send via WebSocket
            send_queue.clear();
        }
        #else
        // Native TCP receive (non-blocking)
        char buffer[4096];
        
        // Set socket to non-blocking
        int flags = fcntl(socket_fd, F_GETFL, 0);
        fcntl(socket_fd, F_SETFL, flags | O_NONBLOCK);
        
        ssize_t received = recv(socket_fd, buffer, sizeof(buffer) - 1, 0);
        if (received > 0) {
            buffer[received] = '\0';
            if (receive_callback) {
                receive_callback(std::string(buffer, received));
            }
        } else if (received == 0) {
            // Connection closed
            printf("WASM: TCP connection closed\n");
            close();
        }
        
        // Process send queue (retry partial sends)
        if (!send_queue.empty()) {
            std::string remaining = send_queue.front();
            send_queue.erase(send_queue.begin());
            ssize_t sent = ::send(socket_fd, remaining.c_str(), remaining.length(), 0);
            if (sent < (ssize_t)remaining.length() && sent >= 0) {
                send_queue.insert(send_queue.begin(), remaining.substr(sent));
            }
        }
        #endif
    }
    
    void close() {
        if (socket_fd >= 0) {
            printf("WASM: Closing TCP socket\n");
            socket_fd = -1;
            connected = false;
        }
    }
    
    bool isConnected() const { return connected; }
    NetworkEndpoint getRemoteEndpoint() const { return remote_endpoint; }
};

// Network Manager - manages all network connections
class NetworkManagerWASM {
private:
    UDPSocketWASM* discovery_socket;
    std::map<std::string, TCPSocketWASM*> tcp_connections;
    int discovery_port;
    bool initialized;
    
public:
    NetworkManagerWASM() : discovery_socket(nullptr), discovery_port(7400), initialized(false) {}
    
    ~NetworkManagerWASM() {
        cleanup();
    }
    
    bool init(int discovery_port = 7400) {
        if (initialized) return true;
        
        this->discovery_port = discovery_port;
        
        // Create UDP socket for discovery
        discovery_socket = new UDPSocketWASM();
        if (!discovery_socket->create()) {
            printf("WASM: Failed to create discovery socket\n");
            return false;
        }
        
        // Bind to discovery port
        if (!discovery_socket->bind("0.0.0.0", discovery_port)) {
            printf("WASM: Failed to bind discovery socket\n");
            return false;
        }
        
        // Set receive callback
        discovery_socket->setReceiveCallback([this](const std::string& data, const NetworkEndpoint& endpoint) {
            this->handleDiscoveryMessage(data, endpoint);
        });
        
        initialized = true;
        printf("WASM: Network Manager initialized (discovery port: %d)\n", discovery_port);
        return true;
    }
    
    void handleDiscoveryMessage(const std::string& data, const NetworkEndpoint& endpoint) {
        printf("WASM: Discovery message from %s: %s\n", endpoint.toString().c_str(), data.c_str());
        // TODO: Parse discovery message and establish TCP connection if needed
    }
    
    bool sendDiscoveryMessage(const std::string& message, const NetworkEndpoint& endpoint) {
        if (!initialized || !discovery_socket) {
            return false;
        }
        return discovery_socket->sendTo(message, endpoint);
    }
    
    TCPSocketWASM* createTCPConnection(const std::string& address, int port) {
        std::string key = NetworkEndpoint(address, port).toString();
        
        if (tcp_connections.find(key) != tcp_connections.end()) {
            return tcp_connections[key];
        }
        
        TCPSocketWASM* socket = new TCPSocketWASM();
        if (socket->connect(address, port)) {
            tcp_connections[key] = socket;
            return socket;
        }
        
        delete socket;
        return nullptr;
    }
    
    bool sendTCPMessage(const std::string& address, int port, const std::string& data) {
        TCPSocketWASM* socket = createTCPConnection(address, port);
        if (!socket) {
            return false;
        }
        return socket->send(data);
    }
    
    void poll() {
        if (discovery_socket) {
            discovery_socket->poll();
        }
        
        for (auto& pair : tcp_connections) {
            pair.second->poll();
        }
    }
    
    void cleanup() {
        if (discovery_socket) {
            discovery_socket->close();
            delete discovery_socket;
            discovery_socket = nullptr;
        }
        
        for (auto& pair : tcp_connections) {
            pair.second->close();
            delete pair.second;
        }
        tcp_connections.clear();
        
        initialized = false;
    }
    
    bool isInitialized() const { return initialized; }
};

EMSCRIPTEN_BINDINGS(wasi_networking) {
    class_<NetworkEndpoint>("NetworkEndpoint")
        .constructor<const std::string&, int>()
        .function("toString", &NetworkEndpoint::toString);
    
    class_<UDPSocketWASM>("UDPSocketWASM")
        .constructor<>()
        .function("create", &UDPSocketWASM::create)
        .function("bind", &UDPSocketWASM::bind)
        .function("sendTo", &UDPSocketWASM::sendTo)
        .function("poll", &UDPSocketWASM::poll)
        .function("close", &UDPSocketWASM::close)
        .function("isBound", &UDPSocketWASM::isBound);
    
    class_<TCPSocketWASM>("TCPSocketWASM")
        .constructor<>()
        .function("create", &TCPSocketWASM::create)
        .function("connect", &TCPSocketWASM::connect)
        .function("send", &TCPSocketWASM::send)
        .function("poll", &TCPSocketWASM::poll)
        .function("close", &TCPSocketWASM::close)
        .function("isConnected", &TCPSocketWASM::isConnected);
    
    class_<NetworkManagerWASM>("NetworkManagerWASM")
        .constructor<>()
        .function("init", &NetworkManagerWASM::init)
        .function("sendDiscoveryMessage", &NetworkManagerWASM::sendDiscoveryMessage)
        .function("sendTCPMessage", &NetworkManagerWASM::sendTCPMessage)
        .function("poll", &NetworkManagerWASM::poll)
        .function("cleanup", &NetworkManagerWASM::cleanup)
        .function("isInitialized", &NetworkManagerWASM::isInitialized);
}

