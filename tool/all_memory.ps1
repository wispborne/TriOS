# Everything TriOS costs the machine, in one place.
#
# Its own memory is only part of the story. The in-app browser runs in separate
# Edge processes, and the sprites and text it draws sit in graphics memory.
# Neither shows up in a Dart memory tool, and between them they were once bigger
# than everything the Dart heap held.
#
# Usage: tool/all_memory.ps1

$trios = Get-Process TriOS -ErrorAction SilentlyContinue
if (-not $trios) { Write-Host "TriOS is not running."; exit }
if ($trios -is [array]) { $trios = $trios[0] }

$triosMb = [math]::Round($trios.WorkingSet64 / 1MB, 1)

# Every process descended from TriOS, however deeply nested.
$everything = Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId
$family = @($trios.Id)
$growing = $true
while ($growing) {
    $growing = $false
    foreach ($process in $everything) {
        if (($family -contains $process.ParentProcessId) -and
            -not ($family -contains $process.ProcessId)) {
            $family += $process.ProcessId
            $growing = $true
        }
    }
}
$childIds = @($family | Where-Object { $_ -ne $trios.Id })
$children = if ($childIds.Count -gt 0) {
    @(Get-Process -Id $childIds -ErrorAction SilentlyContinue)
} else { @() }
$childMb = if ($children.Count -gt 0) {
    [math]::Round((($children | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)
} else { 0 }

# Graphics memory. Windows reports this per process, in its own counter.
$gpuMb = 0
try {
    $samples = (Get-Counter "\GPU Process Memory(*)\Local Usage" -ErrorAction Stop).CounterSamples
    $mine = $samples | Where-Object {
        $_.InstanceName -match "pid_$($trios.Id)_" -and $_.CookedValue -gt 0
    }
    $gpuMb = [math]::Round((($mine | Measure-Object CookedValue -Sum).Sum) / 1MB, 1)
} catch {
    Write-Host "Could not read the graphics memory counter: $_"
}

"TriOS itself:      {0,8:N1} MB" -f $triosMb
"Child processes:   {0,8:N1} MB  ({1} of them)" -f $childMb, $children.Count
"Graphics memory:   {0,8:N1} MB" -f $gpuMb
"Altogether:        {0,8:N1} MB" -f ($triosMb + $childMb + $gpuMb)

if ($children.Count -gt 0) {
    ""
    $children | Sort-Object WorkingSet64 -Descending | ForEach-Object {
        "  {0,8:N1} MB  {1} (pid {2})" -f ($_.WorkingSet64 / 1MB), $_.ProcessName, $_.Id
    }
}
