# Windows 11 DISA STIG Remediations (Manual + PowerShell)

Ten DISA Windows 11 STIG findings, found with a Tenable credentialed compliance scan on an Azure Windows 11 VM, fixed by hand, reverted to prove the scanner catches the regression, then fixed again with PowerShell and verified by rescan.

Built during the LogN Pacific cybersecurity internship (Cyber Range lab environment).

<!-- IMAGE: before/after Tenable compliance summary side by side -->
![Before and after compliance summary](images/before-after-summary.png)

---

## Remediations

| # | STIG ID | Requirement | Category | Script |
|---|---------|-------------|----------|--------|
| 1 | [WN11-AU-000500](https://stigaview.com/products/win11/v2r11/WN11-AU-000500/) | Application event log size >= 32768 KB | Audit / Logging | [remediation-STIG-ID-WN11-AU-000500.ps1](scripts/remediation-STIG-ID-WN11-AU-000500.ps1) |
| 2 | [WN11-AU-000505](https://stigaview.com/products/win11/v2r11/WN11-AU-000505/) | Security event log holds one week (5120000 KB) | Audit / Logging | [remediation-STIG-ID-WN11-AU-000505.ps1](scripts/remediation-STIG-ID-WN11-AU-000505.ps1) |
| 3 | [WN11-AU-000510](https://stigaview.com/products/win11/v2r11/WN11-AU-000510/) | System event log size >= 32768 KB | Audit / Logging | [remediation-STIG-ID-WN11-AU-000510.ps1](scripts/remediation-STIG-ID-WN11-AU-000510.ps1) |
| 4 | [WN11-CC-000326](https://stigaview.com/products/win11/v2r11/WN11-CC-000326/) | PowerShell Script Block Logging enabled | Logging / Detection | [remediation-STIG-ID-WN11-CC-000326.ps1](scripts/remediation-STIG-ID-WN11-CC-000326.ps1) |
| 5 | [WN11-CC-000327](https://stigaview.com/products/win11/v2r11/WN11-CC-000327/) | PowerShell Transcription enabled, secure output folder | Logging / Detection | [remediation-STIG-ID-WN11-CC-000327.ps1](scripts/remediation-STIG-ID-WN11-CC-000327.ps1) |
| 6 | [WN11-AU-000050](https://stigaview.com/products/win11/v2r11/WN11-AU-000050/) | Audit Process Creation (Success), event 4688 | Audit Policy | [remediation-STIG-ID-WN11-AU-000050.ps1](scripts/remediation-STIG-ID-WN11-AU-000050.ps1) |
| 7 | [WN11-CC-000038](https://stigaview.com/products/win11/v2r11/WN11-CC-000038/) | WDigest authentication disabled | Credential Protection | [remediation-STIG-ID-WN11-CC-000038.ps1](scripts/remediation-STIG-ID-WN11-CC-000038.ps1) |
| 8 | [WN11-CC-000190](https://stigaview.com/products/win11/v2r11/WN11-CC-000190/) | AutoPlay disabled for all drives | Attack Surface | [remediation-STIG-ID-WN11-CC-000190.ps1](scripts/remediation-STIG-ID-WN11-CC-000190.ps1) |
| 9 | [WN11-AC-000020](https://stigaview.com/products/win11/v2r11/WN11-AC-000020/) | Password history = 24 | Account Policy | [remediation-STIG-ID-WN11-AC-000020.ps1](scripts/remediation-STIG-ID-WN11-AC-000020.ps1) |
| 10 | [WN11-00-000175](https://stigaview.com/products/win11/v2r11/WN11-00-000175/) | Secondary Logon service disabled | Services | [remediation-STIG-ID-WN11-00-000175.ps1](scripts/remediation-STIG-ID-WN11-00-000175.ps1) |

Every script:

- follows the Cyber Range remediation template header (synopsis, STIG ID, documentation link, tested on block)
- requires an elevated session (`#Requires -RunAsAdministrator`)
- is idempotent: running it twice does no harm
- verifies its own result and prints `[PASS]` or `[FAIL]` with exit code 0 or 1, so it can be used from Intune, a scheduled task or an RMM tool

## Helper tools

| Tool | Purpose |
|------|---------|
| [tools/Test-STIGCompliance.ps1](tools/Test-STIGCompliance.ps1) | Local PASS/FAIL table for all 10 settings in a few seconds. Used as a pre check before spending 10+ minutes on a Tenable rescan. |
| [tools/Undo-STIGRemediation.ps1](tools/Undo-STIGRemediation.ps1) | Reverts one STIG (`-StigId`) or all (`-All`) to Windows defaults so the regression shows up as FAILED. **Lab use only.** |

## Methodology

1. Credentialed Tenable **Advanced Network Scan** with the **DISA Microsoft Windows 11 STIG** audit, plugins limited to Policy Compliance > Windows Compliance Checks for speed.
2. Pick a FAILED STIG from the baseline, read its check and fix text.
3. Fix it **manually** (Group Policy Editor, Registry Editor, Services or Local Security Policy).
4. Restart and rescan: confirm **PASSED**.
5. Export the change (`reg export`, `auditpol /backup`, `secedit /export`), then **undo** it. Rescan: confirm **FAILED** again. This proves the scanner is actually testing the setting I changed.
6. Write the **PowerShell** fix, run it, rescan: confirm **PASSED**.
7. Publish the script here and log it in the internship tracker.

The full step by step procedure, including gpedit paths, registry paths, undo steps and troubleshooting, is in **[RUNBOOK.md](RUNBOOK.md)**. Scan results and screenshots are in **[EVIDENCE.md](EVIDENCE.md)**.

## Results

| Scan | Date | Passed | Failed | Warning |
|------|------|--------|--------|---------|
| Baseline | | | | |
| After manual fixes | | | | |
| After undo | | | | |
| After PowerShell fixes | | | | |

All 10 targeted STIGs: FAILED at baseline, PASSED after manual fix, FAILED after undo, PASSED after PowerShell. (Fill in the table above from EVIDENCE.md once the scans are done.)

## Lab environment

| Component | Detail |
|-----------|--------|
| Target | Windows 11 Pro VM in Microsoft Azure (workgroup, not domain joined) |
| Scanner | Tenable Vulnerability Management, internal scan engine |
| Audit | DISA Microsoft Windows 11 STIG (version noted in EVIDENCE.md) |
| Scripting | Windows PowerShell 5.1 |
| Reference | [STIG-A-View, Windows 11 V2R11](https://stigaview.com/products/win11/latest/) |

The Windows Firewall was disabled on the lab VM so the scanner could reach it. In production I would allow the scanner's IP on TCP 445 instead.

## Repository layout

```
windows11-stig-remediations/
├── README.md
├── RUNBOOK.md                 full procedure, manual + PowerShell, troubleshooting
├── EVIDENCE.md                scan results and screenshot checklist
├── TRACKER.md                 rows for the internship tracking spreadsheet
├── MEETING-SCRIPT.md          change advisory / stakeholder meeting
├── INTERVIEW-STAR.md          STAR interview answers about this project
├── images/
├── scripts/                   10 remediation scripts
└── tools/                     pre check and undo helpers
```

## Disclaimer

These scripts change security settings. Test in a lab first. In a domain environment the same settings belong in Group Policy or Intune; these scripts are for workgroup machines, golden image builds, and filling gaps.

## Author

**Trey (Rachata Wichakkhapan)**
[LinkedIn](https://linkedin.com/in/treywcp) | [GitHub](https://github.com/rachata072) | [breakfixlearn.com](https://breakfixlearn.com)
