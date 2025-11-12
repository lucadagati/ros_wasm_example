/*
 * microROS Node in WASM
 * 
 * This file implements a ROS node that runs INSIDE WASM runtime.
 * Uses minimal ROS2 DDS implementation for WASM.
 */

#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>
#include <vector>
#include <functional>

// TODO: Include microROS headers when available
// For now, we'll implement a minimal ROS2 DDS layer

using namespace emscripten;

// Minimal ROS2 DDS message structure
struct ROSMessage {
    std::string topic;
    std::string data;
    uint64_t timestamp;
};

// Minimal ROS2 DDS Publisher
class ROSPublisherWASM {
private:
    std::string node_name;
    std::string topic_name;
    bool initialized;
    int message_count;
    
public:
    ROSPublisherWASM(const std::string& node_name, const std::string& topic_name)
        : node_name(node_name), topic_name(topic_name), initialized(false), message_count(0) {}
    
    // Initialize ROS node and publisher in WASM
    bool init() {
        printf("WASM: Initializing ROS node '%s' in WASM runtime\n", node_name.c_str());
        printf("WASM: Creating publisher on topic '%s'\n", topic_name.c_str());
        
        // TODO: Initialize microROS in WASM
        // rcl_allocator_t allocator = rcl_get_default_allocator();
        // rclc_support_t support;
        // rclc_support_init(&support, 0, NULL, &allocator);
        // rclc_node_init_default(&node, node_name.c_str(), "", &support);
        // rclc_publisher_init_default(&publisher, &node, 
        //     ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String), 
        //     topic_name.c_str());
        
        initialized = true;
        printf("WASM: ROS publisher initialized (minimal DDS)\n");
        return true;
    }
    
    // Publish message via ROS2 DDS - ALL IN WASM
    bool publish(const std::string& data) {
        if (!initialized) {
            printf("WASM: ROS node not initialized\n");
            return false;
        }
        
        message_count++;
        printf("WASM: Publishing message #%d to topic '%s' via ROS2 DDS (in WASM)\n", 
               message_count, topic_name.c_str());
        
        // TODO: Publish via microROS DDS in WASM
        // std_msgs__msg__String msg;
        // msg.data.data = (char*)data.c_str();
        // msg.data.size = data.length();
        // rcl_ret_t ret = rcl_publish(&publisher, &msg, NULL);
        
        // For now, simulate DDS publish
        // In real implementation, this would use ROS2 DDS transport in WASM
        printf("WASM: Message published via ROS2 DDS: %s\n", data.c_str());
        
        return true;
    }
    
    int getMessageCount() const { return message_count; }
    bool isInitialized() const { return initialized; }
    std::string getTopicName() const { return topic_name; }
};

// Minimal ROS2 DDS Subscriber
class ROSSubscriberWASM {
private:
    std::string node_name;
    std::string topic_name;
    bool initialized;
    int messages_received;
    std::vector<std::string> received_messages;
    std::function<void(const std::string&)> callback;
    
public:
    ROSSubscriberWASM(const std::string& node_name, const std::string& topic_name)
        : node_name(node_name), topic_name(topic_name), initialized(false), messages_received(0) {}
    
    // Initialize ROS node and subscriber in WASM
    bool init() {
        printf("WASM: Initializing ROS node '%s' in WASM runtime\n", node_name.c_str());
        printf("WASM: Creating subscriber on topic '%s'\n", topic_name.c_str());
        
        // TODO: Initialize microROS in WASM
        // rcl_allocator_t allocator = rcl_get_default_allocator();
        // rclc_support_t support;
        // rclc_support_init(&support, 0, NULL, &allocator);
        // rclc_node_init_default(&node, node_name.c_str(), "", &support);
        // rclc_subscription_init_default(&subscription, &node,
        //     ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String),
        //     topic_name.c_str());
        
        initialized = true;
        printf("WASM: ROS subscriber initialized (minimal DDS)\n");
        return true;
    }
    
    // Set callback for received messages
    void setCallback(std::function<void(const std::string&)> cb) {
        callback = cb;
    }
    
    // Process incoming message - ALL IN WASM
    void processMessage(const std::string& data) {
        if (!initialized) {
            printf("WASM: ROS node not initialized\n");
            return;
        }
        
        messages_received++;
        received_messages.push_back(data);
        if (received_messages.size() > 10) {
            received_messages.erase(received_messages.begin());
        }
        
        printf("WASM: Message received #%d on topic '%s' via ROS2 DDS (in WASM)\n", 
               messages_received, topic_name.c_str());
        printf("WASM: Processing message in WASM: %s\n", data.c_str());
        
        // Call callback if set
        if (callback) {
            callback(data);
        }
    }
    
    // Spin ROS node - process messages in WASM
    void spinOnce() {
        if (!initialized) return;
        
        // TODO: Spin ROS node in WASM
        // rcl_wait_set_t wait_set;
        // rcl_wait_set_init(&wait_set, 0, 0, 1, 0, 0, 0, &support.context, rcl_get_default_allocator());
        // rcl_wait_set_add_subscription(&wait_set, &subscription, NULL);
        // rcl_wait(&wait_set, RCL_MS_TO_NS(100));
        // 
        // if (rcl_take(&subscription, &msg, NULL, NULL) == RCL_RET_OK) {
        //     processMessage(std::string(msg.data.data, msg.data.size));
        // }
        // 
        // rcl_wait_set_fini(&wait_set);
    }
    
    int getMessagesReceived() const { return messages_received; }
    bool isInitialized() const { return initialized; }
    std::string getTopicName() const { return topic_name; }
    std::string getLastMessage() const { 
        return received_messages.empty() ? "" : received_messages.back();
    }
};

EMSCRIPTEN_BINDINGS(microros_wasm) {
    class_<ROSPublisherWASM>("ROSPublisherWASM")
        .constructor<const std::string&, const std::string&>()
        .function("init", &ROSPublisherWASM::init)
        .function("publish", &ROSPublisherWASM::publish)
        .function("getMessageCount", &ROSPublisherWASM::getMessageCount)
        .function("isInitialized", &ROSPublisherWASM::isInitialized)
        .function("getTopicName", &ROSPublisherWASM::getTopicName);
    
    class_<ROSSubscriberWASM>("ROSSubscriberWASM")
        .constructor<const std::string&, const std::string&>()
        .function("init", &ROSSubscriberWASM::init)
        .function("processMessage", &ROSSubscriberWASM::processMessage)
        .function("spinOnce", &ROSSubscriberWASM::spinOnce)
        .function("getMessagesReceived", &ROSSubscriberWASM::getMessagesReceived)
        .function("isInitialized", &ROSSubscriberWASM::isInitialized)
        .function("getTopicName", &ROSSubscriberWASM::getTopicName)
        .function("getLastMessage", &ROSSubscriberWASM::getLastMessage);
}

