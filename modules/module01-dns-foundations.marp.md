---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 1: Introduction to DNS - Foundations and Concepts

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: dense -->
## Welcome

- **Instructor:** Terry Sweetser, IEISI.ORG
- **You:** your name and your organisation; write the one question you want answered this week on the sheet going round
- **This room:** [venue, Wi-Fi, breaks, facilities: the instructor fills these in]
- **Your materials:** these slides, each module's lab kit (today `labs/module01/`), and your lab sheet: your team number `NN`, your VM addresses and the lab zone names
- **How we work:** questions at any time; the labs take half of every module; outside the lab network you only query public DNS servers, at the pace of a person typing

<!--
Before class: fill in the venue line. The instructor's background is not in the course plans; introduce yourself in your own words.
Introductions: name and organisation only, about 15 seconds each: 5 minutes for 20 participants; keep the rest of the opening to 7 minutes. "What Changed Recently" is a 30-second preview here: the course returns to each row (RFC 9499 terms, TCP, glue, b.root, PTI) in sections 4-7.
Collect each participant's question on a sheet and come back to it at the course conclusion (Day 6).
-->

---
<!-- _class: dense table-compact -->
## The Course

| Day | Session 1-2 | Session 3-4 |
|---|---|---|
| 1 | **Module 1** Introduction to DNS | **Module 2** Zones, records and data |
| 2 | **Module 3** Server types | **Module 4** Software platforms |
| 3 | **Module 5** Advanced operations | **Module 6** Security fundamentals |
| 4 | **Module 7** DNSSEC | **Module 8** Privacy and encryption |
| 5 | **Module 9** Registry operations and EPP | **Module 10** CoCCA registry systems |
| 6 | **Module 11** Monitoring and incident response | **Module 12** Emerging technologies; course conclusion |
| 7 (morning) | Final project in teams of 3-4: design and build | Team presentations (15 minutes each) |

- 12 modules, each **90 minutes of theory and 90 minutes of lab**; 39 contact hours; at most 20 participants
- Shorter programmes use the same modules: Days 1-2 (Modules 1-4), Days 3-4 (Modules 5-8), Days 3-6 and Day 7 (Modules 5-12)

---
<!-- _class: dense -->
## How Each Day Runs

<div class="columns">
<div>

| Session | Time | |
|---|---|---|
| 1 | 09:00-10:30 | Theory, module A |
| | 10:30-11:00 | Break |
| 2 | 11:00-12:30 | Lab, module A |
| | 12:30-14:00 | Lunch |
| 3 | 14:00-15:30 | Theory, module B |
| | 15:30-16:00 | Break |
| 4 | 16:00-17:30 | Lab, module B |

</div>
<div>

**Assessment**
- **Practical assessments** are your lab work, graded against the day's tasks: no extra exam time
- **Knowledge checks** take the last 15-30 minutes of Session 3; Day 3 adds a mid-course assessment, Day 5 a case study
- **Day 7:** the final project, in teams, presented to the group

</div>
</div>

---
<!-- _class: dense -->
## Your Lab for the Week

```text
 laptop ──SSH──> VM 1  teamNN authoritative server  192.0.2.30   today: client tools only
         ──SSH──> VM 2  teamNN resolver              192.0.2.10   unused until Module 3

 classroom LAN:  instructor servers   192.0.2.53 registry for the lab TLD example.
                                      192.0.2.52 / .54 / .55  Module 1 lab root, child, resolver
```

- **Two Debian 13 VMs each**, kept all week; `NN` is your team number. Addresses on the slides are examples: use your lab sheet
- **What you build when:** zones (Module 2), servers (Modules 3-4), hardening (6), signing and validation (7), encrypted transports (8), registration over EPP (9)
- **The lab TLD is `example.`**: the instructor's "registry" delegates `teamNN.example` to your VM 1. It is reserved for examples (RFC 6761), so it never collides with a real name

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Explain** why the DNS replaced the HOSTS.TXT file, and how hierarchy, delegation and caching follow from that
- **Describe** the namespace: labels, fully qualified names, the root, TLD types, domains, zones and delegation
- **Distinguish** authoritative servers, recursive resolvers and stub resolvers, and compare the DNS with other ways hosts look up names
- **Trace** a lookup from the root to an authoritative answer, by hand with `dig +norec` and with `dig +trace`
- **Read** a DNS message: header flags, response codes, sections, UDP and TCP, IPv4 and IPv6
- **Name** who runs each part: ICANN, IANA and PTI, root server operators, registries, registrars, RIRs
- **Diagnose** a broken delegation with `dig`, `host` and `nslookup`, and say who has to fix it

---
<!-- _class: dense table-compact -->
## What Changed Recently

Older introductions to the DNS are out of date in five places:

| Then | Now |
|---|---|
| Terms from RFC 8499 (2019) or older RFCs | RFC 9499 (BCP 219, March 2024): "primary" and "secondary" servers; "lame delegation" is to be avoided as unclear |
| TCP "only for zone transfers" | All DNS resolvers and servers MUST support UDP and TCP (RFC 7766; RFC 9210, BCP 235, 2022) |
| Referrals carry glue if it fits | In-domain glue MUST be included, or TC set (RFC 9471, September 2023) |
| b.root-servers.net on its old addresses | Renumbered on 27 November 2023 to 170.247.170.2 and 2801:1b8:10::b (USC/ISI; IANA root hints) |
| IANA functions under a US government contract | The contract expired on 1 October 2016; Public Technical Identifiers (PTI), an ICANN affiliate, performs them |

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. Welcome and the course (12m)
2. From HOSTS.TXT to the DNS (8m)
3. The namespace (15m)
4. Records, servers and caching (10m)
5. Resolution (15m)
6. The DNS message (10m)
7. Who runs the DNS (10m)
8. Tools and a debugging method (10m)

## Agenda (90 min Lab)

1. Lab 1.1 Walk the hierarchy (30m)
2. Lab 1.2 Read the response (30m)
3. Lab 1.3 Debug a delegation (30m)

---
<!-- _class: section-divider -->
# 1 · From HOSTS.TXT to the DNS

---
<!-- _class: dense -->
## Names Before the DNS

- From 1974 the Network Information Center (NIC) kept the host names of the ARPANET on line (RFC 608); by 1985 the "DoD Host Table" was the file `HOSTS.TXT` on the host SRI-NIC, fetched by FTP (RFC 952)
- Every host copied the whole file. RFC 1034 §2.1 lists what went wrong:
  - the bandwidth to distribute it grew with "the square of the number of hosts"
  - organisations ran their own networks but "had to wait for the NIC to change HOSTS.TXT"
  - applications needed a general-purpose name service, not just host addresses
- Names were flat and short: up to 24 characters of letters, digits and minus (RFC 952)

The same model survives as `/etc/hosts` on every Debian system: fine for one machine, impossible for the Internet.

---
<!-- _class: dense -->
## The Design: A Distributed Database

- **1983:** Paul Mockapetris publishes RFC 882 and RFC 883: "a distributed database and generalized resources" (RFC 1034 §2.1)
- **1987:** RFC 1034 (concepts) and RFC 1035 (implementation) replace them; together they are **STD 13**, still the base standard, updated by many later RFCs
- Design goals (RFC 1034 §2.2):
  - "a consistent name space", with no addresses or routes inside the names
  - maintained "in a distributed manner, with local caching"
  - "the source of the data should control the tradeoff" between cost, update speed and cache accuracy
- The result: a **tree of names**, each part run by whoever owns it (**delegation**), and copies held for a set time (**caching**, controlled by the **TTL**)

---
<!-- _class: dense table-compact -->
## A Short Timeline

| Year | Event | Source |
|---|---|---|
| 1974, 1985 | Host names on line at the NIC; `HOSTS.TXT` specification | RFC 608; RFC 952 |
| 1983 | Domain names: concepts and implementation | RFC 882, RFC 883 |
| 1984 | First TLDs: GOV, EDU, COM, MIL, ORG, ARPA (temporary) and countries | RFC 920 |
| 1987 | The DNS standard as we use it (STD 13) | RFC 1034, RFC 1035 |
| 1994 | TLD structure and delegation; two-letter country codes from ISO 3166 | RFC 1591 |
| 1995, 2003 | IPv6 addresses in the DNS: AAAA | RFC 1886; RFC 3596 |
| 1998 | ICANN founded | icann.org |
| 2010 | Root zone signed with DNSSEC, 15 July 2010 | IANA, KSK-2010 record |
| 2016 | IANA stewardship transition, 1 October 2016 | ICANN announcement |
| 2024 | Current DNS terminology | RFC 9499 |

---
<!-- _class: dense -->
## Other Ways Hosts Find Names

| System | Scope | How it works |
|---|---|---|
| `/etc/hosts` | one machine | a local file, read before the DNS on Debian 13 (`hosts: files dns`) |
| Multicast DNS (`.local`) | one network link | hosts answer for their own names by multicast (RFC 6762) |
| LLMNR | one network link | similar link-local lookups (RFC 4795, Informational) |
| **The DNS** | the Internet | a delegated tree with caching; the only global one |

- An application asks the operating system, which follows `/etc/nsswitch.conf`; the DNS is one of its sources
- `dig`, `host` and `nslookup` ask the DNS only: a name in `/etc/hosts` is invisible to them (tested on Debian 13), while `getent hosts name` sees it
- When an application and `dig` disagree, check the other sources first

---
<!-- _class: section-divider -->
# 2 · The Namespace

---
<!-- _class: dense -->
## A Tree of Labels

```text
                                   .  (the root)
          ┌────────────┬───────────┼────────────┬──────────────┐
         com          org          nz          arpa         example    ← top-level domains
          │            │           │            │              │        (example. exists only in the lab)
       example        ietf        govt      in-addr          good      ← second level
          │                                     │              │
         www                                   202            www      ← www.good.example.
```

- Each node has a **label** of up to 63 octets; a whole name is at most 255 octets (RFC 1035 §2.3.4)
- A **domain name** is the list of labels from a node up to the root: `www.good.example.` (RFC 9499)
- The root's label is empty; the trailing dot stands for it
- Names compare without regard to case: `WWW.Good.EXAMPLE` is the same name (RFC 4343)
- Whoever controls a node decides what exists below it: that is delegation

---
<!-- _class: dense -->
## Fully Qualified Names

- A **fully qualified domain name** (FQDN) ends at the root. In presentation format the dot is written: `www.good.example.` (RFC 9499)
- Applications usually leave the dot off (the "common display format"); DNS tools and zone files keep it
- A name without the final dot can be **relative**. The stub resolver may add the `search` domains from `/etc/resolv.conf`:

```text
search team01.example        # in /etc/resolv.conf
host www                     # tries www.team01.example.
dig www                      # asks for www. only: dig ignores the search list unless +search
```

- In a zone file (Module 2), a name without the final dot is relative to the zone: `www.example.com` written in `good.example` means `www.example.com.good.example.`
- Host names were limited to letters, digits and hyphen (RFC 952, RFC 1123 §2.1); the DNS itself accepts any octets in a label (RFC 2181 §11)

---
<!-- _class: dense table-compact -->
## Top-Level Domains

| Type (IANA root zone database) | Active, 22 October 2026 | Examples |
|---|---|---|
| Generic (gTLD) | 1,127, of which 90 IDN | `com`, `org`, `net`, `info` |
| Country code (ccTLD) | 309, of which 61 IDN | `nz`, `fj`, `jp`; `рф` (`xn--p1ai`), `中国` (`xn--fiqs8s`) |
| Special use | 1 | `arpa`: infrastructure, run by IANA under IAB guidance (RFC 3172) |
| **Total in the root zone** | **1,437** | IANA TLD list, version 2026102100 |

- Country codes follow ISO 3166-1; "The IANA is not in the business of deciding what is and what is not a country" (RFC 1591)
- RFC 1591 (1994): "It is extremely unlikely that any other TLDs will be created". There were then seven generic TLDs
- To the DNS a TLD is an ordinary zone; the split into gTLD and ccTLD "is a matter of policy" (RFC 9499): different contracts, rules and registries (Module 9)

---
<!-- _class: dense -->
## Internationalised Names

- On the wire, the DNS carries labels as octets; applications use **IDNA2008** (RFC 5890, 5891) for names in other scripts
- A **U-label** is what users see (`рф`); the **A-label** is what the DNS stores: `xn--` followed by its Punycode form (RFC 3492): `xn--p1ai`
- The root zone holds the A-label; so does every zone below it

```text
$ dig рф. NS +short          # dig 9.20 (Debian 13) converts the name for you
f.dns.ripn.net.
...
;; QUESTION SECTION:
;xn--p1ai.        IN  NS     # what was actually sent
```

- 151 of the 1,437 TLDs are IDNs (IANA, 22 October 2026)
- What you type, what is sent and what is displayed can differ: compare the QUESTION SECTION when debugging

---
<!-- _class: dense table-compact -->
## Names Reserved for Special Use

| Name | Reserved for | Source |
|---|---|---|
| `example.`, `example.com`, `example.net`, `example.org` | documentation and examples | RFC 2606, RFC 6761 |
| `test.` | testing | RFC 6761 |
| `invalid.` | names that must never resolve | RFC 6761 |
| `localhost.` | the local host (127.0.0.1, ::1) | RFC 6761 |
| `local.` | multicast DNS on the local link | RFC 6762 |
| `home.arpa.` | home networks | RFC 8375 |
| `alt.` | name systems other than the DNS | RFC 9476 |

- The lab uses `example.` as its TLD and `.test` for its root server's name: neither exists in the real root (`dig -4 @a.root-servers.net example. NS +norec` gives NXDOMAIN)
- Lab addresses come from the documentation ranges: 192.0.2.0/24, 198.51.100.0/24 (RFC 5737) and 2001:db8::/32 (RFC 3849)

---
<!-- _class: dense -->
## Domains and Zones

```text
 example.                        ┐
   ├── ns1.example.              │ zone "example." on 192.0.2.53 (the lab TLD)
   ├── good.example.  NS + glue  ┘
   │      ════════ zone cut ═══════════════════════════════════════
   │    good.example.            ┐
   │      ├── ns1.good.example.  │ zone "good.example." on 192.0.2.54
   │      ├── www.good.example.  │
   │      └── web.good.example.  ┘
   └── team01.example.  NS + glue → your VM (zone from Module 2)
```

- A **domain** is a node and everything below it: the domain `example.` includes `www.good.example.`
- A **zone** is the part that one set of servers answers for: from its **apex** down to the **zone cuts** (RFC 9499; RFC 1034 §4.2)
- The `example.` zone holds only the delegation for `good.example`, not `www.good.example`
- Every zone has one SOA record and an NS record set at its apex (Module 2 explains them)

---
<!-- _class: dense table-compact -->
## Delegation and Glue

- **Delegation:** the parent adds an NS record set for the child's name (RFC 9499)
- **Glue:** when the server's name is inside the child (`ns1.good.example`), the parent also holds its address. Without it the NS records would say "we should contact the server using the address we wish to learn" (RFC 1034 §4.2.1, quoted in RFC 9499)

| Delegation of `good.example` to | Relationship (RFC 9499) | Glue in `example.` |
|---|---|---|
| `ns1.good.example` | in-domain | required: RFC 9471 MUST include it, or set TC |
| `ns.other.example` | sibling domain | SHOULD be included (RFC 9471) |
| `ns.provider.net` | unrelated | none: the resolver looks the name up separately |

The parent's copy (NS and glue) and the child's copy (NS and addresses at the apex) must match: administrators "should insure that the NS and glue RRs which mark both sides of the cut are consistent and remain so" (RFC 1034 §4.2.2). Lab 1.3 shows what happens when they do not.

---
<!-- _class: section-divider -->
# 3 · Records, Servers and Caching

---
<!-- _class: dense -->
## Resource Records

```text
www.good.example.   300   IN    A      192.0.2.80
 └─ owner name ─┘   TTL  class  type   └─ data (RDATA) ─┘
```

- Every piece of DNS data is a **resource record** (RR): owner name, TTL, class, type, data (RFC 1035 §3.2.1)
- Records with the same owner, class and type form an **RRset** (RFC 2181 §5): `www.good.example` A could hold several addresses; they are answered and cached together
- **Class** is almost always `IN` (Internet); you will also meet `CH` (Chaos) in `hostname.bind CH TXT`
- **TTL** is in seconds: how long others may keep a copy (0 to 2147483647, RFC 2181 §8)
- Zone file syntax, and the meaning of each field in the SOA, are Module 2

---
<!-- _class: dense table-compact -->
## Five Record Types for Today

| Type | Code | Holds | From the lab zone `good.example` |
|---|---|---|---|
| **A** | 1 | an IPv4 address | `www.good.example. 300 IN A 192.0.2.80` |
| **AAAA** | 28 | an IPv6 address | `www.good.example. 300 IN AAAA 2001:db8::80` |
| **NS** | 2 | an authoritative server for the zone | `good.example. 300 IN NS ns1.good.example.` |
| **SOA** | 6 | the start of a zone: primary server, contact, serial, timers | `good.example. 300 IN SOA ns1.good.example. hostmaster.good.example. 1 3600 600 86400 60` |
| **CNAME** | 5 | "this name is an alias for that one" | `web.good.example. 300 IN CNAME www.good.example.` |

- Type codes from the IANA DNS parameters registry; `dig` shows the names
- MX, TXT, PTR, SRV, CAA, HTTPS and the email records (SPF, DKIM, DMARC) are Module 2; DNSSEC records are Module 7

---
<!-- _class: dense table-compact -->
## Who Answers: Server Roles

| Role (RFC 9499) | Answers from | Reply flag | In this course |
|---|---|---|---|
| **Authoritative, primary** | its own copy of the zone; the source for transfers | `aa` | instructor servers today; your VM 1 from Module 2 |
| **Authoritative, secondary** | a copy fetched by zone transfer | `aa` | Module 3 |
| **Recursive resolver** | its cache, or by asking authoritative servers | `ra` | lab resolver 192.0.2.55 today; your VM 2 from Module 3 |
| **Stub resolver** | asks a recursive resolver; does no lookup work itself | | the resolver library on your VM; `dig`, `host`, `nslookup` |
| **Forwarder** | passes queries to another resolver | `ra` | Module 3 |

- An authoritative server answers "from local knowledge" (RFC 9499); a resolver answers for any zone
- Keep the two roles on separate servers (Module 6: open resolvers); the software that does each is Module 4

---
<!-- _class: dense -->
## Caching and TTL

- A resolver keeps each answer for its **TTL**, counting down, then asks again. The zone's owner sets the TTL: "the source of the data should control the tradeoff" (RFC 1034 §2.2)
- In the lab: the authoritative server always says 300; the resolver's copy shrinks

```text
$ dig @192.0.2.54 www.good.example +norec +noall +answer   # authoritative
www.good.example.   300   IN  A  192.0.2.80
$ dig @192.0.2.55 www.good.example +noall +answer          # resolver, a few seconds later
www.good.example.   297   IN  A  192.0.2.80
```

- Negative answers ("no such name", "no such type") are cached too (RFC 2308); the zone's SOA says for how long (Module 2)
- Consequence: a change reaches users only as old copies expire. Lower the TTL before a planned change (Module 2)

---
<!-- _class: dense -->
## The Stub Resolver on Your VM

```text
$ cat /etc/resolv.conf          # written by DHCP, or by hand
nameserver 192.0.2.9            # example: the classroom resolver is on your lab sheet
$ grep hosts /etc/nsswitch.conf # Debian 13 default
hosts:          files dns
```

- A stub resolver "relies on the services of a recursive name server"; it MUST be able to use more than one (RFC 1123 §6.1.3.1): list two `nameserver` lines
- `files dns`: applications check `/etc/hosts` first, then ask the servers in `resolv.conf`
- Debian 13 packages `systemd-resolved` separately (Priority: optional); where it is installed, `resolv.conf` points at its local stub, `nameserver 127.0.0.53`
- `getent hosts www.example.com` shows what applications get; `dig www.example.com` shows what the DNS says

---
<!-- _class: section-divider -->
# 4 · Resolution

---
<!-- _class: dense -->
## Resolving www.example.com

```text
 stub (your VM)              recursive resolver                   authoritative servers
 1 www.example.com A? ────>  2 in the cache? no
   (RD=1)                    3 www.example.com A? (RD=0) ───────>  a root server
                               <── referral: com. NS + glue ─────┘
                             4 www.example.com A? ──────────────>  a com. server
                               <── referral: example.com. NS ────┘
                             5 www.example.com A? ──────────────>  an example.com. server
                               <── answer, aa ───────────────────┘
 7 answer (ra) <─────────────  6 cache everything for its TTL
```

- The stub asks once and waits; the resolver does the walk
- Each server answers from its own data: a **referral** to servers closer to the name, or the **answer**
- In the lab the same walk is root 192.0.2.52 → `example.` 192.0.2.53 → `good.example` 192.0.2.54
- A modern resolver may ask each level for less than the full name (QNAME minimisation, Module 6)

---
<!-- _class: dense -->
## Recursive and Iterative Queries

- **Recursive query:** RD (Recursion Desired) set. A server that accepts it "returns either an error or the answer, but never referrals" (RFC 1034 §4.3.1); the reply has **RD and RA** set
- **Iterative query:** the server answers only from what it holds: an answer with `aa`, a referral, or an error. Resolvers send these to authoritative servers, with RD clear
- `dig` sets RD by default; `+norec` clears it to ask a server for its own data
- An authoritative-only server ignores RD: `dig` then warns

```text
$ dig @192.0.2.52 . NS
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 2
;; WARNING: recursion requested but not available
```

- RFC 9499 calls the two server behaviours **recursive mode** and **iterative mode**

---
<!-- _class: dense -->
## A Referral, Line by Line

```text
$ dig -4 @a.root-servers.net www.example.com A +norec
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49809
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 13, ADDITIONAL: 27
;; QUESTION SECTION:
;www.example.com.              IN   A
;; AUTHORITY SECTION:
com.                  172800   IN   NS     a.gtld-servers.net.        (13 NS records)
;; ADDITIONAL SECTION:
a.gtld-servers.net.   172800   IN   A      192.5.6.30                 (glue: A and AAAA
a.gtld-servers.net.   172800   IN   AAAA   2001:503:a83e::2:30         for all 13 servers)
```

- **No `aa`**, **empty answer**, **NOERROR**: a referral is not an error; RFC 9499 calls it a downward referral
- **Authority:** where to ask next; **additional:** their addresses (glue), so no extra lookup is needed
- The root keeps the `com.` delegation for 172800 seconds (2 days): resolvers will not ask it again soon
- Output of 22 October 2026; the ID, the root instance and the order of records change every time

---
<!-- _class: dense -->
## Walking It by Hand (Lab Hierarchy)

```text
$ dig @192.0.2.52 www.good.example +norec          # the lab root
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
example.              3600  IN  NS  ns1.example.
ns1.example.          3600  IN  A   192.0.2.53
$ dig @192.0.2.53 www.good.example +norec          # the lab TLD ("registry")
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
good.example.           60  IN  NS  ns1.good.example.
ns1.good.example.       60  IN  A   192.0.2.54
$ dig @192.0.2.54 www.good.example +norec          # the zone's own server
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
www.good.example.      300  IN  A   192.0.2.80
```

- Same question three times; only the server changes. The first two replies are referrals, the last is authoritative
- Each next address comes from the **glue** in the previous reply
- This works with no Internet access: Lab 1.1 uses it when outbound port 53 is blocked

---
<!-- _class: dense -->
## dig +trace

```text
$ dig -4 +trace www.example.com
.                    14761  IN  NS  k.root-servers.net.     ... 13 NS
;; Received 1097 bytes from 127.0.0.1#53(127.0.0.1) in 0 ms
com.                172800  IN  NS  a.gtld-servers.net.     ... 13 NS, plus DS and RRSIG
;; Received 1175 bytes from 192.58.128.30#53(j.root-servers.net) in 23 ms
example.com.        172800  IN  NS  hera.ns.cloudflare.com. ... 2 NS, plus DS and RRSIG
;; Received 510 bytes from 192.54.112.30#53(h.gtld-servers.net) in 187 ms
www.example.com.       300  IN  A   172.66.147.243          ... 2 A
;; Received 183 bytes from 172.64.32.162#53(hera.ns.cloudflare.com) in 3 ms
```

- `dig` does the walk itself: it gets the root servers from your resolver, then asks down the tree with RD clear
- It looks up **each server's address through your VM's resolver**, not from the glue: with no working resolver it stops at "couldn't get address for ..." (dig 9.20, tested). Offline, walk by hand
- DS and RRSIG lines are DNSSEC (Module 7); `+nodnssec` hides them
- A resolver does less work than this: it starts from its cache

---
<!-- _class: dense -->
## The Root Server System

- **13 names**, `a` to `m.root-servers.net`, each with one IPv4 and one IPv6 address; **12 operators** (next section)
- **2,048 instances** as of 21 October 2026 (root-servers.org): each address is announced from many places at once (**anycast**), and routing delivers your query to a nearby one
- Ask which instance answered (RFC 4892; `+nsid` uses RFC 5001):

```text
$ dig -4 @l.root-servers.net hostname.bind CH TXT +short
"nz-mae-aa"                      # from Brisbane, 22 October 2026
$ dig -4 @f.root-servers.net hostname.bind CH TXT +short
"BNE.cf.f.root-servers.org"
```

- Root service MUST be offered over IPv4 and IPv6, UDP and TCP (RFC 7720, BCP 40)
- The root servers also serve `arpa.` (try `dig -4 @a.root-servers.net arpa. NS +norec`)

---
<!-- _class: dense -->
## Root Hints and Priming

<div class="columns">
<div>

```text
a  198.41.0.4      2001:503:ba3e::2:30
b  170.247.170.2   2801:1b8:10::b
c  192.33.4.12     2001:500:2::c
d  199.7.91.13     2001:500:2d::d
e  192.203.230.10  2001:500:a8::e
f  192.5.5.241     2001:500:2f::f
g  192.112.36.4    2001:500:12::d0d
h  198.97.190.53   2001:500:1::53
i  192.36.148.17   2001:7fe::53
j  192.58.128.30   2001:503:c27::2:30
k  193.0.14.129    2001:7fd::1
l  199.7.83.42     2001:500:9f::42
m  202.12.27.33    2001:dc3::35
```

</div>
<div>

- A resolver starts from **root hints**, the names and addresses of the root servers: `named.root` from IANA, Debian's `dns-root-data`, or BIND's built-in copy
- It then sends a **priming query**, `. NS` with RD clear, and uses the list in the answer (RFC 9609, BCP 209)
- Left: `a` to `m.root-servers.net` in the IANA root hints, updated 21 October 2026
- `b` moved on 27 November 2023: older hints files have its old addresses, and priming corrects them

</div>
</div>

---
<!-- _class: dense -->
## What the Resolver Remembers

After one lookup of `www.example.com`, a resolver's cache holds:

| Record set | TTL from the source | Effect |
|---|---|---|
| `.` NS and the root addresses | 518400 s (6 days) | no priming for days |
| `com.` NS and glue | 172800 s (2 days) | the next `.com` name starts at the com servers |
| `example.com.` NS | 172800 s (2 days) from the com servers | the next name in `example.com` goes straight to its servers |
| `www.example.com.` A | 300 s | repeated lookups need no queries at all |

- On 22 October our `dig . NS` showed a TTL of 14773: a copy cached by the resolver, not the 518400 the root sends
- A resolver asks a root server again only for a TLD it has not cached, or when a cached delegation expires
- Caching also delays changes: a delegation change at the TLD is seen only as old copies expire

---
<!-- _class: section-divider -->
# 5 · The DNS Message

---
<!-- _class: dense -->
## One Format for Questions and Answers

```text
 +---------------------+
 |        Header       |   12 octets: ID, flags, response code, four counts
 +---------------------+
 |       Question      |   the question for the name server: QNAME, QTYPE, QCLASS
 +---------------------+
 |        Answer       |   RRs answering the question
 +---------------------+
 |      Authority      |   RRs pointing toward an authority (NS; or the SOA of a negative answer)
 +---------------------+
 |      Additional     |   RRs holding additional information (glue; the EDNS OPT record)
 +---------------------+
```

- Queries and responses use the same format (RFC 1035 §4.1); a query has only the header and question
- The 16-bit **ID** matches a response to its query; the resolver picks it at random (Module 6 explains why)
- `dig` prints each section under its name: `;; ANSWER SECTION:` and so on

---
<!-- _class: dense table-compact -->
## Header Flags

```text
 |                      ID                       |   16 bits
 |QR| OPCODE    |AA|TC|RD|RA| Z|AD|CD| RCODE     |   16 bits
 | QDCOUNT, ANCOUNT, NSCOUNT, ARCOUNT            |   16 bits each
```

| Flag (RFC 1035 §4.1.1; IANA registry) | Means |
|---|---|
| QR | 0 query, 1 response |
| OPCODE | 0 QUERY for lookups (NOTIFY and UPDATE come later in the course) |
| AA | the responding server is authoritative for the name |
| TC | truncated: retry over TCP |
| RD, RA | recursion desired (copied from the query); recursion available |
| Z, AD, CD | Z must be zero; AD and CD belong to DNSSEC (Module 7) |

---
<!-- _class: dense table-compact -->
## Response Codes

| RCODE | Name | Means | Typical cause |
|---|---|---|---|
| 0 | NOERROR | an answer, a referral, or an empty answer | |
| 1 | FORMERR | the server could not read the query | broken client or middlebox |
| 2 | SERVFAIL | the server could not produce an answer | no usable authoritative server; DNSSEC failure (Module 7) |
| 3 | NXDOMAIN | the name does not exist | a typo; a name not delegated or not in the zone |
| 4 | NOTIMP | the kind of query is not supported | |
| 5 | REFUSED | the server will not answer, by policy | a zone it does not serve; a resolver that is not yours |

- **NODATA** is not an RCODE: NOERROR, an empty answer and the zone's SOA in authority: "the name exists, but not with that type" (RFC 2308, RFC 9499)
- **Extended DNS Errors** (RFC 8914) add a reason that `dig` prints as `EDE:` (Module 7); the lab's SERVFAIL and REFUSED replies carry none
- Codes 0-5: RFC 1035; the rest: IANA DNS parameters

---
<!-- _class: dense -->
## Reading dig Output

```text
$ dig @192.0.2.54 www.good.example +norec
; <<>> DiG 9.20.30-1~deb13u1-Debian <<>> @192.0.2.54 www.good.example +norec  ← version, command
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62048        ← OPCODE, RCODE, ID
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2  ← flags, section counts
; EDNS: version: 0, flags:; udp: 1232                            ← EDNS: UDP size offered
; COOKIE: 5141d39583c31e18... (good)                              ← DNS Cookies (Module 6)
;www.good.example.              IN   A                           ← QUESTION SECTION
;; ANSWER SECTION:
www.good.example.        300    IN   A    192.0.2.80
;; AUTHORITY SECTION:
good.example.            300    IN   NS   ns1.good.example.
;; ADDITIONAL SECTION:
ns1.good.example.        300    IN   A    192.0.2.54
;; SERVER: 192.0.2.54#53(192.0.2.54) (UDP)                       ← who answered, and how
```

ADDITIONAL counts the OPT pseudo-record too: one address plus OPT. Query time, date and size lines follow.

---
<!-- _class: dense -->
## UDP, TCP and Message Size

- Port **53**, over **UDP and TCP**. Plain UDP messages are limited to 512 octets; longer ones are truncated with **TC** set (RFC 1035 §4.2.1)
- **EDNS(0)** (RFC 6891, STD 75) lets the client offer a larger UDP size: `dig` 9.20 offers 1232 (`udp: 1232` in its output)
- On TC, the client repeats the query over TCP. From the lab:

```text
$ dig @192.0.2.54 big.good.example TXT +norec +bufsize=512 +ignore
;; flags: qr aa tc; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1
$ dig @192.0.2.54 big.good.example TXT +norec +bufsize=512
;; Truncated, retrying in TCP mode.
;; SERVER: 192.0.2.54#53(192.0.2.54) (TCP)
;; MSG SIZE  rcvd: 741
```

- "All DNS resolvers and servers MUST support and service both UDP and TCP queries" (RFC 9210, BCP 235): a firewall that blocks TCP 53 breaks the DNS
- Large UDP answers and fragmentation (RFC 9715): Module 6. Encrypted transports on ports 853 and 443: Module 8

---
<!-- _class: dense -->
## IPv6 and the DNS

- **AAAA** holds an IPv6 address (RFC 3596, STD 88); a name can have A and AAAA records at once
- The record type does not depend on the transport: an AAAA query can travel over IPv4, an A query over IPv6 (`dig -4`, `dig -6`)
- **Reverse lookups** use names under `arpa`: IPv4 octets reversed under `in-addr.arpa`, IPv6 nibbles reversed under `ip6.arpa` (RFC 3596 §2.5). `dig -x` builds the name:

```text
$ dig -x 2001:503:ba3e::2:30 +noall +question
;0.3.0.0.2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.e.3.a.b.3.0.5.0.1.0.0.2.ip6.arpa. IN PTR
```

- The root, `in-addr.arpa` and `ip6.arpa` servers all have IPv6 addresses (RFC 7720; RFC 5855)
- If the classroom has no IPv6, `dig -6` fails at once ("network unreachable"): the DNS data is the same either way. PTR records and reverse zones are Module 2

---
<!-- _class: section-divider -->
# 6 · Who Runs the DNS

---
<!-- _class: dense -->
## The Map

```text
 IETF  ── standards (RFCs) ───────────────> IANA protocol registries (types, RCODEs, flags)
 ICANN ── policy (GNSO, ccNSO, ASO; advice from GAC, SSAC, RSSAC, ALAC)
   └── PTI performs the IANA functions ─┬─> root zone: TLD managers, delegation data
                                        └─> number pools ──> RIRs ──> ISPs ──> you
 root zone: IANA (administrator) ──> Verisign (maintainer: builds, signs, distributes)
                                 ──> 12 root server operators, 13 names
 a domain:  registrant ──> reseller ──> registrar ──EPP──> registry ──> TLD zone
```

- No single body runs the DNS: standards, policy, the root zone, the root servers, each TLD and each zone below have different owners
- The rest of this section takes each line in turn; Module 9 covers registries and registrars in depth

---
<!-- _class: dense -->
## ICANN and IANA

- **ICANN** (founded 1998) is a not-for-profit that "coordinates these unique identifiers": names, addresses, protocol parameters. It "doesn't control content on the Internet" (icann.org)
- Policy comes from supporting organisations (**GNSO** for generic names, **ccNSO** for country codes, **ASO** for addresses), with advice from committees (**GAC**, **SSAC**, **RSSAC**, **ALAC**)
- **IANA** keeps the global registries: the root zone, IP address pools for the RIRs, and protocol parameters for the IETF (RFC 2860 sets out the IETF side)
- The IANA functions "are performed by **Public Technical Identifiers**, a purpose-built affiliate of ICANN" (iana.org)
- Until 2016 this ran under a contract with the US government (NTIA). "Today, 1 October 2016, the contract ... has officially expired" (ICANN): the **IANA stewardship transition**

---
<!-- _class: dense -->
## Changing the Root Zone

```text
 TLD manager ──request──> IANA (PTI)               ──> Root Zone Maintainer (Verisign)  ──> root servers
                          checks consent, runs          builds the zone file, signs it,      load each new
                          technical tests, updates      distributes it                       serial
                          the root zone database
```

- RSSAC037 (2018) names the roles: the **Root Zone Administrator** manages the data and assigns TLD operators; the **Root Zone Maintainer** "accepting service data from the Root Zone Administrator, formatting it into zone file format, cryptographically signing it ... and putting it into the root zone distribution system"
- The root zone has been signed with DNSSEC since 15 July 2010 (IANA): Module 7
- A TLD manager changes its name servers or DS records this way; anyone below a TLD changes theirs through their registrar (Module 9)

---
<!-- _class: dense -->
## Root Server Operators and RSSAC

<div class="columns">
<div>

```text
a, j  Verisign, Inc.
b     Information Sciences Institute (USC)
c     Cogent Communications
d     University of Maryland
e     NASA
f     Internet Systems Consortium
g     Defense Information Systems Agency
h     U.S. Army DEVCOM Army Research Lab
i     Netnod
k     RIPE NCC
l     ICANN
m     WIDE Project
```

</div>
<div>

- 13 names, 12 independent organisations (root-servers.org); all serve the same root zone
- Each runs its own hardware, software, sites and peering
- **RSSAC** "advises the ICANN community and the Board on matters relating to the operation, administration, security, and integrity of the Root Server System"; its members represent the operators (icann.org)
- Sites and statistics: root-servers.org

</div>
</div>

---
<!-- _class: dense table-compact -->
## Registries, Registrars and Registrants

| Role | Does | Example in this course |
|---|---|---|
| **Registry** | decides what goes into a zone and runs the database for it; for a TLD, publishes the TLD zone | the instructor's server for `example.` |
| **Registrar** | a "go-between for registrants and registries"; the only party that talks EPP to the registry | your team account `regNN` (Module 9) |
| **Reseller** | sells through a registrar's system; no registry access | |
| **Registrant** | the person or organisation "on whose behalf a name ... is registered" | you, for `teamNN.example` |
| **DNS operator** | runs the name servers for the domain | your VM 1, from Module 2 |

- Definitions from RFC 9499; the same roles as Module 9's "Who Does What"
- **gTLD** registries and registrars work under contracts with ICANN; each **ccTLD** sets its own policy and accredits its own registrars
- The registry publishes the delegation (NS and glue); the registrant's DNS operator runs the zone. A delegation fault can sit on either side, or in the gap between them

---
<!-- _class: dense -->
## RIRs and Reverse DNS

- **IANA** allocates IP address pools to five **Regional Internet Registries**: AFRINIC (Africa), APNIC (Asia/Pacific), ARIN (Canada, USA, some Caribbean), LACNIC (Latin America, some Caribbean), RIPE NCC (Europe, Middle East, Central Asia). ISPs get addresses from an RIR, NIR or LIR (iana.org)
- Reverse DNS follows the same chain. `in-addr.arpa` and `ip6.arpa` are served by `a` to `f.in-addr-servers.arpa` and `a` to `f.ip6-servers.arpa` (RFC 5855, BCP 155); the RIRs run the zones for their address blocks and delegate further to address holders

```text
$ dig 202.in-addr.arpa NS +short                  # 22 October 2026
ns1.apnic.net.
ns2.apnic.net.
rirns.arin.net.                                   # (and secondaries at other RIRs)
```

- Getting your own reverse zone delegated is a request to your RIR or ISP; PTR records are Module 2

---
<!-- _class: section-divider -->
# 7 · Tools and a Debugging Method

---
<!-- _class: dense table-compact -->
## The Tools on Your VM

| Tool | Debian 13 package | Use it for |
|---|---|---|
| `dig` | `bind9-dnsutils` | any query, with the full response: the course's main tool |
| `host` | `bind9-host` (installed with `bind9-dnsutils`) | quick answers in plain sentences |
| `nslookup` | `bind9-dnsutils` | the same lookups, in an older format, with an interactive mode |
| `delv` | `bind9-dnsutils` | DNSSEC validation (Module 7) |
| `tcpdump` | `tcpdump` | capturing DNS traffic to a file (needs `sudo`) |
| `tshark` | `tshark` | reading captures as text; Wireshark on your laptop shows the same file graphically |

- Installed on the lab VMs: `sudo apt install bind9-dnsutils tcpdump tshark`. `dnsutils` is only an alias that `bind9-dnsutils` provides
- Versions in the lab: BIND tools 9.20.30, tcpdump 4.99.5, TShark 4.4.19 (Debian 13, 22 October 2026)

---
<!-- _class: dense table-compact -->
## dig Options You Will Use

| Option | Does |
|---|---|
| `dig @server name type` | ask `server` (name or address) for `name` and `type`; type defaults to A |
| `+norec` | clear RD: ask a server for its own data only |
| `+trace` | walk from the root yourself (needs a working resolver for the server names) |
| `+short`; `+noall +answer` | only the data; only the answer section (also `+authority`, `+additional`) |
| `-4`, `-6` | send over IPv4 or IPv6 only |
| `+tcp`; `+bufsize=512 +ignore` | use TCP; offer 512 octets and show a truncated reply as it is |
| `-x address` | reverse lookup: builds the `in-addr.arpa` or `ip6.arpa` name |
| `+nsid`; `hostname.bind CH TXT` | which server instance answered |
| `+tries=1 +timeout=2` | fail fast when a server does not answer |
| `+search` | use the `search` list in `resolv.conf`, as `host` and `nslookup` do by default |

---
<!-- _class: dense -->
## host and nslookup

The same lookup through the lab resolver, as `host` and `nslookup` show it:

```text
$ host www.good.example 192.0.2.55
Using domain server: ...                         (3 lines naming the server)
www.good.example has address 192.0.2.80
www.good.example has IPv6 address 2001:db8::80
$ nslookup www.good.example 192.0.2.55
Server:         192.0.2.55
Address:        192.0.2.55#53
Non-authoritative answer:
Name:   www.good.example
Address: 192.0.2.80                              (then the AAAA)
```

- "Non-authoritative answer" means the reply came from a resolver's cache or lookup, not from the zone's own server
- Both add the `search` domains to short names; `dig` does not. Neither shows flags or sections: switch to `dig` to debug

---
<!-- _class: dense -->
## A Debugging Method

1. **Write down the symptom exactly:** name, type, who sees it, from where, since when
2. **Reproduce it through the same resolver** the user has: `dig name` (status, query time)
3. **Ask another resolver:** the same result means the zone's data or delegation; a different one points at the first resolver or its cache
4. **Find the zone's servers from the parent:** `dig @parent-server name +norec` (walk down from the root if you do not know the parent)
5. **Ask each listed server directly** with `+norec`: `aa`? REFUSED? no reply?
6. **Compare the parent's and the child's view:** NS names, and the glue against the addresses in the zone
7. **Record** the evidence (command and the line that proves it), the cause, who must fix it, and how you will check the fix

Lab 1.3 uses exactly these steps. Monitoring that finds faults before users do is Module 11.

---
<!-- _class: dense table-compact -->
## Delegation Faults and Their Evidence

| Fault | What you see | Evidence | Who fixes it |
|---|---|---|---|
| Listed server does not serve the zone | resolver SERVFAIL | that server: REFUSED, or no `aa` | operator adds the zone, or registrant changes the NS |
| No server at the listed address | SERVFAIL after a delay | `dig @address`: timed out | operator, or registrant updates the address |
| Server up, nothing on port 53 | SERVFAIL | "connection refused" | DNS operator starts the server |
| Stale glue | works, but slowly or not everywhere | parent's address for an NS differs from the zone's | registrant, via the registrar |
| NS sets differ | usually works | parent's NS list differs from the zone's apex NS | both sides agree on one set |
| Not delegated | NXDOMAIN | the parent answers NXDOMAIN with its own SOA | registrant registers or renews |

RFC 9499: "lame delegation" is historic and unclear; name the specific fault.

---
<!-- _class: dense -->
## Worked Example: Your Zone on Day 1

The instructor's registry already delegates `teamNN.example` to your VM 1, which runs no DNS server yet:

```text
$ dig @192.0.2.55 www.team01.example                 # 1-2. the user's view
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: ...
$ dig @192.0.2.53 www.team01.example +norec          # 4. the parent
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
team01.example.       60  IN  NS  ns1.team01.example.
ns1.team01.example.   60  IN  A   192.0.2.30
$ dig @192.0.2.30 www.team01.example +norec          # 5. the listed server
;; communications error to 192.0.2.30#53: connection refused
```

- Cause: the host is up but nothing listens on port 53. Fix: the DNS operator (you) starts a server with the zone, in Modules 2-4
- Check the fix: the same three commands, ending with `flags: qr aa`

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

```text
                       classroom LAN (lab sheet addresses; 192.0.2.0/24 on the slides)
  ─────┬───────────────────┬────────────────┬──────────────────┬────────────────┬──────
   your VM 1           lab root          registry (TLD)     lab child         lab resolver
   192.0.2.30          192.0.2.52        192.0.2.53         192.0.2.54        192.0.2.55
   client today        zone "."          zone example.      lab zones under   recursive; knows
                                                            example.          only the lab tree
```

- Log in to **VM 1** over SSH. It has the client tools and no DNS server; VM 2 waits for Module 3
- **Packages:** `bind9-dnsutils` (`dig`, `nslookup`), `bind9-host`, `tcpdump`, `tshark`
- **Captures:** `sudo tcpdump -i any -n -U -w file.pcap port 53`; read with `tshark -r` (no `sudo` needed), or copy the file to your laptop for Wireshark
- **Lab names exist only in the lab:** your classroom resolver uses the real root, which says `example.` does not exist. Use `@192.0.2.55` for lab names
- **Your kit:** `labs/module01/` (what was tested, online and offline paths); the lab servers are run by the instructor

---
<!-- _class: dense table-compact -->
## Online or Offline

Some classrooms block outbound port 53. Test once: `dig -4 @a.root-servers.net . SOA +norec +tries=1 +timeout=2`

| Part | With Internet access | Without |
|---|---|---|
| Lab 1.1 steps 1-3 | the real root, TLD and authoritative servers | the lab resolver, root, TLD and child (`www.good.example`) |
| Lab 1.1 step 4 | `dig +trace` | skipped: `+trace` needs your VM's resolver to know the lab names |
| Lab 1.1 steps 5-6 | real TLD referrals; root instances over IPv4 and IPv6 | `com.` at the lab root; AAAA records and `dig -x` names |
| Labs 1.2 and 1.3 | lab servers | the same lab servers |

- IPv6 transport works only where the classroom has IPv6; the AAAA data is there either way
- Real servers' answers change from day to day: compare the shape of your output with the slides, not the numbers

---
<!-- _class: dense -->
## Lab 1.1: Walk the Hierarchy (30 min)

1. `cat /etc/resolv.conf`; `dig . NS`: which server answered (SERVER line)? Which flags? How many NS records, with what TTL?
2. `dig -4 @a.root-servers.net . NS +norec`: compare the flags and the TTL with step 1
3. By hand: `dig -4 @a.root-servers.net www.example.com +norec`; take one address from the ADDITIONAL section and ask it the same question; repeat until a reply has `aa`
4. `dig -4 +trace www.example.com`, then a name in your own country's ccTLD; compare with step 3
5. Other TLDs: `dig -4 @a.root-servers.net org. NS +norec +noall +authority +additional`; repeat for your ccTLD, `xn--p1ai.` and `arpa.` (where is the answer?)
6. `dig -4 @l.root-servers.net hostname.bind CH TXT +short`; try `f` and `k`, and `-6` if IPv6 works; compare with your neighbours

**Offline:** step 1 `dig @192.0.2.55 . NS`; step 2 `dig @192.0.2.52 . NS +norec`; step 3 `@192.0.2.52`, then `@192.0.2.53`, then `@192.0.2.54` for `www.good.example`; step 5 `dig @192.0.2.52 com. NS +norec`; step 6 `dig @192.0.2.54 www.good.example AAAA +norec` and `dig @192.0.2.52 -x 2001:db8::80 +norec +noall +question`

> **Checkpoint:** for every reply you can say who sent it and whether it was a referral (no `aa`, NS in authority, glue) or an answer (`aa`), and why step 1 had `ra` and step 2 had `aa`

<!--
Step 1: the classroom resolver answers with rd ra and a TTL below 518400 (cached); step 2: aa, 518400, the 13 names with A and AAAA in additional.
Step 5: arpa. comes back in the ANSWER section with aa: the root servers are authoritative for arpa. xn--p1ai is .рф.
Step 6: the instance names differ between letters, between IPv4 and IPv6, and between classrooms: anycast.
Offline step 5: NXDOMAIN with aa: the lab root knows only example.
-->

---
<!-- _class: dense -->
## Lab 1.2: Read the Response (30 min)

1. In a second SSH session: `sudo tcpdump -i any -n -U -w m01.pcap port 53`
2. `dig @192.0.2.54 www.good.example +norec`, then `dig @192.0.2.55 www.good.example` twice, a few seconds apart: compare flags and TTL
3. Response codes: `dig @192.0.2.55 nosuch.good.example`; `dig @192.0.2.55 www.good.example TXT`; `dig @192.0.2.54 www.example.com +norec`; `dig @192.0.2.55 www.teamNN.example`
4. Sections: `dig @192.0.2.55 web.good.example`; `dig @192.0.2.53 www.good.example +norec`
5. Size and transport: `dig @192.0.2.54 big.good.example TXT +norec +bufsize=512 +ignore`; the same without `+ignore`; then `dig @192.0.2.54 www.good.example +norec +tcp`
6. Wait a few seconds, stop tcpdump (Ctrl-C), then:
   `tshark -r m01.pcap -Y 'dns.flags.response == 1' -T fields -E header=y -e ip.src -e tcp.srcport -e dns.flags.authoritative -e dns.flags.truncated -e dns.flags.recavail -e dns.flags.rcode -e dns.qry.name`

**With Internet access:** capture `dig -4` and `dig -6 @a.root-servers.net . SOA +norec`, and find both in the capture (`tshark -r m01.pcap -Y ipv6`)

> **Checkpoint:** for every reply you can name the QR, AA, TC, RD and RA flags and the RCODE in `dig` and in `tshark` (True/False, RCODE as a number), tell NXDOMAIN from NODATA, and explain the TCP retry

<!--
Expected (lab, 22 October 2026): step 2 aa from .54, rd ra from .55 with the TTL dropping from 300; step 3 NXDOMAIN with the good.example SOA, NOERROR with ANSWER 0 and the good.example SOA (NODATA), REFUSED, SERVFAIL (the team's own zone: no server yet, the worked example); step 4 CNAME then A; referral with AUTHORITY 1, ADDITIONAL 2; step 5 tc and ANSWER 0, then "Truncated, retrying in TCP mode", (TCP), 741 octets.
tshark rows: 192.0.2.54 True False False 0 www.good.example; 192.0.2.55 False False True 3 nosuch.good.example; 192.0.2.54 False False False 5 www.example.com; 192.0.2.55 False False True 2 www.teamNN.example; 192.0.2.54 True True False 0 big.good.example; then the same name with tcp.srcport 53 and TC False.
-->

---
<!-- _class: dense -->
## Lab 1.3: Debug a Delegation (30 min)

Reports (zone names from your lab sheet; these are the defaults): **www.alpha.example** and **www.bravo.example** fail. **www.echo.example** "does not exist". **www.charlie.example** and **www.delta.example** work, but the registry's checks flag both zones.

For each zone, follow the method and fill in one row of the worksheet:

1. `dig @192.0.2.55 www.X.example`: status and query time
2. `dig @192.0.2.53 www.X.example +norec`: delegated? to which names and addresses?
3. Each listed address: `dig @address www.X.example +norec +tries=1 +timeout=2`
4. Compare: `dig @192.0.2.53 X.example NS +norec` with `dig @zone-server X.example NS +norec`; ask the zone's own server for each `nsN.X.example`
5. Worksheet: symptom · evidence (command and the line that proves it) · cause · who fixes it · how to check the fix

> **Checkpoint:** one cause per zone, each with evidence; your worksheet is assessed (Practical Assessment 1A, task 2)

**Discussion:** which of these faults would a registry catch before it publishes a delegation, and which only the DNS operator can fix?

<!--
Answer key (instructor only; same as labs/instructor/module01/README.md). Default labels; with M01_FAULT_LABELS the roles keep this order: not served, no server, stale glue, NS sets differ, not delegated.
alpha: delegated to ns1.alpha.example 192.0.2.54; that server does not serve alpha.example: REFUSED; resolver SERVFAIL. Fix: the DNS operator adds the zone, or the registrant points NS at a server that has it.
bravo: delegated to ns1.bravo.example 198.51.100.53; nothing answers there (timed out, or network unreachable on a lab LAN with no route); resolver SERVFAIL. Fix: correct address or a working server; registrant through registrar if the address changed.
charlie: parent glue ns2.charlie.example 198.51.100.54, but the zone says 192.0.2.54; resolves because ns1 works. Fix: registrant updates the host address through the registrar (EPP host update, Module 9).
delta: parent NS ns1 and ns2; the zone's apex NS ns1 and ns3, and ns2.delta.example is NXDOMAIN in the zone; resolves; the resolver uses the zone's set. Fix: make both sides list the same servers (registrant updates the delegation, or the operator restores ns2).
echo: no delegation: NXDOMAIN with aa from the parent, example. SOA in authority. Fix: register the name (or renew it).
Timing in a classroom with a default gateway: bravo through the resolver takes about 10 s (measured in review with the TEST-NET-2 range dropped); dig may print one "timed out" line before SERVFAIL; the delay is the evidence. charlie can be slow once (about 0.9 s cold). On a lab LAN with no route, bravo fails at once with "network unreachable".
Grading: good.example has one NS, and the two names in charlie and delta share one address: lab simplifications. Credit a participant who notices; do not deduct either way.
The discussion: a registry can test alpha, bravo, charlie and delta before publishing (pre-delegation checks); echo is a registration matter; operating the servers is always the DNS operator's job.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 1034, 1035 (STD 13); RFC 882, 883; RFC 608, 952, 920, 1591
- RFC 9499 (BCP 219, obsoletes 8499) terminology; RFC 2181; RFC 4343; RFC 1123 §6.1
- RFC 9471 glue; RFC 2308 negative caching; RFC 8914 EDE
- RFC 3596 (STD 88); RFC 5855; RFC 3172 arpa
- RFC 6891 (STD 75) EDNS(0); RFC 7766, 9210 TCP; RFC 9715
- RFC 7720 root service; RFC 9609 priming; RFC 4892, 5001
- RFC 5890, 5891, 3492 IDNA; RFC 2606, 6761, 6762, 8375, 9476; RFC 4795 LLMNR
- RFC 5737, 3849 documentation addresses; RFC 2860
- IANA: DNS parameters, root zone database, `named.root`, numbers
- ICANN: history, stewardship transition, RSSAC; RSSAC037; root-servers.org

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>dig @server name type +norec
dig -4 +trace name
dig name +noall +answer
dig -x 2001:db8::80
dig @s hostname.bind CH TXT
host name server
nslookup name server
sudo tcpdump -i any -n -U \
  -w f.pcap port 53
tshark -r f.pcap -Y dns
getent hosts name
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. Name two problems with HOSTS.TXT that the DNS design solved, and the design feature that solved each.
2. What is the difference between the domain `example.` and the zone `example.` in the lab?
3. A reply has `flags: qr; ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2` and status NOERROR. What is it, and what do you do next?
4. `dig www.example.net` returns NOERROR with no answer and an SOA in the authority section. What does that mean, and how does it differ from NXDOMAIN?
5. Why does a referral need glue for `ns1.good.example`, but not for `ns.provider.net`?
6. A name works from the office but SERVFAILs from home. List your first three commands, and say which result would point at the delegation rather than a resolver.

<!--
Answers:
1. Distribution cost (every host copied one file, load "proportional to the square of the number of hosts") -> a distributed database with caching; the NIC as a bottleneck for changes -> delegation, so each organisation edits its own zone; also flat names -> a hierarchy (RFC 1034 §2.1-2.2).
2. The domain is the whole subtree, including www.good.example and team01.example. The zone is what the registry server 192.0.2.53 is authoritative for: example. down to the cuts, holding only the NS and glue for good.example, team01.example and the others.
3. A referral (downward referral, RFC 9499): no aa, the next servers in authority, their addresses (glue) in additional (the second additional record is the OPT pseudo-record). Ask one of those addresses the same question with +norec.
4. NODATA: the name exists but has no record of that type (RFC 2308). NXDOMAIN: the name does not exist at all. Both are negative answers and are cached for the time the SOA gives.
5. ns1.good.example is inside the zone being delegated: without its address in the parent, the resolver would have to ask good.example's servers where good.example's server is. ns.provider.net is in another part of the tree (unrelated, RFC 9499): the resolver looks it up separately, starting from net. RFC 9471: in-domain glue MUST be in a referral.
6. dig name (through the home resolver; status and time); dig @another-resolver name; dig @parent-server name +norec and then dig @each-listed-server name +norec. If the authoritative servers answer properly from both places, suspect the home resolver (cache, filtering). If a listed server times out or refuses from home too, or the parent's NS or glue are wrong, it is the delegation; a fault that shows only from some places can also be an anycast instance or a network path.
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
