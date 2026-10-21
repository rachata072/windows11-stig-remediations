<#
.SYNOPSIS
    This PowerShell script enables PowerShell Transcription, writes transcripts to C:\ProgramData\PS_Transcript,
    and locks that folder down so standard users can write transcripts but cannot read or change them.

.NOTES
    Author          : Trey (Rachata Wichakkhapan)
    LinkedIn        : linkedin.com/in/treywcp/
    GitHub          : github.com/rachata072
    Date Created    : 2026-10-20
    Last Modified   : 2026-10-20
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-CC-000327
    Documentation   : https://stigaview.com/products/win11/v2r11/WN11-CC-000327/

.TESTED ON
    Date(s) Tested  : 
    Tested By       : Trey (Rachata Wichakkhapan)
    Systems Tested  : Windows 11 Pro (Azure VM, Cyber Range)
    PowerShell Ver. : 

.USAGE
    Run from an elevated PowerShell session (Run as Administrator).
    Transcription starts for NEW PowerShell sessions after the script runs.

    Example syntax:
    PS C:\> .\remediation-STIG-ID-WN11-CC-000327.ps1
#>

#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# Required settings
# ---------------------------------------------------------------------------
$RegPath         = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription'
$TranscriptDir   = 'C:\ProgramData\PS_Transcript'

try {
    # 1. Create the output folder
    if (-not (Test-Path -Path $TranscriptDir)) {
        New-Item -Path $TranscriptDir -ItemType Directory -Force | Out-Null
        Write-Host "[INFO] Created $TranscriptDir"
    }

    # 2. Lock down the folder. Admins and SYSTEM get full control.
    #    Users and Authenticated Users only get Write Data + Append Data (WD,AD),
    #    so a normal user's session can drop a transcript but cannot read or
    #    delete anyone's transcripts (including their own).
    #    Well-known SIDs are used so this works on any OS language:
    #    *S-1-5-32-544 = Administrators, *S-1-5-18 = SYSTEM,
    #    *S-1-5-32-545 = Users, *S-1-5-11 = Authenticated Users
    $null = icacls.exe $TranscriptDir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)(F)' '*S-1-5-18:(OI)(CI)(F)'
    $null = icacls.exe $TranscriptDir /grant:r '*S-1-5-32-545:(OI)(CI)(WD,AD)' '*S-1-5-11:(OI)(CI)(WD,AD)'
    Write-Host "[INFO] Permissions applied to $TranscriptDir"

    # 3. Policy registry values
    if (-not (Test-Path -Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name 'EnableTranscripting'    -PropertyType DWord  -Value 1              -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'OutputDirectory'        -PropertyType String -Value $TranscriptDir -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'EnableInvocationHeader' -PropertyType DWord  -Value 1              -Force | Out-Null
    Write-Host "[INFO] Transcription policy values written to $RegPath"
}
catch {
    Write-Host "[ERROR] Remediation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
$Current = (Get-ItemProperty -Path $RegPath -Name 'EnableTranscripting' -ErrorAction SilentlyContinue).EnableTranscripting
if ($Current -eq 1) {
    Write-Host "[PASS] EnableTranscripting = 1, output folder = $TranscriptDir" -ForegroundColor Green
    icacls.exe $TranscriptDir
    exit 0
}
else {
    Write-Host "[FAIL] EnableTranscripting is '$Current' (required: 1)" -ForegroundColor Red
    exit 1
}
