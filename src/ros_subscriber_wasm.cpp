/*
 * ROS Subscriber Node in WASM
 * 
 * Complete ROS subscriber node using minimal DDS layer.
 * This node runs entirely inside WASM runtime.
 */

// Include DDS minimal implementation
// Note: In production, this would be a proper header file
// For now, we include the implementation directly
#include "dds_minimal_wasm.cpp"
#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>
#include <vector>

using namespace emscripten;

// ROS Subscriber Node - Complete implementation
class ROSSubscriberNodeWASM {
private:
    DDSParticipantWASM* participant;
    DDSSubscriberWASM* subscriber;
    std::string node_name;
    std::string topic_name;
    int messages_received;
    std::vector<double> received_values;
    double last_value;
    std::string last_message;
    bool ros_initialized;
    
    // Message callback
    void messageCallback(const std::string& data) {
        messages_received++;
        last_message = data;
        
        // Parse JSON to extract value
        size_t pos = data.find("\"value\":");
        if (pos != std::string::npos) {
            sscanf(data.c_str() + pos + 8, "%lf", &last_value);
            received_values.push_back(last_value);
            
            // Keep last 10 values
            if (received_values.size() > 10) {
                received_values.erase(received_values.begin());
            }
        }
        
        printf("WASM: Message processed in WASM: value=%.2f\n", last_value);
        
        // Simulate actuator response
        if (last_value > 25.0) {
            printf("WASM: ALARM - Temperature high (%.2f), activating cooling system!\n", last_value);
        }
    }
    
public:
    ROSSubscriberNodeWASM(const std::string& node_name, const std::string& topic_name)
        : node_name(node_name), topic_name(topic_name), messages_received(0), 
          last_value(0.0), ros_initialized(false), participant(nullptr), subscriber(nullptr) {}
    
    // Initialize ROS node and subscriber
    bool init() {
        printf("WASM: Initializing ROS Subscriber Node '%s'\n", node_name.c_str());
        
        // Create DDS participant (represents ROS node)
        participant = new DDSParticipantWASM(node_name, 0);
        if (!participant->init()) {
            printf("WASM: Failed to initialize DDS participant\n");
            return false;
        }
        
        // Create DDS subscriber
        subscriber = new DDSSubscriberWASM(participant, topic_name);
        if (!subscriber->init()) {
            printf("WASM: Failed to initialize DDS subscriber\n");
            return false;
        }
        
        // Set callback for received messages
        subscriber->setCallback([this](const std::string& data) {
            this->messageCallback(data);
        });
        
        ros_initialized = true;
        printf("WASM: ROS Subscriber Node '%s' initialized successfully\n", node_name.c_str());
        return true;
    }
    
    // Process incoming message (called by DDS layer)
    void processMessage(const std::string& serialized) {
        if (!ros_initialized) {
            printf("WASM: ROS node not initialized\n");
            return;
        }
        
        // Receive via DDS - this executes entirely in WASM
        subscriber->receiveMessage(serialized);
    }
    
    // Spin ROS node (process events and messages)
    void spinOnce() {
        if (!ros_initialized) return;
        
        // Process DDS events
        participant->discoverParticipants();
        
        // Check for incoming messages
        subscriber->spinOnce();
    }
    
    int getMessagesReceived() const { return messages_received; }
    double getLastValue() const { return last_value; }
    std::string getLastMessage() const { return last_message; }
    
    double getAverageValue() const {
        if (received_values.empty()) return 0.0;
        double sum = 0.0;
        for (double val : received_values) {
            sum += val;
        }
        return sum / received_values.size();
    }
    
    bool isInitialized() const { return ros_initialized; }
    std::string getNodeName() const { return node_name; }
    std::string getTopicName() const { return topic_name; }
};

EMSCRIPTEN_BINDINGS(ros_subscriber_wasm) {
    class_<ROSSubscriberNodeWASM>("ROSSubscriberNodeWASM")
        .constructor<const std::string&, const std::string&>()
        .function("init", &ROSSubscriberNodeWASM::init)
        .function("processMessage", &ROSSubscriberNodeWASM::processMessage)
        .function("spinOnce", &ROSSubscriberNodeWASM::spinOnce)
        .function("getMessagesReceived", &ROSSubscriberNodeWASM::getMessagesReceived)
        .function("getLastValue", &ROSSubscriberNodeWASM::getLastValue)
        .function("getLastMessage", &ROSSubscriberNodeWASM::getLastMessage)
        .function("getAverageValue", &ROSSubscriberNodeWASM::getAverageValue)
        .function("isInitialized", &ROSSubscriberNodeWASM::isInitialized)
        .function("getNodeName", &ROSSubscriberNodeWASM::getNodeName)
        .function("getTopicName", &ROSSubscriberNodeWASM::getTopicName);
}

