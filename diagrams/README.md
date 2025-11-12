# UML Diagrams

This directory contains formal UML diagrams for the WASM-ROS Communication project.

## PlantUML Source Files

### Core Architecture Diagrams

- **`architecture.puml`** - Basic system architecture showing microROS in WASM
- **`architecture_complete.puml`** - Complete architecture with Kubernetes orchestration
- **`k8s_deployment.puml`** - Kubernetes deployment architecture
- **`deployment_diagram.puml`** - Infrastructure deployment diagram

### Communication & Flow Diagrams

- **`sequence.puml`** - Sequence diagram showing message flow between components
- **`workflow.puml`** - Complete workflow from deployment to message processing

### System Structure Diagrams

- **`component_diagram.puml`** - Component diagram showing system modules and dependencies
- **`package_diagram.puml`** - Package structure and organization
- **`class_diagram.puml`** - Class diagram for WASM modules (PublisherNode and SubscriberNode)

### Behavioral Diagrams

- **`state_diagram.puml`** - State machine for microROS nodes
- **`use_case_diagram.puml`** - Use cases for the system

### Master File

- **`all_diagrams.puml`** - Master document (placeholder for combined view)

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

## Diagram Types Summary

1. **Architecture Diagrams** (4):
   - Basic architecture
   - Complete architecture with K8s
   - K8s deployment
   - Infrastructure deployment

2. **Communication Diagrams** (2):
   - Sequence diagram
   - Workflow diagram

3. **Structure Diagrams** (3):
   - Component diagram
   - Package diagram
   - Class diagram

4. **Behavioral Diagrams** (2):
   - State diagram
   - Use case diagram

**Total: 12 UML diagrams**

## Key Architecture Points

All diagrams show:
- **microROS runs INSIDE WASM Runtime** (not external)
- **Direct ROS2 DDS communication** between WASM environments
- **No external ROS Bridge** needed
- **Kubernetes orchestration** of WASM runtimes
- **Complete isolation** and portability

## Usage in PPTX

Selected diagrams are included in the PPTX presentation:
- Complete Architecture Schema
- System Workflow
- Communication Sequence
- K8s Deployment
- Component & Class Diagrams

All diagrams are available in both PlantUML source (`.puml`) and PNG format (`.png`).
