# INTERVIEW SCRIPTS (STAR Method)

Five questions you are likely to get about this project, each answered with Situation, Task, Action, Result. Read them, then put them in your own words. Replace any number in square brackets with your real scan result.

---

## Q1. "Tell me about a time you hardened a system against a security standard."

**Situation:** During my cybersecurity internship with LogN Pacific, I had a Windows 11 virtual machine in Azure that was built from a standard image. A credentialed Tenable scan against the DISA Windows 11 STIG showed [___] failed compliance checks.

**Task:** My job was to pick STIGs from those failures, fix them, prove the fix with a rescan, and turn each fix into a reusable PowerShell script that could be published and used again.

**Action:** I chose ten, focusing first on logging because the Security log was only 20 MB and would overwrite itself within hours. For each one I read the check text on STIG-A-View, fixed it by hand in Group Policy, the registry, Services, or Local Security Policy, rebooted and rescanned. Then I deliberately undid the fix and rescanned to prove the scanner was testing exactly the setting I changed. After that I wrote a PowerShell script that applies the fix, verifies it, and returns a pass or fail exit code, and I rescanned again.

**Result:** All ten went from FAILED to PASSED, and the overall failed count dropped from [___] to [___]. The ten scripts and a runbook are on my GitHub, and each one is logged on the internship tracking sheet that HR uses for employer verification.

---

## Q2. "Why did you undo your fix? Isn't that wasted time?"

**Situation:** The methodology for the lab was: fix manually, rescan, then undo the fix and rescan again before writing the script.

**Task:** I had to decide whether that extra scan was worth the 10 to 15 minutes each time.

**Action:** I kept it, because a passing result on its own does not prove much. The check might be looking at a different registry path, or the setting might already have been applied by something else. When I undid each fix and the finding came back as FAILED, that proved a direct cause and effect between my change and the scanner result. To save time I batched the scans into three rounds: all manual fixes, all undos, all scripts, instead of thirty separate scans.

**Result:** It actually caught a real problem. [Example if it happened to you: on WN11-AU-000050 the undo in Group Policy did not make the check fail, because advanced audit settings stay applied after the GPO is set back to not configured. I had to also run auditpol to clear it.] That taught me that "not configured" in Group Policy does not always mean "back to default", which matters a lot when you plan a rollback.

---

## Q3. "Tell me about a time a security change could have hurt users. How did you handle it?"

**Situation:** One of the STIGs, WN11-00-000175, requires disabling the Secondary Logon service. That service powers "Run as different user", which helpdesk techs commonly use to install software with admin rights on a user's machine.

**Task:** I needed to close a credential abuse path without breaking a workflow the helpdesk relied on.

**Action:** In my change proposal I listed every group affected by each of the ten settings, not just the technical details. For Secondary Logon I proposed two alternatives for the helpdesk: signing in with the admin account directly, or using the remote support tool's own elevation, which is audited. I also proposed a grace period before full rollout and a documented exception process with an owner and expiry date for machines that truly need the service.

**Result:** In the CAB role play the change was approved with a pilot ring and a two week grace period for the helpdesk. The lesson I took away was to ask "who uses this feature today?" before putting any hardening change on the list, and to talk to that team before the meeting, not during it.

---

## Q4. "How would you roll these out to 500 machines?"

**Situation:** My lab was one workgroup VM, but in a real company it would be hundreds of domain joined or Intune managed laptops.

**Task:** Explain how the lab work scales.

**Action:** For domain machines, I would put the settings in a dedicated GPO, linked to a pilot OU first, because Group Policy keeps reapplying the settings and stops drift. For Intune machines, the same settings exist in the Settings Catalog, and my scripts can run as Intune Remediations because each one exits 0 for compliant and 1 for not compliant. The scripts also cover the golden image build so new machines start compliant. Then a scheduled Tenable compliance scan confirms nothing has drifted.

**Result:** The approach is pilot ring, one week of SIEM tuning, then the wider fleet, with a per control rollback script. That is the plan I documented in the runbook and meeting script.

---

## Q5. "Pick one STIG and explain why it actually matters."

**Situation:** WN11-CC-000038 requires WDigest authentication to be disabled by setting `UseLogonCredential` to 0.

**Task:** Understand why a setting that is "already off by default" on Windows 11 still fails the scan.

**Action:** I found that Windows 11 behaves as if WDigest is disabled, but the registry value does not exist, and the STIG says a missing value is a finding. The reason is attacker behaviour: after getting admin rights, an attacker can set `UseLogonCredential` to 1, wait for an administrator to log in, and then use Mimikatz to read that admin's password in cleartext from LSASS memory. Setting the value explicitly to 0 means a change to 1 is a clear, alertable event, and the scan will flag it.

**Result:** I fixed it in the registry, proved it with a rescan, and wrote the script. In the interview I can now explain not just "what registry key" but "what attack it stops and how I would detect someone turning it back on", which is the difference between following a checklist and understanding the control.

---

## Quick facts to remember

| Item | Answer |
|------|--------|
| Number of STIGs | 10 |
| Scanner | Tenable Vulnerability Management, credentialed Advanced Network Scan, DISA Windows 11 STIG audit |
| Target | Windows 11 VM in Azure |
| Fix methods | Group Policy, Registry, auditpol, Local Security Policy, Services, PowerShell |
| Proof | Fail, manual pass, undo fail, PowerShell pass |
| Biggest lesson | "Not configured" is not always "default"; and talk to the people affected before the CAB |
| GitHub | github.com/rachata072/windows11-stig-remediations |
