---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 3: DNS Server Types — Recursive, Authoritative, and Specialised Roles

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Distinguish** authoritative, recursive, forwarding and stub roles by their RFC 9499 definitions and by the flags in a server's answers
- **Configure** a secondary in BIND 9.20 (`allow-transfer`, `also-notify`, `primaries`) and read a zone transfer in the logs of both servers
- **Configure** a recursive resolver on Debian 13: who may use it, what its cache holds, and how it reaches a private TLD
- **Implement** conditional forwarding, and explain `forward only`, `forward first` and why a forwarder must be a resolver
- **Analyse** failures: a refused transfer, a missing NOTIFY, an unreachable primary, an expired zone, a wrong or dead forwarder
- **Evaluate** stealth servers, hidden primaries, DNS64, a local root copy and filtering resolvers for a given network
- **Design** the number and placement of servers for an organisation (RFC 2182)

---
<!-- _class: dense -->
## Where Day 1 Left Off

```text
 VM 1  192.0.2.30   BIND, primary for teamNN.example and two reverse zones (Module 2)
                    Debian's defaults: also recursive for its own subnet (ra in every answer)
 VM 2  192.0.2.10   bind9 installed, named not started
 registry 192.0.2.53      example.: delegates teamNN.example to VM 1 only (ns1)
 lab resolver 192.0.2.55  Module 1's resolver, still on today
```

- **Today:** VM 2 becomes your resolver (Labs 3.1-3.2), then also a secondary for your zone (3.3); Lab 3.4 stops VM 1, watches what still works, and removes the secondary again
- **After today:** VM 2 is a resolver only. Module 6 hardens it, Module 7 validates with it, Module 8 encrypts it
- Module 1 named the roles and walked a resolution; Module 2 wrote the zone and described transfers. This module configures the servers. Software choice is Module 4; anycast, hidden-primary designs and views are Module 5

---
<!-- _class: dense table-compact -->
## What Changed Recently

| Then | Now |
|---|---|
| Older RFCs' names for the primary, the secondary and a hidden primary | RFC 9499 (BCP 219, March 2024): primary, secondary, stealth server; BIND 9.20 writes `type primary` and `primaries` |
| Caching a failed lookup optional: a resolver "MAY cache a server failure response" (RFC 2308 §7.1) | RFC 9520 (December 2023): resolvers MUST cache resolution failures, for at least 1 second and at most 5 minutes |
| Every zone added to every secondary by hand | Catalog zones (RFC 9432, July 2023): the list of zones is itself a zone; BIND 9.20 consumes it |
| A root zone copy on the resolver (RFC 7706, November 2015), which "was considered controversial" (RFC 8806 §1) | RFC 8806 (June 2020) obsoletes it; BIND's `type mirror` validates the copy |
| Forwarding only over plain DNS | BIND 9.20 `forwarders ... tls`: DNS over TLS to the forwarder (Module 8 does it with Unbound's `forward-tls`) |

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. Day 2 start and what changed (5m)
2. Server roles (10m)
3. Primary and secondary servers (22m)
4. Recursive resolvers (18m)
5. Forwarding (14m)
6. Specialised roles (10m)
7. Choosing and placing servers (11m)

## Agenda (90 min Lab)

1. Lab 3.1 A resolver on VM 2 (20m)
2. Lab 3.2 Forwarding (20m)
3. Lab 3.3 A secondary on VM 2 (30m)
4. Lab 3.4 Failure and clean-up (20m)

<!--
Day 2's Session 1 is this module's theory, so there is no knowledge-check slot here: Knowledge Check 2 (Modules 3-4) closes Session 3, which is Module 4 (Program Facts).
-->

---
<!-- _class: section-divider -->
# 1 · Server Roles

---
<!-- _class: dense table-compact -->
## One Protocol, Many Jobs

Module 1's roles table, with one new row (stealth), the forwarder in full, and a new column: the queries each server sends itself.

| Role (RFC 9499) | Answers from | Its own queries | Flags |
|---|---|---|---|
| **Primary**, **secondary** | as Module 1 | secondary: SOA checks, transfers | `aa` |
| **Stealth server** | as a secondary, but "not listed in an NS RR for the zone" (RFC 1996) | SOA checks, transfers | `aa` |
| **Recursive resolver** | as Module 1 | iterative, RD clear | `ra` |
| **Forwarder** | another resolver, which it asks with RD set | recursive, RD set | `ra` |
| **Stub resolver** | "cannot perform all resolution itself" | to its resolvers only | - |

- Say recursive resolver, not "full resolver": RFC 9499 finds "no consensus on what the term means". With a cache it is a **full-service resolver** (RFC 1123 §6.1.3.1). An **authoritative-only server** "ignores requests for recursion": the registry is one

---
<!-- _class: dense -->
## Read the Flags: What Kind of Server Is This?

```text
$ dig @192.0.2.53 www.team01.example            # registry: authoritative-only
;; flags: qr rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available        → a referral to ns1.team01.example
$ dig @192.0.2.30 www.team01.example +norec     # VM 1 with Debian's defaults
;; flags: qr aa ra; ...                                  → authoritative, and offers recursion
$ dig @192.0.2.30 www.team02.example            # another team's name, offline
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL ...      → VM 1 tried to resolve it
$ dig @192.0.2.55 www.team01.example            # lab resolver
;; flags: qr rd ra; ...                                  → an answer, no aa: from a resolver
```

- `aa`: the answer comes from a zone this server serves. `ra`: it offers recursion to you
- Ask with `+norec` to see only the server's own data (a cached answer or a referral)
- A server may show `aa` for its own zones and `ra` for everything else: VM 1 does today

<!--
Rehearsed 28 October 2026 with BIND 9.20.30 (plan/m03_notes.md, e5). The registry is "recursion no"; VM 1 runs Debian's named.conf.options (only "directory"), so BIND's default allow-recursion { localnets; localhost; } applies to every host on the lab subnet. Offline, VM 1's recursion for another team's name fails (SERVFAIL): it knows only the real root.
-->

---
<!-- _class: dense -->
## Two Jobs, Two Servers

- An authoritative server publishes **your** data to the world; a resolver fetches **anyone's** data for your users. Different clients, different risks
- **Mixing them on one server:**
  - a resolver that also serves a zone answers it from its own copy, even after the parent delegates elsewhere (Lab 3.3 shows this on VM 2)
  - a cache open to the Internet is an open resolver, used in reflection attacks (RFC 5358, BCP 140; Module 6)
  - one restart or overload takes down both your public zone and your users' lookups
- BIND does both by default: `recursion yes`, and recursion allowed for `localnets` and `localhost` (ARM). Unbound is built as a resolver and answers only localhost until `access-control` says otherwise (unbound.conf(5) 1.26.2)
- In this course: VM 1 is authoritative (Module 6 turns off its recursion), VM 2 is the resolver. Its stealth secondary (Lab 3.3) is RFC 2182 §5.1's site pattern, removed in Lab 3.4 only because Module 7 needs VM 2 to validate the zone, not serve it

---
<!-- _class: dense table-compact -->
## Who Runs Which Servers

| Organisation | Authoritative | Resolvers |
|---|---|---|
| Small business | its zone at a DNS provider or registrar | the ISP's, or a public resolver; a home router proxies them |
| Enterprise | public zones (primary in-house or hidden, secondaries outside); internal zones on separate servers | its own, per site; forwarding to a central cache or a filtering service |
| ISP | customer zones, reverse zones for its address space | large caches for its customers, often anycast (Module 5) |
| Registry (TLD) | the TLD zone, on servers at many sites; registry systems (Module 9) | its own, for operations |
| Hosting or DNS provider | many customer zones, API-driven (Module 4), often a secondary service for others | its own |

- Same software, different settings: the role comes from the configuration, not the package
- Most of you will run at least two of these: a public zone and resolvers for your users

---
<!-- _class: dense -->
## Your Two VMs After Today

```text
          Lab 3.1-3.2                      Lab 3.3                          Lab 3.4, end of day
 VM 1  primary (Module 2)            primary, allow-transfer to VM 2      primary, no transfers
 VM 2  resolver: static-stub for     resolver + stealth secondary          resolver only
       example., then forwarding     for teamNN.example                    (Module 6 starts here)
```

- The registry delegates `teamNN.example` to one address per team (VM 1). VM 2 is therefore a **stealth** secondary: it holds the zone and answers with `aa`, but no NS record names it
- That is a real pattern: RFC 2182 §5.1 makes site servers stealth secondaries "to provide answers to local queries directly"
- It is also why Lab 3.4 shows the limit: resolvers elsewhere still depend on VM 1 alone
- Module 6 Lab 6.4 builds a TSIG-protected secondary on VM 2 and removes it; Module 7 needs VM 2 to resolve your zone, not serve it

---
<!-- _class: section-divider -->
# 2 · Primary and Secondary Servers

---
<!-- _class: dense -->
## How Many Servers, and Where

- "we require every zone to be available on at least two servers" (RFC 1034 §4.1; Module 2)
- RFC 2182 (BCP 16, "Selection and Operation of Secondary DNS Servers"):
  - "Secondary servers must be placed at both topologically and geographically dispersed locations" (§3.1)
  - not all "on the same LAN segment in the same room of the same building - or any of those" (§3.2)
  - "It is recommended that three servers be provided for most organisation level zones, with at least one which must be well removed from the others" (§5); four or five for higher reliability
  - more is not always better: larger responses, and more servers that can be misconfigured unnoticed (§5)
- Reverse zones "tend to be less crucial" (§5): fewer, closer servers will often do
- Every server in the NS set must answer with the same data: the parent's NS set and the zone's must agree (Module 1, Lab 1.3)

---
<!-- _class: dense -->
## A Real Zone's Servers

```text
$ dig isc.org NS +short                         $ dig isc.org SOA +short
ns1.isc.org.                                    ns-int.isc.org. hostmaster.isc.org.
ns2.isc.org.                                      2026102355 7200 3600 24796800 3600
ns3.isc.org.                                    $ dig @ns-int.isc.org isc.org SOA +norec
ns.isc.afilias-nst.info.                        ;; ->>HEADER<<- opcode: QUERY, status: REFUSED
nsp.dnsnode.net.
```

- Five servers: three of ISC's own and two operated by other organisations, with names in three TLDs, so no single TLD failure removes them all; every one has IPv4 and IPv6
- The SOA's MNAME, `ns-int.isc.org`, is not in the NS set and refuses queries from outside: a **hidden primary** (next slides)
- Queried 28 October 2026; NS sets and serials change, so query them yourself
- A secondary run by another operator adds a different network and a different organisation; it must accept your NOTIFY and be allowed to fetch your zone

<!--
Addresses at the time: ns1 149.20.2.26, ns2 199.6.1.52, ns3 51.75.79.143, ns.isc.afilias-nst.info 199.254.63.254, nsp.dnsnode.net 194.58.198.32, each also with IPv6; ns-int.isc.org 149.20.2.53 answered REFUSED to the course host. The REFRESH 7200, RETRY 3600 and EXPIRE 24796800 (about 287 days) are ISC's choices, much longer than RFC 1912's suggestion of 2-4 weeks for EXPIRE: worth a question to the room.
-->

---
<!-- _class: dense -->
## The Primary's Side

```text
// VM 1: /etc/bind/named.conf.local (Lab 3.3)
zone "team01.example" {
    type primary;
    file "/var/lib/bind/db.team01.example";
    allow-transfer { 192.0.2.10; };   // who may fetch the zone; BIND 9.20 default: none
    also-notify { 192.0.2.10; };      // NOTIFY to servers not in the NS set
};
```

- **NOTIFY** (`notify yes`, the default): after a reload with a new serial, BIND notifies every server in the zone's NS set except the SOA MNAME, plus `also-notify` (ARM; RFC 1996 §2.1 "Notify Set")
- Your zone's NS set is only `ns1`, which is also the MNAME, so without `also-notify` VM 2 hears nothing and waits for REFRESH (tested)
- `allow-transfer` by address is the minimum; Module 6 replaces it with a TSIG key, Module 8 with transfers over TLS
- `named-checkconf`, then `sudo rndc reconfig` (configuration) or `sudo rndc reload zone` (zone data)

---
<!-- _class: dense -->
## The Secondary's Side

```text
// VM 2: /etc/bind/named.conf.local (Lab 3.3)
zone "team01.example" {
    type secondary;
    primaries { 192.0.2.30; };                    // where to fetch it; several allowed
    file "/var/cache/bind/db.team01.example";     // a copy, kept across restarts
};
```

- `type secondary` and `primaries` (BIND 9.20; the older keywords still parse). The secondary accepts NOTIFY from its primaries, from the zone's NS set, and from `allow-notify` (ARM)
- The file is written in BIND's **raw** format by default for secondaries: read it with `named-compilezone -f raw -F text -o - zone file`, or set `masterfile-format text`
- Debian's AppArmor profile lets `named` write in `/var/cache/bind` and `/var/lib/bind`, not in `/etc/bind`
- The secondary refreshes on the SOA timers, on NOTIFY, on restart and on `rndc refresh`; `rndc retransfer` fetches the zone again (a full transfer in the lab)
- BIND clamps the primary's timers: refresh at least `min-refresh-time` (300 s) and retry at least `min-retry-time` (500 s) by default (ARM)

---
<!-- _class: dense -->
## A Transfer, Line by Line

```text
VM 1 (primary), after "rndc reload team01.example" with serial 2026102702:
  zone team01.example/IN: sending notifies (serial 2026102702)
  zone team01.example/IN: sending notify to 192.0.2.10#53
  client @0x... 192.0.2.10#53696 (team01.example): transfer of 'team01.example/IN':
      IXFR version not in journal, falling back to AXFR (serial 2026102701)
      AXFR-style IXFR ended: 1 messages, 14 records, 375 bytes, ... (serial 2026102702)
VM 2 (secondary):
  client @0x... 192.0.2.30#40916: received notify for zone 'team01.example'
  zone team01.example/IN: notify from 192.0.2.30#40916: serial 2026102702
  zone team01.example/IN: transferred serial 2026102702
```

- Read it in order: NOTIFY out, NOTIFY in, the secondary's SOA check, the transfer, the new serial
- `sudo journalctl -u named -n 20` shows the same lines on each VM (rehearsed 28 October 2026)
- `sudo rndc zonestatus team01.example` on VM 2: `type: secondary`, `serial`, `next refresh`, `expires`

---
<!-- _class: dense -->
## AXFR or IXFR

- The secondary asks for **IXFR** (only the changes, RFC 1995) when it has a copy, **AXFR** (the whole zone, RFC 5936) when it has none
- A primary can send changes only if it has them in a **journal**. A zone edited by hand and reloaded has none, so BIND answers the IXFR request with the whole zone: "IXFR version not in journal, falling back to AXFR", then "AXFR-style IXFR"
- `ixfr-from-differences yes;` makes BIND compare each reloaded file with the previous version and journal the difference; "It is off for all zones by default" (ARM). Tested: "IXFR started (serial 2026102701 -> 2026102702)" and a `.jnl` file on both servers
- Dynamic updates (`nsupdate`, RFC 2136) and inline signing (Module 7) keep journals anyway
- For a small zone the difference does not matter; for a TLD zone of millions of names it does
- AXFR runs over TCP (RFC 5936). The zone crosses the network in clear text: TSIG proves who asked (Module 6), TLS hides the contents (RFC 9103, Module 8)

---
<!-- _class: dense -->
## When the Primary Is Down

```text
VM 2: zone team01.example/IN: refresh: failure trying primary 192.0.2.30#53 (source 0.0.0.0#0): connection refused
$ dig @192.0.2.10 www.team01.example +norec
;; flags: qr aa ra; ...                    the secondary keeps answering from its copy
test zone (SOA 1 60 30 120 60; min-refresh-time 1; min-retry-time 1 on the secondary), 120 s later:
zone short.example/IN: expired
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL
```

- REFRESH and RETRY decide how often the secondary asks; **EXPIRE** is the "upper limit on the time interval that can elapse before the zone is no longer authoritative" (RFC 1035 §3.3.13)
- After EXPIRE without a successful check the secondary answers SERVFAIL: stale data stops being served as authoritative
- The lab zone's 1209600 s (two weeks) gives you time to repair a primary; ISC's `isc.org` uses about 287 days
- BIND clamps short timers: with the defaults, SOA values of 60/30/120 gave an expiry 800 s after the transfer (tested)

---
<!-- _class: dense -->
## Stealth Servers and Hidden Primaries

```text
 hidden primary ──transfers──> listed secondaries (in the NS set) <── resolvers everywhere
 (not in the NS set;           ns1, ns2, ns3: in the parent and in the zone
  REFUSED to the public)  ──transfers──> stealth secondaries at your sites <── your own resolvers
```

- **Stealth server:** authoritative, usually a secondary, "not listed in an NS RR for the zone"; it "will only be known by other servers if they are given static configuration data" (RFC 1996 §2.1): hence `also-notify`
- RFC 2182 §5.1: site servers as stealth secondaries "provide answers to local queries directly", even when the site loses its outside links; they do not count towards the listed servers
- **Hidden primary:** RFC 9499 defines it as "a stealth server that is a primary server for zone transfers"; its name may be the SOA MNAME or appear nowhere. It takes updates and signing out of the attack surface
- Building the hidden-primary architecture with public secondaries is Module 5; here VM 2 is the stealth secondary

---
<!-- _class: dense table-compact -->
## Transfer Problems and What BIND Logs

| Symptom | Log line (BIND 9.20.30, tested) | Fix |
|---|---|---|
| Secondary never loads; SERVFAIL from it | secondary: `failed while receiving responses: REFUSED`; primary: `zone transfer 'zone/AXFR/IN' denied` | `allow-transfer` on the primary, then `rndc retransfer` |
| Changes arrive only every REFRESH | primary: no `sending notify to` line for the secondary | `also-notify`, or list the server in NS |
| Change never arrives | primary: `zone serial (N) unchanged` (Module 2) | raise the serial, reload |
| Primary unreachable | `refresh: failure trying primary ... connection refused` (or `timed out`) | the primary, its firewall, or `primaries` |
| Copy too old | `zone .../IN: expired`, then SERVFAIL | restore the primary before EXPIRE |
| Listed server not serving | lame: REFUSED or no answer at that address (Module 1) | load the zone there, or remove it from NS |

`dig @<each NS> zone SOA +norec`: every server should show the same serial with `aa`. Monitoring that is Module 11.

---
<!-- _class: dense -->
## Many Zones, Many Secondaries

- Each new zone needs a `zone` statement on every secondary: with hundreds of zones, someone forgets one
- **Catalog zones** (RFC 9432, July 2023): "the list of zones is represented as a regular DNS zone ... and transferred using DNS zone transfers"; secondaries add and remove member zones as the catalog changes. BIND 9.20 consumes them (`catalog-zones` in `options`; ARM §6.8)
- `rndc addzone` and `rndc delzone` add and remove zones on a running BIND, with `allow-new-zones yes` (Module 4)
- **Secondary services:** another operator serves your zone from its network (`ns.isc.afilias-nst.info` for `isc.org`). You allow its transfer addresses and notify it; it should check your serial and alert you
- **Multi-provider DNS:** two providers both serving the zone; easy for unsigned zones, harder once the zone is signed (RFC 8901, Module 7)
- Whatever the tool, the check is the same: every listed server answers `aa` with the current serial

---
<!-- _class: section-divider -->
# 3 · Recursive Resolvers

---
<!-- _class: dense -->
## Inside a Resolver

```text
 clients ─RD=1─> [ access check ] ─> [ cache: answers, negative answers, failures ] ─hit─> answer (ra)
                                                    │ miss
                                                    v
                    [ server choice: delegations, addresses, round-trip times ] ─RD=0─> authoritative servers
                                                    │
                    [ validator: Module 7 ]  <──────┘  [ forwarders, stub zones: section 4 ]
```

- **Client side:** who may ask (`allow-recursion`, `allow-query-cache`), how many at once (`recursive-clients`, default 1000 in BIND 9.20)
- **Cache:** everything learned, kept for its TTL within the resolver's limits (Module 2); BIND's default size is 90% of physical memory for a view with recursion (ARM): set `max-cache-size` on a shared host
- **Resolver side:** the walk from Module 1, with a memory of how each server performed
- `rndc dumpdb -cache` writes all three parts to `/var/cache/bind/named_dump.db` (Lab 3.1)

---
<!-- _class: dense -->
## Who May Use It

```text
options {                                        // VM 2, the kit's named.conf.options
    recursion yes;                               // BIND default
    allow-recursion { localnets; localhost; };   // BIND default when not set
    dnssec-validation auto;                      // BIND default (Module 7)
    validate-except { "example"; };              // the lab TLD (section 4's last slide)
};
```

- `localnets`: every subnet this host has an address on. VM 1 on the lab subnet may use VM 2; a host elsewhere gets REFUSED for recursion
- BIND: "if allow-recursion is not present, it defaults to allow-query-cache {localnets; localhost;}" (ARM). Unbound: "only localhost ... is implicitly allowed, the rest is refused" (unbound.conf(5))
- An **open resolver** "accepts and processes queries from any (or nearly any) client" (RFC 9499): Module 6 closes it with named ACLs
- Debian's VM 1 is a resolver for the same subnet today; Module 6 sets `recursion no` there

---
<!-- _class: dense -->
## Looking into the Cache

```text
$ sudo rndc dumpdb -cache; grep -A1 -E 'team01|Address database' /var/cache/bind/named_dump.db
team01.example.          56  IN NS   ns1.team01.example.
mail.team01.example.     60  A       192.0.2.81
nosuch.team01.example.   60  \-ANY   ;-$NXDOMAIN
; team01.example. SOA ns1.team01.example. hostmaster.team01.example. 2026102701 3600 600 1209600 60
ns1.team01.example.      56  \-AAAA  ;-$NXRRSET
www.team01.example.      56  A       192.0.2.80
; Address database dump
; ns1.team01.example. [v4 TTL 56] [v6 TTL 56] [v4 not_found] [v6 nxrrset]
;   192.0.2.30 [srtt 0] [flags 00000004] [edns 6/0] [plain 0/0] [udpsize 512] ...
```

- Positive answers, **negative** answers with the SOA that set their TTL (RFC 2308), and the server addresses with a smoothed round-trip time (`srtt`); a `SERVFAIL cache` section follows
- `sudo rndc flushname name` drops one name, `flushtree zone` a subtree, `flush` everything: the next query goes out again
- `dig +norec` to a resolver shows cached answers, but VM 2 answers REFUSED for names under its static-stub zone (ARM: such queries "are prohibited"): use the dump

<!--
Excerpt from the rehearsal (step 3.1.9) and plan/m03_notes.md e3 (28 October 2026); TTLs are what was left at the moment of the dump. The NXRRSET for ns1's AAAA is BIND looking for an IPv6 address for the server; the zone has none. The address database also lists the 26 root server addresses BIND tried and failed to reach offline.
-->

---
<!-- _class: dense -->
## Remembering Failures and Servers

- **Failures:** RFC 2308 §7 made caching them optional; RFC 9520 (December 2023): "Resolvers MUST implement a cache for resolution failures", for "at least 1 second" and not "longer than 5 minutes", backing off for persistent failures
- BIND keeps SERVFAIL answers for `servfail-ttl`, default 1 second, at most 30 (ARM); Module 2 saw that second after a reload
- **Servers:** the resolver remembers each authoritative address: round-trip time, EDNS support, whether it answers. BIND keeps it in its address database (the `srtt` above); Unbound's host cache holds "roundtrip timing, lameness and EDNS support information" for 900 s by default
- A dead or unreachable server in your NS set costs time: "the only way the resolvers can determine that these addresses are, in fact, unreachable, is to try them" (RFC 2182 §4), and each resolver learns it for itself
- In the lab: a dead forwarder cost 3067 ms before SERVFAIL (Lab 3.2, Docker bridge); on a real network a timeout is often seconds per try

---
<!-- _class: dense -->
## Staying Useful When Servers Fail

- **Serve-stale** (RFC 8767): answer from expired cache data when the authoritative servers cannot be reached. BIND 9.20 keeps and serves stale data only when you enable it (`stale-cache-enable`, `stale-answer-enable`: default no; `rndc serve-stale on`)
- **Prefetch:** when a query arrives for a record with 2 s or less left, BIND answers it and refreshes the record, for records whose original TTL was at least 9 s (defaults `prefetch 2 9`, ARM)
- **Local copies:** a secondary or a mirror of a zone on the resolver host answers without asking anyone (stealth secondary: RFC 2182 §5.1; root mirror: section 5)
- **Several resolvers per client:** the stub needs more than one, on different hosts
- None of these fixes a broken zone: they buy time for the people fixing it

---
<!-- _class: dense -->
## Clients and Their Resolvers

```text
# /etc/resolv.conf on a client (Module 1 showed one nameserver)
nameserver 192.0.2.10        # resolver 1: VM 2 in this lab
nameserver 192.0.2.11        # resolver 2: another host, another switch, another power feed
options timeout:2 attempts:2 rotate
```

- glibc on Debian 13: at most 3 `nameserver` lines (MAXNS), "queries them in the order listed"; `timeout` 5 s and `attempts` 2 by default; `rotate` spreads load instead of sending everything to the first (resolv.conf(5))
- With the defaults, a dead first resolver costs each lookup about 5 s before the second is tried
- Clients get these addresses from DHCP or IPv6 Router Advertisements (RFC 8106); encrypted resolver discovery (DDR, DNR) is Module 8
- Home routers often hand out their own address and relay queries: section 4's last slide

---
<!-- _class: dense table-compact -->
## A Resolver for a Private TLD

`example.` is not in the real root. VM 2 asked for `www.team01.example` (BIND 9.20.30; online static-stub row: Module 6's tests):

| VM 2 configuration | Offline | With Internet |
|---|---|---|
| Debian's defaults | SERVFAIL: no root server reachable | NXDOMAIN with `ad`: the root proves `example.` does not exist |
| `static-stub` for `example` to the registry, validation on | SERVFAIL: "broken trust chain" | SERVFAIL: "got insecure response; parent indicates it should be secure" |
| the same plus `validate-except { "example"; }` | NOERROR | NOERROR |

- `static-stub`: "a set of name servers to use to resolve all queries for the given zone"; they "must point to authoritative servers" (ARM)
- `validate-except`: for "a top-level domain intended only for local use, so that the lack of a secure delegation ... in the root zone does not cause validation failures" (ARM)
- The ARM warns: "Use of static-stub zones is not recommended"; real internal names belong under a domain you own (Module 5). Module 6 installs the same two lines; Module 7 replaces `validate-except` with a trust anchor

---
<!-- _class: section-divider -->
# 4 · Forwarding

---
<!-- _class: dense -->
## Forwarders

```text
 stub ─RD=1─> VM 2 (forwarder) ─RD=1─> lab resolver 192.0.2.55 ─RD=0─> registry, VM 1 ...
                cache                     cache, does the walk
```

- **Forwarding:** "one server sending a DNS query with the RD bit set to 1 to another server to resolve that query"; it "is different than simply blindly relaying queries" (RFC 9499)
- A **forwarder** is "a nameserver used to resolve queries instead of directly using the authoritative nameserver chain" (RFC 2308 §1, quoted in RFC 9499)
- BIND forwards only "queries for which the server is not authoritative and does not have the answer in its cache" (ARM): VM 2's own zones and cache come first
- Seen from the authoritative side, the forwarder hides its clients: in Lab 3.2 VM 1's query log shows 192.0.2.55 asking, where with the static-stub zone it showed VM 2

---
<!-- _class: dense -->
## forward only, forward first

```text
options {                          // everything not answered locally goes upstream
    forwarders { 192.0.2.55; };    // "a list of IP addresses of DNS resolvers"
    forward only;                  // default: first
};
```

- `first` (the default): "query the forwarders first; if that does not answer the question, the server then looks for the answer itself". `only`: "the server only queries the forwarders" (ARM)
- `only` makes the forwarder a single point of failure: tested with an unused address, SERVFAIL after 3067 ms on every lookup
- `first` hides a failed forwarder, but the fallback needs a path to the root servers: a firewalled site usually has none, so it only adds delay
- Forwarding to two or more resolvers on different hosts is the usual answer
- A zone of `type forward` with no `forwarders` (or an empty list) switches forwarding off for that domain

---
<!-- _class: dense table-compact -->
## Three Ways to Send a Domain Elsewhere

| BIND zone type | Points at | Queries sent | Use it for |
|---|---|---|---|
| `type forward` | **resolvers** (`forwarders`) | RD set: the forwarder resolves | conditional forwarding to an internal resolver |
| `type static-stub` | **authoritative servers** (`server-addresses`) | RD clear: VM 2 iterates | a domain the root does not delegate: the lab's `example.` |
| `type stub` | authoritative servers (`primaries`) | RD clear | as static-stub, then follows the zone's own NS set |

```text
zone "example" { type forward; forward only; forwarders { 192.0.2.55; }; };   // Lab 3.2
zone "example" { type static-stub; server-addresses { 192.0.2.53; }; };       // Lab 3.1, Module 6
```

- Stub and static-stub zones are BIND features, not standard DNS; the ARM recommends proper delegation instead. Unbound's equivalents are `forward-zone` and `stub-zone` (Module 4)

---
<!-- _class: dense -->
## A Forwarder Must Be a Resolver

```text
zone "example" { type forward; forward only; forwarders { 192.0.2.53; }; };   // the registry
$ dig @127.0.0.1 www.team01.example
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL
$ sudo journalctl -u named -n 3
... DNS format error from 192.0.2.53#53 resolving www.team01.example/A for 127.0.0.1#42613: non-improving referral
```

- The registry is authoritative-only: it answers RD-set queries with a referral. A forwarder's answer must be an answer, so BIND treats the referral as an error and gives SERVFAIL (tested, BIND 9.20.30)
- Rule: `forwarders` = resolvers; `server-addresses` and `primaries` = authoritative servers
- Check the target first: `dig @target name` shows `ra` for a resolver; `dig @target zone SOA +norec` shows `aa` for an authoritative server

---
<!-- _class: dense table-compact -->
## Should You Forward?

| Forwarding gives you | It costs you |
|---|---|
| one shared cache for many small resolvers (sites, branches) | the upstream's failures and delays become yours |
| a path out for resolvers with no direct Internet access | the upstream sees every name your users look up (Module 8) |
| one place for policy: filtering, logging (Module 6) | the upstream's view: filtered, rewritten or split answers |
| internal domains resolved by internal servers (conditional) | the upstream must validate, or you must (Module 7) |

- Typical enterprise: site resolvers forward to two central resolvers; internal domains go to internal servers; the central resolvers resolve from the root and validate
- Typical ISP: no forwarding; recursive resolvers close to customers
- Keep validation on the resolver that answers your clients: `dnssec-validation auto` on a forwarder checks what the upstream sends

---
<!-- _class: dense -->
## DNS Proxies at the Edge

- A home or office router often gives its own address to clients and relays their queries to the ISP's resolvers: a **DNS proxy** (RFC 5625, BCP 152)
- RFC 5625: its role "should therefore be no more and no less than to receive DNS requests from clients on the LAN side, forward those verbatim ... and ensure that the whole response is returned verbatim"; it is "RECOMMENDED that proxies should be as transparent as possible"
- RFC 5625 §4 lists what a proxy must pass on unchanged: unknown flags and record types, TCP, EDNS0 and large answers, TSIG. A proxy that drops any of them breaks large answers or validation for every client behind it
- Troubleshooting a client: ask the proxy, then the resolver behind it, then the authoritative server, with the same `dig` (Module 1's method)
- RFC 9499 does not define "DNS proxy"; the term covers anything from a relay to a full forwarder with a cache

---
<!-- _class: section-divider -->
# 5 · Specialised Roles

---
<!-- _class: dense table-compact -->
## A Map of Specialised Roles

| Role | What it adds | Where in the course |
|---|---|---|
| **DNS64** resolver | AAAA records made from A records, for IPv6-only clients behind NAT64 | next slide |
| **Mirror of the root** | a validated local copy of the root zone on the resolver | the slide after |
| **Policy-implementing resolver** | changes answers by policy: malware blocking, walled gardens (RFC 9499) | RPZ, Module 6 |
| **Validating resolver** | checks DNSSEC signatures, answers `ad` or SERVFAIL | Module 7 |
| **Encrypted resolver** | DNS over TLS, HTTPS or QUIC to clients | Module 8 |
| **Signer** | signs zones, often a hidden primary | Module 7 |
| **Anycast servers, load balancers** | one address at many sites; answers that depend on health or location | Module 5 |
| **Registry and TLD servers** | the TLD zone built from a registration database | Modules 9-10 |
| **Root servers** | the root zone, 13 identities, many instances | Module 1 |

---
<!-- _class: dense -->
## DNS64

```text
options { dns64 64:ff9b::/96 { clients { any; }; }; };       // on a resolver
$ dig @192.0.2.10 ftp.team01.example AAAA +noall +answer        # ftp has only an A record
ftp.team01.example.   60   IN   AAAA   64:ff9b::c000:252          # 192.0.2.82 inside the prefix
$ dig @192.0.2.10 www.team01.example AAAA +noall +answer        # a real AAAA is left alone
www.team01.example.   60   IN   AAAA   2001:db8:1::80
```

- DNS64 synthesises "AAAA resource records (RRs) from A RRs" (RFC 6147 §1), so that an IPv6-only client reaches an IPv4-only server through a NAT64 translator
- `64:ff9b::/96` is the Well-Known Prefix (RFC 6052 §2.1); operators may use their own prefix. BIND also creates `ipv4only.arpa`, which clients query to discover the prefix (RFC 7050, RFC 8880)
- "DNSSEC is designed to detect changes to DNS answers, and DNS64 may alter answers" (RFC 6147 §3): a validating client cannot validate a synthesised record
- Run it only on resolvers that serve IPv6-only networks with NAT64. Tested with BIND 9.20.30 configured as VM 2 (28 October 2026); not part of the lab

---
<!-- _class: dense -->
## A Local Copy of the Root

```text
zone "." { type mirror; };          // BIND 9.20 has the root's transfer sources built in
zone ./IN: transferred serial 2026102700
transfer of './IN' from 2801:1b8:10::b#53: Transfer completed: 87 messages, 24915 records, 1425127 bytes
zone ./IN: mirror zone is now in use
$ dig @127.0.0.1 . SOA
;; flags: qr rd ra ad; ...          ad, not aa: validated data, served by the resolver
```

- RFC 8806 (Informational, June 2020; obsoletes RFC 7706): run a root service "on the same host as the recursive server"; it "MUST NOT answer queries from any other resolver"
- Gains: answers for the root, including the many queries for TLDs that do not exist, without leaving the host; root traffic is not visible on the network
- BIND's `mirror` zone validates the whole copy with DNSSEC before use; if the copy is unusable, BIND falls back to normal recursion (ARM)
- Needs Internet access to the transfer sources: tested online on 28 October 2026 (record count as of that date), not in the offline lab

---
<!-- _class: dense -->
## Policy, Views and Split DNS

- **Policy-implementing resolver:** "changes some of the answers that it returns based on policy criteria"; "a stub resolver has no idea whether upstream resolvers implement such policy" (RFC 9499). Module 6 builds one with RPZ and labels its answers with Extended DNS Errors
- **Split DNS:** servers "provide partly or completely different answers in those domains depending on the source of the query" (RFC 9499)
- **View:** "a configuration for a DNS server that allows it to provide different responses depending on attributes of the query", usually the source address; "not a standardized part of the DNS" (RFC 9499)
- Both are design decisions with costs: the same name means two things, caches and logs must be read per view, and DNSSEC must sign each version. Module 5 builds views; here, know the role exists
- A static-stub or forward zone for an internal domain (section 4) is the resolver half of a split: the internal servers answer, the Internet never sees the name

---
<!-- _class: section-divider -->
# 6 · Choosing and Placing Servers

---
<!-- _class: dense table-compact -->
## What Each Organisation Needs

| Question | Small office | Enterprise | ISP |
|---|---|---|---|
| Public zones: who serves them? | a provider, with two or more NS | own hidden primary plus outside secondaries (RFC 2182: three, one far away) | own servers at several sites, plus an outside secondary |
| Internal names? | none, or the router's | internal zones on internal servers, never on the public ones | management zones; customer reverse zones |
| Resolvers for users? | the ISP's or a public one | two per site, or central pairs; forward to them | per region, close to customers, often anycast |
| Validation, filtering? | upstream's | on the central resolvers (Modules 6-7) | validation; filtering only as the law or customers require |
| Who changes what? | the provider's web form | change procedure, version control (Module 2) | automation and APIs (Module 4) |

- Write down the failure you are designing for: a server, a site, a provider, a link to the outside

---
<!-- _class: dense -->
## Where to Put Servers

```text
 authoritative (listed):   site A ─── ns1        provider X ─── ns2        provider Y (other TLD) ─── ns3
                           hidden primary at site A ── transfers ──> ns1, ns2, ns3

 resolvers:   users at site A ──> res-a1, res-a2 ──┐
              users at site B ──> res-b1, res-b2 ──┴── (forward, or resolve from the root) ──> Internet
```

- **Authoritative:** spread across networks, sites and providers (RFC 2182 §3.1); names under more than one TLD; IPv4 and IPv6 on each; secondaries reachable from where your users and customers are
- **Resolvers:** close to the users they serve; at least two per site or per client population, on different hosts and power; reachable only by those users
- **Do not** put all listed servers behind one firewall, one upstream or one hosting provider; do not list addresses that much of the network cannot reach (RFC 2182 §4)
- Anycast puts one address at many sites, for both roles (RFC 4786, BCP 126): Module 5

---
<!-- _class: dense -->
## Capacity: Measure, Then Plan

- **Authoritative load** grows with your zone's popularity and with attacks, not with your staff count: plan for floods (Module 6) and use anycast or a provider for headroom (Module 5)
- **Resolver load** grows with users and with how often caches miss; memory limits the hit rate: BIND's cache defaults to 90% of physical memory (one view), so size the host and set `max-cache-size`
- **Measure before buying:** `dnsperf` replays a query file at a fixed rate; `resperf` raises the rate until the resolver falls behind (Debian package `dnsperf` 2.14.0). Module 6 uses `dnsperf` at 50 queries per second on your own servers only
- **Watch in production:** BIND's statistics (`rndc stats`, the statistics channel), query and response rates, SERVFAIL rate, cache hit rate, `recursive-clients` in use (default limit 1000): Module 11

---
<!-- _class: dense -->
## Design Exercise

A company with two offices (300 and 40 staff), a public website and mail, an internal `corp` domain under its own name, and an ISP link at each office.

1. How many listed authoritative servers for the public zone, run by whom, and where? Where is the primary?
2. Where do the resolvers for staff run, how many, and do they forward?
3. How do staff resolve internal names, and how do you keep those names off the public servers?
4. What happens to each office when its ISP link fails? When the head office loses power?
5. Which servers validate DNSSEC, and which ones log queries?

<!--
One reasonable answer: public zone on three listed servers: a secondary service from two providers (different networks, names under different TLDs) plus none in-house, with a hidden primary at head office that only the providers can transfer from (RFC 2182 §3.1, §5). Resolvers: two at head office, one or two at the branch forwarding to head office with forward first (or resolving directly), all validating; internal names in corp.<company domain> on internal servers, reached by static-stub or forward zones on the resolvers, or as stealth secondaries on the site resolvers (RFC 2182 §5.1) so lookups survive a link failure. A branch link failure: local names still resolve from a stealth secondary; Internet names fail anyway. A head-office power failure: the public zone stays up (it is served by the providers), the hidden primary only stops changes until EXPIRE matters. Accept other answers that name the failure each choice covers.
-->

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

```text
                        classroom LAN (lab sheet addresses; 192.0.2.0/24 on the slides)
  ─────┬───────────────────────┬───────────────────────┬──────────────────────┬──────────
   VM 1 192.0.2.30          VM 2 192.0.2.10          registry 192.0.2.53     lab resolver 192.0.2.55
   primary for              resolver (3.1-3.2),      example.: teamNN        Module 1's resolver:
   teamNN.example           secondary (3.3-3.4)      delegated to VM 1       Lab 3.2's forwarder
```

- **VM 2 gets BIND running today:** the image has `bind9`, `bind9-utils` and `bind9-dnsutils` with `named` stopped. `sudo rndc-confgen -a -u bind` (this VM's own control key), then `sudo systemctl enable --now named`. Otherwise `sudo apt install bind9 bind9-utils bind9-dnsutils`
- **Kit** `labs/module03/`: `vm2/named.conf.options`, `named.conf.local`, `named.conf.forward`, `named.conf.secondary`; `vm1/zone-transfer.snippet`
- **Logs:** `sudo journalctl -u named -f` in a second SSH session on each VM; `sudo rndc querylog on` on VM 1 in Lab 3.1
- **After every edit:** `named-checkconf`, then `sudo rndc reconfig` (configuration) or `sudo rndc reload zone` (zone data)
- **Offline:** every step uses lab servers. Replace `NN` and the addresses with your lab sheet's

---
<!-- _class: dense -->
## Lab 3.1: A Resolver on VM 2 (20 min)

1. On VM 2: start BIND (Lab Environment); `named -v`; `cat /etc/bind/named.conf.options`: only `directory`
2. `dig @127.0.0.1 www.teamNN.example`: SERVFAIL offline, NXDOMAIN with Internet. What does VM 2 know?
3. `sudo cp vm2/named.conf.options vm2/named.conf.local /etc/bind/`; `named-checkconf`; `sudo rndc reconfig`
4. On VM 1: `sudo rndc querylog on`, and watch its journal. On VM 2: `dig @127.0.0.1 www.teamNN.example` twice, 5 s apart: flags, TTL, and who asked VM 1 (`-` after the type: no RD)
5. From VM 1: `dig @192.0.2.10 mail.teamNN.example`. On VM 2: `dig @127.0.0.1 www.teamNN.example +norec`: why REFUSED?
6. `dig @127.0.0.1 nosuch.teamNN.example`; `sudo rndc dumpdb -cache`; `grep -A1 -E 'teamNN|Address database' /var/cache/bind/named_dump.db`; then `sudo rndc flushname www.teamNN.example`, ask again and watch VM 1's log

> **Checkpoint:** answers with `ra` and no `aa`; VM 1's log shows VM 2 asking without RD, once per TTL; the dump shows the answer, the NXDOMAIN and VM 1's address with its round-trip time

<!--
Rehearsed 28 October 2026 (labs/module03/test/rehearse.sh, 3.1.1-3.1.10b): step 2 SERVFAIL "flags: qr rd ra" offline; step 4 "flags: qr rd ra", 192.0.2.80, TTL 60 then about 55; VM 1 journal: "client @0x... 192.0.2.10#51259 (www.team01.example): query: www.team01.example IN A -E(0)DK (192.0.2.30)" and an AAAA query for ns1 (BIND looks up the server's IPv6 address); no new line for the cached answer. Step 5: NOERROR from VM 1's side; REFUSED for +norec (ARM: non-recursive queries to a static-stub zone are prohibited). Step 6: "nosuch.teamNN.example. 60 \-ANY ;-$NXDOMAIN" with the SOA, "; ns1.teamNN.example. [v4 TTL 60] ..." and "192.0.2.30 [srtt ...]"; after flushname VM 1 logs a new query.
With Internet, step 2 is NXDOMAIN with ad (tested in Docker online): the real root proves example. does not exist. rndc needs sudo (the key is mode 600); the dump itself is mode 644, owner bind, so grep needs none (checked in the harness).
-->

---
<!-- _class: dense -->
## Lab 3.2: Forwarding (20 min)

Each step: edit `/etc/bind/named.conf.local` on VM 2, `named-checkconf`, `sudo rndc reconfig`, `sudo rndc flush`.

1. Replace the static-stub zone with (a) from `vm2/named.conf.forward`: forward `example` to the lab resolver
2. `dig @127.0.0.1 ftp.teamNN.example`: who asked VM 1 this time? Then `dig @192.0.2.55 ftp.teamNN.example +norec`
3. Change the forwarder to the registry, 192.0.2.53 (b). Ask again; `sudo journalctl -u named -n 5`
4. Change it to the unused address on your lab sheet (c; 192.0.2.250 on the slides). Ask again and note the query time. What would `forward first` change, offline?
5. Put the static-stub zone back: `sudo cp vm2/named.conf.local /etc/bind/`; reconfigure and flush; ask once more and read VM 1's log

> **Checkpoint:** you can say who queried VM 1 in steps 2 and 5; why (b) fails ("non-improving referral") and (c) fails; and VM 2 ends with the kit's static-stub zone

**Discussion:** your company's resolvers forward everything to the ISP's resolvers. What do you gain, and what do you lose?

<!--
Rehearsed 28 October 2026 (3.2.1-3.2.7): step 2 NOERROR 192.0.2.82; VM 1's journal shows "192.0.2.55#39065 (ftp.teamNN.example): query: ftp.teamNN.example IN A -E(0)DCV": the lab resolver asked, without RD, and VM 2 did not appear. The lab resolver's +norec answer comes from its cache. Step 3: SERVFAIL, "DNS format error from 192.0.2.53#53 resolving www.team01.example/A for 127.0.0.1#42613: non-improving referral". Step 4: SERVFAIL after about 3 s (3067 and 3075 ms in two runs) on the Docker test bridge (no host at that address); on a real LAN the delay depends on the network. forward first would fall back to iterating from the real root: offline that fails too, with Internet it gets the root's NXDOMAIN for example. Ask a name that is not cached at the lab resolver in step 2 (ftp is usually fresh; any team's name works).
-->

---
<!-- _class: dense -->
## Lab 3.3: A Secondary on VM 2 (30 min)

1. On VM 2: `dig @192.0.2.30 teamNN.example AXFR`. Why "Transfer failed."?
2. Add `vm2/named.conf.secondary` (with your `NN`) to VM 2's `named.conf.local`; check; reconfigure. Read VM 2's journal, then VM 1's: what do they say?
3. On VM 1: add the two lines of `vm1/zone-transfer.snippet` inside your zone statement; check; reconfigure. On VM 2: `sudo rndc retransfer teamNN.example`; journal; `sudo rndc zonestatus teamNN.example`
4. `dig @192.0.2.10 teamNN.example SOA +norec` and the same at 192.0.2.30: flags and serial
5. On VM 1: add `app IN A 192.0.2.84`, raise the serial, `named-checkzone`, `sudo rndc reload teamNN.example`. In both journals: the NOTIFY, and IXFR or AXFR?
6. On VM 2: `dig @127.0.0.1 app.teamNN.example`: flags? Did VM 1's query log see it?

> **Checkpoint:** VM 1 logs `sending notify to` VM 2 and the transfer; VM 2 logs `transferred serial` with your new serial; both answer the SOA with `aa` and the same serial (Practical Assessment 2A, task 1)

<!--
Rehearsed 28 October 2026 (3.3.1-3.3.11b): step 1 "; Transfer failed." (BIND 9.20 allow-transfer default none). Step 2: VM 2 "transfer of 'teamNN.example/IN' from 192.0.2.30#53: failed while receiving responses: REFUSED"; VM 1 "client @0x... 192.0.2.10#46514 (teamNN.example): zone transfer 'teamNN.example/AXFR/IN' denied"; dig to VM 2 for the zone gives SERVFAIL until it loads. Step 3: "transferred serial 2026102701"; zonestatus type: secondary, expires: 14 days ahead. Step 5: VM 1 "sending notify to 192.0.2.10#53", "IXFR version not in journal, falling back to AXFR", "AXFR-style IXFR ended"; VM 2 "notify from 192.0.2.30#...: serial ...", "transferred serial ...". Step 6: flags qr aa rd ra: VM 2's resolver answers from its own copy and VM 1 sees no query. Common mistakes: also-notify missing (VM 2 updates only at REFRESH, up to an hour), NN not replaced, the snippet outside the zone braces (named-checkconf: unknown option).
-->

---
<!-- _class: dense -->
## Lab 3.4: Failure and Clean-up (20 min)

1. On VM 1: `sudo systemctl stop named`. On VM 2: `dig @192.0.2.10 www.teamNN.example +norec`
2. `dig @192.0.2.55 lab34.teamNN.example`; `dig @192.0.2.53 teamNN.example NS +norec`. Why does the lab resolver fail while VM 2 answers?
3. On VM 2: `sudo rndc refresh teamNN.example`; journal; `sudo rndc zonestatus teamNN.example`. When would VM 2 stop answering?
4. On VM 1: `sudo systemctl start named`. On VM 2: `sudo rndc refresh teamNN.example`; compare the serials
5. Clean up. VM 2: delete the secondary zone from `named.conf.local`; check; reconfigure; `sudo rm -f /var/cache/bind/db.teamNN.example /var/cache/bind/db.teamNN.example.jnl`. VM 1: delete the two snippet lines; check; reconfigure
6. On VM 2: `dig @127.0.0.1 www.teamNN.example` (no `aa`) and `dig @192.0.2.30 teamNN.example AXFR` (refused)

> **Checkpoint:** you can say which server answered in steps 1-2 and why; VM 2 is a resolver only and VM 1 allows no transfers: the state Modules 4-6 start from

**Discussion:** what change would let every resolver use VM 2 while VM 1 is down, and who must make it?

<!--
Rehearsed 28 October 2026 (3.4.1-3.4.10): step 1 "flags: qr aa ra", 192.0.2.80; step 2 SERVFAIL from the lab resolver, and the registry's referral lists only ns1.teamNN.example. Step 3 "refresh: failure trying primary 192.0.2.30#53 (source 0.0.0.0#0): connection refused"; expires: two weeks after the last successful refresh (SOA EXPIRE 1209600). Step 4: same serial on both. Step 6: "flags: qr rd ra" (VM 2 resolves through the static-stub again) and "; Transfer failed.".
Discussion answer: add ns2.teamNN.example (VM 2) to the zone's NS set and an A record for it, and ask the registry to add the same NS and glue (the instructor; teams.conf holds one address per team, so the lab does not do this). Both sides must agree (Module 1, Lab 1.3). VM 2 would then answer the whole Internet for the zone while resolving only for your subnet: two roles on one host, which production avoids.
Why clean up: Module 6 Lab 6.4 adds TSIG-only allow-transfer and also-notify lines to the same zone statement (two allow-transfer lines are a configuration error), and Module 7 needs VM 2 to resolve and validate teamNN.example, not serve it.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 1034, 1035 (STD 13); RFC 1123 §6.1.3.1; RFC 1912; RFC 9499 (BCP 219)
- RFC 2182 (BCP 16) secondary servers; RFC 1996 NOTIFY
- RFC 1995 IXFR, 5936 AXFR; RFC 2136; RFC 9103 XoT
- RFC 9432 catalog zones; RFC 8901 multi-signer
- RFC 2308; RFC 9520 failure caching; RFC 8767 serve-stale
- RFC 5358 (BCP 140) open resolvers; RFC 5625 (BCP 152) DNS proxies
- RFC 6147 DNS64, RFC 6052, RFC 7050, RFC 8880; RFC 8106
- RFC 8806 local root (obsoletes 7706); RFC 4786 (BCP 126) anycast
- ISC BIND 9.20 ARM: zone types, forwarding, `allow-recursion`, `ixfr-from-differences`, `dns64`, `mirror`, catalog zones; `rndc(8)`
- Debian 13 `bind9` 1:9.20.30; `unbound.conf(5)` 1.26.2; `resolv.conf(5)`

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>named-checkconf
sudo rndc reconfig
sudo rndc retransfer zone
sudo rndc refresh zone
sudo rndc zonestatus zone
sudo rndc querylog on
sudo rndc dumpdb -cache
sudo rndc flushname name
dig @server zone SOA +norec
dig @server zone AXFR
sudo journalctl -u named -n 20
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. A server answers your zone with `flags: qr aa ra` and `google.com` with `qr rd ra`. Which roles does it play, and what would you change?
2. Your new secondary logs `failed while receiving responses: REFUSED`. Where do you look next, and what do you change?
3. You raise the serial and reload the primary; a secondary picks up the change only an hour later. Give two causes.
4. The primary has been down for 15 days and the SOA EXPIRE is 1209600. What do clients of the secondary see, and why is that intended?
5. `zone "corp.example" { type forward; forwarders { 10.1.1.1; }; };` gives SERVFAIL and the log says `non-improving referral`. What is 10.1.1.1, and how do you fix the zone?
6. Why does RFC 2182 recommend three listed servers, one well removed, and why does a stealth secondary not count as one of them?

<!--
Answers:
1. Authoritative for your zone (aa) and a recursive resolver for others (ra): both roles on one server, like VM 1 with Debian's defaults. Separate them, or at least restrict recursion to your own clients (allow-recursion; Module 6 sets recursion no on the authoritative server; RFC 5358).
2. The primary refused the transfer: its log shows "zone transfer '<zone>/AXFR/IN' denied". Add the secondary's address (or a TSIG key, Module 6) to allow-transfer on the primary (BIND 9.20 default none), rndc reconfig, then rndc retransfer on the secondary.
3. The secondary got no NOTIFY: it is not in the NS set and the primary has no also-notify for it (or NOTIFY is blocked, or the secondary does not accept it: not a primary or in allow-notify), so it waited for REFRESH (3600 s in the lab zone). Or the transfer failed at first and it retried after RETRY. (A serial that was not raised would not arrive at all.)
4. SERVFAIL: after EXPIRE without a successful refresh the zone "is no longer authoritative" (RFC 1035 §3.3.13), and BIND logs "expired". Intended: a secondary that cannot reach its primary for that long must not keep serving data that may be wrong. Fix the primary, or point primaries at another source, before EXPIRE.
5. An authoritative-only server: it answered the forwarded (RD set) query with a referral, which BIND rejects from a forwarder. Either forward to a resolver that can resolve corp.example, or use type static-stub with server-addresses { 10.1.1.1; } (or a proper delegation).
6. Two listed servers are often effectively one, because "Various problems can cause a server to be unavailable for extended periods"; three with one far away survive a site, link or provider failure (§3.1, §5). A stealth server is not in the NS set, so resolvers outside never ask it: it answers only those configured to use it (§5.1), as Lab 3.4 showed.
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
