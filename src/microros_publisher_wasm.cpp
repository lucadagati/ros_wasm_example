/*
 * microROS Publisher Node in WASM
 * 
 * Complete ROS publisher node using microROS (rcl/rclc) API.
 * This demonstrates microROS running inside WASM runtime.
 */

// TODO: Include microROS headers when ported
// #include <rcl/rcl.h>
// #include <rclc/rclc.h>
// #include <rclc/executor.h>
// #include <std_msgs/msg/string.h>

// For now, use our ported rcl/rclc
#include "rcl_types_wasm.h"
#include "rcl_port_wasm.cpp"
#include "rclc_port_wasm.cpp"
#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>

using namespace emscripten;

// microROS Publisher Node using official API
class MicroROSPublisherNodeWASM {
private:
    // microROS handles
    rcl_node_t node;
    rcl_publisher_t publisher;
    rclc_support_t support;
    
    std::string node_name;
    std::string topic_name;
    bool initialized;
    int message_count;
    double sensor_value;
    
public:
    MicroROSPublisherNodeWASM(const std::string& name, const std::string& topic)
        : node_name(name), topic_name(topic), initialized(false), 
          message_count(0), sensor_value(0.0) {}
    
    bool init() {
        printf("WASM: Initializing microROS publisher node '%s'\n", node_name.c_str());
        
        // Initialize rcl
        rcl_ret_t ret = rcl_init(0, NULL, NULL, &support.context);
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to initialize rcl\n");
            return false;
        }
        
        // Initialize rclc support
        ret = rclc_support_init(&support, 0, NULL, NULL);
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to initialize rclc support\n");
            return false;
        }
        
        // Create node using microROS API
        ret = rclc_node_init_default(&node, node_name.c_str(), "", &support);
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to create microROS node\n");
            return false;
        }
        
        // Create publisher using microROS API
        // TODO: Use actual std_msgs type support when available
        ret = rclc_publisher_init_default(&publisher, &node, NULL, topic_name.c_str());
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to create microROS publisher\n");
            return false;
        }
        
        initialized = true;
        printf("WASM: microROS publisher node initialized successfully\n");
        return true;
    }
    
    std::string generateSensorData() {
        message_count++;
        sensor_value = 20.0 + (message_count % 10);
        
        char buffer[256];
        snprintf(buffer, sizeof(buffer),
                 "{\"id\": %d, \"sensor\": \"temperature\", \"value\": %.2f, \"unit\": \"celsius\"}",
                 message_count, sensor_value);
        
        return std::string(buffer);
    }
    
    bool publishMessage() {
        if (!initialized) {
            printf("WASM: Node not initialized\n");
            return false;
        }
        
        std::string data = generateSensorData();
        
        printf("WASM: Publishing via microROS API: %s\n", data.c_str());
        
        // TODO: Create std_msgs message and publish
        // std_msgs__msg__String msg;
        // msg.data.data = (char*)data.c_str();
        // msg.data.size = data.length();
        // rcl_ret_t ret = rcl_publish(&publisher, &msg, NULL);
        
        // For now, simulate
        rcl_ret_t ret = rcl_publish(&publisher, data.c_str(), NULL);
        
        if (ret == RCL_RET_OK) {
            printf("WASM: Message published successfully via microROS\n");
            return true;
        } else {
            printf("WASM: Failed to publish message\n");
            return false;
        }
    }
    
    int getMessageCount() const { return message_count; }
    double getSensorValue() const { return sensor_value; }
    bool isInitialized() const { return initialized; }
    std::string getNodeName() const { return node_name; }
    std::string getTopicName() const { return topic_name; }
};

EMSCRIPTEN_BINDINGS(microros_publisher_wasm) {
    class_<MicroROSPublisherNodeWASM>("MicroROSPublisherNodeWASM")
        .constructor<const std::string&, const std::string&>()
        .function("init", &MicroROSPublisherNodeWASM::init)
        .function("generateSensorData", &MicroROSPublisherNodeWASM::generateSensorData)
        .function("publishMessage", &MicroROSPublisherNodeWASM::publishMessage)
        .function("getMessageCount", &MicroROSPublisherNodeWASM::getMessageCount)
        .function("getSensorValue", &MicroROSPublisherNodeWASM::getSensorValue)
        .function("isInitialized", &MicroROSPublisherNodeWASM::isInitialized)
        .function("getNodeName", &MicroROSPublisherNodeWASM::getNodeName)
        .function("getTopicName", &MicroROSPublisherNodeWASM::getTopicName);
}

