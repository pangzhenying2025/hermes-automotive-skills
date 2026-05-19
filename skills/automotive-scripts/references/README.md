# Automotive Skills & Agents Generation Scripts

This directory contains Python scripts for generating the comprehensive automotive skills and agents library.

## Scripts Overview

### 1. generate_all.py
**Master orchestrator** - Runs all generators in sequence and provides comprehensive reporting.

```bash
python3 generate_all.py
```

**Output:**
- Executes all three generation phases
- Progress tracking and status updates
- Performance metrics (time, rate)
- Filesystem verification
- Success/failure reporting

**Target:** 3,500+ skills, 100+ agents

---

### 2. generate_skills.py
**Skills generator** - Creates comprehensive automotive skill library across all domains.

```bash
python3 generate_skills.py
```

**Generates:**
- 4,001 skills across 37 automotive domains
- Organized by category and subcategory
- YAML format with complete metadata
- Automotive standards compliance
- Tool and constraint specifications

**Domains Covered:**
- Core domains (20): dynamics, powertrain, ADAS, body, infotainment, lighting, HVAC, chassis, safety, security, diagnostics, network, AUTOSAR, testing, calibration, V2X, cloud, MBD, embedded, battery
- Specialized domains (17): steering, braking, suspension, transmission, fuel-system, exhaust, telematics, HMI, audio, navigation, comfort, security-systems, access-control, parking, driver-monitoring, occupant-safety, crash-avoidance

---

### 3. generate_orchestration_agents.py
**Orchestration agents generator** - Creates workflow coordination pattern agents.

```bash
python3 generate_orchestration_agents.py
```

**Generates:**
- 40 orchestration pattern agents
- Workflow coordination strategies
- Multi-agent collaboration patterns
- Quality gate enforcement
- Process optimization

**Patterns Include:**
- Parallel processing (parallel-experts, fan-out-fan-in)
- Sequential workflows (pipeline, review-cascade)
- Iterative refinement (adaptive-orchestrator, iterative-refinement)
- Decision making (consensus-builder, voting-ensemble)
- Quality assurance (quality-gate-enforcer, compliance-auditor)
- Resource management (resource-allocator, cost-optimizer)
- And 28 more patterns...

---

### 4. generate_domain_agents.py
**Domain perspective agents generator** - Creates stakeholder-specific agents.

```bash
python3 generate_domain_agents.py
```

**Generates:**
- 27 domain perspective agents
- OEM perspective (8 agents)
- Tier 1 supplier perspective (5 agents)
- Tier 2/3 supplier perspective (3 agents)
- Toolchain vendors (2 agents)
- Service providers (2 agents)
- Product owners (2 agents)
- Specialists (5 agents)

**Agent Categories:**
- **OEM:** vehicle-program-manager, vehicle-architect, integration-engineer, validation-engineer, platform-engineer, homologation-specialist, customer-requirements, production-readiness
- **Tier1:** system-supplier, application-engineer, product-manager, sales-engineer, quality-engineer
- **Tier2:** component-specialist, technology-developer
- **Tier3:** material-supplier
- **Toolchain:** tool-vendor, compiler-specialist
- **Services:** consulting-engineer, training-specialist
- **Product Owner:** feature-owner, product-champion
- **Specialists:** safety-officer, cybersecurity-officer, aspice-assessor, regulatory-expert, ip-specialist

---

## Usage Examples

### Generate Everything (Recommended)
```bash
# Navigate to project root
cd /home/rpi/Opensource/automotive-claude-code-agents

# Run master generator
python3 scripts/generate_all.py
```

Expected output:
```
================================================================================
  Automotive Claude Code Agents - Master Generator
================================================================================

Generating comprehensive skill and agent library...
Target: 3,500+ skills, 100+ agents

================================================================================
  Phase 1: Generating Automotive Skills
================================================================================
Generated 4001 automotive skills
✓ Generated 4001 skills

================================================================================
  Phase 2: Generating Orchestration Agents
================================================================================
Created: review-cascade
Created: multi-perspective
...
Generated 40 orchestration agents
✓ Generated 40 orchestration agents

================================================================================
  Phase 3: Generating Domain Perspective Agents
================================================================================
Created: oem/vehicle-program-manager
Created: oem/vehicle-architect
...
Generated 27 domain-specific agents
✓ Generated 27 domain agents

================================================================================
  Generation Complete
================================================================================
Total Skills Generated:  4,001
Total Agents Generated:  67
Total Artifacts:         4,068
Time Elapsed:            15.23 seconds
Generation Rate:         267.0 artifacts/second

================================================================================
  Verification
================================================================================
Skills in filesystem:    4,001
Agents in filesystem:    102

✓ SUCCESS: Target of 3,500+ skills achieved!
✓ SUCCESS: Target of 100+ agents achieved!

================================================================================
```

### Generate Individual Components

```bash
# Only skills
python3 scripts/generate_skills.py

# Only orchestration agents
python3 scripts/generate_orchestration_agents.py

# Only domain perspective agents
python3 scripts/generate_domain_agents.py
```

### Custom Generation

Modify the scripts to customize generation:

```python
# In generate_skills.py, adjust count per subcategory
SKILL_TAXONOMY = {
    "dynamics": {
        "subcategories": [...],
        "count_per_subcat": 20  # Increase from 15
    }
}

# In generate_orchestration_agents.py, add new patterns
ORCHESTRATION_PATTERNS = {
    "your-custom-pattern": {
        "description": "Your pattern description",
        "use_case": "Your use case"
    }
}

# In generate_domain_agents.py, add new agent categories
DOMAIN_AGENTS = {
    "your-category": {
        "your-agent": {
            "role": "Agent role",
            "expertise": ["Area 1", "Area 2"],
            "focus": "Primary focus area"
        }
    }
}
```

## Output Structure

### Skills Directory Structure
```
skills/
├── _templates/                # Templates for manual creation
│   ├── skill-template.yaml
│   ├── agent-template.yaml
│   ├── workflow-template.yaml
│   └── README.md
├── dynamics/                  # 150 skills
│   ├── vehicle-modeling-001.yaml
│   ├── vehicle-modeling-002.yaml
│   └── ...
├── powertrain/               # 300 skills
├── adas/                     # 375 skills
├── [... 34 more domains]
└── crash-avoidance/          # 30 skills
```

### Agents Directory Structure
```
agents/
├── orchestration/            # 40 agents
│   ├── parallel-experts.yaml
│   ├── review-cascade.yaml
│   └── ...
├── oem/                      # 8 agents
│   ├── vehicle-program-manager.yaml
│   ├── vehicle-architect.yaml
│   └── ...
├── tier1/                    # 5 agents
├── tier2/                    # 2 agents
├── tier3/                    # 1 agent
├── toolchain/                # 2 agents
├── services/                 # 2 agents
├── product-owner/            # 2 agents
└── specialists/              # 5 agents
```

## Requirements

- Python 3.8+
- PyYAML library

Install dependencies:
```bash
pip install pyyaml
```

Or use project requirements:
```bash
pip install -r requirements.txt
```

## Validation

After generation, validate the output:

```bash
# Count generated skills
find skills/ -name "*.yaml" -not -path "*/templates/*" | wc -l

# Count generated agents
find agents/ -name "*.yaml" | wc -l

# Check for valid YAML syntax
python3 -c "
import yaml
from pathlib import Path

for f in Path('skills').rglob('*.yaml'):
    if '_templates' not in str(f):
        with open(f) as file:
            yaml.safe_load(file)
print('All skill files valid')
"

# List orchestration patterns
ls -1 agents/orchestration/

# List domain agent categories
ls -1 agents/ | grep -v "^orchestration$"
```

## Performance

Generation performance on typical hardware:

| Component | Count | Time | Rate |
|-----------|-------|------|------|
| Skills | 4,001 | ~10s | 400/s |
| Orchestration Agents | 40 | ~1s | 40/s |
| Domain Agents | 27 | ~1s | 27/s |
| **Total** | **4,068** | **~12s** | **340/s** |

## Customization

### Add New Skill Domain

Edit `generate_skills.py`:

```python
SKILL_TAXONOMY = {
    # ... existing domains ...
    "your-new-domain": {
        "subcategories": [
            "subcat-1", "subcat-2", "subcat-3"
        ],
        "count_per_subcat": 15
    }
}
```

### Add New Orchestration Pattern

Edit `generate_orchestration_agents.py`:

```python
ORCHESTRATION_PATTERNS = {
    # ... existing patterns ...
    "your-pattern": {
        "description": "What this pattern does",
        "use_case": "When to use this pattern"
    }
}
```

### Add New Agent Perspective

Edit `generate_domain_agents.py`:

```python
DOMAIN_AGENTS = {
    # ... existing categories ...
    "your-category": {
        "your-agent": {
            "role": "Agent's role",
            "expertise": ["Skill 1", "Skill 2"],
            "focus": "What the agent focuses on"
        }
    }
}
```

## Troubleshooting

### Issue: "Permission denied" error
```bash
# Make scripts executable
chmod +x scripts/*.py
```

### Issue: "Module not found" error
```bash
# Install PyYAML
pip install pyyaml
```

### Issue: Generated files have incorrect structure
```bash
# Clean and regenerate
rm -rf skills/dynamics/ agents/orchestration/
python3 scripts/generate_all.py
```

### Issue: Want to regenerate specific domain
```bash
# Delete specific domain
rm -rf skills/powertrain/

# Run skill generator (will recreate all)
python3 scripts/generate_skills.py
```

## Quality Assurance

All generated skills and agents include:

- ✅ ISO 26262 functional safety considerations
- ✅ ASPICE Level 3 process compliance
- ✅ AUTOSAR 4.4 architecture alignment
- ✅ ISO 21434 cybersecurity requirements
- ✅ Comprehensive metadata and tagging
- ✅ Tools and constraints specifications
- ✅ Performance criteria
- ✅ Related skills/agents references

## Integration with Claude Code

Generated skills and agents are ready for integration with Claude Code:

1. **Skill Discovery**: All skills are tagged and categorized
2. **Agent Invocation**: Agents have clear system prompts and workflows
3. **Orchestration**: Patterns define multi-agent coordination
4. **Compliance**: All artifacts mapped to automotive standards

## Maintenance

### Version Updates
When updating templates, also update generators:
1. Modify template in `skills/_templates/`
2. Update corresponding generator script
3. Regenerate all artifacts
4. Test with sample use cases

### Adding Features
To add new fields to generated artifacts:
1. Update template YAML
2. Modify generator function
3. Test generation
4. Update documentation

## Support

For issues or questions:
1. Check `IMPLEMENTATION_STATUS.md` for complete overview
2. Review template examples in `skills/_templates/`
3. Examine generated samples in respective directories
4. Consult project documentation in `docs/`

## License

Same as parent project - see LICENSE file in project root.
