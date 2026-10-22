<#
.SYNOPSIS
    This PowerShell script configures the audit policy to record Detailed Tracking >> Process Creation successes
    (event ID 4688). It also enables the dependency WN11-SO-000030 (force audit policy subcategory settings)
    so the subcategory setting is not overridden by legacy category settings.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-20
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-AU-000050
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-AU-000050/

.TESTED ON
    Date(s) Tested  : 2026-10-21
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro 25H2, OS Build 26200.9711 (Azure VM, Cyber Range)
    PowerShell Ver. : 5.1 (Windows PowerShell)

.USAGE
    Run from an elevated PowerShell session (Run as Administrator).

    Example syntax:
    PS C:\> .\remediation-STIG-ID-WN11-AU-000050.ps1
#>

#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# Step 1: Dependency WN11-SO-000030
# "Audit: Force audit policy subcategory settings to override audit policy
#  category settings" must be Enabled, otherwise subcategory settings can be
#  silently ignored.
# ---------------------------------------------------------------------------
$LsaPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
New-ItemProperty -Path $LsaPath -Name 'SCENoApplyLegacyAuditPolicy' -PropertyType DWord -Value 1 -Force | Out-Null
Write-Host "[INFO] SCENoApplyLegacyAuditPolicy = 1 (WN11-SO-000030 dependency)"

# ---------------------------------------------------------------------------
# Step 2: Enable success auditing for Process Creation
# The GUID is used instead of the name so the script also works on
# non-English Windows builds where the subcategory name is translated.
# Process Creation GUID: {0CCE922B-69AE-11D9-BED3-505054503030}
# ---------------------------------------------------------------------------
$ProcessCreationGuid = '{0CCE922B-69AE-11D9-BED3-505054503030}'
$null = auditpol.exe /set /subcategory:$ProcessCreationGuid /success:enable
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] auditpol failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Verification (parse auditpol CSV output so we do not depend on spacing)
# ---------------------------------------------------------------------------
$Row = auditpol.exe /get /subcategory:$ProcessCreationGuid /r | Where-Object { $_ } | ConvertFrom-Csv
$Setting = $Row.'Inclusion Setting'
if ($Setting -match 'Success') {
    Write-Host "[PASS] Process Creation auditing is '$Setting'" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] Process Creation auditing is '$Setting' (required: Success)" -ForegroundColor Red
    exit 1
}
