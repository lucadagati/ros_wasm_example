/*
 * microROS Subscriber Node in WASM
 * 
 * Complete ROS subscriber node using microROS (rcl/rclc) API.
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
#include <vector>

using namespace emscripten;

// microROS Subscriber Node using official API
class MicroROSSubscriberNodeWASM {
private:
    // microROS handles
    rcl_node_t node;
    rcl_subscription_t subscription;
    rclc_support_t support;
    rclc_executor_t executor;
    
    std::string node_name;
    std::string topic_name;
    bool initialized;
    int messages_received;
    std::vector<double> received_values;
    double last_value;
    std::string last_message;
    
    // Message callback
    static void messageCallback(const void* msg) {
        // TODO: Cast to std_msgs__msg__String and process
        // const std_msgs__msg__String* string_msg = (const std_msgs__msg__String*)msg;
        // Process message...
        printf("WASM: Message received via microROS callback\n");
    }
    
public:
    MicroROSSubscriberNodeWASM(const std::string& name, const std::string& topic)
        : node_name(name), topic_name(topic), initialized(false), 
          messages_received(0), last_value(0.0) {}
    
    bool init() {
        printf("WASM: Initializing microROS subscriber node '%s'\n", node_name.c_str());
        
        // Initialize rclc support (this also initializes rcl)
        rcl_ret_t ret = rclc_support_init(&support, 0, NULL, NULL);
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
        
        // Create subscriber using microROS API
        // TODO: Use actual std_msgs type support when available
        ret = rclc_subscription_init_default(&subscription, &node, NULL, topic_name.c_str());
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to create microROS subscriber\n");
            return false;
        }
        
        // Initialize executor
        ret = rclc_executor_init(&executor, &support.context, 1, NULL);
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to initialize executor\n");
            return false;
        }
        
        // Add subscription to executor
        // TODO: Use actual message type when available
        ret = rclc_executor_add_subscription(&executor, &subscription, NULL, 
                                             messageCallback, 
                                             RCLC_EXECUTOR_HANDLE_TYPE_SUBSCRIPTION);
        if (ret != RCL_RET_OK) {
            printf("WASM: Failed to add subscription to executor\n");
            return false;
        }
        
        initialized = true;
        printf("WASM: microROS subscriber node initialized successfully\n");
        return true;
    }
    
    void spinOnce() {
        if (!initialized) return;
        
        // Spin executor - this processes incoming messages
        rcl_ret_t ret = rclc_executor_spin_some(&executor, 100000000); // 100ms timeout
        if (ret != RCL_RET_OK && ret != RCL_RET_TIMEOUT) {
            printf("WASM: Error in executor spin\n");
        }
    }
    
    void processMessage(const std::string& data) {
        messages_received++;
        last_message = data;
        
        // Parse JSON to extract value
        size_t pos = data.find("\"value\":");
        if (pos != std::string::npos) {
            sscanf(data.c_str() + pos + 8, "%lf", &last_value);
            received_values.push_back(last_value);
            
            if (received_values.size() > 10) {
                received_values.erase(received_values.begin());
            }
        }
        
        printf("WASM: Message processed via microROS: value=%.2f\n", last_value);
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
    
    bool isInitialized() const { return initialized; }
    std::string getNodeName() const { return node_name; }
    std::string getTopicName() const { return topic_name; }
};

EMSCRIPTEN_BINDINGS(microros_subscriber_wasm) {
    class_<MicroROSSubscriberNodeWASM>("MicroROSSubscriberNodeWASM")
        .constructor<const std::string&, const std::string&>()
        .function("init", &MicroROSSubscriberNodeWASM::init)
        .function("spinOnce", &MicroROSSubscriberNodeWASM::spinOnce)
        .function("processMessage", &MicroROSSubscriberNodeWASM::processMessage)
        .function("getMessagesReceived", &MicroROSSubscriberNodeWASM::getMessagesReceived)
        .function("getLastValue", &MicroROSSubscriberNodeWASM::getLastValue)
        .function("getLastMessage", &MicroROSSubscriberNodeWASM::getLastMessage)
        .function("getAverageValue", &MicroROSSubscriberNodeWASM::getAverageValue)
        .function("isInitialized", &MicroROSSubscriberNodeWASM::isInitialized)
        .function("getNodeName", &MicroROSSubscriberNodeWASM::getNodeName)
        .function("getTopicName", &MicroROSSubscriberNodeWASM::getTopicName);
}

