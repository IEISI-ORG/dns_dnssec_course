# Module 8 lab kit: DNS privacy and encryption

Files for Labs 8.1-8.5 of `modules/module08-dns-privacy-encryption.marp.md`.
The labs add DNS over TLS (DoT), DNS over HTTPS (DoH), DDR records and
padding to the Module 7 resolver VM, and use the Module 7 authoritative VM
as the client.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `make-certs.sh` | run on the resolver VM: `sudo sh make-certs.sh NN <resolver address> /etc/bind/tls` | 8.2 |
| `resolver/named.conf.module08` | `/etc/bind/`, included from `named.conf` | 8.2, 8.4 |
| `resolver/named.conf.options.module08` | lines to paste into the resolver's `options { }` | 8.2, 8.5 |
| `resolver/db.resolver.arpa` | `/etc/bind/`; set your team number | 8.4 |
| `unbound/module08-forward.conf` | client VM, `/etc/unbound/unbound.conf.d/` | 8.3 |
| `unbound/module08-server.conf` | reference only: the same service on Unbound | - |
| `test/` | rehearsal harness (below); not for participants | - |

## Keys and certificates

Nothing secret is in this kit. `make-certs.sh NN RESOLVER_IP` creates, on the
resolver VM, a team CA (`ca.key`, `ca.crt`, 30 days) and a resolver key and
certificate for `resolver.teamNN.example` with the resolver's IP address as a
subjectAltName (needed for DDR verified discovery). Each team generates its
own; keys never leave the resolver VM, and only `ca.crt` is copied to the
client. Make `resolver.key` readable by BIND:
`chown root:bind resolver.key; chmod 640 resolver.key`.
`.gitignore` keeps keys, certificates directories, logs and pid files out of git.

## Rehearsal harness (`test/`)

`test/rehearse.sh WORKDIR` runs every lab command without root, inside an
unprivileged user and network namespace (`unshare -rn`), with the lab
addresses on the namespace loopback:

| Address | Role |
|---|---|
| 192.0.2.1 | authoritative server (`example.`, `team01.example`), BIND |
| 192.0.2.10 | team resolver, BIND: Do53, DoT 853, DoH 443, `resolver.arpa` |
| 192.0.2.20 | the same service on Unbound (`module08-server.conf`) |
| 192.0.2.30 | client address for `dig`/`kdig`; Unbound forwarder on 127.0.0.1:5300 |
| 192.0.2.40 | Knot DNS with DoQ (instructor demo) |

`test/setup.sh` builds the work directory from the classroom files, rewriting
only `/etc/...` paths, team `NN` -> `01`, and runs `named-checkconf`,
`named-checkzone` and `unbound-checkconf`. Run it as:

```sh
TMPDIR=/tmp sh test/rehearse.sh "$PWD/work" > transcript.txt
```

It needs, in `PATH`: `unshare`, `ip`, BIND 9.20 (`named`, `rndc`,
`rndc-confgen`, `named-checkconf`, `named-checkzone`, `dig`), Unbound 1.26,
`kdig`, `openssl`, `curl`, `tcpdump`, `tshark`, `python3`, and optionally
Knot DNS 3.4 (`knotd`, `knotc`) for the DoQ demo. `TMPDIR` must be short: the
Knot control socket path is limited to 108 bytes. All servers are stopped on
exit.

Differences from the classroom: validation is off on the test resolver (no
Internet in the namespace); `example` is a `static-stub` zone; the resolver
listens on 192.0.2.10 rather than `any` (the classroom `options` lines are
checked with `named-checkconf` only), and the Unbound forwarder sends from
192.0.2.30 (`outgoing-interface`).

## Tested

2026-10-21 on Debian 13 packages: bind9 9.20.29-1~deb13u1, unbound
1.26.1-0+deb13u1, knot-dnsutils and knot 3.4.6-2, openssl 3.5.7, curl 8.14.1,
tcpdump 4.99.5, tshark 4.4.19. The transcripts are kept in the instructor's notes, not in this repository.

Not tested: the `systemctl` steps on real VMs; Debian 12 (BIND 9.18, Unbound
1.17); DNR (DHCP option 162/144), which is discussion only.
