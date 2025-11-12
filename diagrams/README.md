# UML Diagrams

This directory contains formal UML diagrams for the WASM-ROS Communication project.

## PlantUML Source Files

- `architecture.puml` - System architecture diagram showing WASM modules, ROS Bridge, and communication flow
- `sequence.puml` - Sequence diagram showing message flow between components
- `k8s_deployment.puml` - Kubernetes deployment architecture
- `component_diagram.puml` - Component diagram showing system modules and dependencies
- `class_diagram.puml` - Class diagram for WASM modules (PublisherNode and SubscriberNode)

## Generated PNG Files

All `.puml` files are converted to PNG images using PlantUML online service.

## Conversion

To regenerate PNG files from PlantUML sources:

```bash
python3 convert_uml_online.py
```

Or if PlantUML is installed locally:

```bash
./convert_uml_to_png.sh
```

## Diagram Types

1. **Architecture Diagram**: High-level system architecture
2. **Sequence Diagram**: Communication flow between components
3. **K8s Deployment Diagram**: Kubernetes orchestration structure
4. **Component Diagram**: System components and their relationships
5. **Class Diagram**: WASM module class structures

All diagrams are included in the PPTX presentation.

