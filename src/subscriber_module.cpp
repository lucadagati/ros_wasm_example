#include <emscripten.h>
#include <emscripten/bind.h>
#include <string>
#include <cstdio>
#include <vector>

using namespace emscripten;

// Simulazione di un attuatore nell'ambiente WASM 2
class SubscriberNode {
private:
    int messages_received;
    std::vector<double> received_values;
    double last_value;
    std::string last_message;

public:
    SubscriberNode() : messages_received(0), last_value(0.0), last_message("") {}

    void processMessage(const std::string& message) {
        messages_received++;
        last_message = message;
        
        // Semplice parsing per estrarre il valore
        size_t pos = message.find("\"value\":");
        if (pos != std::string::npos) {
            sscanf(message.c_str() + pos + 8, "%lf", &last_value);
            received_values.push_back(last_value);
            
            // Limita la storia a 10 valori
            if (received_values.size() > 10) {
                received_values.erase(received_values.begin());
            }
        }
        
        printf("WASM Subscriber: Messaggio ricevuto #%d - Valore: %.2f\n", 
               messages_received, last_value);
        
        // Simula reazione dell'attuatore
        if (last_value > 25.0) {
            printf("WASM Subscriber: AZIONE - Temperatura alta, attivazione sistema raffreddamento!\n");
        }
    }

    int getMessagesReceived() const {
        return messages_received;
    }

    double getLastValue() const {
        return last_value;
    }

    std::string getLastMessage() const {
        return last_message;
    }

    double getAverageValue() const {
        if (received_values.empty()) return 0.0;
        
        double sum = 0.0;
        for (double val : received_values) {
            sum += val;
        }
        return sum / received_values.size();
    }

    void reset() {
        messages_received = 0;
        received_values.clear();
        last_value = 0.0;
        last_message = "";
    }
};

EMSCRIPTEN_BINDINGS(subscriber_module) {
    class_<SubscriberNode>("SubscriberNode")
        .constructor<>()
        .function("processMessage", &SubscriberNode::processMessage)
        .function("getMessagesReceived", &SubscriberNode::getMessagesReceived)
        .function("getLastValue", &SubscriberNode::getLastValue)
        .function("getLastMessage", &SubscriberNode::getLastMessage)
        .function("getAverageValue", &SubscriberNode::getAverageValue)
        .function("reset", &SubscriberNode::reset);
}

