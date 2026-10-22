# RUNBOOK: Windows 11 DISA STIG Remediation (Manual First, Then PowerShell)

This runbook is the full procedure. It is written so you can follow it top to bottom in the lab without guessing. Screenshots do NOT go in this file; they go in [EVIDENCE.md](EVIDENCE.md), and every step below that produces proof tells you which evidence item to capture.

**Scope:** 10 Windows 11 STIG findings on one Azure Windows 11 VM, scanned with Tenable Vulnerability Management (DISA Microsoft Windows 11 STIG audit), fixed manually first, reverted, then fixed with PowerShell.

| # | STIG ID | Short name | Fix mechanism |
|---|---------|------------|---------------|
| 1 | WN11-AU-000500 | Application event log size | Registry (policy) |
| 2 | WN11-AU-000505 | Security event log size | Registry (policy) |
| 3 | WN11-AU-000510 | System event log size | Registry (policy) |
| 4 | WN11-CC-000326 | PowerShell Script Block Logging | Registry (policy) |
| 5 | WN11-CC-000327 | PowerShell Transcription | Registry + folder ACL |
| 6 | WN11-AU-000050 | Audit Process Creation | Advanced Audit Policy (auditpol) |
| 7 | WN11-CC-000038 | WDigest disabled | Registry (no ADMX by default) |
| 8 | WN11-CC-000190 | AutoPlay off for all drives | Registry (policy) |
| 9 | WN11-AC-000020 | Password history 24 | Local security policy (net accounts) |
| 10 | WN11-00-000175 | Secondary Logon disabled | Windows service |

The order is deliberate. Items 1 to 3 are the same pattern three times, so you learn the loop on the easy ones. Items 4 to 6 build a logging story (who ran what). Items 7 to 10 introduce a new fix mechanism each time.

---

## Part 1: Lab Setup

### 1.1 Create (or reuse) the Windows 11 VM

1. Log in to https://portal.azure.com.
2. If you already have a working Windows 11 VM in the Cyber Range, reuse it. Otherwise create one following the Cyber Range "How to Properly Create a VM" guide (correct resource group, region, VNet and naming convention for your cohort).
3. Write these down. You will need them several times:

| Item | Value |
|------|-------|
| VM name | `________________` |
| Private IP | `________________` |
| Local admin username | `________________` |
| Windows edition and build (`winver`) | `________________` |

4. RDP into the VM and run `winver`. Note the build. (Evidence item E1.)

### 1.2 Disable the Windows Firewall (lab only)

Tenable's credentialed checks talk to the VM over SMB (TCP 445) and remote registry. In the Cyber Range the firewall is turned off so the scanner can reach it.

**GUI:** Run `wf.msc` > Windows Defender Firewall Properties > set Firewall state to **Off** on the Domain, Private and Public tabs > OK.

**PowerShell (elevated):**

```powershell
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False
Get-NetFirewallProfile | Select-Object Name, Enabled
```

All three should show `False`.

> Real world note: you would never do this in production. You would allow the scanner's IP through the firewall on 445 instead. Say this in interviews; it shows you know the lab shortcut is a shortcut.

### 1.3 Make a working folder on the VM

```powershell
New-Item -Path C:\STIG -ItemType Directory -Force
New-Item -Path C:\STIG\backup -ItemType Directory -Force
```

Copy the `scripts\` and `tools\` folders from this repo into `C:\STIG`. (Clipboard paste through RDP works, or download the repo zip from GitHub in Edge on the VM.)

If PowerShell refuses to run the scripts because of execution policy, allow it for this session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

### 1.4 Create the Tenable scan

1. Log in to https://cloud.tenable.com.
2. **Scans > Create a Scan > Advanced Network Scan.**
3. **Settings > Basic > General:**
   - Name: `STIG-WIN11-<yourname>-<vmname>`
   - Scanner: **LOCAL-SCAN-ENGINE-01**
   - Targets: the VM's **private IP** from 1.1
4. **Settings > Discovery > Host Discovery:** enable **Use fast network discovery**.
5. **Credentials > Host > Windows:**
   - Authentication method: Password
   - Username and password: the VM's local admin
   - Domain: leave blank
   - Recommended: enable **Start the Remote Registry service during the scan** and **Enable administrative shares during the scan**.
6. **Compliance > Windows:** search `Windows 11 STIG` and add **DISA Microsoft Windows 11 STIG** (pick the version your cohort uses, for example v2r6). Write down the exact audit file name; it goes in your evidence and your scripts' notes.
7. **Plugins (makes the scan STIG only and fast):**
   - Click **Disable All**.
   - Find the family **Policy Compliance**, open it, and enable only **Windows Compliance Checks** (plugin 21156).
8. **Save.** (Evidence item E2: Discovery tab. E3: Compliance tab. E4: Plugins tab.)

### 1.5 Run the baseline scan

1. Launch the scan. A STIG only scan of one host usually takes 5 to 15 minutes.
2. Open the results > **Audits** (or Compliance) tab. Filter Status = **Failed**.
3. Confirm each of the 10 STIG IDs in the table above shows **FAILED**. Search the audit list by STIG ID; Tenable puts the ID in the check name.
4. Record the baseline counts (Passed / Failed / Warning) in EVIDENCE.md section 2. (Evidence items E5 and E6.)
5. Export the results: **Report > CSV** (or PDF). Save as `baseline-<date>.csv`. You will compare against it at the end.

> If one of the 10 already shows PASSED on your image, that is fine. Note it, skip it, and pick another failed STIG from the baseline. The loop in Part 2 works for any registry based STIG.

---

## Part 2: The Remediation Loop (repeat for every STIG)

Every STIG in Part 3 follows exactly these 8 steps. This is the methodology from the internship brief, written as a checklist.

| Step | Action | Proof |
|------|--------|-------|
| A | Read the STIG on stigaview.com (check text = what the scanner looks at, fix text = what to change). | none |
| B | **Manual fix** (Group Policy Editor, Registry Editor, Services, or command line). | screenshot of the setting |
| C | Run `C:\STIG\tools\Test-STIGCompliance.ps1` for a fast local pre-check, then **restart the VM and rescan**. | Tenable shows PASSED |
| D | **Back up** the change (`reg export` or `auditpol /backup`) so you can study it later. | the .reg / .csv file |
| E | **Undo** the manual fix (revert to default). Restart and rescan. | Tenable shows FAILED again |
| F | **PowerShell fix**: run `C:\STIG\scripts\remediation-STIG-ID-<ID>.ps1`. | `[PASS]` in console |
| G | Restart and **rescan**. | Tenable shows PASSED |
| H | Commit the script to GitHub and add the row to the internship tracking spreadsheet. | repo link |

### Saving time on rescans

A full rescan per step per STIG is 10 STIGs x 3 scans = 30 scans. That is the honest way, and it is what the brief asks for. If you are short on time, batch them:

- **Round 1 (manual):** do step B for all 10, restart once, scan once. All 10 should pass.
- **Round 2 (undo):** do step D and E for all 10 (`Undo-STIGRemediation.ps1 -All` is fine here because you already proved the manual fix), restart, scan once. All 10 should fail.
- **Round 3 (PowerShell):** run all 10 scripts, restart, scan once. All 10 should pass.

Three scans, same proof. Write in EVIDENCE.md which approach you used.

---

## Part 3: The 10 STIGs

### STIG 1: WN11-AU-000500, Application event log size

**What it is:** The Application log must be allowed to grow to at least 32768 KB (32 MB). The Windows default is 20 MB.

**Why it matters:** When the log hits its max size, old events are overwritten. An attacker who generates noise (or simply waits) can push the evidence out before anyone looks. A bigger log means a longer look-back window for incident response.

**What the scanner checks:**
`HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application` > `MaxSize` (REG_DWORD) >= `0x8000` (32768).

**B. Manual fix (Group Policy):**

1. Run `gpedit.msc`.
2. Computer Configuration > Administrative Templates > Windows Components > Event Log Service > **Application**.
3. Open **Specify the maximum log file size (KB)** > **Enabled** > Maximum Log Size (KB) = `32768` > OK.
4. Run `gpupdate /force`.

**B. Manual fix (Registry Editor alternative):**

1. Run `regedit`.
2. Go to `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows`.
3. If there is no `EventLog` key: right click Windows > New > Key > `EventLog`. Inside it, create key `Application`.
4. In `Application`: right click > New > DWORD (32-bit) Value > name `MaxSize`.
5. Double click it, choose **Decimal**, enter `32768`. OK.

(EVIDENCE.md, STIG 1 item a.)

**C. Verify:** `C:\STIG\tools\Test-STIGCompliance.ps1` shows PASS for WN11-AU-000500. Restart, rescan, confirm PASSED. (EVIDENCE.md, STIG 1 item b.)

**D. Back up before undoing:**

```cmd
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application" C:\STIG\backup\WN11-AU-000500.reg /y
```

Open the .reg file in Notepad. You will see `"MaxSize"=dword:00008000`. 0x8000 hex is 32768 decimal. This is the line you can paste into ChatGPT (or read yourself) to build the PowerShell version.

**E. Undo:** gpedit > same setting > **Not Configured** > OK > `gpupdate /force`. (Or in regedit, delete the `MaxSize` value.) Or:

```powershell
C:\STIG\tools\Undo-STIGRemediation.ps1 -StigId WN11-AU-000500
```

Restart, rescan, confirm FAILED. (EVIDENCE.md, STIG 1 item c.)

**F. PowerShell fix:**

```powershell
C:\STIG\scripts\remediation-STIG-ID-WN11-AU-000500.ps1
```

Expected output ends with `[PASS] MaxSize is 32768 (required: >= 32768)`. (EVIDENCE.md, STIG 1 item d.)

**G. Rescan:** confirm PASSED. (EVIDENCE.md, STIG 1 item d.)

> Note on gpedit vs PowerShell: if you set it in gpedit and later run the script, both write the same registry value. The script wins only until the next time local Group Policy reapplies with a different value, which is why we undo the gpedit setting in step E first.

---

### STIG 2: WN11-AU-000505, Security event log size

**What it is:** The Security log must hold at least one week of audit records. Older STIG versions (and many Tenable audit files) require **1024000 KB** (about 1 GB). STIG V2R11 raised the example to **5120000 KB** (about 5 GB).

**Why it matters:** The Security log is where logons (4624/4625), process creation (4688), privilege use and account changes live. It is the single most important log for an investigation, and the default 20 MB fills in hours on a busy machine.

**What the scanner checks:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security` > `MaxSize` (REG_DWORD) >= the value in your audit file.

**Decision:** The script sets **5120000** so it passes both the older and newer audit file. Size is a maximum, not a pre allocation, so it does not eat 5 GB of disk on day one.

**B. Manual fix:** gpedit > Event Log Service > **Security** > Specify the maximum log file size (KB) > Enabled > `5120000` (or `1024000` to match an older audit file exactly). Registry alternative: same as STIG 1 but key `Security`.

**C, D, E:** same as STIG 1, with `Security` in place of `Application`:

```cmd
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security" C:\STIG\backup\WN11-AU-000505.reg /y
```

**F. PowerShell fix:** `C:\STIG\scripts\remediation-STIG-ID-WN11-AU-000505.ps1`

**G. Rescan.**

---

### STIG 3: WN11-AU-000510, System event log size

**What it is:** System log max size >= 32768 KB.

**Why it matters:** Service installs (7045), unexpected shutdowns, driver loads. Event 7045 is one of the first places to look for persistence and for tools like PsExec.

**Scanner checks:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\System` > `MaxSize` >= 32768.

**B to G:** identical to STIG 1 with key `System`. Script: `remediation-STIG-ID-WN11-AU-000510.ps1`.

> Tip: after doing STIG 1 to 3, you have done the same pattern three times. In your write-up, point out that a real environment would push all three in one GPO, and the PowerShell scripts are for machines not covered by GPO (workgroup machines, Intune gaps, golden image builds).

---

### STIG 4: WN11-CC-000326, PowerShell Script Block Logging

**What it is:** Logs the full text of every PowerShell script block that runs, including code that was obfuscated or downloaded into memory and never touched disk. Events go to **Applications and Services Logs > Microsoft > Windows > PowerShell > Operational**, event ID **4104**.

**Why it matters:** PowerShell is the attacker's favourite built-in tool. Base64 encoded `-enc` commands are decoded before execution, and script block logging captures the decoded version. This is often the single best artifact in a fileless malware investigation.

**Scanner checks:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging` > `EnableScriptBlockLogging` (REG_DWORD) = 1.

**B. Manual fix:** gpedit > Computer Configuration > Administrative Templates > Windows Components > **Windows PowerShell** > **Turn on PowerShell Script Block Logging** > Enabled > OK > `gpupdate /force`.

**C. Verify it actually works (not just the registry):**

```powershell
# open a NEW PowerShell window, then:
Write-Output "stig-test-4104"
Get-WinEvent -LogName 'Microsoft-Windows-PowerShell/Operational' -MaxEvents 20 |
    Where-Object Id -eq 4104 | Select-Object TimeCreated, Message -First 3
```

You should see your test string inside a 4104 event. (EVIDENCE.md, STIG 4 item a. This screenshot is a strong one for the blog.)

**D. Back up:** `reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" C:\STIG\backup\WN11-CC-000326.reg /y`

**E. Undo:** set the policy to Not Configured, or `Undo-STIGRemediation.ps1 -StigId WN11-CC-000326`.

**F. PowerShell fix:** `remediation-STIG-ID-WN11-CC-000326.ps1`

**G. Rescan.**

---

### STIG 5: WN11-CC-000327, PowerShell Transcription

**What it is:** Writes a text transcript of every PowerShell session (input and output) to a folder.

**Why it matters:** Script block logging shows the code. Transcription shows what the person typed and what came back on screen, which reads like a session recording during an investigation.

**Scanner checks:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription` > `EnableTranscripting` (REG_DWORD) = 1. The STIG also requires the output folder to be write only for normal users (they must not read or edit transcripts).

**B. Manual fix:**

1. Create the folder and lock it down (elevated Command Prompt):

```cmd
mkdir C:\ProgramData\PS_Transcript
icacls "C:\ProgramData\PS_Transcript" /inheritance:r /grant:r "Administrators:(OI)(CI)(F)" /grant:r "SYSTEM:(OI)(CI)(F)"
icacls "C:\ProgramData\PS_Transcript" /grant:r "Users:(OI)(CI)(WD,AD)" "Authenticated Users:(OI)(CI)(WD,AD)"
icacls "C:\ProgramData\PS_Transcript"
```

2. gpedit > Windows Components > Windows PowerShell > **Turn on PowerShell Transcription** > Enabled > Transcript output directory = `C:\ProgramData\PS_Transcript` > tick **Include invocation headers** > OK > `gpupdate /force`.

**C. Verify:** open a new PowerShell window, run `Get-Date`, close it. Browse to `C:\ProgramData\PS_Transcript\<today's date>\` and open the newest `PowerShell_transcript...txt`. (EVIDENCE.md, STIG 5 item a.)

**D. Back up:** `reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" C:\STIG\backup\WN11-CC-000327.reg /y`

**E. Undo:** policy to Not Configured, or `Undo-STIGRemediation.ps1 -StigId WN11-CC-000327`. Leave the folder; it does not affect the check.

**F. PowerShell fix:** `remediation-STIG-ID-WN11-CC-000327.ps1` (creates the folder, applies the ACL using well known SIDs so it works on any OS language, writes the 3 registry values).

**G. Rescan.**

---

### STIG 6: WN11-AU-000050, Audit Process Creation (Success)

**What it is:** Turns on Security event **4688** (a new process has been created).

**Why it matters:** Process creation is the backbone of endpoint detection. Without it, the Security log cannot tell you that `winword.exe` spawned `powershell.exe`.

**Dependency (important):** STIG **WN11-SO-000030**, "Audit: Force audit policy subcategory settings to override audit policy category settings", must be **Enabled**. If it is not, the old category level policy can silently override the subcategory you just set. The script sets both.

**Scanner checks:** `auditpol /get /category:*` shows **Detailed Tracking > Process Creation: Success**.

> **Warning (found in this lab):** configuring Advanced Audit Policy in the *local* Group Policy Editor writes an `audit.csv` that **replaces the whole audit policy**. Every subcategory you do not set becomes No Auditing. In this lab, setting only Process Creation switched off 13 default subcategories (Logon, Logoff, Special Logon, User Account Management, Security Group Management, Audit Policy Change, Authentication Policy Change, Security State Change, Other System Events, System Integrity) and 13 STIG checks went from PASSED to FAILED. Safer manual option: skip step 2 below and run `auditpol /set /subcategory:"Process Creation" /success:enable` instead, which changes one subcategory only. If you use gpedit anyway, check `auditpol /get /category:*` afterwards.

**B. Manual fix:**

1. gpedit > Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options > **Audit: Force audit policy subcategory settings...** > Enabled.
2. gpedit > Computer Configuration > Windows Settings > Security Settings > **Advanced Audit Policy Configuration** > System Audit Policies > **Detailed Tracking** > **Audit Process Creation** > tick Configure the following audit events > **Success** > OK.
3. `gpupdate /force`, then confirm:

```cmd
auditpol /get /subcategory:"Process Creation"
```

Should show `Success`. (EVIDENCE.md, STIG 6 item a.)

**C. Verify it works:** run `notepad.exe`, then:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 5 |
    Select-Object TimeCreated, @{n='Process';e={$_.Properties[5].Value}}
```

**D. Back up:**

```cmd
auditpol /backup /file:C:\STIG\backup\WN11-AU-000050-auditpol.csv
```

**E. Undo:** in gpedit set Audit Process Creation back to "not configured" (untick Configure), then also run `auditpol /set /subcategory:"Process Creation" /success:disable` because advanced audit settings can stick after the GPO is removed. Or `Undo-STIGRemediation.ps1 -StigId WN11-AU-000050`. Restart, rescan, FAILED.

If you configured it with gpedit, also remove the audit policy file and restore the defaults it wiped, otherwise the next Group Policy refresh can wipe them again:

```powershell
Remove-Item "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit\audit.csv" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\security\audit\audit.csv" -Force -ErrorAction SilentlyContinue
gpupdate /force
auditpol /set /subcategory:"Security Group Management" /success:enable
auditpol /set /subcategory:"User Account Management" /success:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable
auditpol /set /subcategory:"Special Logon" /success:enable
auditpol /set /subcategory:"Audit Policy Change" /success:enable
auditpol /set /subcategory:"Authentication Policy Change" /success:enable
auditpol /set /subcategory:"Security State Change" /success:enable
auditpol /set /subcategory:"Other System Events" /success:enable /failure:enable
auditpol /set /subcategory:"System Integrity" /success:enable /failure:enable
```

**F. PowerShell fix:** `remediation-STIG-ID-WN11-AU-000050.ps1` (uses the subcategory GUID `{0CCE922B-69AE-11D9-BED3-505054503030}`, which works on non-English Windows too).

**G. Rescan.**

---

### STIG 7: WN11-CC-000038, WDigest Authentication disabled

**What it is:** WDigest is a legacy auth protocol. When enabled, Windows keeps the user's password in LSASS memory in a recoverable form.

**Why it matters:** This is the classic Mimikatz `sekurlsa::wdigest` attack. Attackers who get admin on a box will set `UseLogonCredential = 1` themselves, wait for an admin to log in, and dump the cleartext password. Setting it explicitly to 0 (and alerting when it changes) closes that door.

**Scanner checks:** `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest` > `UseLogonCredential` (REG_DWORD) = 0. Windows 11 behaves as disabled by default, but the value does not exist, and the STIG says "does not exist = finding". That is why it fails on a fresh image.

**B. Manual fix (Registry Editor, because the GPO setting needs the DISA SecGuide.admx template that is not installed by default):**

1. `regedit` > `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest`.
2. New > DWORD (32-bit) Value > `UseLogonCredential` > value `0`.

(Optional deeper path: download the STIG package from cyber.mil, copy `SecGuide.admx` to `C:\Windows\PolicyDefinitions` and `SecGuide.adml` to `C:\Windows\PolicyDefinitions\en-US`, then the setting appears under Administrative Templates > MS Security Guide.)

**D. Back up:** `reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" C:\STIG\backup\WN11-CC-000038.reg /y`

**E. Undo:** delete the `UseLogonCredential` value (do NOT set it to 1; deleting returns to default).

**F. PowerShell fix:** `remediation-STIG-ID-WN11-CC-000038.ps1`

**G. Rescan.**

---

### STIG 8: WN11-CC-000190, AutoPlay turned off for all drives

**What it is:** Stops Windows from automatically opening or running content when a USB stick, CD or network drive is connected.

**Why it matters:** Removable media autorun is a long standing malware delivery path (Stuxnet, Conficker, USB drop attacks).

**Scanner checks:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` > `NoDriveTypeAutoRun` (REG_DWORD) = `0xFF` (255).

**B. Manual fix:** gpedit > Computer Configuration > Administrative Templates > Windows Components > **AutoPlay Policies** > **Turn off Autoplay** > Enabled > Turn off Autoplay on: **All drives** > OK > `gpupdate /force`.

Registry alternative: create DWORD `NoDriveTypeAutoRun` in the key above, choose **Hexadecimal** and type `ff`, or **Decimal** and type `255`. (Typing 255 while Hexadecimal is selected gives 0x255 = 597, which fails. This is the most common mistake on this STIG.)

**D. Back up:** `reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" C:\STIG\backup\WN11-CC-000190.reg /y`

**E. Undo:** Not Configured, or `Undo-STIGRemediation.ps1 -StigId WN11-CC-000190`.

**F. PowerShell fix:** `remediation-STIG-ID-WN11-CC-000190.ps1`

**G. Rescan.**

---

### STIG 9: WN11-AC-000020, Password history 24 passwords remembered

**What it is:** Users cannot reuse any of their last 24 passwords.

**Why it matters:** Without history, a forced password change after a breach is useless: the user changes it and changes it straight back.

**Scanner checks:** local security policy **Enforce password history** >= 24.

**B. Manual fix:** `secpol.msc` > Account Policies > Password Policy > **Enforce password history** > `24` > OK.

**C. Verify:** `net accounts` shows `Length of password history maintained: 24`. (EVIDENCE.md, STIG 9 item a.)

**D. Back up:** `secedit /export /cfg C:\STIG\backup\WN11-AC-000020-secpol.inf /areas SECURITYPOLICY` and find the line `PasswordHistorySize = 24`.

**E. Undo:** secpol.msc > set it back to `0`, or `net accounts /uniquepw:0`.

**F. PowerShell fix:** `remediation-STIG-ID-WN11-AC-000020.ps1` (sets it with `net accounts`, verifies with a `secedit` export so it does not depend on the English text of `net accounts`).

**G. Rescan.**

> Interview point: on a domain joined machine this setting comes from the Default Domain Policy, and a local change will be overwritten. Our lab VM is a workgroup machine, so the local policy is the right place.

---

### STIG 10: WN11-00-000175, Secondary Logon service disabled

**What it is:** The Secondary Logon service (`seclogon`) is what makes "Run as different user" and `runas.exe` work.

**Why it matters:** It lets a process start under different credentials from inside an existing session. Attackers use it for lateral movement and token tricks, and it has had its own privilege escalation bugs. Admins in a STIG environment should log in with the admin account instead.

**Scanner checks:** service `seclogon` startup type = **Disabled**.

**B. Manual fix:** `services.msc` > **Secondary Logon** > Properties > Stop > Startup type **Disabled** > OK. (EVIDENCE.md, STIG 10 item a.)

**D. Back up:** `sc.exe qc seclogon > C:\STIG\backup\WN11-00-000175-before.txt` (do this BEFORE the fix if you want the original state; default is DEMAND_START = Manual).

**E. Undo:** startup type back to **Manual**, or `Undo-STIGRemediation.ps1 -StigId WN11-00-000175`.

**F. PowerShell fix:** `remediation-STIG-ID-WN11-00-000175.ps1`

**G. Rescan.**

---

## Part 4: Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Scan finishes in about 1 minute and only shows "Vulnerabilities by Asset" and "History" | Host discovery did not find the VM | Discovery tab > enable **Use fast network discovery**. Confirm the target is the **private** IP. |
| Scan runs but no Audits/Compliance tab | Compliance audit not added, or Windows Compliance Checks plugin disabled | Re-check 1.4 step 6 and 7. |
| Every compliance check shows ERROR or WARNING "credentials" | Credentialed login failed | Re check username/password. Turn the firewall off (1.2). Enable "Start the Remote Registry service during the scan". If you use a non built in admin account, set `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy` = 1 (DWORD) and reboot. |
| Fixed the setting, rescan still FAILED | Scan used cached/old results, or GPO not applied | Restart the VM, wait 2 minutes, rescan. Run `gpupdate /force`. Compare the **Actual Value** column in the Tenable finding with the expected value. |
| Script error: "cannot be loaded because running scripts is disabled" | Execution policy | `Set-ExecutionPolicy -Scope Process Bypass -Force` |
| Script error: "The script ... cannot be run because it contains a #requires statement for running as Administrator" | Not elevated | Right click PowerShell > Run as administrator. |
| WN11-CC-000190 fails with value 597 | Typed 255 in Hexadecimal mode | Delete and recreate as Decimal 255 (or Hex ff). |
| 13 audit checks (Logon, Logoff, System Integrity...) suddenly FAIL after the Process Creation fix | Local GPO Advanced Audit Policy audit.csv replaced the whole audit policy | Delete both audit.csv files, `gpupdate /force`, restore defaults with auditpol (STIG 6, step E). Use auditpol instead of gpedit for single subcategories. |
| Secondary Logon will not stop: "Cannot stop seclogon service" | Service reports NOT_STOPPABLE (`sc.exe queryex seclogon`) on Windows 11 25H2 | Set startup type Disabled (that is what the STIG checks) and reboot. The script does this and warns instead of failing. |
| WN11-AU-000050 still fails after GPO | WN11-SO-000030 not enabled, or category level policy overriding | Enable "Force audit policy subcategory settings" and rerun the script. |
| WN11-AU-000505 fails even though you set 1024000 | Your Tenable audit file is V2R11 or later (5120000) | Use the script value 5120000. Read the expected value in the finding. |
| Undo did not make it FAIL again | gpedit setting still "Enabled" and reapplied the value | Set it to **Not Configured** in gpedit first, then run the undo script, then `gpupdate /force`. |

---

## Part 5: Publish

### 5.1 Fill in the script headers

In each `.ps1`, fill in the `.TESTED ON` block after you have actually run it:

```
Date(s) Tested  : 2026-10-xx
Tested By       : Trey (Rachata Wichakkhapan)
Systems Tested  : Windows 11 Pro 24H2 (Azure VM, Cyber Range)
PowerShell Ver. : 5.1.xxxxx      <- run $PSVersionTable.PSVersion
```

### 5.2 Push to GitHub (run these on your own PC, not from Claude)

```powershell
cd D:\Projects\STIG-Remediation\Github\windows11-stig-remediations
git init
git add .
git commit -m "Windows 11 STIG remediations: 10 STIGs, manual + PowerShell"
git branch -M main
git remote add origin https://github.com/rachata072/windows11-stig-remediations.git
git push -u origin main
```

(Create the empty `windows11-stig-remediations` repo on github.com first, without a README.)

### 5.3 Internship tracking spreadsheet

Use [TRACKER.md](TRACKER.md). It has one row per STIG with the direct GitHub link to each script, ready to paste into the LogN Pacific intern sheet.
