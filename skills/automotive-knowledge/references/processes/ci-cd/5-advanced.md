# CI/CD for Automotive Software - Level 5: Advanced Topics

> Audience: CI/CD architects and DevOps engineers pushing pipeline boundaries
> Purpose: Advanced patterns for automotive CI/CD at scale

## Pipeline as Code Patterns

### Dynamic Pipeline Generation

For large automotive platforms with hundreds of ECU software components,
static pipeline definitions become unmanageable. Dynamic generation solves this:

```python
#!/usr/bin/env python3
"""Generate CI pipeline stages from component manifest."""

import json
import yaml
from pathlib import Path
from typing import Any


def load_component_manifest(path: str) -> dict[str, Any]:
    """Load component definitions with ASIL levels and dependencies."""
    with open(path) as f:
        return yaml.safe_load(f)


def generate_pipeline(manifest: dict) -> dict:
    """Generate GitLab CI pipeline from component manifest."""
    pipeline: dict[str, Any] = {
        'stages': ['build', 'analyze', 'test', 'integration', 'package'],
        'variables': {
            'TOOLCHAIN_IMAGE': manifest['toolchain']['image'],
        }
    }

    for name, comp in manifest['components'].items():
        asil = comp.get('asil', 'QM')
        coverage_min = {'QM': 60, 'A': 70, 'B': 80, 'C': 90, 'D': 95}[asil]

        # Build job
        pipeline[f'build:{name}'] = {
            'stage': 'build',
            'image': manifest['toolchain']['image'],
            'script': [
                f'cd {comp["path"]}',
                'mkdir -p build && cd build',
                f'cmake .. -DCMAKE_TOOLCHAIN_FILE={comp.get("toolchain", "default")}.cmake',
                'make -j$(nproc)',
            ],
            'artifacts': {'paths': [f'{comp["path"]}/build/']},
        }

        # Test job with ASIL-appropriate coverage
        pipeline[f'test:{name}'] = {
            'stage': 'test',
            'needs': [f'build:{name}'],
            'script': [
                f'cd {comp["path"]}/build',
                'ctest --output-on-failure',
                f'gcovr --fail-under-line {coverage_min}',
            ],
        }

        # MISRA analysis for safety-critical components
        if asil != 'QM':
            pipeline[f'misra:{name}'] = {
                'stage': 'analyze',
                'needs': [f'build:{name}'],
                'script': [
                    f'cppcheck --addon=misra.json {comp["path"]}/src/',
                ],
            }

    return pipeline


if __name__ == '__main__':
    manifest = load_component_manifest('components.yml')
    pipeline = generate_pipeline(manifest)
    print(yaml.dump(pipeline, default_flow_style=False))
```

### Component Manifest

```yaml
# components.yml - defines all software components and their properties
toolchain:
  image: automotive-sdk:2024.1

components:
  battery-manager:
    path: services/battery-manager
    asil: D
    toolchain: aarch64-poky-linux
    dependencies: [protobuf, zmq]
    hil_required: true

  telemetry-gateway:
    path: services/telemetry-gateway
    asil: QM
    toolchain: aarch64-poky-linux
    dependencies: [mqtt, protobuf]
    hil_required: false

  motor-controller:
    path: services/motor-controller
    asil: C
    toolchain: arm-none-eabi
    dependencies: [hal, rtos]
    hil_required: true
```

## Incremental Analysis

### Changed-File-Only Analysis

For large codebases, analyzing everything on every commit is impractical:

```bash
#!/bin/bash
# Run static analysis only on changed files
set -euo pipefail

BASE_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-develop}"
CHANGED_FILES=$(git diff --name-only "origin/${BASE_BRANCH}...HEAD" -- '*.c' '*.h')

if [ -z "${CHANGED_FILES}" ]; then
    echo "No C/C++ files changed, skipping analysis"
    exit 0
fi

echo "Analyzing changed files:"
echo "${CHANGED_FILES}"

# Run MISRA on changed files only
echo "${CHANGED_FILES}" | xargs cppcheck --enable=all --std=c11 \
    --addon=misra.json --xml --xml-version=2 2> misra-incremental.xml

# Run complexity on changed files only
echo "${CHANGED_FILES}" | xargs lizard --CCN 15 --length 50

# But always run full analysis on release branches
if [[ "${CI_COMMIT_BRANCH}" == release/* ]]; then
    echo "Release branch: running full analysis"
    cppcheck --enable=all --std=c11 --addon=misra.json src/ 2> misra-full.xml
fi
```

## HIL Farm Orchestration

### Distributed HIL Test Scheduling

```python
"""HIL test farm scheduler for parallel ECU testing."""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import asyncio
import aiohttp


class BenchStatus(Enum):
    AVAILABLE = "available"
    BUSY = "busy"
    MAINTENANCE = "maintenance"


@dataclass
class HilBench:
    bench_id: str
    ecu_type: str
    status: BenchStatus
    ip_address: str
    current_job: Optional[str] = None


@dataclass
class HilTestJob:
    job_id: str
    ecu_type: str
    binary_path: str
    test_suite: str
    priority: int = 0
    timeout_minutes: int = 60


class HilFarmScheduler:
    def __init__(self) -> None:
        self.benches: list[HilBench] = []
        self.job_queue: list[HilTestJob] = []

    def register_bench(self, bench: HilBench) -> None:
        self.benches.append(bench)

    def submit_job(self, job: HilTestJob) -> None:
        self.job_queue.append(job)
        self.job_queue.sort(key=lambda j: j.priority, reverse=True)

    def find_available_bench(self, ecu_type: str) -> Optional[HilBench]:
        for bench in self.benches:
            if bench.ecu_type == ecu_type and bench.status == BenchStatus.AVAILABLE:
                return bench
        return None

    async def execute_job(self, bench: HilBench, job: HilTestJob) -> dict:
        bench.status = BenchStatus.BUSY
        bench.current_job = job.job_id

        try:
            async with aiohttp.ClientSession() as session:
                # Flash ECU
                await session.post(f"http://{bench.ip_address}/flash",
                                   json={"binary": job.binary_path})

                # Run tests
                resp = await session.post(
                    f"http://{bench.ip_address}/test",
                    json={"suite": job.test_suite,
                           "timeout": job.timeout_minutes},
                    timeout=aiohttp.ClientTimeout(
                        total=job.timeout_minutes * 60))
                return await resp.json()
        finally:
            bench.status = BenchStatus.AVAILABLE
            bench.current_job = None

    async def schedule(self) -> None:
        while self.job_queue:
            job = self.job_queue[0]
            bench = self.find_available_bench(job.ecu_type)
            if bench:
                self.job_queue.pop(0)
                asyncio.create_task(self.execute_job(bench, job))
            else:
                await asyncio.sleep(10)
```

## Build Cache Optimization

### Distributed Build Cache

```yaml
# Gradle-style build cache for CMake projects
# sstate-cache configuration (Yocto pattern adapted for CI)

cache:
  strategy:
    # Level 1: Local build directory cache
    local:
      path: ${CI_PROJECT_DIR}/.build-cache
      max_size: 2GB

    # Level 2: Shared runner cache
    runner:
      type: s3
      bucket: ci-build-cache
      prefix: ${CI_PROJECT_NAME}
      max_age: 7d

    # Level 3: Cross-project shared objects
    shared:
      type: s3
      bucket: ci-shared-cache
      prefix: sstate
      max_age: 30d

  # Cache key based on compiler + flags + dependency versions
  key_components:
    - compiler_version
    - cmake_flags_hash
    - dependency_lock_hash
```

## Compliance Evidence Generation

### Automated ISO 26262 Work Products

```python
"""Generate ISO 26262 compliance evidence from CI pipeline data."""

from dataclasses import dataclass
from datetime import datetime
import json


@dataclass
class ComplianceEvidence:
    work_product_id: str
    title: str
    asil: str
    pipeline_run: str
    timestamp: str
    artifacts: list[dict]
    status: str


def generate_test_evidence(pipeline_data: dict) -> ComplianceEvidence:
    """Generate ISO 26262 Part 6 test evidence."""
    return ComplianceEvidence(
        work_product_id="WP-06-09",
        title="Software Unit Test Report",
        asil=pipeline_data.get("asil", "B"),
        pipeline_run=pipeline_data["pipeline_id"],
        timestamp=datetime.utcnow().isoformat(),
        artifacts=[
            {
                "type": "unit_test_results",
                "format": "JUnit XML",
                "path": pipeline_data["test_results_path"],
                "total": pipeline_data["tests_total"],
                "passed": pipeline_data["tests_passed"],
                "failed": pipeline_data["tests_failed"],
            },
            {
                "type": "coverage_report",
                "format": "Cobertura XML",
                "path": pipeline_data["coverage_path"],
                "line_coverage": pipeline_data["line_coverage"],
                "branch_coverage": pipeline_data["branch_coverage"],
                "mcdc_coverage": pipeline_data.get("mcdc_coverage"),
            },
            {
                "type": "static_analysis",
                "format": "cppcheck XML",
                "path": pipeline_data["misra_report_path"],
                "violations": pipeline_data["misra_violations"],
                "deviations": pipeline_data["misra_deviations"],
            },
        ],
        status="PASS" if pipeline_data["tests_failed"] == 0 else "FAIL",
    )
```

## Canary Deployments for Vehicle Software

### Phased OTA Rollout Pipeline

```
Stage 1: Internal test fleet (10 vehicles)
  - Duration: 48 hours
  - Success criteria: 0 critical errors, <2 warnings
  |
  v (auto-promote if criteria met)
Stage 2: Early adopter fleet (100 vehicles)
  - Duration: 1 week
  - Success criteria: 0 critical, <5 non-critical
  - Automatic rollback if error rate > 0.1%
  |
  v (manual approval required)
Stage 3: Regional rollout (1,000 vehicles)
  - Duration: 2 weeks
  - Success criteria: same as stage 2
  |
  v (manual approval required)
Stage 4: Full fleet deployment
  - Staggered: 10% per day
  - Continuous monitoring for 30 days
```

## Future Directions

- **AI-assisted code review**: LLM models trained on automotive coding standards
  to provide review feedback in CI pipeline
- **Predictive test selection**: ML models predict which tests are most likely
  to fail based on code changes, reducing test time by 60-80%
- **Self-healing pipelines**: Automatic detection and resolution of transient
  CI failures (flaky tests, infrastructure issues)
- **Digital twin CI**: Run integration tests against digital twin of vehicle
  electronics, eliminating HIL hardware bottlenecks
- **Shift-left security**: SAST/DAST integrated at pre-commit with
  automotive-specific vulnerability databases

## Summary

Advanced automotive CI/CD scales through dynamic pipeline generation from
component manifests, incremental analysis on changed files, distributed HIL
farm orchestration, and build cache optimization. Compliance evidence
generation automates ISO 26262 work product creation. Canary deployment
patterns enable safe fleet-wide OTA rollouts with automatic rollback.
