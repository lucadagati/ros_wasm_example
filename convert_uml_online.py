#!/usr/bin/env python3
"""Convert PlantUML files to PNG using online service"""

import os
import urllib.request
import urllib.parse
import base64
import zlib

def encode_plantuml(text):
    """Encode PlantUML text for URL"""
    compressed = zlib.compress(text.encode('utf-8'))
    encoded = base64.b64encode(compressed).decode('ascii')
    # PlantUML encoding: replace characters
    encoded = encoded.translate(str.maketrans('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', 
                                              '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'))
    return encoded

def convert_puml_to_png(puml_file, output_file):
    """Convert PlantUML file to PNG using online service"""
    print(f"Converting {puml_file}...")
    
    # Read PlantUML file
    with open(puml_file, 'r') as f:
        puml_text = f.read()
    
    # Encode for URL
    encoded = encode_plantuml(puml_text)
    
    # Use PlantUML online server
    url = f"http://www.plantuml.com/plantuml/png/{encoded}"
    
    try:
        # Download PNG
        urllib.request.urlretrieve(url, output_file)
        print(f"✓ Created: {output_file}")
        return True
    except Exception as e:
        print(f"✗ Error converting {puml_file}: {e}")
        # Try alternative: use plantuml.com/plantuml/img/ endpoint
        try:
            url_alt = f"http://www.plantuml.com/plantuml/img/{encoded}"
            urllib.request.urlretrieve(url_alt, output_file)
            print(f"✓ Created (alt): {output_file}")
            return True
        except Exception as e2:
            print(f"✗ Alternative also failed: {e2}")
            return False

if __name__ == "__main__":
    diagrams_dir = "diagrams"
    
    if not os.path.exists(diagrams_dir):
        print(f"ERROR: {diagrams_dir} directory not found")
        exit(1)
    
    puml_files = [f for f in os.listdir(diagrams_dir) if f.endswith('.puml')]
    
    if not puml_files:
        print("No PlantUML files found")
        exit(1)
    
    print(f"Found {len(puml_files)} PlantUML files")
    print("Converting using PlantUML online service...\n")
    
    success_count = 0
    for puml_file in puml_files:
        puml_path = os.path.join(diagrams_dir, puml_file)
        png_file = puml_file.replace('.puml', '.png')
        png_path = os.path.join(diagrams_dir, png_file)
        
        if convert_puml_to_png(puml_path, png_path):
            success_count += 1
    
    print(f"\n✓ Converted {success_count}/{len(puml_files)} diagrams")
    
    if success_count > 0:
        print("\nGenerated PNG files:")
        for puml_file in puml_files:
            png_file = puml_file.replace('.puml', '.png')
            png_path = os.path.join(diagrams_dir, png_file)
            if os.path.exists(png_path):
                size = os.path.getsize(png_path)
                print(f"  {png_file}: {size} bytes")

