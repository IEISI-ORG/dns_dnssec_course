---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 4: DNS Software Platforms — BIND, Unbound, PowerDNS, and Alternatives

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Compare** BIND, Unbound, PowerDNS, NSD, Knot DNS, Knot Resolver and hosted services by role, data store, control interface, licence and support life
- **Operate** BIND 9.20 on Debian 13 beyond the zone files: the configuration as `named` reads it, `rndc`, the statistics channel, zones added at run time
- **Configure** Unbound as a resolver next to BIND: access control, stub and forward zones, local data, `unbound-control`
- **Deploy** PowerDNS Authoritative with a database backend and change a zone through its HTTP API
- **Analyse** a migration: import a zone, compare what two servers answer, find and fix the difference
- **Evaluate** software for an organisation from support lifecycles, advisories and your own measurements, not vendor benchmarks
- **Create** configuration templates that each server's own checker accepts

---
<!-- _class: dense -->
## Where Day 2 Stands

```text
 VM 1  192.0.2.30   BIND: primary for teamNN.example and two reverse zones (Module 2)
 VM 2  192.0.2.10   BIND: resolver with Module 3's static-stub zone for example.
 registry 192.0.2.53      example.: delegates teamNN.example to VM 1
 lab resolver 192.0.2.55  Module 1's resolver, on until the end of today
 This afternoon:  VM 2 also runs Unbound, VM 1 also runs PowerDNS, both on port 5300
```

- Modules 2 and 3 ran BIND because it does both jobs. This module asks what else does them, and what changes when you switch
- BIND keeps port 53 on both VMs; the other two programs get port 5300 and are switched off again in Lab 4.4
- Pointers out: views and split horizon, anycast, load balancing (Module 5); TSIG, RPZ, hardening (Module 6); signing (Module 7); DoT, DoH, DoQ (Module 8)

---
<!-- _class: dense table-compact -->
## What Changed Recently

| Then | Now (as of 28 October 2026) |
|---|---|
| BIND 9.18 the Extended Support Version | 9.18 end of life June 2026; 9.20 (first released July 2024) is ESV and current stable, end of life Q2 2028 (ISC) |
| `auto-dnssec` in BIND | removed in 9.20.0 ("use dnssec-policy or manual signing instead"): Module 7 |
| A Debian stable release keeps one upstream version | Debian 13 moved Unbound from 1.22.0 to upstream 1.26.1 in September 2026, "instead of trying to provide fixes for older version" |
| PowerDNS Authoritative 4.x | upstream 5.1 is current; 4.9 (Debian 13's 4.9.17): critical fixes only, end of life near (vendor page) |
| dnsdist 1.9, Knot Resolver 5 | dnsdist 2.0 (July 2025), 1.9 end of life July 2026; Knot Resolver 6: a manager and YAML. Debian 13 still has 1.9 and 5.7 |

<!--
Sources fetched 28 October 2026 (plan/m04_notes.md): isc.org/download and kb.isc.org aa-00896; BIND 9.20.0 release notes in the ARM; Debian unbound changelog 1.26.1-0+deb13u1; doc.powerdns.com EOL pages; dnsdist.org/eol.html and the dnsdist 2.0.0 announcement (21 July 2025); knot-resolver.cz "Upgrading to Knot Resolver 6". Versions move: check them on the day.
-->

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. Day 2 so far and what changed (5m)
2. The software landscape (10m)
3. BIND 9 (18m)
4. Unbound (12m)
5. PowerDNS (15m)
6. Alternatives and hosted DNS (8m)
7. Choosing and migrating (7m)
8. Knowledge Check 2: Day 2 quiz, Modules 3-4 (15m)

## Agenda (90 min Lab)

1. Lab 4.1 BIND under the hood (20m)
2. Lab 4.2 Unbound next to BIND (25m)
3. Lab 4.3 PowerDNS with a database (30m)
4. Lab 4.4 Compare, then clean up (15m)

<!--
Program Facts: knowledge checks take the last 15-30 minutes of Session 3. Day 2's Session 3 is this module, so the theory content is 75 minutes and Knowledge Check 2 (dns_assessment_plan.md: 15 minutes, scenario questions on server roles, software capabilities, architecture and performance) closes the session. The quiz is handed out on paper; it is not in this deck.
-->

---
<!-- _class: section-divider -->
# 1 · The Software Landscape

---
<!-- _class: dense table-compact -->
## Who Makes What

| Software | Maintainer | Authoritative | Resolver | Licence | Debian 13 |
|---|---|---|---|---|---|
| **BIND 9** | ISC | yes | yes | MPL-2.0 | 9.20.30 |
| **Unbound** | NLnet Labs | local data only | yes | BSD | 1.26.2 |
| **NSD** | NLnet Labs | yes | no | BSD-like | 4.12.0 |
| **PowerDNS** Auth., Recursor | PowerDNS | Auth. | Recursor | GPL-2 | 4.9.17, 5.2.13 |
| **dnsdist** | PowerDNS | load balancer | | GPL-2 | 1.9.16 |
| **Knot DNS**, **Knot Resolver** | CZ.NIC | Knot DNS | Knot Resolver | GPL-3+ | 3.4.6, 5.7.5 |
| **dnsmasq** | Simon Kelley | local names | forwarder | GPL-2 or GPL-3 | 2.91 (`dnsmasq-base`) |

- All in Debian 13 (versions as of 28 October 2026); CoreDNS is not. Microsoft DNS and hosted services: section 5

<!--
Licences from /usr/share/doc/<package>/copyright in Debian 13 (Files: *): bind9 "MPL-2.0 and ISC and BSD-2-clause and BSD-3-clause"; unbound "BSD-3-NLnetLabs"; nsd "NSD-BSD-like"; pdns-server, pdns-recursor, dnsdist "GPL-2 with OpenSSL Exception"; knot "GPL-3+"; knot-resolver "GPL-3.0+". dnsmasq-base 2.91-1+deb13u2 copyright: "Upstream-Contact: Simon Kelley", Files: * "License: GPL-2 or GPL-3". Debian describes it as "Small caching DNS proxy and DHCP/TFTP server".
-->

---
<!-- _class: dense -->
## One Program for Both Jobs, or One per Job

- **BIND** serves zones and resolves in one `named`, often in the same process (Module 3: VM 1 did both with Debian's defaults)
- **Split designs:** NSD "has not implemented recursive caching by design" (NLnet Labs); Unbound is a resolver; PowerDNS ships separate Authoritative and Recursor programs; Knot DNS and Knot Resolver are separate too
- **Why split:** a bug or an attack on one role does not take the other with it; each program is smaller; each can be upgraded on its own timetable (Module 3: two jobs, two servers)
- **Why one:** one configuration language, one tool set, one vendor to follow
- **Diversity:** different implementations on your listed servers, so that one software bug does not stop all of them. NLnet Labs: "three DNS root servers and many top-level domain registries use NSD as part of their server implementation"
- Whatever you run, the protocol is the same: Lab 4.4 sends the same questions to three programs and compares the answers

---
<!-- _class: dense table-compact -->
## Who Fixes the Bugs, and for How Long

| Software | Upstream today (28 Oct 2026) | Debian 13 ships | Status of Debian's version upstream |
|---|---|---|---|
| BIND | 9.20.30 (ESV), 9.21.27 (development) | 9.20.30 | supported to Q2 2028 |
| Unbound | 1.26.2 | 1.26.2 | current |
| PowerDNS Authoritative | 5.1 current | 4.9.17 | critical fixes; EOL: "after ... 5.2" or "~ Sep 2026" |
| PowerDNS Recursor | 5.4 current | 5.2.13 | end of life |
| dnsdist | 2.1 current | 1.9.16 | end of life since 21 July 2026 |
| Knot DNS, Knot Resolver | 3.6.2, 6.5.1 | 3.4.6, 5.7.5 | older branches |

- Two support promises: the vendor's for its branch, and Debian's security team for the package in stable. Debian still uploaded dnsdist 1.9.16 in August 2026
- ISC: "Each even-numbered version is supported for a total of 4 years". PowerDNS: customers with a commercial agreement "can receive support for releases which are End Of Life"
- Choose the branch, then put its end-of-life date in your plan

<!--
Sources: isc.org/download; kb.isc.org aa-00896; nlnetlabs.nl Unbound and NSD download pages; doc.powerdns.com/authoritative/appendices/EOL.html (text: "4.9 will only receive critical updates; it will be end of life after PowerDNS Authoritative Server 5.2 is released"; the table on the same page: 4.9 end of life "~ September 2026", already past, while 5.2 is not released: the page contradicts itself, which is the point to make: read the whole page, not the headline); doc.powerdns.com/recursor/appendices/EOL.html ("PowerDNS Recursor 5.2, 5.1, 5.0, 4.x, 3.x, and 2.x are End of Life"); dnsdist.org/eol.html ("End of Life since July 21st, 2026"); knot-dns.cz, knot-resolver.cz; Debian changelogs. All fetched 28 October 2026.
-->

---
<!-- _class: dense -->
## 21 October 2026: Three Vendors, One Day

```text
ISC         CVE-2026-19630 and three more    fixed in BIND 9.20.30
NLnet Labs  CVE-2026-97206 (HIGH) and four   fixed in Unbound 1.26.2
PowerDNS    advisory 2026-13 (Authoritative), 2026-12 (Recursor, seven CVEs)
Debian 13   bind9 1:9.20.30-1~deb13u1, unbound 1.26.2-0+deb13u1 in trixie-security
```

- Every implementation has security releases; what differs is how you hear of them and how fast you can install them
- **Where to look:** ISC's BIND 9 Security Vulnerability Matrix; NLnet Labs' security advisories pages; PowerDNS advisories per product; Debian security announcements (DSA) for packaged versions
- **What to have ready:** a test copy of each server, the package or build steps, and a way to restart without losing service (two or more servers: Module 3)
- Same day, separate flaws: each vendor's list is the one to follow for its software

<!--
From the advisory pages (fetched 28 October 2026): kb.isc.org/docs/aa-00913 (CVE-2026-19630, -94300, -96888, -97313, 2026-10-21, fixed in 9.20.30); nlnetlabs.nl/projects/unbound/security-advisories (CVE-2026-97206, 2026-10-21, "DNS-over-QUIC path-migration can lead to use-after-free on multi-threaded deployments"; the Debian changelog lists four more); docs.powerdns.com advisories 2026-13 (CVE-2026-73206) and Recursor 2026-12. The last bullet is an observation about this release day, not a general statistic.
-->

---
<!-- _class: section-divider -->
# 2 · BIND 9

---
<!-- _class: dense -->
## BIND 9 in Brief

- **History** (ARM appendix): BIND was written at UC Berkeley after the first DNS server, "Jeeves" (1983-84); ISC and its predecessor have maintained it since 4.9.3; BIND 8 in May 1997; **BIND 9 in September 2000**, "a major rewrite"
- **Releases:** even minor numbers are stable branches (9.18, 9.20), odd ones development (9.21); each even branch is supported for four years (ISC)
- **One daemon, `named`:** authoritative, recursive, or both; views (Module 5); DNSSEC signing and validation (Module 7); RRL and RPZ (Module 6); DoT and DoH (Module 8); catalog zones (Module 3)
- **Threads:** "If not specified, named tries to determine the number of CPUs present and creates one thread per CPU" (ARM, `-n`). The test host: 12 CPUs, 12 worker threads; your VM shows its own count
- **Control:** `rndc` over a key-protected channel; **data:** zone files, journals, and the new-zone database
- Its size is the trade-off: one program, many features, many options to get right

---
<!-- _class: dense -->
## BIND on Debian 13: Files and Paths

```text
$ named-checkconf -p      # what named reads: includes resolved, comments gone
options { directory "/var/cache/bind"; allow-recursion { ... }; ... };
zone "example" { type static-stub; ... };                   # named.conf.local (Module 3)
zone "." { type hint; file "/usr/share/dns/root.hints"; };   # named.conf.root-hints
```

| Path | Holds | `named` may |
|---|---|---|
| `/etc/bind/named.conf`, `rndc.key` | includes `.options`, `.local`, `.root-hints`; the control key | read |
| `/var/lib/bind` | your zone files, journals, signed zones (Module 7) | write |
| `/var/cache/bind` | secondary copies, cache dumps, `_default.nzd` | write |

- Debian's AppArmor profile enforces the last column (Module 2)

---
<!-- _class: dense table-compact -->
## named.conf: the Building Blocks

| Statement | Does | Course |
|---|---|---|
| `options { }` | server-wide settings: directory, recursion, `listen-on`, defaults for zones | Modules 2, 3, 6 |
| `zone "name" { }` | one zone: `type`, `file`, `primaries`, `allow-transfer` | Modules 2, 3 |
| `acl "name" { }` | a named address list for `allow-*` | Module 6 |
| `key`, `tls`, `http` | TSIG keys; DoT and DoH | Modules 6, 8 |
| `dnssec-policy`, `trust-anchors` | signing and validation | Module 7 |
| `logging { }` | channels (where) and categories (what) | Module 6 |
| `view "name" { }` | different zones or answers per client | Module 5 |
| `controls { }` | where `rndc` may connect; default 127.0.0.1 port 953 with `rndc.key` | today |
| `statistics-channels { }` | counters over HTTP, XML and JSON | Lab 4.1 |

- One grammar: braces, semicolons, `//` comments. `named-checkconf -z` also loads every zone

---
<!-- _class: dense -->
## What This Build Can Do: named -V

```text
$ named -V
built by make with ... '--with-json-c' '--with-lmdb=/usr' '--with-maxminddb' ...
linked to libnghttp2 version: 1.64.0
linked to libxml2 version: 20914
```

- **json-c, libxml2:** the statistics channel in JSON and XML (Lab 4.1)
- **LMDB:** the database that `rndc addzone` writes (`_default.nzd`)
- **libmaxminddb:** GeoIP in ACLs (Module 5); **nghttp2:** DNS over HTTPS (Module 8)
- **dnstap:** a binary log of queries and responses (Module 11)

- A feature in the ARM works only if your package was built with it

---
<!-- _class: dense table-compact -->
## rndc: Talking to a Running named

| Command | Does | Seen in |
|---|---|---|
| `reconfig` | rereads the configuration; loads new zones only | Modules 2-3 |
| `reload [zone]` | reloads zone files (all, or one) | Module 2 |
| `status`, `zonestatus zone` | server and zone state | Module 3, Lab 4.1 |
| `querylog on` | query logging until the next restart | Module 3, Lab 4.2 |
| `flush`, `flushname`, `dumpdb -cache`, `stats` | cache; counters to a file | Modules 3, 6 |
| `retransfer`, `refresh`, `notify` | secondaries and transfers | Module 3 |
| `addzone`, `delzone`, `modzone`, `showzone` | zones without editing files | Lab 4.1 |
| `dnssec -status`, `nta` | signing and validation | Module 7 |

- `rndc` authenticates with the key in `/etc/bind/rndc.key` (mode 600: hence `sudo`). Keep `controls` on 127.0.0.1: a remote control channel is a key and a port to protect

<!--
rndc(8) in the 9.20 ARM. Debian's default: no controls statement, so named listens on 127.0.0.1 and ::1 port 953 with rndc.key (the key made by rndc-confgen -a in Modules 2-3). Remote rndc from another VM is not in the lab: it would mean copying the key and opening port 953, which Module 6's hardening then has to close again.
-->

---
<!-- _class: dense -->
## Reading rndc status

```text
$ sudo rndc status                            # VM 2, test lab, 28 October 2026
version: BIND 9.20.30-1~deb13u1-Debian (Stable Release) <id:>
CPUs found: 12
worker threads: 12
number of zones: 102 (100 automatic)
query logging is OFF
recursive clients: 0/900/1000
server is up and running
```

- **100 automatic zones:** the built-in empty zones for private and special addresses (RFC 6303, Module 2); the other two are Module 3's static-stub zone and the root hints
- **recursive clients 0/900/1000:** in use now, soft quota (90% of the limit), `recursive-clients` (default 1000, Module 3). Above the soft quota, each new query drops a pending one (ARM)
- **query logging is OFF:** `rndc querylog on` lasts until the next restart, so Module 3's setting is gone

<!--
Rehearsal step 4.1.3. ARM: "A soft quota is also set. When this lower quota is exceeded, incoming requests are accepted, but for each one, a pending request is dropped. If recursive-clients is greater than 1000, the soft quota is set to recursive-clients minus 100; otherwise it is set to 90% of recursive-clients." Above the hard limit, new incoming requests are not accepted.
-->

---
<!-- _class: dense -->
## Adding Zones Without Editing Files

```text
options { directory "/var/cache/bind"; allow-new-zones yes; };       // VM 1, Lab 4.1
$ sudo rndc addzone lab4.team01.example '{ type primary; file "/var/lib/bind/db.lab4.team01.example"; };'
added zone lab4.team01.example in view _default via addzone        (named's log)
$ sudo rndc showzone lab4.team01.example
zone "lab4.team01.example" { type primary; file "/var/lib/bind/db.lab4.team01.example"; };
$ ls /var/cache/bind
_default.nzd ...                                                    (an LMDB database)
$ sudo rndc delzone -clean lab4.team01.example
zone 'lab4.team01.example' and associated files will be deleted.
```

- "The configuration is saved in ... an LMDB database file called viewname.nzd" and loaded at every restart (`rndc(8)` in the ARM)
- Tested: removing `allow-new-zones` hides an added zone but leaves it in the database; turning the option on again brings it back. Delete zones with `delzone` before you turn the option off
- Automation tools use this to add customer zones; catalog zones (RFC 9432, Module 3) do it for secondaries; PowerDNS keeps its zones in a database anyway (section 4)

---
<!-- _class: dense -->
## Counting What named Does

```text
statistics-channels { inet 127.0.0.1 port 8053 allow { 127.0.0.1; }; };   // vm2/named.conf.stats
$ curl -s http://127.0.0.1:8053/json/v1/server | jq -c '{nsstats: ..., cache: ...}'
{"nsstats":{"Requestv4":6,"QrySuccess":6,"QryRecursion":2},"cache":{"QueryHits":4,"QueryMisses":2}}
```

- Three lookups of one name in Lab 4.1: `Requestv4` up by 3, `QueryHits` up by 2 (one miss, then the cache)
- `/json/v1/...` or `/xml/v3/...` while it runs, or `rndc stats` into a file (Module 6). Monitoring systems read the channel: Module 11
- ARM: "If no allow clause is present, named accepts connection attempts from any address", and the statistics "may contain sensitive internal information". Always write `allow`
- Gathering the statistics "locks various subsystems": poll every few seconds, not continuously

<!--
Rehearsal step 4.1.4 (28 October 2026): the counters are cumulative since start; the six requests include three from the set-up. Debian's named is built with json-c and libxml2 (named -V), so both formats are there; "/" returns the XML with a stylesheet.
-->

---
<!-- _class: dense -->
## Logging and the Query Log

```text
client @0x... 192.0.2.10#18493 (ftp.team01.example): query: ftp.team01.example IN A -E(0)DC (192.0.2.30)
                                                                                    ││   ││
                                                                RD: - clear, + set ─┘│   │└── C: CD set
                                                                    EDNS version 0 ──┘   └──── D: DO set
       also: T (TCP), S (signed, TSIG), V (valid server cookie), K (cookie, no valid server cookie)
```

- **Channels** say where (file, syslog, stderr) and how much (`severity`); **categories** say what (`queries`, `xfer-in`, `security`, `dnssec`, `resolver`, ...). Debian logs to the journal; Module 6 adds files in `/var/log/named`
- The query-log flags are from the ARM's `queries` category. In Lab 4.2 the line above comes from Unbound; BIND's own queries show `DK`, then `DV` once it has VM 1's cookie (RFC 7873)
- "Only one logging statement is used" (ARM): Debian has none; Module 6's `named.conf.logging` is then the one, so no other kit may add a second

---
<!-- _class: section-divider -->
# 3 · Unbound

---
<!-- _class: dense -->
## Unbound in Brief

- **NLnet Labs**, BSD licence; 1.0.0 released 20 May 2008; current 1.26.2 (21 October 2026), the same version Debian 13 now ships
- **A resolver first:** it answers from its cache, from local data, or by resolving. `auth-zone:` can keep a copy of a zone from a file or by AXFR and IXFR, for example the root (RFC 8806, Module 3)
- **Modules in a chain:** `unbound-control status` shows `modules: 2 [ validator iterator ]`: the iterator resolves, the validator checks DNSSEC
- **Defaults that matter** (unbound.conf(5) 1.26.2): `num-threads` 1; `msg-cache-size` and `rrset-cache-size` 4 MB each; `qname-minimisation` yes (RFC 9156); `aggressive-nsec` yes; `prefetch` no; `serve-expired` no
- **Closed by default:** "only localhost ... is implicitly allowed, the rest is refused" (Module 3)
- **Sizing:** threads and cache sizes are settings you choose (`num-threads`, the two cache sizes); BIND takes one thread per CPU and up to 90% of memory for its cache unless told otherwise (Module 3)

---
<!-- _class: dense -->
## Unbound on Debian 13

```text
/etc/unbound/unbound.conf                include-toplevel: "/etc/unbound/unbound.conf.d/*.conf"
 unbound.conf.d/remote-control.conf      control-enable: yes   control-interface: /run/unbound.ctl
 unbound.conf.d/root-auto-trust-anchor-file.conf    auto-trust-anchor-file: ".../root.key"
unbound.service   unbound-helper root_trust_anchor_update, then unbound -d -p
```

- Validation with the root key (RFC 5011, Module 7) is on; `unbound-control` works over a local socket, without keys
- `root.key` is written by the service's first start; before that, `unbound-checkconf` fails with "auto-trust-anchor-file ... does not exist" (tested). The course's VM image writes it at build time, so the check works before the first start
- **With BIND on the same VM:** Debian's defaults listen on localhost port 53. Tested: "can't bind socket: Address already in use for ::1 port 53", then "fatal error: could not open ports". That is why the lab uses port 5300 (and why Module 8 meets the same message)
- `unbound-resolvconf.service` changes `/etc/resolv.conf` only if the `resolvconf` package is installed

---
<!-- _class: dense -->
## The Lab's Unbound File

```text
server:                                    # labs/module04/vm2/module04.conf
    interface: 127.0.0.1@5300
    interface: 192.0.2.10@5300
    access-control: 192.0.2.0/24 allow     # BIND: allow-recursion
    domain-insecure: "example"             # BIND: validate-except
    log-queries: yes                       # BIND: rndc querylog on
stub-zone:
    name: "example"                        # BIND: type static-stub
    stub-addr: 192.0.2.53
```

- Clauses (`server:`, `stub-zone:`, ...) at the left margin; indented `name: value` options; `#` comments
- Several files: Debian includes every `*.conf` in `unbound.conf.d`, so one file per job is easy to add and remove
- `unbound-checkconf` checks; `sudo unbound-control reload` rereads (and resets the statistics: tested)
- `access-control` actions: `allow` refuses non-recursive queries (except local data); `allow_snoop` permits them; `refuse` answers REFUSED; `deny` drops

---
<!-- _class: dense table-compact -->
## BIND and Unbound, Side by Side

| Task | BIND 9.20 (`named.conf`) | Unbound 1.26 (`unbound.conf`) |
|---|---|---|
| Who may ask | `allow-recursion { ... };` | `access-control: <net> allow` |
| Private TLD, iterate to its servers | `type static-stub; server-addresses` | `stub-zone:` with `stub-addr` |
| Send a domain to a resolver | `type forward; forwarders` | `forward-zone:` with `forward-addr` |
| Everything to one resolver | `forwarders` in `options` | `forward-zone:` named `"."` |
| No validation below a name | `validate-except` | `domain-insecure` |
| Answer a name yourself | a zone of your own | `local-data`, `local-zone` |
| Block or rewrite names | RPZ (Module 6) | `local-zone` types, or RPZ (`rpz:`) |
| Control and counters | `rndc`, statistics channel | `unbound-control` |
| Forwarder is not a resolver | SERVFAIL, "non-improving referral" | the referral goes to the client (tested) |

- The ideas carry over; the defaults and the failure behaviour do not. Test each change on the software you will run

<!--
Last row: Lab 4.2 step 9 and Module 3 Lab 3.2. Unbound's documentation says forward-addr targets "are not authority servers, but are (just like Unbound is) recursive servers too"; with the registry as forwarder, Unbound 1.26.2 returned NOERROR with an empty answer and the delegation in the authority section (rehearsal 4.2.10); a stub resolver sees no address. BIND rejects the same answer. Neither is a configuration you want.
-->

---
<!-- _class: dense -->
## Answers of Its Own: local-zone and local-data

```text
server:
    local-data: "printer.home.arpa. 60 IN A 192.0.2.99"
    local-zone: "new.team01.example." always_nxdomain
$ dig @127.0.0.1 -p 5300 printer.home.arpa       →  flags: qr aa rd ra;  192.0.2.99
$ dig @127.0.0.1 -p 5300 new.team01.example      →  NXDOMAIN   (BIND on port 53: 192.0.2.87)
```

- `home.arpa` is for "non-unique use in residential home networks" (RFC 8375); Unbound serves it, `test`, `invalid`, `onion`, `resolver.arpa` and the private reverse zones as **default local zones**
- Zone types decide what happens to names without local data: `static` (NXDOMAIN), `transparent` (resolve as usual), `always_nxdomain`, `redirect`, `refuse`, and more (unbound.conf(5))
- Good for a few names: a printer, a block list from a script. For whole zones with delegations, run an authoritative server and point a `stub-zone` at it (Lab 4.4)
- The answer carries `aa`: the client cannot tell Unbound's own data from the real zone's (Module 6: policy-implementing resolvers)

---
<!-- _class: dense table-compact -->
## unbound-control

| Command | Does | BIND equivalent |
|---|---|---|
| `status` | version, threads, modules, uptime | `rndc status` |
| `reload` | reread the configuration (cache and counters cleared) | `rndc reconfig` |
| `stats_noreset` | counters: `total.num.queries`, `cachehits`, `cachemiss` | statistics channel |
| `dump_cache` | the cache as text | `rndc dumpdb -cache` |
| `flush name`, `flush_zone name` | drop one name, or a subtree | `rndc flushname`, `flushtree` |
| `lookup name` | which servers it would ask, with round-trip times | the address database in the dump |
| `local_data`, `forward_add` | change data and forwarding without a reload | `rndc addzone` (zones only) |

- Lab 4.2 steps 2-3: `total.num.queries=3`, `cachehits=1`, `cachemiss=2`: the refused `+norec` query counts as a hit (tested). `stats` zeroes the counters

---
<!-- _class: section-divider -->
# 4 · PowerDNS

---
<!-- _class: dense -->
## The PowerDNS Family

- **Authoritative Server** (`pdns_server`): zones from a **backend**: a database, BIND-style zone files, LMDB, GeoIP, LDAP, a script. "PowerDNS comes with ABSOLUTELY NO WARRANTY ... GPL version 2" (startup log)
- **Recursor** (`pdns_recursor`): a resolver only. Debian 13 has 5.2.13; upstream supports 5.4 and calls 5.2 end of life
- **dnsdist:** "a highly DNS-, DoS- and abuse-aware loadbalancer" in front of resolvers or authoritative servers; DoT and DoH to clients (Module 8)
- Three programs, three release trains, three advisory lists: the split design of section 1 from one vendor
- Common pattern: dnsdist on the public address, Recursor or Authoritative behind it, the zone data in a database the provisioning system writes
- PowerDNS-Admin and similar web front ends are separate projects and not in Debian 13; they use the HTTP API you use in Lab 4.3

---
<!-- _class: dense table-compact -->
## Authoritative: Backends and Caches

| Backend (`launch=`) | Data in | Native | Primary | Secondary | DNSSEC | Update |
|---|---|---|---|---|---|---|
| `gsqlite3`, `gmysql`, `gpgsql`, `godbc` | SQL database | yes | yes | yes | yes | yes |
| `bind` | BIND zone files and a `named.conf` | yes | yes | yes | yes | no |
| `lmdb` | LMDB file | yes | yes | yes | yes | yes\* |
| `geoip`, `lua2`, `pipe`, `remote` | computed, or another program | yes | `lua2`, `remote`\* | `remote`\* | all but `pipe` | no |

- **Generic SQL** backends share one schema (`domains`, `records`, `domainmetadata`, ...). The lab: SQLite, no database server
- **Caches in front of the backend:** the packet cache (whole answers, `cache-ttl` 20 s) and the query cache (records, 20 s; negative answers 60 s). Change the database directly and answers may lag by that much
- **Zone cache:** the list of zones, refreshed every 300 s (`zone-cache-refresh-interval`): see two slides on

<!--
Backends table: doc.powerdns.com/authoritative/backends/index.html (fetched 28 October 2026; the asterisks are the page's: support with conditions, see its footnotes; the last row merges four backends: geoip Primary/Secondary No, DNSSEC Yes; lua2 Primary Yes, Secondary No, DNSSEC Yes; pipe all No; remote Primary/Secondary/DNSSEC Yes*). Cache defaults from the comments in Debian's pdns.conf 4.9.17 (cache-ttl=20, query-cache-ttl=20, negquery-cache-ttl=60, zone-cache-refresh-interval=300). Schema: /usr/share/pdns-backend-sqlite3/schema/schema.sqlite3.sql, seven tables.
-->

---
<!-- _class: dense -->
## Native Replication or Zone Transfers

```text
 Native:     provisioning ─SQL─> database primary ══ database replication ══> database replicas
                                        │                                         │
                                  pdns_server (ns1)                         pdns_server (ns2, ns3)

 Primary:    pdns_server ─NOTIFY, AXFR/IXFR─> any secondary (BIND, NSD, Knot, PowerDNS)
```

- "Native replication is the default"; "PowerDNS assumes that the backend is taking care of replication unaided" (PowerDNS documentation). Every server reads the same data from its own database replica; no NOTIFY, no transfers, and the SOA serial does not have to change
- **Primary:** "PowerDNS sends out notifications of changes to secondaries", as BIND does (Module 3). The serial must go up, or secondaries never fetch the change
- **Secondary:** PowerDNS fetches zones by AXFR from any primary, which is also the safest way to move a zone into it (tested: section 4's last slide)
- A zone loaded with `pdnsutil` is **Native**: the database replication you set up is the replication there is

---
<!-- _class: dense -->
## PowerDNS on Debian 13

```text
/etc/powerdns/pdns.conf (root:pdns 640)    include-dir=/etc/powerdns/pdns.d   launch=   security-poll-suffix=
/etc/powerdns/pdns.d/module04.conf         launch=gsqlite3
                                           gsqlite3-database=/var/lib/powerdns/pdns.sqlite3
                                           local-address=127.0.0.1, 192.0.2.30   local-port=5300
                                           api=yes   webserver-address=127.0.0.1   webserver-port=8081
                                           log-dns-queries=yes   loglevel=5
/etc/powerdns/pdns.d/api-key.conf          api-key=<made on the VM (Lab 4.3); never in the kit>
pdns.service: User=pdns, ProtectSystem=full, ... pdns_server --guardian=no --daemon=no
```

- Debian starts with **no backend** (`launch=` empty) and switches off PowerDNS's security-status polling (`security-poll-suffix=` empty; upstream default `secpoll.powerdns.com.`): Debian's security updates are the channel instead
- One setting per line, `name=value`; later files in `pdns.d` add to or replace earlier ones
- `api=yes` "also enables the HTTP listener" (Debian's `pdns.conf`): the API on 127.0.0.1:8081, with the key. Tested: without the key, 401 Unauthorized; not reachable from VM 2
- The SQLite file belongs to user `pdns`: run `pdnsutil` as `sudo -u pdns`

---
<!-- _class: dense -->
## pdnsutil, pdns_control and the Zone Cache

```text
$ sudo -u pdns pdnsutil load-zone team01.example /var/lib/bind/db.team01.example
Creating 'team01.example'
$ sudo -u pdns pdnsutil check-zone team01.example
Checked 25 records of 'team01.example', 0 errors, 1 warnings.
$ dig @127.0.0.1 -p 5300 team01.example SOA          →  status: REFUSED
$ sudo pdns_control rediscover; sudo pdns_control purge
$ dig @127.0.0.1 -p 5300 team01.example SOA          →  flags: qr aa rd;  ... 2026102709 ...
```

- `pdnsutil` writes the database; the running server does not know the new zone until its zone cache refreshes (300 s) or `pdns_control rediscover`, and a REFUSED it already gave stays in the packet cache until `purge` (tested with three zones)
- A zone created **through the API** answered at once (tested): another reason to automate through the API
- `pdns_control` talks to the running server (`rping`, `show udp-queries`, `purge`); `pdnsutil` to the database (`list-zone`, `check-zone`, `secure-zone` for DNSSEC, `set-meta`)

---
<!-- _class: dense -->
## The HTTP API

```text
$ A=http://127.0.0.1:8081/api/v1/servers/localhost      # ~/pdns-api.hdr: "X-API-Key: <key>"
$ curl -s -H @$HOME/pdns-api.hdr $A/zones | jq -r '.[] | [.name, .kind, .serial] | @tsv'
team01.example.	Native	2026102709
$ curl -s -X PATCH -H @$HOME/pdns-api.hdr --data @add-record.json $A/zones/team01.example.   →  204
{"rrsets": [{"name": "api.team01.example.", "type": "A", "ttl": 60, "changetype": "REPLACE",
  "records": [{"content": "192.0.2.85", "disabled": false}]}]}
```

- REST over HTTP with JSON: `GET` lists, `POST` creates zones, `PATCH` replaces or deletes whole RRsets, `PUT` changes zone settings, `DELETE` removes zones; `/statistics` gives the counters
- **SOA-EDIT-API:** a zone loaded with `pdnsutil` has none: tested, a `PATCH` left the serial at 2026102709. After `PUT {"soa_edit_api": "INCREASE"}` the next change gave 2026102710. Zones created through the API get `DEFAULT`: today's YYYYMMDD01 if that is higher, else +1
- Treat the key as a secret: in a mode-600 header file, not on the command line where `ps` shows it; the API on localhost or behind TLS; change the key if it leaks

<!--
Rehearsal steps 4.3.8-4.3.10 (28 October 2026). PowerDNS documentation (domainmetadata): "If not set during zone creation, a SOA-EDIT-API metadata record is created and set to DEFAULT"; DEFAULT follows the SOA-EDIT-DNSUPDATE rule "Generate a soa serial of YYYYMMDD01. If the current serial is lower than the generated serial, use the generated serial", otherwise it adds one: with the course's 202610xxNN serials, DEFAULT jumps to the class date's YYYYMMDD01 (the code review reproduced 2026102709 -> 2026102801 on 28 October), so the lab uses INCREASE, which adds one on any date. curl reads headers from a file with -H @file (curl 7.55 and later; Debian 13 has 8.14). With Native replication the serial does not matter to PowerDNS's own servers, but it does to any secondary and to monitoring that compares serials (Module 3).
-->

---
<!-- _class: dense -->
## A Migration Finding: One Record Changed on Import

```text
team01.example zone file (Module 2):   @   IN HTTPS 0 www                  (a relative name)
$ sh zonediff.sh team01.example /var/lib/bind/db.team01.example 127.0.0.1 5300
< team01.example.   60 IN HTTPS   0 www.team01.example.        what BIND serves
> team01.example.   60 IN HTTPS   0 www.                       what PowerDNS 4.9.17 serves
```

- `pdnsutil load-zone` did not complete the relative target of the AliasMode HTTPS record; `check-zone` reported 0 errors. MX, SRV, CNAME, CAA, the three-string DKIM TXT and the ServiceMode HTTPS record arrived intact
- The same file in NSD 4.12.0 and Knot DNS 3.4.6: "same". Into PowerDNS from `named-compilezone -s full` output (absolute names) or by AXFR from BIND: "same" (all tested 28 October 2026)
- Lesson: an importer is a parser, and parsers differ. Compare what the old and the new server **answer**, record by record, before you move the delegation
- `labs/module04/vm1/zonediff.sh`: AXFR from the new server, both sides through `named-checkzone -D -s full`, then `diff`

<!--
Not reported upstream (course rule); it may be fixed in later PowerDNS releases: test the version you deploy. In the lab the fix goes through the API (Lab 4.3 step 7). Clients follow an HTTPS AliasMode target to find the service (RFC 9460 §2.4.2); "www." would send them to a name that does not exist.
-->

---
<!-- _class: section-divider -->
# 5 · Alternatives and Hosted DNS

---
<!-- _class: dense -->
## NSD and Knot DNS: Authoritative Only

- **NSD** (NLnet Labs, BSD): authoritative only, zone files and `nsd.conf`, transfers in and out, no recursion "by design". "Three DNS root servers and many top-level domain registries use NSD" (NLnet Labs). Debian 13: 4.12.0
- **Knot DNS** (CZ.NIC, GPL-3+): authoritative only, automatic DNSSEC signing with policies (Module 7), DNS over QUIC (Module 8's demo), `knotc` for control. Debian 13: 3.4.6; upstream 3.6.2
- Both load the same zone files as BIND. Tested: Module 2's team zone served by NSD and by Knot, compared with `zonediff.sh`: "same" for both
- Typical use: listed secondaries behind a hidden primary (Module 5), or a second implementation next to BIND for diversity

```text
zone:                                     # nsd.conf          zone:                    # knot.conf
    name: team01.example                                        - domain: team01.example
    zonefile: db.team01.example                                   file: db.team01.example
    provide-xfr: 127.0.0.1 NOKEY                                  acl: local
```

<!--
Test (plan/m04_notes.md, experiment 14): Debian 13 nsd 4.12.0 and knot 3.4.6 in a container, NSD on 127.0.0.1@5301, Knot on @5302, each allowing transfers to 127.0.0.1 only; zonediff.sh against the BIND zone file: "same" for both, including the HTTPS AliasMode target.
-->

---
<!-- _class: dense table-compact -->
## Resolvers and Front Ends

| Software | What it is | In Debian 13 |
|---|---|---|
| **Knot Resolver** (CZ.NIC) | resolver; version 6 adds "a new process called knot-resolver-manager" and "declarative configuration in YAML that can be validated before running" | 5.7.5 (Lua configuration); upstream 6.5.1 |
| **PowerDNS Recursor** | resolver "including Lua scripting capabilities" (Debian description) | 5.2.13 (end of life upstream) |
| **dnsdist** | load balancer and filter in front of servers | 1.9.16 (end of life upstream) |
| **dnsmasq** | "Small caching DNS proxy and DHCP/TFTP server" (Debian description) | 2.91 |
| **CoreDNS** | plug-in server; "the default implementation of Kubernetes cluster DNS" | not packaged |
| **systemd-resolved** | a local stub resolver and cache for a Linux host | 257.13 |

- Pick by job: a site resolver, a forwarder on a router, the DNS inside a container platform, a front end that spreads load
- A distribution's version can lag upstream by a major release: plan whether you take the distribution's package or the vendor's

<!--
Knot Resolver quotes: knot-resolver.cz "Upgrading to Knot Resolver 6" (fetched 28 October 2026). CoreDNS: kubernetes.io "Using CoreDNS for Service Discovery"; coredns.io (Apache 2.0, CNCF graduated). dnsmasq and pdns-recursor descriptions are their Debian 13 package descriptions. systemd-resolved: apt-cache policy systemd-resolved, 257.13-1~deb13u1 (28 October 2026). dnsdist 1.9.16 as packaged: "Enabled features: ... dns-over-tls(openssl) dns-over-https(nghttp2) ..." (dnsdist --version).
-->

---
<!-- _class: dense -->
## Microsoft DNS and Hosted DNS Services

- **Windows Server DNS** on domain controllers can store zones in Active Directory: "all zone data is replicated automatically by means of Active Directory replication" (Microsoft Learn), not by zone transfers. An AD domain's own names live there
- Connecting it to the rest: conditional forwarders or stub zones toward it from BIND or Unbound (Module 3), zone transfers to or from it where policy allows
- **Hosted (cloud) DNS:** the provider runs the listed authoritative servers, usually anycast (Module 5); you change records through a web console or an API; you pay per zone and per query
- **Vendor extensions:** "Amazon Route 53 alias records provide a Route 53–specific extension to DNS", allowed at the zone apex where a CNAME is not. The standard answer for web clients is the HTTPS record (RFC 9460, Module 2); extensions do not move to another provider
- **Before you choose one:** can it take or give a zone transfer (a way out), does it sign with DNSSEC and publish CDS (Module 7), how many records and changes per second, and what does a query cost at peak

<!--
Microsoft Learn: "Understanding Active Directory Domain Services Integration" / Active Directory-integrated DNS zones (fetched 28 October 2026). AWS: "Choosing between alias and non-alias records" (fetched 28 October 2026). Provider capabilities differ and change: the last bullet is a checklist, not a claim about any one provider.
-->

---
<!-- _class: section-divider -->
# 6 · Choosing and Migrating

---
<!-- _class: dense table-compact -->
## Selection Questions

| Question | Why it matters | Where you saw it |
|---|---|---|
| Which role: authoritative, resolver, both, front end? | split or combined programs | sections 1-4 |
| Where does zone data come from? | files and `rndc`, a database and an API, a provider's console | Labs 4.1, 4.3 |
| How do changes reach the other servers? | NOTIFY and transfers, database replication, the provider | Module 3, section 4 |
| Which features do you need, in this build? | DNSSEC signing, RPZ, DoT/DoH/DoQ, views, GeoIP | `named -V`, Modules 5-8 |
| Who supports this version, until when? | vendor branch, distribution, paid support | section 1 |
| How do you hear of and install fixes? | advisories, packages, a tested upgrade path | 21 October 2026 |
| What can your team already run and debug? | logs, control tools, statistics | Labs 4.1-4.4 |
| How do you leave again? | export formats, transfers, API, extensions | section 5 |

- Write the answers down per role and per site; the software often follows from them, and you may run more than one

---
<!-- _class: dense -->
## Measure, Do Not Copy Benchmarks

- Published query rates come from one test set-up: hardware, kernel, query mix, cache state, response sizes, DNSSEC. Yours differs in every one
- **Measure your own:** replay a sample of your real queries against each candidate with `dnsperf` at a fixed rate, or raise the rate with `resperf` until it falls behind (Debian package `dnsperf`, Module 3); on your own servers, never on someone else's (Module 6)
- **Record the set-up with the number:** date, versions, hardware, query file, cache warm or cold, threads and cache sizes. A number without its set-up is not evidence
- **Look beyond speed:** memory per cached record, start-up and reload times for your zone count, behaviour under failure (Lab 3.4, the forwarder rows above), CPU per query when signing
- This course quotes no performance numbers: none were measured on hardware like yours

---
<!-- _class: dense -->
## Moving a Zone to Other Software

1. **Inventory:** zones, record types (HTTPS, CAA, long TXT), DNSSEC keys and policy, transfer and NOTIFY partners, ACLs, views
2. **Load a copy:** by AXFR from the old primary (the new server as a secondary), or from a file with absolute names (`named-compilezone -s full`)
3. **Compare answers:** every record from both servers (`zonediff.sh`), then a sample of real queries; differences are the work list
4. **Run in parallel:** the new server as an extra secondary or stealth server, watched for a while
5. **Switch:** change the primary role or the NS set and the parent's delegation (Module 1), with low TTLs first; keep the old server until the old TTLs have expired
6. **Signed zones:** keys or a key rollover move too: Module 7 (RFC 8901 for two signers)

- **Templates:** keep one configuration file per role and per job, in version control, with the team or site values in one place; check each with its own tool (`named-checkconf -z`, `unbound-checkconf`, `pdnsutil check-zone`) before it reaches a server. The lab kits are examples

---
<!-- _class: dense -->
## Exercise: Which Software Where?

For each organisation, name the software for its authoritative servers and its resolvers, how zone data gets in, and one risk you accept.

1. An ISP with 400,000 broadband customers, resolvers in three cities, and reverse zones for its address space
2. A hosting company with 60,000 customer zones, created and changed by a customer web portal
3. A ccTLD registry: one large signed zone, built from the registration database every few minutes (Modules 9-10)
4. A company with an Active Directory domain, two offices and a public website (Module 3's design exercise)

<!--
Reasonable answers (accept others that name the role split, the data path and a risk):
1. Resolvers: Unbound, BIND or PowerDNS Recursor (or Knot Resolver), two or more per city, anycast between them (Module 5), dnsdist in front if load spreading is needed; validation on (Module 7). Authoritative reverse zones: BIND or NSD/Knot fed from the IP address management system. Risk: one resolver implementation everywhere means one bug affects every customer; some ISPs run two.
2. PowerDNS Authoritative with a SQL backend and native (database) replication, zones created through the API by the portal; or BIND with rndc addzone and catalog zones. Risk: the database is now part of DNS service; a portal bug can break many zones at once (validate input, rate-limit changes).
3. A hidden primary that builds and signs the zone (BIND dnssec-policy or Knot), public secondaries on NSD and Knot (and/or BIND) at many sites, often with an anycast provider: implementation diversity at the TLD. Risk: build pipeline errors publish to every server quickly; the registry needs checks before NOTIFY (Module 11).
4. Internal: Windows DNS on the domain controllers for the AD zones; site resolvers (Unbound or BIND) forwarding the AD domain to the domain controllers (conditional forwarding, Module 3) and resolving the rest themselves. Public zone: a hosted DNS service or a secondary service with a hidden primary. Risk: two administration teams and two tool sets.
-->

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

```text
 VM 1 192.0.2.30           VM 2 192.0.2.10         registry 192.0.2.53   lab resolver 192.0.2.55
 BIND :53 primary          BIND :53 resolver       example.              Lab 4.2's forwarder
 PowerDNS :5300 (4.3)      Unbound :5300 (4.2)
```

- **Packages** (in the VM image, services disabled): `unbound`, `pdns-server`, `pdns-backend-sqlite3`, `sqlite3`, `curl`, `jq`. With a mirror: `sudo apt install --no-install-recommends` them (the recommended `pdns-backend-bind` stops Lab 4.3), then `sudo systemctl disable --now unbound pdns`
- **Kit** `labs/module04/`: `vm1/module04.conf` (PowerDNS), `vm1/zonediff.sh`, `vm1/*.json` (API bodies), `vm1/db.lab4.teamNN.example`; `vm2/module04.conf` (Unbound), `vm2/named.conf.stats`; `comparison-sheet.md` (Lab 4.4)
- **Logs:** `sudo journalctl -u named -f`, `-u unbound -f`, `-u pdns -f` in a second SSH session
- **Offline:** every step uses your VMs, the registry and the lab resolver. Replace `NN` and the addresses with your lab sheet's
- **End state (Lab 4.4):** Unbound and PowerDNS stopped and disabled, BIND as Module 3 left it

---
<!-- _class: dense -->
## Lab 4.1: BIND Under the Hood (20 min)

1. On VM 2: `named -V`. Find json-c, libxml2, LMDB, maxminddb and nghttp2: what does each give you?
2. `named-checkconf -p`: which of Debian's files did each part come from? Where are the root hints?
3. `sudo rndc status`: worker threads, zones (why 100 automatic?), recursive clients
4. `sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.m03`, then append `vm2/named.conf.stats` to `named.conf.local`; `named-checkconf`; `sudo rndc reconfig`. Ask `dig @127.0.0.1 mail.teamNN.example` three times, reading `curl -s http://127.0.0.1:8053/json/v1/server | jq '.nsstats.Requestv4, .views._default.resolver.cachestats.QueryHits'` before and after
5. On VM 1: add `allow-new-zones yes;` to `options` in `named.conf.options`; check; reconfig. Copy `vm1/db.lab4.teamNN.example` (with your `NN`) to `/var/lib/bind/`; `sudo rndc addzone lab4.teamNN.example '{ type primary; file "/var/lib/bind/db.lab4.teamNN.example"; };'`; `dig @127.0.0.1 www.lab4.teamNN.example +norec`; `sudo rndc showzone lab4.teamNN.example`; `ls /var/cache/bind`
6. `sudo rndc delzone -clean lab4.teamNN.example`; delete the `allow-new-zones` line; check; reconfig

> **Checkpoint:** requests up by 3 and cache hits by 2; the added zone answered with `aa`, then is gone with its file; VM 1's `named.conf.options` is Debian's again

<!--
Rehearsed 28 October 2026 (labs/module04/test/rehearse.sh 4.1.1-4.1.6b): step 3 "worker threads: 12" (one per CPU of the test host; a VM shows its own), "number of zones: 102 (100 automatic)", "recursive clients: 0/900/1000"; step 4 "requests=3 hits=2"; step 5 "_default.nzd" in /var/cache/bind and "flags: qr aa"; step 6 "zone 'lab4.teamNN.example' and associated files will be deleted.", then NXDOMAIN from VM 1 (the name is under teamNN.example). The file goes a moment after the command. If a participant removes allow-new-zones before delzone, the zone disappears but stays in _default.nzd and returns when the option comes back: delete first.
-->

---
<!-- _class: dense -->
## Lab 4.2: Unbound Next to BIND (25 min)

1. On VM 2: read the two files in `/etc/unbound/unbound.conf.d`. Copy `vm2/module04.conf` there (your `NN` and addresses); `sudo unbound-checkconf`; `sudo systemctl start unbound`; `sudo unbound-control status`
2. On VM 1: `sudo rndc querylog on` and watch its journal. On VM 2: `dig @127.0.0.1 -p 5300 ftp.teamNN.example`, then the same on port 53. Same answer? In VM 1's log, which line is Unbound's (flags)?
3. From VM 1: `dig @192.0.2.10 -p 5300 mail.teamNN.example`, then with `+norec`. Why REFUSED?
4. `sudo unbound-control stats_noreset | grep total.num`; `sudo unbound-control dump_cache | grep teamNN`; `sudo unbound-control flush ftp.teamNN.example`
5. Remove the `#` from the two `local-` lines; `sudo unbound-control reload`; ask Unbound and BIND for `printer.home.arpa` and `new.teamNN.example`
6. Change `stub-zone:` to `forward-zone:` and `stub-addr: 192.0.2.53` to `forward-addr: 192.0.2.55`; reload; `dig @127.0.0.1 -p 5300 web.teamNN.example`: who asked VM 1?
7. Forward to the registry, 192.0.2.53; reload; ask for `mail.teamNN.example`. Compare with Module 3's BIND. Put the stub zone back; reload

> **Checkpoint:** the same answers from both resolvers; Unbound's line `-E(0)DC` in VM 1's log; the referral passed to the client in step 7 (BIND: SERVFAIL); the stub zone back (Practical Assessment 2A, task 2)

<!--
Rehearsed 28 October 2026 (4.2.1-4.2.11): without the kit file, Debian's defaults fail: "can't bind socket: Address already in use for ::1 port 53". unbound-checkconf works once the service has started once (root.key). Step 2: Unbound "query: ftp.teamNN.example IN A -E(0)DC" (DO and CD, no cookie), BIND "-E(0)DK" then "-E(0)DV". Step 3: 192.0.2.81, then REFUSED (allow refuses non-recursive queries). Step 5: printer 192.0.2.99 with aa; new: NXDOMAIN from Unbound, 192.0.2.87 from BIND. Step 6: list_forwards "example. IN forward +i 192.0.2.55"; VM 1's log shows 192.0.2.55. Step 7: NOERROR, "ANSWER: 0, AUTHORITY: 1", team01.example NS ns1.team01.example. Reload clears the cache and the counters.
-->

---
<!-- _class: dense -->
## Lab 4.3: PowerDNS with a Database (30 min)

1. VM 1: `grep -v '^#' /etc/powerdns/pdns.conf | grep .`; `ls /etc/powerdns/pdns.d` (empty): which backend? `sudo -u pdns sqlite3 /var/lib/powerdns/pdns.sqlite3 < /usr/share/pdns-backend-sqlite3/schema/schema.sqlite3.sql`
2. `sudo install -m 640 -g pdns vm1/module04.conf /etc/powerdns/pdns.d/` (your address first); `(umask 077; echo "X-API-Key: $(openssl rand -hex 16)" > ~/pdns-api.hdr)`; `sed 's/^X-API-Key: /api-key=/' ~/pdns-api.hdr | sudo install -m 640 -g pdns /dev/stdin /etc/powerdns/pdns.d/api-key.conf`
3. `sudo systemctl start pdns`; `sudo journalctl -u pdns -n 15`; `dig @127.0.0.1 -p 5300 teamNN.example SOA`
4. `sudo -u pdns pdnsutil load-zone teamNN.example /var/lib/bind/db.teamNN.example`; `check-zone`; ask; `sudo pdns_control rediscover; sudo pdns_control purge`; ask
5. `sh vm1/zonediff.sh teamNN.example /var/lib/bind/db.teamNN.example 127.0.0.1 5300`: what differs, and why?
6. `A=http://127.0.0.1:8081/api/v1/servers/localhost`; `curl -s -H @$HOME/pdns-api.hdr $A/zones | jq`; again without `-H`
7. `curl -s -X PATCH -H @$HOME/pdns-api.hdr --data @fix-https.json $A/zones/teamNN.example.` (your `NN` in the file); `zonediff.sh`; the serial?
8. `PUT` `soa-edit-api.json` to the same URL, `PATCH` `add-record.json`; `dig ... api.teamNN.example`; serial, `zonediff.sh`

> **Checkpoint:** REFUSED until `rediscover`; HTTPS differs, then "same"; 401 without key; `api`, serial +1 (2A task 3)

<!--
Rehearsed 28 October 2026 (4.3.1-4.3.10). Step 1: "launch=" and "security-poll-suffix=" empty. Step 3: "UDP server bound to 192.0.2.30:5300", "[webserver] Listening for HTTP requests on 127.0.0.1:8081"; REFUSED with "flags: qr rd;" (no zone). Step 4: "Checked 25 records of 'teamNN.example', 0 errors, 1 warnings" (the alpn quoting); still REFUSED (zone cache); after rediscover and purge "flags: qr aa rd;" and the team's serial. Step 5: "< ... HTTPS 0 www.teamNN.example." and "> ... HTTPS 0 www." Step 6: "teamNN.example. Native <serial>", then "Unauthorized" (401). Step 7: 204, "same", serial unchanged (no SOA-EDIT-API on a pdnsutil-loaded zone). Step 8 (soa-edit-api.json sets INCREASE): 204, 204, 192.0.2.85, zonediff now shows the SOA one higher (2026102710 from 2026102709) and the api record: PowerDNS and BIND hold different zones. Discussion: which one is the zone now? The (umask 077) runs in a subshell so that later sudo cp commands do not create unreadable files; the header file keeps the key off the command line (ps).
-->

---
<!-- _class: dense -->
## Lab 4.4: Compare, Then Clean Up (15 min)

1. VM 2: uncomment the three `teamNN.example` stub-zone lines in Unbound's file; reload; `dig @127.0.0.1 -p 5300 api.teamNN.example` and `dig @127.0.0.1 api.teamNN.example`. Who answered? PowerDNS's journal on VM 1
2. Counters: `sudo unbound-control stats_noreset | grep total.num`; VM 2's statistics channel; on VM 1 `curl -s -H @$HOME/pdns-api.hdr $A/statistics | jq`, `sudo pdns_control show udp-queries`
3. Fill in `labs/module04/comparison-sheet.md` (one per team)
4. VM 2: `sudo systemctl disable --now unbound`; `sudo rm /etc/unbound/unbound.conf.d/module04.conf`; `sudo mv /etc/bind/named.conf.local.m03 /etc/bind/named.conf.local`; `named-checkconf`; `sudo rndc reconfig`
5. VM 1: `sudo systemctl disable --now pdns`; `sudo rm /etc/powerdns/pdns.d/api-key.conf /etc/powerdns/pdns.d/module04.conf ~/pdns-api.hdr`
6. Both: `sudo ss -lntup | grep -E ':(5300|8053|8081) '` (nothing); `dig @192.0.2.10 www.teamNN.example`

> **Checkpoint:** Unbound gave PowerDNS's `api`, BIND NXDOMAIN: one delegation, two zones. Nothing on 5300; BIND as Module 3 left it (2B)

**Discussion** (a minute per team, 2B task 4): which of the three for a zone you run, and what would you test first?

<!--
Rehearsed 28 October 2026 (4.4.1-4.4.6): Unbound 192.0.2.85, BIND NXDOMAIN; PowerDNS log "Remote 192.0.2.10 wants 'api.teamNN.example|A', do = 1". After the clean-up only BIND listens (no 5300, 8053 or 8081), VM 2's named.conf.local and named.conf.options are byte-equal to the team's own pre-Module-4 files (the harness adds a line to VM 2's file at set-up, as a lab-sheet edit would, so copying Module 3's template back would fail the check), VM 1's BIND files unchanged, no API key on disk. Why clean up: Module 8 Lab 8.3 puts Unbound on VM 1's 127.0.0.1 port 5300; Modules 5-8 expect BIND alone on both VMs. The SQLite database may stay (PowerDNS is disabled); module04.conf goes, because it binds 127.0.0.1:5300, Module 8's port. Moving the saved named.conf.local back removes the statistics channel and keeps the team's lab-sheet addresses.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 1034 (STD 13); RFC 9499 (BCP 219) terminology; RFC 2182 (BCP 16)
- RFC 6303 (BCP 163) locally served zones; RFC 6761; RFC 8375 `home.arpa`
- RFC 3225, RFC 4035 (DO, CD bits); RFC 7873 cookies; RFC 9156
- RFC 9432; RFC 9460 SVCB and HTTPS; RFC 8901; RFC 5011; RFC 8806
- ISC: BIND 9.20 ARM (history, `rndc`, `statistics-channels`, logging); isc.org/download; KB aa-00896, aa-00913
- NLnet Labs: unbound.conf(5) 1.26.2, `unbound-control`; NSD; security advisories
- PowerDNS: Authoritative docs (backends, modes, HTTP API, metadata, EOL); Recursor, dnsdist EOL
- CZ.NIC (knot-dns.cz, knot-resolver.cz); Microsoft Learn; AWS Route 53; kubernetes.io; Debian 13 packages (`copyright`, `changelog`)

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>named -V
named-checkconf -p
sudo rndc status
sudo rndc addzone|delzone
curl :8053/json/v1/server
sudo unbound-checkconf
sudo unbound-control status
sudo unbound-control reload
sudo pdns_control rediscover
curl -H @$HOME/pdns-api.hdr $A/zones
sh zonediff.sh zone file server port
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. A colleague wants to run Unbound and BIND on the same Debian host. What fails first, and name two ways to make them coexist.
2. Your zone is in PowerDNS with native replication. Why may its SOA serial never change, and when does that become a problem?
3. You added a zone with `pdnsutil` and the server answers REFUSED. What two caches are involved, and what do you run?
4. An importer reported 0 errors, but one record changed. How would you have caught it before moving the delegation?
5. Debian 13 ships dnsdist 1.9, which its vendor no longer supports. What do you check before you deploy it?
6. Why might a TLD run NSD or Knot DNS on some listed servers and BIND on others?

<!--
Review questions for the deck; Knowledge Check 2 (the paper quiz) is separate.
1. Port 53: Debian's Unbound listens on localhost:53, which BIND already holds ("Address already in use"). Give one of them other addresses or ports (Lab 4.2: Unbound on 5300), or run them on separate hosts or containers; better still, one resolver per host.
2. Native: every server reads the same database through database replication; nothing compares serials. It matters as soon as a secondary fetches by AXFR/IXFR (it never sees a change), or monitoring compares serials (Module 3, Module 11): set SOA-EDIT-API (and SOA-EDIT) or raise it yourself.
3. The zone cache (list of zones, refreshed every zone-cache-refresh-interval, 300 s) and the packet cache (the REFUSED answer, cache-ttl 20 s): pdns_control rediscover, then pdns_control purge. Creating zones through the API avoids it.
4. Compare answers from old and new server, record by record (zonediff.sh: AXFR from the new server, canonical form, diff), then sample real queries; or load by AXFR rather than by parsing the file.
5. Debian's security support for the package (the security tracker, DSAs, recent uploads: 1.9.16 in August 2026), whether the features you need are in 1.9, and the path to a supported version (vendor packages for 2.x) with its own update process.
6. Diversity: a bug or a crafted query that stops one implementation does not stop all listed servers; NSD and Knot are authoritative-only and small; NLnet Labs reports three root servers and many TLD registries using NSD.
-->

---
<!-- _class: section-divider -->
# Thank You

---
<!-- _class: dense -->
## Contact

**Terry Sweetser** — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Licence

---
<!-- _class: dense -->
## Creative Commons Attribution–NonCommercial–ShareAlike 4.0

This work is licensed under a  
[Creative Commons Attribution–NonCommercial–ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

**You are free to:**
- **Share** — copy and redistribute the material
- **Adapt** — remix, transform, and build upon the material

**Under the following terms:**
- **Attribution** — credit **Terry Sweetser (IEISI.ORG)**
- **NonCommercial** — no commercial use
- **ShareAlike** — same licence on derivatives
