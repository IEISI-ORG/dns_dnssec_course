---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 6: DNS Security Fundamentals and Threat Landscape

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **List** the classes of attack on the DNS (forgery, hijacking, denial of service, abuse as a channel) and where each one lands
- **Explain** cache poisoning and the Kaminsky attack, and how port and ID randomisation, DNS Cookies and DNSSEC defend against it
- **Explain** reflection and amplification, open resolvers, and random-subdomain floods
- **Configure** BIND 9.20 access controls, response rate limiting, QNAME minimisation and DNS Cookies, and check them on the wire
- **Implement** TSIG-authenticated zone transfers with `tsig-keygen`
- **Configure** a Response Policy Zone fed from another server
- **Assess** a server's exposure from its configuration, logs and statistics, and name the signs of an attack in progress

---
<!-- _class: dense table-compact -->
## What Changed Recently

Older DNS security training is out of date in five places:

| Then | Now |
|---|---|
| TSIG is RFC 2845; HMAC-MD5 common | RFC 8945 (Internet Standard, STD 93, 2020): hmac-sha256 RECOMMENDED, HMAC-MD5 MUST NOT be used |
| DNS Cookies: each server's own format | RFC 9018 (2021): one interoperable server cookie (SipHash-2-4), so anycast sets can share it |
| QNAME minimisation is Experimental (RFC 7816) | RFC 9156 (Proposed Standard, 2021) obsoletes it |
| BIND allows zone transfers to anyone by default | BIND 9.20 (Debian 13) refuses them unless `allow-transfer` says otherwise; BIND 9.18 allowed all |
| Large UDP answers, fragments | EDNS buffer 1232 by default in BIND 9.20 and Unbound 1.26; RFC 9715 (2025) on avoiding fragmentation |

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. The threat landscape (10m)
2. Cache poisoning and hijacking (15m)
3. Floods and amplification (20m)
4. Hardening servers (20m)
5. TSIG and zone transfers (10m)
6. RPZ, tunnelling and detection (10m)
7. Recap and questions (5m)

## Agenda (90 min Lab)

1. Lab 6.1 Close the open doors (20m)
2. Lab 6.2 Watch the resolver defend itself (15m)
3. Lab 6.3 Rate limiting under load (20m)
4. Lab 6.4 TSIG-protected zone transfer (20m)
5. Lab 6.5 RPZ and spotting a tunnel (15m)

---
<!-- _class: section-divider -->
# 1 · The Threat Landscape

---
<!-- _class: dense -->
## Why DNS Is a Target

- **Every connection starts with a lookup:** control the answer and you control where users go, including mail and certificate validation
- **UDP and no authentication** in the original protocol: an answer is accepted if it matches the question, ID and ports (RFC 5452)
- **Trust is delegated:** registrant, registrar, registry, DNS operator and resolver operator each hold part of the chain
- **Small queries, large answers:** a DNS server is a ready-made traffic amplifier
- **Port 53 is open almost everywhere:** a channel that firewalls rarely inspect

RFC 3833 (2004) is the IETF's threat analysis: packet interception, ID guessing and query prediction, name chaining, betrayal by a trusted server, denial of service, authenticated denial, wildcards. It also measures how far DNSSEC (Module 7) helps against each; most of it still applies.

---
<!-- _class: dense table-compact -->
## Attack Classes

| Class | Examples | Main defences | Where |
|---|---|---|---|
| Forged data | cache poisoning, Kaminsky, side channels | port and ID randomisation, cookies, DNSSEC validation | §2, Module 7 |
| Hijacking | registrar account takeover, changed NS, BGP route hijack | MFA, registry lock, RPKI, monitoring | §2, Module 9 |
| Denial of service | reflection and amplification, query floods, random subdomains | ACLs, RRL, BCP 38, fetch limits, capacity | §3 |
| Abuse as a channel | tunnelling, malware command and control | RPZ, egress rules, query analysis | §6 |
| Data exposure | open zone transfers, query snooping | `allow-transfer`, TSIG, encryption | §4, §5, Module 8 |

One server can face all five. The authoritative side and the resolver side need different defences, so this module treats them separately.

---
<!-- _class: dense -->
## Where Attacks Land

```text
 registrant ── registrar ── registry ──> TLD zone (NS, DS)        (A) accounts, EPP
                                             │
 stub ──(1)──> recursive resolver ──(2)──> authoritative servers   (B) server, zone data
   │              │      ▲                    ▲
   │              │      └── forged answers ──┘                    (C) off-path forgery
   │              └── spoofed queries from "victims"               (D) reflection
   └── changed resolver settings, rogue DHCP                       (E) stub and LAN
```

- **(A)** and **(B)** change the real data: DNSSEC does not help if the attacker controls the zone or its DS
- **(C)** forges data in transit: randomisation and cookies make it harder; DNSSEC validation detects it
- **(D)** uses your server against someone else: ACLs and rate limiting
- **(E)** sends the user to another resolver: device management, DNSSEC, encrypted DNS (Module 8)

---
<!-- _class: dense table-compact -->
## Dated History

| Year | Event | Primary source |
|---|---|---|
| 2008 | Kaminsky attack: birthday attack with in-bailiwick referrals; insufficient ID and source-port randomness | CVE-2008-1447; CERT/CC VU#800113, published 8 July 2008 |
| 2019 | DNS infrastructure tampering: stolen credentials, changed A, MX and NS records, valid certificates for the victims' domains | CISA Emergency Directive 19-01, 22 January 2019 |
| 2020 | NXNSAttack: crafted referrals make a resolver send very many fetches | CVE-2020-8616; ISC advisory, 19 May 2020; USENIX Security 2020 paper |
| 2020 | SAD DNS: an ICMP side channel reveals the resolver's source port | CVE-2020-25705 (Linux); ACM CCS 2020 paper |
| 2024 | KeyTrap: crafted DNSSEC zones exhaust a validator's CPU | CVE-2023-50387 (and CVE-2023-50868, NSEC3); ISC advisory, 13 February 2024 |

The software flaws were fixed, but only on servers that were upgraded: BIND 9.20 (Debian 13) is outside the affected ranges of the ISC advisories above, and SAD DNS was a kernel flaw (the Debian security tracker lists trixie's `linux` package as fixed). The 2019 campaign used stolen passwords, which no patch fixes.

---
<!-- _class: dense table-compact -->
## Defence Map

| Defence | Forgery | Hijack | DoS / reflection | Channel abuse | Exposure |
|---|---|---|---|---|---|
| Port and ID randomisation | yes | | | | |
| DNS Cookies | yes | | yes | | |
| DNSSEC validation (Module 7) | yes | partly | | | |
| ACLs, no open recursion | | | yes | | yes |
| Response rate limiting | | | yes | | |
| TSIG on transfers | yes | | | | yes |
| RPZ | | partly | | yes | |
| Encrypted DNS (Module 8) | partly | partly | | | yes |
| Account security, registry lock | | yes | | | |

No single measure covers everything. The labs build the server-side rows; DNSSEC and encryption follow in Modules 7 and 8.

---
<!-- _class: section-divider -->
# 2 · Cache Poisoning and Hijacking

---
<!-- _class: dense -->
## How a Resolver Accepts an Answer

RFC 5452 §9.1: a resolver MUST match all of these before it believes a response:

- the response's **source address** against the query's destination address
- the **destination address and port** against the query's source address and port
- the **query ID**
- the **query name, class and type**

Then the resolver accepts only in-domain records (RFC 5452 §6): NS and address records for a zone the answering server is not responsible for are dropped or ranked lowest (RFC 2181 §5.4.1).

An off-path attacker cannot see the query. It knows the question (it often triggers the lookup itself) and can forge the server's address, so what it must **guess is the ID and the port**, and its answer must arrive before the real one.

---
<!-- _class: dense -->
## The Arithmetic of Guessing

- **ID only:** 16 bits, on average 32,768 attempts (RFC 5452 §4.3)
- **ID and port:** a random source port per query adds up to 16 bits more
- **The window:** the time until the real answer arrives, often around 0.1 s

RFC 5452 §8.1 works an example at 7,000 forged packets per second, with an effectively zero TTL (the attacker can trigger queries for new names at will):

| Source ports used | 50% chance of a successful forgery |
|---|---|
| 1 (fixed port) | within 7 seconds |
| 64,000 (random per query) | after around 116 hours |

Source-port randomisation turned a seconds-long attack into one that takes days, at packet rates a watchful operator can notice (RFC 5452 §8). It does not make forgery impossible.

---
<!-- _class: dense -->
## The Kaminsky Attack (2008)

- **Before:** an attacker had one chance per TTL; a cached answer blocked further attempts for that name
- **The idea:** make the resolver look up names that are not cached (`a1.bank.example`, `a2.bank.example`, ...), so every query is a new chance: "an effectively infinite number of queries" (RFC 5452 §8.1)
- **The payload:** forged responses carry **in-bailiwick referrals** (CVE-2008-1447): NS and address records for `bank.example` itself, which pass the in-domain check (RFC 5452 §6) and replace the real delegation in the cache
- **The flaw:** many resolvers used a fixed or predictable source port, so only the 16-bit ID protected them (VU#800113)

CVE-2008-1447 ("DNS Insufficient Socket Entropy Vulnerability") was published with CERT/CC VU#800113 on 8 July 2008; fixed versions included BIND 9.5.0-P1, 9.4.2-P1 and 9.3.5-P1. The mitigation was per-query source-port randomisation, which VU#800113 says adds approximately 16 bits that an attacker must guess.

---
<!-- _class: dense -->
## Defences Inside the Resolver

- **Random ID and source port** for every query (RFC 5452 §9.2, MUST); BIND 9.20 uses the operating system's ephemeral range, 32768-60999 on Debian 13
- **0x20 encoding:** randomise the case of the query name, `wWw.TeAm01.eXaMpLe`, and require it back unchanged. An Internet-Draft from 2008 that expired; Unbound offers it (`use-caps-for-id`, default no); the BIND 9.20 ARM has no such option
- **DNS Cookies** (RFC 7873, 9018): a 64-bit client cookie the attacker must also guess (section 4)
- **TCP** when forgery is suspected (RFC 5452 §9.3): an off-path attacker must also guess the 32-bit sequence number
- **DNSSEC validation:** a forged answer fails validation whatever its ID and port (Module 7)

NAT devices that serialise or limit the source ports can largely undo port randomisation (RFC 5452 §10). Check what your edge device does to the resolver's queries.

---
<!-- _class: dense -->
## Seen in the Lab (Lab 6.2)

The resolver's queries for three names, cold cache, captured on the resolver:

```text
dst         sport  id      type  name                 client cookie     server cookie
192.0.2.53  35396  0x2378  NS    team01.example       081d630faeb24dc8  -
192.0.2.30  41141  0xeca0  A     www.team01.example   bf1a9d7380181439  -
192.0.2.53  54980  0xbbf3  AAAA  ns1.team01.example   081d630faeb24dc8  010000006ad8b639...
192.0.2.30  53178  0xb781  AAAA  ns1.team01.example   bf1a9d7380181439  010000006ad8b639...
192.0.2.30  39102  0x7136  A     mail.team01.example  bf1a9d7380181439  010000006ad8b639...
192.0.2.30  55484  0x9fe2  A     ftp.team01.example   bf1a9d7380181439  010000006ad8b639...
```

- A new source port and ID on every query
- A different client cookie per server; the server cookie is sent back once learned
- The registry (192.0.2.53) is asked only for `team01.example NS`: QNAME minimisation (section 4)

---
<!-- _class: dense -->
## SAD DNS (2020): Finding the Port

- An **off-path** attacker uses a side channel to learn which UDP port the resolver is waiting on, then only has to guess the 16-bit ID
- The Linux flaw (CVE-2020-25705): the global ICMP rate limit let an attacker "quickly scan open UDP ports" and "effectively bypass source port UDP randomization"
- The authors (ACM CCS 2020) report side channels in Linux, Windows, macOS and FreeBSD, and injecting records into caches such as BIND, Unbound and dnsmasq

What protects you:

- **Patched kernels:** keep the resolver's operating system updated, not only BIND
- **DNSSEC validation:** the forged data fails validation however the port was found
- **DNS Cookies** between resolver and authoritative servers that support them

The lesson: each guessing defence buys time; only validation checks the data.

---
<!-- _class: dense table-compact -->
## Hijacking: Four Places

| Where | What the attacker changes | Defences |
|---|---|---|
| Registrar or registry account | NS and DS records at the parent | MFA, unique credentials, **registry lock** (Module 9), alerts on changes |
| Authoritative server or its provider | the zone data itself | patching, access control, signing keys kept off the public server (hidden primary, Module 5) |
| BGP routes to the server | where packets for its address go | RPKI route origin validation (RFC 6811), monitoring your prefixes |
| Resolver or stub settings | which resolver the client asks | DHCP and router hardening, device management, DNSSEC validation, encrypted DNS (Module 8) |

DNSSEC validation detects a hijack in the middle (routes; a rogue resolver, if the stub validates). It does not detect a hijack at the registrar or registry if the attacker can also change or remove the DS record.

---
<!-- _class: dense -->
## DNS Infrastructure Tampering (2019)

CISA Emergency Directive 19-01 (22 January 2019) describes the campaign:

1. The attacker obtains the credentials of an account that can change DNS records
2. It changes A, MX or NS records to point at its own servers, then passes the traffic on
3. It obtains valid certificates for the domains, so users see no warnings

The directive required, within 10 business days: **audit** the public DNS records on all authoritative and secondary servers; **change the passwords** of all accounts that can change DNS records; add **multi-factor authentication** to them; and **monitor Certificate Transparency logs** for unexpected certificates.

For a ccTLD: the same applies to registrar and registry accounts, and to your own DNS hosting. Registry lock (Module 9) sets `server…Prohibited` statuses that no registrar can remove over EPP, so a stolen registrar password is not enough to change the delegation.

---
<!-- _class: section-divider -->
# 3 · Floods and Amplification

---
<!-- _class: dense -->
## Reflection and Amplification

```text
 attacker ──(spoofed source = victim)──> open resolver or authoritative server
                                                 │  large responses
 victim  <───────────────────────────────────────┘
```

- The attacker sends small queries with the **victim's address** as the source
- Each server sends its larger answer to the victim; many servers together flood it
- **Amplification factor** = response size / query size; RFC 5358 (2008) put it at around 80 for an open resolver with EDNS0
- **The real fix** is ingress filtering, so networks cannot send packets with forged source addresses: BCP 38 (RFC 2827) and BCP 84 (RFC 3704)

You cannot make other networks deploy BCP 38. You can make sure your own servers are poor amplifiers and your own network does not let spoofed packets out.

---
<!-- _class: dense -->
## Measured on Your Own Server (Lab 6.3)

```text
$ dig @192.0.2.30 big.team01.example TXT +qr +noall +stats
;; QUERY SIZE: 59
;; MSG SIZE  rcvd: 1105

$ dig @192.0.2.30 team01.example ANY +notcp +noall +answer +stats
team01.example.  60  IN  SOA  ns1.team01.example. admin.team01.example. 1 300 60 86400 60
;; MSG SIZE  rcvd: 117
```

- A 59-octet query returned 1105 octets: a factor of about 19, from one record set you published
- `minimal-any yes`: an ANY query over UDP gets one RRset, as RFC 8482 allows (here the SOA, 117 octets)
- `dig` 9.20 sends ANY over TCP unless told `+notcp`; an attacker's spoofed queries cannot use TCP
- RFC 5358 describes attackers publishing a large record and reflecting it; any large RRset of yours (DNSKEY, TXT, long A lists) serves as well: know which ones you have

---
<!-- _class: dense -->
## Open Resolvers

- **An open resolver** answers recursive queries from anyone on the Internet: a reflector, and a target for cache poisoning attempts
- RFC 5358 (BCP 140): "By default, nameservers SHOULD NOT offer recursive service to external networks"
- Authorise clients by address (ACL), by interface, or by TSIG/SIG(0) for roaming clients
- **Keep authoritative and recursive service separate** as much as practical: an authoritative server must answer everyone; a resolver should answer only its own users

Test from **outside** your network: from inside, your own ACL lets you in.

```text
$ dig @<your resolver> www.teamNN.example      # from another network
;; ->>HEADER<<- opcode: QUERY, status: REFUSED
```

---
<!-- _class: dense table-compact -->
## BIND 9.20 Access Controls

| Option | Controls | Default (BIND 9.20 ARM) |
|---|---|---|
| `recursion` | recursion and caching for clients | `yes` |
| `allow-query` | who may query at all | any |
| `allow-query-cache` | who may get answers from the cache | `allow-recursion`, else `localnets; localhost;` |
| `allow-recursion` | who may ask for recursion | `allow-query-cache`, else `allow-query`, else `localnets; localhost;` |
| `allow-transfer` | who may transfer zones | none (BIND 9.18: any) |
| `allow-update` | who may send dynamic updates | none |

- **The trap:** set `allow-query { any; }` for an authoritative zone and leave recursion on, and `allow-recursion` inherits `any`: an open resolver
- Debian 13's `named.conf.options` sets only `directory`, so recursion is on for **localnets**: every host on the same subnets as the server

---
<!-- _class: dense -->
## The localnets Trap (Lab 6.1)

Debian's defaults, queried from a neighbouring team's VM on the same lab subnet:

```text
$ dig @192.0.2.30 www.team01.example      # the authoritative VM
;; flags: qr aa rd ra; ...                    # ra: recursion offered
$ dig @192.0.2.30 version.bind TXT CH +short
"9.20.30-1~deb13u1-Debian"
```

After the Module 6 configuration (the VM still answers for its own zone, `qr aa rd`):

```text
$ dig @192.0.2.30 www.example.org
;; ->>HEADER<<- opcode: QUERY, status: REFUSED
; EDE: 20 (Not Authoritative): (recursion disabled)
$ dig @192.0.2.10 www.team01.example      # the resolver: also REFUSED
```

Zone transfers failed even under the defaults: BIND 9.20's `allow-transfer` is none.

---
<!-- _class: dense -->
## Response Rate Limiting (RRL)

BIND's `rate-limit` stops an **authoritative** server from being a useful reflector:

- Identical responses to one client **netblock** (/24 for IPv4, /56 for IPv6) share a token bucket: `responses-per-second` credits per second, tracked over `window` seconds
- Over the limit, responses are **dropped**, but every `slip`-th one (default 2) gets a small reply: **TC=1** (no cookie in the query) or **BADCOOKIE** (cookie present). A real client retries over TCP or with the cookie and gets through
- Separate limits for NXDOMAIN (`nxdomains-per-second`), NODATA, referrals and errors; `all-per-second` as a blunt cap
- **Not limited:** TCP, and queries with a valid server cookie
- `log-only yes` to measure first; RRL is meant for authoritative servers, and on a resolver it can slow mail servers and browsers (BIND ARM)

```text
rate-limit { responses-per-second 5; window 5; slip 2; log-only no; };
```

---
<!-- _class: dense table-compact -->
## RRL in the Lab (Lab 6.3)

`dnsperf` from the resolver VM to the team's own authoritative VM, 50 queries/s for 10 s, `big.team01.example TXT`. The amplification is gone: a 47-octet query now earns, on average, a 72-octet reply.

| | log-only | enforcing |
|---|---|---|
| Queries sent | 500 | 405 |
| Answered | 500 | 205 (mostly small TC replies) |
| Lost (dropped) | 0 | 200 |
| Average response | 1077 octets | 72 octets |

```text
rate-limit: info: would limit responses to 192.0.2.0/24 for big.team01.example IN TXT (7738b09b)
rate-limit: info: limit responses to 192.0.2.0/24 for big.team01.example IN TXT (7738b09b)
     200 responses dropped for rate limits
     200 responses truncated for rate limits
```

---
<!-- _class: dense -->
## What a Real Client Sees

While the stream above is being limited:

```text
$ dig @192.0.2.30 big.team01.example TXT +nocookie +ignore
;; flags: qr aa tc rd ad; QUERY: 1, ANSWER: 0, ...      # slipped: truncated, retry over TCP

$ dig @192.0.2.30 big.team01.example TXT
;; BADCOOKIE, retrying.
;; flags: qr aa rd; QUERY: 1, ANSWER: 4, ...
; COOKIE: 07a9bd7376084cc7010000006ad8b65658c7abf1090c5ddf (good)
```

- A client without cookies gets a truncated reply and switches to TCP (`+ignore` stopped `dig` doing so here)
- A client with a cookie gets BADCOOKIE with a server cookie, retries, and is then exempt
- The attacker never sees these replies; the victim whose address was forged receives only the small slipped ones

---
<!-- _class: dense table-compact -->
## Query Floods and Random Subdomains

- **Direct floods:** more queries than the server can answer; the answer is capacity, anycast (Module 5) and upstream filtering
- **Random-subdomain ("water torture"):** `x7f3k.victim.example`, `q9a2.victim.example`, ... through many resolvers; nothing is cached, so every query reaches the victim's servers and the resolvers wait on them
- **NXNSAttack** (2020): referrals naming non-existent name servers made resolvers send a storm of fetches (over 1620x packet amplification in the paper); fixed in BIND 9.11.19, 9.14.12, 9.16.3

Resolver limits in BIND 9.20 [defaults]; RFC 8198 (Module 7) also answers random names in signed zones from cached NSEC records:

| Option | Limits |
|---|---|
| `fetches-per-zone` [0, no limit] | simultaneous fetches to one zone; then drop or SERVFAIL |
| `fetches-per-server` [0, no limit] | simultaneous fetches to one server; adjusted to congestion when set |
| `clients-per-query` [10] | clients waiting for the same name and type |
| `max-recursion-queries` [50] | iterative queries for one lookup |

---
<!-- _class: dense -->
## Response Size and Fragmentation

- Large UDP responses fragment; fragments are often lost or filtered, and forged fragments are an off-path cache-poisoning vector (RFC 9715)
- **BIND 9.20:** `edns-udp-size` and `max-udp-size` default to **1232** octets; larger answers are truncated and the client retries over TCP
- **Unbound 1.26:** `edns-buffer-size` and `max-udp-size` default to 1232 ("DNS Flag Day 2020 recommendation", unbound.conf(5))
- RFC 9715 (Informational, January 2025) describes avoiding IP fragmentation in DNS over UDP; it gives 1400 as the RECOMMENDED maximum DNS/UDP payload, smaller values allowed
- TCP must work: RFC 7766 requires TCP support from all general-purpose DNS implementations. Firewalls that block TCP/53 break large answers, DNSSEC and RRL's slip

Smaller UDP answers also limit what an amplification attack can get from one query.

---
<!-- _class: section-divider -->
# 4 · Hardening Servers

---
<!-- _class: dense -->
## Authoritative Server Checklist

- **No recursion:** `recursion no;` (also blocks cache snooping)
- **Transfers only to your secondaries,** authenticated with TSIG (section 5); `allow-update { none; }` unless you use dynamic DNS with keys
- **Hide the software version:** `version none; hostname none; server-id none;` (this hides the string, not the bugs: patch anyway)
- **Smaller answers:** `minimal-responses yes; minimal-any yes;`
- **Rate limiting:** `rate-limit { ... };`, tested with `log-only yes` first
- **Hidden primary** (Module 5): the server that holds the signing keys and accepts updates is not one of the public name servers
- **Sign the zone** (Module 7), and monitor what the world sees: SOA serials, NS and DS at the parent, DNSSEC expiry
- **Patch:** follow your vendor's security advisories (ISC, NLnet Labs, CZ.NIC, PowerDNS)

---
<!-- _class: dense -->
## Authoritative Configuration (Lab Kit)

```text
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };            // public data
    allow-transfer { none; };        // per zone: a TSIG key (Lab 6.4)
    allow-update { none; };
    version none; hostname none; server-id none;
    minimal-responses yes;
    minimal-any yes;
    rate-limit { responses-per-second 5; window 5; slip 2; log-only yes; };
};
```

- `labs/module06/auth/named.conf.options` replaces Debian's file (which sets only `directory`)
- The lab rate is low on purpose, so a small, capped load shows the limit; production values depend on your traffic (start with `log-only yes` and read the logs)
- `version none` answers `version.bind` with an empty answer instead of the version string

---
<!-- _class: dense -->
## Recursive Resolver Checklist

- **Only your clients:** `allow-query`, `allow-query-cache` and `allow-recursion` set to an ACL of your networks
- **Validate:** `dnssec-validation auto;` (BIND's default; Module 7)
- **Send less:** QNAME minimisation (RFC 9156), on by default in BIND and Unbound
- **Cookies:** DNS Cookies to authoritative servers and to clients (RFC 7873, 9018)
- **Limit work per query and per zone:** `fetches-per-zone`, `fetches-per-server`, `max-recursion-queries`
- **Small UDP answers:** keep the 1232-octet default; allow TCP/53
- **Filter known-bad names:** RPZ (section 6)
- **Encrypt the client hop:** DoT, DoH, DoQ and DDR are Module 8
- **Keep the OS patched** too: SAD DNS was a kernel flaw

---
<!-- _class: dense -->
## Resolver Configuration (Lab Kit)

```text
acl "trusted" { localhost; 192.0.2.10; 192.0.2.30; };   // your VMs
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { trusted; };  allow-query-cache { trusted; };  allow-recursion { trusted; };
    allow-transfer { none; };  allow-update { none; };
    version none; hostname none; server-id none;
    dnssec-validation auto;
    validate-except { "example"; };     // lab TLD not in the real root; Module 7 removes this
    qname-minimization relaxed;  send-cookie yes;  answer-cookie yes;   // BIND 9.20 defaults
    minimal-responses yes;
    fetches-per-zone 100 fail;
};
zone "example" { type static-stub; server-addresses { 192.0.2.53; }; };   // the registry
```

Without `validate-except`, BIND rejected the lab zone ("parent indicates it should be secure"): the real root proves that `example.` does not exist.

---
<!-- _class: dense -->
## QNAME Minimisation (RFC 9156)

Without it, the resolver sends the full name to every server on the way down. With it, each server is asked only about the next label below its zone:

```text
 to the root:        example. NS ?           (not www.team01.example A)
 to example.:        team01.example. NS ?
 to team01.example:  www.team01.example. A ?
```

- RFC 9156 (Proposed Standard, November 2021) obsoletes the Experimental RFC 7816
- The minimised QTYPE can be any type whose data lives below the zone cut; **A or AAAA** are good choices because they blend in; NS is still allowed
- Names with many (random) labels cost a query per label: RFC 9156 §2.3 lets resolvers add several labels per step, with a cap on the steps (MAX_MINIMISE_COUNT, RECOMMENDED 10)
- **BIND 9.20:** `qname-minimization relaxed` by default, NS queries on the way down, full query after NXDOMAIN or errors; `strict` follows the RFC 7816 algorithm to the letter
- **Unbound 1.26:** `qname-minimisation: yes` by default, QTYPE A where possible

---
<!-- _class: dense -->
## QNAME Minimisation in the Lab (Lab 6.2)

The resolver's queries for one lookup of `www.team01.example` (from the capture above):

```text
192.0.2.10 -> 192.0.2.53   NS    team01.example       # the registry: only the delegation
192.0.2.10 -> 192.0.2.30   A     www.team01.example   # the team's server: the full name
```

And the random names of Lab 6.5 (`<random>.t.team01.example`):

```text
192.0.2.10 -> 192.0.2.30   NS    t.team01.example     -> NXDOMAIN
192.0.2.10 -> 192.0.2.30   TXT   jnindm235lzg....t.team01.example   -> NXDOMAIN (each name)
```

- The NXDOMAIN for `t.team01.example` would, by RFC 8020, prove that nothing exists below it, but relaxed mode sends the full query anyway
- So random-subdomain floods still reach the authoritative server; with a signed zone, RFC 8198 lets the resolver answer them itself

---
<!-- _class: dense -->
## DNS Cookies (RFC 7873, RFC 9018)

```text
 client ── query + client cookie (8 octets) ──────────────> server
 client <── answer + client cookie + server cookie (8-32) ── server
 client ── query + client cookie + server cookie ─────────> server   (verified)
```

- An EDNS option (code 10). A forged answer must echo the 64-bit **client cookie**; compare TCP's 32-bit sequence number (RFC 7873 §1)
- The **server cookie** proves the client has talked to the server before: such clients are not spoofed, so BIND exempts them from RRL
- **RFC 9018:** a 16-octet server cookie: version 1, reserved, a timestamp, and a SipHash-2-4 hash, keyed with the server secret, of the client cookie, those fields and the client's IP address. Servers in an anycast set share the secret and accept each other's cookies
- Timestamp: accepted from 1 hour in the past to 5 minutes in the future; the server issues a new cookie when the client's is more than 30 minutes old
- **BADCOOKIE** (RCODE 23, "Bad/missing Server Cookie"): the client retries with the server cookie it was sent
- Cookies are returned only to the address they came from, so they cannot track users across networks; a client MUST use a different client cookie for each server address (RFC 9018 §3)

---
<!-- _class: dense -->
## Cookies on the Wire (Lab 6.2)

```text
$ dig @192.0.2.10 www.team01.example +noall +comments
; COOKIE: b36ba22ad8fd54b8010000006ad8b63b675b49e38adcd59a (good)
```

`dig` prints its 8-octet client cookie followed by the 16-octet server cookie (`01` = version 1); `(good)` means the client cookie came back. The authoritative server's query log marks each query from the resolver:

```text
query: www.team01.example IN A -E(0)DCK (192.0.2.30)     # K: cookie, no valid server cookie yet
query: mail.team01.example IN A -E(0)DCV (192.0.2.30)    # V: valid server cookie
```

The first query to a server carries only the client cookie; from the second on, the resolver echoes the server cookie it was given (`V`).

---
<!-- _class: dense table-compact -->
## DNS Cookie Options

| BIND 9.20 option | Default | Effect |
|---|---|---|
| `send-cookie` | yes | the resolver sends cookies upstream |
| `answer-cookie` | yes | the server answers with cookies |
| `require-server-cookie` | no | yes: UDP clients that send a cookie but no valid server cookie get BADCOOKIE (cookie-less clients are not affected) |
| `nocookie-udp-size` | 4096 | cap on UDP answers to clients without a valid server cookie |
| `cookie-secret` | random at start | share it across an anycast set (128-bit hex) |
| `require-cookie` (per `server`) | no | yes: retry over TCP when that server's UDP answer has no cookie |

- Unbound 1.26: `answer-cookie: no` by default
- `require-server-cookie yes` lowers amplification (BADCOOKIE is smaller than a full answer) but costs every new client an extra round trip; RRL slips BADCOOKIE rather than TC to clients that sent a cookie

---
<!-- _class: dense -->
## Pointers: DNSSEC and Encryption

<div class="columns">
<div>

### DNSSEC (Module 7)
- The only defence that checks the **data**, whatever the path
- Validation on your resolver: `dnssec-validation auto;`
- Signing your zones protects every validating resolver's users
- RFC 8198 aggressive caching: NSEC proofs answer random names locally (`synth-from-dnssec`, default yes)
- Limits on validation work per fetch (experimental in BIND 9.20): `max-validations-per-fetch` (16), `max-validation-failures-per-fetch` (1)

</div>
<div>

### Encrypted DNS (Module 8)
- DoT, DoH and DoQ protect the stub-to-resolver hop from observation and tampering
- DDR and DNR let clients find your encrypted resolver
- Zone transfers over TLS (RFC 9103) hide zone contents in transit
- Encryption does not check the data: a lying resolver is still believed

</div>
</div>

---
<!-- _class: section-divider -->
# 5 · TSIG and Zone Transfers

---
<!-- _class: dense table-compact -->
## TSIG (RFC 8945)

- A **shared secret** and an HMAC over the message and the time it was signed; the response is signed with the same key
- **Time window:** the Fudge field; RFC 8945 RECOMMENDS 300 seconds. Keep clocks in sync (NTP)
- **One key per pair:** "Secrets SHOULD NOT be shared by more than two entities"; the secret SHOULD be at least as long as the hash output
- **Authenticates the transaction, not the data:** a compromised primary still sends bad data with a good signature

| Algorithm | Implementation | Use |
|---|---|---|
| hmac-sha256 | MUST | RECOMMENDED |
| hmac-sha1 | MUST | NOT RECOMMENDED |
| HMAC-MD5.SIG-ALG.REG.INT | MAY | MUST NOT |
| hmac-sha384, hmac-sha512, gss-tsig | MAY | MAY |

RFC 8945 (2020) is an Internet Standard (STD 93) and obsoletes RFC 2845 and RFC 4635.

---
<!-- _class: dense -->
## Making a Key

```text
$ sudo sh -c 'umask 077; tsig-keygen -a hmac-sha256 teamNN-xfr > /etc/bind/teamNN-xfr.key'
$ sudo chown root:bind /etc/bind/teamNN-xfr.key; sudo chmod 640 /etc/bind/teamNN-xfr.key
$ sudo sed 's/secret ".*"/secret "(hidden)"/' /etc/bind/teamNN-xfr.key
key "teamNN-xfr" {
        algorithm hmac-sha256;
        secret "(hidden)";
};
```

- `tsig-keygen` (Debian package `bind9`) prints a `key` statement: the default algorithm is hmac-sha256 with a 256-bit random secret
- Name keys after the pair of servers, not the zone, so the same name never means two secrets
- Keep the key in its own file, readable by `named` only, and `include` it; never show it on a projector or paste it into a world-readable `named.conf`, a ticket or a Git repository
- Copy it to the other server over SSH, not by e-mail or chat
- Each team generates its own key during the lab: no shared or fixed secrets

---
<!-- _class: dense -->
## TSIG-Protected Transfers in BIND

<div class="columns">
<div>

```text
// primary: named.conf.local
include "/etc/bind/teamNN-xfr.key";
zone "teamNN.example" {
  type primary;
  file "/var/lib/bind/db.teamNN.example";
  allow-transfer { key "teamNN-xfr"; };
  also-notify { 192.0.2.10
                key "teamNN-xfr"; };
};
```

</div>
<div>

```text
// secondary
include "/etc/bind/teamNN-xfr.key";
zone "teamNN.example" {
  type secondary;
  primaries { 192.0.2.30
              key "teamNN-xfr"; };
  file "/var/cache/bind/teamNN.example.db";
};
```

</div>
</div>

- `key` in an ACL: the request must be signed with that key (combine with addresses if needed)
- `primaries ... key`: SOA queries, NOTIFY and transfer requests are signed
- Debian's AppArmor profile lets `named` write only under `/var/cache/bind` and `/var/lib/bind`: keep secondary zone files there

---
<!-- _class: dense -->
## When TSIG Fails (Lab 6.4)

```text
$ sudo dig @192.0.2.30 team01.example AXFR                  # no key
; Transfer failed.
$ sudo dig @192.0.2.30 -k wrong.key team01.example AXFR     # right name, wrong secret
team01-xfr.  0  ANY  TSIG  hmac-sha256. 1792587361 300 0 51562 BADSIG 0
$ sudo dig @192.0.2.30 -k other.key team01.example AXFR     # unknown key name
team99-xfr.  0  ANY  TSIG  hmac-sha256. 1792587361 300 0 23778 BADKEY 0
```

The primary's log:

```text
security: error: client 192.0.2.10#54099 (team01.example): zone transfer 'team01.example/AXFR/IN' denied
security: error: client 192.0.2.10#54111: request has invalid signature: TSIG team01-xfr: tsig verify failure (BADSIG)
```

- BADKEY, BADSIG and BADTIME come with RCODE NOTAUTH; BADTIME: clocks differ by more than the fudge (`300`)
- `dig -k` on a key it cannot read prints "permission denied" and **sends the query unsigned**: use `sudo dig`

---
<!-- _class: dense -->
## Beyond TSIG

- **Rotate keys:** add the new key on both sides, switch the ACL and `primaries`, then remove the old one; after any suspected compromise, at once
- **Transfers are not secret with TSIG:** the zone crosses the network in cleartext. Use zone transfers over TLS (RFC 9103, Module 8) when the contents matter, for example a TLD zone listing every registered name
- **TSIG is not DNSSEC:** a secondary that receives a signed zone can serve it unchanged; validating resolvers check the data end to end (Module 7)
- **Other mechanisms:** SIG(0) (RFC 2931) uses public keys; GSS-TSIG (RFC 3645) uses Kerberos; catalog zones (RFC 9432) carry the zone list to secondaries
- **Monitor:** `xfer-out` log lines show who transferred which serial; alert on denied transfers and on serial mismatches between primary and secondaries

---
<!-- _class: section-divider -->
# 6 · RPZ, Tunnelling and Detection

---
<!-- _class: dense -->
## Response Policy Zones (RPZ)

- A resolver loads policy from **ordinary DNS zones** and rewrites answers: block, redirect to a walled garden, or let through
- Policy zones are transferred like any zone (NOTIFY, AXFR/IXFR, with TSIG or address ACLs), so one feed can serve many resolvers
- **Status:** not an RFC. The specification is an Internet-Draft, `draft-vixie-dnsop-dns-rpz-00` (individual submission, Informational, June 2018), which has expired; the datatracker lists it as replacing `draft-ietf-dnsop-dns-rpz-00` (March 2017)
- **Implementations:** BIND (`response-policy`), Unbound (`rpz:` clauses), among others; check your software's documentation for which triggers it supports
- **Policy and law:** filtering users' DNS is a decision with legal and customer consequences; publish what you filter and why (an RPS, Module 8)

---
<!-- _class: dense table-compact -->
## Triggers and Actions

<div class="columns">
<div>

| Trigger | Owner name (example) |
|---|---|
| QNAME | `malware.example` |
| Response IP | `32.66.2.0.192.rpz-ip` |
| NSDNAME | `ns.bad.example.rpz-nsdname` |
| NSIP | `24.0.2.0.192.rpz-nsip` |
| Client IP | `24.0.2.0.192.rpz-client-ip` |

</div>
<div>

| Action | Record |
|---|---|
| NXDOMAIN | `CNAME .` |
| NODATA | `CNAME *.` |
| PASSTHRU | `CNAME rpz-passthru.` |
| DROP | `CNAME rpz-drop.` |
| TCP-only | `CNAME rpz-tcp-only.` |
| Local data | any records |

</div>
</div>

- QNAME matches the query name and CNAME targets; Response IP an address in the answer (here 192.0.2.66/32); NSDNAME and NSIP the authoritative servers; Client IP the asker
- Addresses are written as prefix length, then the octets in reverse, as in `in-addr.arpa`
- Local data example: `phish.example CNAME walled-garden.example.`

---
<!-- _class: dense -->
## RPZ in BIND

```text
options {
    response-policy {
        zone "local.rpz";                        // your overrides, checked first
        zone "feed.rpz.test" ede filtered;       // the provider's feed
    };
};
zone "feed.rpz.test" { type secondary; primaries { 192.0.2.53; };
    file "/var/cache/bind/feed.rpz.test.db"; allow-query { localhost; }; };
zone "local.rpz" { type primary; file "/etc/bind/db.local.rpz"; allow-query { localhost; }; };
```

- **Order matters:** the first zone listed that matches wins, so a local PASSTHRU can override a feed
- `ede filtered` adds Extended DNS Error 17 (RFC 8914) to rewritten answers, so users and helpdesks can see why
- By default BIND rewrites only queries with RD=1, recurses before applying the policy (`qname-wait-recurse yes`), and skips DNSSEC-signed answers to DO=1 queries unless `break-dnssec yes`
- Rewritten answers have a TTL of at most 5 seconds (`max-policy-ttl`); rewrites are logged in the `rpz` category and counted in `rndc stats`

---
<!-- _class: dense -->
## RPZ in the Lab (Lab 6.5)

```text
$ dig @192.0.2.10 malware.example          # feed: CNAME .
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN
; EDE: 17 (Filtered)
$ dig @192.0.2.10 phish.example +noall +answer   # feed: walled garden
phish.example.          5   IN  CNAME  walled-garden.example.
walled-garden.example.  60  IN  A      192.0.2.68
$ dig @192.0.2.10 tracker.example +short   # feed: NODATA; local.rpz: PASSTHRU
192.0.2.69
$ dig @192.0.2.10 c2.team01.example        # answer 192.0.2.66 matches an rpz-ip trigger
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN
$ dig @192.0.2.10 malware.example +dnssec +short   # DO=1, signed example.: not rewritten
192.0.2.66
```

```text
rpz: info: client 192.0.2.30#49702 (c2.team01.example): rpz IP NXDOMAIN rewrite c2.team01.example/A/IN via 32.66.2.0.192.rpz-ip.feed.rpz.test
```

---
<!-- _class: dense -->
## DNS Tunnelling and Covert Channels

- **How:** a client encodes data in query names under a domain the attacker runs (`<encoded data>.t.attacker.example`); the attacker's server answers with data in TXT, NULL or other records. Each label holds up to 63 octets, each name up to 255 (RFC 1035 §2.3.4)
- **Why it works:** the client only needs to reach a resolver; the resolver carries the traffic to the attacker's server for it
- **Uses:** moving data out of a network, or commands into it, where only DNS is allowed out

Signs on the resolver or in captures:

- Many **unique names under one parent domain**, few repeats
- **Long, random-looking labels** (base32, base64, hex)
- Unusual **types** (TXT, NULL) and many **NXDOMAIN** answers
- Steady query volume to one domain from one or a few clients

Responses: block the domain with RPZ, rate-limit the clients, and stop clients from using DNS servers other than yours (egress filtering of port 53, and of DoT and DoH, Module 8).

---
<!-- _class: dense -->
## Spotting the Pattern (Lab 6.5)

30 TXT queries for random base32 labels under `t.team01.example`, mixed with 5 ordinary lookups, summarised from a capture on the resolver:

```text
$ sh labs/module06/tools/dns-signs.sh signs.pcap 192.0.2.10
parent                   queries  unique max-label  nxdom  qtypes
t.team01.example              30      30        32     30  16
team01.example                 5       3         4      2  1
(qtypes are numbers: 1 A, 2 NS, 16 TXT, 28 AAAA)
```

- `t.team01.example`: every name unique, 32-character labels, all TXT, all NXDOMAIN
- `team01.example`: a few names, short labels, repeats; the two NXDOMAIN are the minimised `t.team01.example` query and the RPZ-blocked `ftp`
- Tunnels with real data look like the first line; random-subdomain floods too, but at a much higher rate and from many resolvers

---
<!-- _class: dense table-compact -->
## Logging and Detection Signs

| Sign | Where BIND shows it |
|---|---|
| Refused queries (probing, open-resolver scans) | `rndc stats`: "auth queries rejected", "recursive queries rejected" (not logged at info) |
| Reflection through your server | `rate-limit` log category; "responses dropped/truncated for rate limits" |
| Transfer attempts | `security`: "zone transfer ... denied"; `xfer-out` for successes |
| TSIG problems | `security`: "tsig verify failure (BADSIG)", BADKEY, BADTIME |
| Random-subdomain flood | NXDOMAIN counters rising; `spill` category when fetch limits drop queries |
| Policy hits | `rpz` category; "response policy zone rewrites" in `rndc stats` |
| Tunnelling | query logs or captures: unique long labels under one parent |

The lab's `common/named.conf.logging` sends these categories to `/var/log/named/security.log`. Debian 13's BIND is built with dnstap for full query capture; dashboards, alerting and incident response are Module 11.

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

- **Your two Debian 13 VMs**, used again in Modules 7 and 8: the **authoritative** server for `teamNN.example` (also the client in these labs) and the **resolver**; BIND 9.20 on both
- **Registry server** (instructor): serves the lab TLD `example.` and the RPZ feed `feed.rpz.test` (lab sheet address; 192.0.2.53 on the slides)
- **Packages:** `bind9`, `bind9-utils`, `bind9-dnsutils`, `dnsperf`, `tcpdump`, `tshark`
- **Lab kit:** `labs/module06/`: `auth/`, `resolver/`, `common/named.conf.logging`, `tools/dns-signs.sh`
- **Addresses** on the slides: authoritative 192.0.2.30, resolver 192.0.2.10, a neighbouring team 192.0.2.31; use your lab sheet
- **Logs:** `sudo install -d -o bind -g bind /var/log/named` on both VMs, then include `named.conf.logging`
- **After each change:** `sudo named-checkconf` and `sudo rndc reconfig` (or `rndc reload` for zone data); if a change does not take effect, `sudo systemctl restart named`

---
<!-- _class: dense -->
## Lab Rules: Contained Testing

These labs generate attack-like traffic. The rules are not optional:

- **Only your own VMs** and the instructor's lab servers, only on the lab network. Never a third-party host, never the Internet
- **Load tests are small and capped:** `dnsperf -Q 50 -l 10` (50 queries per second for 10 seconds), from your resolver VM to your own authoritative VM only
- **No spoofed source addresses**, no tools beyond the ones on the slides (`dig`, `dnsperf`, `tcpdump`, `tshark`, `rndc`)
- **Cache poisoning is observed, not attempted:** you look at the defences (ports, IDs, cookies, QNAME minimisation) in your own captures
- Testing someone else's servers without written permission may be illegal in your country, even "just a scan"

If something behaves unexpectedly, stop the load and ask the instructor.

---
<!-- _class: dense -->
## Lab 6.1: Close the Open Doors (20 min)

1. From the neighbouring team's VM (ask them, or use the instructor's): `dig @<your auth VM> www.teamNN.example`; note the `ra` flag. Then `dig @<your auth VM> version.bind TXT CH +short` and `dig @<your auth VM> teamNN.example AXFR`
2. On the authoritative VM: install `auth/named.conf.options` as `/etc/bind/named.conf.options`; set up logging; `named-checkconf`; `rndc reconfig`
3. On the resolver: install `resolver/named.conf.options` and `resolver/named.conf.local` (the `example` static-stub); put your two addresses in `acl "trusted"`; check and reconfigure
4. Repeat step 1 against both VMs from the neighbour; then query the resolver from your own authoritative VM
5. On both VMs: `sudo rndc stats`; `sudo grep 'rejected' /var/cache/bind/named.stats`

> **Checkpoint:** the neighbour gets REFUSED for recursion on both VMs and no version string; your own VM still resolves through your resolver; the rejected counters went up

---
<!-- _class: dense -->
## Lab 6.2: Watch the Resolver Defend Itself (15 min)

1. On the resolver: `sudo rndc flush`, then `sudo tcpdump -i any -n -w up.pcap udp port 53`
2. From the authoritative VM: `dig @<resolver> www.teamNN.example`, then `mail.` and `ftp.`; stop the capture
3. List the resolver's queries:
   `tshark -r up.pcap -Y 'ip.src==<resolver> && dns.flags.response==0 && (ip.dst==<auth VM> || ip.dst==<registry>)' -T fields -e ip.dst -e udp.srcport -e dns.id -e dns.qry.type -e dns.qry.name -e dns.opt.cookie.client -e dns.opt.cookie.server` (the address filter hides the resolver's own root and trust-anchor queries)
4. On the authoritative VM: `sudo rndc querylog on`; on the resolver `sudo rndc flush`; repeat step 2; read the `K` and `V` flags in the log (`journalctl -u named`); `sudo rndc querylog off`
5. From the authoritative VM: `dig @<resolver> www.teamNN.example`; copy the COOKIE value; repeat with `+cookie=<value>`

> **Checkpoint:** you can point to a different source port and ID on every query, the minimised NS query to the registry, and the server cookie appearing once learned

---
<!-- _class: dense -->
## Lab 6.3: Rate Limiting Under Load (20 min)

1. Add the `big` TXT records from `auth/db.additions` to your zone; raise the serial; `rndc reload teamNN.example`
2. From the resolver VM: `dig @<auth VM> big.teamNN.example TXT +qr`; compare QUERY SIZE with MSG SIZE; try `teamNN.example ANY +notcp`
3. `echo "big.teamNN.example TXT" > big.txt`, then, with RRL in `log-only yes` mode:
   `dnsperf -s <auth VM> -e -d big.txt -l 10 -Q 50`; read `security.log` on the authoritative VM
4. Set `log-only no;`, `rndc reconfig`, and run the same `dnsperf` again; `rndc stats` and `grep 'rate limits' /var/cache/bind/named.stats`
5. While a third run is going, from the resolver VM: `dig ... +nocookie +ignore`, then `dig` with cookies (the default)

> **Checkpoint:** log-only answers everything at about 1077 octets; enforcing drops about half, slips the rest as small replies (about 72 octets on average); `dig` with a cookie gets BADCOOKIE, retries and gets the full answer

---
<!-- _class: dense -->
## Lab 6.4: TSIG-Protected Zone Transfer (20 min)

1. On the authoritative VM: `sudo sh -c 'umask 077; tsig-keygen -a hmac-sha256 teamNN-xfr > /etc/bind/teamNN-xfr.key'`; `sudo chown root:bind /etc/bind/teamNN-xfr.key; sudo chmod 640 /etc/bind/teamNN-xfr.key`
2. Include the key in `named.conf.local`; add the two lines from `auth/zone-tsig.snippet` to your zone (Module 3 Lab 3.4 removed its address-only lines); check, `rndc reconfig`
3. Copy the key to the resolver VM: `sudo cat /etc/bind/teamNN-xfr.key | ssh <resolver> 'sudo sh -c "umask 077; cat > /etc/bind/teamNN-xfr.key; chown root:bind /etc/bind/teamNN-xfr.key; chmod 640 /etc/bind/teamNN-xfr.key"'`. On the resolver, **as root**: `sudo dig @<auth VM> teamNN.example AXFR` with no key, with `-k /etc/bind/teamNN-xfr.key`, with a second key of the same name (`tsig-keygen teamNN-xfr > wrong.key`) and with a key of another name (`tsig-keygen teamNN-other > other.key`)
4. Add `resolver/named.conf.secondary` to the resolver's `named.conf.local`; reconfigure; read `xfer-in` in its `security.log`
5. On the authoritative VM: add a record, raise the serial, `rndc reload teamNN.example`; watch the NOTIFY and the new transfer arrive
6. **Remove the secondary zone** from the resolver and reconfigure: Module 7 needs the resolver to resolve your zone, not serve it

> **Checkpoint:** no key gives "Transfer failed", a wrong secret BADSIG, an unknown name BADKEY, the right key the whole zone; the secondary logs "transferred serial <your new serial>: TSIG 'teamNN-xfr'"

---
<!-- _class: dense -->
## Lab 6.5: RPZ and Spotting a Tunnel (15 min)

1. Before: `dig @<resolver> malware.example +short` (and `phish.example`, `tracker.example`); add `c2` from `auth/db.additions` to your zone
2. On the resolver: add `resolver/named.conf.rpz` to `named.conf.local`, the `response-policy` block from `named.conf.rpz-options` to `options`, and `db.local.rpz` (set `NN`); check and reconfigure
3. Repeat step 1 and `dig @<resolver> c2.teamNN.example`; then `dig @<resolver> malware.example +dnssec` and compare; read the `rpz:` lines in `security.log`
4. On the resolver: `sudo tcpdump -i any -n -w signs.pcap udp port 53`, while the authoritative VM sends 30 random names:
   `for i in $(seq 30); do dig @<resolver> $(head -c 20 /dev/urandom | base32 | tr -d = | tr A-Z a-z).t.teamNN.example TXT +short; done`
5. `sh labs/module06/tools/dns-signs.sh signs.pcap <resolver>`

> **Checkpoint:** malware NXDOMAIN with EDE 17 (but its real address with `+dnssec`, because `example.` is signed), phish redirected, tracker allowed by your local zone, c2 blocked by its address; the summary shows `t.teamNN.example` with 30 unique long labels

**Discussion:** which of these signs would you alert on for a resolver serving 100,000 users, and at what threshold?

<!--
Step 4 sends 30 queries at the pace of dig, to the team's own servers only. The names exist nowhere, so every one is NXDOMAIN; with BIND's relaxed QNAME minimisation the resolver still sends each full name upstream after the NXDOMAIN for t.teamNN.example (see the QNAME minimisation slide). Real tunnels use names under a domain the attacker controls, with answers carrying data.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 3833: threat analysis; RFC 5452: forged answers
- RFC 5358 (BCP 140): open resolvers; RFC 2827 (BCP 38), RFC 3704 (BCP 84)
- RFC 7873, 9018: DNS Cookies; RFC 9156: QNAME minimisation
- RFC 8945 (STD 93): TSIG; RFC 2931: SIG(0); RFC 3645: GSS-TSIG; RFC 9432: catalog zones
- RFC 8482: ANY; RFC 9715: fragmentation; RFC 7766: TCP
- RFC 8020, 8198: NXDOMAIN cut, aggressive caching; RFC 8914: EDE
- RFC 6811: BGP origin validation; RFC 2181 §5.4.1; RFC 1035 §2.3.4
- draft-vixie-dnsop-dns-rpz-00 (expired); draft-vixie-dnsext-dns0x20-00 (expired)
- CVE-2008-1447, CVE-2020-8616, CVE-2020-25705, CVE-2023-50387, CVE-2023-50868; CERT/CC VU#800113; CISA ED 19-01
- BIND 9.20 ARM: access control, `rate-limit`, `response-policy`, TSIG; unbound.conf(5); IANA DNS parameters (RCODEs, EDNS options, EDE codes)

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>dig @s name +qr          # sizes
dig @s version.bind TXT CH
dig @s zone AXFR -k key
tsig-keygen -a hmac-sha256 n
rndc stats; rndc querylog on
dnsperf -s s -e -d f -l 10 -Q 50
tshark -r f.pcap -Y dns -T fields
  -e dns.qry.name
named-checkconf; rndc reconfig
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. Why did source-port randomisation make the Kaminsky attack impractical, and why is it still not enough on its own?
2. Your authoritative server has `allow-query { any; };` and no `recursion` statement. What can a stranger do with it, and what one line fixes it?
3. An RRL-limited server drops some responses and truncates others. What does a legitimate client do with each, and why does a spoofed victim gain little?
4. What does a DNS server cookie prove, and how does BIND treat queries that carry a valid one?
5. A secondary logs `tsig verify failure (BADSIG)` for its transfers. What are the likely causes, and how would BADTIME differ?
6. Your RPZ blocks `malware.example`, but a user with a validating stub and DO=1 still gets an answer. Why?

<!--
Answers:
1. With a random source port per query the attacker must guess about 16 more bits as well as the 16-bit ID; RFC 5452's example goes from a 50% success chance within 7 seconds (one port) to about 116 hours (64,000 ports) at 7,000 packets per second. Not enough because side channels can reveal the port (SAD DNS, CVE-2020-25705), NAT can de-randomise ports, and a determined attacker can still win eventually; only DNSSEC validation checks the data itself.
2. Recursion defaults to yes and allow-recursion inherits allow-query (any), so it is an open resolver: a reflector for amplification attacks and a target for poisoning attempts. Fix: recursion no; (on an authoritative server). On a resolver, set allow-recursion and allow-query-cache to your own clients.
3. Dropped: the client times out and retries. Truncated (TC=1): it retries over TCP, which is not rate limited. With a client cookie, the slipped reply is BADCOOKIE with a server cookie, and the retry with that cookie is exempt. A spoofed victim receives only the slipped small replies (every second one with slip 2) and no large answers, so the amplification is gone.
4. That the client received an earlier response from this server at its address, so the source address is not spoofed (RFC 7873, 9018). BIND does not rate limit such queries (RRL exemption), and nocookie-udp-size, if set lower than max-udp-size, caps only the answers to clients without one.
5. The key name matches but the secret differs: a mistyped or regenerated key on one side. BADTIME means the signature is valid but the time signed is outside the fudge (300 seconds recommended): the clocks are out of sync, fix NTP. All three come with RCODE NOTAUTH.
6. BIND by default does not rewrite answers to DO=1 queries when the name has DNSSEC records in its original zone, because the rewritten answer would not validate (break-dnssec no). If example. is signed, the answer passes through unless break-dnssec yes is set. (In class the registry's example. is signed by the Module 7 policy, so dig +dnssec malware.example passes through while plain dig is rewritten, as Lab 6.5 step 3 shows; c2.teamNN.example is rewritten either way because the team zone is unsigned. If the instructor serves an unsigned example., both are rewritten.)
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
