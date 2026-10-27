# Module 5 lab kit: advanced DNS operations and architecture

Files for Labs 5.1-5.4 of `modules/module05-advanced-dns-operations.marp.md`.
Each team uses its two Debian 13 VMs as Module 4 left them: VM 1 (192.0.2.30
on the slides) is the primary for `teamNN.example`, VM 2 (192.0.2.10) the BIND
resolver. Lab 5.1 makes VM 2 a hidden primary for a child zone with VM 1 as
its public secondary, Lab 5.2 gives VM 1 two views, and Labs 5.3-5.4 build an
anycast service inside VM 2 with network namespaces. Every lab undoes its own
changes: Module 6 starts from the state Module 4 left.

Tested 2026-10-28 (AEST) with `test/rehearse.sh`: 61 of 61 checks, BIND
9.20.30 (bind9 1:9.20.30-1~deb13u1), BIRD 2.17.5 (bird2 2.17.5-0+deb13u1),
iproute2 6.15.0-1, against the instructor stack with the `m01` profile.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `vm2/db.hp.teamNN.example` | VM 2, `/var/lib/bind/db.hp.teamNN.example` (set `NN`) | 5.1 |
| `vm2/named.conf.hidden-primary` | VM 2, appended to `/etc/bind/named.conf.local` (save a copy first) | 5.1 |
| `vm1/named.conf.public-secondary` | VM 1, appended to `/etc/bind/named.conf.local` (save a copy first) | 5.1 |
| `vm1/named.conf.views` | VM 1, replaces `/etc/bind/named.conf.local` for Lab 5.2 only | 5.2 |
| `vm1/internal.additions` | VM 1, appended to the internal copy `/var/lib/bind/db.teamNN.example.internal` | 5.2 |
| `anycast/anycast-lab.sh` | VM 2, run with `sudo sh anycast/anycast-lab.sh COMMAND` (up, status, stop, start, fix, down) | 5.3, 5.4 |
| `anycast/bird-r1.conf`, `bird-r2.conf` | read by the script: the two routers (AS 65001, AS 65002) | 5.3 |
| `anycast/bird-site-a.conf`, `bird-site-b.conf` | read by the script: the two sites (both AS 65100) | 5.3 |
| `anycast/named-site-a.conf`, `named-site-b.conf`, `db.svc.test` | read by the script: the DNS server at each site and its zone | 5.3 |
| `anycast/healthcheck.sh` | started by the script in each site: announces or withdraws the route | 5.3 |
| `instructor/faults.sh`, `instructor/README.md` | the instructor's: sets the Lab 5.4 faults on a team's VM 2 over SSH; the answers | 5.4 |
| `test/` | rehearsal harness (below); not for participants | - |

Replace `teamNN`/`NN` (and `N1 N2` in the views file, as in Module 2's zone
statements) with the team number, and the slide addresses with the lab
sheet's: VM 1 192.0.2.30, VM 2 192.0.2.10, registry 192.0.2.53, lab resolver
192.0.2.55. The anycast lab's addresses (198.51.100.0/24, RFC 5737) exist only
inside VM 2 and need no change.

## VM image and packages

Add `bird2` to the image used for both VMs (Module 4's list stays), installed
with `--no-install-recommends`, then `sudo systemctl disable --now bird`:
Debian's `bird.service` would otherwise run BIRD with `/etc/bird/bird.conf` in
the VM's own namespace, which the lab does not use. `iproute2` (`ip netns`) is
part of a standard Debian install. Offline path: the package is in the image;
with a mirror, `sudo apt install --no-install-recommends bird2` and the same
`disable`. Neither BIRD nor this kit generates keys.

## The instructor stack

The registry (192.0.2.53) as every day, and the `m01` profile's lab resolver
(192.0.2.55) kept on until the end of the Module 5 lab (Day 3 lunch): Lab 5.1
uses it as a resolver elsewhere, Lab 5.2 as an outside client of VM 1's
external view. No instructor-stack code changes; see
`../instructor/README.md` for switching `m01` off afterwards.

## Lab 5.1: hidden primary

VM 2 is the hidden primary for `hp.teamNN.example`, a child zone that the team
delegates from its own zone (`hp IN NS ns1.teamNN.example.`), so the registry
needs no change. VM 1 is the only listed server and the only host VM 2 lets
query, transfer or be notified (`notify explicit`). VM 2's own resolver users
are refused for the zone too (REFUSED, EDE 18): a zone's `allow-query` applies
to every client of that `named`. A hidden zone cannot sit on VM 1, because VM
1 serves the parent and would refuse the resolvers that follow the delegation.

Clean-up (step 7): the saved `named.conf.local` back on both VMs, the `hp`
line removed from `teamNN.example` with a new serial, the secondary's file
`/var/cache/bind/db.hp.teamNN.example` and the zone file on VM 2 deleted. The
team zone ends two serials higher than it started; nothing else changes.

## Lab 5.2: views

The views file puts every zone in a view (`internal` for VM 1 itself and VM 2,
`external` for everyone else with `recursion no`) and shares the two reverse
zones with `in-view`. Debian 13's `named.conf` includes
`named.conf.root-hints` (the hint zone) at the top level, so step 2 comments
that line out; `named-checkconf` stops with "when using 'view' statements, all
zones must be in views" until then. Clean-up: the saved `named.conf.local`
and `named.conf` back, the internal zone file deleted, and after `rndc
reconfig` the per-view managed-keys journals `internal.mkeys.jnl` and
`external.mkeys.jnl` in `/var/cache/bind` deleted.

## Labs 5.3-5.4: anycast inside VM 2

```text
  C1 ── R1 (AS 65001) ── R2 (AS 65002) ── C2
         │                      │
       site A                 site B        both AS 65100, both 198.51.100.53
  C1-R1 .2/.1   R1-A .5/.6   R1-R2 .9/.10   R2-B .13/.14   R2-C2 .17/.18
```

`anycast-lab.sh up` makes six network namespaces (`m05-c1`, `m05-c2`,
`m05-r1`, `m05-r2`, `m05-a`, `m05-b`), joins them with veth pairs, starts
BIRD in the routers and sites (as Debian's unit does: root, then user `bird`;
sockets and pid files in `/run/m05-anycast`), a `named` in each site and
`healthcheck.sh` in each site. The health check is installed in
`/usr/local/lib/m05-anycast`, not `/run`: Debian 13 mounts `/run` with
`noexec` (initramfs-tools), so a script there cannot be executed; `up` stops
with "health check at site a did not start" if one does not run within 5 s.
`up` also stops at once if `bird2` is missing, and removes what it built if
interrupted with Ctrl-C. BGP carries only the service prefix; the links
are static routes. It waits until all four BGP sessions are up and each router
forwards to its own city's site. `down` stops every process in the namespaces
and removes the namespaces, `/run/m05-anycast`, `/etc/bind/m05-anycast`,
`/var/cache/bind/m05-anycast` and `/usr/local/lib/m05-anycast`.

The site servers are Debian's `named`, so Debian's AppArmor profile applies:
their configuration and zone are in `/etc/bind/m05-anycast/{a,b}` (read only),
their logs in `/var/cache/bind/m05-anycast/{a,b}` (writable). They set
`pid-file none` and `session-keyfile none` because the profile allows only
`/run/named/named.pid` and `/run/named/session.key`, which belong to the VM's
own `named`; `controls { };` leaves port 953 to it. The script never uses
`pkill` or `killall` (they would also stop VM 2's resolver); it signals only
processes listed by `ip netns pids`.

`healthcheck.sh` asks its site's `named` for the `svc.test` SOA on the anycast
address every second and enables or disables BIRD's static protocol `svc`
(the announcement) accordingly; it sets the state on every round, so a BIRD
reconfiguration cannot leave a site withdrawn, and logs its start and each change to
`/run/m05-anycast/<site>-health.log`, so a restarted check is visible. The BGP sessions use `connect retry
time 5` (BIRD's default is 120 s) so that a router started before its peer
does not wait two minutes.

Loops that ask "which site?" must use NSID (`dig +nsid` on a normal query):
BIND's built-in `_bind` view answers `id.server` and `hostname.bind` at most 3
times per second per /24 and drops the rest (`named -C`), which looked like
packet loss in the rehearsal.

### Lab 5.4 faults

The instructor sets them with `instructor/faults.sh`, piped to the team's VM 2
over SSH (`ssh <VM 2> 'sudo sh -s -- N' < instructor/faults.sh`); the
answers are in `instructor/README.md`. Participants undo each with
`anycast-lab.sh fix`, which restores both sites' zones, BIRD configurations,
`named` and health checks and waits until each router forwards to its own
site. **This repository is public**, so anyone can read the faults: Practical
Assessment 3A task 4 grades the evidence and the method (the commands, their
order, what each showed and ruled out), not just the named cause.

## What the anycast lab does not show

Internet catchments, latency, BGP convergence and path hunting across many
networks, covering-prefix announcements (on the Internet a /32 does not
propagate: RFC 4786 §4.4.2), DDoS absorption and TCP across a route change.
The deck says so.

## End state (what Module 6 starts from)

Both VMs as Module 4 left them: `named.conf`, `named.conf.local` and
`named.conf.options` unchanged, no `hp`, `internal` or `mkeys` files, no
namespaces, nothing in `/usr/local/lib/m05-anycast`, only `named` listening
on port 53, query logging off on both VMs (Lab 5.1 turns it on, Labs 5.1 and
5.2 turn it off again), and `teamNN.example` two serials higher. `bird2`
installed and disabled.

## Secrets

Nothing secret is in this kit, and the labs create none: Lab 5.1 restricts
transfers by address (Module 6 Lab 6.4 adds TSIG). `../.gitignore` keeps keys,
logs and pid files out of git.

## Rehearsal harness (`test/`)

`test/rehearse.sh [TRANSCRIPT]` starts the instructor stack
(`../../instructor`, profile `m01`) on an internal Docker bridge with no route
out, plus two Debian 13 containers built from `test/Dockerfile` (the Module
2-4 packages plus `bird2`, `iproute2`, `procps`): VM 1 set up as Modules 2-4
left it (Module 2's zones with the Lab 2.1-2.4 records and Module 3's `lab33`)
and VM 2 with Module 3's resolver files (plus one line, standing for a team's
own edits). Both containers mount `/run` as a `noexec` tmpfs, as Debian 13
does (step 0.2 checks it; without it the harness missed a health check that
could not run from `/run`). VM 2 runs `--privileged`, because Labs 5.3-5.4
create network namespaces and set forwarding inside them, as root on a real
VM can. It runs
every lab step and checks each checkpoint, including the exact serials, the
failover (C1 reaches site B after `stop a` and never returns to site A in the
sample), each fault's symptoms and evidence, both health checks running after
each `fix`, no process left after `down`, query logging off and byte-equal configuration files at the end; it also checks the
serve-stale transcript on the caching slide (checks S.1-S.3). Run it as:

```sh
labs/module05/test/rehearse.sh                    # transcript to a new file under ${TMPDIR:-/tmp}
KIT_DIR=/path/to/changed/copy labs/module05/test/rehearse.sh   # mutation test
SETUP_ONLY=1 labs/module05/test/rehearse.sh       # leave the set-up running to explore
```

It takes about a minute with cached images. `named` runs in the foreground
with its log in `/var/log/named.out`, where a VM has the journal; Docker does
not enforce AppArmor, so the AppArmor paths above were checked against the
profile's text, not by running under it.

**Not tested:** real VMs (`sudo`, `systemctl`, `journalctl`, AppArmor
enforcement on the site servers inside `ip netns exec`); `apt install bird2`
on a VM; IPv6 transport; memory on a 2-vCPU VM. On the 12-CPU test host the
four BIRD processes used 12-13 MiB; the site servers' memory was not
separated from VM 2's own resolver (the three `named` processes together:
92 MiB in one run, 527-534 MiB in later ones, mostly the resolver's cache and
one worker thread per CPU).
