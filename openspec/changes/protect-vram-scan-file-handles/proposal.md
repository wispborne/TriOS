# Protect VRAM scans from file-handle exhaustion

Status: ready-for-agent

VRAM scans currently permit 2,000 image reads per worker. Four workers can exceed a Linux process's open-file limit and leave native graphics code unable to create synchronization handles.

Use a small scan-wide read budget, divide it among workers, and reduce it on Linux according to the process's current open files and limit. Refuse a scan when there is insufficient room. Replace polling waits with queued permits.

This prevents excessive scan concurrency. It does not confirm the cause of feedback TRIOS-2B0 or guarantee safety if other app work exhausts handles during the scan.

## Validation

The VRAM test set passed 137 tests. The additional worker-pool test passed with a one-handle budget in sequential and multithreaded modes. Targeted static analysis passed with six existing style notices. The new tests demonstrated the old excessive default, continued queued reads after cancellation, and repeated waiting log lines before implementation.

The native Linux crash has not been reproduced or verified as fixed. The selected read budget and worker allocation now appear in info-level logs before mod scans.

File-limit failures now remain visible in an error banner on the estimator page until another scan starts. The banner suggests restarting TriOS, then restarting the computer if that does not help; numerical diagnostics remain in the log. The 16 targeted budget, worker, and manager tests pass, and analysis of the updated error handling and page reports no issues.
