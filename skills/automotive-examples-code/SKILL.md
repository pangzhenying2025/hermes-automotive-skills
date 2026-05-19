---
name: automotive-examples-code
description: >
  Production-ready automotive code examples from automotive-claude-code-agents.
  Includes BMS ECU firmware (C), ADAS perception pipeline (Python), battery thermal modeling,
  network topologies, multi-region cloud deployment (Terraform/K8s), and automotive protocol demos.
  Use when the user wants real working code for automotive ECUs, ADAS, BMS, or deployment.
tags: [automotive, examples, code, adas, bms, autosar, terraform, kubernetes]
---

# Automotive Code Examples

Full production-ready code examples from the automotive-claude-code-agents repository.

## Examples Index

| Example | Language | Description |
|---------|----------|-------------|
| `adas-perception/` | Python | Camera-based object detection pipeline for ADAS |
| `ecu-bms/` | C | Full BMS firmware with RTE, cell monitoring, SOC estimation |
| `battery-thermal/` | - | Battery thermal modeling reference |
| `network-topologies/` | Docker/YAML | Automotive Ethernet topologies with Docker Compose |
| `multi-region-deployment/` | TF/K8s/SQL | Multi-region cloud deployment for connected vehicles |
| `automotive_protocols_demo.py` | Python | CAN/LIN/Ethernet protocol interaction demo |

## File List

  - `examples/adas-perception\config\pipeline_config.yaml`
  - `examples/adas-perception\src\camera\detector.py`
  - `examples/adas-perception\src\main.py`
  - `examples/adas-perception\tests\test_camera.py`
  - `examples/automotive_protocols_demo.py`
  - `examples/ecu-bms\requirements\bms-requirements.yaml`
  - `examples/ecu-bms\src\application\cell_monitor.c`
  - `examples/ecu-bms\src\application\cell_monitor.h`
  - `examples/ecu-bms\src\application\soc_estimator.c`
  - `examples/ecu-bms\src\application\soc_estimator.h`
  - `examples/ecu-bms\src\rte\Rte_BMS.c`
  - `examples/ecu-bms\src\rte\Rte_BMS.h`
  - `examples/ecu-bms\tests\unit\test_cell_monitor.c`
  - `examples/multi-region-deployment\database\setup-multi-region-replication.sql`
  - `examples/multi-region-deployment\kubernetes\applications\vehicle-gateway-deployment.yaml`
  - `examples/multi-region-deployment\scripts\failover-to-region.sh`
  - `examples/multi-region-deployment\terraform\global\main.tf`
  - `examples/multi-region-deployment\terraform\us-east-1\main.tf`
  - `examples/network-topologies\docker-compose.yml`
  - `examples/network-topologies\setup.sh`
  - `examples/network-topologies\test-virtual-network.py`
  - `examples/qnx\complete_workflow.py`
  - `examples/qnx-adaptive-platform\deployment\execution\adas_controller.json`
  - `examples/qnx-adaptive-platform\deployment\machine\machine_manifest.json`
  - `examples/qnx-adaptive-platform\runtime\ara_com\include\ara\com\skeleton.h`
  - `examples/qnx-adaptive-platform\runtime\ara_com\include\ara\com\types.h`
