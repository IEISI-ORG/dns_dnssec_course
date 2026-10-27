# Module 4 lab kit: DNS software platforms

Files for Labs 4.1-4.4 of `modules/module04-dns-software-platforms.marp.md`.
In Module 4 each team looks inside the BIND servers it already runs, puts
Unbound next to BIND on VM 2 and PowerDNS Authoritative (with an SQLite
database) next to BIND on VM 1, compares what the three answer, and then
switches the two newcomers off again.

## Topology (Day 2 afternoon)

| Machine | Address on the slides | Role in Module 4 |
|---|---|---|
| Participant VM 1 | 192.0.2.30 | BIND on port 53, primary for `teamNN.example` (Modules 2-3); PowerDNS on port 5300 (Lab 4.3) |
| Participant VM 2 | 192.0.2.10 | BIND on port 53, the resolver from Module 3; Unbound on port 5300 (Lab 4.2) |
| Registry / lab TLD (`parent`) | 192.0.2.53 | serves `example.`; Unbound's stub zone points at it |
| Lab resolver (`m01-resolver`) | 192.0.2.55 | Module 1's resolver: Unbound's forwarder in Lab 4.2 |

The instructor stack keeps the `m01` profile on until the end of Day 2
(instructor README). Use the lab sheet addresses in place of the slide
addresses.

## Why port 5300, and why two VMs are enough

The course gives each team two VMs from Module 1 to Module 9, and BIND owns
port 53 on both. A second resolver or authoritative server on the same VM
needs another address or another port; Module 4 uses port 5300 (as Module 8
does for Unbound on VM 1), so `dig -p 5300` reaches the newcomer and plain
`dig` still reaches BIND. Unbound goes on VM 2 (the resolver VM), PowerDNS on
VM 1 (the authoritative VM). Lab 4.4 stops and disables both and removes the
Module 4 files that change BIND, so Modules 5-8 find BIND alone on both VMs,
as Module 3 left them. Module 8 Lab 8.3 later runs Unbound on VM 1's
127.0.0.1 port 5300: PowerDNS must be stopped by then (Lab 4.4 step 5).

## Packages and the offline path

Add these to the VM image (the same image for both VMs), with a mirror:

```sh
sudo apt install --no-install-recommends unbound pdns-server pdns-backend-sqlite3 sqlite3 curl jq
sudo systemctl disable --now unbound pdns     # BIND keeps port 53
sudo /usr/libexec/unbound-helper root_trust_anchor_update   # root.key
```

`--no-install-recommends` matters: `pdns-server` recommends
`pdns-backend-bind`, whose `/etc/powerdns/pdns.d/bind.conf` (`launch+=bind`,
`bind-config=...`) makes PowerDNS refuse the kit's settings ("Fatal error:
Trying to set unknown setting 'bind-config'", reproduced in the code review),
so Lab 4.3 cannot start it. On an image that already has it: `sudo apt purge
pdns-backend-bind`. Lab 4.3 step 1 shows `/etc/powerdns/pdns.d` empty. The
other recommends are not needed (`dns-root-data`, which Unbound recommends,
comes with `bind9`). The stand-in image (`test/Dockerfile`) is built the
same way.

On a VM where BIND already runs, both services fail to start after the
install (tested: Unbound with "can't bind socket: Address already in use",
PowerDNS with "Unable to launch, no backends configured for querying"); that
is expected and harmless. Disable them anyway: an enabled `pdns` with a
backend but no `local-port` would race `named` for port 53 at boot. The
packages create no keys or secrets (Unbound's control channel is a local
socket). `/var/lib/unbound/root.key` is the public root trust anchor, which
Debian's unit writes when `unbound` first starts; without it
`unbound-checkconf` fails ("auto-trust-anchor-file ... does not exist"), so
the last line writes it in the image: Module 8 Lab 8.3 runs
`unbound-checkconf` on VM 1, where Unbound has never started. `openssl` is in the image from Module 2.

Every lab step talks only to the two VMs, the registry and the lab
resolver; nothing needs the Internet.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `vm2/named.conf.stats` | VM 2, appended to `/etc/bind/named.conf.local` after saving a copy as `named.conf.local.m03`: BIND's statistics channel on 127.0.0.1 port 8053 | 4.1 (the copy goes back in 4.4) |
| `vm1/db.lab4.teamNN.example` | VM 1, `/var/lib/bind/` with your `NN`: a zone for `rndc addzone`, deleted with `rndc delzone -clean` | 4.1 |
| `vm2/module04.conf` | VM 2, `/etc/unbound/unbound.conf.d/`: Unbound on port 5300, `access-control`, `domain-insecure`, stub zone for `example`; commented lines for the local data (4.2) and the stub zone to PowerDNS (4.4) | 4.2, 4.4 |
| `vm1/module04.conf` | VM 1, `/etc/powerdns/pdns.d/` (root:pdns 640): gsqlite3 backend, port 5300, API on 127.0.0.1:8081, query logging | 4.3 (deleted in 4.4) |
| `comparison-sheet.md` | one copy per team: the BIND/Unbound/PowerDNS table and two questions, with the assessor's notes for Practical Assessment 2B | 4.4 |
| `vm1/zonediff.sh` | run on VM 1: `sh zonediff.sh ZONE FILE SERVER [PORT]` compares a zone file with what a server transfers (AXFR), both in `named-checkzone -D -s full` form | 4.3, 4.4 |
| `vm1/fix-https.json`, `vm1/soa-edit-api.json`, `vm1/add-record.json` | request bodies for the PowerDNS API (`curl --data @file`); set `NN` in the first and last | 4.3 |
| `test/` | rehearsal harness (below); not for participants | - |

Set `NN` and the addresses to the lab sheet's. Commands that change BIND:
`named-checkconf`, then `sudo rndc reconfig`. Unbound: `sudo unbound-checkconf`,
then `sudo unbound-control reload` (which also clears its cache and
counters). PowerDNS reads its settings at start (`sudo systemctl restart
pdns`); zones and records live in the database.

## Keys and secrets

Nothing secret is in this kit. The PowerDNS API key is made on VM 1 in Lab
4.3 (`openssl rand -hex 16` into the header file `~/pdns-api.hdr`,
`X-API-Key: <key>`, mode 600, read by `curl -H @$HOME/pdns-api.hdr` so the
key is never on a command line; and `/etc/powerdns/pdns.d/api-key.conf`,
root:pdns 640) and deleted in Lab 4.4. Make it in a subshell,
`(umask 077; ...)`: a `umask 077` left in the shell makes later `sudo cp`
files unreadable for `named`. `../.gitignore` blocks `*.key`,
`api-key.conf`, `pdns-api.hdr`, SQLite files and BIND's `*.nzd` in case one
is copied into the repository by mistake.

## What Module 4 leaves for later modules

- VM 1: BIND exactly as Module 3 left it (`named.conf.options` as Debian
  installs it again after Lab 4.1 removes `allow-new-zones`; no zone added
  with `rndc addzone` left in `/var/cache/bind/_default.nzd`); PowerDNS
  stopped and disabled, its SQLite database may stay, `module04.conf`
  deleted (it binds 127.0.0.1:5300, Module 8's port); no API key on disk.
- VM 2: BIND with the team's own `named.conf.options` and
  `named.conf.local` from Module 3 (Lab 4.4 moves the copy saved in Lab 4.1
  back, which removes the statistics channel and keeps the team's lab-sheet
  addresses); Unbound stopped and disabled, `module04.conf` removed.
- Nothing listens on ports 5300, 8053 or 8081.
- `rndc querylog on` (Lab 4.2) lasts until `named` restarts.

## Tested

2026-10-28 AEDT (27 October UTC, the containers' date) on a Debian 13 host with Docker; the stand-in VMs (`test/Dockerfile`,
built with `build --pull --no-cache`) carry bind9 1:9.20.30-1~deb13u1,
unbound 1.26.2-0+deb13u1, pdns-server and pdns-backend-sqlite3
4.9.17-0+deb13u1, sqlite3 3.46.1-7+deb13u2, curl 8.14.1-2+deb13u7, jq
1.7.1-6+deb13u4.

- `test/rehearse.sh`: starts the instructor stack (profile `m01`) on an
  internal Docker bridge, puts a stand-in VM 1 at 192.0.2.30 (set up as
  Modules 2 and 3 left it: the team zone with the Lab 2.1-2.4 records and a
  fresh DKIM key, the two reverse zones) and a stand-in VM 2 at 192.0.2.10
  (BIND with Module 3's files and one added line standing for the team's
  own edits), mounts this kit, and runs every step of
  Labs 4.1-4.4 as the slides give them: `named -V`, `named-checkconf -p`,
  `rndc status`, the statistics channel (requests up by exactly 3, cache
  hits by 2), `rndc addzone`/`delzone -clean`; Unbound's defaults failing on
  port 53, the kit's file, the same answer from Unbound and BIND, the two
  resolvers' flags in VM 1's query log, `+norec` refused, `unbound-control`,
  local data, forwarding to the lab resolver and to the registry (the
  referral passed on); PowerDNS's database, settings and key modes, REFUSED
  until `pdns_control rediscover`, the migration check finding the changed
  HTTPS record, the API (401 without the key, the fix, SOA-EDIT-API and a
  new record with the serial exactly one higher with SOA-EDIT-API
  INCREASE); Unbound asking PowerDNS, the counters (Unbound's exact; the
  PowerDNS API and `pdns_control` must agree), and the clean-up compared
  with each VM's own pre-Module-4 files. A daemon that does not start stops
  the run. 45 checks,
  under a minute with the images built. `KIT_DIR=<a changed copy of this
  kit>` runs it against a changed kit: with `domain-insecure` removed and
  the HTTPS fix broken, 7 checks fail (38/45). It removes every container,
  network and volume it made (`SETUP_ONLY=1` leaves the lab up for
  exploring; the next run removes it); the transcript goes to the file
  given as the first argument, or to a new file under `$TMPDIR` (default
  `/tmp`), never into the repository. `KIT_DIR` may be relative.
- The harness starts the daemons as Debian's units do (`unbound-helper
  root_trust_anchor_update` then `unbound -d -p`; `pdns_server
  --guardian=no --daemon=no --disable-syslog` as user `pdns`), with their
  logs in `/var/log/*.out` (Unbound with an extra `use-syslog: no`); `sudo
  -u pdns` is `runuser -u pdns` there.
- The theory slides' other outputs (NSD 4.12.0 and Knot DNS 3.4.6 serving
  the same zone, PowerDNS loading from `named-compilezone -s full` and by
  AXFR, zones created through the API, the `allow-new-zones` removal) are
  recorded in the course's notes, with dates.

Not tested: real VMs (`sudo`, `systemctl`, `journalctl`, AppArmor; Docker
does not enforce AppArmor); `apt install` on a VM with BIND running (the
failure messages above come from starting the daemons by hand next to
`named`); the `systemctl disable` steps; IPv6 transport; PowerDNS with
MySQL/MariaDB or PostgreSQL (same schema family, not run).
