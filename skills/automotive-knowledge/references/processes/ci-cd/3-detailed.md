# CI/CD for Automotive Software - Level 3: Detailed Implementation

> Audience: Developers and DevOps engineers implementing CI/CD
> Purpose: Concrete pipeline definitions, scripts, and configurations

## Jenkinsfile: Multi-Stage Automotive Pipeline

```groovy
pipeline {
    agent none

    environment {
        TOOLCHAIN_IMAGE = 'automotive-sdk:2024.1'
        ARTIFACT_REPO   = 'https://artifactory.example.com/automotive'
        MISRA_CONFIG     = 'misra-c-2012-mandatory.cfg'
    }

    options {
        timestamps()
        timeout(time: 4, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '50'))
    }

    stages {
        stage('Build') {
            parallel {
                stage('Build ARM Target') {
                    agent { docker { image "${TOOLCHAIN_IMAGE}" } }
                    steps {
                        sh '''
                            source /opt/sdk/environment-setup-aarch64-linux
                            mkdir -p build-arm && cd build-arm
                            cmake .. -DCMAKE_BUILD_TYPE=Release \
                                     -DCMAKE_TOOLCHAIN_FILE=../cmake/aarch64-toolchain.cmake
                            make -j\$(nproc) 2>&1 | tee build.log
                            # Fail on warnings
                            if grep -q "warning:" build.log; then
                                echo "Build warnings detected"
                                exit 1
                            fi
                        '''
                    }
                    post {
                        success {
                            archiveArtifacts artifacts: 'build-arm/**/*.elf'
                            stash name: 'arm-binaries', includes: 'build-arm/**/*.elf'
                        }
                    }
                }
                stage('Build x86 Host') {
                    agent { docker { image "${TOOLCHAIN_IMAGE}" } }
                    steps {
                        sh '''
                            mkdir -p build-host && cd build-host
                            cmake .. -DCMAKE_BUILD_TYPE=Debug \
                                     -DENABLE_COVERAGE=ON \
                                     -DENABLE_SANITIZERS=ON
                            make -j\$(nproc)
                        '''
                    }
                    post {
                        success {
                            stash name: 'host-binaries', includes: 'build-host/**'
                        }
                    }
                }
            }
        }

        stage('Static Analysis') {
            agent { docker { image "${TOOLCHAIN_IMAGE}" } }
            steps {
                unstash 'host-binaries'
                sh '''
                    # MISRA compliance check
                    cppcheck --enable=all --std=c11 \
                             --addon=misra.json \
                             --suppressions-list=misra-suppressions.txt \
                             --xml --xml-version=2 \
                             src/ 2> cppcheck-report.xml

                    # Complexity analysis
                    lizard src/ --CCN 15 --length 50 --arguments 4 \
                           --xml > complexity-report.xml

                    # Security scan
                    flawfinder --minlevel=2 --columns --dataonly \
                               --html src/ > security-report.html
                '''
            }
            post {
                always {
                    recordIssues(tools: [cppCheck(pattern: 'cppcheck-report.xml')])
                    archiveArtifacts artifacts: '*-report.*'
                }
            }
        }

        stage('Unit Tests + Coverage') {
            agent { docker { image "${TOOLCHAIN_IMAGE}" } }
            steps {
                unstash 'host-binaries'
                sh '''
                    cd build-host
                    ctest --output-on-failure --timeout 60 -j\$(nproc)

                    # Generate coverage report
                    gcovr --root .. --xml-pretty -o coverage.xml \
                          --branches --exclude='.*test.*' \
                          --exclude='.*third_party.*'

                    # Check coverage thresholds
                    python3 ../scripts/check_coverage.py coverage.xml \
                            --line-threshold 80 \
                            --branch-threshold 70 \
                            --mcdc-threshold 100 \
                            --mcdc-paths src/safety/
                '''
            }
            post {
                always {
                    junit 'build-host/**/test-results.xml'
                    cobertura coberturaReportFile: 'build-host/coverage.xml'
                }
            }
        }

        stage('Integration Tests (SIL)') {
            when { anyOf { branch 'develop'; branch 'release/*' } }
            agent { label 'sil-capable' }
            steps {
                unstash 'host-binaries'
                sh '''
                    cd tests/integration
                    python3 -m pytest -v --timeout=300 \
                            --junitxml=integration-results.xml \
                            test_service_integration.py \
                            test_can_simulation.py \
                            test_state_machine.py
                '''
            }
            post {
                always {
                    junit 'tests/integration/integration-results.xml'
                }
            }
        }

        stage('HIL Tests') {
            when { branch 'release/*' }
            agent { label 'hil-bench-01' }
            steps {
                unstash 'arm-binaries'
                sh '''
                    # Flash target ECU
                    openocd -f board/target-ecu.cfg \
                            -c "program build-arm/app.elf verify reset exit"

                    # Run HIL test suite
                    robot --outputdir hil-results \
                          --variable ECU_IP:192.168.1.100 \
                          --variable TIMEOUT:30 \
                          tests/hil/
                '''
            }
            post {
                always {
                    robot outputPath: 'hil-results'
                    archiveArtifacts artifacts: 'hil-results/**'
                }
            }
        }

        stage('Package and Sign') {
            when { branch 'release/*' }
            agent { docker { image "${TOOLCHAIN_IMAGE}" } }
            steps {
                unstash 'arm-binaries'
                sh '''
                    # Create OTA update package
                    python3 scripts/create_ota_package.py \
                            --binary build-arm/app.elf \
                            --version ${BUILD_TAG} \
                            --output update-package.swu

                    # Sign with HSM (via PKCS#11)
                    python3 scripts/sign_package.py \
                            --package update-package.swu \
                            --hsm-slot 0 \
                            --output update-package-signed.swu
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'update-package-signed.swu'
                }
            }
        }
    }

    post {
        failure {
            slackSend(channel: '#ci-failures',
                      message: "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        success {
            slackSend(channel: '#ci-builds',
                      message: "Build passed: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
    }
}
```

## Coverage Threshold Script

```python
#!/usr/bin/env python3
"""Check coverage thresholds for automotive CI gate."""

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import NamedTuple


class CoverageResult(NamedTuple):
    line_rate: float
    branch_rate: float
    file_path: str


def parse_cobertura(xml_path: str) -> list[CoverageResult]:
    """Parse Cobertura XML coverage report."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    results = []

    for package in root.findall('.//package'):
        for cls in package.findall('.//class'):
            filename = cls.get('filename', 'unknown')
            line_rate = float(cls.get('line-rate', '0'))
            branch_rate = float(cls.get('branch-rate', '0'))
            results.append(CoverageResult(line_rate, branch_rate, filename))

    return results


def check_thresholds(results: list[CoverageResult],
                     line_threshold: float,
                     branch_threshold: float,
                     mcdc_threshold: float,
                     mcdc_paths: list[str]) -> bool:
    """Verify coverage meets thresholds. Return True if all pass."""
    total_lines_covered = 0
    total_lines = 0
    total_branches_covered = 0
    total_branches = 0
    passed = True

    for r in results:
        total_lines += 1
        total_lines_covered += r.line_rate

        # Check MC/DC paths (safety-critical code)
        is_safety = any(r.file_path.startswith(p) for p in mcdc_paths)
        if is_safety and r.branch_rate * 100 < mcdc_threshold:
            print(f"FAIL: {r.file_path} branch coverage "
                  f"{r.branch_rate*100:.1f}% < {mcdc_threshold}% (safety code)")
            passed = False

    avg_line = (total_lines_covered / max(total_lines, 1)) * 100
    if avg_line < line_threshold:
        print(f"FAIL: Overall line coverage {avg_line:.1f}% < {line_threshold}%")
        passed = False
    else:
        print(f"PASS: Overall line coverage {avg_line:.1f}% >= {line_threshold}%")

    return passed


def main() -> None:
    parser = argparse.ArgumentParser(description='Coverage gate checker')
    parser.add_argument('coverage_xml', help='Cobertura XML report path')
    parser.add_argument('--line-threshold', type=float, default=80.0)
    parser.add_argument('--branch-threshold', type=float, default=70.0)
    parser.add_argument('--mcdc-threshold', type=float, default=100.0)
    parser.add_argument('--mcdc-paths', nargs='*', default=[])
    args = parser.parse_args()

    results = parse_cobertura(args.coverage_xml)
    if not check_thresholds(results, args.line_threshold,
                            args.branch_threshold, args.mcdc_threshold,
                            args.mcdc_paths):
        sys.exit(1)
    print("All coverage gates passed.")


if __name__ == '__main__':
    main()
```

## GitLab CI Alternative

```yaml
# .gitlab-ci.yml for automotive project
variables:
  TOOLCHAIN_IMAGE: automotive-sdk:2024.1
  GIT_SUBMODULE_STRATEGY: recursive

stages:
  - build
  - analyze
  - test
  - integration
  - package

build:arm:
  stage: build
  image: ${TOOLCHAIN_IMAGE}
  script:
    - source /opt/sdk/environment-setup-aarch64-linux
    - mkdir -p build-arm && cd build-arm
    - cmake .. -DCMAKE_BUILD_TYPE=Release
    - make -j$(nproc)
  artifacts:
    paths: [build-arm/]
    expire_in: 1 week

build:host:
  stage: build
  image: ${TOOLCHAIN_IMAGE}
  script:
    - mkdir -p build-host && cd build-host
    - cmake .. -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON
    - make -j$(nproc)
  artifacts:
    paths: [build-host/]
    expire_in: 1 week

static-analysis:
  stage: analyze
  image: ${TOOLCHAIN_IMAGE}
  needs: [build:host]
  script:
    - cppcheck --enable=all --std=c11 --addon=misra.json
              --xml --xml-version=2 src/ 2> cppcheck.xml
    - lizard src/ --CCN 15 --length 50 --xml > complexity.xml
  artifacts:
    reports:
      codequality: cppcheck.xml

unit-tests:
  stage: test
  image: ${TOOLCHAIN_IMAGE}
  needs: [build:host]
  script:
    - cd build-host && ctest --output-on-failure -j$(nproc)
    - gcovr --root .. --xml-pretty -o coverage.xml
  artifacts:
    reports:
      junit: build-host/**/test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: build-host/coverage.xml
  coverage: '/^TOTAL.*\s+(\d+)%$/'

integration-tests:
  stage: integration
  needs: [build:host, unit-tests]
  rules:
    - if: $CI_COMMIT_BRANCH =~ /^(develop|release\/.*)$/
  script:
    - cd tests/integration
    - python3 -m pytest -v --junitxml=results.xml
  artifacts:
    reports:
      junit: tests/integration/results.xml

package-sign:
  stage: package
  needs: [build:arm, integration-tests]
  rules:
    - if: $CI_COMMIT_BRANCH =~ /^release\/.*/
  script:
    - python3 scripts/create_ota_package.py
              --binary build-arm/app.elf
              --version ${CI_COMMIT_TAG}
              --output update.swu
    - python3 scripts/sign_package.py
              --package update.swu --hsm-slot 0
  artifacts:
    paths: [update-signed.swu]
    expire_in: 1 year
```

## Docker Build Environment

```dockerfile
# Dockerfile for reproducible automotive build environment
FROM ubuntu:22.04 AS automotive-sdk

ARG GCC_ARM_VERSION=12.3.rel1
ARG CMAKE_VERSION=3.28.1

# Install base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget git python3 python3-pip \
    cppcheck lizard flawfinder gcovr \
    && rm -rf /var/lib/apt/lists/*

# Install ARM cross-compiler
RUN wget -q "https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_ARM_VERSION}/binrel/arm-gnu-toolchain-${GCC_ARM_VERSION}-x86_64-aarch64-none-linux-gnu.tar.xz" \
    && tar xf arm-gnu-toolchain-*.tar.xz -C /opt/ \
    && rm arm-gnu-toolchain-*.tar.xz
ENV PATH="/opt/arm-gnu-toolchain-${GCC_ARM_VERSION}-x86_64-aarch64-none-linux-gnu/bin:${PATH}"

# Install CMake
RUN wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" \
    && chmod +x cmake-*.sh && ./cmake-*.sh --skip-license --prefix=/usr/local \
    && rm cmake-*.sh

# Install Python test tools
RUN pip3 install pytest robotframework gcovr

# Verification
RUN aarch64-none-linux-gnu-gcc --version && cmake --version
```

## Summary

Automotive CI/CD implementation requires multi-stage pipelines with parallel
build targets (host + cross-compiled), static analysis gates (MISRA, complexity,
security), coverage enforcement with safety-specific thresholds, and hardware-
in-the-loop test integration. Reproducible builds via containerized environments
and comprehensive artifact archival ensure traceability and compliance.
