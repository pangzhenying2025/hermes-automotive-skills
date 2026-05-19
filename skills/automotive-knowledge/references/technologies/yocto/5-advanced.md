# Yocto Project - Advanced Topics

## Custom Layer Creation

### Create Layer from Scratch

```bash
# Use layer creation script
bitbake-layers create-layer meta-automotive-custom

# Structure created:
# meta-automotive-custom/
# ├── conf/
# │   └── layer.conf
# ├── COPYING.MIT
# ├── README
# └── recipes-example/
#     └── example/
#         └── example_0.1.bb
```

### Layer Configuration

**conf/layer.conf**:
```python
# Layer identifier
BBPATH =. "${LAYERDIR}:"

# Recipe patterns
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

# Collection name
BBFILE_COLLECTIONS += "automotive-custom"
BBFILE_PATTERN_automotive-custom = "^${LAYERDIR}/"
BBFILE_PRIORITY_automotive-custom = "10"

# Layer dependencies
LAYERDEPENDS_automotive-custom = "core openembedded-layer"
LAYERSERIES_COMPAT_automotive-custom = "kirkstone langdale mickledore"

# Recipe preferences
PREFERRED_VERSION_battery-manager = "2.0%"
```

### Add Layer to Build

```bash
# Add layer
bitbake-layers add-layer ../meta-automotive-custom

# Verify
bitbake-layers show-layers
```

## Multiconfig Builds

Build multiple machine configurations simultaneously.

### Configure Multiconfig

**conf/local.conf**:
```python
# Enable multiconfig
BBMULTICONFIG = "ecu gateway display"
```

**conf/multiconfig/ecu.conf**:
```python
MACHINE = "automotive-ecu"
TMPDIR = "${TOPDIR}/tmp-ecu"
```

**conf/multiconfig/gateway.conf**:
```python
MACHINE = "automotive-gateway"
TMPDIR = "${TOPDIR}/tmp-gateway"
```

**conf/multiconfig/display.conf**:
```python
MACHINE = "automotive-display"
TMPDIR = "${TOPDIR}/tmp-display"
```

### Build All Configs

```bash
# Build all configurations
bitbake multiconfig:ecu:automotive-image \
         multiconfig:gateway:automotive-image \
         multiconfig:display:automotive-image

# Or with dependencies
bitbake mc::ecu:automotive-image mc::gateway:automotive-image
```

### Cross-Config Dependencies

```bitbake
# Recipe in ecu config depends on package from gateway config
DEPENDS += "mc::gateway:special-library"
```

## Reproducible Builds

Ensure identical builds produce identical binaries.

### Enable Reproducibility

**conf/local.conf**:
```python
# Reproducible builds
INHERIT += "reproducible_build"

# Source date epoch (fixes timestamps)
SOURCE_DATE_EPOCH = "1609459200"  # 2021-01-01

# Remove build paths from binaries
BUILDINFO_REPRODUCIBLE = "1"
DEBUG_PREFIX_MAP = "1"
```

### Verify Reproducibility

```bash
# Build twice
bitbake automotive-image
mv tmp/deploy/images/automotive-ecu/automotive-image*.ext4 /tmp/build1.ext4

bitbake -c cleanall automotive-image
bitbake automotive-image
mv tmp/deploy/images/automotive-ecu/automotive-image*.ext4 /tmp/build2.ext4

# Compare
sha256sum /tmp/build1.ext4 /tmp/build2.ext4
# Should be identical
```

## Shared State (sstate) Optimization

### sstate-cache Configuration

```python
# Shared sstate across builds
SSTATE_DIR = "/shared/yocto/sstate-cache"

# Mirror for sstate artifacts
SSTATE_MIRRORS = "\
file://.* http://sstate-mirror.example.com/PATH;downloadfilename=PATH \
file://.* file:///shared/network-sstate/PATH \
"

# Prune old sstate
BB_DISKMON_DIRS = "STOPTASKS,${SSTATE_DIR},10G,100M"
```

### Populate sstate Mirror

```bash
# Build and publish sstate
bitbake automotive-image
./scripts/sstate-cache-management.sh --stamps-dir=tmp/stamps --cache-dir=sstate-cache \
    --destination=/path/to/mirror
```

## Toaster Web Interface

Toaster provides web-based interface for builds.

### Start Toaster

```bash
cd poky
source oe-init-build-env
source toaster start

# Access UI
# http://localhost:8000
```

### Configure Build via Toaster

- Create project via web UI
- Select machine and distribution
- Add layers
- Trigger builds
- View real-time progress
- Analyze build statistics

### Stop Toaster

```bash
source toaster stop
```

## devtool Workflow

devtool streamlines recipe development and modification.

### Create New Recipe

```bash
# Create recipe from upstream source
devtool add battery-monitor git://github.com/example/battery-monitor.git

# Recipe created in workspace/recipes/battery-monitor/
# Source cloned to workspace/sources/battery-monitor/
```

### Modify Existing Recipe

```bash
# Extract source to workspace
devtool modify battery-manager

# Make changes in workspace/sources/battery-manager/
vim workspace/sources/battery-manager/src/main.c

# Build with changes
devtool build battery-manager

# Deploy to target
devtool deploy-target battery-manager root@192.168.1.100

# Test on target, iterate
```

### Finish Development

```bash
# Generate patch from changes
devtool finish battery-manager meta-automotive-apps

# Creates .bbappend with patches
# meta-automotive-apps/recipes-apps/battery-manager/battery-manager_%.bbappend
# meta-automotive-apps/recipes-apps/battery-manager/battery-manager/0001-fix-bug.patch
```

## Custom Distribution

Create organization-specific distribution.

**meta-automotive-distro/conf/distro/automotive-secure.conf**:
```python
require conf/distro/poky.conf

DISTRO = "automotive-secure"
DISTRO_NAME = "Automotive Secure Linux"
DISTRO_VERSION = "1.0"

# Security hardening
DISTRO_FEATURES:append = " pam selinux"
DISTRO_FEATURES:append = " seccomp"

# Remove insecure features
DISTRO_FEATURES:remove = "x11"

# Compiler hardening flags
SECURITY_CFLAGS = "-fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE"
SECURITY_LDFLAGS = "-Wl,-z,relro,-z,now -pie"

# Read-only rootfs by default
IMAGE_FEATURES:append = " read-only-rootfs"

# Minimal package set
PREFERRED_PROVIDER_virtual/libc = "glibc"
INIT_MANAGER = "systemd"

# No development tools on target
EXTRA_IMAGE_FEATURES:remove = "tools-debug dev-pkgs"

# Mandatory security updates
PREFERRED_VERSION_openssl = "3.0%"
PREFERRED_VERSION_openssh = "9.0%"
```

## License Compliance

### License Auditing

```bash
# Generate license manifest
bitbake -c populate_lic automotive-image

# License files in:
# tmp/deploy/licenses/automotive-image-*/

# Create license report
bitbake -c populate_sdk automotive-image
# SDK includes license documentation
```

### Configure License Restrictions

**conf/local.conf**:
```python
# Whitelist acceptable licenses
LICENSE_FLAGS_ACCEPTED = "commercial"

# Blacklist unacceptable licenses
INCOMPATIBLE_LICENSE = "GPL-3.0 LGPL-3.0 AGPL-3.0"

# Audit mode (warning only)
LICENSE_AUDIT_REPORTING = "warn"
```

## SDK Customization

### Extensible SDK (eSDK)

```bash
# Build extensible SDK
bitbake -c populate_sdk_ext automotive-image

# Install eSDK
./automotive-linux-*-esdk-*.sh

# eSDK includes:
# - Build system (BitBake + layers)
# - devtool for recipe creation
# - Ability to add new recipes
```

### eSDK Workflow

```bash
# Source eSDK environment
source /opt/automotive-esdk/environment-setup-*

# Add new software
devtool add mynewapp git://...

# Build
devtool build mynewapp

# Test
devtool deploy-target mynewapp root@target-ip

# Integrate into image
devtool finish mynewapp ./meta-automotive-apps
```

## Image Encryption

Encrypt root filesystem for security.

### dm-crypt Integration

**conf/local.conf**:
```python
IMAGE_FSTYPES += "ext4.enc"
IMAGE_ENCRYPTION_COMMAND = "cryptsetup luksFormat --key-file=\${ENCRYPT_KEY} \${IMAGE_NAME}.ext4"
```

**Recipe for boot configuration**:
```bitbake
# Add cryptsetup to image
IMAGE_INSTALL:append = " cryptsetup kernel-module-dm-crypt"

# Kernel command line
APPEND = "root=/dev/mapper/rootfs rootfstype=ext4"

# Initramfs to unlock
INITRAMFS_IMAGE = "automotive-initramfs-unlock"
```

## Over-the-Air (OTA) Updates

### SWUpdate Integration

**meta-automotive-ota/recipes-support/swupdate/swupdate_%.bbappend**:
```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://swupdate.cfg"

EXTRA_OECONF:append = " --enable-encrypted-images"
RDEPENDS:${PN}:append = " openssl libubootenv-bin"
```

**OTA Image Recipe**:
```bitbake
inherit swupdate

IMAGE_INSTALL:append = " swupdate swupdate-www"

SWU_IMAGES = "automotive-image"
```

### Mender Integration

```python
# conf/local.conf
IMAGE_INSTALL:append = " mender-client"
INHERIT += "mender-full"

MENDER_SERVER_URL = "https://hosted.mender.io"
MENDER_ARTIFACT_NAME = "automotive-release-${PV}"
```

## Real-Time Linux (PREEMPT_RT)

### Enable RT Kernel

**linux-automotive-rt_5.15.bb**:
```bitbake
require linux-automotive.inc

SRC_URI:append = " file://preempt-rt.cfg"

# RT patch
SRC_URI:append = " https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.15/patch-5.15.71-rt50.patch.xz"
```

**preempt-rt.cfg**:
```
CONFIG_PREEMPT_RT=y
CONFIG_HZ_1000=y
CONFIG_NO_HZ_FULL=y
```

**Image with RT tuning**:
```bitbake
IMAGE_INSTALL:append = " rt-tests stress-ng"

# CPU isolation
APPEND:append = " isolcpus=2,3 nohz_full=2,3"
```

## Performance Profiling

### Build Time Analysis

```bash
# Enable build stats
echo "USER_CLASSES += \"buildstats buildhistory\"" >> conf/local.conf

# Analyze build time
../poky/scripts/pybootchartgui/pybootchartgui.py tmp/buildstats/
# Generates buildstats.png

# Task time breakdown
bitbake -g -u taskexp automotive-image
```

### Runtime Analysis

```bitbake
# Add profiling tools
IMAGE_INSTALL:append = " perf lttng-tools systemtap"

# Debug symbols
IMAGE_FEATURES:append = " dbg-pkgs"
```

## CI/CD Integration

### GitLab CI Example

**.gitlab-ci.yml**:
```yaml
stages:
  - build
  - test
  - deploy

variables:
  MACHINE: "automotive-ecu"
  DISTRO: "automotive-linux"

build_image:
  stage: build
  image: crops/poky:ubuntu-22.04
  script:
    - source oe-init-build-env
    - echo 'MACHINE = "${MACHINE}"' >> conf/local.conf
    - echo 'DISTRO = "${DISTRO}"' >> conf/local.conf
    - bitbake automotive-image
  artifacts:
    paths:
      - build/tmp/deploy/images/${MACHINE}/*.wic.bz2
    expire_in: 1 week

test_image:
  stage: test
  script:
    - ./scripts/qemu-test.sh build/tmp/deploy/images/${MACHINE}/automotive-image*.wic.bz2
```

### Jenkins Pipeline

```groovy
pipeline {
    agent { label 'yocto-builder' }

    stages {
        stage('Setup') {
            steps {
                sh 'source oe-init-build-env'
            }
        }

        stage('Build') {
            steps {
                sh 'bitbake automotive-image'
            }
        }

        stage('Test') {
            steps {
                sh './scripts/run-tests.sh'
            }
        }

        stage('Publish') {
            steps {
                archiveArtifacts artifacts: 'tmp/deploy/images/**/*.wic.bz2'
            }
        }
    }
}
```

## Best Practices

1. **Layer Organization**: Separate BSP, distro, and application layers
2. **Version Control**: Store layers in Git, use submodules or Repo manifest
3. **Build Server**: Dedicated build machine with fast storage (SSD/NVMe)
4. **Shared State**: Network sstate-cache for team builds
5. **Reproducibility**: Enable reproducible_build for auditability
6. **Documentation**: Maintain CLAUDE.md in each custom layer
7. **Testing**: Automate image testing with QEMU or hardware-in-loop
8. **Security**: Regular CVE scanning, security-focused distro config
9. **Modularity**: Use packagegroups for logical software grouping
10. **Maintainability**: Minimize bbappends, prefer recipe overrides in layers

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Advanced Yocto users, build system architects
