<#
.SYNOPSIS
    This PowerShell script enables PowerShell Script Block Logging (event ID 4104 in
    Microsoft-Windows-PowerShell/Operational), so the full text of every script block that runs is logged.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-20
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-CC-000326
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-CC-000326/

.TESTED ON
    Date(s) Tested  : 2026-10-21
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro 25H2, OS Build 26200.9711 (Azure VM, Cyber Range)
    PowerShell Ver. : 5.1 (Windows PowerShell)

.USAGE
    Run from an elevated PowerShell session (Run as Administrator).

    Example syntax:
    PS C:\> .\remediation-STIG-ID-WN11-CC-000326.ps1
#>

#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# Required setting
# ---------------------------------------------------------------------------
$RegPath   = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
$ValueName = 'EnableScriptBlockLogging'
$Required  = 1

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
}
catch {
    Write-Host "[ERROR] Remediation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
$Current = (Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction SilentlyContinue).$ValueName
if ($null -ne $Current -and $Current -eq $Required) {
    Write-Host "[PASS] $ValueName is $Current (required: $Required)" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] $ValueName is '$Current' (required: $Required)" -ForegroundColor Red
    exit 1
}
