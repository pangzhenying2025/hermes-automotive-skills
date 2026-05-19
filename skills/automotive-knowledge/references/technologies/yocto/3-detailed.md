# Yocto Project - Detailed Recipe Writing Guide

## Complete Recipe Example: CAN Utilities

### Recipe File: canutils_git.bb

```bitbake
# recipes-connectivity/canutils/canutils_git.bb

SUMMARY = "Linux CAN utilities"
DESCRIPTION = "CAN utilities including candump, cansend, canplayer for SocketCAN"
HOMEPAGE = "https://github.com/linux-can/can-utils"
SECTION = "net"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=94d55d512a9ba36caa9b7df079bae19f"

# Version
PV = "2023.03+git${SRCPV}"

# Source
SRC_URI = "git://github.com/linux-can/can-utils.git;protocol=https;branch=master"
SRCREV = "a2b7e5b2f5c0d8f9e4d3c2b1a0f9e8d7c6b5a4d3"

# Source directory
S = "${WORKDIR}/git"

# Dependencies
DEPENDS = "libsocketcan"
RDEPENDS:${PN} = "kernel-module-can kernel-module-can-raw"

# Build system
inherit cmake

# CMake options
EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release"

# Installation
do_install:append() {
    # Install configuration files
    install -d ${D}${sysconfdir}/can
    echo "can0 bitrate 500000" > ${D}${sysconfdir}/can/interfaces

    # Install systemd service
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/can-setup.service \
            ${D}${systemd_system_unitdir}/
    fi
}

# systemd
inherit systemd
SYSTEMD_SERVICE:${PN} = "can-setup.service"
SYSTEMD_AUTO_ENABLE = "enable"

# Additional files
SRC_URI += "file://can-setup.service"

# Package files
FILES:${PN} += "${sysconfdir}/can/interfaces"
```

### Supporting Files

**files/can-setup.service**:
```ini
[Unit]
Description=Setup CAN interfaces
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ip link set can0 type can bitrate 500000
ExecStart=/usr/bin/ip link set can0 up
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

## SRC_URI: Source Fetching

### Git Source

```bitbake
# Git with specific branch
SRC_URI = "git://github.com/user/repo.git;protocol=https;branch=main"
SRCREV = "abc123def456..."

# Git with tag
SRC_URI = "git://github.com/user/repo.git;protocol=https;tag=v2.0.1"

# Git with multiple repositories
SRC_URI = "git://github.com/user/main-repo.git;protocol=https;branch=main;name=main \
           git://github.com/user/sub-repo.git;protocol=https;branch=dev;name=sub;destsuffix=git/submodule"

SRCREV_main = "abc123..."
SRCREV_sub = "def456..."

# Automatic SRCREV (latest, not recommended for production)
SRCREV = "${AUTOREV}"
```

### HTTP/FTP Download

```bitbake
SRC_URI = "https://example.com/software-${PV}.tar.gz"
SRC_URI[sha256sum] = "a1b2c3d4e5f6..."

# Multiple archives
SRC_URI = "https://example.com/main-${PV}.tar.gz \
           https://example.com/docs-${PV}.tar.gz;name=docs"
SRC_URI[sha256sum] = "..."
SRC_URI[docs.sha256sum] = "..."
```

### Local Files

```bitbake
SRC_URI = "file://config.yaml \
           file://systemd-service.service \
           file://0001-fix-buffer-overflow.patch \
          "

# Files searched in:
# 1. recipes-*/recipe-name/recipe-name/
# 2. recipes-*/recipe-name/files/
```

### Patches

```bitbake
SRC_URI += "file://0001-add-can-fd-support.patch \
            file://0002-fix-memory-leak.patch \
           "

# Patch application controlled by
# do_patch task (automatic)
```

## do_compile: Build Tasks

### CMake Build

```bitbake
inherit cmake

EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release \
                 -DENABLE_TESTS=OFF \
                 -DCUSTOM_OPTION=ON \
                "

# Custom compile
do_compile:prepend() {
    export MY_ENV_VAR="value"
}

do_compile:append() {
    # Build additional component
    cd ${S}/extra-component
    oe_runmake
}
```

### Autotools Build

```bitbake
inherit autotools

# Configure options
EXTRA_OECONF = "--enable-feature \
                --disable-deprecated \
                --with-ssl=${STAGING_DIR_TARGET}${prefix} \
               "

# Custom configure
do_configure:prepend() {
    ./autogen.sh
}
```

### Makefile Build

```bitbake
# No inheritance needed

# Set build variables
EXTRA_OEMAKE = "CC='${CC}' \
                CFLAGS='${CFLAGS}' \
                LDFLAGS='${LDFLAGS}' \
                PREFIX=${prefix} \
               "

do_compile() {
    oe_runmake all
}

do_install() {
    oe_runmake install DESTDIR=${D}
}
```

### Cargo (Rust) Build

```bitbake
inherit cargo

SRC_URI = "git://github.com/user/rust-app.git;protocol=https;branch=main"

# Cargo dependencies
SRC_URI += "crate://crates.io/serde/1.0.152 \
            crate://crates.io/tokio/1.25.0 \
           "

CARGO_SRC_DIR = "${S}"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/rust-app \
        ${D}${bindir}/
}
```

## do_install: Installation Tasks

### Directory Creation and File Installation

```bitbake
do_install() {
    # Create directories
    install -d ${D}${bindir}
    install -d ${D}${libdir}
    install -d ${D}${sysconfdir}
    install -d ${D}${datadir}/${PN}

    # Install binaries
    install -m 0755 ${B}/my-app ${D}${bindir}/

    # Install libraries
    install -m 0644 ${B}/libmylib.so.${PV} ${D}${libdir}/
    ln -sf libmylib.so.${PV} ${D}${libdir}/libmylib.so.2
    ln -sf libmylib.so.2 ${D}${libdir}/libmylib.so

    # Install configuration
    install -m 0644 ${WORKDIR}/config.yaml ${D}${sysconfdir}/

    # Install data files
    install -m 0644 ${S}/data/* ${D}${datadir}/${PN}/
}
```

### Common Installation Paths

```bitbake
${bindir}              # /usr/bin
${sbindir}             # /usr/sbin
${libdir}              # /usr/lib
${includedir}          # /usr/include
${datadir}             # /usr/share
${sysconfdir}          # /etc
${localstatedir}       # /var
${systemd_system_unitdir}  # /lib/systemd/system
```

## DEPENDS and RDEPENDS

### Build Dependencies (DEPENDS)

```bitbake
# Single dependency
DEPENDS = "protobuf"

# Multiple dependencies
DEPENDS = "protobuf zeromq openssl"

# Append dependency
DEPENDS += "libxml2"

# Machine-specific dependency
DEPENDS:append:automotive-ecu = " custom-library"
```

### Runtime Dependencies (RDEPENDS)

```bitbake
# Runtime dependencies for package
RDEPENDS:${PN} = "bash libprotobuf libzmq5"

# Split package dependencies
RDEPENDS:${PN}-dev = "${PN} (= ${EXTENDPKGV})"
RDEPENDS:${PN}-tools = "${PN} python3"

# Conditional runtime dependency
RDEPENDS:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}"
```

### Dependency Examples

**C++ Application with Libraries**:
```bitbake
DEPENDS = "boost protobuf zeromq"
RDEPENDS:${PN} = "libboost-system libboost-thread libprotobuf libzmq5"
```

**Python Application**:
```bitbake
DEPENDS = "python3-setuptools-native"
RDEPENDS:${PN} = "python3 python3-requests python3-numpy"
```

**Kernel Module**:
```bitbake
DEPENDS = "virtual/kernel"
RDEPENDS:${PN} = "kernel-module-can"
```

## Systemd Service Integration

### Complete Example

```bitbake
# battery-manager.bb

inherit systemd

SRC_URI += "file://battery-manager.service"

SYSTEMD_SERVICE:${PN} = "battery-manager.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install:append() {
    # Install service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/battery-manager.service \
        ${D}${systemd_system_unitdir}/

    # Install environment file
    install -d ${D}${sysconfdir}/default
    echo "BATTERY_CONFIG=/etc/battery/config.yaml" > \
        ${D}${sysconfdir}/default/battery-manager
}

FILES:${PN} += "${sysconfdir}/default/battery-manager"
```

**battery-manager.service**:
```ini
[Unit]
Description=Battery Management Service
After=network.target can-setup.service
Requires=can-setup.service

[Service]
Type=simple
EnvironmentFile=/etc/default/battery-manager
ExecStart=/usr/bin/battery-manager --config ${BATTERY_CONFIG}
Restart=always
RestartSec=5
User=battery
Group=battery

[Install]
WantedBy=multi-user.target
```

### Multiple Services

```bitbake
SYSTEMD_SERVICE:${PN} = "service1.service service2.service service3.service"

# Enable only specific services
SYSTEMD_AUTO_ENABLE:service1.service = "enable"
SYSTEMD_AUTO_ENABLE:service2.service = "disable"
```

## User and Group Creation

```bitbake
inherit useradd

USERADD_PACKAGES = "${PN}"

USERADD_PARAM:${PN} = "-u 1200 -d /var/lib/battery -r -s /bin/false battery"
GROUPADD_PARAM:${PN} = "-g 1200 battery"

do_install:append() {
    # Create user's home directory
    install -d -m 0750 ${D}/var/lib/battery
    chown battery:battery ${D}/var/lib/battery

    # Set file ownership
    chown battery:battery ${D}${sysconfdir}/battery/config.yaml
}
```

## Package Splitting

### Automatic Splitting

Default packages created:
- `${PN}`: Main package
- `${PN}-dev`: Development files (headers, .a, .la)
- `${PN}-staticdev`: Static libraries
- `${PN}-dbg`: Debug symbols
- `${PN}-doc`: Documentation

### Custom Package Splitting

```bitbake
# Define additional packages
PACKAGES =+ "${PN}-tools ${PN}-plugins"

# Assign files to packages
FILES:${PN} = "${bindir}/battery-manager \
               ${sysconfdir}/battery/ \
              "

FILES:${PN}-tools = "${bindir}/battery-calibrate \
                     ${bindir}/battery-test \
                    "

FILES:${PN}-plugins = "${libdir}/battery-manager/plugins/*.so"

# Dependencies for split packages
RDEPENDS:${PN}-tools = "${PN}"
RDEPENDS:${PN}-plugins = "${PN}"

# Descriptions
SUMMARY:${PN}-tools = "Battery Manager calibration tools"
SUMMARY:${PN}-plugins = "Battery Manager plugins"
```

## bbappend Files

Extend existing recipes without modifying them.

### Example: Extend Kernel Recipe

**meta-automotive-bsp/recipes-kernel/linux/linux-automotive_%.bbappend**:
```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Add patches
SRC_URI += "file://0001-add-automotive-can-driver.patch \
            file://0002-enable-realtime-features.patch \
           "

# Add kernel config fragment
SRC_URI += "file://automotive.cfg"

# Override kernel defconfig
do_configure:prepend() {
    cp ${WORKDIR}/automotive_defconfig ${B}/.config
}
```

**Kernel config fragment (automotive.cfg)**:
```
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_VCAN=m
CONFIG_CAN_SLCAN=m
CONFIG_PREEMPT_RT=y
CONFIG_HIGH_RES_TIMERS=y
```

### Example: Extend systemd

**meta-automotive/recipes-core/systemd/systemd_%.bbappend**:
```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add custom service files
SRC_URI += "file://automotive-setup.service"

do_install:append() {
    install -m 0644 ${WORKDIR}/automotive-setup.service \
        ${D}${systemd_system_unitdir}/
}

SYSTEMD_SERVICE:${PN} += "automotive-setup.service"
```

## Image Recipes

### Minimal Image

```bitbake
# recipes-core/images/automotive-minimal-image.bb

SUMMARY = "Minimal automotive image"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL = "packagegroup-core-boot \
                 kernel-modules \
                 systemd \
                 can-utils \
                "

# Remove unnecessary packages
IMAGE_INSTALL:remove = "busybox"

# Image size
IMAGE_ROOTFS_SIZE ?= "4096"
IMAGE_ROOTFS_EXTRA_SPACE = "1024"

# Image format
IMAGE_FSTYPES = "ext4 tar.bz2"
```

### Full-Featured Image

```bitbake
# recipes-core/images/automotive-image.bb

SUMMARY = "Full automotive image with applications"
LICENSE = "MIT"

inherit core-image

# Package groups
IMAGE_INSTALL = "packagegroup-core-boot \
                 packagegroup-automotive-core \
                 packagegroup-automotive-apps \
                "

# Individual packages
IMAGE_INSTALL += "battery-manager \
                  vehicle-controller \
                  adas-processor \
                  canutils \
                  openssh \
                  vim \
                 "

# Image features
IMAGE_FEATURES += "ssh-server-openssh \
                   tools-debug \
                   package-management \
                   read-only-rootfs \
                  "

# Image size (MB)
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "2048"

# Multiple output formats
IMAGE_FSTYPES = "ext4 wic.bz2 tar.bz2"

# WIC image layout
WKS_FILE = "automotive-ecu.wks"

# Post-processing
ROOTFS_POSTPROCESS_COMMAND += "remove_dev_files; set_hostname; "

remove_dev_files() {
    rm -rf ${IMAGE_ROOTFS}/dev/*
}

set_hostname() {
    echo "automotive-ecu" > ${IMAGE_ROOTFS}/etc/hostname
}
```

### WIC Image Layout

**automotive-ecu.wks**:
```
# Boot partition
part /boot --source bootimg-partition --ondisk mmcblk0 --fstype=vfat --label boot --active --align 4 --size 64

# Root partition
part / --source rootfs --ondisk mmcblk0 --fstype=ext4 --label root --align 4 --size 4G

# Data partition
part /data --ondisk mmcblk0 --fstype=ext4 --label data --align 4 --size 8G
```

## Recipe Debugging

### Enable Verbose Output

```bitbake
# In recipe
do_compile() {
    bbnote "Starting compilation"
    bbwarn "This is a warning"
    bbdebug 1 "Debug message level 1"

    oe_runmake V=1  # Verbose make
}
```

### Add Development Shell Access

```bash
# Drop into devshell (before do_compile)
bitbake -c devshell battery-manager

# Inside devshell:
# - Source directory: $S
# - Build directory: $B
# - All environment variables available
```

### Inspect Task Logs

```bash
# View compile log
cat tmp/work/cortexa53-poky-linux/battery-manager/2.0-r0/temp/log.do_compile

# View install log
cat tmp/work/cortexa53-poky-linux/battery-manager/2.0-r0/temp/log.do_install

# View all task logs
ls tmp/work/cortexa53-poky-linux/battery-manager/2.0-r0/temp/log.do_*
```

## Common Recipe Patterns

### Qt5 Application

```bitbake
require recipes-qt/qt5/qt5.inc

DEPENDS = "qtbase qtdeclarative"
RDEPENDS:${PN} = "qtbase-plugins qtdeclarative-qmlplugins"

inherit qmake5

EXTRA_QMAKEVARS_PRE += "CONFIG+=release"

do_install:append() {
    install -d ${D}${datadir}/applications
    install -m 0644 ${WORKDIR}/battery-hmi.desktop \
        ${D}${datadir}/applications/
}
```

### Python Application

```bitbake
SUMMARY = "Battery diagnostic tool"
LICENSE = "MIT"

SRC_URI = "file://battery-diag.py \
           file://setup.py \
          "

RDEPENDS:${PN} = "python3 python3-can python3-yaml"

inherit setuptools3

S = "${WORKDIR}"

do_install:append() {
    # Install additional scripts
    install -d ${D}${bindir}
    install -m 0755 ${S}/battery-diag.py ${D}${bindir}/
}
```

### Kernel Module

```bitbake
SUMMARY = "Custom CAN driver"
LICENSE = "GPL-2.0-only"

inherit module

SRC_URI = "file://Makefile \
           file://can_driver.c \
          "

S = "${WORKDIR}"

RPROVIDES:${PN} += "kernel-module-can-custom"
```

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Yocto recipe developers, embedded Linux engineers
