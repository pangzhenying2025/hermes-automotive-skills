#!/usr/bin/env python3
"""
Master Generator for Automotive Claude Code Agents
Generates complete skill and agent library (3,500+ skills, 100+ agents)
"""

import sys
import time
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import generation modules
try:
    from generate_skills import generate_all_skills
    from generate_orchestration_agents import generate_all_orchestration_agents
    from generate_domain_agents import generate_all_domain_agents
except ImportError as e:
    print(f"Error importing generation modules: {e}")
    sys.exit(1)


def print_banner(text: str):
    """Print formatted banner"""
    print("\n" + "=" * 80)
    print(f"  {text}")
    print("=" * 80 + "\n")


def main():
    """Run all generators"""
    print_banner("Automotive Claude Code Agents - Master Generator")
    print("Generating comprehensive skill and agent library...")
    print("Target: 3,500+ skills, 100+ agents\n")

    total_skills = 0
    total_agents = 0
    start_time = time.time()

    # Phase 1: Generate Skills
    print_banner("Phase 1: Generating Automotive Skills")
    try:
        skills_count = generate_all_skills()
        total_skills += skills_count
        print(f"✓ Generated {skills_count} skills")
    except Exception as e:
        print(f"✗ Error generating skills: {e}")
        return 1

    # Phase 2: Generate Orchestration Agents
    print_banner("Phase 2: Generating Orchestration Agents")
    try:
        orchestration_count = generate_all_orchestration_agents()
        total_agents += orchestration_count
        print(f"✓ Generated {orchestration_count} orchestration agents")
    except Exception as e:
        print(f"✗ Error generating orchestration agents: {e}")
        return 1

    # Phase 3: Generate Domain Agents
    print_banner("Phase 3: Generating Domain Perspective Agents")
    try:
        domain_count = generate_all_domain_agents()
        total_agents += domain_count
        print(f"✓ Generated {domain_count} domain agents")
    except Exception as e:
        print(f"✗ Error generating domain agents: {e}")
        return 1

    # Summary
    elapsed_time = time.time() - start_time
    print_banner("Generation Complete")
    print(f"Total Skills Generated:  {total_skills:,}")
    print(f"Total Agents Generated:  {total_agents:,}")
    print(f"Total Artifacts:         {total_skills + total_agents:,}")
    print(f"Time Elapsed:            {elapsed_time:.2f} seconds")
    print(f"Generation Rate:         {(total_skills + total_agents) / elapsed_time:.1f} artifacts/second")

    # Verification
    print_banner("Verification")
    base_dir = Path("/home/rpi/Opensource/automotive-claude-code-agents")

    # Count skills
    skills_dir = base_dir / "skills"
    actual_skills = sum(1 for _ in skills_dir.rglob("*.yaml"))
    print(f"Skills in filesystem:    {actual_skills:,}")

    # Count agents
    agents_dir = base_dir / "agents"
    actual_agents = sum(1 for _ in agents_dir.rglob("*.yaml"))
    print(f"Agents in filesystem:    {actual_agents:,}")

    if actual_skills >= 3500:
        print("\n✓ SUCCESS: Target of 3,500+ skills achieved!")
    else:
        print(f"\n⚠ WARNING: Only {actual_skills} skills generated (target: 3,500+)")

    if actual_agents >= 100:
        print("✓ SUCCESS: Target of 100+ agents achieved!")
    else:
        print(f"⚠ WARNING: Only {actual_agents} agents generated (target: 100+)")

    print("\n" + "=" * 80)
    return 0


if __name__ == "__main__":
    sys.exit(main())
