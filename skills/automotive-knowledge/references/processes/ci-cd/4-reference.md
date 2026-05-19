# CI/CD for Automotive Software - Level 4: Reference

> Audience: Developers needing quick lookup tables and configurations
> Purpose: Rapid reference for CI/CD tools, thresholds, and configurations

## Pipeline Stage Reference

| Stage | Tools | Trigger | Timeout | Block on Fail |
|-------|-------|---------|---------|--------------|
| Build (host) | GCC, CMake | Every push | 15 min | Yes |
| Build (target) | ARM GCC, Yocto SDK | Every push | 30 min | Yes |
| MISRA check | cppcheck, Polyspace | Every push | 30 min | Yes (mandatory) |
| Complexity | lizard | Every push | 5 min | Warning only |
| Unit tests | GoogleTest, pytest | Every push | 20 min | Yes |
| Coverage | gcovr, JaCoCo | Every push | 10 min | Yes |
| Security scan | flawfinder, Snyk | Every push | 15 min | Yes (critical) |
| Integration | pytest, Robot | Merge to develop | 60 min | Yes |
| SIL simulation | Custom runner | Merge to develop | 2 hours | Yes |
| HIL tests | Robot Framework | Release branch | 4 hours | Yes |
| Package | CMake CPack, SWUpdate | Release branch | 15 min | Yes |
| Sign | PKCS#11, HSM | Release branch | 5 min | Yes |

## Coverage Thresholds by ASIL

| ASIL Level | Line Coverage | Branch Coverage | MC/DC | Requirements |
|-----------|--------------|----------------|-------|-------------|
| QM | >= 60% | >= 50% | N/A | N/A |
| ASIL A | >= 70% | >= 60% | N/A | >= 90% |
| ASIL B | >= 80% | >= 70% | Recommended | >= 95% |
| ASIL C | >= 90% | >= 80% | Required | >= 98% |
| ASIL D | >= 95% | >= 90% | 100% | 100% |

## MISRA Compliance Configuration

```
# misra-suppressions.txt - Justified deviations
# Format: [rule]:[file]:[line]:[justification-id]

# Deviation D001: Third-party header includes
misra-c2012-20.10:third_party/*:*:D001

# Deviation D002: Assembly in startup code
misra-c2012-1.2:startup/boot.c:*:D002

# Deviation D003: Bitfields in hardware register access
misra-c2012-6.1:drivers/registers.h:*:D003
```

## Complexity Thresholds

| Metric | Threshold | Action |
|--------|-----------|--------|
| Cyclomatic complexity | <= 10 (ideal), <= 15 (max) | Block if > 15 |
| Function length | <= 50 lines | Warning if > 50 |
| File length | <= 500 lines | Warning if > 500 |
| Function parameters | <= 4 | Warning if > 4 |
| Nesting depth | <= 4 | Block if > 4 |
| Duplicated code | <= 3% | Warning if > 3% |

## Build Configuration Matrix

| Target | Compiler | Flags | Sanitizers |
|--------|----------|-------|-----------|
| Host Debug | GCC 12 | -O0 -g -Wall -Werror | ASan, UBSan |
| Host Release | GCC 12 | -O2 -DNDEBUG | None |
| ARM Debug | ARM GCC 12 | -O0 -g -mcpu=cortex-a53 | None |
| ARM Release | ARM GCC 12 | -O2 -mcpu=cortex-a53 | None |
| Coverage | GCC 12 | -O0 -g --coverage | None |
| MISRA | GCC 12 + cppcheck | -std=c11 -pedantic | None |

## Jenkins Plugin Reference

| Plugin | Purpose | Configuration |
|--------|---------|--------------|
| Pipeline | Declarative pipelines | Jenkinsfile in repo root |
| Docker Pipeline | Containerized builds | Agent runs in container |
| JUnit | Test result publishing | `junit '**/test-results.xml'` |
| Cobertura | Coverage reporting | `cobertura 'coverage.xml'` |
| Warnings NG | Static analysis | `recordIssues tools: [...]` |
| Robot Framework | HIL test results | `robot outputPath: 'results'` |
| Slack | Notifications | Channel + webhook URL |
| Artifactory | Artifact management | Server ID + credentials |
| OWASP Dep Check | Dependency audit | Auto-update NVD database |

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| BUILD_TYPE | Debug/Release | Release |
| TARGET_ARCH | Target architecture | aarch64 |
| MISRA_STRICT | Enable strict MISRA | true |
| COVERAGE_MIN | Minimum coverage % | 80 |
| HIL_BENCH_IP | HIL bench address | 192.168.1.100 |
| HSM_SLOT | Signing key slot | 0 |
| OTA_SERVER | OTA backend URL | https://ota.example.com |
| ARTIFACT_REPO | Artifact repository | https://artifactory.example.com |

## Artifact Naming Convention

```
Format: {project}-{component}-{version}-{target}-{build_type}.{ext}

Examples:
  cube-bgm-2.1.0-aarch64-release.elf
  cube-bgm-2.1.0-aarch64-release.swu
  cube-bgm-2.1.0-x86_64-debug.elf
  cube-bgm-2.1.0-coverage-report.xml
  cube-bgm-2.1.0-misra-report.html
```

## Git Branch Strategy

| Branch | Purpose | Protection | CI Stages |
|--------|---------|-----------|-----------|
| feature/* | Development | None | Build + Analysis + Unit |
| develop | Integration | PR required | All except HIL |
| release/* | Release prep | PR + approval | All stages |
| hotfix/* | Emergency fix | PR + safety review | All stages |
| main | Production | PR + 2 approvals | Tag + archive only |

## Notification Rules

| Event | Channel | Recipients |
|-------|---------|-----------|
| Build failure | Slack #ci-failures | Committer + team lead |
| Gate failure | Slack #ci-failures | Committer |
| Security CVE found | Slack #security | Security team |
| Release ready | Slack #releases | Release manager |
| HIL test failure | Slack #hil-testing | Test engineers |
| Deployment complete | Slack #deployments | Operations team |

## Common CI/CD CLI Commands

```bash
# Trigger Jenkins build
curl -X POST "https://jenkins.example.com/job/cube-bgm/build" \
     --user user:token

# Check build status
curl -s "https://jenkins.example.com/job/cube-bgm/lastBuild/api/json" \
     | jq '.result'

# Download artifact
curl -O "https://artifactory.example.com/automotive/cube-bgm-2.1.0.elf"

# GitLab: trigger pipeline
curl -X POST "https://gitlab.example.com/api/v4/projects/42/trigger/pipeline" \
     -F "token=TRIGGER_TOKEN" -F "ref=develop"

# View pipeline status
gh run list --workflow=ci.yml --limit=5
```

## Summary

This reference covers pipeline stages with timing and trigger rules,
coverage thresholds mapped to ASIL levels, static analysis configuration,
build matrix for host and target platforms, and standard conventions for
artifacts, branches, and notifications.
