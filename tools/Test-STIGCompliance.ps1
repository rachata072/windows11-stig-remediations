<#
.SYNOPSIS
    Quick local pre-check for the 10 Windows 11 STIGs in this repo.
    Prints PASS or FAIL for each one so you know what to expect BEFORE you
    spend 10 to 20 minutes on a Tenable rescan.

.NOTES
    Author        : Trey (Rachata Wichakkhapan)
    GitHub        : github.com/rachata072
    Date Created  : 2026-10-20
    Version       : 1.0

    This is a convenience check, not the source of truth. Tenable's compliance
    scan is the official result. If this script says PASS and Tenable says
    FAILED, read the "Actual Value" in the Tenable finding and compare.

.USAGE
    PS C:\> .\Test-STIGCompliance.ps1
#>

#Requires -RunAsAdministrator

function Get-RegValue {
    param([string]$Path, [string]$Name)
    (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
}

# Password history needs a secedit export
$Export = Join-Path $env:TEMP 'secpol-precheck.inf'
$null = secedit.exe /export /cfg $Export /areas SECURITYPOLICY
$PwHistLine = Select-String -Path $Export -Pattern '^\s*PasswordHistorySize\s*=\s*(\d+)' | Select-Object -First 1
$PwHist = if ($PwHistLine) { [int]$PwHistLine.Matches[0].Groups[1].Value } else { $null }
Remove-Item $Export -Force -ErrorAction SilentlyContinue

# Process Creation audit (GUID so it works on any OS language)
$ProcAudit = (auditpol.exe /get /subcategory:'{0CCE922B-69AE-11D9-BED3-505054503030}' /r | Where-Object { $_ } | ConvertFrom-Csv).'Inclusion Setting'
$ForceSub  = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' 'SCENoApplyLegacyAuditPolicy'

$SecLogon = Get-CimInstance Win32_Service -Filter "Name='seclogon'"

$Checks = @(
    [pscustomobject]@{ StigId='WN11-AU-000500'; Title='Application log >= 32768 KB'
        Actual = Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application' 'MaxSize' }
    [pscustomobject]@{ StigId='WN11-AU-000505'; Title='Security log >= 1024000 KB (V2R11: 5120000)'
        Actual = Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security' 'MaxSize' }
    [pscustomobject]@{ StigId='WN11-AU-000510'; Title='System log >= 32768 KB'
        Actual = Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\System' 'MaxSize' }
    [pscustomobject]@{ StigId='WN11-AU-000050'; Title='Audit Process Creation: Success'
        Actual = "$ProcAudit (SCENoApplyLegacyAuditPolicy=$ForceSub)" }
    [pscustomobject]@{ StigId='WN11-CC-000326'; Title='PowerShell Script Block Logging = 1'
        Actual = Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' 'EnableScriptBlockLogging' }
    [pscustomobject]@{ StigId='WN11-CC-000327'; Title='PowerShell Transcription = 1'
        Actual = Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' 'EnableTranscripting' }
    [pscustomobject]@{ StigId='WN11-CC-000038'; Title='WDigest UseLogonCredential = 0'
        Actual = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest' 'UseLogonCredential' }
    [pscustomobject]@{ StigId='WN11-CC-000190'; Title='NoDriveTypeAutoRun = 255'
        Actual = Get-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoDriveTypeAutoRun' }
    [pscustomobject]@{ StigId='WN11-AC-000020'; Title='Password history >= 24'
        Actual = $PwHist }
    [pscustomobject]@{ StigId='WN11-00-000175'; Title='Secondary Logon disabled'
        Actual = "$($SecLogon.State) / $($SecLogon.StartMode)" }
)

$Rules = @{
    'WN11-AU-000500' = { param($v) $null -ne $v -and $v -ge 32768 }
    'WN11-AU-000505' = { param($v) $null -ne $v -and $v -ge 1024000 }
    'WN11-AU-000510' = { param($v) $null -ne $v -and $v -ge 32768 }
    'WN11-AU-000050' = { param($v) $ProcAudit -match 'Success' -and $ForceSub -eq 1 }
    'WN11-CC-000326' = { param($v) $v -eq 1 }
    'WN11-CC-000327' = { param($v) $v -eq 1 }
    'WN11-CC-000038' = { param($v) $null -ne $v -and $v -eq 0 }
    'WN11-CC-000190' = { param($v) $v -eq 255 }
    'WN11-AC-000020' = { param($v) $null -ne $v -and $v -ge 24 }
    'WN11-00-000175' = { param($v) $SecLogon.StartMode -eq 'Disabled' }
}

$Results = foreach ($c in $Checks) {
    $ok = & $Rules[$c.StigId] $c.Actual
    [pscustomobject]@{
        Result = if ($ok) { 'PASS' } else { 'FAIL' }
        StigId = $c.StigId
        Title  = $c.Title
        Actual = if ($null -eq $c.Actual -or "$($c.Actual)" -eq '') { '<not set>' } else { $c.Actual }
    }
}

$Results | Format-Table -AutoSize
$Pass = ($Results | Where-Object Result -eq 'PASS').Count
Write-Host "$Pass of $($Results.Count) checks passing" -ForegroundColor Cyan
