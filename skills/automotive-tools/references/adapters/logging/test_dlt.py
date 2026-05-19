#!/usr/bin/env python3
"""
Quick test script for DLT adapter functionality.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from tools.adapters.logging import (
    DLTAdapter,
    DLTViewerAdapter,
    DLTFilter,
    DLTLogLevel
)


def test_basic_logging():
    """Test basic logging functionality."""
    print("Test 1: Basic Logging")
    print("-" * 40)

    dlt = DLTAdapter(
        app_id="TEST",
        context_id="DEMO",
        ecu_id="ECU1",
        use_network=False,
        log_file="/tmp/test_dlt.dlt"
    )

    dlt.log_info("Test started")
    dlt.log_error("Test error", code=123)
    dlt.log_debug("Test debug", value=456)
    dlt.close()

    print("✓ Logs written to /tmp/test_dlt.dlt")
    print()


def test_parsing():
    """Test log parsing."""
    print("Test 2: Log Parsing")
    print("-" * 40)

    viewer = DLTViewerAdapter("/tmp/test_dlt.dlt")
    entries = viewer.get_entries()

    print(f"Found {len(entries)} log entries:")
    for entry in entries:
        print(f"  [{entry.log_level.name:8s}] {entry.message}")

    stats = viewer.get_statistics()
    print(f"\nStatistics:")
    print(f"  Total entries: {stats['total_entries']}")
    print(f"  App IDs: {stats['app_ids']}")
    print(f"  Context IDs: {stats['context_ids']}")
    print(f"  Log levels: {stats['log_levels']}")
    print()


def test_filtering():
    """Test log filtering."""
    print("Test 3: Log Filtering")
    print("-" * 40)

    viewer = DLTViewerAdapter("/tmp/test_dlt.dlt")

    # Filter errors only
    error_filter = DLTFilter(min_level=DLTLogLevel.ERROR)
    errors = viewer.get_entries(error_filter)

    print(f"Error entries: {len(errors)}")
    for entry in errors:
        print(f"  {entry}")
    print()


def test_export():
    """Test log export."""
    print("Test 4: Log Export")
    print("-" * 40)

    viewer = DLTViewerAdapter("/tmp/test_dlt.dlt")

    viewer.export_csv("/tmp/test_dlt.csv")
    print("✓ Exported to CSV: /tmp/test_dlt.csv")

    viewer.export_json("/tmp/test_dlt.json", pretty=True)
    print("✓ Exported to JSON: /tmp/test_dlt.json")
    print()


def main():
    """Run all tests."""
    print("\n" + "=" * 40)
    print("DLT Adapter Test Suite")
    print("=" * 40 + "\n")

    try:
        test_basic_logging()
        test_parsing()
        test_filtering()
        test_export()

        print("=" * 40)
        print("All tests passed!")
        print("=" * 40)

    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
