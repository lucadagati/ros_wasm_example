/*
 * rcl/rclc Types for WASM
 * 
 * Common type definitions for rcl and rclc ports.
 * These will be replaced with actual microROS types when ported.
 */

#ifndef RCL_TYPES_WASM_H
#define RCL_TYPES_WASM_H

// rcl types (simplified for WASM)
typedef struct {
    void* impl;
} rcl_node_t;

typedef struct {
    void* impl;
} rcl_publisher_t;

typedef struct {
    void* impl;
} rcl_subscription_t;

typedef struct {
    void* impl;
} rcl_context_t;

typedef struct {
    rcl_context_t* context;
    void* allocator;
} rcl_init_options_t;

typedef struct {
    int dummy;
} rcl_node_options_t;

typedef struct {
    int dummy;
} rcl_publisher_options_t;

typedef struct {
    int dummy;
} rcl_subscription_options_t;

// rclc types
typedef struct {
    rcl_context_t* context;
    void* allocator;
} rclc_support_t;

typedef struct {
    void* impl;
} rclc_executor_t;

// rosidl types
typedef struct {
    int dummy;
} rosidl_message_type_support_t;

// rmw types
typedef struct {
    int dummy;
} rmw_publisher_allocation_t;

typedef struct {
    int dummy;
} rmw_message_info_t;

typedef struct {
    int dummy;
} rmw_subscription_allocation_t;

// rcl return codes
typedef enum {
    RCL_RET_OK = 0,
    RCL_RET_ERROR = 1,
    RCL_RET_BAD_ALLOC = 2,
    RCL_RET_INVALID_ARGUMENT = 3,
    RCL_RET_TIMEOUT = 4,
} rcl_ret_t;

// rclc executor handle types
typedef enum {
    RCLC_EXECUTOR_HANDLE_TYPE_SUBSCRIPTION = 0,
    RCLC_EXECUTOR_HANDLE_TYPE_TIMER = 1,
    RCLC_EXECUTOR_HANDLE_TYPE_CLIENT = 2,
    RCLC_EXECUTOR_HANDLE_TYPE_SERVICE = 3,
} rclc_executor_handle_type_t;

#endif // RCL_TYPES_WASM_H

