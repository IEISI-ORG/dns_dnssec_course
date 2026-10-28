# Module 11, Lab 11.4: the incident drill (instructor)

This repository is public: participants can read this file and the scripts
in advance. Grade the evidence, its order and the method (Practical
Assessment 6A tasks 2 and 4), not the name of the cause. Each fault has two
variants; choose the variant and the order yourself and give only the
symptom. Evidence taken from `/var/backups/m11` or from the sudo lines in
the journal does not count as method.

## Before the drill

- You need root on every team's VM 1 without a sudo prompt (root login
  or `NOPASSWD` sudo for your account): with stdin redirected, `sudo` cannot
  prompt and stops with "a terminal is required".
- Grade 6A task 1 (the monitoring) during Labs 11.2-11.3, before the drill:
  Lab 11.4's clean-up removes it.
- Lab 11.4 has 35 minutes: about 9 per fault and 5 for the clean-up and the
  debrief. Set each fault for **all teams in one loop**, so the waits for
  alerts and caches overlap.

## Setting the faults

Faults 1 and 2 are set on each team's VM 1, as root, without copying the
script there; it prints only "fault set", also when a fault is already in
place. With `VM1S` holding the teams' "NN address" pairs (`teams.conf` has
them):

```sh
# fault 1, variant listen (default) or acl
while read -r nn a; do ssh "$a" "sudo sh -s -- set 1 $nn listen" < faults.sh; done < VM1S
# fault 2: VM 2's address (lame: REFUSED) or an unused address (time-outs)
while read -r nn a; do ssh "$a" "sudo sh -s -- set 2 $nn <that team's VM 2>" < faults.sh; done < VM1S
```

Fault 3 is set at the registry, on the instructor server, in `labs/instructor`:

```sh
for nn in 01 02 03; do sh ../module11/instructor/ds-fault.sh set $nn digest; done   # or: tag
```

Wait until the alert or check shows the fault before you give the symptom
(fault 1: about 1.5 minutes to the alert; fault 3: up to 2 minutes before
the resolver's cached DS expires).

## Symptoms to give, causes and fixes

| Fault | Symptom to give | Cause | What the team should find | Fix |
|---|---|---|---|---|
| 1 listen | "Users outside cannot resolve `teamNN.example`. The server team says `named` is running." | `listen-on { 127.0.0.1; }; listen-on-v6 { ::1; };` added to VM 1's options: `named` answers on loopback only | DNSProbeFailed for VM 1; `zonecheck.sh`: "connection refused"; on VM 1 `rndc status` "server is up and running" and the exporter still reports (`bind_up 1`); `ss -lnu` shows `127.0.0.1:53` but not VM 1's address; the `listen-on` lines in `named.conf.options` | delete the two lines, `named-checkconf`, `rndc reconfig`; the alert clears within about 30 s |
| 1 acl | the same | `allow-query { any; }` replaced by `allow-query { 127.0.0.1; };` in VM 1's options | DNSProbeFailed for VM 1; `dig @VM1` from VM 2: REFUSED; `zonecheck.sh`: "status: REFUSED"; `named` up, listening on its address; the `allow-query` line | put `allow-query { any; };` back, check, reconfig |
| 2 | "Nothing is down. A colleague changed the zone this morning." | `@ IN NS ns2.teamNN.example.` and `ns2 IN A <address>` added to the zone with a new serial: with VM 2's address a server that is not authoritative (a lame server, RFC 9499); with an unused address, one that does not answer | no Prometheus alert (its probe list names only VM 1); `zonecheck.sh`: "NS sets differ" (WARNING) and "ns2 ... status: REFUSED" or "timed out" (CRITICAL); `dig @VM1 teamNN.example NS` lists ns2; the zone file and its serial. VM 2's "BADKEY" and "NOTAUTH" lines for VM 1's NOTIFYs are not evidence: Lab 6.4's `also-notify` with the key causes them at every serial change | remove the two lines, raise the serial, `rndc reload teamNN.example`; better: ask whether a second server was intended, and if so set it up as a secondary before listing it |
| 3 digest / tag | "Some users get SERVFAIL for `teamNN.example`; others are fine." (validating resolvers fail, non-validating ones work) | the DS at the registry has a wrong digest (variant digest) or a wrong key tag (variant tag), as after a mistyped DS submission | `dig` through VM 2: SERVFAIL (BIND 9.20.30 gave no EDE in the test); `+cd` answers; VM 2's log "no valid signature found (DS)", "broken trust chain"; `zonecheck.sh`: "DS ... matches no DNSKEY"; `dig @registry teamNN.example DS` against `dnssec-dsfromkey -2` on the zone's DNSKEY | the team sends you the correct DS (`dig @VM1 teamNN.example DNSKEY \| dnssec-dsfromkey -2 -f - teamNN.example`); you run `sh ../module11/instructor/ds-fault.sh fix NN`; AD returns within about a minute (DS TTL 60) |

Good method, for all three: what users see first (through the resolver),
then each server directly, then the parent; the logs; one change at a time,
written down with its time; the same commands again to verify; the alert
or check back to OK. Points off for changing configuration before looking,
or for a fix that is not verified.

## Debrief (5 minutes)

Which of `zonecheck.sh`'s checks could the Prometheus probes make, and why
did fault 2 raise no alert? (The probes ask a fixed list of addresses;
zonecheck takes its list from the parent and the zone.)

## Undo (rescue) and clean

If a team is stuck or the session runs out:

```sh
ssh <VM 1> 'sudo sh -s -- undo 1 NN' < faults.sh    # the saved options
ssh <VM 1> 'sudo sh -s -- undo 2 NN' < faults.sh    # the saved zone, serial one above the current one
sh ../module11/instructor/ds-fault.sh fix NN          # in labs/instructor
```

Both undos stop with "nothing saved to undo" when there is no saved copy,
and check the file before they write it. After the drill, on every VM 1:

```sh
ssh <VM 1> 'sudo sh -s -- clean NN' < faults.sh     # deletes /var/backups/m11
```

`ds-fault.sh fix` rebuilds the DS from the DNSKEY RRset that the team's
server publishes now.

## Grading notes (6A)

- Task 2 (10 points): faults 1 and 3, about 5 points each: detection (which
  alert or check, and when), the evidence in a sensible order, the cause
  shown by output, the fix verified.
- Task 4 (5 points): the incident records (`../incident-record.md`), one
  per fault: times, evidence with commands, cause, fix, verification,
  time to detect and to recover, one prevention. Fault 2's record is the
  short one (cause, why no alert fired, the check that caught it). The
  records may be finished after the session; they are due by the end of
  Day 6.
