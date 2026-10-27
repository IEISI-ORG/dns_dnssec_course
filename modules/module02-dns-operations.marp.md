---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 2: DNS Operations - Zones, Records, and Data Management

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Write** a zone file from scratch: directives, the SOA, absolute and relative names, and the record types an organisation needs
- **Configure** A, AAAA, CNAME, MX, TXT, SRV, CAA, HTTPS and PTR records, and the email records SPF, DKIM and DMARC
- **Check** zone files with `named-checkzone`, read its errors, and load zones into BIND 9.20 on Debian 13
- **Explain** the SOA timers and serial, and how secondaries, NOTIFY, AXFR and IXFR keep copies in step
- **Build** forward and reverse zones for IPv4 and IPv6, and say who delegates a reverse zone
- **Evaluate** TTLs for different records and plan a change around them
- **Design** a zone structure, naming conventions and a change procedure for an organisation

---
<!-- _class: dense -->
## Where This Morning Left Off

```text
$ dig @192.0.2.55 www.team01.example                 # Module 1, worked example
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: ...
$ dig @192.0.2.30 www.team01.example +norec
;; communications error to 192.0.2.30#53: connection refused
```

- The registry (192.0.2.53) already delegates `teamNN.example` to your VM 1, and nothing answers there yet
- This afternoon you write the zone, load it into BIND on VM 1, and the same commands return an answer with `aa`
- **Built on top of it later:** a secondary and a resolver on VM 2 (Module 3), BIND in depth (Module 4), hardening (6), signing (7), registration over EPP (9)
- Module 1 promised this module zone files, the SOA, the other record types, PTR records and TTL changes; secondaries, forwarders and resolvers are Module 3

---
<!-- _class: dense table-compact -->
## What Changed Recently

| Then | Now |
|---|---|
| DMARC in RFC 7489 (Informational, 2015), with `pct=` sampling | RFC 9989, 9990, 9991 (Proposed Standards, May 2026): `pct`, `rf`, `ri` removed; `t` and `psd` new; `np` (RFC 9091, 2021) made standard; a DNS tree walk finds the policy |
| SPF in its own record type (99) | TXT only (RFC 7208, 2014): type 99 is "not to use" |
| CAA in RFC 6844 | RFC 8659 (2019) |
| No standard alias at the zone apex; vendor "ALIAS" or "ANAME" | HTTPS and SVCB records in AliasMode (RFC 9460, November 2023) |
| DKIM signed with rsa-sha1, short keys | rsa-sha1 MUST NOT be used; RSA keys MUST be ≥1024 bits, SHOULD be ≥2048 (RFC 8301); Ed25519 (RFC 8463) |
| Older RFCs' names for the two kinds of authoritative server | primary and secondary (RFC 9499); BIND 9.20 writes `type primary` |
| Debian 12's `bind9` shipped `db.local` and other zone files to copy | Debian 13's `bind9` ships none: you write zone files from scratch |

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. Day 1 so far and what changed (4m)
2. Zones as data (7m)
3. Zone file syntax (14m)
4. SOA, serials and loading (9m)
5. Record types (18m)
6. Email records (10m)
7. Reverse DNS (6m)
8. TTL strategy and zone management (7m)
9. Knowledge Check 1: Day 1 quiz, Modules 1-2 (15m)

## Agenda (90 min Lab)

1. Lab 2.1 Write and load your zone (30m)
2. Lab 2.2 Reverse zones and a broken file (25m)
3. Lab 2.3 TTLs and caching (20m)
4. Lab 2.4 Email records (15m)

<!--
Program Facts: knowledge checks take the last 15-30 minutes of Session 3. Day 1's Session 3 is this module, so the theory content is 75 minutes and Knowledge Check 1 (dns_assessment_plan.md: 15 minutes, 15 questions on hierarchy, record types, TTLs and stakeholders) closes the session. The quiz is handed out on paper; it is not in this deck.
-->

---
<!-- _class: section-divider -->
# 1 · Zones as Data

---
<!-- _class: dense -->
## A Zone Is Data and a Server

```text
 /var/lib/bind/db.teamNN.example ──load──> named on VM 1 (primary) ──zone transfer──> VM 2 (secondary, Module 3)
            the file you edit                answers with aa                            a copy, also aa
```

- As in Module 1, a **zone** runs from its **apex** down to the zone cuts; in a zone file the apex is called the **origin** (RFC 9499)
- At the apex: exactly one **SOA** record and the **NS** RRset naming the zone's own servers. Below it: your names. At each cut: NS (and glue) for a child zone
- A **primary** loads the zone from a file; **secondaries** copy it by zone transfer (RFC 9499 terms)
- "we require every zone to be available on at least two servers" (RFC 1034 §4.1): your zone has one server today (`ns1`, VM 1); Module 3 adds a secondary on VM 2
- On Debian 13: zone files in `/var/lib/bind`, where AppArmor lets `named` write (Module 7 signs the zone in place); zone statements in `/etc/bind/named.conf.local`

---
<!-- _class: dense -->
## Parent Side and Child Side

```text
 example. on the registry (192.0.2.53)          teamNN.example on your VM 1 (192.0.2.30)
 teamNN.example.      60 NS  ns1.teamNN.example.   teamNN.example.     60 SOA ns1.teamNN.example. ...
 ns1.teamNN.example.  60 A   192.0.2.30            teamNN.example.     60 NS  ns1.teamNN.example.
   delegation and glue: sent in referrals,         ns1.teamNN.example. 60 A   192.0.2.30
   without aa                                        authoritative: answered with aa
```

- The parent holds the delegation: NS records and glue (and DS in Module 7). The NS records at a cut "are the property of the child zone" (RFC 2181 §6.1): the parent sends them in referrals, without `aa`
- The child holds the authoritative copy of its own NS and addresses, and everything else in the zone
- The two copies must agree (Module 1, Lab 1.3). In Lab 2.1 you compare the registry's view with your zone
- You change the parent's side through the registry (registrar and EPP, Module 9), the child's side in your zone file

---
<!-- _class: dense -->
## Delegating Part of Your Own Zone

```text
; in db.teamNN.example: lab.teamNN.example is run by other servers
lab       IN NS  ns1.lab.teamNN.example.
          IN NS  ns.provider.example.net.
ns1.lab   IN A   192.0.2.40             ; glue: this server is inside the child
www.lab   IN A   192.0.2.41             ; occluded: below the cut, never served
```

- A cut inside your zone works like the registry's: NS records at the child's name, glue for servers inside the child (in-domain glue, RFC 9471)
- Data below the cut stays in your file but is not served: BIND answers `www.lab` with a referral (an **occluded name**, RFC 9499; tested)
- Missing glue is only a warning: `NS 'ns1.lab.teamNN.example' has no REQUIRED GLUE address records`, and the zone still loads. Read every warning
- Zones are cut "at points where a particular organization wants to take over control of a subtree" (RFC 1034 §4.2): section 7 comes back to when to delegate

---
<!-- _class: section-divider -->
# 2 · Zone File Syntax

---
<!-- _class: dense -->
## The Zone File Format

```text
; a comment runs to the end of the line
$TTL 60                                             ; default TTL (RFC 2308 §4)
@       IN SOA  ns1.team01.example. hostmaster.team01.example. (
                2026102701 3600 600 1209600 60 )    ; ( ) carry a record over several lines
        IN NS   ns1                                 ; blank owner: same owner as the line before
ns1  60 IN A    192.0.2.30                          ; owner  TTL  class  type  data
www     IN A    192.0.2.80
```

- One entry per line: `owner [TTL] [class] type data`; TTL and class may swap places. A missing class is the last one given (RFC 1035 §5.1); a missing TTL is the `$TTL` value (RFC 2308 §4, next slide)
- `@` stands for the current origin. A line that **starts with a blank** belongs to the previous owner: indentation changes meaning
- Text in double quotes keeps its spaces; `\.` puts a dot inside a label, `\DDD` any octet
- The format is the primary's input only. Secondaries receive records, not your comments, and "After a zone transfer all RRs have explicit TTLs" (RFC 2308 §4)

---
<!-- _class: dense -->
## Absolute and Relative Names

- A name that ends in a dot is **absolute**; any other name gets the **origin** appended (RFC 1035 §5.1). The origin is the zone name from `named.conf` until `$ORIGIN` changes it

```text
mail                    →  mail.team01.example.
mail.team01.example.    →  mail.team01.example.
mail.team01.example     →  mail.team01.example.team01.example.     ← the classic mistake
```

- The mistake is valid syntax, so the zone loads. You see it only as a warning, or in the compiled zone:

```text
zone team01.example/IN: team01.example/MX 'mail.team01.example.team01.example' has no address records (A or AAAA)
$ named-compilezone -o - team01.example /var/lib/bind/db.team01.example   # every name written out
team01.example.         60 IN MX     10 mail.team01.example.team01.example.
```

- The same applies to owner names, NS, CNAME, SRV and PTR targets. Pick one style per file: RFC 1912 §3.2 asks for consistency

---
<!-- _class: dense table-compact -->
## Directives

| Directive | Does | Defined in |
|---|---|---|
| `$TTL 60` | TTL for every following record that has none | RFC 2308 §4 |
| `$ORIGIN sub.team01.example.` | new origin for the relative names that follow | RFC 1035 §5.1 |
| `$INCLUDE file [origin]` | reads another file; never changes the origin of the file that includes it | RFC 1035 §5.1 |
| `$GENERATE 10-12 h$ A 192.0.2.$` | BIND only: `h10` to `h12` with addresses .10 to .12 | BIND 9.20 ARM §3.5.6 |

- Without `$TTL`, BIND warns `no TTL specified; using SOA MINTTL instead` (tested): put `$TTL` on the first line
- A record can still carry its own TTL: `app 10 IN A 192.0.2.85`
- One RRset, one TTL (Module 1; RFC 2181 §5.2): given two, BIND warns `TTL set to prior TTL` and uses the first
- `$GENERATE` is for long regular runs, such as reverse zones (section 6); it is not portable to other servers

---
<!-- _class: dense -->
## Your Zone After Lab 2.1

<div class="columns">
<div>

```text
$TTL 60
@  IN SOA   ns1.team01.example. (
            hostmaster.team01.example.
            2026102701 3600 600
            1209600 60 )
   IN NS    ns1.team01.example.
   IN A     192.0.2.80
   IN AAAA  2001:db8:1::80
   IN HTTPS 0 www
   IN MX    10 mail
   IN CAA   0 issue "ca.example.net"
   IN CAA   0 iodef "mailto:hostmaster@team01.example"
```

</div>
<div>

```text
ns1   IN A     192.0.2.30
www   IN A     192.0.2.80
      IN AAAA  2001:db8:1::80
      IN HTTPS 1 . alpn="h2"
web   IN CNAME www
mail  IN A     192.0.2.81
      IN AAAA  2001:db8:1::81
ftp   IN A     192.0.2.82
_imaps._tcp IN SRV 0 1 993 mail
```

</div>
</div>

- Left the apex (SOA, NS, addresses, HTTPS alias, MX, CAA); right the hosts, an alias and a service. IPv6: `2001:db8:NN::/48`
- `www`, `mail` and `ftp` keep these addresses for Modules 6-8. Every TTL is 60 s (Module 7's lab signing limit)

---
<!-- _class: dense -->
## Check Before You Load

```text
$ named-checkzone team01.example /var/lib/bind/db.team01.example
zone team01.example/IN: loaded serial 2026102701
OK
$ named-checkconf -z                     # every primary zone in named.conf, loaded as named would
zone team01.example/IN: loaded serial 2026102701
```

- `named-checkzone` "performs the same checks as named does when loading a zone". One default differs: it only **warns** about host-name syntax (check-names), where `named` **refuses** a primary zone (ARM). Add `-k fail`, or use `named-checkconf -z`
- `named-compilezone -o - zone file` prints the zone with every name in full
- `named-checkzone -l 60` rejects any TTL above 60, as `max-zone-ttl 60` in the workshop plan's lab signing policy (Module 7) will
- **The routine:** edit → raise the serial → check → `sudo rndc reload zone` → ask your server with `+norec` → ask through a resolver

---
<!-- _class: dense table-compact -->
## What BIND Says When It Is Wrong

| Mistake | `named-checkzone` 9.20.30 says | Loads? |
|---|---|---|
| Serial with 11 digits | `near '20261027001': out of range` | no |
| Letter O in an address | `near '192.0.2.8O': bad dotted quad` | no |
| CNAME next to other data, or at the apex | `web.x: CNAME and other data` | no |
| NS name with no address in the zone | `NS 'ns2.x' has no address records (A or AAAA)` | no |
| MX target without its final dot | `MX 'mail.x.x' has no address records (A or AAAA)` | yes: warning |
| `_` in a host name | `bad owner name (check-names)` | `named`: no |
| A TXT string longer than 255 octets | `syntax error` | no |
| Missing `)` | `unbalanced parentheses` | no |
| A name outside the zone | `ignoring out-of-zone data (www.example.com)` | yes: record dropped |

Syntax errors come first, several per pass; checks on the loaded zone follow once they are fixed. Repeat until `OK` with no warnings.

---
<!-- _class: section-divider -->
# 3 · SOA, Serials and Loading

---
<!-- _class: dense -->
## The SOA Record

```text
team01.example. 60 IN SOA ns1.team01.example. hostmaster.team01.example. (
                2026102701 ; SERIAL   the zone's version; secondaries compare it
                3600       ; REFRESH  how often a secondary asks for the SOA
                600        ; RETRY    how soon it asks again after a failed check
                1209600    ; EXPIRE   when it stops answering if it cannot reach the primary
                60 )       ; MINIMUM  TTL of negative answers (RFC 2308)
```

- Field names and meanings: RFC 1035 §3.3.13, as RFC 9499 uses them; all times in seconds
- **MNAME** `ns1.team01.example.`: the primary. BIND sends NOTIFY to the zone's NS names except this one (ARM)
- **RNAME** `hostmaster.team01.example.`: the mailbox `hostmaster@team01.example` with `@` written as a dot (RFC 1912 §2.2); HOSTMASTER is the standard mailbox name for DNS (RFC 2142)
- RFC 1912 §2.2 (1996) suggests refresh of 20 minutes to 2 hours (longer with NOTIFY) and expire of 2-4 weeks
- MINIMUM was once also a minimum and a default TTL; RFC 2308 §4 leaves it only "the TTL to be used for negative responses" (RFC 9499)

---
<!-- _class: dense -->
## Serial Numbers

- An unsigned 32-bit number compared with sequence-space arithmetic (RFC 1982): an increase of up to 2147483647 (2³¹ − 1) counts as newer. Going down, or jumping further, leaves secondaries believing their old copy is the newest
- Any scheme that only goes up works: `YYYYMMDDnn` (RFC 1912 §2.2: "This won't overflow until the year 4294"), a counter, or Unix time. `ietf.org` served serial 2418103546 on 27 October 2026
- Raise it on **every** change. BIND reloads the file anyway, and warns (tested):

```text
zone team01.example/IN: zone serial (2026102706) unchanged. zone may fail to transfer to secondaries.
```

- Set too high by mistake? RFC 1912 §3.1: add 2147483647 (wrapping past 2³²), load, wait two refresh periods; repeat until below the target, then set the target
- Avoid 0: "many DNS implementations have incorrectly treated zero as a special case" (RFC 1982 §7)
- For dynamic zones BIND can set the serial itself (`serial-update-method`: increment, unixtime or date)

---
<!-- _class: dense -->
## How Secondaries Keep Up

```text
 primary (VM 1)                                   secondary (VM 2 from Module 3)
   change saved, serial raised ── NOTIFY ────────>  "check now"                      (RFC 1996)
                              <── SOA? ──────────   every REFRESH; every RETRY after a failure
   serial 2026102702 ─────────────────────────────>  newer than my copy?
                              <── IXFR or AXFR ───   only the changes (RFC 1995), or all (RFC 5936, TCP)
                                                    no successful check for EXPIRE: stop answering
```

- "To detect changes, secondaries just check the SERIAL field of the SOA" (RFC 1034 §4.3.5); NOTIFY turns polling into "an interrupt as opposed to poll model" (RFC 1996)
- BIND 9.20 sends NOTIFY by default, to the zone's NS names (except MNAME) and any `also-notify`
- It allows **no** outgoing zone transfers unless `allow-transfer` lists the receiver: "the default is none" (ARM)
- In this course: the secondary on VM 2 in Module 3, TSIG on transfers in Module 6, transfers over TLS in Module 8

---
<!-- _class: dense -->
## Loading a Zone on Debian 13

```text
// /etc/bind/named.conf.local
zone "team01.example" {
    type primary;                          // the older keyword is still accepted (ARM)
    file "/var/lib/bind/db.team01.example";
};
$ named-checkconf -z && sudo rndc reload
server reload successful
$ sudo rndc zonestatus team01.example      # name, type, file, serial, nodes, last loaded
```

- `rndc reload` reloads the configuration and the zones; `rndc reload zone` only that zone. `systemctl reload named` runs `rndc reload` (Debian's `named.service`)
- Debian 13 layout (AppArmor profile): `/etc/bind` for configuration, read-only to `named`; `/var/lib/bind` for zones `named` may write (journals, Module 7's signed copy), so your zone files go there; `/var/cache/bind` for secondary copies
- Leave `named.conf.options` as Debian installed it (only `directory`). With BIND's defaults the server also offers recursion to its own subnet, so answers from VM 1 carry `ra` as well as `aa`. Module 6 turns that off

---
<!-- _class: section-divider -->
# 4 · Record Types

---
<!-- _class: dense table-compact -->
## The Records in This Module

| Type | Code | Holds | Defined in |
|---|---|---|---|
| A, AAAA | 1, 28 | an IPv4 address, an IPv6 address | RFC 1035, RFC 3596 |
| CNAME | 5 | an alias for another name (rules: two slides on) | RFC 1035 |
| MX | 15 | where mail for the name goes | RFC 1035, RFC 5321 |
| TXT | 16 | text: SPF, DKIM, DMARC, verification tokens | RFC 1035 |
| PTR | 12 | the name for an address (reverse DNS) | RFC 1035 |
| SRV | 33 | where a service runs: host and port | RFC 2782 |
| CAA | 257 | which certificate authorities may issue for the name | RFC 8659 |
| SVCB, HTTPS | 64, 65 | service bindings; aliasing at the apex | RFC 9460 |
| SPF | 99 | **do not use**: SPF lives in TXT | RFC 7208 |

Type codes: IANA DNS parameters registry, updated 16 October 2026. NS and SOA: sections 1 and 3; DNSSEC records: Module 7.

---
<!-- _class: dense -->
## Addresses and Host Names

```text
www   IN A     192.0.2.80
www   IN A     192.0.2.90        ; the same RRset: a client receives both
www   IN AAAA  2001:db8:1::80    ; a different RRset at the same name
```

- A and AAAA can share a name; several addresses of one type are one RRset (Module 1)
- Several addresses spread load crudely: a resolver keeps handing out a dead server's address until the TTL runs out. Load balancing and failover are Modules 3 and 5
- The apex can hold addresses like any other name: `team01.example` answers A and AAAA in the lab zone
- Module 1's host-name rule (letters, digits, hyphen) is what BIND's check-names enforces: on the owners of A, AAAA and MX records and on names inside NS, SOA, MX, SRV and reverse-zone PTR records (ARM). `mail_relay A` is refused, `_dmarc TXT` is not. Write names in lower case

---
<!-- _class: dense -->
## CNAME: An Alias

```text
web     IN CNAME www
$ dig @127.0.0.1 web.team01.example +norec +noall +answer
web.team01.example.     60  IN  CNAME  www.team01.example.
www.team01.example.     60  IN  A      192.0.2.80
```

- "If a CNAME RR is present at a node, no other data should be present" (RFC 1034 §3.6.2; RFC 2181 §10.1): no MX or TXT beside it. BIND refuses the zone: `CNAME and other data`
- So the apex cannot be a CNAME: it always holds the SOA and NS records
- NS and MX must name the host itself, "must not be an alias" (RFC 2181 §10.3), and so must SRV targets (RFC 2782). BIND refuses an NS that names a CNAME and warns for MX and SRV (tested)
- The server follows the chain inside its own data, so both records come back together
- Use an alias for a service that follows a name you do not control, or while renaming a host: "Don't go overboard with CNAMEs" (RFC 1912 §2.4)

---
<!-- _class: dense -->
## The Apex Problem: HTTPS and SVCB

- Users type `team01.example`, not `www.team01.example`, and the apex cannot be a CNAME
- Vendors answer with their own "ALIAS", "ANAME" or "CNAME flattening": the provider's server looks up the target and returns addresses. None of these is a record type in the IANA registry (checked 27 October 2026)
- The standard answer: **HTTPS** (type 65) and **SVCB** (type 64), RFC 9460

```text
@     IN HTTPS 0 www                ; AliasMode: for HTTPS, use www (allowed at the apex)
www   IN HTTPS 1 . alpn="h2"        ; ServiceMode: "." means www itself; it offers HTTP/2
@     IN A     192.0.2.80           ; kept for clients that do not use HTTPS records
$ dig cloudflare.com HTTPS +short   # 27 October 2026
1 . alpn="h3,h2" ipv4hint=104.16.132.229,104.16.133.229 ipv6hint=2606:4700::6810:84e5,...
```

- "The primary purpose of AliasMode is to allow aliasing at the zone apex, where CNAME is not allowed" (RFC 9460 §2.4.2). Clients that do not use HTTPS records "will just ignore the new record" (§10.4.2): keep A and AAAA at the apex

---
<!-- _class: dense -->
## MX: Where Mail Goes

```text
@     IN MX  10 mail                 ; lowest preference first
ftp   IN MX  0 .                     ; null MX: ftp.team01.example takes no mail
$ dig isc.org MX +short               # 27 October 2026
5 mx.pao1.isc.org.
10 mx.ams1.isc.org.
```

- A sending server looks up the MX records of the domain after the `@`. "Lower numbers are more preferred than higher ones"; with no MX at all, the name's own address is used as an "implicit MX" (RFC 5321 §5.1)
- The target is a host name with A or AAAA records: never an address, never a CNAME (RFC 2181 §10.3)
- A name that receives no mail publishes a single `MX 0 .` (RFC 7505) and "MUST NOT advertise any other MX RR". `example.com` does this (27 October 2026)
- The answer to an MX query carries the target's addresses in the additional section when the server has them

---
<!-- _class: dense -->
## TXT Records and Underscored Names

```text
lab1._domainkey IN TXT ( "v=DKIM1; k=rsa; p="
                         "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3u4vTeivfUtmhmbt..."
                         "...lMvCXsuHdJvufyN+OjExl1K2j6JA7knQDgc+NQIDAQAB" )
```

- TXT data is one or more strings of at most 255 octets each (RFC 1035 §3.3). Longer text is split into several strings in one record; one longer string is a `syntax error` (tested)
- Each application says how strings join: SPF and DKIM concatenate them with no spaces (RFC 7208 §3.3; RFC 6376 §3.6.2.2)
- One name can hold several TXT records for different uses: `dig ietf.org TXT` returned five on 27 October 2026. SPF must find exactly one beginning `v=spf1` (RFC 7208 §3.2)
- **Underscored names** keep each use's records apart: `_dmarc`, `lab1._domainkey`, `_imaps._tcp` (RFC 8552, BCP 222). IANA keeps the registry of them

---
<!-- _class: dense -->
## SRV: Where a Service Runs

```text
_imaps._tcp  IN SRV  0 1 993 mail     ; priority  weight  port  target
$ dig _imaps._tcp.gmail.com SRV +short   # 27 October 2026
5 0 993 imap.gmail.com.
```

- Format: `_service._proto.name TTL class SRV priority weight port target` (RFC 2782). The service labels come from the IANA service name registry (RFC 6335); `_imaps`, `_imap` and `_submission` for mail clients are in RFC 6186
- A client tries the lowest priority first; among equal priorities, weight shares the load; port is the TCP or UDP port
- The target needs address records and "MUST NOT be an alias"; a target of `.` "means that the service is decidedly not available at this domain" (RFC 2782)
- A client uses SRV only where its protocol's specification says so, as RFC 6186 does for mail clients

---
<!-- _class: dense -->
## CAA: Which CAs May Issue

```text
@  IN CAA  0 issue "ca.example.net"                      ; only this CA may issue
@  IN CAA  0 iodef "mailto:hostmaster@team01.example"    ; where a CA reports requests that break it
$ dig google.com CAA +short           # 27 October 2026
0 issue "pki.goog"
```

- Before issuing, a CA MUST look for CAA; if it finds an RRset it "MUST NOT issue a certificate unless" the request matches it (RFC 8659 §3)
- The search "climbs the DNS name tree" from the name towards the root and stops at the first CAA RRset: one set at the apex covers every name below it that has none
- Tags: `issue` (any certificate), `issuewild` (wildcard certificates), `iodef` (reports); flag 128 marks a tag critical; `0 issue ";"` forbids issuance
- CAA binds CAs that follow RFC 8659, not attackers. "The use of DNSSEC to authenticate CAA RRs is strongly RECOMMENDED" (RFC 8659): Module 7

---
<!-- _class: dense table-compact -->
## Less Common Records and Features

| Feature | Example | What it does |
|---|---|---|
| Wildcard | `* IN TXT "wildcard"` | answers for names that do not exist in the zone; a name that exists without TXT gets NODATA, not the wildcard (RFC 4592; tested on BIND 9.20) |
| DNAME | `old IN DNAME new.team01.example.` | "redirection for a subtree of the domain name tree" (RFC 6672) |
| Unknown type | `x IN TYPE65280 \# 2 abcd` | generic syntax for a type the software does not know (RFC 3597; tested) |
| SPF type 99 | none | "implementations are not to use it" (RFC 7208 §14.1): publish SPF as TXT |
| Delegation inside the zone | `lab IN NS ...` | section 1 |

- A wildcard also answers deeper names (in the test, a two-label name matched `*`), so every mistyped name below it gets an answer: use one for a reason, not by default
- Module 7 adds the DNSSEC types; Module 8 the DDR records under `resolver.arpa`

---
<!-- _class: section-divider -->
# 5 · Email Records

---
<!-- _class: dense -->
## How Mail Uses Your Zone

```text
 sending server                                  your zone, team01.example
  1 MX for team01.example? ─────────────────────>  10 mail.team01.example. (+ its addresses)
  2 connects to mail.team01.example and delivers
 a receiving server checks a message "From: alice@team01.example"
  3 SPF:   TXT at the envelope (MAIL FROM) domain ─>  "v=spf1 mx -all"
  4 DKIM:  TXT at <selector>._domainkey.<domain> ─>  the public key for the signature
  5 DMARC: TXT at _dmarc.team01.example ─────────>  policy; reports to the rua address
```

- **MX** routes mail to you; **SPF**, **DKIM** and **DMARC** let receivers check mail that claims to come from you
- All three are TXT records: no mail server is needed to publish them, and none runs in the lab
- DMARC passes when SPF or DKIM passes for a domain **aligned** with the `From:` domain (RFC 9989 §4)
- A domain that sends no mail says so too: null MX, `v=spf1 -all`, DMARC `p=reject`. `example.com` publishes all three (27 October 2026)

---
<!-- _class: dense -->
## SPF: Who May Send

```text
@     IN TXT  "v=spf1 mx -all"        ; the hosts in our MX records; fail everyone else
ftp   IN TXT  "v=spf1 -all"           ; this name sends no mail
$ dig ietf.org TXT +short | grep spf1    # 27 October 2026 (shortened)
"v=spf1 ip4:166.84.6.31 ... include:_spf.google.com include:spf.hostedrt.com ~all"
```

- "SPF records MUST be published as a DNS TXT (type 16) Resource Record (RR) [RFC1035] only" (RFC 7208 §3.1), one per name (§3.2)
- Mechanisms: `ip4:`, `ip6:`, `a`, `mx`, `include:` and `all`; qualifiers `+` pass, `-` fail, `~` softfail, `?` neutral
- `include`, `a`, `mx`, `ptr`, `exists` and `redirect` cost DNS lookups: at most **10** per check, or the result is "permerror" (§4.6.4). Long `include` chains break this limit
- `ptr` "SHOULD NOT be published" (§5.5); keep the record small: under 450 octets of names and text (§3.4)

---
<!-- _class: dense -->
## DKIM: The Signer's Public Key

```text
$ openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out lab1.private
$ openssl pkey -in lab1.private -pubout -outform DER | base64 -w0 > lab1.pub
$ wc -c < lab1.pub
392                                  # more than 255: split into two strings
$ fold -w 250 lab1.pub | sed 's/.*/"&"/'
```

- A signature names a domain (`d=`) and a selector (`s=`); the key is TXT at `selector._domainkey.domain` (RFC 6376 §3.6.2.1, STD 76)
- Tags: `v=DKIM1` (first, if present), `k=rsa` (the default) or `k=ed25519` (RFC 8463), `p=` the public key in base64; an empty `p=` means "this public key has been revoked"
- RFC 8301: "rsa-sha1 MUST NOT be used for signing or verifying"; RSA keys MUST be at least 1024 bits, SHOULD be at least 2048
- Roll keys with selectors: publish the new key under a new selector, move signing to it, then empty the old `p=`
- The private key stays on the mail server, never in the zone or the kit: in the lab it lives in your home directory

---
<!-- _class: dense -->
## DMARC: The Policy (RFC 9989)

```text
_dmarc  IN TXT  "v=DMARC1; p=none; rua=mailto:dmarc-reports@team01.example"
$ dig _dmarc.ietf.org TXT +short       # 27 October 2026
"v=DMARC1; p=none; rua=mailto:dmarc_agg@vali.email,mailto:dmarc-report@ietf.org"
$ dig _dmarc.example.com TXT +short
"v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s"
```

- At `_dmarc.<domain>`; `v=DMARC1` MUST come first. `p=` none, quarantine or reject; `sp=` subdomains; `np=` non-existent subdomains (from RFC 9091)
- `rua=` where aggregate reports go (RFC 9990); `ruf=` failure reports (RFC 9991); `adkim`/`aspf` relaxed or strict alignment
- New in RFC 9989: `t=y` test mode and `psd=`; `pct=`, `rf=` and `ri=` removed; a "DNS Tree Walk" finds the policy instead of a public suffix list (§4.10)
- Start with `p=none` and a `rua` mailbox ("monitoring mode", §5.1.4), read the reports, then tighten the policy

---
<!-- _class: section-divider -->
# 6 · Reverse DNS

---
<!-- _class: dense -->
## Reverse Zones and PTR

```text
192.0.2.80      →  80.2.0.192.in-addr.arpa.                        PTR  www.team01.example.
2001:db8:1::81  →  1.8.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.         (20 nibbles: the host part)
                   1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.                PTR  mail.team01.example.
```

- As in Module 1, `dig -x` turns the address into a name under `in-addr.arpa` or `ip6.arpa` (RFC 3596 §2.5)
- Reverse zones follow address blocks: a /24 is `2.0.192.in-addr.arpa`; a /48 is 12 nibbles, `1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa` for `2001:db8:1::/48`
- Delegation follows allocation: IANA, RIR, ISP, you (Module 1). Ask whoever gave you the addresses. In the lab nobody delegates them: ask your own server
- "Make sure your PTR and A records match", and point PTR at a name with an A record, "not a alias defined by a CNAME" (RFC 1912 §2.1)
- Mail servers, SSH, logs and traceroute look at PTR records (RFC 8501 §4)

---
<!-- _class: dense -->
## Smaller Than a /24, and IPv6

```text
; 2.0.192.in-addr.arpa (held by the ISP): hand 192.0.2.0/25 to a customer
0/25     IN NS     ns.a.example.
1        IN CNAME  1.0/25.2.0.192.in-addr.arpa.
$GENERATE 2-127 $ CNAME $.0/25                   ; BIND: the other 126 in one line
; 0/25.2.0.192.in-addr.arpa (the customer's zone)
1        IN PTR    host1.a.example.
```

- in-addr.arpa zones can only be cut between octets. RFC 2317 (BCP 20) adds a level, "Since a single zone can only be delegated once", and the parent points each address at it with a CNAME
- IPv6 needs no such trick: every nibble is a label, so a reverse zone can start at any 4-bit boundary (/48, /52, /56, /60, /64)
- For large IPv6 networks per-address PTR records are "impractical"; RFC 8501 lists the options (no PTR, wildcards, dynamic updates, generated answers). For a host with a static address and name, "AAAA and PTR records should exist and match" (§4)

---
<!-- _class: dense -->
## Your Reverse Zones in the Lab

<div class="columns">
<div>

```text
; /var/lib/bind/db.192.0.2
$TTL 60
@   IN SOA ns1.team01.example. hostmaster.team01.example. (
           2026102701 3600 600 1209600 60 )
    IN NS  ns1.team01.example.
30  IN PTR ns1.team01.example.
80  IN PTR www.team01.example.
81  IN PTR mail.team01.example.
82  IN PTR ftp.team01.example.
```

</div>
<div>

```text
$ dig @127.0.0.1 -x 192.0.2.81 +norec +short
mail.team01.example.
$ dig @127.0.0.1 mail.team01.example +norec +short
192.0.2.81                     # forward-confirmed
$ dig @192.0.2.55 -x 2001:db8:1::81 \
      +noall +question
;1.8.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.
 1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa. IN PTR
```

</div>
</div>

- PTR targets are absolute names with the final dot: a relative `www` would mean `www.2.0.192.in-addr.arpa.`
- The IPv6 zone `db.2001-db8-NN` holds the last 20 nibbles as relative owner names; `dig -x` gives them to you
- Every team serves its own copy of `2.0.192.in-addr.arpa`. The lab resolver answers `-x 192.0.2.80` with NXDOMAIN, `aa` and the SOA `2.0.192.IN-ADDR.ARPA. ... SOA 2.0.192.IN-ADDR.ARPA. .`: an empty zone it serves itself for documentation and private address space (RFC 6303, BCP 163), so the query never leaves it

---
<!-- _class: section-divider -->
# 7 · TTL Strategy and Zone Management

---
<!-- _class: dense table-compact -->
## Choosing TTLs

| A longer TTL | A shorter TTL |
|---|---|
| fewer queries reach your servers; caches answer faster | changes reach users sooner |
| cached answers outlast a short outage of your servers | more queries; users depend more on your servers being up |

- You set the TTL per record (Module 1: the source controls the trade-off); resolvers keep copies within their own limits
- Default limits: BIND keeps answers at most 1 week and negative answers 3 hours (ARM); Unbound 1 day and 1 hour (unbound.conf(5), 1.26.2)
- Negative answers live for the smaller of the SOA's TTL and MINIMUM (RFC 2308 §5); "Values of one to three hours have been found to work well" as a resolver limit
- The parent sets the TTL of your delegation: `com.` keeps one for 172800 s (Module 1). A change of name servers waits for the parent's TTL, not yours
- Some resolvers serve expired data when your servers cannot be reached (serve-stale, RFC 8767)
- In the lab every TTL is at most 60 s, so that you can watch it, and the workshop plan's lab signing policy (Module 7, `max-zone-ttl 60`) would refuse more

---
<!-- _class: dense -->
## Planning a Change

```text
 day -2: lower the TTL     day 0: change the address    + minutes: verify       later: raise the TTL
   3600 → 60                  resolvers re-ask within 60 s  dig @each-NS +norec     60 → 3600
         └──── wait at least the OLD TTL (3600 s) ────┘
```

- RFC 1912 §2.2: "turn this value down temporarily beforehand. Then wait the previous minimum value, make your changes, verify their correctness, and turn this value back up"
- Lab 2.3 does this in seconds: TTL 60 → 10, wait 60 s, change: the lab resolver had the new address within 11 s (rehearsed 27 October 2026)
- A name that someone asked for before you created it stays NXDOMAIN in their resolver until the negative TTL runs out
- Moving to new name servers: the NS and glue at the parent keep their own TTL. Keep the old servers answering, with the same data, until that has passed

---
<!-- _class: dense -->
## Designing the Zone Structure

```text
 example.org                  public names: www, mail, SPF/DKIM/DMARC   your primary + two secondaries
   ├─ eng.example.org         delegated: engineering runs its own servers
   ├─ shop.example.org        CNAME or HTTPS alias to a provider's name
   └─ internal names          split horizon (Module 5): never on the public servers
 reverse: 2.0.192.in-addr.arpa, 1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa   delegated to you by your RIR or ISP
```

- Cut a zone where another party "wants to take over control of a subtree" (RFC 1034 §4.2): another team, provider or server set, or a separate change schedule. One zone is simpler otherwise: fewer delegations to keep consistent
- Name hosts by function (`www`, `mail`, `ns1`), not by hardware or room; the name outlives the machine. Aliases help when renaming (RFC 1912 §2.4)
- One convention for every zone: lower case; letters, digits, hyphen in host names; one serial scheme; the same SOA timers; reverse zones on block boundaries

---
<!-- _class: dense -->
## A Zone Change Procedure

1. Keep zone files in version control; every change has an author and a reason
2. Raise the serial, with one scheme for all zones
3. `named-checkzone -k fail -l <your maximum TTL> zone file`; `named-checkconf -z`
4. `sudo rndc reload zone`; read the log line `loaded serial ...`
5. Verify: `dig @<each NS> zone SOA +norec` shows the new serial on every server; then ask through a resolver for the changed name
6. For moves and renumbering: lower the TTLs first (previous slide)

- Automation follows the same steps: dynamic updates with `nsupdate` (RFC 2136), APIs (Module 4: the PowerDNS API and cloud DNS), signing (Module 7)
- Monitoring (Module 11): serial agreement across your servers and the parent's delegation belong in its checks

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

```text
                       classroom LAN (lab sheet addresses; 192.0.2.0/24 on the slides)
  ──────┬────────────────────────────┬─────────────────────────────┬─────────────────────
    your VM 1 192.0.2.30          registry 192.0.2.53              lab resolver 192.0.2.55
    BIND: teamNN.example and      example.: delegates              from Module 1: recursive for
    two reverse zones             teamNN.example to VM 1           the lab; only the lab tree
```

- **VM 1 gets BIND today:** `bind9` and `bind9-utils`, plus `openssl` for Lab 2.4. Already in your image: `sudo rndc-confgen -a -u bind` (this VM's own control key), then `sudo systemctl enable --now named`. Otherwise: `sudo apt install bind9 bind9-utils openssl` (`named` starts by itself). VM 2 waits for Module 3
- **Kit:** `labs/module02/`: `zones/` (templates for your three zone files and the `zone` statements), `broken/db.broken.example`
- **Rights:** edit files in `/etc/bind` and `/var/lib/bind` and run `rndc` with `sudo`; `named-checkzone`, `named-checkconf -z` and `dig` need none
- **Offline:** everything is on the lab network; no Internet access is needed
- Replace `NN` with your team number and the addresses with your lab sheet's

---
<!-- _class: dense -->
## Lab 2.1: Write and Load Your Zone (30 min)

1. Start BIND (Lab Environment); `named -v`; `ls /etc/bind`: Debian 13 gives you no zone files
2. `sudo cp zones/db.teamNN.example /var/lib/bind/db.team01.example` (your number); `sudo sed -i 's/NN/01/g' /var/lib/bind/db.team01.example`; put your VM 1 address on the `ns1` line
3. Add the records from "Your Zone After Lab 2.1": apex A, AAAA, `HTTPS 0 www`, `MX 10 mail`, CAA `issue` and `iodef`; `www` A, AAAA and HTTPS (`1 . alpn="h2"`); `web` CNAME; `mail` A, AAAA; `ftp` A; `_imaps._tcp` SRV
4. `named-checkzone teamNN.example /var/lib/bind/db.teamNN.example` until `OK` with no warnings; then `named-compilezone -o - teamNN.example /var/lib/bind/db.teamNN.example`
5. Add the first `zone` statement from `zones/named.conf.local` to `/etc/bind/named.conf.local`; `named-checkconf -z`; `sudo rndc reload`; `sudo rndc zonestatus teamNN.example`
6. `dig @127.0.0.1 teamNN.example SOA +norec`, then each type; `dig @192.0.2.55 www.teamNN.example`; compare `dig @192.0.2.53 teamNN.example NS +norec` with your zone's NS and `ns1` address

> **Checkpoint:** `OK` with no warnings; `aa` from your server; the lab resolver answers NOERROR where Module 1 showed SERVFAIL; the registry's NS and glue match your zone (Practical Assessment 1B, task 1)

<!--
Expected (rehearsed 27 October 2026, BIND 9.20.30): named-checkzone "zone team01.example/IN: loaded serial 2026102701" and OK; rndc reload "server reload successful"; dig @127.0.0.1 ... SOA +norec: "flags: qr aa ra" (ra: Debian's defaults allow recursion for localhost and localnets; Module 6 Lab 6.1 removes it); the MX answer has mail's A and AAAA and ns1's A in the additional section; dig @192.0.2.55 www.teamNN.example: NOERROR, "flags: qr rd ra", 192.0.2.80. Another host on the lab subnet also gets "qr aa ra" from VM 1.
Common mistakes: "MX 10 mail.teamNN.example" without the final dot (warning: has no address records); forgetting to replace NN in the file name; editing without sudo; a CNAME next to another record at web.
If the lab resolver still says SERVFAIL right after the reload, ask again: BIND caches SERVFAIL for a second (servfail-ttl).
-->

---
<!-- _class: dense -->
## Lab 2.2: Reverse Zones and a Broken File (25 min)

1. Copy `zones/db.192.0.2` and `zones/db.2001-db8-NN` to `/var/lib/bind` (`db.2001-db8-01` for team 01); set `NN`; add PTRs for `www` (.80), `mail` (.81), `ftp` (.82), and for `mail` at `2001:db8:NN::81` (owner name from `dig @192.0.2.55 -x 2001:db8:NN::81 +noall +question`)
2. Zone names: `2.0.192.in-addr.arpa`, and the first 12 nibbles of `2001:db8:NN::/48` reversed (team 01: `1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa`). `named-checkzone` each; add both `zone` statements; `named-checkconf -z`; `sudo rndc reload`
3. `dig @127.0.0.1 -x 192.0.2.80 +norec`; `dig @127.0.0.1 -x 2001:db8:NN::81 +norec +short`; confirm each PTR name gives the address back. Then `dig @192.0.2.55 -x 192.0.2.80`: NXDOMAIN. Whose SOA is in the authority section?
4. `cp broken/db.broken.example ~`; `named-checkzone broken.example db.broken.example`; fix and repeat until `OK`; then with `-k fail`; then read `named-compilezone -o - broken.example db.broken.example`

> **Checkpoint:** both reverse zones answer with `aa` and match the forward records; the broken file passes `named-checkzone -k fail` with no warnings, and you can name all seven mistakes (Practical Assessment 1B, tasks 2 and 4)

<!--
Broken file, as rehearsed: pass 1 reports four messages: line 4 "near '20261027001': out of range" (serial, 11 digits); line 10 "near '192.0.2.8O': bad dotted quad" (letter O); line 12 "web.broken.example: CNAME and other data" (web has CNAME and TXT); line 14 "mail_relay.broken.example: bad owner name (check-names)" (warning only by default). Pass 2: "NS 'ns2.broken.example' has no address records (A or AAAA)" (add an A for ns2 or remove that NS). Pass 3: OK, with two warnings: "MX 'mail.broken.example.broken.example' has no address records" (missing final dot) and the bad owner name. -k fail refuses the underscore (named would too). named-compilezone shows the seventh: "ftp.broken.example.broken.example." (owner without its final dot), which produces no message at all.
Step 3: the lab resolver (BIND, built-in empty zones on by default, ARM 8.2.13.14) answers from its own empty zone: status NXDOMAIN, flags qr aa rd ra, authority "2.0.192.IN-ADDR.ARPA. 86400 IN SOA 2.0.192.IN-ADDR.ARPA. . 0 28800 7200 604800 86400". RFC 6303 lists 2.0.192.IN-ADDR.ARPA and 8.B.D.0.1.0.0.2.IP6.ARPA among the zones every resolver serves locally, so the query never reaches the lab root. A classroom on RFC 1918 addresses sees the same for its own reverse zones. In production the RIR or ISP delegates the reverse zone.
-->

---
<!-- _class: dense -->
## Lab 2.3: TTLs and Caching (20 min)

The lab resolver 192.0.2.55 plays "everyone's cache". After every edit: raise the serial, `named-checkzone`, `sudo rndc reload teamNN.example`.

1. Add `app IN A 192.0.2.84`. `dig @192.0.2.55 app.teamNN.example +noall +answer` twice, 5 s apart; the same `@127.0.0.1 +norec`: which TTL moves?
2. Change `app` to .85. Ask both servers at once; `dig @192.0.2.55 app.teamNN.example +norec` shows only what is cached. How long until the resolver has .85?
3. Planned change: set `app 10 IN A 192.0.2.85`; wait until the resolver's TTL shows 10 or less; change to .86. How long now?
4. `dig @192.0.2.55 new.teamNN.example`: NXDOMAIN; note the SOA's TTL in authority. Add `new IN A 192.0.2.87`; ask at once, and again after that TTL
5. Change a record **without** raising the serial; `sudo rndc reload teamNN.example`; `sudo journalctl -u named -n 5`. Then raise the serial and reload
6. `named-checkzone -l 60 teamNN.example /var/lib/bind/db.teamNN.example`

> **Checkpoint:** you can say how long each change took to reach the resolver and which TTL decided it, and what the serial warning means for a secondary

<!--
Rehearsed 27 October 2026: step 1 resolver TTL 60 then 55; own server always 60. Step 2: server .85, resolver (+norec, cache only) .84 with 54 s left; .85 after 53 s. Step 3: the 60-second copy must expire first (up to 60 s); after that the change to .86 reached the resolver within 11 s. Step 4: team01.example. 60 IN SOA ... in authority; still NXDOMAIN right after adding new; 192.0.2.87 after 59 s. Step 5 log line: "zone team01.example/IN: zone serial (2026102706) unchanged. zone may fail to transfer to secondaries." - the file was loaded anyway on the primary; a secondary (Module 3) would keep the old copy. Step 6: OK; a record with TTL 3600 gives "TTL 3600 exceeds configured max-zone-ttl 60".
The resolver is shared by the class: teams query only their own names, so no team disturbs another.
-->

---
<!-- _class: dense -->
## Lab 2.4: Email Records (15 min)

1. Add `@ IN TXT "v=spf1 mx -all"`, and for `ftp`: `MX 0 .` and `TXT "v=spf1 -all"`
2. In your home directory (not in `/etc/bind` or `/var/lib/bind`): make the DKIM key and fold it, as on the DKIM slide
3. Add the key: `lab1._domainkey IN TXT ( "v=DKIM1; k=rsa; p="` then the quoted lines, then `)`. First try the whole key as one string: what does `named-checkzone` say?
4. Add `_dmarc IN TXT "v=DMARC1; p=none; rua=mailto:dmarc-reports@teamNN.example"`
5. Serial; `named-checkzone -k fail -l 60 ...`; `sudo rndc reload teamNN.example`; `dig @127.0.0.1` for `teamNN.example TXT`, `ftp.teamNN.example MX`, `_dmarc.teamNN.example TXT`; the same through 192.0.2.55
6. Compare the key in the DNS with yours:
   `dig @127.0.0.1 lab1._domainkey.teamNN.example TXT +short | tr -d '" \n' | sed 's/^.*;p=//' | cmp - lab1.pub && echo match`

> **Checkpoint:** SPF, null MX, DKIM and DMARC answer from your server and through the resolver, and the key matches (Practical Assessment 1B, task 3)

**Discussion:** which names in your zone should send mail, and which should publish `v=spf1 -all` and a null MX?

<!--
Rehearsed: lab1.pub is 392 characters (2048-bit RSA, SubjectPublicKeyInfo in base64); fold -w 250 gives two quoted lines of 252 and 144 characters. The whole key in one string: "syntax error" and "not loaded due to errors". named-checkzone -k fail -l 60: OK with no warnings (a null MX raises none). dig returns the DKIM record as three strings: "v=DKIM1; k=rsa; p=" "MIIB..." "...IDAQAB". The cmp line prints "match".
Keep lab1.private out of the course repository and out of /etc/bind and /var/lib/bind; labs/.gitignore blocks *.private. Delete it after the course.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 1034, 1035 (STD 13); RFC 2181; RFC 9499 (BCP 219)
- RFC 1912; RFC 2142; RFC 4343; RFC 1123; RFC 9471 glue
- RFC 2308 negative caching; RFC 1982 serials; RFC 8767
- RFC 1995 IXFR, 1996 NOTIFY, 5936 AXFR; RFC 2136 UPDATE
- RFC 3596 (STD 88); RFC 2317 (BCP 20); RFC 8501; RFC 6303 (BCP 163), 1918
- RFC 2782, 6186, 6335 SRV; RFC 8659 CAA (obsoletes 6844)
- RFC 9460 SVCB/HTTPS; RFC 4592; RFC 6672; RFC 3597
- RFC 5321; RFC 7505 null MX; RFC 7208 SPF
- RFC 6376 (STD 76), 8301, 8463 DKIM
- RFC 9989-9991 DMARC (obsolete 7489, 9091); RFC 8552 (BCP 222)
- IANA: DNS parameters; underscored node names
- ISC BIND 9.20 ARM and man pages; Debian 13 `bind9` 1:9.20.30; `unbound.conf(5)` 1.26.2

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>named-checkzone zone file
named-checkzone -k fail -l 60 \
  zone file
named-compilezone -o - zone file
named-checkconf -z
sudo rndc reload [zone]
sudo rndc zonestatus zone
dig @127.0.0.1 name type +norec
dig @resolver -x address +noall +question
sudo journalctl -u named -n 20
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. In `team01.example` you wrote `@ IN MX 10 mail.team01.example`. What does BIND load, what does `named-checkzone` say, and how do you fix it?
2. Why can `team01.example` not be a CNAME, and which standard record lets web clients use an alias at the apex?
3. A secondary still serves old data an hour after you changed the primary. Name two causes involving the SOA.
4. `www` has a TTL of 86400 and the web server moves tomorrow at 10:00. What do you change, and when?
5. Someone asked for `new.team01.example` a minute before you added it. Why does their resolver still say NXDOMAIN, and for how long?
6. Your DKIM public key is 392 characters long. How do you publish it, and how does a verifier read it?

<!--
Answers:
1. The name has no final dot, so the origin is appended: the MX points at mail.team01.example.team01.example. BIND loads it; named-checkzone warns "MX 'mail.team01.example.team01.example' has no address records (A or AAAA)"; named-compilezone shows it. Fix: "MX 10 mail" or "MX 10 mail.team01.example." (RFC 1035 §5.1).
2. A CNAME allows no other data at its name (RFC 1034 §3.6.2, RFC 2181 §10.1), and the apex must hold the SOA and NS records. HTTPS (or SVCB) in AliasMode, "@ IN HTTPS 0 www" (RFC 9460 §2.4.2); keep A and AAAA at the apex for other clients.
3. The serial was not raised (or went down, or jumped by more than 2^31 - 1), so the secondary thinks it is current; NOTIFY did not reach it and REFRESH (3600 s in the lab) has not yet passed, or its checks fail and it is retrying every RETRY. Also possible: the primary does not allow the transfer (BIND 9.20 default allow-transfer none).
4. Today, at least 86400 s before 10:00 tomorrow, lower the TTL (to 300 or 60) and raise the serial. At 10:00 change the address; verify on every NS with +norec and through a resolver; then raise the TTL again (RFC 1912 §2.2). Lowering it later than 10:00 yesterday helps nothing: caches hold the 86400 s copy.
5. Negative caching: the resolver keeps the NXDOMAIN for the smaller of the SOA record's TTL and its MINIMUM field (RFC 2308 §5): 60 s in the lab, often hours in production, capped by the resolver (BIND 3 hours, Unbound 1 hour by default).
6. As one TXT record with several strings of at most 255 octets each, e.g. "v=DKIM1; k=rsa; p=" "<250 characters>" "<142 characters>", at selector._domainkey.domain. The verifier concatenates the strings with no spaces (RFC 6376 §3.6.2.2) and reads the p= tag.
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
