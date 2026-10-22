<#
.SYNOPSIS
    This PowerShell script stops and disables the Secondary Logon service (seclogon), which powers
    'Run as different user' and can be abused to launch processes under other credentials.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-21
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-00-000175
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-00-000175/

.TESTED ON
    Date(s) Tested  : 2026-10-21
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro 25H2, OS Build 26200.9711 (Azure VM, Cyber Range)
    PowerShell Ver. : 5.1 (Windows PowerShell)

.USAGE
    Run from an elevated PowerShell session (Run as Administrator).

    Example syntax:
    PS C:\> .\remediation-STIG-ID-WN11-00-000175.ps1
#>

#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# Required setting
# ---------------------------------------------------------------------------
$ServiceName = 'seclogon'

# ---------------------------------------------------------------------------
# Remediation
# Order matters: set Disabled FIRST (this is what the STIG checks), then try
# to stop the running service. On some Windows 11 builds seclogon refuses a
# live stop ("Cannot stop seclogon service"). In that case the setting is
# still compliant and the service simply will not start after the next reboot.
# ---------------------------------------------------------------------------
$RebootNeeded = $false
try {
    Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
    Write-Host "[INFO] $ServiceName startup type set to Disabled"
}
catch {
    Write-Host "[ERROR] Could not set startup type: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$Svc = Get-Service -Name $ServiceName

# A Paused service often refuses a direct Stop, so resume it first.
if ($Svc.Status -eq 'Paused') {
    Resume-Service -Name $ServiceName -ErrorAction SilentlyContinue
    $Svc.Refresh()
}

if ($Svc.Status -ne 'Stopped') {
    try {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Host "[INFO] Stopped $ServiceName"
    }
    catch {
        $RebootNeeded = $true
        Write-Host "[WARN] $ServiceName would not stop while Windows is running. It is Disabled and will stay stopped after a reboot." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Verification
# The STIG check is the startup type. Running state is reported for info.
# ---------------------------------------------------------------------------
$Svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'"
if ($Svc.StartMode -eq 'Disabled') {
    Write-Host "[PASS] $ServiceName startup type is Disabled (current state: $($Svc.State))" -ForegroundColor Green
    if ($RebootNeeded) { Write-Host "[INFO] Restart the computer to fully stop the service." -ForegroundColor Yellow }
    exit 0
}
else {
    Write-Host "[FAIL] $ServiceName startup type is $($Svc.StartMode) (required: Disabled)" -ForegroundColor Red
    exit 1
}
