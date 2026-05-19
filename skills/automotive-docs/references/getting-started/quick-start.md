# Quick Start Guide - Automotive Claude Code Agents

## 5-Minute Getting Started

This guide gets you up and running with automotive AI agents in 5 minutes.

## Prerequisites

- Linux/macOS with Python 3.8+
- Anthropic API key ([get one here](https://console.anthropic.com))
- Basic understanding of automotive software development

## Step 1: Installation (2 minutes)

```bash
# Clone and install
git clone https://github.com/yourusername/automotive-claude-code-agents.git
cd automotive-claude-code-agents
./scripts/install.sh

# Activate environment
source .venv/bin/activate
```

## Step 2: Configuration (1 minute)

```bash
# Set API key
export ANTHROPIC_API_KEY="your-api-key-here"

# Or add to .env file
echo "ANTHROPIC_API_KEY=your-api-key-here" >> .env
```

## Step 3: Run Your First Agent (2 minutes)

### Example 1: Code Review Agent

Review AUTOSAR C code for compliance:

```bash
# Run code reviewer on sample file
./agents/code-reviewer/run.sh examples/autosar_sample.c

# Output:
# ✓ MISRA C compliance check
# ✓ AUTOSAR naming conventions
# ✗ Missing safety annotations (3 issues)
# Suggestions: [detailed report]
```

### Example 2: AUTOSAR Architecture Agent

Generate AUTOSAR SWC from requirements:

```bash
# Run architecture agent
./agents/autosar-architect/run.sh --requirements examples/cruise_control_req.yaml

# Output:
# Generated:
# - SWC definition (CruiseControl.arxml)
# - Interface specifications (3 ports)
# - Runnable entities (5 runnables)
# - RTE configuration
```

### Example 3: CAN Analysis Agent

Analyze CAN database:

```bash
# Analyze DBC file
./agents/can-analyst/run.sh examples/vehicle_can.dbc

# Output:
# Messages: 127
# Signals: 543
# ✓ No ID conflicts
# ✗ Warning: Bus load > 70% at 10ms cycle
# Suggestions: [optimization recommendations]
```

## Common Use Cases

### Use Case 1: Review AUTOSAR BSW Configuration

```bash
# Point agent to your tresos project
./agents/bsw-validator/run.sh /path/to/tresos/project

# Validates:
# - Module dependencies
# - Parameter ranges
# - Resource allocation
# - Timing constraints
```

### Use Case 2: Generate UDS Diagnostic Services

```bash
# From diagnostic specification
./agents/uds-generator/run.sh --spec examples/diagnostics.yaml --output src/dcm

# Generates:
# - Dcm service handlers
# - DID read/write functions
# - Security access routines
# - Test cases
```

### Use Case 3: Optimize CAN Message Layout

```bash
# Optimize signal packing
./agents/can-optimizer/run.sh --dbc vehicle.dbc --optimize-for size

# Results:
# - Reduced messages: 127 → 98
# - Bus load: 75% → 58%
# - Preserved signal semantics
# - Updated DBC file: vehicle_optimized.dbc
```

### Use Case 4: ISO 26262 Compliance Check

```bash
# Check safety requirements coverage
./agents/safety-auditor/run.sh --requirements safety_reqs.yaml --code src/

# Report:
# - Requirements traced: 87/100
# - Missing safety mechanisms: 5
# - ASIL compliance: ASIL-C achieved
# - Suggestions for ASIL-D compliance
```

## Interactive Mode

Launch interactive agent console:

```bash
# Start CLI
./cli.py

# Interactive session:
>>> agent: code-reviewer
>>> file: examples/autosar_sample.c
>>> analyze

# Or use natural language:
>>> "Review this AUTOSAR code for MISRA compliance"
```

## Web Interface

Launch web-based agent interface:

```bash
# Start server
make serve-web

# Open browser: http://localhost:8080
# Upload files, select agents, view results
```

## Using Skills Directly

Skills can be used independently of agents:

```bash
# Use AUTOSAR SWC generator skill
python -c "
from skills.autosar.swc_generator import generate_swc
swc = generate_swc(
    name='CruiseControl',
    ports=['SpeedInput', 'ThrottleOutput'],
    runnables=['ControlLoop']
)
print(swc.to_arxml())
"
```

## Using Commands

Commands orchestrate multiple skills:

```bash
# Run AUTOSAR workflow command
./commands/autosar-workflow.sh \
  --requirements cruise_control.yaml \
  --generate-swc \
  --generate-rte \
  --build

# Executes:
# 1. Parse requirements
# 2. Generate SWC
# 3. Generate RTE
# 4. Configure BSW
# 5. Build project
```

## Custom Workflows

Create custom workflows with YAML:

```yaml
# workflow.yaml
name: My AUTOSAR Workflow
steps:
  - agent: requirements-analyzer
    input: requirements.yaml
    output: analyzed_reqs.json

  - agent: autosar-architect
    input: analyzed_reqs.json
    output: architecture/

  - agent: code-generator
    input: architecture/
    output: src/

  - agent: code-reviewer
    input: src/
    output: review_report.md

  - agent: test-generator
    input: architecture/
    output: tests/
```

Run with:
```bash
./run-workflow.sh workflow.yaml
```

## Explore Knowledge Base

Access 500+ automotive reference documents:

```bash
# Search knowledge base
./tools/kb-search.sh "AUTOSAR RTE"

# Results:
# - standards/autosar-classic/2-conceptual.md
# - standards/autosar-classic/3-detailed.md
# - tutorials/rte-configuration.md

# View document
./tools/kb-view.sh standards/autosar-classic/3-detailed.md
```

## Example Projects

Pre-built examples in `examples/` directory:

```
examples/
├── autosar-classic/
│   ├── simple-swc/          ← Basic SWC example
│   ├── multi-core/          ← Multi-core OS config
│   └── safety-critical/     ← ASIL-D example
├── autosar-adaptive/
│   ├── service-proxy/       ← ara::com example
│   └── crypto-service/      ← ara::crypto example
├── can-networks/
│   ├── powertrain.dbc       ← CAN database
│   └── body-control.dbc
├── diagnostics/
│   └── uds-services/        ← UDS implementation
└── yocto/
    └── meta-automotive/     ← Yocto layer example
```

Run any example:
```bash
cd examples/autosar-classic/simple-swc
make
```

## Next Steps

### Learn More

1. **Tutorials**: Comprehensive guides in `docs/tutorials/`
   - [AUTOSAR SWC Development](../tutorials/autosar-swc-tutorial.md)
   - [CAN Network Design](../tutorials/can-network-tutorial.md)
   - [ISO 26262 Workflow](../tutorials/iso26262-workflow.md)

2. **Reference Documentation**: `knowledge-base/`
   - 500+ technical documents
   - Standards, technologies, processes, tools
   - 5-level depth (overview → advanced)

3. **API Documentation**: `docs/api/`
   - Agent APIs
   - Skill APIs
   - Tool adapters

### Customize

1. **Create Custom Agent**:
```bash
./scripts/create-agent.sh my-custom-agent
cd agents/my-custom-agent
# Edit agent.yaml and implement logic
```

2. **Add Custom Skill**:
```bash
./scripts/create-skill.sh my-custom-skill
cd skills/my-custom-skill
# Implement skill logic
```

3. **Integrate Custom Tool**:
```bash
# Add tool adapter in tools/
cp tools/template_adapter.py tools/my_tool_adapter.py
# Implement adapter interface
```

## Troubleshooting

### Agent fails to start

```bash
# Check logs
tail -f logs/agents.log

# Verify configuration
./verify.sh
```

### API rate limit

```bash
# Configure rate limiting in .env
AGENT_API_RATE_LIMIT=50  # requests per minute
```

### Out of memory

```bash
# Reduce concurrent agents
AGENT_MAX_CONCURRENT=2

# Or increase system limits
ulimit -v 16384000  # 16GB
```

## Getting Help

- **Documentation**: All docs in `docs/`
- **Examples**: Working code in `examples/`
- **Knowledge Base**: Reference in `knowledge-base/`
- **Issues**: Report bugs on GitHub
- **Community**: Join Discord/Slack (links in README)

## Quick Reference Card

```bash
# Common Commands
./agents/<agent-name>/run.sh <input>    # Run agent
./commands/<command>.sh <args>          # Run command
python -m skills.<skill>.<module>       # Use skill
./tools/kb-search.sh <query>            # Search KB

# Configuration
export ANTHROPIC_API_KEY=<key>          # Set API key
export AGENT_LOG_LEVEL=DEBUG            # Set logging
source .venv/bin/activate               # Activate env

# Maintenance
make test                               # Run tests
make verify                             # Verify install
make clean                              # Clean build
git pull && pip install -r requirements.txt  # Update
```

---

**Congratulations! You're ready to use Automotive Claude Code Agents.**

**Next**: Try the [AUTOSAR SWC Tutorial](../tutorials/autosar-swc-tutorial.md)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Estimated Time**: 5 minutes to first result
