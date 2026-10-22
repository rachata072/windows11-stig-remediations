<#
.SYNOPSIS
    This PowerShell script stops and disables the Secondary Logon service (seclogon), which powers
    'Run as different user' and can be abused to launch processes under other credentials.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-20
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-00-000175
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-00-000175/

.TESTED ON
    Date(s) Tested  : 
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro (Azure VM, Cyber Range)
    PowerShell Ver. : 

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
# ---------------------------------------------------------------------------
try {
    $Svc = Get-Service -Name $ServiceName -ErrorAction Stop

    # A Paused service often refuses a direct Stop, so resume it first.
    if ($Svc.Status -eq 'Paused') {
        Resume-Service -Name $ServiceName -ErrorAction Stop
        Write-Host "[INFO] Resumed paused $ServiceName so it can be stopped"
        $Svc.Refresh()
    }

    if ($Svc.Status -ne 'Stopped') {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Host "[INFO] Stopped $ServiceName"
    }

    Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
    Write-Host "[INFO] $ServiceName startup type set to Disabled"
}
catch {
    Write-Host "[ERROR] Remediation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
$Svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'"
if ($Svc.StartMode -eq 'Disabled' -and $Svc.State -eq 'Stopped') {
    Write-Host "[PASS] $ServiceName is $($Svc.State) and $($Svc.StartMode)" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] $ServiceName is $($Svc.State) / $($Svc.StartMode) (required: Stopped / Disabled)" -ForegroundColor Red
    exit 1
}
