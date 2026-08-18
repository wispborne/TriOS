# Where a running process's resident memory actually is.
#
# RSS is the pages of a process that are in physical memory right now. This asks
# Windows for that exact list of pages, then asks what each page belongs to, and
# adds them up per kind — the executable and DLLs mapped in, files mapped in,
# and plain allocated memory, with the plain memory split by which module
# allocated near it where that can be told.
#
# Usage: native-memory.ps1 -ProcessName TriOS

param(
    [Parameter(Mandatory = $true)][string]$ProcessName
)

$signature = @'
using System;
using System.Runtime.InteropServices;

public static class Peek {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int access, bool inherit, int pid);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr handle);

    [StructLayout(LayoutKind.Sequential)]
    public struct MemoryBasicInformation {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint AllocationProtect;
        public short PartitionId;
        public IntPtr RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualQueryEx(
        IntPtr process, IntPtr address, out MemoryBasicInformation info, IntPtr length);

    [DllImport("psapi.dll", SetLastError = true)]
    public static extern bool QueryWorkingSet(IntPtr process, IntPtr buffer, int size);

    [DllImport("psapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern int GetMappedFileNameW(
        IntPtr process, IntPtr address, System.Text.StringBuilder name, int size);
}
'@

Add-Type -TypeDefinition $signature -ErrorAction Stop

$process = Get-Process -Name $ProcessName -ErrorAction Stop
if ($process -is [array]) { $process = $process[0] }

# PROCESS_QUERY_INFORMATION | PROCESS_VM_READ
$handle = [Peek]::OpenProcess(0x0410, $false, $process.Id)
if ($handle -eq [IntPtr]::Zero) { throw "Could not open process $($process.Id)." }

try {
    # Ask for the working set. The first slot is the count, so grow the buffer
    # until it fits.
    $slots = 1024 * 1024
    while ($true) {
        $bytes = ($slots + 1) * [IntPtr]::Size
        $buffer = [Runtime.InteropServices.Marshal]::AllocHGlobal($bytes)
        $ok = [Peek]::QueryWorkingSet($handle, $buffer, $bytes)
        if ($ok) { break }
        [Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
        $slots = $slots * 2
        if ($slots -gt 32 * 1024 * 1024) { throw "Working set too big to read." }
    }

    $count = [Runtime.InteropServices.Marshal]::ReadIntPtr($buffer).ToInt64()
    Write-Host "$($process.ProcessName) ($($process.Id)): $count resident pages, $([math]::Round($count * 4096 / 1MB, 1)) MB"
    Write-Host ""

    # Every page in the working set, as its region's allocation base.
    $pages = New-Object 'System.Collections.Generic.List[int64]'
    for ($i = 1; $i -le $count; $i++) {
        $entry = [Runtime.InteropServices.Marshal]::ReadIntPtr($buffer, $i * [IntPtr]::Size).ToInt64()
        # The low twelve bits are flags, not address.
        $pages.Add($entry -band -4096)
    }
    [Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)

    # Group the pages by the block they were allocated in, so one VirtualQueryEx
    # per block answers for all of them.
    $residentByBlock = @{}
    $infoSize = [IntPtr][Runtime.InteropServices.Marshal]::SizeOf([type][Peek+MemoryBasicInformation])
    $blockOf = @{}
    foreach ($page in $pages) {
        $block = $blockOf[$page]
        if ($null -eq $block) {
            $info = New-Object 'Peek+MemoryBasicInformation'
            $written = [Peek]::VirtualQueryEx($handle, [IntPtr]$page, [ref]$info, $infoSize)
            if ($written -eq [IntPtr]::Zero) { continue }
            $base = $info.AllocationBase.ToInt64()
            if ($base -eq 0) { $base = $page }
            $block = @{ Base = $base; Type = $info.Type }
            $blockOf[$page] = $block
        }
        $key = "$($block.Type)|$($block.Base)"
        if ($residentByBlock.ContainsKey($key)) {
            $residentByBlock[$key] += 4096
        } else {
            $residentByBlock[$key] = 4096
        }
    }

    # Name each block: a module if one starts there, otherwise the mapped file,
    # otherwise plain allocated memory.
    $moduleAt = @{}
    foreach ($module in $process.Modules) {
        $moduleAt[$module.BaseAddress.ToInt64()] = $module.ModuleName
    }

    $kindNames = @{ 0x1000000 = 'image'; 0x40000 = 'mapped file'; 0x20000 = 'private' }

    $rows = foreach ($key in $residentByBlock.Keys) {
        $parts = $key.Split('|')
        $type = [int]$parts[0]
        $base = [int64]$parts[1]
        $name = $moduleAt[$base]
        if (-not $name -and $type -ne 0x20000) {
            $sb = New-Object System.Text.StringBuilder 260
            if ([Peek]::GetMappedFileNameW($handle, [IntPtr]$base, $sb, 260) -gt 0) {
                $name = Split-Path -Leaf $sb.ToString()
            }
        }
        if (-not $name) { $name = '(anonymous)' }
        $info = New-Object 'Peek+MemoryBasicInformation'
        [void][Peek]::VirtualQueryEx($handle, [IntPtr]$base, [ref]$info, $infoSize)
        [pscustomobject]@{
            Kind    = if ($kindNames.ContainsKey($type)) { $kindNames[$type] } else { "type $type" }
            Name    = $name
            MB      = [math]::Round($residentByBlock[$key] / 1MB, 2)
            Address = '0x{0:X}' -f $base
            Protect = '0x{0:X}' -f $info.AllocationProtect
            Reserved = [math]::Round($info.RegionSize.ToInt64() / 1MB, 2)
        }
    }

    Write-Host "By kind"
    $rows | Group-Object Kind | ForEach-Object {
        $total = ($_.Group | Measure-Object MB -Sum).Sum
        "{0,-14} {1,8:N1} MB  ({2} blocks)" -f $_.Name, $total, $_.Count
    }

    Write-Host ""
    Write-Host "Private blocks by size"
    $private = $rows | Where-Object Kind -eq 'private'
    $bands = @(
        @{ Name = '8 MB and up';  Test = { $_.MB -ge 8 } },
        @{ Name = '1 to 8 MB';    Test = { $_.MB -ge 1 -and $_.MB -lt 8 } },
        @{ Name = '256 KB to 1 MB'; Test = { $_.MB -ge 0.25 -and $_.MB -lt 1 } },
        @{ Name = 'under 256 KB'; Test = { $_.MB -lt 0.25 } }
    )
    foreach ($band in $bands) {
        $inBand = $private | Where-Object $band.Test
        $total = ($inBand | Measure-Object MB -Sum).Sum
        "{0,-16} {1,8:N1} MB  ({2} blocks)" -f $band.Name, $total, $inBand.Count
    }

    Write-Host ""
    Write-Host "Biggest blocks"
    $rows | Sort-Object MB -Descending | Select-Object -First 30 | ForEach-Object {
        "{0,8:N1} MB  {1,-12} {2,-18} at {3}  protect {4}" -f
            $_.MB, $_.Kind, $_.Name, $_.Address, $_.Protect
    }

    Write-Host ""
    Write-Host "Nearest module below each big private block"
    $moduleRanges = foreach ($module in $process.Modules) {
        [pscustomobject]@{
            Name  = $module.ModuleName
            Start = $module.BaseAddress.ToInt64()
            End   = $module.BaseAddress.ToInt64() + $module.ModuleMemorySize
        }
    }
    $rows | Where-Object { $_.Kind -eq 'private' -and $_.MB -ge 4 } |
        Sort-Object MB -Descending | ForEach-Object {
            $address = [Convert]::ToInt64($_.Address.Substring(2), 16)
            $below = $moduleRanges | Where-Object { $_.Start -lt $address } |
                Sort-Object Start -Descending | Select-Object -First 1
            $gap = if ($below) { [math]::Round(($address - $below.End) / 1MB, 1) } else { 0 }
            "{0,8:N1} MB at {1}  nearest module below: {2} ({3} MB away)" -f
                $_.MB, $_.Address, $below.Name, $gap
        }
}
finally {
    [void][Peek]::CloseHandle($handle)
}
