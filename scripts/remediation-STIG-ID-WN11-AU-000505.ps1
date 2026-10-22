<#
.SYNOPSIS
    This PowerShell script ensures that the maximum size of the Windows Security event log is at least 5120000 KB
    (about 5 GB), enough to hold one week of audit records. V2R11 raised this from 1024000 KB, so
    5120000 KB passes both the older and newer audit files.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-20
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-AU-000505
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-AU-000505/

.TESTED ON
    Date(s) Tested  : 2026-10-21
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro 25H2, OS Build 26200.9711 (Azure VM, Cyber Range)
    PowerShell Ver. : 5.1 (Windows PowerShell)

.USAGE
    Run from an elevated PowerShell session (Run as Administrator).
    A reboot before rescanning is recommended but not required.

    Example syntax:
    PS C:\> .\remediation-STIG-ID-WN11-AU-000505.ps1
#>

#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# Required setting
# ---------------------------------------------------------------------------
$RegPath   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security'
$ValueName = 'MaxSize'
$Required  = 5120000

# ---------------------------------------------------------------------------
# Remediation
# ---------------------------------------------------------------------------
try {
    if (-not (Test-Path -Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
        Write-Host "[INFO] Created registry key $RegPath"
    }

    New-ItemProperty -Path $RegPath -Name $ValueName -PropertyType DWord -Value $Required -Force | Out-Null
    Write-Host "[INFO] Set $ValueName = $Required at $RegPath"

    # Apply the new size to the live log right away (wevtutil takes bytes).
    # The policy value above is what the scanner checks; this line just means
    # you do not have to wait for a reboot before the log actually grows.
    $Bytes = [int64]$Required * 1024
    wevtutil sl Security /ms:$Bytes
    Write-Host "[INFO] Live Security log maximum size set to $Bytes bytes"
}
catch {
    Write-Host "[ERROR] Remediation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
$Current = (Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction SilentlyContinue).$ValueName
if ($null -ne $Current -and $Current -ge $Required) {
    Write-Host "[PASS] $ValueName is $Current (required: >= $Required)" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] $ValueName is '$Current' (required: >= $Required)" -ForegroundColor Red
    exit 1
}
