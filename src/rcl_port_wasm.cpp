/*
 * rcl (ROS Client Library) Port for WASM
 * 
 * This file provides WASM-compatible implementations of rcl functions.
 * It bridges rcl API with our custom RMW implementation.
 */

#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include "rcl_types_wasm.h"
#include "rmw_custom_wasm.cpp"

// TODO: Include actual rcl headers when ported
// #include <rcl/rcl.h>
class DDSParticipantWASM;

// Global RMW instance (in real implementation, would be per-context)
static RMWCustomWASM* g_rmw_instance = nullptr;

// rcl_init - Initialize ROS Client Library
extern "C" rcl_ret_t rcl_init(
    int argc,
    char const * const * argv,
    const rcl_init_options_t* options,
    rcl_context_t* context)
{
    printf("WASM: rcl_init called\n");
    
    // Initialize our RMW (which uses our DDS layer)
    if (!g_rmw_instance) {
        g_rmw_instance = new RMWCustomWASM();
        if (!g_rmw_instance->init()) {
            printf("WASM: Failed to initialize RMW\n");
            return RCL_RET_ERROR;
        }
    }
    
    // Initialize context (store RMW instance)
    if (context) {
        context->impl = g_rmw_instance;
    }
    
    return RCL_RET_OK;
}

// rcl_node_init - Initialize ROS node
extern "C" rcl_ret_t rcl_node_init(
    rcl_node_t* node,
    const char* name,
    const char* namespace_,
    rcl_context_t* context,
    const rcl_node_options_t* options)
{
    printf("WASM: rcl_node_init called: %s\n", name);
    
    if (!node || !context || !g_rmw_instance) {
        return RCL_RET_INVALID_ARGUMENT;
    }
    
    // Create DDS participant via RMW
    std::string node_name = name;
    if (namespace_ && strlen(namespace_) > 0) {
        node_name = std::string(namespace_) + "/" + name;
    }
    
    void* participant = g_rmw_instance->createParticipant(node_name, 0);
    if (!participant) {
        printf("WASM: Failed to create DDS participant\n");
        return RCL_RET_ERROR;
    }
    
    // Store participant in node
    node->impl = participant;
    
    printf("WASM: ROS node initialized: %s\n", node_name.c_str());
    return RCL_RET_OK;
}

// rcl_publisher_init - Initialize publisher
extern "C" rcl_ret_t rcl_publisher_init(
    rcl_publisher_t* publisher,
    const rcl_node_t* node,
    const rosidl_message_type_support_t* type_support,
    const char* topic_name,
    const rcl_publisher_options_t* options)
{
    printf("WASM: rcl_publisher_init called: %s\n", topic_name);
    
    if (!publisher || !node || !node->impl || !g_rmw_instance) {
        return RCL_RET_INVALID_ARGUMENT;
    }
    
    // Create publisher via RMW
    void* pub_handle = g_rmw_instance->createPublisher(node->impl, topic_name, "std_msgs::msg::String");
    if (!pub_handle) {
        printf("WASM: Failed to create publisher\n");
        return RCL_RET_ERROR;
    }
    
    // Store publisher handle
    publisher->impl = pub_handle;
    
    printf("WASM: Publisher initialized on topic: %s\n", topic_name);
    return RCL_RET_OK;
}

// rcl_publish - Publish message
extern "C" rcl_ret_t rcl_publish(
    const rcl_publisher_t* publisher,
    const void* ros_message,
    rmw_publisher_allocation_t* allocation)
{
    if (!publisher || !publisher->impl || !g_rmw_instance) {
        return RCL_RET_INVALID_ARGUMENT;
    }
    
    // TODO: Extract message data from ros_message
    // For now, assume ros_message is a string pointer
    const char* data = static_cast<const char*>(ros_message);
    std::string message_data = data ? std::string(data) : "";
    
    // Publish via our RMW (which uses our DDS)
    if (g_rmw_instance->publish(publisher->impl, message_data)) {
        return RCL_RET_OK;
    }
    
    return RCL_RET_ERROR;
}

// rcl_subscription_init - Initialize subscriber
extern "C" rcl_ret_t rcl_subscription_init(
    rcl_subscription_t* subscription,
    const rcl_node_t* node,
    const rosidl_message_type_support_t* type_support,
    const char* topic_name,
    const rcl_subscription_options_t* options)
{
    printf("WASM: rcl_subscription_init called: %s\n", topic_name);
    
    if (!subscription || !node || !node->impl || !g_rmw_instance) {
        return RCL_RET_INVALID_ARGUMENT;
    }
    
    // Create subscriber via RMW
    void* sub_handle = g_rmw_instance->createSubscriber(node->impl, topic_name, "std_msgs::msg::String");
    if (!sub_handle) {
        printf("WASM: Failed to create subscriber\n");
        return RCL_RET_ERROR;
    }
    
    // Store subscriber handle
    subscription->impl = sub_handle;
    
    printf("WASM: Subscriber initialized on topic: %s\n", topic_name);
    return RCL_RET_OK;
}

// rcl_take - Take message from subscription
extern "C" rcl_ret_t rcl_take(
    const rcl_subscription_t* subscription,
    void* ros_message,
    rmw_message_info_t* message_info,
    rmw_subscription_allocation_t* allocation)
{
    if (!subscription || !subscription->impl || !g_rmw_instance) {
        return RCL_RET_INVALID_ARGUMENT;
    }
    
    // Take message via our RMW
    std::string data;
    if (g_rmw_instance->take(subscription->impl, data)) {
        // TODO: Copy to ros_message (std_msgs__msg__String)
        // For now, assume ros_message is a char* buffer
        if (ros_message) {
            char* msg_buffer = static_cast<char*>(ros_message);
            strncpy(msg_buffer, data.c_str(), 1024); // Assume buffer size
            msg_buffer[1023] = '\0';
        }
        return RCL_RET_OK;
    }
    
    // No message available
    return RCL_RET_TIMEOUT;
}

// Types are now in rcl_types_wasm.h

