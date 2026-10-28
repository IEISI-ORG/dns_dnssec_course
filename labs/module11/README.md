# Module 11 lab kit: DNS monitoring, incident response and performance

Files for Labs 11.1-11.4 of `modules/module11-monitoring-incident-response.marp.md`.
The labs read BIND's counters on both team VMs, measure the resolver under a
small capped load, capture its traffic with dnstap, run Prometheus with two
exporters and alert rules on VM 2, check the zone across its servers and its
parent with `tools/zonecheck.sh`, and then handle three faults that the
instructor sets. Everything is undone at the end.

## Starting state (Day 6)

The two VMs as Modules 6-9 left them (Module 10 has no lab on these VMs yet;
if it gets one, it must leave them as they were):

- **VM 1** (192.0.2.30 on the slides): BIND authoritative for `teamNN.example`
  (signed with Module 7's `lab` policy, DS at the registry) and
  `manualNN.example` (signed by hand in Lab 7.1, DS at the registry);
  Module 6's options (`recursion no`, response rate limiting enforcing) and
  logging file; Lab 6.4's TSIG key with its `allow-transfer` and
  `also-notify` lines, so VM 1 sends a signed NOTIFY to VM 2 at every serial
  change and VM 2 logs "tsig verify failure (BADKEY)" and "NOTAUTH" for each
  (tested): background noise, not a fault.
- **VM 2** (192.0.2.10): the BIND validating resolver with Module 6's
  options, the `example` static-stub zone, Module 7's trust anchor for
  `example.`, Module 8's DoT (853) and DoH (443) listeners with the team
  certificate (`/etc/bind/tls`). **Check first** (Lab 11.1 step 1): VM 2
  must answer plain DNS on port 53. Module 8's kit file, before PR #17,
  added only the 853 and 443 `listen-on` lines, and with no other
  `listen-on` named then stops listening on port 53 (tested); the fix is
  `listen-on port 53 { any; };` and `listen-on-v6 port 53 { any; };`, as
  the Module 8 slide shows.
- **Instructor server:** the registry for `example.` (192.0.2.53). The `m01`
  profile is off since the Day 3 lunch break.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `common/named.conf.stats` | both VMs, appended to `/etc/bind/named.conf.local` (save a copy as `named.conf.local.m09` first): statistics channel on 127.0.0.1:8053 | 11.1 (copy back in 11.4) |
| `tools/rates.sh` | run on either VM: per-second rates and the cache hit ratio from two readings of the channel | 11.1 |
| `vm1/names.txt` | VM 1, with your `NN`: the dnsperf query file of names that exist | 11.1 |
| `vm2/dnstap.options` | VM 2, two lines pasted inside `options { }` (save `named.conf.options` as `.m09` first); at most 3 files of 20 MB | 11.1 (removed in the same lab) |
| `vm1/prometheus-bind-exporter` | VM 1, `/etc/default/` (save Debian's copy as `.m09`): the exporter on VM 1's address, port 9119 | 11.2 |
| `vm2/prometheus`, `vm2/prometheus-bind-exporter`, `vm2/prometheus-blackbox-exporter` | VM 2, `/etc/default/` (save Debian's copies): every listener on 127.0.0.1 | 11.2 |
| `vm2/prometheus.yml`, `vm2/blackbox.yml`, `vm2/dns-rules.yml` | VM 2, `/etc/prometheus/` with your `NN` and addresses (save Debian's `prometheus.yml` and `blackbox.yml`); copy `/etc/bind/tls/ca.crt` to `/etc/prometheus/team-ca.crt` (mode 644; never `ca.key`) | 11.2 |
| `tools/alerts.sh` | VM 2: the alerts Prometheus holds now, one per line; exit 2 when Prometheus does not answer | 11.2-11.4 |
| `test/dns-rules.test.yml` | rule tests for `vm2/dns-rules.yml`: `promtool test rules test/dns-rules.test.yml` in the kit directory | 11.2 |
| `tools/zonecheck.sh` | VM 2 (or VM 1): servers from the parent and the zone (IPv4 and IPv6), `aa`, serials, NS sets, glue, DS (SHA-1, SHA-256, SHA-384) against the DNSKEY that signs the DNSKEY RRset, signature time left (default thresholds 4 and 2 days, below BIND's refresh point); Monitoring Plugins exit codes | 11.3-11.4 |
| `incident-record.md` | one copy per fault, handed in (Practical Assessment 6A task 4) | 11.4 |
| `instructor/` | the instructor's fault scripts and answers; not for participants before the drill | 11.4 |
| `test/` | rehearsal harness (below); not for participants | - |

Replace `NN` with your team number and the slide addresses with your lab
sheet's: registry 192.0.2.53, VM 1 192.0.2.30, VM 2 192.0.2.10.

## VM image

Add to the image the Modules 2-9 VMs are built from, with
`--no-install-recommends` (Debian's `prometheus` recommends
`prometheus-node-exporter`, which the labs do not use):

```sh
apt-get install --no-install-recommends prometheus prometheus-bind-exporter prometheus-blackbox-exporter
systemctl disable --now prometheus prometheus-bind-exporter prometheus-blackbox-exporter
rm -rf /var/lib/prometheus/metrics2/*    # the seconds of data the first start wrote
```

Debian enables and starts the three services on installation; Prometheus
then listens on every address (port 9090) and the exporters on 9115 and
9119. Lab 11.2 starts them with the kit's `/etc/default` files, which bind
them to 127.0.0.1 (VM 1's exporter to VM 1's address). `dnsperf` (Module 6),
`curl`, `jq` (Module 4) and `bind9-dnsutils` (`dig`, `dnstap-read`) are
already in the image. Tested versions (Debian 13, 2026-10-28 AEST, 27 October UTC): prometheus
2.53.3+ds1-2, promtool 2.53.3+ds1-2, prometheus-bind-exporter 0.8.0-1+b6,
prometheus-blackbox-exporter 0.26.0-1, dnsperf 2.14.0-5, bind9 1:9.20.30-1~deb13u1.
Offline path: the pre-installed image; with a mirror, the two commands above.

Prometheus 2.53 is the version Debian 13 ships and supports; upstream's
support for 2.53 (an LTS release) ended on 31 July 2025 (prometheus.io
release cycle page, read 28 October 2026). Grafana is not packaged in
Debian; the labs use Prometheus's own query API (`promtool query`) and, if
you want graphs, its web page through an SSH tunnel
(`ssh -L 9090:127.0.0.1:9090 <VM 2>`).

## Load and containment

The only load is `dnsperf -Q 50 -l 10` (50 queries per second for 10
seconds) from VM 1 to the team's own resolver (VM 2), twice, as in Module 6;
the resolver sends at most that rate on to the team's own VM 1. The probes
ask VM 1 and VM 2 once every 15 seconds; `zonecheck.sh` sends a few dozen
queries per run, some to the registry. Nothing else leaves the team's VMs.
The latency figures on the slides come from the test lab (two containers on
one Docker bridge on a 12-CPU host): they are a comparison between two
runs, not a property of your hardware.

## End state (what Module 12 starts from)

Both VMs as Module 9 left them: `named.conf`, `named.conf.local` and
`named.conf.options` byte-equal to the saved copies; no statistics channel,
no dnstap; the three Prometheus services stopped and disabled, their
`/etc/default` files and Debian's `prometheus.yml` and `blackbox.yml` back,
`dns-rules.yml` and `team-ca.crt` deleted, `/var/lib/prometheus/metrics2`
emptied; `/var/backups/m11` removed (`faults.sh clean`); `teamNN.example` two serials higher (fault 2 and its fix; more if the instructor's undo or a variant was used); the DS
at the registry matches the team's KSK again. On VM 2 only `named` listens
(53, 853, 443, and 953 on loopback).

## Instructor side

`instructor/faults.sh` sets faults 1 and 2 on a team's VM 1 over SSH (root
login or `NOPASSWD` sudo) and `clean` removes its saved copies
(`/var/backups/m11`) after the drill; `instructor/ds-fault.sh` sets fault 3
at the registry. Each fault has two variants. Their README has the
symptoms to give, the answers and how to grade. This repository is public,
so the drill is graded on evidence and method (Practical Assessment 6A
tasks 2 and 4), not on naming the cause.

## Rehearsal harness (`test/`)

`test/rehearse.sh [TRANSCRIPT]` starts the instructor stack
(`labs/instructor`, no profile) on an internal Docker bridge with no route
out, and two Debian 13 containers built from `test/Dockerfile`, set up as
Modules 6-9 leave the VMs (VM 1 with Lab 6.4's TSIG lines; VM 2's options
with the port 53 `listen-on` lines that the Module 8 slide shows). Both mount `/run` `noexec`, as Debian
13 does. It then runs every step of Labs 11.1-11.4, including the
instructor's faults and their variants (piped in as over SSH, and
`ds-fault.sh` against the stack), the instructor's undo and clean, the
rule tests (`promtool test rules`) and the clean-up, and checks each
checkpoint. `KIT_DIR=<copy>` runs
it against a changed kit (mutation tests); `SETUP_ONLY=1` stops after the
set-up and leaves everything running. It takes about 10 minutes, most of it
waiting for alerts (`for: 1m`) and for cached DS records to expire, and
removes its containers, network, volumes and work directory; the images
and the transcript stay. Needs Docker with Compose v2; the image build
needs Internet access, the lab steps do not.

## Tested

2026-10-28 AEST (27 October UTC), Debian 13 packages as listed above, images built with
`--pull --no-cache`. Measured in the harness (six runs; your times will
differ): DNSProbeFailed fired 65-86 s after VM 1's `named` stopped (15 s
scrapes plus `for: 1m`) and cleared 14-29 s after it started; after the
wrong DS was published, the resolver returned SERVFAIL 103-115 s later
(cached DS and DNSKEY had to expire), and AD again 57-60 s after the fix. Memory on the test
host: Prometheus 78 MiB, the blackbox exporter 25 MiB, bind_exporter
22 MiB resident.

Not tested: real VMs (`systemctl` and the Debian units, `journalctl`,
AppArmor enforcement; Docker does not enforce AppArmor, so dnstap's path in
`/var/cache/bind` was checked against the profile's text only); `apt install`
on a running VM; the Prometheus web page through an SSH tunnel; IPv6
transport; a 2-vCPU, 2 GB VM.
