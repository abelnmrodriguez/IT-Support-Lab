# collect-system-diagnostics.ps1
# Collect basic system, network, and event diagnostics into a timestamped folder

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$out = "C:\LabOutputs\Diagnostics-$ts"

New-Item -Path $out -ItemType Directory -Force | Out-Null

# System information
systeminfo > "$out\systeminfo.txt"
msinfo32 /report "$out\msinfo.txt"

# Network information
ipconfig /all > "$out\network_ipconfig.txt"
Get-NetAdapter | Format-List * > "$out\netadapter.txt"
Get-NetIPAddress | Format-List * > "$out\netip.txt"
Get-DnsClientCache | Out-File "$out\dns_cache.txt"

# Processes and services
Get-Process |
    Sort-Object CPU -Descending |
    Select-Object -First 30 |
    Format-Table -AutoSize |
    Out-File "$out\top_processes.txt"

Get-Service |
    Where-Object {$_.Status -ne 'Running'} |
    Out-File "$out\stopped_services.txt"

# Event logs from the last 24 hours
$start = (Get-Date).AddDays(-1)

Get-WinEvent -FilterHashtable @{
    LogName='System'
    StartTime=$start
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
    Out-File "$out\system_events.txt"

Get-WinEvent -FilterHashtable @{
    LogName='Application'
    StartTime=$start
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
    Out-File "$out\application_events.txt"

Write-Host "Diagnostics complete."
Write-Host "Results saved to: $out"
