# Yocto Project - Overview

## What is Yocto?

The Yocto Project is an open-source collaboration providing templates, tools, and methods to create custom Linux-based systems for embedded products, regardless of the hardware architecture. It is the de facto standard for building embedded Linux in automotive, industrial, and IoT applications.

## Key Characteristics

- **Layer-based architecture**: Modular, reusable configuration
- **BitBake build system**: Task-based build orchestration
- **OpenEmbedded Core**: Base metadata for Linux distribution
- **Cross-platform**: ARM, x86, PowerPC, RISC-V, and more
- **Reproducible builds**: Same input → same output
- **Long-term support**: LTS releases for production use

## Core Components

### BitBake
Task execution engine that:
- Parses recipes (.bb files)
- Resolves dependencies
- Executes tasks (fetch, unpack, compile, install)
- Generates packages (RPM, DEB, IPK)

### OpenEmbedded Core (oe-core)
Base layer providing:
- Core recipes for Linux kernel, C library, core utilities
- Classes for common build patterns
- Configuration templates

### Poky
Reference distribution containing:
- BitBake
- OpenEmbedded Core
- Sample BSP layers
- Documentation

## Yocto Layers

```
meta-custom/          ← Your product layer
meta-myboard/         ← BSP (Board Support Package)
meta-openembedded/    ← Community recipes
meta-virtualization/  ← Docker, LXC, etc.
oe-core/              ← Core system
bitbake/              ← Build engine
```

### Layer Types

**BSP Layer** (meta-raspberrypi, meta-ti, meta-renesas)
- Machine configurations
- Kernel recipes
- U-Boot recipes
- Hardware-specific drivers

**Distribution Layer** (meta-automotive, meta-ros)
- System policies
- Init system (systemd, sysvinit)
- Package management
- Feature selection

**Application Layer** (meta-ivi, meta-saft)
- Application recipes
- Service configurations
- Custom packages

## Build Workflow

```
1. Source environment
   $ source oe-init-build-env

2. Configure (conf/local.conf, conf/bblayers.conf)
   MACHINE = "raspberrypi4-64"
   DISTRO = "poky"

3. Build image
   $ bitbake core-image-minimal

4. Output
   build/tmp/deploy/images/<machine>/
   - <image>.wic    ← Flashable image
   - <image>.tar.gz ← Root filesystem
   - bzImage        ← Kernel
   - *.dtb          ← Device tree
```

## Recipe Anatomy

```bitbake
# Recipe: myapp_1.0.bb

SUMMARY = "My Application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=..."

SRC_URI = "git://github.com/myorg/myapp.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit cmake systemd

DEPENDS = "protobuf zeromq"
RDEPENDS:${PN} = "libzmq5 libprotobuf"

SYSTEMD_SERVICE:${PN} = "myapp.service"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/myapp.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${systemd_system_unitdir}/myapp.service"
```

## Key Configuration Files

### conf/local.conf
Global build configuration:

```bash
# Machine selection
MACHINE = "qemux86-64"

# Distribution
DISTRO = "poky"

# Parallelism
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# Package management
PACKAGE_CLASSES = "package_rpm"

# Extra image features
EXTRA_IMAGE_FEATURES = "debug-tweaks ssh-server-openssh"

# Disk space monitoring
BB_DISKMON_DIRS = "..."
```

### conf/bblayers.conf
Layer configuration:

```python
BBLAYERS ?= " \
  /path/to/poky/meta \
  /path/to/poky/meta-poky \
  /path/to/poky/meta-yocto-bsp \
  /path/to/meta-openembedded/meta-oe \
  /path/to/meta-openembedded/meta-networking \
  /path/to/meta-custom \
"
```

## Image Types

**core-image-minimal**
- Minimal bootable system
- ~10-20 MB root filesystem
- Use case: Testing, embedded systems

**core-image-base**
- Minimal + basic packages
- ~100 MB
- Use case: Simple applications

**core-image-full-cmdline**
- Full command-line environment
- ~200 MB
- Use case: Headless servers

**core-image-sato**
- Graphical system with Sato UI
- ~500 MB
- Use case: Reference implementation

**Custom Images**
```bitbake
# recipes-images/myimage/myimage.bb
require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " \
    myapp \
    protobuf \
    zeromq \
    systemd \
    vim \
    can-utils \
"

IMAGE_FEATURES:append = " \
    ssh-server-openssh \
    package-management \
"
```

## SDK Generation

Generate cross-compilation toolchain:

```bash
# Build SDK
$ bitbake myimage -c populate_sdk

# Output: tmp/deploy/sdk/
# poky-glibc-x86_64-myimage-cortexa72-toolchain-3.5.sh

# Install SDK
$ ./poky-glibc-x86_64-myimage-cortexa72-toolchain-3.5.sh

# Use SDK
$ source /opt/poky/3.5/environment-setup-cortexa72-poky-linux
$ $CC myapp.c -o myapp
```

## Common Tasks

```bash
# List all recipes
$ bitbake-layers show-recipes

# Show recipe dependencies
$ bitbake -g myapp
$ cat pn-buildlist

# Clean recipe
$ bitbake -c cleanall myapp

# Force rebuild
$ bitbake -f -c compile myapp

# Show recipe variables
$ bitbake -e myapp | grep ^SRC_URI=

# Run devshell (interactive build environment)
$ bitbake -c devshell myapp

# Show layer information
$ bitbake-layers show-layers
$ bitbake-layers show-appends
```

## Yocto Releases

| Release | Codename | Year | LTS | Linux Kernel |
|---------|----------|------|-----|--------------|
| 1.0 | Denzil | 2012 | No | 3.2 |
| 1.4 | Dylan | 2013 | Yes | 3.8 |
| 1.6 | Daisy | 2014 | No | 3.14 |
| 2.0 | Jethro | 2015 | No | 4.1 |
| 2.2 | Morty | 2016 | No | 4.8 |
| 2.4 | Rocko | 2017 | No | 4.12 |
| 2.5 | Sumo | 2018 | No | 4.14 |
| 2.6 | Thud | 2018 | No | 4.18 |
| 2.7 | Warrior | 2019 | No | 5.0 |
| 3.0 | Zeus | 2019 | No | 5.2 |
| 3.1 | Dunfell | 2020 | Yes | 5.4 |
| 3.2 | Gatesgarth | 2020 | No | 5.8 |
| 3.3 | Hardknott | 2021 | No | 5.10 |
| 3.4 | Honister | 2021 | No | 5.14 |
| 4.0 | Kirkstone | 2022 | Yes | 5.15 |
| 4.1 | Langdale | 2022 | No | 5.19 |
| 4.2 | Mickledore | 2023 | No | 6.1 |
| 4.3 | Nanbield | 2023 | No | 6.5 |
| 5.0 | Scarthgap | 2024 | Yes | 6.6 |

**Recommendation**: Use LTS releases (Kirkstone, Scarthgap) for production

## Automotive Use Cases

**In-Vehicle Infotainment (IVI)**
- Base: Yocto + meta-ivi
- Graphics: Wayland, Qt, Flutter
- Multimedia: GStreamer, PulseAudio

**Telematics Gateway**
- Base: Yocto + meta-openembedded
- Connectivity: ModemManager, NetworkManager
- Security: TPM, secure boot

**ADAS/Autonomous Driving**
- Base: Yocto + meta-ros
- Real-time: RT-PREEMPT kernel, Xenomai
- Vision: OpenCV, TensorFlow Lite

**Digital Instrument Cluster**
- Base: Yocto + meta-qt5
- Graphics: Qt/QML, Wayland
- CAN: SocketCAN, can-utils

## Best Practices

1. **Use layers**: Don't modify core layers, create custom layers
2. **Pin versions**: Use SRCREV for git-based recipes
3. **Minimize image**: Only include required packages
4. **Use sstate-cache**: Share build artifacts across builds
5. **Version control**: Track conf/ and custom layers in git
6. **Test on target**: Always validate on real hardware
7. **Security**: Enable security features (SELinux, secure boot)

## Troubleshooting

```bash
# Build fails - check logs
$ bitbake myapp
# Error → Check: tmp/work/.../myapp/1.0-r0/temp/log.do_compile

# Dependency issues
$ bitbake -g myimage
$ cat pn-depends.dot | grep myapp

# Disk space
$ df -h
$ rm -rf tmp/work/*  # Clean work directory

# Network fetch failures
# Set mirrors in local.conf
PREMIRRORS:prepend = "\
    git://.*/.* http://my-mirror/sources/ \n \
"
```

## Next Steps

- **Level 2**: Conceptual understanding of BitBake and recipes
- **Level 3**: Detailed recipe writing, layer creation
- **Level 4**: Complete reference for all variables and classes
- **Level 5**: Advanced patterns, optimization, security hardening

## References

- Yocto Project Official: https://www.yoctoproject.org
- OpenEmbedded: https://www.openembedded.org
- BitBake Manual: https://docs.yoctoproject.org/bitbake/

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Embedded Linux developers, BSP engineers, automotive system integrators
