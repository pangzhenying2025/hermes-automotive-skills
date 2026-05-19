#!/usr/bin/env python3
"""
Orchestration Agents Generator
Creates 40+ orchestration pattern agents for automotive development
"""

import os
import yaml
from pathlib import Path

BASE_DIR = Path("/home/rpi/Opensource/automotive-claude-code-agents")
AGENTS_DIR = BASE_DIR / "agents" / "orchestration"

ORCHESTRATION_PATTERNS = {
    "review-cascade": {
        "description": "Sequential review pattern with multiple validation stages",
        "use_case": "Safety-critical code review with escalating rigor"
    },
    "multi-perspective": {
        "description": "Same problem analyzed from different viewpoints",
        "use_case": "Architecture decisions requiring OEM, supplier, and safety perspectives"
    },
    "hierarchical-decomposition": {
        "description": "Top-down task breakdown into manageable subtasks",
        "use_case": "Large feature development requiring structured decomposition"
    },
    "consensus-builder": {
        "description": "Achieve agreement among experts with different opinions",
        "use_case": "Technical decisions with multiple valid approaches"
    },
    "iterative-refinement": {
        "description": "Successive improvement cycles with feedback",
        "use_case": "Algorithm tuning and calibration optimization"
    },
    "round-robin-review": {
        "description": "Each expert reviews all others' work",
        "use_case": "Comprehensive peer review for high ASIL code"
    },
    "expert-committee": {
        "description": "Panel of experts deliberating together",
        "use_case": "Safety case approval and major architectural decisions"
    },
    "master-apprentice": {
        "description": "Expert guides junior agent through learning",
        "use_case": "Knowledge transfer and skill development"
    },
    "divide-conquer": {
        "description": "Split problem, solve independently, merge results",
        "use_case": "Large codebase refactoring across modules"
    },
    "pipeline-orchestrator": {
        "description": "Sequential stages with handoffs",
        "use_case": "Requirements → Design → Code → Test → Deploy pipeline"
    },
    "fan-out-fan-in": {
        "description": "Broadcast task to multiple agents, collect and merge",
        "use_case": "Multi-variant testing across different ECU configurations"
    },
    "critical-path-optimizer": {
        "description": "Optimize workflow to minimize critical path",
        "use_case": "Release sprint with tight deadline"
    },
    "adaptive-orchestrator": {
        "description": "Adjust strategy based on intermediate results",
        "use_case": "Debugging complex issues with unknown root cause"
    },
    "tournament-selection": {
        "description": "Multiple solutions compete, best wins",
        "use_case": "Algorithm selection for best performance"
    },
    "collaborative-editing": {
        "description": "Multiple agents contribute to same artifact",
        "use_case": "System architecture document co-creation"
    },
    "devil-advocate": {
        "description": "One agent challenges others' assumptions",
        "use_case": "Robust hazard analysis with contrarian viewpoint"
    },
    "specialist-generalist": {
        "description": "Specialists provide depth, generalist provides breadth",
        "use_case": "System integration with deep component expertise"
    },
    "quality-gate-enforcer": {
        "description": "Strict validation at each stage transition",
        "use_case": "ASPICE-compliant development process"
    },
    "dependency-resolver": {
        "description": "Manage complex inter-agent dependencies",
        "use_case": "ECU network development with circular dependencies"
    },
    "resource-allocator": {
        "description": "Optimize agent assignment to tasks",
        "use_case": "Team workload balancing during development"
    },
    "escalation-manager": {
        "description": "Route issues to appropriate authority level",
        "use_case": "Bug triage and severity-based assignment"
    },
    "cross-validator": {
        "description": "Independent verification by different methods",
        "use_case": "Model-in-loop vs hardware-in-loop comparison"
    },
    "progressive-enhancement": {
        "description": "Start simple, add complexity incrementally",
        "use_case": "Prototype → MVP → Full featured system"
    },
    "fallback-handler": {
        "description": "Primary approach with backup strategies",
        "use_case": "Sensor fusion with graceful degradation"
    },
    "meta-orchestrator": {
        "description": "Orchestrates other orchestrators",
        "use_case": "Complete vehicle program management"
    },
    "swarm-intelligence": {
        "description": "Emergent behavior from simple agent interactions",
        "use_case": "Distributed testing across test fleet"
    },
    "auction-based": {
        "description": "Agents bid for tasks based on capability",
        "use_case": "Dynamic work allocation in large team"
    },
    "voting-ensemble": {
        "description": "Multiple agents vote on best solution",
        "use_case": "Fault-tolerant decision making"
    },
    "time-boxed": {
        "description": "Fixed time allocation with best-effort output",
        "use_case": "Rapid prototyping under time pressure"
    },
    "cost-optimizer": {
        "description": "Minimize resource usage while meeting requirements",
        "use_case": "ECU hardware selection and optimization"
    },
    "risk-based-prioritizer": {
        "description": "Prioritize work by risk and impact",
        "use_case": "Safety requirement implementation order"
    },
    "continuous-integrator": {
        "description": "Ongoing integration of incremental changes",
        "use_case": "CI/CD pipeline for ECU software"
    },
    "knowledge-synthesizer": {
        "description": "Combine insights from multiple knowledge sources",
        "use_case": "Lessons learned database analysis"
    },
    "simulation-validator": {
        "description": "Run multiple simulation scenarios in parallel",
        "use_case": "ADAS validation across edge cases"
    },
    "test-generator": {
        "description": "Generate comprehensive test suites",
        "use_case": "Requirements-based test case generation"
    },
    "compliance-auditor": {
        "description": "Verify adherence to standards and regulations",
        "use_case": "ISO 26262 compliance audit"
    },
    "change-propagator": {
        "description": "Track and propagate requirement changes",
        "use_case": "Impact analysis for requirement modifications"
    },
    "version-reconciler": {
        "description": "Manage multi-version compatibility",
        "use_case": "Software variants for different vehicle models"
    },
    "performance-tuner": {
        "description": "Optimize system for performance metrics",
        "use_case": "ECU CPU and memory optimization"
    },
    "documentation-weaver": {
        "description": "Generate comprehensive documentation from artifacts",
        "use_case": "Automated technical documentation generation"
    }
}


def create_orchestration_agent(pattern_name: str, pattern_info: dict) -> dict:
    """Generate orchestration agent definition"""

    return {
        "name": pattern_name,
        "version": "1.0.0",
        "type": "orchestrator",
        "domain": "automotive",
        "role": "workflow-coordinator",
        "description": pattern_info["description"],
        "expertise": [
            "Multi-agent coordination",
            "Workflow optimization",
            "Automotive processes",
            "Standards compliance"
        ],
        "responsibilities": [
            f"Implement {pattern_name.replace('-', ' ')} pattern",
            "Coordinate agent interactions",
            "Monitor workflow progress",
            "Ensure quality and compliance"
        ],
        "automotive_context": {
            "oem_tier": "OEM|Tier1",
            "lifecycle_phase": "Development|Validation",
            "standards_compliance": [
                "ISO 26262",
                "ASPICE",
                "AUTOSAR"
            ]
        },
        "system_prompt": f"""
You are a {pattern_name.replace('-', ' ').title()} Orchestrator for automotive development.

## Pattern Purpose

{pattern_info['description']}

## Primary Use Case

{pattern_info['use_case']}

## Orchestration Approach

1. Analyze incoming task requirements
2. Apply {pattern_name} pattern strategy
3. Coordinate agent interactions per pattern
4. Monitor and adjust execution
5. Synthesize and deliver results

## Automotive Context

- Follow ISO 26262 functional safety requirements
- Ensure ASPICE process compliance
- Maintain AUTOSAR architectural consistency
- Track requirements traceability

## Quality Standards

- All deliverables must meet automotive quality standards
- Safety-critical components require ASIL-appropriate rigor
- Documentation per ASPICE work product guidelines
- Code follows MISRA C/C++ rules

## Deliverables

- Orchestrated workflow results
- Coordination logs and decisions
- Quality metrics and reports
- Compliance evidence
""",
        "skills": [
            {"skill": "workflow-management", "proficiency": "expert"},
            {"skill": "agent-coordination", "proficiency": "expert"},
            {"skill": "automotive-processes", "proficiency": "advanced"}
        ],
        "tools": {
            "required": ["Agent framework", "Workflow engine"],
            "optional": ["Monitoring dashboard", "Metrics collector"]
        },
        "workflows": [
            {
                "name": f"{pattern_name} execution",
                "trigger": f"Task requiring {pattern_name} pattern",
                "steps": [
                    {
                        "step": "Initialize",
                        "actions": ["Parse requirements", "Identify agents", "Setup workflow"]
                    },
                    {
                        "step": "Execute pattern",
                        "actions": ["Apply coordination logic", "Monitor execution", "Handle issues"]
                    },
                    {
                        "step": "Synthesize results",
                        "actions": ["Collect outputs", "Integrate results", "Validate quality"]
                    }
                ]
            }
        ],
        "performance_metrics": [
            {"metric": "Task completion time", "target": "< pattern-specific SLA"},
            {"metric": "Quality score", "target": "> 90%"},
            {"metric": "Resource efficiency", "target": "> 80%"}
        ],
        "metadata": {
            "author": "Automotive Claude Code Agents",
            "created": "2026-03-19",
            "status": "production",
            "priority": "high"
        },
        "tags": [
            "orchestration",
            pattern_name,
            "automotive",
            "workflow"
        ]
    }


def generate_all_orchestration_agents():
    """Generate all orchestration pattern agents"""
    AGENTS_DIR.mkdir(parents=True, exist_ok=True)

    count = 0
    for pattern_name, pattern_info in ORCHESTRATION_PATTERNS.items():
        agent = create_orchestration_agent(pattern_name, pattern_info)

        filename = AGENTS_DIR / f"{pattern_name}.yaml"
        with open(filename, 'w') as f:
            yaml.dump(agent, f, default_flow_style=False, sort_keys=False)

        count += 1
        print(f"Created: {pattern_name}")

    print(f"\nGenerated {count} orchestration agents")
    return count


if __name__ == "__main__":
    count = generate_all_orchestration_agents()
    print(f"Successfully created {count} orchestration pattern agents")
