# MEETING SCRIPT: Windows 11 STIG Hardening, Change Advisory Board

A realistic role play of the meeting where this change gets approved. Read it out loud once before an interview; it is the "business side" of the project that most candidates cannot talk about.

## The cast

| Name | Role | What they care about |
|------|------|----------------------|
| **Jordan** | Security Analyst (presenter, this is you) | Closing the audit findings with evidence |
| **Priya** | Security Lead | Risk, audit deadline, detection coverage |
| **Marcus** | IT Operations Manager, CAB chair | Change risk, rollback plan, outage windows |
| **Sam** | Endpoint / Desktop Team Lead | Helpdesk workload, user complaints, tools breaking |
| **Aisha** | SOC Analyst | Log volume, SIEM ingestion, alert quality |

## The problem in one paragraph

A credentialed Tenable compliance scan against the DISA Windows 11 STIG baseline flagged a list of failed controls on the standard Windows 11 build. Ten were picked as the first wave because they are low risk, high value, and can be fixed with a script. Most of them are about **visibility**: the event logs are so small they overwrite themselves within hours, PowerShell activity is not recorded, and process creation is not audited. If an incident happened today, the SOC would have very little to investigate with. The rest close well known attack paths: WDigest cleartext credentials, USB autorun, password reuse, and the Secondary Logon service.

## Who is affected by this change

| Group | Impact | Mitigation |
|-------|--------|------------|
| All Windows 11 users | AutoPlay no longer pops up for USB drives. Cannot reuse any of their last 24 passwords. | Short notice from IT; users open USB drives from File Explorer. |
| Helpdesk / desktop techs | "Run as different user" and `runas` stop working (Secondary Logon disabled). | Techs sign in with their admin account or use the remote support tool's elevation. Documented exception process for the few machines that truly need it. |
| SOC | More events: 4688 process creation, 4104 script blocks, transcripts. | Aisha tunes SIEM ingestion and filters noisy known good processes. |
| Storage | Security log can grow to about 5 GB per machine. | It is a cap, not a reservation; standard builds have plenty of headroom. Logs forward to the SIEM anyway. |
| Developers / admins who use PowerShell | Everything they type in PowerShell is transcribed. | Folder is write only for users; transcripts are readable only by admins and SYSTEM. Reminder not to paste secrets into the console. |

---

## Script

**Marcus:** Okay, next on the CAB agenda. Jordan, you have the Windows 11 STIG change. Go ahead.

**Jordan:** Thanks, Marcus. Short version: our last compliance scan against the DISA Windows 11 STIG flagged our standard build on a long list of controls. I am asking to fix ten of them in this first wave. I picked these ten because they are configuration only, they do not need new software, and I have tested every one of them in the lab.

**Priya:** Remind everyone why these ten and not the scariest ones on the list.

**Jordan:** Two reasons. First, six of the ten are about logging. Right now the Security log on a Windows 11 machine is 20 MB. On a normal workday that rolls over in a few hours. If someone phished a user on Monday and we found out on Thursday, the evidence would already be gone. Same story for PowerShell: we do not record script blocks or transcripts, and we do not audit process creation. Second, the other four close known attack techniques that do not need any exploit at all, like WDigest, which lets an attacker read cleartext passwords from memory.

**Aisha:** I want to jump in on the logging. More logs is good for me, but I need to know what is coming. What are the event IDs?

**Jordan:** 4688 for process creation in the Security log, 4104 for script block logging in the PowerShell Operational log, and plain text transcripts in `C:\ProgramData\PS_Transcript`. In the lab, a normal idle VM produced a few hundred 4688 events an hour. A developer machine will be a lot more.

**Aisha:** Fine, I can filter known good parent and child pairs. Can you give me a week on a pilot group before it goes wide so I can tune it?

**Jordan:** Yes, that is already in the rollout plan. Pilot ring first.

**Marcus:** Let me ask about the testing. How do you know the scripts do what they say?

**Jordan:** For each STIG I did the same loop. Baseline scan, it fails. I fix it by hand in Group Policy or the registry, rescan, it passes. Then I undo the fix and rescan to prove it fails again, which tells me the scanner is really checking the thing I changed and I did not just get lucky. Then I write the PowerShell version, run it, rescan, it passes. All the screenshots are in the evidence file in the repo.

**Marcus:** I like the undo step. That is also my rollback plan, right?

**Jordan:** Exactly. There is an undo script that takes a STIG ID and puts that one setting back to the Windows default. Rollback for any single control is under a minute, no reboot required for most of them.

**Sam:** Okay, I have a problem with one of them. The Secondary Logon one. My techs use "Run as different user" all day. A user calls, the tech remotes in, shift right clicks the installer, runs it as their admin account. If you disable that service, that workflow is dead.

**Jordan:** That is a fair point, and it is the reason I put this one last in the list. The STIG wants it disabled because that same feature lets a process start under different credentials from inside someone else's session. That is a lateral movement trick. What we did in the lab test: the tech either signs the user out and signs in as the admin account, or uses the elevation feature in the remote support tool, which goes through its own audited service.

**Sam:** Signing the user out is slower. They lose their open windows.

**Priya:** How often does that happen per day, Sam?

**Sam:** Honestly, maybe fifteen, twenty times across the team.

**Priya:** Then I would rather we take the small time hit than leave a credential abuse path open on every machine. But I do not want to blindside the helpdesk.

**Marcus:** Proposal. Secondary Logon goes out in the pilot like everything else, but Sam's team gets two weeks to move to the remote tool elevation before it goes to the wider fleet. If there is a machine that truly needs it, it goes through a documented exception with an owner and an expiry date.

**Sam:** I can live with that if the exception process is actually quick.

**Jordan:** I will write the exception request template this week and send it to you first.

**Sam:** Next thing. Password history to 24. Users are going to call us when they cannot reuse their old password.

**Jordan:** They will, at first. The upside is that when we force a password reset after a phishing incident, the user cannot just set it back to the password the attacker already has. I would suggest a two line note in the IT newsletter before rollout so the first call is not a surprise.

**Priya:** And on the domain machines this will come from the domain policy anyway, so the script is mainly for the build image and the non domain machines, correct?

**Jordan:** Correct. In production these settings belong in Group Policy or Intune. The scripts cover the golden image, workgroup machines, and anything Intune misses. They also return an exit code, so we can run them as an Intune remediation script and get a report back.

**Marcus:** What about disk space on the 5 GB Security log?

**Jordan:** It is a maximum, not a reservation. The log only grows as events come in, and once logs are forwarding to the SIEM the local copy is the backup. Our standard image has well over that free.

**Aisha:** One more on transcription. People paste API keys and passwords into PowerShell. Those will end up in a text file.

**Jordan:** Yes, that is the risk with transcription. The script locks the folder so standard users can only write to it, not read it. Only administrators and SYSTEM can read transcripts. I would add a line in the admin guidelines: never paste secrets into the console, use a credential prompt or a secret store.

**Priya:** Good. Put that in the change record as a known risk with that mitigation.

**Marcus:** Okay. Here is what I am hearing. Pilot ring of, say, twenty machines including two from Sam's team and two developer machines. One week of pilot for Aisha to tune ingestion. Secondary Logon gets a two week grace for helpdesk before full rollout. Rollback is the undo script per control. Any objections?

**Sam:** No objection with the grace period.

**Aisha:** None from me.

**Priya:** Approved from security.

**Marcus:** Approved. Jordan, please attach the rescan evidence to the change ticket and send the user notice through comms before the pilot starts.

**Jordan:** Will do. Thanks, everyone.

---

## Action items from the meeting

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | Attach baseline and final Tenable reports to the change ticket | Jordan | Before pilot |
| 2 | Write Secondary Logon exception request template | Jordan | This week |
| 3 | Move helpdesk elevation to the remote support tool | Sam | 2 weeks |
| 4 | Tune SIEM ingestion for 4688 / 4104 during pilot | Aisha | Pilot week |
| 5 | IT newsletter note: AutoPlay and password history | Jordan with Comms | Before pilot |
| 6 | Add "no secrets in the PowerShell console" to admin guidelines | Priya | Before full rollout |

## What to say if asked "what would you do differently?"

"I would have talked to the helpdesk before the CAB, not during it. The Secondary Logon change was technically correct, but Sam heard about it for the first time in the meeting. Now I check every STIG for 'who uses this feature today' before I put it on the change list."
