# Design

Add VramScanFileBudget to own the concurrency policy. Cap header reads at 64 across a scan. On Linux, read /proc/self/limits and count /proc/self/fd entries before scanning. Reserve 64 handles for unrelated app work. If these diagnostics are unavailable, use the conservative cap. If the diagnostics show no remaining capacity after the reserve, fail before starting the scan.

Divide the budget among the actual number of workers, reducing worker count when the budget is smaller than the configured pool. Sequential scans use the whole budget. Keep the existing maxFileHandles parameter as an optional lower scan-wide cap.

Use queued permits in scanOneMod so waiting files do not poll or generate repeated buffered log lines. Validate per-mod limits and check cancellation after obtaining a permit. Keep image readers' existing finally-based close calls.

Test Linux limit parsing, reserve calculations, worker division, actual scan concurrency, failure recovery, invalid limits, and cancellation while waiting. Run the existing VRAM tests and targeted analysis. Native Linux crash verification remains with the reporter.

Keep scan errors in a separate in-memory Riverpod notifier. The estimator page shows a persistent error banner until the next scan starts. File-limit errors explain that scanning cannot start safely and suggest restarting TriOS, then restarting the computer if that does not help. Keep numerical diagnostics in the log. Do not report user cancellation as a failure.
