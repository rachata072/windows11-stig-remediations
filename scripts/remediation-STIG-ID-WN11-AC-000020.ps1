<#
.SYNOPSIS
    This PowerShell script sets the local password history to 24 passwords remembered.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-20
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-AC-000020
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-AC-000020/

.TESTED ON
    Date(s) Tested  : 
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro (Azure VM, Cyber Range)
    PowerShell Ver. : 

.USAGE
    Run from an elevated PowerShell session (Run as Administrator).
    This changes LOCAL account policy. On a domain-joined machine the domain password policy wins.

    Example syntax:
    PS C:\> .\remediation-STIG-ID-WN11-AC-000020.ps1
#>

#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# Required setting
# ---------------------------------------------------------------------------
$Required = 24

# ---------------------------------------------------------------------------
# Remediation
# "net accounts /uniquepw" is the built-in way to set "Enforce password history"
# on the local SAM. It only affects future password changes.
# ---------------------------------------------------------------------------
$null = net.exe accounts /uniquepw:$Required
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] net accounts failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
Write-Host "[INFO] Password history set to $Required"

# ---------------------------------------------------------------------------
# Verification
# Export the local security policy and read PasswordHistorySize. This is
# language independent, unlike parsing the text output of "net accounts".
# ---------------------------------------------------------------------------
$Export = Join-Path $env:TEMP 'secpol-WN11-AC-000020.inf'
$null = secedit.exe /export /cfg $Export /areas SECURITYPOLICY
$Line = Select-String -Path $Export -Pattern '^\s*PasswordHistorySize\s*=\s*(\d+)' | Select-Object -First 1
Remove-Item -Path $Export -Force -ErrorAction SilentlyContinue

$Current = if ($Line) { [int]$Line.Matches[0].Groups[1].Value } else { $null }
if ($null -ne $Current -and $Current -ge $Required) {
    Write-Host "[PASS] PasswordHistorySize = $Current (required: >= $Required)" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] PasswordHistorySize = '$Current' (required: >= $Required)" -ForegroundColor Red
    exit 1
}
