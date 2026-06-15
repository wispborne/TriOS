## ADDED Requirements

### Requirement: Total VRAM reported in bytes
`getGPUInfo()` SHALL report total GPU VRAM as a byte count, preserving the
existing unit contract consumed by the VRAM warning logic.

#### Scenario: Source reports a non-byte unit
- **WHEN** a source returns VRAM in a unit other than bytes (e.g. `nvidia-smi`
  reports MiB)
- **THEN** the value SHALL be converted to bytes before being returned

### Requirement: Windows VRAM via registry
On Windows, `getGPUInfo()` SHALL read total VRAM from the display-adapter
registry value `HardwareInformation.qwMemorySize` (a 64-bit QWORD) under
`HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`,
not from WMI `AdapterRAM`.

#### Scenario: Card with more than 4 GiB
- **WHEN** the machine has a GPU with more than 4 GiB of VRAM
- **THEN** the reported total SHALL be the true 64-bit size, not capped at
  ~4095 MB

#### Scenario: Multiple display adapters
- **WHEN** more than one adapter subkey exposes a VRAM value
- **THEN** the adapter with the largest VRAM SHALL be selected

#### Scenario: Registry value absent
- **WHEN** no adapter subkey exposes `HardwareInformation.qwMemorySize`
- **THEN** VRAM SHALL be reported as unknown

### Requirement: Linux VRAM via sysfs and nvidia-smi
On Linux, `getGPUInfo()` SHALL obtain total VRAM from the amdgpu sysfs file
`/sys/class/drm/card*/device/mem_info_vram_total` for AMD GPUs, and from
`nvidia-smi --query-gpu=memory.total` for NVIDIA GPUs.

#### Scenario: AMD GPU present
- **WHEN** an amdgpu sysfs `mem_info_vram_total` file exists
- **THEN** its byte value SHALL be read and reported as total VRAM

#### Scenario: NVIDIA GPU present
- **WHEN** `nvidia-smi` is available and reports a memory total
- **THEN** the value SHALL be parsed, converted from MiB to bytes, and reported

#### Scenario: Multiple GPU sources
- **WHEN** more than one source returns a value
- **THEN** the largest VRAM value SHALL be selected

#### Scenario: No usable source
- **WHEN** no amdgpu sysfs file exists and `nvidia-smi` is unavailable or
  returns nothing (e.g. an Intel integrated GPU)
- **THEN** VRAM SHALL be reported as unknown

### Requirement: Unknown VRAM suppresses the warning
When total VRAM cannot be reliably determined, the VRAM warning logic SHALL NOT
emit a "not enough VRAM" warning.

#### Scenario: VRAM unknown
- **WHEN** `getGPUInfo()` cannot determine total VRAM
- **THEN** no "you may not have enough free VRAM" warning SHALL be shown

#### Scenario: VRAM known and insufficient
- **WHEN** total VRAM is known and is less than the estimated requirement
- **THEN** the warning SHALL be shown as before

### Requirement: VRAM usage bar on the estimator page
The VRAM Estimator page SHALL display total VRAM with a progress bar showing
estimated usage against the total, in the region shared by both chart types so
it is visible for both the bar and pie views, only when the total VRAM is known.

#### Scenario: Total VRAM known, bar chart
- **WHEN** total VRAM is known and the bar chart is shown
- **THEN** the page SHALL show the total VRAM and a progress bar whose fill is
  the estimated VRAM usage (the same estimate used by the warning: deduped mod
  bytes plus the vanilla baseline) divided by the total

#### Scenario: Total VRAM known, pie chart
- **WHEN** total VRAM is known and the pie chart is shown
- **THEN** the same total VRAM and progress bar SHALL be shown

#### Scenario: Total VRAM unknown
- **WHEN** total VRAM is unknown
- **THEN** the page SHALL NOT show the total or the progress bar

#### Scenario: Estimate exceeds total
- **WHEN** the estimated usage is greater than the total VRAM
- **THEN** the progress bar SHALL be clamped to full rather than overflowing
