/*
 * Test Server for WASM Runtime Communication
 * 
 * This server bridges communication between multiple WASM runtimes
 * running ROS nodes. It simulates the network layer.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');

const PORT = 8080;
const DDS_DISCOVERY_PORT = 7400;

// Store connected WASM runtimes
const participants = new Map();
const publishers = new Map();
const subscribers = new Map();

// Create HTTP server
const server = http.createServer((req, res) => {
    let filePath = '.' + req.url;
    if (filePath === './') {
        filePath = './test_communication.html';
    }
    
    const extname = String(path.extname(filePath)).toLowerCase();
    const mimeTypes = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.wasm': 'application/wasm',
        '.json': 'application/json',
        '.css': 'text/css'
    };
    
    const contentType = mimeTypes[extname] || 'application/octet-stream';
    
    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('404 Not Found');
            } else {
                res.writeHead(500);
                res.end('Server Error: ' + error.code);
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

// Create WebSocket server for DDS communication
const wss = new WebSocket.Server({ 
    server: server,
    path: '/dds'
});

wss.on('connection', (ws, req) => {
    console.log('New WASM runtime connected');
    
    let runtimeId = null;
    let runtimeType = null; // 'publisher' or 'subscriber'
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            
            if (data.type === 'register') {
                runtimeId = data.id;
                runtimeType = data.runtimeType;
                
                if (runtimeType === 'publisher') {
                    participants.set(runtimeId, { ws, type: 'publisher', topics: [] });
                    publishers.set(runtimeId, { ws, topics: [] });
                    console.log(`Publisher registered: ${runtimeId}`);
                } else if (runtimeType === 'subscriber') {
                    participants.set(runtimeId, { ws, type: 'subscriber', topics: [] });
                    subscribers.set(runtimeId, { ws, topics: [] });
                    console.log(`Subscriber registered: ${runtimeId}`);
                }
                
                // Notify other participants
                broadcastDiscovery(runtimeId, runtimeType);
            } else if (data.type === 'discovery') {
                // Handle DDS discovery message
                handleDiscovery(data, runtimeId);
            } else if (data.type === 'publish') {
                // Handle message publication
                handlePublish(data, runtimeId);
            } else if (data.type === 'subscribe') {
                // Handle subscription
                handleSubscribe(data, runtimeId);
            }
        } catch (error) {
            console.error('Error processing message:', error);
        }
    });
    
    ws.on('close', () => {
        if (runtimeId) {
            participants.delete(runtimeId);
            if (runtimeType === 'publisher') {
                publishers.delete(runtimeId);
            } else if (runtimeType === 'subscriber') {
                subscribers.delete(runtimeId);
            }
            console.log(`Runtime disconnected: ${runtimeId}`);
        }
    });
});

function broadcastDiscovery(newId, newType) {
    // Notify all participants about new participant
    participants.forEach((participant, id) => {
        if (id !== newId) {
            participant.ws.send(JSON.stringify({
                type: 'discovery',
                participant: {
                    id: newId,
                    type: newType
                }
            }));
        }
    });
}

function handleDiscovery(data, fromId) {
    // Forward discovery to other participants
    participants.forEach((participant, id) => {
        if (id !== fromId) {
            participant.ws.send(JSON.stringify(data));
        }
    });
}

function handlePublish(data, fromId) {
    // Forward published message to all subscribers of the topic
    const topic = data.topic;
    const message = data.message;
    
    console.log(`Message published on ${topic} by ${fromId}`);
    
    subscribers.forEach((subscriber, id) => {
        if (subscriber.topics.includes(topic)) {
            subscriber.ws.send(JSON.stringify({
                type: 'message',
                topic: topic,
                data: message,
                from: fromId
            }));
            console.log(`Message forwarded to subscriber ${id}`);
        }
    });
}

function handleSubscribe(data, subscriberId) {
    const topic = data.topic;
    const subscriber = subscribers.get(subscriberId);
    
    if (subscriber && !subscriber.topics.includes(topic)) {
        subscriber.topics.push(topic);
        console.log(`Subscriber ${subscriberId} subscribed to ${topic}`);
        
        // Notify publishers
        publishers.forEach((publisher, id) => {
            publisher.ws.send(JSON.stringify({
                type: 'subscriber_discovered',
                topic: topic,
                subscriber: subscriberId
            }));
        });
    }
}

server.listen(PORT, () => {
    console.log('========================================');
    console.log('WASM ROS Communication Test Server');
    console.log('========================================');
    console.log('');
    console.log(`HTTP Server: http://localhost:${PORT}`);
    console.log(`WebSocket: ws://localhost:${PORT}/dds`);
    console.log('');
    console.log('Open in browser:');
    console.log(`  http://localhost:${PORT}/test_communication.html`);
    console.log('');
});

