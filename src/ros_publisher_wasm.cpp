/*
 * ROS Publisher Node in WASM
 * 
 * Complete ROS publisher node using minimal DDS layer.
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

using namespace emscripten;

// ROS Publisher Node - Complete implementation
class ROSPublisherNodeWASM {
private:
    DDSParticipantWASM* participant;
    DDSPublisherWASM* publisher;
    std::string node_name;
    std::string topic_name;
    int message_count;
    double sensor_value;
    bool ros_initialized;
    
public:
    ROSPublisherNodeWASM(const std::string& node_name, const std::string& topic_name)
        : node_name(node_name), topic_name(topic_name), message_count(0), 
          sensor_value(0.0), ros_initialized(false), participant(nullptr), publisher(nullptr) {}
    
    // Initialize ROS node and publisher
    bool init() {
        printf("WASM: Initializing ROS Publisher Node '%s'\n", node_name.c_str());
        
        // Create DDS participant (represents ROS node)
        participant = new DDSParticipantWASM(node_name, 0);
        if (!participant->init()) {
            printf("WASM: Failed to initialize DDS participant\n");
            return false;
        }
        
        // Create DDS publisher
        publisher = new DDSPublisherWASM(participant, topic_name);
        if (!publisher->init()) {
            printf("WASM: Failed to initialize DDS publisher\n");
            return false;
        }
        
        ros_initialized = true;
        printf("WASM: ROS Publisher Node '%s' initialized successfully\n", node_name.c_str());
        return true;
    }
    
    // Generate sensor data (business logic)
    std::string generateSensorData() {
        message_count++;
        sensor_value = 20.0 + (message_count % 10);
        
        char buffer[256];
        snprintf(buffer, sizeof(buffer),
                 "{\"id\": %d, \"sensor\": \"temperature\", \"value\": %.2f, \"unit\": \"celsius\"}",
                 message_count, sensor_value);
        
        return std::string(buffer);
    }
    
    // Publish message via ROS2 DDS (ALL IN WASM)
    bool publishMessage() {
        if (!ros_initialized) {
            printf("WASM: ROS node not initialized\n");
            return false;
        }
        
        std::string data = generateSensorData();
        
        printf("WASM: Publishing message #%d via ROS2 DDS (in WASM)\n", message_count);
        
        // Publish via DDS - this executes entirely in WASM
        bool success = publisher->publish(data);
        
        if (success) {
            printf("WASM: Message published successfully via ROS2 DDS\n");
        } else {
            printf("WASM: Failed to publish message\n");
        }
        
        return success;
    }
    
    // Spin ROS node (process events)
    void spinOnce() {
        if (!ros_initialized) return;
        
        // TODO: Process DDS events
        // - Check for subscriber discovery
        // - Handle acknowledgments
        participant->discoverParticipants();
    }
    
    int getMessageCount() const { return message_count; }
    double getSensorValue() const { return sensor_value; }
    bool isInitialized() const { return ros_initialized; }
    std::string getNodeName() const { return node_name; }
    std::string getTopicName() const { return topic_name; }
};

EMSCRIPTEN_BINDINGS(ros_publisher_wasm) {
    class_<ROSPublisherNodeWASM>("ROSPublisherNodeWASM")
        .constructor<const std::string&, const std::string&>()
        .function("init", &ROSPublisherNodeWASM::init)
        .function("generateSensorData", &ROSPublisherNodeWASM::generateSensorData)
        .function("publishMessage", &ROSPublisherNodeWASM::publishMessage)
        .function("spinOnce", &ROSPublisherNodeWASM::spinOnce)
        .function("getMessageCount", &ROSPublisherNodeWASM::getMessageCount)
        .function("getSensorValue", &ROSPublisherNodeWASM::getSensorValue)
        .function("isInitialized", &ROSPublisherNodeWASM::isInitialized)
        .function("getNodeName", &ROSPublisherNodeWASM::getNodeName)
        .function("getTopicName", &ROSPublisherNodeWASM::getTopicName);
}

