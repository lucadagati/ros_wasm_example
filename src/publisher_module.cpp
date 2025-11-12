#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>

using namespace emscripten;

// Simulazione di un sensore nell'ambiente WASM 1
class PublisherNode {
private:
    int message_count;
    double sensor_value;

public:
    PublisherNode() : message_count(0), sensor_value(0.0) {}

    std::string generateMessage() {
        message_count++;
        // Simula lettura sensore (es: temperatura)
        sensor_value = 20.0 + (message_count % 10);
        
        char buffer[256];
        snprintf(buffer, sizeof(buffer), 
                 "{\"id\": %d, \"sensor\": \"temperature\", \"value\": %.2f, \"unit\": \"celsius\"}",
                 message_count, sensor_value);
        
        printf("WASM Publisher: Messaggio generato #%d - Valore: %.2f\n", 
               message_count, sensor_value);
        
        return std::string(buffer);
    }

    int getMessageCount() const {
        return message_count;
    }

    double getSensorValue() const {
        return sensor_value;
    }

    void reset() {
        message_count = 0;
        sensor_value = 0.0;
    }
};

EMSCRIPTEN_BINDINGS(publisher_module) {
    class_<PublisherNode>("PublisherNode")
        .constructor<>()
        .function("generateMessage", &PublisherNode::generateMessage)
        .function("getMessageCount", &PublisherNode::getMessageCount)
        .function("getSensorValue", &PublisherNode::getSensorValue)
        .function("reset", &PublisherNode::reset);
}

