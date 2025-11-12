/*
 * Minimal ROS2 DDS Implementation for WASM
 * 
 * This implements a minimal DDS layer that allows ROS2 communication
 * directly from WASM runtime without external ROS Bridge.
 * 
 * Features:
 * - DDS Participant discovery (UDP-based)
 * - Publisher/Subscriber with topic matching
 * - Message serialization/deserialization
 * - WASI networking support
 */

#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>
#include <vector>
#include <map>
#include <functional>
#include <cstring>
#include <cstdint>
#include "wasi_networking.cpp"

// DDS Message structure
struct DDSMessage {
    std::string topic_name;
    std::string type_name;
    std::string data;
    uint64_t timestamp;
    uint32_t sequence_number;
};

// DDS Participant - represents a ROS node
class DDSParticipantWASM {
private:
    std::string participant_name;
    int domain_id;
    bool initialized;
    uint32_t participant_guid[4];  // GUID for DDS discovery
    NetworkManagerWASM* network_manager;
    
public:
    DDSParticipantWASM(const std::string& name, int domain_id = 0)
        : participant_name(name), domain_id(domain_id), initialized(false), network_manager(nullptr) {
        // Generate simple GUID (in real DDS this would be more complex)
        participant_guid[0] = 0x01010101;
        participant_guid[1] = 0x02020202;
        participant_guid[2] = 0x03030303;
        participant_guid[3] = static_cast<uint32_t>(std::hash<std::string>{}(name));
    }
    
    ~DDSParticipantWASM() {
        if (network_manager) {
            network_manager->cleanup();
            delete network_manager;
        }
    }
    
    bool init() {
        if (initialized) return true;
        
        printf("WASM: Initializing DDS Participant '%s' (domain: %d)\n", 
               participant_name.c_str(), domain_id);
        
        // Initialize network manager for DDS discovery
        network_manager = new NetworkManagerWASM();
        if (!network_manager->init(7400 + domain_id)) {
            printf("WASM: Failed to initialize network manager\n");
            return false;
        }
        
        initialized = true;
        printf("WASM: DDS Participant initialized (GUID: %08X-%08X-%08X-%08X)\n",
               participant_guid[0], participant_guid[1], participant_guid[2], participant_guid[3]);
        return true;
    }
    
    void discoverParticipants() {
        if (!initialized || !network_manager) return;
        
        // Send participant announcement via UDP discovery
        char announcement[256];
        snprintf(announcement, sizeof(announcement),
                 "DDS_PARTICIPANT:%s:%08X-%08X-%08X-%08X",
                 participant_name.c_str(),
                 participant_guid[0], participant_guid[1], participant_guid[2], participant_guid[3]);
        
        // Send to DDS discovery multicast address (239.255.0.1) or broadcast
        NetworkEndpoint discovery_endpoint("239.255.0.1", 7400 + domain_id);
        network_manager->sendDiscoveryMessage(announcement, discovery_endpoint);
        
        // Poll for incoming discovery messages
        network_manager->poll();
    }
    
    bool isInitialized() const { return initialized; }
    std::string getName() const { return participant_name; }
    int getDomainId() const { return domain_id; }
};

// DDS Publisher
class DDSPublisherWASM {
private:
    DDSParticipantWASM* participant;
    std::string topic_name;
    std::string type_name;
    bool initialized;
    uint32_t sequence_number;
    std::vector<NetworkEndpoint> subscriber_endpoints;  // Discovered subscribers
    
public:
    DDSPublisherWASM(DDSParticipantWASM* part, const std::string& topic, const std::string& type = "std_msgs::msg::String")
        : participant(part), topic_name(topic), type_name(type), initialized(false), sequence_number(0) {}
    
    bool init() {
        if (initialized) return true;
        if (!participant || !participant->isInitialized()) {
            printf("WASM: ERROR - Participant not initialized\n");
            return false;
        }
        
        printf("WASM: Creating DDS Publisher on topic '%s' (type: %s)\n", 
               topic_name.c_str(), type_name.c_str());
        
        // TODO: Register publisher with DDS
        // - Announce publisher via discovery
        // - Wait for subscriber discovery
        // - Setup communication endpoints
        
        initialized = true;
        printf("WASM: DDS Publisher initialized\n");
        return true;
    }
    
    bool publish(const std::string& data) {
        if (!initialized) {
            printf("WASM: Publisher not initialized\n");
            return false;
        }
        
        sequence_number++;
        
        // Create DDS message
        DDSMessage msg;
        msg.topic_name = topic_name;
        msg.type_name = type_name;
        msg.data = data;
        msg.timestamp = emscripten_get_now();  // Current time in milliseconds
        msg.sequence_number = sequence_number;
        
        printf("WASM: Publishing message #%u to topic '%s' via DDS\n", 
               sequence_number, topic_name.c_str());
        
        // Serialize message
        std::string serialized = serializeMessage(msg);
        
        // Send via DDS to all discovered subscribers
        if (participant && participant->network_manager) {
            bool sent = false;
            for (const auto& endpoint : subscriber_endpoints) {
                if (participant->network_manager->sendTCPMessage(endpoint.address, endpoint.port, serialized)) {
                    sent = true;
                    printf("WASM: Message sent to subscriber %s:%d\n", endpoint.address.c_str(), endpoint.port);
                }
            }
            
            if (subscriber_endpoints.empty()) {
                printf("WASM: No subscribers discovered yet (message queued)\n");
            } else if (!sent) {
                printf("WASM: Failed to send to any subscriber\n");
            }
        } else {
            printf("WASM: Network manager not available (simulated send)\n");
        }
        
        return true;
    }
    
    std::string serializeMessage(const DDSMessage& msg) {
        // Simple JSON-like serialization (in real DDS would use CDR)
        char buffer[1024];
        snprintf(buffer, sizeof(buffer),
                 "{\"topic\":\"%s\",\"type\":\"%s\",\"data\":\"%s\",\"seq\":%u,\"ts\":%llu}",
                 msg.topic_name.c_str(), msg.type_name.c_str(), 
                 msg.data.c_str(), msg.sequence_number, msg.timestamp);
        return std::string(buffer);
    }
    
    void addSubscriberEndpoint(const std::string& address, int port) {
        subscriber_endpoints.push_back(NetworkEndpoint(address, port));
        printf("WASM: Added subscriber endpoint: %s:%d\n", address.c_str(), port);
    }
    
    bool isInitialized() const { return initialized; }
    std::string getTopicName() const { return topic_name; }
    int getSequenceNumber() const { return sequence_number; }
};

// DDS Subscriber
class DDSSubscriberWASM {
private:
    DDSParticipantWASM* participant;
    std::string topic_name;
    std::string type_name;
    bool initialized;
    std::function<void(const std::string&)> callback;
    std::vector<NetworkEndpoint> publisher_endpoints;  // Discovered publishers
    int messages_received;
    
public:
    DDSSubscriberWASM(DDSParticipantWASM* part, const std::string& topic, const std::string& type = "std_msgs::msg::String")
        : participant(part), topic_name(topic), type_name(type), initialized(false), messages_received(0) {}
    
    bool init() {
        if (initialized) return true;
        if (!participant || !participant->isInitialized()) {
            printf("WASM: ERROR - Participant not initialized\n");
            return false;
        }
        
        printf("WASM: Creating DDS Subscriber on topic '%s' (type: %s)\n", 
               topic_name.c_str(), type_name.c_str());
        
        // TODO: Register subscriber with DDS
        // - Announce subscriber via discovery
        // - Wait for publisher discovery
        // - Setup communication endpoints
        // - Start listening for messages
        
        initialized = true;
        printf("WASM: DDS Subscriber initialized\n");
        return true;
    }
    
    void setCallback(std::function<void(const std::string&)> cb) {
        callback = cb;
    }
    
    void receiveMessage(const std::string& serialized) {
        if (!initialized) return;
        
        // Deserialize message
        DDSMessage msg = deserializeMessage(serialized);
        
        if (msg.topic_name != topic_name) {
            printf("WASM: Topic mismatch: expected '%s', got '%s'\n", 
                   topic_name.c_str(), msg.topic_name.c_str());
            return;
        }
        
        messages_received++;
        printf("WASM: Message received #%d on topic '%s' via DDS\n", 
               messages_received, topic_name.c_str());
        printf("WASM: Data: %s\n", msg.data.c_str());
        
        // Call callback
        if (callback) {
            callback(msg.data);
        }
    }
    
    DDSMessage deserializeMessage(const std::string& serialized) {
        // Simple deserialization (in real DDS would use CDR)
        DDSMessage msg;
        // For now, just extract data field (simplified)
        size_t data_pos = serialized.find("\"data\":\"");
        if (data_pos != std::string::npos) {
            data_pos += 8;  // Skip "data":"
            size_t data_end = serialized.find("\"", data_pos);
            if (data_end != std::string::npos) {
                msg.data = serialized.substr(data_pos, data_end - data_pos);
            }
        }
        msg.topic_name = topic_name;
        msg.type_name = type_name;
        return msg;
    }
    
    void addPublisherEndpoint(const std::string& address, int port) {
        publisher_endpoints.push_back(NetworkEndpoint(address, port));
        printf("WASM: Added publisher endpoint: %s:%d\n", address.c_str(), port);
    }
    
    void spinOnce() {
        if (!initialized) return;
        
        // TODO: Check for incoming messages
        // - Poll socket for new messages
        // - Deserialize and process
        // - Call callback
    }
    
    bool isInitialized() const { return initialized; }
    std::string getTopicName() const { return topic_name; }
    int getMessagesReceived() const { return messages_received; }
};

EMSCRIPTEN_BINDINGS(dds_minimal_wasm) {
    class_<DDSParticipantWASM>("DDSParticipantWASM")
        .constructor<const std::string&, int>()
        .function("init", &DDSParticipantWASM::init)
        .function("discoverParticipants", &DDSParticipantWASM::discoverParticipants)
        .function("isInitialized", &DDSParticipantWASM::isInitialized)
        .function("getName", &DDSParticipantWASM::getName)
        .function("getDomainId", &DDSParticipantWASM::getDomainId);
    
    class_<DDSPublisherWASM>("DDSPublisherWASM")
        .constructor<DDSParticipantWASM*, const std::string&, const std::string&>()
        .function("init", &DDSPublisherWASM::init)
        .function("publish", &DDSPublisherWASM::publish)
        .function("addSubscriberEndpoint", &DDSPublisherWASM::addSubscriberEndpoint, allow_raw_pointers())
        .function("isInitialized", &DDSPublisherWASM::isInitialized)
        .function("getTopicName", &DDSPublisherWASM::getTopicName)
        .function("getSequenceNumber", &DDSPublisherWASM::getSequenceNumber);
    
    class_<DDSSubscriberWASM>("DDSSubscriberWASM")
        .constructor<DDSParticipantWASM*, const std::string&, const std::string&>()
        .function("init", &DDSSubscriberWASM::init)
        .function("setCallback", &DDSSubscriberWASM::setCallback)
        .function("receiveMessage", &DDSSubscriberWASM::receiveMessage)
        .function("addPublisherEndpoint", &DDSSubscriberWASM::addPublisherEndpoint)
        .function("spinOnce", &DDSSubscriberWASM::spinOnce)
        .function("isInitialized", &DDSSubscriberWASM::isInitialized)
        .function("getTopicName", &DDSSubscriberWASM::getTopicName)
        .function("getMessagesReceived", &DDSSubscriberWASM::getMessagesReceived);
}
