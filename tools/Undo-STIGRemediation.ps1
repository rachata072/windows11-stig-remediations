<#
.SYNOPSIS
    Reverts one (or all) of the 10 STIG fixes in this repo back to the
    Windows 11 default, so you can prove the finding comes back as FAILED
    on a rescan (step 5 of the STIG methodology).

.NOTES
    Author        : Trey (Rachata Wichakkhapan)
    GitHub        : github.com/rachata072
    Date Created  : 2026-10-20
    Version       : 1.0

    LAB USE ONLY. This script deliberately makes the machine less secure.
    Never run it on a production or personal machine.

.USAGE
    PS C:\> .\Undo-STIGRemediation.ps1 -StigId WN11-AU-000500
    PS C:\> .\Undo-STIGRemediation.ps1 -All
#>

#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName = 'One')]
param(
    [Parameter(Mandatory, ParameterSetName = 'One')]
    [ValidateSet('WN11-AU-000500','WN11-AU-000505','WN11-AU-000510','WN11-AU-000050',
                 'WN11-CC-000326','WN11-CC-000327','WN11-CC-000038','WN11-CC-000190',
                 'WN11-AC-000020','WN11-00-000175')]
    [string]$StigId,

    [Parameter(Mandatory, ParameterSetName = 'All')]
    [switch]$All
)

function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $Path -Name $Name -Force
        Write-Host "[UNDO] Removed $Name from $Path" -ForegroundColor Yellow
    }
    else {
        Write-Host "[UNDO] $Name was not present at $Path (already default)"
    }
}

$Undo = [ordered]@{
    'WN11-AU-000500' = {
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application' 'MaxSize'
        wevtutil sl Application /ms:20971520   # Windows default 20 MB
    }
    'WN11-AU-000505' = {
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security' 'MaxSize'
        wevtutil sl Security /ms:20971520
    }
    'WN11-AU-000510' = {
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\System' 'MaxSize'
        wevtutil sl System /ms:20971520
    }
    'WN11-AU-000050' = {
        $null = auditpol.exe /set /subcategory:'{0CCE922B-69AE-11D9-BED3-505054503030}' /success:disable
        Write-Host "[UNDO] Process Creation success auditing disabled" -ForegroundColor Yellow
    }
    'WN11-CC-000326' = {
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' 'EnableScriptBlockLogging'
    }
    'WN11-CC-000327' = {
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' 'EnableTranscripting'
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' 'OutputDirectory'
        Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' 'EnableInvocationHeader'
        Write-Host "[UNDO] Transcript folder C:\ProgramData\PS_Transcript left in place (evidence)."
    }
    'WN11-CC-000038' = {
        Remove-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest' 'UseLogonCredential'
    }
    'WN11-CC-000190' = {
        Remove-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoDriveTypeAutoRun'
    }
    'WN11-AC-000020' = {
        $null = net.exe accounts /uniquepw:0
        Write-Host "[UNDO] Password history set to 0" -ForegroundColor Yellow
    }
    'WN11-00-000175' = {
        Set-Service -Name seclogon -StartupType Manual
        Write-Host "[UNDO] seclogon startup type set back to Manual (Windows default)" -ForegroundColor Yellow
    }
}

Write-Warning "LAB USE ONLY: reverting STIG settings to insecure defaults."

if ($All) {
    foreach ($id in $Undo.Keys) { Write-Host "`n== $id ==" -ForegroundColor Cyan; & $Undo[$id] }
}
else {
    Write-Host "== $StigId ==" -ForegroundColor Cyan
    & $Undo[$StigId]
}

Write-Host "`nDone. Restart the VM, then rescan to confirm the finding(s) show FAILED." -ForegroundColor Cyan
