#!/usr/bin/env python3
"""Create UML diagrams for microROS WASM K8s project"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
except ImportError:
    print("ERROR: Pillow not installed. Install with: pip install Pillow")
    exit(1)

# Create diagrams directory
os.makedirs('diagrams', exist_ok=True)

# Colors
COLORS = {
    'wasm': (102, 126, 234),
    'js': (76, 175, 80),
    'ros': (255, 193, 7),
    'k8s': (0, 123, 255),
    'topic': (156, 39, 176),
    'bg': (255, 255, 255),
    'text': (0, 0, 0),
    'line': (100, 100, 100)
}

def create_architecture_diagram():
    """Create architecture diagram"""
    width, height = 1200, 800
    img = Image.new('RGB', (width, height), COLORS['bg'])
    draw = ImageDraw.Draw(img)
    
    # Try to use a font, fallback to default
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # Title
    draw.text((width//2 - 200, 30), "WASM-ROS Communication Architecture", fill=COLORS['text'], font=font_large)
    
    # Publisher WASM (left)
    pub_x, pub_y = 100, 200
    pub_w, pub_h = 200, 150
    draw.rectangle([pub_x, pub_y, pub_x + pub_w, pub_y + pub_h], fill=COLORS['wasm'], outline=(0, 0, 0), width=2)
    draw.text((pub_x + 20, pub_y + 20), "WASM Publisher", fill=(255, 255, 255), font=font_medium)
    draw.text((pub_x + 20, pub_y + 50), "Environment 1", fill=(255, 255, 255), font=font_small)
    draw.text((pub_x + 20, pub_y + 75), "Temp Sensor", fill=(255, 255, 255), font=font_small)
    
    # ROS Bridge (center)
    bridge_x, bridge_y = 450, 200
    bridge_w, bridge_h = 200, 150
    draw.rectangle([bridge_x, bridge_y, bridge_x + bridge_w, bridge_y + bridge_h], fill=COLORS['ros'], outline=(0, 0, 0), width=2)
    draw.text((bridge_x + 30, bridge_y + 20), "ROS Bridge", fill=(0, 0, 0), font=font_medium)
    draw.text((bridge_x + 30, bridge_y + 50), "WebSocket", fill=(0, 0, 0), font=font_small)
    draw.text((bridge_x + 30, bridge_y + 75), "Port 9090", fill=(0, 0, 0), font=font_small)
    
    # ROS Topic (center-top)
    topic_x, topic_y = 450, 100
    topic_w, topic_h = 200, 80
    draw.rectangle([topic_x, topic_y, topic_x + topic_w, topic_y + topic_h], fill=COLORS['topic'], outline=(0, 0, 0), width=2)
    draw.text((topic_x + 20, topic_y + 20), "ROS Topic", fill=(255, 255, 255), font=font_medium)
    draw.text((topic_x + 20, topic_y + 50), "/sensor/temp", fill=(255, 255, 255), font=font_small)
    
    # Subscriber WASM (right)
    sub_x, sub_y = 800, 200
    sub_w, sub_h = 200, 150
    draw.rectangle([sub_x, sub_y, sub_x + sub_w, sub_y + sub_h], fill=(245, 87, 108), outline=(0, 0, 0), width=2)
    draw.text((sub_x + 20, sub_y + 20), "WASM Subscriber", fill=(255, 255, 255), font=font_medium)
    draw.text((sub_x + 20, sub_y + 50), "Environment 2", fill=(255, 255, 255), font=font_small)
    draw.text((sub_x + 20, sub_y + 75), "Actuator", fill=(255, 255, 255), font=font_small)
    
    # Arrows
    # Publisher -> Bridge
    draw.line([pub_x + pub_w, pub_y + pub_h//2, bridge_x, bridge_y + bridge_h//2], fill=COLORS['line'], width=3)
    draw.polygon([(bridge_x, bridge_y + bridge_h//2), (bridge_x - 10, bridge_y + bridge_h//2 - 5), (bridge_x - 10, bridge_y + bridge_h//2 + 5)], fill=COLORS['line'])
    draw.text((pub_x + pub_w + 10, pub_y + pub_h//2 - 10), "WebSocket", fill=COLORS['line'], font=font_small)
    
    # Bridge -> Topic
    draw.line([bridge_x + bridge_w//2, bridge_y, bridge_x + bridge_w//2, topic_y + topic_h], fill=COLORS['line'], width=3)
    draw.polygon([(bridge_x + bridge_w//2, topic_y + topic_h), (bridge_x + bridge_w//2 - 5, topic_y + topic_h - 10), (bridge_x + bridge_w//2 + 5, topic_y + topic_h - 10)], fill=COLORS['line'])
    
    # Bridge -> Subscriber
    draw.line([bridge_x + bridge_w, bridge_y + bridge_h//2, sub_x, sub_y + sub_h//2], fill=COLORS['line'], width=3)
    draw.polygon([(sub_x, sub_y + sub_h//2), (sub_x - 10, sub_y + sub_h//2 - 5), (sub_x - 10, sub_y + sub_h//2 + 5)], fill=COLORS['line'])
    draw.text((bridge_x + bridge_w + 10, bridge_y + bridge_h//2 - 10), "WebSocket", fill=COLORS['line'], font=font_small)
    
    # Browser labels
    draw.text((pub_x, pub_y + pub_h + 20), "Browser Tab 1", fill=COLORS['text'], font=font_small)
    draw.text((sub_x, sub_y + sub_h + 20), "Browser Tab 2", fill=COLORS['text'], font=font_small)
    
    img.save('diagrams/architecture_diagram.png')
    print("✓ Created: diagrams/architecture_diagram.png")

def create_sequence_diagram():
    """Create sequence diagram"""
    width, height = 1200, 900
    img = Image.new('RGB', (width, height), COLORS['bg'])
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # Title
    draw.text((width//2 - 150, 30), "Communication Sequence Diagram", fill=COLORS['text'], font=font_large)
    
    # Participants (vertical positions)
    participants = [
        ("Publisher WASM", 150, COLORS['wasm']),
        ("JavaScript (Pub)", 300, COLORS['js']),
        ("ROS Bridge", 450, COLORS['ros']),
        ("ROS2 Topics", 600, COLORS['topic']),
        ("JavaScript (Sub)", 750, COLORS['js']),
        ("Subscriber WASM", 900, COLORS['wasm'])
    ]
    
    y_start = 120
    y_end = 800
    box_width = 140
    box_height = 60
    
    # Draw participants
    for name, x, color in participants:
        # Box
        draw.rectangle([x - box_width//2, y_start, x + box_width//2, y_start + box_height], 
                      fill=color, outline=(0, 0, 0), width=2)
        # Text
        text_color = (255, 255, 255) if color != COLORS['ros'] else (0, 0, 0)
        draw.text((x - box_width//2 + 10, y_start + 15), name, fill=text_color, font=font_small)
        # Lifeline
        draw.line([x, y_start + box_height, x, y_end], fill=COLORS['line'], width=2)
    
    # Messages
    msg_y = y_start + box_height + 50
    msg_spacing = 80
    
    messages = [
        (0, 1, "generateMessage()", True),
        (1, 2, "publish(topic, msg)", True),
        (2, 3, "ROS2 DDS publish", True),
        (3, 2, "message delivery", False),
        (2, 4, "message callback", False),
        (4, 5, "processMessage(data)", False)
    ]
    
    for from_idx, to_idx, msg_text, is_solid in messages:
        from_x = participants[from_idx][1]
        to_x = participants[to_idx][1]
        
        # Arrow line
        line_color = COLORS['line'] if is_solid else (200, 200, 200)
        draw.line([from_x, msg_y, to_x, msg_y], fill=line_color, width=2)
        
        # Arrow head
        if to_x > from_x:
            draw.polygon([(to_x, msg_y), (to_x - 8, msg_y - 4), (to_x - 8, msg_y + 4)], fill=line_color)
        else:
            draw.polygon([(to_x, msg_y), (to_x + 8, msg_y - 4), (to_x + 8, msg_y + 4)], fill=line_color)
        
        # Message text
        text_x = min(from_x, to_x) + abs(to_x - from_x)//2 - 50
        draw.text((text_x, msg_y - 15), msg_text, fill=COLORS['text'], font=font_small)
        
        msg_y += msg_spacing
    
    # Loop label
    draw.rectangle([100, y_end - 50, 300, y_end - 20], fill=(240, 240, 240), outline=COLORS['line'], width=1)
    draw.text((110, y_end - 40), "Loop: Every second", fill=COLORS['text'], font=font_small)
    
    img.save('diagrams/sequence_diagram.png')
    print("✓ Created: diagrams/sequence_diagram.png")

def create_k8s_deployment_diagram():
    """Create K8s deployment diagram"""
    width, height = 1200, 800
    img = Image.new('RGB', (width, height), COLORS['bg'])
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # Title
    draw.text((width//2 - 200, 30), "Kubernetes Deployment Architecture", fill=COLORS['text'], font=font_large)
    
    # K8s Cluster container
    cluster_x, cluster_y = 100, 150
    cluster_w, cluster_h = 1000, 600
    draw.rectangle([cluster_x, cluster_y, cluster_x + cluster_w, cluster_y + cluster_h], 
                  fill=(240, 248, 255), outline=COLORS['k8s'], width=3)
    draw.text((cluster_x + 20, cluster_y + 20), "Kubernetes Cluster", fill=COLORS['k8s'], font=font_medium)
    
    # Pod 1
    pod1_x, pod1_y = 200, 250
    pod1_w, pod1_h = 300, 200
    draw.rectangle([pod1_x, pod1_y, pod1_x + pod1_w, pod1_y + pod1_h], 
                  fill=(200, 220, 255), outline=(0, 0, 0), width=2)
    draw.text((pod1_x + 10, pod1_y + 10), "K8s Pod 1", fill=COLORS['text'], font=font_medium)
    
    # WASM Runtime 1
    wasm1_x, wasm1_y = pod1_x + 20, pod1_y + 50
    wasm1_w, wasm1_h = 120, 50
    draw.rectangle([wasm1_x, wasm1_y, wasm1_x + wasm1_w, wasm1_y + wasm1_h], 
                  fill=COLORS['wasm'], outline=(0, 0, 0), width=1)
    draw.text((wasm1_x + 5, wasm1_y + 15), "WASM Runtime", fill=(255, 255, 255), font=font_small)
    
    # microROS Node A
    micro1_x, micro1_y = pod1_x + 20, wasm1_y + wasm1_h + 10
    micro1_w, micro1_h = 120, 50
    draw.rectangle([micro1_x, micro1_y, micro1_x + micro1_w, micro1_y + micro1_h], 
                  fill=COLORS['js'], outline=(0, 0, 0), width=1)
    draw.text((micro1_x + 5, micro1_y + 15), "microROS Node A", fill=(255, 255, 255), font=font_small)
    
    # Pod 2
    pod2_x, pod2_y = 700, 250
    pod2_w, pod2_h = 300, 200
    draw.rectangle([pod2_x, pod2_y, pod2_x + pod2_w, pod2_y + pod2_h], 
                  fill=(200, 220, 255), outline=(0, 0, 0), width=2)
    draw.text((pod2_x + 10, pod2_y + 10), "K8s Pod 2", fill=COLORS['text'], font=font_medium)
    
    # WASM Runtime 2
    wasm2_x, wasm2_y = pod2_x + 20, pod2_y + 50
    wasm2_w, wasm2_h = 120, 50
    draw.rectangle([wasm2_x, wasm2_y, wasm2_x + wasm2_w, wasm2_y + wasm2_h], 
                  fill=COLORS['wasm'], outline=(0, 0, 0), width=1)
    draw.text((wasm2_x + 5, wasm2_y + 15), "WASM Runtime", fill=(255, 255, 255), font=font_small)
    
    # microROS Node B
    micro2_x, micro2_y = pod2_x + 20, wasm2_y + wasm2_h + 10
    micro2_w, micro2_h = 120, 50
    draw.rectangle([micro2_x, micro2_y, micro2_x + micro2_w, micro2_y + micro2_h], 
                  fill=COLORS['js'], outline=(0, 0, 0), width=1)
    draw.text((micro2_x + 5, micro2_y + 15), "microROS Node B", fill=(255, 255, 255), font=font_small)
    
    # Connection arrow
    draw.line([pod1_x + pod1_w, pod1_y + pod1_h//2, pod2_x, pod2_y + pod2_h//2], 
             fill=COLORS['topic'], width=4)
    draw.polygon([(pod2_x, pod2_y + pod2_h//2), (pod2_x - 10, pod2_y + pod2_h//2 - 5), 
                  (pod2_x - 10, pod2_y + pod2_h//2 + 5)], fill=COLORS['topic'])
    draw.text((pod1_x + pod1_w + 20, pod1_y + pod1_h//2 - 10), "ROS Topics/Services", 
             fill=COLORS['topic'], font=font_small)
    
    # K8s management features
    mgmt_y = cluster_y + cluster_h - 100
    draw.text((cluster_x + 20, mgmt_y), "K8s manages:", fill=COLORS['text'], font=font_medium)
    features = ["• Deployment & Scaling", "• Health Checks", "• Updates & Recovery", "• Service Discovery"]
    for i, feature in enumerate(features):
        draw.text((cluster_x + 20, mgmt_y + 30 + i*25), feature, fill=COLORS['text'], font=font_small)
    
    img.save('diagrams/k8s_deployment_diagram.png')
    print("✓ Created: diagrams/k8s_deployment_diagram.png")

if __name__ == "__main__":
    print("Creating UML diagrams...")
    create_architecture_diagram()
    create_sequence_diagram()
    create_k8s_deployment_diagram()
    print("\n✓ All diagrams created in diagrams/ directory")

