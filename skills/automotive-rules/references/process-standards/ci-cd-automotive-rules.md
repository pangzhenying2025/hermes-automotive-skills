# CI/CD Pipeline Rules for Automotive Software

> Rules for building, testing, and deploying automotive software through
> continuous integration and delivery pipelines, balancing rapid feedback
> with safety assurance and regulatory compliance.

## Scope

These rules apply to all CI/CD pipelines processing automotive software,
from ECU firmware builds through cloud backend deployments, including
build systems, test automation, artifact management, and release processes.

---

## Pipeline Architecture

### Standard Pipeline Stages

```
+--------+   +--------+   +---------+   +--------+   +--------+
| Build  |-->| Test   |-->| Analyze |-->| Package|-->| Deploy |
+--------+   +--------+   +---------+   +--------+   +--------+
    |            |             |            |            |
    v            v             v            v            v
 Compile     Unit Test    MISRA Check   Sign FW      Staging
 Link        Integ Test   Coverage      Version      Release
 Generate    SIL Test     Dependency    Archive      OTA Push
```

### Pipeline Configuration

```yaml
# Multi-stage automotive CI pipeline
pipeline:
  name: "BMS Firmware CI/CD"
  trigger:
    branches: [develop, release/*, hotfix/*]
    merge_requests: true
    tags: ["v*"]

  variables:
    SDK_PATH: "/opt/automotive-sdk"
    MISRA_CONFIG: "configs/misra-c-2012.cfg"
    COVERAGE_THRESHOLD: 80
    ARTIFACT_RETENTION_DAYS: 365

  stages:
    - name: build
      parallel:
        - build_debug
        - build_release
        - build_coverage

    - name: test
      parallel:
        - unit_tests
        - integration_tests
        - sil_tests

    - name: analyze
      parallel:
        - misra_check
        - coverage_report
        - dependency_audit
        - complexity_check

    - name: package
      depends_on: [test, analyze]
      jobs: [sign_firmware, create_artifact]

    - name: deploy
      depends_on: [package]
      manual_approval: true  # Requires human approval
      jobs: [deploy_to_hil, deploy_to_staging]
```

---

## Build Rules

### Reproducible Builds

```yaml
build_requirements:
  deterministic:
    - "Same source + same toolchain = identical binary (bit-for-bit)"
    - "Record all build inputs: source hash, toolchain version, SDK version"
    - "No timestamps embedded in binary (use build ID instead)"
    - "Pin all dependency versions (no floating/latest references)"

  toolchain_management:
    compiler: "GCC 12.3.0 (cross-compiler for target architecture)"
    sdk: "Yocto SDK v4.0.12 (locked to specific commit)"
    cmake: "3.25.2"
    container: "registry.example.com/automotive-build:v2.4.0"

  build_metadata:
    - git_commit_hash
    - git_branch
    - build_number
    - compiler_version
    - sdk_version
    - build_timestamp_utc
    - builder_container_digest
```

### Build Artifact Management

```yaml
artifact_management:
  naming_convention: >
    {project}-{variant}-{version}-{build_number}-{git_short_hash}.{ext}
    Example: bms-fw-release-v2.4.0-b1234-abc1234.bin

  storage:
    type: "Artifactory / Nexus"
    retention:
      release_builds: "Permanent (lifetime of vehicle)"
      rc_builds: "1 year"
      development_builds: "90 days"
      pr_builds: "30 days"

  traceability:
    - "Every artifact linked to source commit"
    - "Every artifact linked to build log"
    - "Every artifact linked to test results"
    - "Build manifest (SBOM) generated for each artifact"
```

---

## Test Execution Rules

### Test Stage Requirements

```yaml
unit_test_stage:
  execution: "Every commit and PR"
  max_duration: "10 minutes"
  environment: "Docker container on CI runner"
  pass_criteria:
    - "All tests pass (0 failures)"
    - "No new test warnings"
    - "Execution time within 2x historical average"
  failure_action: "Block merge, notify author"

integration_test_stage:
  execution: "Every PR and develop branch"
  max_duration: "30 minutes"
  environment: "Docker compose with service dependencies"
  pass_criteria:
    - "All tests pass"
    - "No flaky test failures (retry once before failing)"
  failure_action: "Block merge, notify author and team lead"

sil_test_stage:
  execution: "Every PR for safety-critical modules"
  max_duration: "60 minutes"
  environment: "SIL simulation environment"
  pass_criteria:
    - "All back-to-back tests within tolerance"
    - "All safety requirement tests pass"
  failure_action: "Block merge, notify safety team"
```

### Flaky Test Management

```yaml
flaky_test_policy:
  detection:
    method: "Track pass/fail history per test over last 100 runs"
    threshold: "Test is flaky if fail rate > 0 but < 100%"

  quarantine:
    trigger: "2 inconsistent results in 7 days"
    action: "Move to quarantine suite, create ticket"
    max_quarantine_days: 14
    escalation: "If not fixed in 14 days, escalate to tech lead"

  prevention:
    - "No sleep-based synchronization in tests"
    - "No external service dependencies in unit tests"
    - "All tests must pass when run in isolation"
    - "All tests must pass when run in any order"
    - "Use deterministic time sources in tests"
```

---

## Static Analysis

### MISRA Compliance Check

```yaml
misra_check:
  tool: "cppcheck / Polyspace / QAC"
  standard: "MISRA C:2012 (with Amendment 2)"
  mandatory_rules: "All mandatory and required rules"
  advisory_rules: "Project-specific subset (documented)"

  execution:
    when: "Every PR"
    scope: "Changed files + dependent headers"
    full_scan: "Weekly on develop branch"

  pass_criteria:
    - "Zero mandatory rule violations"
    - "Zero required rule violations (unless deviated)"
    - "All deviations pre-approved and documented"

  deviation_process:
    - "Developer requests deviation with justification"
    - "Safety engineer reviews and approves/rejects"
    - "Approved deviations recorded in deviation database"
    - "Deviations reviewed at each MISRA full scan"
```

### Complexity Metrics

```yaml
complexity_gate:
  metrics:
    cyclomatic_complexity:
      max_per_function: 15
      max_per_module: 50
      action_on_exceed: "Block merge + require refactoring"

    function_length:
      max_lines: 50
      action_on_exceed: "Warning (block at 75 lines)"

    file_length:
      max_lines: 500
      action_on_exceed: "Warning (block at 750 lines)"

    nesting_depth:
      max_levels: 4
      action_on_exceed: "Block merge"

    parameter_count:
      max_per_function: 6
      action_on_exceed: "Warning"
```

---

## Security in CI/CD

### Pipeline Security

```yaml
pipeline_security:
  secrets_management:
    - "No secrets in pipeline YAML files"
    - "Use CI/CD platform secret variables"
    - "Rotate CI tokens quarterly"
    - "Signing keys accessed via HSM integration"

  supply_chain:
    - "Pin all container image digests (not tags)"
    - "Verify container image signatures"
    - "Scan dependencies for known CVEs"
    - "Generate SBOM for every build"

  access_control:
    - "Pipeline definitions require PR review"
    - "Production deploy requires manual approval"
    - "Audit log of all pipeline modifications"
    - "Separate CI credentials from developer credentials"
```

### Dependency Scanning

```yaml
dependency_audit:
  tools:
    c_cpp: "cppcheck + custom CVE scanner"
    python: "pip-audit + safety"
    java: "OWASP Dependency-Check"
    npm: "npm audit"

  execution: "Every PR and daily on develop"

  policy:
    critical_cve: "Block merge immediately"
    high_cve: "Block merge, 48-hour grace if no fix available"
    medium_cve: "Warning, must resolve within 30 days"
    low_cve: "Track in backlog"
```

---

## Release Process

### Release Pipeline

```yaml
release_pipeline:
  trigger: "Git tag matching v*.*.* on release/* branch"

  steps:
    1_build:
      action: "Build release variant with optimization"
      output: "Firmware binary + debug symbols"

    2_test:
      action: "Run full regression suite"
      scope: "Unit + Integration + SIL + HIL (if available)"
      pass_required: true

    3_analyze:
      action: "Full MISRA scan + coverage report"
      pass_required: true

    4_sign:
      action: "Sign firmware with production key (HSM)"
      approval: "Two authorized signers"
      audit: "Signing event logged"

    5_package:
      action: "Create release package with metadata"
      contents:
        - "Signed firmware binary"
        - "Debug symbols (separate)"
        - "SBOM (Software Bill of Materials)"
        - "Test results summary"
        - "Coverage report"
        - "MISRA compliance report"
        - "Release notes"

    6_publish:
      action: "Publish to release artifact repository"
      retention: "Permanent"
      notification: "Release team, safety team, project manager"

    7_deploy:
      action: "Deploy to OTA staging"
      approval: "Release manager"
      monitoring: "Post-deploy smoke tests"
```

### Version Management

```yaml
versioning:
  scheme: "Semantic Versioning (MAJOR.MINOR.PATCH)"
  rules:
    major: "Breaking changes, ASIL-impacting modifications"
    minor: "New features, non-breaking additions"
    patch: "Bug fixes, safety corrections"

  branch_strategy:
    develop: "Next release integration"
    release: "Release candidate stabilization"
    main: "Production releases only"
    hotfix: "Emergency production fixes"

  tagging:
    format: "v{MAJOR}.{MINOR}.{PATCH}"
    signed: true  # GPG-signed tags
    annotated: true  # Include release notes in tag
```

---

## Audit and Compliance

### Pipeline Audit Trail

```yaml
audit_requirements:
  logged_events:
    - "Pipeline start/stop with trigger source"
    - "Build inputs (commit, branch, dependencies)"
    - "Test results with pass/fail counts"
    - "Static analysis findings"
    - "Coverage metrics"
    - "Signing operations"
    - "Deployment approvals and executors"
    - "Pipeline configuration changes"

  retention: "Life of vehicle + 10 years"
  format: "Structured JSON logs in append-only storage"
  tamper_protection: "Log integrity via hash chain"
```

---

## Review Checklist

- [ ] Pipeline builds are reproducible (deterministic)
- [ ] Toolchain versions pinned in container image
- [ ] Unit tests run on every commit
- [ ] Integration tests gate PR merges
- [ ] MISRA compliance checked on every PR
- [ ] Coverage thresholds enforced as gates
- [ ] Dependencies scanned for CVEs
- [ ] Secrets managed via platform variables (not in code)
- [ ] Release builds signed with HSM-protected keys
- [ ] Audit trail captures all pipeline events
- [ ] Flaky tests quarantined and tracked
- [ ] Release packages include SBOM and compliance artifacts
