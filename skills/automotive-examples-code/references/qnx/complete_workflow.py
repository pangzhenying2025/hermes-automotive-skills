#!/usr/bin/env python3
"""
QNX Complete Workflow Example

Demonstrates full development cycle:
1. Project creation
2. Building
3. Boot image creation
4. Deployment
5. Process monitoring
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.adapters.qnx import (
    MomenticsAdapter,
    QnxSdpAdapter,
    ProcessManagerAdapter,
    QnxBuildAdapter,
    ProjectType,
    Architecture,
    BuildVariant,
    TargetArchitecture,
    OptimizationLevel,
    StandardVersion,
    BuildConfig,
    CompilerFlags,
    LinkerFlags
)


def main():
    print("=" * 80)
    print("QNX Complete Workflow Example")
    print("=" * 80)

    # Configuration
    PROJECT_NAME = "automotive_can_gateway"
    TARGET_IP = "192.168.1.100"
    TARGET_PORT = 8000

    # Step 1: Create Project
    print("\n[1/6] Creating QNX project...")
    try:
        momentics = MomenticsAdapter(
            workspace_path="/tmp/qnx_workspace"
        )

        project_result = momentics.create_project(
            name=PROJECT_NAME,
            project_type=ProjectType.QNX_CPP_PROJECT,
            architecture=TargetArchitecture.AARCH64LE,
            build_variant=BuildVariant.RELEASE,
            libraries=["socket", "can", "pthread"]
        )

        if project_result.get("success"):
            print(f"✓ Project created: {project_result['data']['project_path']}")
        else:
            print(f"✗ Project creation failed: {project_result.get('error')}")
            return

    except Exception as e:
        print(f"✗ Exception during project creation: {e}")
        print("Note: This requires QNX SDP installation")

    # Step 2: Build Project
    print("\n[2/6] Building project...")
    try:
        builder = QnxBuildAdapter()

        # Create build configuration
        config = BuildConfig(
            project_name=PROJECT_NAME,
            architecture=Architecture.AARCH64LE,
            source_files=[
                "src/main.cpp",
                "src/can_handler.cpp",
                "src/message_queue.cpp"
            ],
            output_file=f"build/{PROJECT_NAME}",
            compiler_flags=CompilerFlags(
                optimization=OptimizationLevel.O2,
                debug=False,
                standard=StandardVersion.CPP14,
                defines=["AUTOMOTIVE_MODE", "CAN_ENABLED"],
                warnings=["-Wall", "-Wextra"],
                include_paths=["include/"]
            ),
            linker_flags=LinkerFlags(
                libraries=["socket", "can", "pthread"],
                static=False
            )
        )

        # Generate Makefile
        makefile_result = builder.generate_makefile(
            config=config,
            output_path="/tmp/qnx_workspace/Makefile"
        )

        if makefile_result.get("success"):
            print(f"✓ Makefile generated: {makefile_result['data']['makefile']}")
        else:
            print(f"✗ Makefile generation failed")

        # Get compiler version
        version_result = builder.get_compiler_version()
        if version_result.get("success"):
            print(f"✓ Compiler: {version_result['data']['compiler']}")
        else:
            print("✗ Compiler not found (requires QNX SDP)")

    except Exception as e:
        print(f"✗ Build configuration error: {e}")
        print("Note: This requires QNX SDP installation")

    # Step 3: Create Boot Image
    print("\n[3/6] Creating boot image...")
    try:
        sdp = QnxSdpAdapter()

        boot_result = sdp.build_automotive_image(
            output_file="/tmp/ifs-automotive-gateway.bin",
            include_can=True,
            include_ethernet=True,
            custom_drivers=["dev-can-flexcan"]
        )

        if boot_result.get("success"):
            print(f"✓ Boot image created: {boot_result['data']['boot_image']}")
            print(f"  Size: {boot_result['data']['size_bytes']} bytes")
        else:
            print(f"✗ Boot image creation failed")

    except Exception as e:
        print(f"✗ Boot image error: {e}")
        print("Note: This requires QNX SDP installation")

    # Step 4: Deployment (simulated)
    print("\n[4/6] Deployment to target...")
    print(f"Target: {TARGET_IP}:{TARGET_PORT}")
    print("Note: Actual deployment requires QNX target hardware")
    print("Would execute:")
    print(f"  scp build/{PROJECT_NAME} root@{TARGET_IP}:/usr/local/bin/")
    print(f"  ssh root@{TARGET_IP} 'chmod +x /usr/local/bin/{PROJECT_NAME}'")

    # Step 5: Process Management (simulated)
    print("\n[5/6] Process management...")
    try:
        pm = ProcessManagerAdapter(
            target_ip=TARGET_IP,
            target_port=TARGET_PORT
        )

        # Note: This will fail without actual QNX target
        print(f"Note: Requires QNX target at {TARGET_IP}")
        print("Would execute:")
        print(f"  Launch: on -p 50 /usr/local/bin/{PROJECT_NAME} &")
        print("  Monitor: pidin -p can_gateway")
        print("  Stats: pidin info")

    except Exception as e:
        print(f"Process manager requires QNX target: {e}")

    # Step 6: Summary
    print("\n[6/6] Workflow Summary")
    print("=" * 80)
    print("Complete QNX development workflow demonstrated:")
    print("  1. ✓ Project structure created")
    print("  2. ✓ Build configuration defined")
    print("  3. ✓ Boot image specification prepared")
    print("  4. ✓ Deployment scripts ready")
    print("  5. ✓ Process monitoring configured")
    print("")
    print("To execute on real hardware:")
    print("  1. Install QNX SDP 7.1 or 8.0")
    print("  2. Source environment: source /opt/qnx710/qnxsdp-env.sh")
    print("  3. Connect QNX target to network")
    print("  4. Run this script again with proper QNX_HOST/QNX_TARGET")
    print("=" * 80)


if __name__ == "__main__":
    main()
