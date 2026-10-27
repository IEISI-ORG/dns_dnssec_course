# Module 3 lab kit: DNS server types

Files for Labs 3.1-3.4 of `modules/module03-dns-server-types.marp.md`.
In Module 3 each team starts BIND on its VM 2 as a recursive resolver,
tries conditional forwarding, makes VM 2 a secondary for `teamNN.example`
(served by VM 1 since Module 2), stops VM 1 to see what still works, and
then removes the secondary again.

## Topology (Day 2 morning)

| Machine | Address on the slides | Role in Module 3 |
|---|---|---|
| Participant VM 1 | 192.0.2.30 | primary for `teamNN.example`, as Module 2 left it; its query log shows who asks it |
| Participant VM 2 | 192.0.2.10 | resolver (Labs 3.1-3.2), also a stealth secondary for `teamNN.example` (Labs 3.3-3.4), a resolver only at the end |
| Registry / lab TLD (`parent`) | 192.0.2.53 | serves `example.`; delegates `teamNN.example` to VM 1 only (`teams.conf`); target of VM 2's static-stub zone |
| Lab resolver (`m01-resolver`) | 192.0.2.55 | Module 1's resolver: the forwarder in Lab 3.2 and "a resolver elsewhere" in Lab 3.4 |

The instructor stack keeps the `m01` profile on through Day 2 (instructor
README). Use the lab sheet addresses in place of the slide addresses.

## Why VM 2 is a stealth secondary

The registry delegates each team to one address (`teams.conf`, VM 1), and
the zone's NS set is `ns1` only. VM 2 is therefore a stealth server
(RFC 1996 §2.1): authoritative for the zone, answering with `aa`, but named
in no NS record, so VM 1 must list it in `also-notify`. RFC 2182 §5.1
describes the same arrangement for site servers that answer local queries
directly. Lab 3.4 shows the limit: with VM 1 stopped, VM 2 still answers,
but a resolver following the delegation (the lab resolver) gets SERVFAIL.
Making VM 2 a listed `ns2` would need an NS and an A record in the zone and
the same NS and glue at the registry; the course does not do that, because
Module 6 Lab 6.4 and Module 7 need VM 2 as a resolver that does not serve
the zone.

## Packages and the offline path

VM 2's image carries `bind9`, `bind9-utils` and `bind9-dnsutils` with
`named` disabled and without `/etc/bind/rndc.key`, as VM 1's did before
Module 2 (see `../module02/README.md` for the image steps). Lab 3.1 makes
the VM's own control key and starts it:
`sudo rndc-confgen -a -u bind; sudo systemctl enable --now named`. With a
mirror, `sudo apt install bind9 bind9-utils bind9-dnsutils` does the same.

Every lab step talks only to VM 1, VM 2, the registry and the lab resolver.
The lab TLD `example.` is not in the real root, so VM 2 needs the kit's
static-stub zone and `validate-except { "example"; }` to resolve lab names:
with Debian's defaults it answers SERVFAIL offline (no root server
reachable) and NXDOMAIN with Internet access (the real root proves
`example.` does not exist). With Internet access VM 2 also resolves real
names, with `ad`.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `vm2/named.conf.options` | VM 2, replaces `/etc/bind/named.conf.options`: Debian's `directory`, BIND's recursion defaults written out, `validate-except { "example"; }` | 3.1 |
| `vm2/named.conf.local` | VM 2, replaces `/etc/bind/named.conf.local`: static-stub zone `example` pointing at the registry | 3.1, 3.2 (restored), 3.4 (end state) |
| `vm2/named.conf.forward` | VM 2: the forward zones of Lab 3.2, (a) to the lab resolver, then (b) the registry and (c) an unused address (192.0.2.250 on the slides; the lab sheet names one) | 3.2 |
| `vm2/named.conf.secondary` | VM 2, appended to `named.conf.local`: the secondary zone, file `/var/cache/bind/db.teamNN.example` | 3.3, removed in 3.4 |
| `vm1/zone-transfer.snippet` | VM 1: two lines (`allow-transfer`, `also-notify`) inside the existing `zone "teamNN.example"` statement | 3.3, removed in 3.4 |
| `test/` | rehearsal harness (below); not for participants | - |

Set `NN` to the team number and the addresses to the lab sheet's.
After each configuration edit: `named-checkconf` (no root needed), then
`sudo rndc reconfig`; in Lab 3.2 also `sudo rndc flush`, so that the next
query goes out again. `rndc reconfig` also handles the zone type changing
from `static-stub` to `forward` and back (tested).

The secondary's file is in `/var/cache/bind`, where Debian's AppArmor
profile lets `named` write, and in BIND's raw format by default; read it
with `named-compilezone -f raw -F text -o - teamNN.example
/var/cache/bind/db.teamNN.example` (owner `bind`, mode 644: no `sudo`
needed; the same for the cache dump `named_dump.db`; both checked by the
harness). Its name differs on purpose from
Module 6's `teamNN.example.db`: a copy left behind could not be mistaken for
Module 6's TSIG secondary.

## What Module 3 leaves for later modules

Lab 3.4 removes the secondary zone and its file from VM 2 and the two
snippet lines from VM 1, so that:

- VM 1 is the primary with Module 2's zone statement and BIND's default
  `allow-transfer { none; }`. Module 6 Lab 6.4 adds `allow-transfer` and
  `also-notify` with a TSIG key; two `allow-transfer` lines in one zone
  statement would be a configuration error.
- VM 2 is a BIND resolver with this kit's `named.conf.options` and
  `named.conf.local`. Module 6 Lab 6.1 replaces both with its hardened files,
  which keep the same static-stub zone and `validate-except`; Module 7
  Lab 7.3 replaces `validate-except` with a trust anchor for `example.`;
  Module 8 adds DNS over TLS and HTTPS to the same `named`.
- Neither VM serves the other's role: Module 7 needs VM 2 to resolve and
  validate `teamNN.example`, not to serve it.

## Keys and secrets

Nothing secret is in this kit. The only key in Module 3 is VM 2's own rndc
key, made on the VM in Lab 3.1. Zone transfers here are authorised by
address only; Module 6 adds TSIG. `../.gitignore` blocks `*.key` in case a
key is copied into the repository by mistake.

## Tested

2026-10-28 on a Debian 13 host with Docker 29.9.2; the stand-in VMs carry
`bind9`, `bind9-utils` and `bind9-dnsutils` 1:9.20.30-1~deb13u1
(trixie-security), built with `build --pull --no-cache`.

- The stand-in image has no `/etc/bind/rndc.key` (removed after the
  package install, as the image-build rule in `../module02/README.md` asks),
  so Lab 3.1's `rndc-confgen -a -u bind` runs from the classroom state
  (owner `bind`, mode 600 afterwards, tested).
- `test/rehearse.sh`: starts the instructor stack (profile `m01`) on an
  internal Docker bridge, puts a stand-in VM 1 at 192.0.2.30 (set up as
  Module 2 left it, from `../module02/zones`) and a stand-in VM 2 at
  192.0.2.10, both with this kit mounted, and runs every step of Labs
  3.1-3.4 as the slides give them: Debian's defaults on VM 2, the kit's
  options and static-stub zone, VM 1's query log (VM 2 asking without RD,
  once per TTL), `+norec` refused under the static-stub zone, the cache
  dump and `flushname`; conditional forwarding (the lab resolver in VM 1's
  log), forwarding to the registry ("non-improving referral"), a dead
  forwarder; the refused and then allowed transfer with the log lines on
  both sides, NOTIFY and "AXFR-style IXFR", the same serial with `aa`, VM 2
  answering from its copy; VM 1 stopped, the lab resolver's SERVFAIL, the
  refresh failure, and the clean-up compared with the kit and Module 2's
  files. Every key generation and configuration reload is itself a
  checked step (a failed `rndc reconfig` or a missed edit fails the run at
  once; tested by breaking the dead-forwarder edit on purpose), log lines
  are polled for rather than slept for, and the dead-forwarder step
  requires the configured address and a delay of at least a second. 53
  checks, about a minute with the images built. It removes every
  container, network and volume it made; the transcript goes to the file
  given as the first argument, or to a new file under `$TMPDIR` (default
  `/tmp`), never into the repository.
- The theory slides' other outputs (zone expiry with short timers, IXFR
  with `ixfr-from-differences`, DNS64, the online root mirror and real
  NS sets) are recorded in the course's notes, with dates.

Not tested: real VMs (`sudo`, `systemctl`, `journalctl`, AppArmor; the
harness runs `named -g` and reads its log file); ipvlan on a real classroom
NIC (the dead-forwarder delay, 3067 ms on the Docker bridge, depends on the
network); IPv6 transport.
