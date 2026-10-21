# EVIDENCE: Scan Results and Screenshots

This file holds the proof. The procedure is in [RUNBOOK.md](RUNBOOK.md). Drop each screenshot into `images/` using the exact filename shown, and the image links below will start working on GitHub.

**Screenshot tips:** crop to the relevant window, make sure the STIG ID and the PASSED/FAILED status are readable, and blur the VM's public IP and your username if they are visible.

---

## 1. Lab details

| Item | Value |
|------|-------|
| VM name | |
| Windows edition / build | Windows 11 Pro, version 25H2 (OS Build 26200.9711) |
| PowerShell version (`$PSVersionTable.PSVersion`) | |
| Tenable scan name | |
| Tenable audit file (exact name and version) | |
| Rescan approach used (per STIG, or batched 3 rounds) | |

## 2. Scan summary

| Scan | Date / time | Passed | Failed | Warning | Notes |
|------|-------------|--------|--------|---------|-------|
| Baseline | | | | | |
| After manual fixes | | | | | |
| After undo | | | | | |
| After PowerShell fixes | | | | | |

## 3. Setup screenshots

**E1. winver on the VM**

<!-- Upload: images/E01-winver.png -->
![E1 winver](images/E01-winver.png)

**E2. Tenable scan, Discovery tab with "Use fast network discovery" enabled**

<!-- Upload: images/E02-scan-discovery.png -->
![E2 discovery](images/E02-scan-discovery.png)

**E3. Tenable scan, Compliance tab with DISA Windows 11 STIG audit added**

<!-- Upload: images/E03-scan-compliance.png -->
![E3 compliance](images/E03-scan-compliance.png)

**E4. Tenable scan, Plugins tab with only Windows Compliance Checks enabled**

<!-- Upload: images/E04-scan-plugins.png -->
![E4 plugins](images/E04-scan-plugins.png)

**E5. Baseline scan summary (Passed / Failed / Warning counts)**

<!-- Upload: images/E05-baseline-summary.png -->
![E5 baseline summary](images/E05-baseline-summary.png)

**E6. Baseline audit list filtered to FAILED, showing the 10 target STIG IDs**

<!-- Upload: images/E06-baseline-failed.png -->
![E6 baseline failed](images/E06-baseline-failed.png)

## 4. Local pre check

**Test-STIGCompliance.ps1 at baseline (expect 0 of 10)**

<!-- Upload: images/precheck-baseline.png -->
![precheck baseline](images/precheck-baseline.png)

**Test-STIGCompliance.ps1 after PowerShell fixes (expect 10 of 10)**

<!-- Upload: images/precheck-final.png -->
![precheck final](images/precheck-final.png)

---

## 5. Per STIG proof

Each STIG needs four screenshots: the manual setting, Tenable PASSED after the manual fix, Tenable FAILED after the undo, and the PowerShell `[PASS]` output with Tenable PASSED.

### 1. WN11-AU-000500: Application event log size >= 32768 KB

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** gpedit: Event Log Service > Application > Specify the maximum log file size = 32768

<!-- Upload: images/WN11-AU-000500-1-manual.png -->
![WN11-AU-000500 manual fix](images/WN11-AU-000500-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-AU-000500-2-manual-passed.png -->
![WN11-AU-000500 manual passed](images/WN11-AU-000500-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-AU-000500-3-undo-failed.png -->
![WN11-AU-000500 undo failed](images/WN11-AU-000500-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-AU-000500-4-powershell-passed.png -->
![WN11-AU-000500 powershell passed](images/WN11-AU-000500-4-powershell-passed.png)

Notes / problems hit:

> 

### 2. WN11-AU-000505: Security event log size >= 5120000 KB

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** gpedit: Event Log Service > Security > Specify the maximum log file size = 5120000

<!-- Upload: images/WN11-AU-000505-1-manual.png -->
![WN11-AU-000505 manual fix](images/WN11-AU-000505-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-AU-000505-2-manual-passed.png -->
![WN11-AU-000505 manual passed](images/WN11-AU-000505-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-AU-000505-3-undo-failed.png -->
![WN11-AU-000505 undo failed](images/WN11-AU-000505-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-AU-000505-4-powershell-passed.png -->
![WN11-AU-000505 powershell passed](images/WN11-AU-000505-4-powershell-passed.png)

Notes / problems hit:

> 

### 3. WN11-AU-000510: System event log size >= 32768 KB

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** gpedit: Event Log Service > System > Specify the maximum log file size = 32768

<!-- Upload: images/WN11-AU-000510-1-manual.png -->
![WN11-AU-000510 manual fix](images/WN11-AU-000510-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-AU-000510-2-manual-passed.png -->
![WN11-AU-000510 manual passed](images/WN11-AU-000510-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-AU-000510-3-undo-failed.png -->
![WN11-AU-000510 undo failed](images/WN11-AU-000510-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-AU-000510-4-powershell-passed.png -->
![WN11-AU-000510 powershell passed](images/WN11-AU-000510-4-powershell-passed.png)

Notes / problems hit:

> 

### 4. WN11-CC-000326: PowerShell Script Block Logging

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** gpedit: Windows PowerShell > Turn on PowerShell Script Block Logging = Enabled, plus a 4104 event in Event Viewer

<!-- Upload: images/WN11-CC-000326-1-manual.png -->
![WN11-CC-000326 manual fix](images/WN11-CC-000326-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-CC-000326-2-manual-passed.png -->
![WN11-CC-000326 manual passed](images/WN11-CC-000326-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-CC-000326-3-undo-failed.png -->
![WN11-CC-000326 undo failed](images/WN11-CC-000326-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-CC-000326-4-powershell-passed.png -->
![WN11-CC-000326 powershell passed](images/WN11-CC-000326-4-powershell-passed.png)

Notes / problems hit:

> 

### 5. WN11-CC-000327: PowerShell Transcription

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** gpedit: Turn on PowerShell Transcription = Enabled with output folder, plus icacls output and a transcript .txt file

<!-- Upload: images/WN11-CC-000327-1-manual.png -->
![WN11-CC-000327 manual fix](images/WN11-CC-000327-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-CC-000327-2-manual-passed.png -->
![WN11-CC-000327 manual passed](images/WN11-CC-000327-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-CC-000327-3-undo-failed.png -->
![WN11-CC-000327 undo failed](images/WN11-CC-000327-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-CC-000327-4-powershell-passed.png -->
![WN11-CC-000327 powershell passed](images/WN11-CC-000327-4-powershell-passed.png)

Notes / problems hit:

> 

### 6. WN11-AU-000050: Audit Process Creation (Success)

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** Advanced Audit Policy > Detailed Tracking > Audit Process Creation = Success, plus auditpol output

<!-- Upload: images/WN11-AU-000050-1-manual.png -->
![WN11-AU-000050 manual fix](images/WN11-AU-000050-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-AU-000050-2-manual-passed.png -->
![WN11-AU-000050 manual passed](images/WN11-AU-000050-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-AU-000050-3-undo-failed.png -->
![WN11-AU-000050 undo failed](images/WN11-AU-000050-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-AU-000050-4-powershell-passed.png -->
![WN11-AU-000050 powershell passed](images/WN11-AU-000050-4-powershell-passed.png)

Notes / problems hit:

> 

### 7. WN11-CC-000038: WDigest disabled

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** regedit: WDigest key showing UseLogonCredential = 0

<!-- Upload: images/WN11-CC-000038-1-manual.png -->
![WN11-CC-000038 manual fix](images/WN11-CC-000038-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-CC-000038-2-manual-passed.png -->
![WN11-CC-000038 manual passed](images/WN11-CC-000038-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-CC-000038-3-undo-failed.png -->
![WN11-CC-000038 undo failed](images/WN11-CC-000038-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-CC-000038-4-powershell-passed.png -->
![WN11-CC-000038 powershell passed](images/WN11-CC-000038-4-powershell-passed.png)

Notes / problems hit:

> 

### 8. WN11-CC-000190: AutoPlay off for all drives

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** gpedit: AutoPlay Policies > Turn off Autoplay = Enabled, All drives

<!-- Upload: images/WN11-CC-000190-1-manual.png -->
![WN11-CC-000190 manual fix](images/WN11-CC-000190-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-CC-000190-2-manual-passed.png -->
![WN11-CC-000190 manual passed](images/WN11-CC-000190-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-CC-000190-3-undo-failed.png -->
![WN11-CC-000190 undo failed](images/WN11-CC-000190-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-CC-000190-4-powershell-passed.png -->
![WN11-CC-000190 powershell passed](images/WN11-CC-000190-4-powershell-passed.png)

Notes / problems hit:

> 

### 9. WN11-AC-000020: Password history 24

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** secpol.msc: Enforce password history = 24, plus net accounts output

<!-- Upload: images/WN11-AC-000020-1-manual.png -->
![WN11-AC-000020 manual fix](images/WN11-AC-000020-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-AC-000020-2-manual-passed.png -->
![WN11-AC-000020 manual passed](images/WN11-AC-000020-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-AC-000020-3-undo-failed.png -->
![WN11-AC-000020 undo failed](images/WN11-AC-000020-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-AC-000020-4-powershell-passed.png -->
![WN11-AC-000020 powershell passed](images/WN11-AC-000020-4-powershell-passed.png)

Notes / problems hit:

> 

### 10. WN11-00-000175: Secondary Logon disabled

| Stage | Result | Scan date |
|-------|--------|-----------|
| Baseline | FAILED | |
| Manual fix | | |
| Undo | | |
| PowerShell fix | | |

Tenable "Actual Value" at baseline: `________`  After fix: `________`

**a) Manual fix:** services.msc: Secondary Logon Stopped / Disabled

<!-- Upload: images/WN11-00-000175-1-manual.png -->
![WN11-00-000175 manual fix](images/WN11-00-000175-1-manual.png)

**b) Rescan after manual fix: PASSED**

<!-- Upload: images/WN11-00-000175-2-manual-passed.png -->
![WN11-00-000175 manual passed](images/WN11-00-000175-2-manual-passed.png)

**c) Rescan after undo: FAILED**

<!-- Upload: images/WN11-00-000175-3-undo-failed.png -->
![WN11-00-000175 undo failed](images/WN11-00-000175-3-undo-failed.png)

**d) PowerShell script output and rescan: PASSED**

<!-- Upload: images/WN11-00-000175-4-powershell-passed.png -->
![WN11-00-000175 powershell passed](images/WN11-00-000175-4-powershell-passed.png)

Notes / problems hit:

> 

---

## 6. Final before and after

<!-- Upload: images/before-after-summary.png (baseline summary and final summary side by side) -->
![before and after](images/before-after-summary.png)

**What changed in one sentence:** 

**Biggest problem I hit and how I fixed it:** 
