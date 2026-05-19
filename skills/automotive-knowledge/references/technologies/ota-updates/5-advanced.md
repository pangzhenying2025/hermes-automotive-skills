# OTA Updates - Level 5: Advanced Topics

> Audience: SMEs and researchers working on next-generation OTA systems
> Purpose: Advanced OTA patterns, Uptane framework, and emerging approaches

## Uptane Security Framework

Uptane is the de facto security framework for automotive OTA, designed to
be compromise-resilient even when some servers or keys are compromised.

### Uptane Architecture

```
Director Repository          Image Repository
(per-vehicle targeting)      (global package store)
      |                            |
      v                            v
Director Metadata            Image Metadata
(targets.json per VIN)       (targets.json global)
      |                            |
      +---------- Both --------- -+
                   |
                   v
            Primary ECU
            (validates both repos)
                   |
                   v
            Secondary ECUs
            (receive verified images)
```

### Key Uptane Concepts

**Threshold Signatures**: Multiple keys required to sign metadata,
preventing single-key compromise from affecting updates.

**Metadata Expiration**: All metadata has explicit expiration timestamps.
Stale metadata attack is prevented by checking freshness.

**Rollback Protection**: Version numbers in metadata are monotonically
increasing. Rollback to older metadata is rejected.

**Compromise Resilience**: Even if the image repository is compromised,
the director repository provides a second layer of verification tied
to specific VINs.

## Delta Update Generation

### Binary Delta Algorithms

| Algorithm | Compression Ratio | Speed | Use Case |
|-----------|------------------|-------|----------|
| bsdiff | Excellent (95%+) | Slow | Small ECUs |
| xdelta3 | Good (80-90%) | Fast | Large firmware |
| zstd-diff | Good (85-95%) | Very Fast | Streaming |
| courgette | Excellent for x86 | Medium | x86 ECUs |

### Delta Generation Pipeline

```python
class DeltaGenerator:
    def generate(self, source_fw: bytes, target_fw: bytes,
                  algorithm: str = "bsdiff") -> DeltaPackage:
        # Generate binary diff
        delta_data = self._compute_delta(source_fw, target_fw, algorithm)

        # Compress delta
        compressed = zstd.compress(delta_data, level=19)

        # Create package with reconstruction instructions
        package = DeltaPackage(
            source_hash=sha384(source_fw),
            target_hash=sha384(target_fw),
            source_version=extract_version(source_fw),
            target_version=extract_version(target_fw),
            delta_data=compressed,
            algorithm=algorithm,
            compression="zstd"
        )

        # Verify reconstruction
        reconstructed = self._apply_delta(source_fw, delta_data)
        assert sha384(reconstructed) == sha384(target_fw)

        return package
```

## Multi-ECU Atomic Updates

For updates spanning multiple ECUs that must be applied atomically:

```
Phase 1: Distribute
  - Download all packages to all target ECUs
  - Verify all packages on all ECUs
  - Report readiness to orchestrator

Phase 2: Prepare
  - Flash all ECUs to inactive partitions
  - Verify flash integrity on all ECUs
  - All ECUs report "ready to activate"

Phase 3: Activate (atomic)
  - Orchestrator sends "activate" command
  - All ECUs switch to new partition simultaneously
  - All ECUs boot new firmware

Phase 4: Commit or Rollback
  - All ECUs perform self-test
  - If ALL pass: commit (increment counters)
  - If ANY fail: ALL rollback to previous
```

## Fleet Analytics

```python
class OtaAnalytics:
    def compute_campaign_metrics(self, campaign_id: str) -> dict:
        events = self.db.get_campaign_events(campaign_id)

        return {
            "total_vehicles": len(set(e.vin for e in events)),
            "download_success_rate": self._rate(events, "download_complete"),
            "install_success_rate": self._rate(events, "install_complete"),
            "rollback_rate": self._rate(events, "rollback"),
            "mean_download_time_s": self._mean_duration(events, "download"),
            "mean_install_time_s": self._mean_duration(events, "install"),
            "error_distribution": self._error_histogram(events),
            "p95_total_time_s": self._percentile(events, 0.95),
            "geographic_distribution": self._geo_distribution(events)
        }
```

## Summary

Advanced OTA encompasses the Uptane security framework for
compromise-resilient updates, efficient delta generation algorithms,
atomic multi-ECU update orchestration, and fleet-scale analytics.
These techniques are essential for safe, efficient, and scalable
automotive software update management.
