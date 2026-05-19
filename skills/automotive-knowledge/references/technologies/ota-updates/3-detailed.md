# OTA Updates - Level 3: Detailed Implementation

> Audience: Developers and testers implementing OTA systems
> Purpose: Code examples, protocols, and implementation patterns

## Update Package Format

```c
/* OTA package structure */
#define OTA_MAGIC 0x4F544155  /* "OTAU" */

typedef struct __attribute__((packed)) {
    uint32_t magic;
    uint16_t format_version;
    uint16_t header_size;
    uint32_t payload_size;
    uint8_t  target_ecu_id[16];
    uint32_t target_hw_version;
    uint32_t source_sw_version;
    uint32_t target_sw_version;
    uint8_t  payload_sha384[48];
    uint8_t  header_signature[96];
    uint8_t  payload_signature[96];
    uint32_t monotonic_counter;
    uint8_t  compression_type;   /* 0=none, 1=zstd, 2=lz4 */
    uint8_t  update_type;        /* 0=full, 1=delta */
    uint16_t dependencies_count;
} OtaPackageHeader_t;
```

## Download Manager Implementation

```c
/* Resumable download with integrity verification */
typedef struct {
    char url[256];
    uint32_t total_size;
    uint32_t downloaded_size;
    uint32_t block_size;
    Sha384Context_t hash_ctx;
    uint8_t expected_hash[48];
    DownloadState_t state;
    uint32_t retry_count;
    uint32_t max_retries;
} DownloadSession_t;

OtaError_t download_block(DownloadSession_t* session) {
    uint8_t buffer[DOWNLOAD_BLOCK_SIZE];

    /* HTTP Range request for resume support */
    HttpResponse_t resp = http_get_range(
        session->url,
        session->downloaded_size,
        session->downloaded_size + session->block_size - 1,
        buffer, &actual_size);

    if (resp.status != 200 && resp.status != 206) {
        session->retry_count++;
        return (session->retry_count < session->max_retries)
            ? OTA_ERR_RETRY : OTA_ERR_DOWNLOAD_FAILED;
    }

    /* Update hash incrementally */
    sha384_update(&session->hash_ctx, buffer, actual_size);

    /* Write to staging storage */
    storage_write(PARTITION_STAGING,
                  session->downloaded_size, buffer, actual_size);

    session->downloaded_size += actual_size;
    session->retry_count = 0;

    /* Check if complete */
    if (session->downloaded_size >= session->total_size) {
        uint8_t final_hash[48];
        sha384_final(&session->hash_ctx, final_hash);
        if (!constant_time_compare(final_hash, session->expected_hash, 48)) {
            return OTA_ERR_HASH_MISMATCH;
        }
        session->state = DOWNLOAD_COMPLETE;
    }

    return OTA_OK;
}
```

## ECU Update Orchestration

```python
# Multi-ECU update orchestrator
class UpdateOrchestrator:
    def __init__(self, ecu_manager, vehicle_state):
        self.ecu_mgr = ecu_manager
        self.vehicle = vehicle_state
        self.update_plan = []

    def plan_update(self, campaign: Campaign) -> UpdatePlan:
        plan = UpdatePlan()

        # Resolve dependencies and ordering
        for package in campaign.packages:
            ecu = self.ecu_mgr.get_ecu(package.target_ecu_id)

            # Verify preconditions
            if ecu.sw_version < package.source_sw_version:
                raise PreconditionError(f"ECU {ecu.id} version mismatch")

            plan.add_step(UpdateStep(
                ecu=ecu,
                package=package,
                priority=ecu.safety_level,
                requires_ignition_off=ecu.is_safety_critical
            ))

        # Sort by dependency order
        plan.resolve_dependencies()
        return plan

    def execute_plan(self, plan: UpdatePlan):
        for step in plan.steps:
            # Pre-install checks
            if step.requires_ignition_off:
                if self.vehicle.ignition_state != "OFF":
                    raise SafetyError("Ignition must be off")

            if self.vehicle.battery_soc < 30:
                raise ResourceError("Battery SOC too low for update")

            # Install
            result = self._install_ecu(step)
            if result != UpdateResult.SUCCESS:
                self._rollback_plan(plan, step)
                raise InstallError(f"Failed at step {step}")

            # Post-install verification
            if not self._verify_ecu(step.ecu):
                self._rollback_plan(plan, step)
                raise VerifyError(f"Verification failed for {step.ecu}")

    def _install_ecu(self, step: UpdateStep) -> UpdateResult:
        ecu = step.ecu

        # Flash to inactive partition
        ecu.begin_update(step.package)
        while not ecu.update_complete:
            progress = ecu.get_progress()
            self._report_progress(step, progress)
            time.sleep(0.5)

        return ecu.get_update_result()
```

## Rollback Implementation

```c
/* Automatic rollback on boot failure */
typedef struct {
    uint8_t active_partition;    /* 0 = A, 1 = B */
    uint8_t boot_attempts;
    uint8_t max_boot_attempts;
    uint32_t last_successful_boot_time;
    uint32_t sw_version_a;
    uint32_t sw_version_b;
    bool commit_pending;
} BootManager_t;

/* Called by bootloader on every boot */
BootAction_t boot_manager_decide(BootManager_t* bm) {
    bm->boot_attempts++;

    if (bm->boot_attempts > bm->max_boot_attempts) {
        /* Too many failed boots - rollback */
        bm->active_partition = 1 - bm->active_partition;
        bm->boot_attempts = 0;
        bm->commit_pending = false;
        log_event(EVT_ROLLBACK_TRIGGERED);
        return BOOT_ROLLBACK;
    }

    if (bm->commit_pending) {
        return BOOT_PENDING_COMMIT;
    }

    return BOOT_NORMAL;
}

/* Called by application after successful self-test */
void boot_manager_commit(BootManager_t* bm) {
    bm->boot_attempts = 0;
    bm->commit_pending = false;
    bm->last_successful_boot_time = get_time_s();
    /* Increment monotonic counter to prevent rollback attack */
    increment_secure_counter(bm->active_partition == 0
        ? bm->sw_version_a : bm->sw_version_b);
    log_event(EVT_UPDATE_COMMITTED);
}
```

## Summary

OTA implementation requires robust download management with resume support,
multi-ECU orchestration with dependency resolution, comprehensive verification
at every stage, and automatic rollback for failed updates. The system must
handle partial failures gracefully while maintaining vehicle safety.
