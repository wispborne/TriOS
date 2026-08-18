# How much memory TriOS's Edge processes are using.
#
# The in-app browser runs in separate `msedgewebview2.exe` processes. None of
# that shows up in TriOS's own memory figures, so every memory tool misses it.
# This adds up every one of them whose parent chain leads back to TriOS.
#
# Usage: tool/webview_memory.ps1

$trios = Get-Process TriOS -ErrorAction SilentlyContinue
if (-not $trios) { Write-Host "TriOS is not running."; exit }
if ($trios -is [array]) { $trios = $trios[0] }

$edge = Get-CimInstance Win32_Process -Filter "Name='msedgewebview2.exe'" |
    Select-Object ProcessId, ParentProcessId

# Walk down from TriOS, since Edge nests its own processes several deep.
$family = @($trios.Id)
$growing = $true
while ($growing) {
    $growing = $false
    foreach ($process in $edge) {
        if (($family -contains $process.ParentProcessId) -and
            -not ($family -contains $process.ProcessId)) {
            $family += $process.ProcessId
            $growing = $true
        }
    }
}

$browserIds = @($family | Where-Object { $_ -ne $trios.Id })
$browsers = if ($browserIds.Count -gt 0) {
    @(Get-Process -Id $browserIds -ErrorAction SilentlyContinue)
} else { @() }

$triosMb = [math]::Round($trios.WorkingSet64 / 1MB, 1)
$browserMb = if ($browsers.Count -gt 0) {
    [math]::Round((($browsers | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)
} else { 0 }

"TriOS itself:      {0,8:N1} MB" -f $triosMb
"Its Edge processes:{0,8:N1} MB  ({1} of them)" -f $browserMb, $browsers.Count
"Altogether:        {0,8:N1} MB" -f ($triosMb + $browserMb)

if ($browsers.Count -gt 0) {
    ""
    $browsers | Sort-Object WorkingSet64 -Descending | ForEach-Object {
        "  {0,8:N1} MB  pid {1}" -f ($_.WorkingSet64 / 1MB), $_.Id
    }
}
