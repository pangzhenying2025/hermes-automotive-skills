# Yocto Project - Conceptual Architecture

## Layer Architecture

Yocto organizes recipes, configurations, and metadata into **layers**. Layers provide modularity and enable sharing configurations across projects.

### Layer Hierarchy

```
┌─────────────────────────────────────────┐
│  meta-custom-automotive (application)   │
│  - Vehicle-specific recipes             │
│  - Custom images                        │
└─────────────────────────────────────────┘
                 ↓ depends on
┌─────────────────────────────────────────┐
│  meta-custom-bsp (board support)        │
│  - Machine configurations               │
│  - Kernel recipes                       │
│  - Bootloader                           │
└─────────────────────────────────────────┘
                 ↓ depends on
┌─────────────────────────────────────────┐
│  meta-openembedded (middleware)         │
│  - Additional software                  │
│  - Networking, security                 │
└─────────────────────────────────────────┘
                 ↓ depends on
┌─────────────────────────────────────────┐
│  poky (reference distribution)          │
│  - meta (OE-Core)                       │
│  - meta-poky (Poky-specific)            │
│  - meta-yocto-bsp (reference BSPs)      │
└─────────────────────────────────────────┘
```

### Layer Structure

Every layer follows a standard directory structure:

```
meta-my-layer/
├── conf/
│   └── layer.conf              # Layer configuration
├── recipes-bsp/                # Board support packages
│   ├── bootloader/
│   └── kernel/
├── recipes-core/               # Core system recipes
│   ├── images/                 # Image recipes
│   ├── init/                   # Init systems (systemd)
│   └── packagegroups/          # Package collections
├── recipes-connectivity/       # Network, communication
│   ├── canutils/
│   └── mosquitto/
├── recipes-apps/               # Applications
│   ├── battery-management/
│   └── vehicle-controller/
├── classes/                    # Reusable build logic
├── files/                      # Patches, config files
└── COPYING.MIT                 # License file
```

### Layer Priority

Layers have priority values controlling which layer's recipes override others.

**layer.conf**:
```python
# Layer priority (higher = higher priority)
BBFILE_PRIORITY_meta-custom-automotive = "10"

# Dependencies
LAYERDEPENDS_meta-custom-automotive = "core custom-bsp"

# Version compatibility
LAYERSERIES_COMPAT_meta-custom-automotive = "kirkstone langdale"
```

**Priority Example**:
```
meta (priority 5): provides bash_5.1.bb
meta-custom (priority 10): provides bash_5.1.bbappend

Result: bash recipe from meta, extended by meta-custom
```

## Recipe Structure

Recipes (.bb files) define how to build software packages.

### Recipe Anatomy

```bitbake
# battery-manager.bb

# Metadata
SUMMARY = "Battery Management System Application"
DESCRIPTION = "Real-time battery monitoring and control for EVs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=abc123..."

# Version
PV = "2.0"

# Source
SRC_URI = "git://github.com/example/battery-mgr.git;branch=main;protocol=https \
           file://battery-manager.service \
           file://config.yaml \
          "
SRCREV = "d4f3a2b8c1e9f0a7b6c5d4e3f2a1b0c9d8e7f6a5"

# Dependencies (build-time)
DEPENDS = "protobuf zeromq systemd"

# Dependencies (runtime)
RDEPENDS:${PN} = "libprotobuf zeromq bash"

# Build system
inherit cmake systemd

# Build configuration
EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release \
                 -DENABLE_TESTS=OFF \
                "

# Install task
do_install:append() {
    install -d ${D}${sysconfdir}/battery
    install -m 0644 ${WORKDIR}/config.yaml ${D}${sysconfdir}/battery/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/battery-manager.service \
        ${D}${systemd_system_unitdir}/
}

# Systemd service
SYSTEMD_SERVICE:${PN} = "battery-manager.service"
SYSTEMD_AUTO_ENABLE = "enable"

# Package files
FILES:${PN} += "${sysconfdir}/battery/config.yaml"
```

### Recipe Variables

**Key Variables**:

| Variable | Purpose | Example |
|----------|---------|---------|
| `PN` | Package name | `battery-manager` |
| `PV` | Package version | `2.0` |
| `PR` | Package revision | `r1` |
| `SUMMARY` | Short description | "BMS application" |
| `LICENSE` | License identifier | `"MIT"` |
| `SRC_URI` | Source location | `"git://..."` |
| `SRCREV` | Git commit hash | `"d4f3a2b8..."` |
| `DEPENDS` | Build dependencies | `"protobuf zeromq"` |
| `RDEPENDS` | Runtime dependencies | `"libprotobuf"` |

**Variable Expansion**:
```bitbake
PN = "battery-manager"
PV = "2.0"
P = "${PN}-${PV}"              # "battery-manager-2.0"
WORKDIR = "/path/to/work/${P}" # Work directory
S = "${WORKDIR}/git"           # Source directory (for git)
D = "${WORKDIR}/image"         # Destination (install root)
```

## BSP Layers (Board Support Package)

BSP layers provide machine-specific configurations.

### Machine Configuration

**conf/machine/automotive-ecu.conf**:
```python
# Machine definition
#@TYPE: Machine
#@NAME: Automotive ECU
#@DESCRIPTION: NXP i.MX8-based ECU for battery management

# Architecture
require conf/machine/include/arm/armv8a/tune-cortexa53.inc

# Kernel
PREFERRED_PROVIDER_virtual/kernel = "linux-automotive"
KERNEL_DEVICETREE = "freescale/imx8mm-automotive-ecu.dtb"
KERNEL_IMAGETYPE = "Image"

# Bootloader
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-automotive"
UBOOT_MACHINE = "imx8mm_automotive_defconfig"
UBOOT_DTB_NAME = "imx8mm-automotive-ecu.dtb"

# Serial console
SERIAL_CONSOLES = "115200;ttymxc0"

# Features
MACHINE_FEATURES = "usbhost ethernet can bluetooth wifi"

# Image
IMAGE_FSTYPES = "ext4 wic.bz2"
WKS_FILE = "automotive-ecu.wks"

# Extra firmware
MACHINE_EXTRA_RDEPENDS = "linux-firmware-imx"
```

### Kernel Recipe

**recipes-kernel/linux/linux-automotive_5.15.bb**:
```bitbake
SUMMARY = "Linux kernel for automotive ECU"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=..."

DEPENDS = "bc-native bison-native"

inherit kernel

SRC_URI = "git://github.com/nxp/linux.git;branch=lf-5.15.y;protocol=https \
           file://defconfig \
           file://0001-add-can-fd-support.patch \
          "
SRCREV = "abc123..."

LINUX_VERSION = "5.15.71"
PV = "${LINUX_VERSION}+git${SRCPV}"

KBUILD_DEFCONFIG = "imx_v8_defconfig"

# Device tree
KERNEL_DEVICETREE = "freescale/imx8mm-automotive-ecu.dtb"

# Kernel configuration fragments
SRC_URI += "file://can.cfg \
            file://security.cfg \
           "

# Compatible machines
COMPATIBLE_MACHINE = "automotive-ecu"
```

## Distribution Configuration

Distribution (distro) layers define policy: package versions, features, security settings.

### Distro Configuration

**conf/distro/automotive-linux.conf**:
```python
DISTRO = "automotive-linux"
DISTRO_NAME = "Automotive Linux Distribution"
DISTRO_VERSION = "1.0"
DISTRO_CODENAME = "pioneer"

# Maintainer
MAINTAINER = "Your Automotive Team <team@example.com>"

# Init system
INIT_MANAGER = "systemd"

# Features
DISTRO_FEATURES = "systemd usbhost pci wifi bluetooth can"
DISTRO_FEATURES:append = " pam ipv6"

# Remove sysvinit
DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"

# Security flags
SECURITY_CFLAGS = "-fstack-protector-strong -D_FORTIFY_SOURCE=2"
SECURITY_LDFLAGS = "-Wl,-z,relro,-z,now"

# Compiler optimization
FULL_OPTIMIZATION = "-O2 -pipe"

# Preferred versions
PREFERRED_VERSION_python3 = "3.10%"
PREFERRED_VERSION_systemd = "250%"

# Package management
PACKAGE_CLASSES = "package_rpm"

# SDK
SDK_NAME = "automotive-linux-sdk"
SDK_VENDOR = "-automotive"
```

## Image Types

Image recipes define what goes into the final filesystem.

### Image Recipe Structure

```bitbake
# recipes-core/images/automotive-image.bb

SUMMARY = "Automotive Linux image"
LICENSE = "MIT"

# Base image
inherit core-image

# Packages to include
IMAGE_INSTALL = "packagegroup-core-boot \
                 packagegroup-automotive-core \
                 battery-manager \
                 vehicle-controller \
                 systemd \
                 canutils \
                 openssh \
                "

# Image features
IMAGE_FEATURES += "ssh-server-openssh \
                   tools-debug \
                   package-management \
                  "

# Root filesystem size
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "2048"

# Read-only rootfs
IMAGE_FEATURES += "read-only-rootfs"

# Post-install commands
ROOTFS_POSTPROCESS_COMMAND += "set_root_password; "

set_root_password() {
    # Set default root password (for development only)
    sed -i 's/^root:.*/root:$6$saltsalt$hashedhash:18000:0:99999:7:::/' \
        ${IMAGE_ROOTFS}/etc/shadow
}
```

### Package Groups

Organize related packages into groups.

**recipes-core/packagegroups/packagegroup-automotive-core.bb**:
```bitbake
SUMMARY = "Core automotive packages"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    systemd \
    systemd-serialgetty \
    dbus \
    udev \
    kernel-modules \
    can-utils \
    iproute2 \
    openssh-sftp-server \
    vim \
"
```

## BitBake Fundamentals

BitBake is the task execution engine driving Yocto builds.

### Task Execution Flow

```
fetch → unpack → patch → configure → compile → install → package
  ↓       ↓        ↓         ↓          ↓         ↓         ↓
do_fetch do_unpack do_patch do_configure do_compile do_install do_package
```

**Task Dependencies**:
```
do_configure depends on do_patch
do_compile depends on do_configure
do_install depends on do_compile
do_package depends on do_install
```

### Task Functions

**Example Tasks in Recipe**:
```bitbake
# Override configure task
do_configure() {
    cd ${S}
    ./autogen.sh
    oe_runconf
}

# Append to install task
do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/my-app ${D}${bindir}/
}

# Prepend to compile task
do_compile:prepend() {
    export CFLAGS="${CFLAGS} -DVERSION=${PV}"
}
```

### Variable Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Assign (evaluated at use) | `VAR = "value"` |
| `:=` | Immediate assign | `VAR := "${PV}"` |
| `+=` | Append with space | `SRC_URI += "file://patch"` |
| `=+` | Prepend with space | `CFLAGS =+ "-g"` |
| `.=` | Append without space | `PV .= "+git"` |
| `=.` | Prepend without space | `PN =. "lib"` |
| `?=` | Weak assignment (if not set) | `VAR ?= "default"` |
| `??=` | Weaker assignment | `VAR ??= "weaker"` |

**Override Syntax**:
```bitbake
# Machine-specific
SRC_URI:automotive-ecu = "file://ecu-config"

# Architecture-specific
CFLAGS:arm = "-march=armv7-a"

# Append for specific machine
do_install:append:automotive-ecu() {
    # ECU-specific install steps
}
```

## Dependency Management

### Build-Time Dependencies (DEPENDS)

Packages needed to compile the recipe.

```bitbake
DEPENDS = "protobuf zeromq openssl"
```

**Effect**: BitBake ensures `protobuf`, `zeromq`, and `openssl` are built and staged before compiling this recipe.

### Runtime Dependencies (RDEPENDS)

Packages needed at runtime on target.

```bitbake
RDEPENDS:${PN} = "libprotobuf libzmq5 bash"
```

**Effect**: Package manager ensures these are installed when installing this package.

### Provider Relationships

**Virtual Providers**:
Some dependencies are abstract (e.g., "a kernel").

```bitbake
DEPENDS = "virtual/kernel"

# In machine config:
PREFERRED_PROVIDER_virtual/kernel = "linux-automotive"
```

**Alternatives**:
```bitbake
# Recipe provides alternatives
PROVIDES = "virtual/bootloader"

# Machine selects one
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-automotive"
```

## Classes and Inheritance

Classes provide reusable functionality.

### Common Classes

| Class | Purpose | Usage |
|-------|---------|-------|
| `kernel` | Build Linux kernel | `inherit kernel` |
| `cmake` | CMake-based builds | `inherit cmake` |
| `autotools` | Autoconf/Automake | `inherit autotools` |
| `systemd` | systemd service | `inherit systemd` |
| `useradd` | Create system users | `inherit useradd` |
| `update-rc.d` | SysV init scripts | `inherit update-rc.d` |
| `pkgconfig` | pkg-config support | `inherit pkgconfig` |

### Class Example: systemd

```bitbake
inherit systemd

SYSTEMD_SERVICE:${PN} = "battery-manager.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/battery-manager.service \
        ${D}${systemd_system_unitdir}/
}
```

**Effect**: Class automatically handles:
- systemd dependency
- Service installation path
- Enable/disable logic
- Package file inclusion

## Build Directory Structure

After sourcing `oe-init-build-env`, build directory contains:

```
build/
├── conf/
│   ├── local.conf          # Build configuration
│   ├── bblayers.conf       # Layer configuration
│   └── templateconf.cfg    # Template used
├── cache/                  # Persistent cache
├── downloads/              # Downloaded sources
├── sstate-cache/           # Shared state cache
├── tmp/
│   ├── work/               # Per-recipe work directories
│   ├── deploy/             # Output artifacts
│   │   ├── images/         # Final images
│   │   ├── rpm/            # RPM packages
│   │   └── sdk/            # SDK installers
│   └── sysroots/           # Target/native sysroots
└── bitbake.lock            # Build lock file
```

### Work Directory

Each recipe has a work directory:

```
tmp/work/cortexa53-poky-linux/battery-manager/2.0-r0/
├── battery-manager-2.0/    # Unpacked source (${S})
├── build/                  # Build artifacts (${B})
├── image/                  # Install destination (${D})
├── temp/                   # Log files
│   ├── log.do_compile
│   ├── log.do_install
│   └── run.do_compile
└── package/                # Packaged files
```

## Configuration Files

### local.conf

Build-specific settings.

```python
# Machine
MACHINE = "automotive-ecu"

# Distribution
DISTRO = "automotive-linux"

# Parallelism
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# Download directory
DL_DIR = "/shared/downloads"

# Shared state cache
SSTATE_DIR = "/shared/sstate-cache"

# Disk space monitoring
BB_DISKMON_DIRS = "STOPTASKS,${TMPDIR},1G,100K"

# Package management
PACKAGE_CLASSES = "package_rpm"

# Extra image features
EXTRA_IMAGE_FEATURES = "debug-tweaks tools-debug"

# SDK
SDKMACHINE = "x86_64"
```

### bblayers.conf

Layer configuration.

```python
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  /home/user/yocto/poky/meta \
  /home/user/yocto/poky/meta-poky \
  /home/user/yocto/poky/meta-yocto-bsp \
  /home/user/yocto/meta-openembedded/meta-oe \
  /home/user/yocto/meta-openembedded/meta-networking \
  /home/user/yocto/meta-automotive-bsp \
  /home/user/yocto/meta-automotive-apps \
  "
```

## Next Steps

- **Level 3**: Detailed recipe writing guide with real examples
- **Level 4**: BitBake variable reference and class documentation
- **Level 5**: Advanced topics including custom layers, SDK, reproducible builds

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Embedded Linux developers, Yocto beginners with Linux background
