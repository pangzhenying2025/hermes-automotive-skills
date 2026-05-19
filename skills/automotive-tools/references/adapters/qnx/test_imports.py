#!/usr/bin/env python3
"""
QNX Adapters Import Test

Verifies all QNX adapters can be imported successfully.
"""

import sys
from pathlib import Path

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))


def test_imports():
    """Test all QNX adapter imports"""
    print("Testing QNX adapter imports...")
    print("=" * 60)

    try:
        # Test main package
        print("\n[1/5] Testing package import...")
        from tools.adapters.qnx import (
            MomenticsAdapter,
            QnxSdpAdapter,
            ProcessManagerAdapter,
            QnxBuildAdapter
        )
        print("✓ Package imports successful")

        # Test Momentics enums and classes
        print("\n[2/5] Testing Momentics adapter...")
        from tools.adapters.qnx.momentics_adapter import (
            ProjectType,
            BuildVariant,
            TargetArchitecture,
            MomenticsConfig,
            ProjectConfig,
            TargetConfig
        )
        print("✓ MomenticsAdapter classes imported")

        # Test SDP enums and classes
        print("\n[3/5] Testing SDP adapter...")
        from tools.adapters.qnx.qnx_sdp_adapter import (
            QnxVersion,
            FilesystemType,
            BspConfig,
            IfsConfig
        )
        print("✓ QnxSdpAdapter classes imported")

        # Test Process Manager enums and classes
        print("\n[4/5] Testing Process Manager adapter...")
        from tools.adapters.qnx.process_manager_adapter import (
            ProcessState,
            ProcessPriority,
            ProcessInfo,
            MemoryInfo
        )
        print("✓ ProcessManagerAdapter classes imported")

        # Test Build adapter enums and classes
        print("\n[5/5] Testing Build adapter...")
        from tools.adapters.qnx.qnx_build_adapter import (
            Architecture,
            OptimizationLevel,
            StandardVersion,
            BuildConfig,
            CompilerFlags,
            LinkerFlags
        )
        print("✓ QnxBuildAdapter classes imported")

        print("\n" + "=" * 60)
        print("✅ All imports successful!")
        print("QNX adapters are ready to use.")
        print("=" * 60)

        return True

    except ImportError as e:
        print(f"\n❌ Import failed: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return False


def show_adapter_info():
    """Show information about available adapters"""
    print("\n" + "=" * 60)
    print("QNX Adapters Available:")
    print("=" * 60)

    from tools.adapters.qnx import (
        MomenticsAdapter,
        QnxSdpAdapter,
        ProcessManagerAdapter,
        QnxBuildAdapter
    )

    adapters = [
        ("MomenticsAdapter", MomenticsAdapter, "QNX Momentics IDE automation"),
        ("QnxSdpAdapter", QnxSdpAdapter, "QNX SDP utilities (mkifs, mkxfs, etc)"),
        ("ProcessManagerAdapter", ProcessManagerAdapter, "Remote process control"),
        ("QnxBuildAdapter", QnxBuildAdapter, "Cross-compilation with qcc")
    ]

    for name, adapter_class, description in adapters:
        print(f"\n{name}")
        print(f"  Description: {description}")
        print(f"  Class: {adapter_class.__name__}")
        print(f"  Module: {adapter_class.__module__}")

    print("\n" + "=" * 60)


if __name__ == "__main__":
    success = test_imports()

    if success:
        show_adapter_info()
        sys.exit(0)
    else:
        sys.exit(1)
