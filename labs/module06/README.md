# Module 6 lab kit: DNS security fundamentals

Files for Labs 6.1-6.5 of `modules/module06-dns-security-fundamentals.marp.md`.
The labs harden the two Debian 13 VMs that each participant uses again in
Modules 7 and 8 (an authoritative server for `teamNN.example` and a BIND
resolver), measure amplification and rate limiting against the team's own
server, and add TSIG and a Response Policy Zone.

## Containment

Every lab command targets the participant's own VMs or the instructor's lab
servers on the isolated lab network. The only load generator is
`dnsperf -Q 50 -l 10` (50 queries per second for 10 seconds), from the
team's resolver VM to the team's own authoritative VM. No source addresses
are spoofed and no poisoning tool is used: cache-poisoning defences are
observed in the participants' own captures.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `auth/named.conf.options` | authoritative VM, replaces `/etc/bind/named.conf.options` | 6.1, 6.3 |
| `auth/db.additions` | append to the team zone file (`big` TXT, `c2` A); raise the serial | 6.3, 6.5 |
| `auth/zone-tsig.snippet` | two lines for the `zone "teamNN.example"` statement | 6.4 |
| `common/named.conf.logging` | both VMs, `/etc/bind/`; `include` it from `named.conf` | all |
| `resolver/named.conf.options` | resolver VM, replaces `/etc/bind/named.conf.options`; set your addresses in `acl "trusted"` | 6.1, 6.2 |
| `resolver/named.conf.local` | resolver VM, `/etc/bind/named.conf.local` (static-stub for `example`) | 6.1 |
| `resolver/named.conf.secondary` | resolver VM, added to `named.conf.local` during Lab 6.4, then removed | 6.4 |
| `resolver/named.conf.rpz`, `named.conf.rpz-options`, `db.local.rpz` | resolver VM: policy zones, the `response-policy` block for `options`, the team's own policy zone | 6.5 |
| `tools/dns-signs.sh` | run anywhere with `tshark`: summary of a capture per parent domain | 6.5 |
| `instructor/` | the registry server (below) | 6.5 |
| `test/` | rehearsal harness (below); not for participants | - |

Replace `teamNN`/`NN` with the team number and the slide addresses with the
lab sheet's: registry 192.0.2.53, authoritative VM 192.0.2.30, resolver
192.0.2.10.

Before Lab 6.1 on both VMs: `sudo install -d -o bind -g bind /var/log/named`
(Debian's AppArmor profile for `named` allows writing there).

## Keys and secrets

Nothing secret is in this kit. In Lab 6.4 each team runs
`tsig-keygen -a hmac-sha256 teamNN-xfr` on its authoritative VM, stores the
key in `/etc/bind/teamNN-xfr.key` (owner `root:bind`, mode 640) and copies it
to its resolver VM over SSH. `dig -k` on the 640 key file needs `sudo`:
`dig` does not stop when it cannot read the key ("permission denied"), it
sends the query unsigned, so the right-key test would fail like the no-key
test. The rndc keys are the ones Debian's `bind9`
package generates at installation. `../.gitignore` keeps keys, logs and pid
files out of git.

## Changes that Module 7 depends on

- `resolver/named.conf.local` adds the `example` static-stub that Module 7
  Lab 7.3 step 2 asks for; Lab 7.3 can keep it.
- `resolver/named.conf.options` sets `validate-except { "example"; };`:
  without it BIND 9.20 refused the lab TLD ("got insecure response; parent
  indicates it should be secure"), because the real root proves that
  `example.` does not exist. Module 7 Lab 7.3 step 1 deletes this line when
  it adds the `example.` trust anchor (BIND skips validation under a
  validate-except name even when a trust anchor exists).
- Lab 6.4 makes the resolver VM a secondary for `teamNN.example` and its last
  step removes it again; a resolver that serves the zone authoritatively
  would not validate it in Module 7.
- The authoritative VM keeps `recursion no` and `rate-limit` (5 responses
  per second, `log-only no` after Lab 6.3). Module 7's DS and CDS checks go
  through the resolver, so they are not affected; raise the rate or set
  `log-only yes` if later labs query the authoritative VM in bulk.

## Instructor side

The registry server that serves `example.` for Modules 7 and 9 also serves
the RPZ feed. To run it as a container it needs:

- BIND 9.20 on the lab network address in the lab sheet (192.0.2.53 on the
  slides), UDP and TCP port 53, `recursion no`
- zone `example.` must delegate each `teamNN.example` (NS record plus glue A
  record for the team's authoritative VM), as Module 7's `db.example` does;
  it is signed with the Module 7 `lab` policy, which also signs the added
  records on reload. Lab 6.5 step 3 relies on the signing: DO=1 answers
  from a signed zone are not rewritten by RPZ
- the four A records in `instructor/example.additions` (`malware`, `phish`,
  `walled-garden`, `tracker`); after editing `db.example`, raise the serial
  and `rndc reload example`
- zone `feed.rpz.test.` from `instructor/db.feed.rpz.test`, configured as in
  `instructor/named.conf.module06`: transfers and queries allowed from the
  lab subnet only, `notify no` (team resolvers refresh on the SOA timers,
  every 300 s)
- `acl "lab-network"` in `instructor/named.conf.module06`: set it to the
  classroom prefix from the lab sheet
- no secrets: the feed is protected by the address ACL; add TSIG keys per
  team if the lab network is shared with others
- the instructor Docker Compose stack (`labs/instructor/`, which serves the
  signed `example.` with team delegations from a `teams.conf`) is the
  intended home of this feed zone

## Rehearsal harness (`test/`)

`test/rehearse.sh WORKDIR` runs every lab command without root, inside an
unprivileged user and network namespace (`unshare -rn`). The namespace has
no route to anything outside it:

| Address | Role |
|---|---|
| 192.0.2.53 | registry server: `example.`, `feed.rpz.test` |
| 192.0.2.30 | team01 authoritative VM (also the resolver's client) |
| 192.0.2.10 | team01 resolver VM |
| 192.0.2.31 | a neighbouring team's VM on the same /24 |
| 203.0.113.7 | a host on another network, in a child namespace behind a veth pair |

`test/setup.sh` builds the work directory from the classroom files,
rewriting only paths, `teamNN` -> `team01`, `dnssec-validation auto` ->
`no` (no Internet in the namespace) and `localhost` in the resolver ACL ->
`127.0.0.1` (every lab address is local inside one namespace). Each server
also gets `listen-on`, source addresses, a pid file and an rndc channel on
its own address. It also writes Debian's out-of-the-box configuration
(`default.conf`) for the "before" checks. Run it as:

```sh
sh test/rehearse.sh "$PWD/work" > transcript.txt
```

It needs, in `PATH`: `unshare`, `nsenter`, `ip`, BIND 9.20 (`named`, `rndc`,
`rndc-confgen`, `named-checkconf`, `named-checkzone`, `tsig-keygen`, `dig`),
`dnsperf`, `tcpdump`, `tshark`. All servers are stopped on exit.

## Tested

2026-10-21 on Debian 13 packages: bind9, bind9-utils, bind9-dnsutils and
bind9-libs 1:9.20.29-1~deb13u1 (trixie-security), dnsperf 2.14.0-5,
tcpdump 4.99.5, tshark 4.4.19. The `validate-except` behaviour was checked
separately with Internet access (the namespace connected through
`slirp4netns`): without the line `www.team01.example` gave SERVFAIL, with it
NOERROR, while `isc.org` validated (AD) and `dnssec-failed.org` gave SERVFAIL.
The transcripts are kept in the instructor's notes, not in this repository.

Configuration changes are rehearsed as in class: the harness swaps the
active `named.conf` and runs `rndc reconfig` (Lab 6.1 options, Lab 6.4 key,
secondary zone added and removed, Lab 6.5 policy zones). The registry's
`example.` is signed in the harness (`dnssec-policy default`). The key-file
permission problem is checked by running `dig` on a mode-000 copy without
CAP_DAC_OVERRIDE (a second user cannot be mapped in the namespace).

Not tested: the `systemctl`/`sudo` steps and file ownership on real VMs
(`root:bind` cannot be set inside the namespace); `journalctl -u named` for
the query log (Lab 6.2 step 4; the harness reads `named`'s own log file);
the neighbour and outside checks from real machines; the shipped
`dnssec-validation auto` with `validate-except` was run only with Internet
access (slirp4netns), the harness uses `dnssec-validation no`; the Module 7
`lab` policy on the registry (the harness signs with `default`); Debian 12.

## Assessment 3B

Task 4 of Practical Assessment 3B needs a capture or log to analyse. The
rehearsal harness leaves `WORKDIR/cap/signs.pcap` (tunnel-like queries) and
`WORKDIR/auth/log/security.log` (RRL notices); generate them before class and
hand them out from the instructor server. Do not commit them.
