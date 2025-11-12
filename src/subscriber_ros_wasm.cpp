/*
 * ROS Subscriber Node - Running INSIDE WASM
 * 
 * This is a template for implementing a ROS subscriber that runs
 * entirely inside WASM runtime using microROS.
 * 
 * Target: microROS compiled to WASM, executing in WASM runtime
 */

// TODO: Include microROS headers when ported to WASM
// #include <rcl/rcl.h>
// #include <rclc/rclc.h>
// #include <std_msgs/msg/string.h>

#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>
#include <vector>
#include <algorithm>

using namespace emscripten;

/**
 * ROS Subscriber Node - Executing in WASM
 * 
 * This class will use microROS when ported to WASM.
 * Currently it's a placeholder showing the target structure.
 */
class ROSSubscriberWASM {
private:
    // TODO: microROS node and subscriber handles
    // rcl_node_t node;
    // rcl_subscription_t subscription;
    // std_msgs__msg__String msg;
    
    int messages_received;
    std::vector<double> received_values;
    double last_value;
    std::string last_message;
    bool ros_initialized;

public:
    ROSSubscriberWASM() : messages_received(0), last_value(0.0), ros_initialized(false) {}

    /**
     * Initialize microROS node in WASM
     * 
     * Target implementation:
     * - Initialize rcl (ROS Client Library) in WASM
     * - Create ROS node in WASM
     * - Create subscriber in WASM
     * - Setup ROS2 DDS transport in WASM
     */
    bool initROS() {
        printf("WASM: Initializing microROS subscriber...\n");
        
        // TODO: Initialize microROS in WASM
        // rcl_allocator_t allocator = rcl_get_default_allocator();
        // rclc_support_t support;
        // rclc_support_init(&support, 0, NULL, &allocator);
        // rclc_node_init_default(&node, "wasm_subscriber", "", &support);
        // rclc_subscription_init_default(&subscription, &node,
        //     ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String),
        //     "/sensor/temperature");
        
        ros_initialized = true;
        printf("WASM: microROS subscriber initialized (placeholder)\n");
        return true;
    }

    /**
     * ROS message callback - Executing in WASM
     * 
     * Target: This callback is called by microROS when a message
     * is received via ROS2 DDS, all executing in WASM.
     */
    void messageCallback(const std::string& data) {
        if (!ros_initialized) {
            printf("WASM: ROS not initialized\n");
            return;
        }
        
        messages_received++;
        last_message = data;
        
        // Parse JSON to extract value (simplified)
        // In real implementation, ROS message deserialization happens in WASM
        size_t value_pos = data.find("\"value\":");
        if (value_pos != std::string::npos) {
            sscanf(data.c_str() + value_pos, "\"value\": %lf", &last_value);
            received_values.push_back(last_value);
            if (received_values.size() > 10) {
                received_values.erase(received_values.begin());
            }
        }
        
        printf("WASM: Message received (via microROS in WASM): %s\n", data.c_str());
    }

    /**
     * Spin ROS node - Executing in WASM
     * 
     * Target: rcl_spin() executes in WASM, receives messages via ROS2 DDS
     */
    void spinOnce() {
        if (!ros_initialized) return;
        
        // TODO: Spin ROS node in WASM
        // rcl_wait_set_t wait_set;
        // rcl_wait_set_init(&wait_set, 0, 0, 1, 0, 0, 0, &support.context, rcl_get_default_allocator());
        // rcl_wait_set_add_subscription(&wait_set, &subscription, NULL);
        // rcl_wait(&wait_set, RCL_MS_TO_NS(100));
        // 
        // if (rcl_take(&subscription, &msg, NULL, NULL) == RCL_RET_OK) {
        //     messageCallback(std::string(msg.data.data, msg.data.size));
        // }
        // 
        // rcl_wait_set_fini(&wait_set);
    }

    int getMessagesReceived() const { return messages_received; }
    double getLastValue() const { return last_value; }
    std::string getLastMessage() const { return last_message; }
    
    double getAverageValue() const {
        if (received_values.empty()) return 0.0;
        double sum = 0.0;
        for (double v : received_values) sum += v;
        return sum / received_values.size();
    }
    
    bool isROSInitialized() const { return ros_initialized; }
};

EMSCRIPTEN_BINDINGS(ros_subscriber_wasm) {
    class_<ROSSubscriberWASM>("ROSSubscriberWASM")
        .constructor<>()
        .function("initROS", &ROSSubscriberWASM::initROS)
        .function("messageCallback", &ROSSubscriberWASM::messageCallback)
        .function("spinOnce", &ROSSubscriberWASM::spinOnce)
        .function("getMessagesReceived", &ROSSubscriberWASM::getMessagesReceived)
        .function("getLastValue", &ROSSubscriberWASM::getLastValue)
        .function("getLastMessage", &ROSSubscriberWASM::getLastMessage)
        .function("getAverageValue", &ROSSubscriberWASM::getAverageValue)
        .function("isROSInitialized", &ROSSubscriberWASM::isROSInitialized);
}

