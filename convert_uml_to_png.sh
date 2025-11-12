#!/bin/bash
# Convert PlantUML files to PNG images

echo "Converting PlantUML diagrams to PNG..."

# Check if PlantUML is available
if command -v plantuml &> /dev/null; then
    PLANTUML_CMD="plantuml"
elif command -v java &> /dev/null; then
    # Try to use PlantUML JAR if available
    if [ -f "plantuml.jar" ]; then
        PLANTUML_CMD="java -jar plantuml.jar"
    else
        echo "Downloading PlantUML..."
        wget -q https://github.com/plantuml/plantuml/releases/download/v1.2023.13/plantuml-1.2023.13.jar -O plantuml.jar
        PLANTUML_CMD="java -jar plantuml.jar"
    fi
else
    echo "ERROR: PlantUML not found and Java not available"
    echo "Install PlantUML: sudo apt install plantuml"
    echo "Or install Java and download PlantUML JAR"
    exit 1
fi

cd diagrams

# Convert all .puml files to PNG
for file in *.puml; do
    if [ -f "$file" ]; then
        echo "Converting $file..."
        $PLANTUML_CMD -tpng "$file"
        if [ $? -eq 0 ]; then
            echo "✓ Created: ${file%.puml}.png"
        else
            echo "✗ Error converting $file"
        fi
    fi
done

cd ..

echo ""
echo "✓ Conversion complete!"
ls -lh diagrams/*.png 2>/dev/null | tail -5

