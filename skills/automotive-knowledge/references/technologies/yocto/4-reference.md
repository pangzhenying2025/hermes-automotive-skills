# Yocto Project - Reference

## BitBake Variable Reference

### Directory Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `TOPDIR` | Build directory | `/home/user/build` |
| `TMPDIR` | Temporary build output | `${TOPDIR}/tmp` |
| `WORKDIR` | Recipe work directory | `tmp/work/cortexa53-poky-linux/pkg/1.0-r0` |
| `S` | Source directory | `${WORKDIR}/pkg-1.0` |
| `B` | Build directory | `${WORKDIR}/build` |
| `D` | Install destination | `${WORKDIR}/image` |
| `STAGING_DIR` | Staging area | `tmp/sysroots` |
| `DEPLOY_DIR` | Deploy output | `tmp/deploy` |
| `DL_DIR` | Download cache | `downloads` |

### Package Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PN` | Package name | `battery-manager` |
| `PV` | Package version | `2.0` |
| `PR` | Package revision | `r0` |
| `P` | Package name-version | `battery-manager-2.0` |
| `PF` | Full package ID | `battery-manager-2.0-r0` |
| `BPN` | Base package name | `battery-manager` |
| `BP` | Base package | `battery-manager-2.0` |

### Source Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SRC_URI` | Source locations | `"git://...;branch=main"` |
| `SRCREV` | Git commit hash | `"abc123def456..."` |
| `SRCPV` | Source version | `"git${SRCPV}"` |
| `S` | Source directory | `"${WORKDIR}/git"` |
| `SRC_URI[md5sum]` | Checksum (deprecated) | - |
| `SRC_URI[sha256sum]` | SHA-256 checksum | `"a1b2c3..."` |

### Dependency Variables

| Variable | Purpose |
|----------|---------|
| `DEPENDS` | Build-time dependencies |
| `RDEPENDS` | Runtime dependencies |
| `RRECOMMENDS` | Recommended runtime packages |
| `RSUGGESTS` | Suggested runtime packages |
| `RPROVIDES` | Virtual packages provided |
| `RCONFLICTS` | Conflicting packages |
| `RREPLACES` | Replaced packages |

### Compilation Variables

| Variable | Purpose |
|----------|---------|
| `CC` | C compiler |
| `CXX` | C++ compiler |
| `CFLAGS` | C compiler flags |
| `CXXFLAGS` | C++ compiler flags |
| `LDFLAGS` | Linker flags |
| `EXTRA_OEMAKE` | Extra make variables |
| `EXTRA_OECONF` | Extra configure options |
| `EXTRA_OECMAKE` | Extra CMake options |

### Installation Variables

| Variable | Purpose | Value |
|----------|---------|-------|
| `bindir` | Binary directory | `/usr/bin` |
| `sbindir` | System binary directory | `/usr/sbin` |
| `libdir` | Library directory | `/usr/lib` |
| `includedir` | Header directory | `/usr/include` |
| `sysconfdir` | Configuration directory | `/etc` |
| `datadir` | Data directory | `/usr/share` |
| `localstatedir` | Variable data directory | `/var` |
| `systemd_system_unitdir` | systemd unit directory | `/lib/systemd/system` |

## Class Reference

### kernel

Build Linux kernel.

```bitbake
inherit kernel

DEPENDS = "bc-native bison-native"
KERNEL_DEVICETREE = "vendor/soc-board.dtb"
KERNEL_IMAGETYPE = "Image"
```

**Provided Tasks**: `do_kernel_configme`, `do_kernel_configcheck`, `do_deploy`

### cmake

Build using CMake.

```bitbake
inherit cmake

EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release"
```

**Automatic**: Runs `cmake` + `make`

### autotools

Build using autoconf/automake.

```bitbake
inherit autotools

EXTRA_OECONF = "--enable-feature --disable-docs"
```

**Automatic**: Runs `./configure` + `make` + `make install`

### systemd

Integrate systemd services.

```bitbake
inherit systemd

SYSTEMD_SERVICE:${PN} = "my-service.service"
SYSTEMD_AUTO_ENABLE = "enable"
```

**Automatic**: Installs service, enables in image

### useradd

Create system users and groups.

```bitbake
inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-u 1200 -r -s /bin/false battery"
GROUPADD_PARAM:${PN} = "-g 1200 battery"
```

### update-rc.d

SysV init script management.

```bitbake
inherit update-rc.d

INITSCRIPT_NAME = "battery-manager"
INITSCRIPT_PARAMS = "defaults 90"
```

### pkgconfig

pkg-config support.

```bitbake
inherit pkgconfig

DEPENDS += "libfoo"
```

**Automatic**: Sets `PKG_CONFIG_PATH`

### cargo

Rust/Cargo builds.

```bitbake
inherit cargo

SRC_URI += "crate://crates.io/serde/1.0.152"
```

**Automatic**: Fetches crates, builds with cargo

## BitBake Command Reference

### Build Commands

```bash
# Build specific recipe
bitbake battery-manager

# Build image
bitbake automotive-image

# Build SDK
bitbake -c populate_sdk automotive-image

# Clean recipe
bitbake -c clean battery-manager

# Clean all (including downloads)
bitbake -c cleanall battery-manager

# Force rebuild
bitbake -f battery-manager
```

### Task Execution

```bash
# Execute specific task
bitbake -c compile battery-manager
bitbake -c install battery-manager

# List available tasks
bitbake -c listtasks battery-manager

# Interactive shell (devshell)
bitbake -c devshell battery-manager

# Python shell (pydevshell)
bitbake -c pydevshell battery-manager
```

### Inspection

```bash
# Show recipe variables
bitbake -e battery-manager | grep ^SRC_URI=

# Show dependency graph
bitbake -g automotive-image

# Show runtime dependencies
bitbake -g -u depexp automotive-image

# Show package information
bitbake-layers show-recipes battery-manager

# Show layer information
bitbake-layers show-layers
```

## Package Management

### RPM Commands (on Target)

```bash
# List installed packages
rpm -qa

# Install package
rpm -ivh package.rpm

# Remove package
rpm -e package-name

# Query package info
rpm -qi package-name

# List package files
rpm -ql package-name

# Update all packages
dnf update
```

### DEB Commands (if using deb)

```bash
dpkg -l                    # List packages
dpkg -i package.deb        # Install
dpkg -r package-name       # Remove
apt-get update && apt-get upgrade  # Update
```

### OPKG Commands (if using opkg)

```bash
opkg list                  # List available
opkg list-installed        # List installed
opkg install package       # Install
opkg remove package        # Remove
opkg update                # Update package lists
```

## SDK Commands

### Generate SDK

```bash
# Generate installable SDK
bitbake -c populate_sdk automotive-image

# SDK location
# tmp/deploy/sdk/automotive-linux-glibc-x86_64-automotive-image-cortexa53-toolchain-1.0.sh
```

### Install SDK

```bash
# Run installer
./automotive-linux-*-toolchain-*.sh

# Default install location: /opt/automotive-linux/1.0

# Source SDK environment
source /opt/automotive-linux/1.0/environment-setup-cortexa53-poky-linux
```

### Use SDK

```bash
# After sourcing environment:

# Compile
$CC myapp.c -o myapp

# CMake
cmake -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake ..

# Environment variables set:
# CC, CXX, LD, AR, RANLIB, CFLAGS, LDFLAGS, PKG_CONFIG_PATH
```

## Configuration File Snippets

### local.conf Examples

```python
# Machine selection
MACHINE = "automotive-ecu"

# Multi-machine builds
MACHINE = "automotive-ecu automotive-gateway"

# Parallelism
BB_NUMBER_THREADS = "${@oe.utils.cpu_count()}"
PARALLEL_MAKE = "-j ${@oe.utils.cpu_count()}"

# Shared downloads and sstate
DL_DIR = "/shared/yocto/downloads"
SSTATE_DIR = "/shared/yocto/sstate-cache"

# Disk monitoring
BB_DISKMON_DIRS = "STOPTASKS,${TMPDIR},1G,100K STOPTASKS,${DL_DIR},1G,100K"

# Package format
PACKAGE_CLASSES = "package_rpm"
# or "package_deb" or "package_ipk"

# Extra features for development
EXTRA_IMAGE_FEATURES = "debug-tweaks tools-debug ssh-server-openssh"

# Read-only rootfs
IMAGE_FEATURES += "read-only-rootfs"

# Remove packages
PACKAGE_EXCLUDE = "packageA packageB"

# Kernel provider
PREFERRED_PROVIDER_virtual/kernel = "linux-automotive"

# GCC version
GCCVERSION = "12.%"
```

### bblayers.conf Template

```python
POKY_BBLAYERS_CONF_VERSION = "2"
BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ${TOPDIR}/../poky/meta \
  ${TOPDIR}/../poky/meta-poky \
  ${TOPDIR}/../meta-openembedded/meta-oe \
  ${TOPDIR}/../meta-openembedded/meta-python \
  ${TOPDIR}/../meta-openembedded/meta-networking \
  ${TOPDIR}/../meta-automotive-bsp \
  ${TOPDIR}/../meta-automotive-apps \
  "
```

## Recipe Templates

### Minimal Recipe

```bitbake
SUMMARY = "Description"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=..."

SRC_URI = "file://source.c"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} ${WORKDIR}/source.c -o app
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 app ${D}${bindir}/
}
```

### CMake Recipe Template

```bitbake
SUMMARY = ""
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=..."

SRC_URI = "git://...;protocol=https;branch=main"
SRCREV = "..."
S = "${WORKDIR}/git"

DEPENDS = ""
RDEPENDS:${PN} = ""

inherit cmake

EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release"
```

### systemd Service Recipe

```bitbake
SUMMARY = ""
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=..."

SRC_URI = "file://app \
           file://app.service \
          "

RDEPENDS:${PN} = "systemd"

inherit systemd

SYSTEMD_SERVICE:${PN} = "app.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/app ${D}${bindir}/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/app.service ${D}${systemd_system_unitdir}/
}
```

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Fetch failure | Check `SRC_URI`, network, verify `SRCREV` |
| Patch doesn't apply | Check patch context, base commit |
| Compile error | Check logs in `temp/log.do_compile`, verify `DEPENDS` |
| Missing library | Add to `DEPENDS` (build) or `RDEPENDS` (runtime) |
| Permission denied | Check file modes in `do_install` |
| Package QA errors | Review `FILES:${PN}`, packaging splits |
| Task not found | Check recipe inheritance, task dependencies |
| sstate-cache miss | Clear cache, check `SSTATE_DIR` permissions |

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Yocto developers needing quick reference
