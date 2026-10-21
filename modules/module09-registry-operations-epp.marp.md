---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 9: Registry Operations and EPP Protocol

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Recall** the roles in the registration chain, the EPP object types and the EPP result code classes
- **Explain** the domain lifecycle, the grace periods (RFC 3915) and the client and server status codes
- **Describe** an EPP session over TLS: framing, greeting, login, commands and the poll queue (RFC 5730, 5734)
- **Execute** EPP commands to create contacts, hosts (with glue) and domains, update name servers, renew and transfer
- **Submit** a DS record through the EPP DNSSEC extension (RFC 5910) and explain how a registry processes CDS/CDNSKEY
- **Apply** secure transfer codes (RFC 9154) and the restore process for a deleted domain
- **Analyse** EPP responses and transaction data to find why a command failed

---
<!-- _class: dense table-compact -->
## What Changed Recently

Older registry training is out of date in five places:

| Then | Now |
|---|---|
| WHOIS on port 43 for every gTLD | RDAP is the definitive gTLD service since 28 January 2025; WHOIS no longer required (except .com, .name, .post) |
| Transfer code set at creation, kept in clear | RFC 9154: random, at least 128 bits, set only for a transfer, stored hashed |
| Gaining-registrar FOA and 60-day locks | Revised ICANN Transfer Policy adopted 7 June 2026 (TAC, 720-hour locks, no gaining FOA); not yet in force |
| DS sent by email or web form | EPP `secDNS-1.1` (RFC 5910); CDS/CDNSKEY read by the parent (RFC 7344, 8078, 9615, 9975) |
| Ad hoc ways to delete hosts with glue | RFC 9874 (BCP, September 2025) |

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. The registry operating model (15m)
2. EPP fundamentals (20m)
3. Objects, renewals and transfers (25m)
4. DNSSEC at the registry (10m)
5. Extensions and registration data (10m)
6. Registry operations; recap and questions (10m)

## Agenda (90 min Lab)

1. Lab 9.1 Connect and log in (15m)
2. Lab 9.2 Contacts, hosts and domains (25m)
3. Lab 9.3 Publish your DS (15m)
4. Lab 9.4 Transfer and renew (20m)
5. Lab 9.5 Delete and restore (15m)

---
<!-- _class: section-divider -->
# 1 · The Registry Operating Model

---
<!-- _class: dense table-compact -->
## Who Does What

| Role | Does | Example in the lab |
|---|---|---|
| **Registry** | runs the database for a TLD and publishes the TLD zone | the instructor's server for `example.` |
| **Registrar** | sells names; the only party that talks EPP to the registry | your team account `regNN` |
| **Reseller** | sells through a registrar's system; no registry access | — |
| **Registrant** | holds the right to use the name | the contact `tNN-holder` |
| **DNS operator** | runs the name servers and DNSSEC keys for the domain | your Module 7 server for `teamNN.example` |

- The registry knows registrars, not end customers; the registrar holds the customer relationship
- The DNS operator may be the registrant, the registrar or a third party (RFC 7344 §2.2)

---
<!-- _class: dense -->
## The Shared Registry Model

```text
 registrant ──> registrar A ──┐
 registrant ──> registrar B ──┼── EPP over TLS ──> registry database ──> TLD zone ──> DNS
 registrant ──> registrar C ──┘                          │
                                                         └──> RDAP, escrow, reports
```

- Many registrars, one registry per TLD: every registrar gets the same interface and the same rules
- The registry enforces the rules in software: who may change an object, which statuses block a command, what each command costs
- **gTLDs:** the registry has a Registry Agreement with ICANN; registrars sign ICANN's Registrar Accreditation Agreement (RAA) and a Registry-Registrar Agreement
- **ccTLDs:** each country code registry sets its own policy and accredits its own registrars

---
<!-- _class: dense -->
## What the Registry Stores

<div class="columns">
<div>

### Thin registry
- Domain name, status, dates
- Sponsoring registrar
- Name servers and glue
- DS records
- Contact data stays with each registrar

</div>
<div>

### Thick registry
- Everything in a thin registry
- **Plus** registrant, admin and technical contacts
- One copy of registration data, served by the registry's RDAP
- Contacts become EPP objects (RFC 5733)

</div>
</div>

The lab registry is thick: you create a contact before the domain. Which contacts a registry requires is its own policy.

---
<!-- _class: dense -->
## Services a Registry Runs

| Service | Users | Standard |
|---|---|---|
| Shared registration system (EPP) | registrars | RFC 5730-5734 + extensions |
| TLD zone generation and DNSSEC signing | everyone, through DNS | Module 7 |
| Registration data (RDAP, sometimes WHOIS) | public, law enforcement | RFC 9082, 9083 |
| Data escrow | the escrow agent, ICANN | RFC 8909, 9022 |
| Registrar accounts and billing | registrars, finance | registry policy |
| Monitoring and reporting | operations, ICANN for gTLDs | Registry Agreement Spec 10 |

Most of these read the same database that EPP writes.

---
## The Domain Lifecycle

```text
 available ──create──> registered ──renew──> registered ──expiry──> auto-renew grace
                          │                                              │
                          ├──transfer──> new registrar                   │ registrar deletes
                          │                                              v
                          └──delete──────────────────────────> redemption (30 days)
                                                                 │        │ restore
                                                                 v        └──> registered
                                                           pending delete (5 days)
                                                                 │
                                                                 v
                                                             available
```

Timings shown are the .com contract values; each registry sets its own.

---
<!-- _class: dense table-compact -->
## Grace Periods (RFC 3915)

| Period | Starts | Delete during it means | .com contract value |
|---|---|---|---|
| Add grace (`addPeriod`) | create | registrar gets a credit; name is freed at once | 5 days |
| Renew grace (`renewPeriod`) | explicit renew | credit for the renewal | 5 days |
| Auto-renew grace (`autoRenewPeriod`) | expiry | credit for the automatic renewal | 45 days |
| Transfer grace (`transferPeriod`) | completed transfer | credit for the transfer | 5 days |
| Redemption (`redemptionPeriod`) | delete | domain can be restored | 30 days |
| Pending delete (`pendingDelete`) | end of redemption | nothing can stop the purge | 5 days |

- RFC 3915: "The duration of each grace period is a matter of registry operational policy"
- ICANN's Expired Registration Recovery Policy requires a 30-day redemption period in gTLDs; the AGP Limits Policy caps add-grace refunds (10% of net adds or 50 names a month, whichever is greater)

---
<!-- _class: dense -->
## Redemption and Restore (RFC 3915 §2)

```text
EPP: ok ──<delete>──> EPP: pendingDelete     ──restore request──> EPP: pendingDelete
                      RGP: redemptionPeriod <──no report─────────  RGP: pendingRestore
                             │                                           │ restore report
                             │ period ends                               v
                             v                                     EPP: ok (RGP removed)
                      EPP: pendingDelete, RGP: pendingDelete ──> purged ──> available
```

- A restore is two steps: a **request** (`<rgp:restore op="request"/>`), then a **report** with the registration data before and after, the reason and two statements
- The registry may charge for a restore; registrars use it to undo mistakes, not to warehouse names
- You will run this sequence in Lab 9.5

---
<!-- _class: dense table-compact -->
## Status Codes: Who Can Set Them

| Prefix | Set by | Examples (RFC 5731 §2.3) |
|---|---|---|
| `client…` | the sponsoring registrar | `clientHold`, `clientTransferProhibited`, `clientUpdateProhibited`, `clientDeleteProhibited`, `clientRenewProhibited` |
| `server…` | the registry | `serverHold`, `serverTransferProhibited`, `serverUpdateProhibited`, `serverDeleteProhibited`, `serverRenewProhibited` |
| `pending…` | the registry, while an action waits | `pendingCreate`, `pendingDelete`, `pendingTransfer`, `pendingUpdate`, `pendingRenew` |
| — | the registry | `ok` (nothing else applies), `inactive` (no name servers) |

- `…Hold` removes the delegation from the zone; `…Prohibited` blocks a command
- **Registry lock** is a registry service (for gTLDs, approved per registry through ICANN's RSEP), not an ICANN policy: at the registrar's request the registry sets `server…Prohibited` codes, which no registrar can remove over EPP
- ICANN explains each code for registrants at icann.org/epp (EPP status codes page)

---
<!-- _class: section-divider -->
# 2 · EPP Fundamentals

---
<!-- _class: dense -->
## What EPP Is

- **Extensible Provisioning Protocol:** XML commands from a client (registrar) to a server (registry) that create and change objects in a shared database
- **RFC 5730** (2009); with RFC 5731-5734 it forms Internet Standard STD 69. It obsoletes RFC 4930, which obsoleted RFC 3730 (2004)
- Object mappings define the data: domain (RFC 5731), host (RFC 5732), contact (RFC 5733)
- A transport mapping defines the connection: TCP with TLS (RFC 5734)
- Extensions add data without changing the core: DNSSEC, grace periods, fees, launch phases
- Required of gTLD registries by the Registry Agreement (Spec 6); ccTLDs choose their own registrar interface

EPP is a provisioning protocol. It changes the registry's database; the registry's own systems turn that into DNS.

---
<!-- _class: dense tight table-compact -->
## EPP Standards Map

| RFC | Covers | Status |
|---|---|---|
| 5730 | EPP core: sessions, commands, result codes | Internet Standard (STD 69 = RFC 5730-5734) |
| 5731 / 5732 / 5733 | Domain / host / contact objects | Internet Standard |
| 5734 | TCP and TLS transport (updated by RFC 8996: no TLS 1.0 or 1.1) | Internet Standard |
| 5910 | DNSSEC extension, `secDNS-1.1` (obsoletes RFC 4310) | Proposed Standard |
| 3915 | Grace periods and restore, `rgp-1.0` | Proposed Standard |
| 8334 / 8748 | Launch phases (sunrise, claims) / registry fees, `fee-1.0` | Proposed Standard |
| 9154 / 8807 | Secure transfer codes / login security, `loginSec-1.0` | Proposed Standard |
| 3735 / 7451 | How to extend EPP / the IANA extension registry | Informational |
| 9874 | Deleting domain and host objects | Best Current Practice |

---
<!-- _class: dense -->
## Transport: TLS over TCP (RFC 5734)

- Server listens on TCP port **700**; one EPP session per TLS connection
- TLS is mandatory; RFC 8996 removed TLS 1.0 and 1.1, so use TLS 1.2 or 1.3 (BCP 195, RFC 9325)
- TLS must give **mutual** authentication: the registrar presents a client certificate as well as its login (RFC 5734 §8); registries add IP allow lists and rate limits
- Every frame is a **4-octet length** (including those 4 octets) followed by the XML

```bash
openssl s_client -connect epp.registry.example:700 -CAfile lab-ca.crt -brief </dev/null
# Protocol version: TLSv1.3   Verification: OK
openssl s_client -connect epp.registry.example:700 -CAfile lab-ca.crt -quiet \
    < <(sleep 2) | head -c 4 | od -An -tu1
#    0   0   6 177            <- 6 × 256 + 177 = 1713 octets: the greeting frame
```

Because of the length prefix you cannot type EPP into `openssl s_client`; you need a client.

---
<!-- _class: dense -->
## The Session

<div class="columns">
<div>

1. Client opens TLS; server sends a **greeting**
2. Client sends **login**: registrar ID, password, the objects and extensions it will use
3. Commands and responses, one at a time, in order
4. Client sends **logout**; server answers 1500 and closes

A `<hello/>` at any time returns a fresh greeting.

</div>
<div>

```xml
<greeting>
  <svID>Lab EPP Server</svID>
  <svDate>2026-10-21T02:03:45.532Z</svDate>
  <svcMenu>
    <version>1.0</version>
    <lang>en</lang>
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
    <svcExtension>
      <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
      <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
      ...
```

</div>
</div>

---
<!-- _class: dense -->
## Login

```xml
<command>
  <login>
    <clID>reg03</clID>  <pw>••••••••••••</pw>
    <options><version>1.0</version><lang>en</lang></options>
    <svcs>
      <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
      <svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
                    <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI></svcExtension>
    </svcs>
  </login>
  <clTRID>team03-login-1792548225-3250572-1</clTRID>
</command>
```

- The server answers only within the listed services (RFC 9038 covers the exceptions); `<pw>` is 6-16 characters, longer with RFC 8807

---
<!-- _class: dense table-compact -->
## Commands (RFC 5730 §2.9)

| Group | Command | Does |
|---|---|---|
| Session | `login`, `logout` | open and close the session (`hello` is a separate frame) |
| Query | `check` | is the object available? Several names per command |
| | `info` | full object data |
| | `poll` | read (`req`) or acknowledge (`ack`) queued service messages |
| | `transfer op="query"` | state of a transfer |
| Transform | `create`, `update`, `delete` | change objects |
| | `renew` | extend a domain's registration period |
| | `transfer op="request"`, `approve`, `reject`, `cancel` | move a domain to another registrar |

Every command carries a client transaction ID (`clTRID`); every response returns it with the server's `svTRID`. Keep both: they are how a registrar and a registry find the same transaction in their logs.

---
<!-- _class: dense table-compact -->
## Result Codes (RFC 5730 §3)

First digit: 1 = success, 2 = failure. Second digit: 0 syntax, 1 implementation, 2 security, 3 data management, 4 server, 5 connection.

| Code | Meaning | Code | Meaning |
|---|---|---|---|
| **1000** | completed successfully | **2201** | authorisation error (not your object, or a policy forbids it) |
| **1001** | completed; action pending | **2202** | invalid authorisation information |
| **1300** | no messages | **2302** | object exists |
| **1301** | ack to dequeue | **2303** | object does not exist |
| **1500** | ending session | **2304** | object status prohibits operation |
| 2004 | parameter value range error | **2305** | object association prohibits operation |
| 2104 | billing failure | **2306** | parameter value policy error |
| 2200 | authentication error | 2400 / 2500 | command failed / and server closing |

The `<msg>` text and an optional `<extValue><reason>` explain the failure. Read them before retrying.

---
<!-- _class: dense -->
## Objects and Their Links

```text
  contact tNN-holder ◄── registrant, admin, tech ──  domain teamNN.example ── DS records (secDNS)
                                                         │          │
                                         delegated to ───┤          └── superordinate of
                                                         v                     │
                                  host nsNN.example.net (external)   host ns1.teamNN.example
                                                                     (internal, has glue)
```

- Every object has a repository ID (`roid`), a sponsoring registrar (`clID`) and statuses
- **Contacts** and **hosts** are separate objects that domains point to
- A host is **internal** if its name is under a domain in this registry, otherwise **external**
- Links block deletes: a host that a domain uses has status `linked`

---
<!-- _class: dense -->
## The Poll Queue

The registry tells registrars about events they did not start (a transfer request, an approval, a status change) through a message queue:

```xml
<poll op="req"/>                                     <!-- client -->

<result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result>
<msgQ count="1" id="1">
  <qDate>2026-10-21T02:04:14.955Z</qDate>
  <msg>Transfer requested.</msg>
</msgQ>
<resData><domain:trnData> ... <domain:trStatus>pending</domain:trStatus> ...

<poll op="ack" msgID="1"/>                           <!-- client: remove it -->
```

- 1300 means the queue is empty; a message stays until it is acknowledged
- Registrars poll regularly; in gTLDs a transfer the losing registrar ignores for 5 calendar days is approved by default

---
<!-- _class: section-divider -->
# 3 · Objects, Renewals and Transfers

---
<!-- _class: dense -->
## Contacts (RFC 5733)

```xml
<contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0">
  <contact:id>t03-holder</contact:id>
  <contact:postalInfo type="int">
    <contact:name>Team 03 Holder</contact:name>
    <contact:org>Workshop Team 03</contact:org>
    <contact:addr><contact:street>1 Lab Street</contact:street><contact:city>Brisbane</contact:city>
      <contact:sp>QLD</contact:sp><contact:pc>4000</contact:pc><contact:cc>AU</contact:cc></contact:addr>
  </contact:postalInfo>
  <contact:voice>+61.730000000</contact:voice>
  <contact:email>team03@registrant.example</contact:email>
  <contact:authInfo><contact:pw>Contact-03-pw</contact:pw></contact:authInfo>
</contact:create>
```

- The client chooses the ID (3-16 characters, unique in the registry); phone numbers use `+CC.number` (`+61.730000000`)
- `postalInfo type="int"` is ASCII; `type="loc"` allows other scripts
- `<contact:disclose>` states what the registrant agrees to publish; registry policy and privacy law decide the rest

---
<!-- _class: dense -->
## Is the Name Available? `check` (RFC 5731)

```xml
<domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
  <domain:name>team04.example</domain:name>
  <domain:name>team03.example</domain:name>
</domain:check>
```

```xml
<domain:chkData>
  <domain:cd><domain:name avail="1">team04.example</domain:name></domain:cd>
  <domain:cd><domain:name avail="0">team03.example</domain:name>
             <domain:reason>In use</domain:reason></domain:cd>
</domain:chkData>
```

- `avail="1"` means a create would be accepted now, not that it is reserved for you
- `check` costs the registrar nothing, so registries can give it its own rate limit

---
<!-- _class: dense -->
## Creating a Domain

```xml
<domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
  <domain:name>team03.example</domain:name>
  <domain:period unit="y">1</domain:period>
  <domain:registrant>t03-holder</domain:registrant>
  <domain:contact type="admin">t03-holder</domain:contact><domain:contact type="tech">t03-holder</domain:contact>
  <domain:authInfo><domain:pw>Transfer-03-a1</domain:pw></domain:authInfo>
</domain:create>
```

```xml
<result code="1000"> ... <domain:creData><domain:name>team03.example</domain:name>
  <domain:crDate>2026-10-21T02:03:45.639Z</domain:crDate><domain:exDate>2027-10-21T02:03:45.639Z</domain:exDate>
```

- `period`: 1-99 years (`unit="y"`) or months (`"m"`); `authInfo` is required by the schema
- The domain is now in `addPeriod`, and the registrar's account has been charged

---
<!-- _class: dense -->
## Host Objects and Glue (RFC 5732)

```xml
<host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0">
  <host:name>ns1.team03.example</host:name>
  <host:addr ip="v4">192.0.2.103</host:addr>
  <host:addr ip="v6">2001:db8::3</host:addr>
</host:create>
```

- **Internal host** (`ns1.team03.example`): its domain must exist first (RFC 5732 §3.2.1); the lab registry also requires that you sponsor it (2201 otherwise); its addresses become **glue** in the TLD zone
- **External host** (`ns03.example.net`): no addresses needed; RFC 5732: "IP addresses are REQUIRED only as needed to produce DNS glue records"
- The lab registry rejects an internal host without an address: `2306 ... In-bailiwick hosts must include at least one IP address (glue record)`
- Hosts are never transferred on their own; they move with their superordinate domain

---
<!-- _class: dense -->
## Delegating: Name Server Updates

```xml
<domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
  <domain:name>team03.example</domain:name>
  <domain:add>
    <domain:ns>
      <domain:hostObj>ns1.team03.example</domain:hostObj>
      <domain:hostObj>ns03.example.net</domain:hostObj>
    </domain:ns>
  </domain:add>
</domain:update>
```

- `update` has `add`, `rem` and `chg` parts; one command can remove the old name servers and add new ones
- `hostObj` points to host objects; a registry whose greeting does not offer the host mapping uses `hostAttr` instead, with name and addresses inside the domain (RFC 5731 §1.1)
- A domain with no name servers has status `inactive` and is not in the zone
- gTLD target: changes visible in DNS within 60 minutes for 95% of ICANN's probes (Registry Agreement Spec 10)

---
<!-- _class: dense -->
## Reading an Object: `info`

```xml
<domain:infData>
  <domain:name>team03.example</domain:name>   <domain:roid>D3-RXX</domain:roid>
  <domain:status s="ok"/>
  <domain:registrant>t03-holder</domain:registrant> ...
  <domain:ns><domain:hostObj>ns1.team03.example</domain:hostObj>
             <domain:hostObj>ns03.example.net</domain:hostObj></domain:ns>
  <domain:clID>reg03</domain:clID>  <domain:crID>reg03</domain:crID>
  <domain:crDate>2026-10-21T02:03:45.639Z</domain:crDate>
  <domain:exDate>2027-10-21T02:03:45.639Z</domain:exDate>
</domain:infData>
<extension>
  <rgp:infData><rgp:rgpStatus s="addPeriod"/></rgp:infData>
  <secDNS:infData><secDNS:dsData><secDNS:keyTag>25232</secDNS:keyTag> ...
```

- Extensions add their own `infData`: grace-period state from `rgp`, DS records from `secDNS`
- A registrar that is not the sponsor gets less, unless it supplies the transfer code

---
<!-- _class: dense -->
## Renewing

```xml
<domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
  <domain:name>team03.example</domain:name>
  <domain:curExpDate>2028-10-21</domain:curExpDate>
  <domain:period unit="y">1</domain:period>
</domain:renew>
```

- `curExpDate` must match the current expiry date: a retried renew cannot add a second year by accident
- The response returns the new `exDate`; the domain enters `renewPeriod`
- Registries with an auto-renew grace period (.com has 45 days) renew at expiry and charge the registrar (`autoRenewPeriod`); a delete in that period refunds the renewal

---
<!-- _class: dense -->
## Transfers (RFC 5731 §3.2.4)

```text
gaining registrar          registry                         losing registrar
  transfer op="request"  ──>  checks authInfo, status, locks
  (with authInfo)        <──  1001, trStatus pending  ──poll──>  "Transfer requested."
                                                         <──  transfer op="approve"
                              trStatus clientApproved          (or op="reject")
  poll / info            <──  domain now yours, +1 year, transferPeriod
```

- If the losing registrar does nothing, the transfer is approved by default after 5 calendar days (gTLD Transfer Policy §3.5; `acDate` in the response)
- The gaining registrar can `cancel`; anyone involved can `transfer op="query"`
- Hosts under the domain, its name servers and its DS records move with it
- The lab server refuses a transfer within 60 days of creation (`2201 ... must not be within 60 days of its initial registration`); the lab turns that rule off

---
<!-- _class: dense -->
## Transfer Request and Response

```xml
<transfer op="request">
  <domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
    <domain:name>team03.example</domain:name>
    <domain:period unit="y">1</domain:period>
    <domain:authInfo><domain:pw>wpFn+Rb9v26BDWoH/UeSGzH1</domain:pw></domain:authInfo>
  </domain:transfer>
</transfer>
```

```xml
<result code="1001"><msg>Command completed successfully; action pending</msg></result>
<domain:trnData><domain:name>team03.example</domain:name><domain:trStatus>pending</domain:trStatus>
  <domain:reID>reg04</domain:reID><domain:reDate>2026-10-21T02:04:14.954Z</domain:reDate>
  <domain:acID>reg03</domain:acID><domain:acDate>2026-10-26T02:04:14.954Z</domain:acDate>
```

A wrong or expired code gives `2202 Invalid authorization information`.

---
<!-- _class: dense table-compact -->
## Transfer Codes Done Safely (RFC 9154)

| Old practice | RFC 9154 |
|---|---|
| Code set at creation and kept for years | Set **only when a transfer starts**, with a time-to-live set by the registrar |
| Short, chosen by a person | Random, at least **128 bits** (20 printable characters): `openssl rand -base64 18` |
| Stored in clear text, shown in `info` | Registry stores a **salted hash** (256-bit hash, 128-bit salt); `info` never returns it |
| Losing registrar keeps a copy | Only the registry keeps it; it is cleared after the transfer |

- To unset the code: `update` with an empty `<domain:pw/>`
- The lab server advertises RFC 9154 support but, in its default setting, returns the code in `info`, and the code it generates after a transfer is 16 characters. Test your registry before you rely on it.

---
<!-- _class: dense -->
## ICANN Transfer Policy (gTLDs)

**In force** (version updated 21 February 2024):
- Registrars let the registrant get the AuthInfo code and remove `clientTransferProhibited` themselves, or do it for them within 5 calendar days of the request (§I.A.5)
- The losing registrar may deny a transfer requested within 60 days of creation or of a previous transfer
- A 60-day inter-registrar transfer lock follows a Change of Registrant

**Adopted, not yet in force** (ICANN Board, 7 June 2026; implementation date still to be set):
- AuthInfo becomes the **Transfer Authorization Code (TAC)**, valid for 336 hours (14 days) from when it is set at the registry
- The registry stores the TAC at least to the standard of RFC 9154
- The gaining registrar's Form of Authorization is removed
- Locks of 720 hours after creation and after a transfer; the 60-day Change of Registrant lock goes
- New notices: when a TAC is issued, and within 24 hours of a completed transfer

ccTLDs set their own transfer rules.

---
<!-- _class: dense -->
## Deleting Hosts and Domains

- A domain **SHOULD NOT** be deleted while it has subordinate hosts; the server answers **2305** (RFC 5731 §3.2.2)
- A host that other domains use (`linked`) SHOULD NOT be deleted either (RFC 5732 §3.2.2), and those domains may belong to other registrars
- The common workaround renames the host to a "sacrificial" external name so the delete can go ahead. Renamed to a name that does not exist, the other domains' delegation goes to whoever registers that name; RFC 9874 says this MUST NOT be used
- **RFC 9874** (BCP, September 2025) allows three practices, e.g. renaming to a host under `sacrificial.invalid` (RECOMMENDED for that method) or a client-run sacrificial name server
- Inside the add grace period a delete frees the name immediately and refunds the registrar; after it, the domain goes to `pendingDelete` and the redemption period

The lab registry accepted a delete of a domain that still had a subordinate host. Registries differ; read their policy.

---
<!-- _class: section-divider -->
# 4 · DNSSEC at the Registry

---
<!-- _class: dense -->
## Getting the DS into the Parent

Module 7 ended with a signed `teamNN.example` and a CDS record. The parent zone (`example.`) needs a matching DS.

| Path | Who acts | Standard |
|---|---|---|
| Registrar sends the DS over EPP | registrar, on the registrant's or DNS operator's request | RFC 5910 `secDNS-1.1` |
| Registry reads CDS/CDNSKEY from the child | registry, polling or on request | RFC 7344, 8078, 9615, 9975 |
| Web form or email to the registrar | registrar staff, then EPP | none |

- All three end in the same place: the registry database, then the signed TLD zone
- The gTLD Registry Agreement (Spec 6) requires registries to accept "public-key material from child domain names in a secure manner" and lists RFC 5910 among the EPP RFCs they follow

---
<!-- _class: dense -->
## `secDNS-1.1`: DS Data or Key Data (RFC 5910)

<div class="columns">
<div>

### DS Data interface
- Client sends key tag, algorithm, digest type, digest
- Optional `keyData` inside it, so the server can check
- Registry publishes exactly what it receives

</div>
<div>

### Key Data interface
- Client sends the DNSKEY (flags, protocol, algorithm, public key)
- Registry computes the DS, with a digest type it chooses
- Registry publishes its own DS

</div>
</div>

- A server supports **one** interface, except during a migration; the other gets **2306**
- **DS Data is the usual choice:** it is what `dnssec-signzone`, `dnssec-policy` and CDS already produce, the child's operator picks the digest type, and the registry publishes no record it computed itself
- Key Data suits registries that want to verify the key or change digest types without the registrars

---
<!-- _class: dense -->
## Adding a DS: Four Fields from the DS Record

```bash
$ dnssec-dsfromkey -2 Kteam03.example.+013+25232.key
team03.example. IN DS 25232 13 2 E34BB5F977ACF186CEA77B1EC558B3047A8F4DE75F7F453A8FAC63C6B32664F3
```

```xml
<update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>team03.example</domain:name>
  </domain:update></update>
<extension>
  <secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
    <secDNS:add><secDNS:dsData>
      <secDNS:keyTag>25232</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType>
      <secDNS:digest>E34BB5F977ACF186CEA77B1EC558B3047A8F4DE75F7F453A8FAC63C6B32664F3</secDNS:digest>
    </secDNS:dsData></secDNS:add>
  </secDNS:update>
</extension>
```

---
<!-- _class: dense -->
## KSK Rollover at the Registry

```xml
<secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
  <secDNS:rem><secDNS:dsData>
    <secDNS:keyTag>20915</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType>
    <secDNS:digest>234DF971032783507C458FB74A40357695A8F4959023B01ABF72A818EAA52F3A</secDNS:digest>
  </secDNS:dsData></secDNS:rem>
  <secDNS:add><secDNS:dsData>
    <secDNS:keyTag>53602</secDNS:keyTag><secDNS:alg>13</secDNS:alg><secDNS:digestType>2</secDNS:digestType>
    <secDNS:digest>AD1AAE1CDCEA2605F41146B2D4F29C90E8250EB4777D2F0E7811C873B8E7273F</secDNS:digest>
  </secDNS:dsData></secDNS:add>
</secDNS:update>
```

- The server **must** process `rem` before `add` (RFC 5910 §5.2.5), so one command swaps the DS
- Swap only after the new KSK has signed the DNSKEY set for a DNSKEY TTL (double-KSK, Module 7)
- `<secDNS:rem><secDNS:all>true</secDNS:all></secDNS:rem>` removes every DS: the domain becomes insecure
- An optional `urgent="true"` asks for priority publication; a server that does not offer it returns 2102

---
<!-- _class: dense -->
## What a Registry Should Check

Before accepting a DS:
- **Digest type:** reject SHA-1 (1) for new DS records; the IANA registry marks it MUST NOT for delegations (Module 7). The lab registry answered `2004 Parameter value range error : Unsupported digestType`
- **Algorithm:** a number the IANA registry allows for signing
- **Syntax:** the schema already rejects a digest that is not hexadecimal

Before publishing it, optionally:
- **Match the child:** query the child's DNSKEY set and confirm a key matches the DS; a DS with no matching key makes the domain bogus for every validating resolver
- **Many DS records:** keep a limit; each one enlarges the TLD zone and its responses

Say why a DS was refused, in the result `<msg>` or `<extValue>`: the registrar can only pass on what the registry tells it.

---
<!-- _class: dense -->
## CDS and CDNSKEY: the Registry's View

- **Rollover** (RFC 7344): the CDS/CDNSKEY must be at the child apex, signed by a key that is in the current DNSKEY and DS sets, and must not break the delegation; otherwise ignore and log
- **Three uses** (RFC 8078): add the first DS, change the DS during a rollover, and delete all DS (`CDS 0 0 0 00`)
- **First DS** needs another proof of authenticity. RFC 8078 lists acceptance policies (authenticated channel, extra checks, accept after a delay, challenge, accept from inception); RFC 9615 lets the DNS operator sign the request under its own name servers' zones, e.g. `_dsboot.example.co.uk._signal.ns1.example.net`
- **Consistency** (RFC 9975, May 2026): query every name server of the child, over every address; if their CDS/CDNSKEY sets disagree, do nothing
- After a change, tell the registrar, for example with a change poll message (RFC 8590): the registrar's database still holds the old DS

A registry that scans CDS removes the registrar from routine rollovers; the EPP path remains for the first DS and for registries that do not scan.

---
<!-- _class: section-divider -->
# 5 · Extensions and Registration Data

---
<!-- _class: dense -->
## How EPP Is Extended

- RFC 3735 describes three kinds: **protocol-level** (new commands), **object-level** (new object types) and **command-response** (extra elements in `<extension>`, like `secDNS`)
- Each has an XML namespace; the greeting lists what the server supports, the login what the client uses
- **IANA EPP extensions registry** (RFC 7451): IETF extensions and registry-specific ones, last updated 2026-09-08
- **RFC 9038:** a server that must send an extension the client did not log in with puts it in `<extValue>` instead of failing
- Registry-specific extensions are common (eligibility, IDN tables, privacy, balances); check the registry's documentation before writing a client

If two extensions do the same job, prefer the IETF one: registrar software is more likely to support it.

---
<!-- _class: dense table-compact -->
## Extensions You Will Meet

| Extension | RFC | What it adds |
|---|---|---|
| Launch phases | 8334 (+ 7848 marks) | `sunrise` (trademark holders), `landrush`, `claims` (trademark notice), `open`, `custom` |
| Registry fees | 8748 | price and currency in `check`, and the agreed fee in transform commands |
| Allocation tokens | 8495 | a token that unlocks a reserved or premium name |
| Login security | 8807 | passwords longer than 16 characters, user agent, password and certificate expiry warnings |
| Change poll | 8590 | poll messages for changes the registry made itself |
| Maintenance notices | 9167 | planned outages through the poll queue and `info` |
| DNS TTL values | 9803 | the TTL of NS, DS and glue records for a delegation |
| Organisation mapping | 8543, 8544 | resellers and other organisations as objects |
| Additional email | 9873 | an internationalised email address for a contact |

---
<!-- _class: dense -->
## Registration Data: RDAP Replaces WHOIS

- **RDAP**: HTTPS and JSON, with standard queries and structured, redactable answers (RFC 7480, 7481, 9082, 9083; bootstrap RFC 9224)
- **gTLDs:** since **28 January 2025** RDAP is the definitive source; registries and registrars must run RDAP under the gTLD RDAP Profile and are no longer required to run WHOIS, except for .com, .name and .post
- **ccTLDs:** each sets its own policy: RDAP, WHOIS, both, or a web page
- **Privacy:** redaction is marked in the response (RFC 9537); access to redacted data is a policy matter (GDPR and national law)
- EPP statuses map onto RDAP statuses (RFC 8056), so `clientHold` appears as `client hold`

```bash
curl -s https://rdap.example/domain/team03.example | jq '.status, .nameservers[].ldhName'
```

---
<!-- _class: dense -->
## Policy in Software

The same EPP command means different things in different TLDs; the registry configures:

- **Eligibility:** local presence, trademark or licence checks, often an extension field or a manual queue (`pendingCreate`)
- **Reserved and blocked names:** country names, registry names, names reserved by contract
- **Pricing:** standard, premium and promotional prices; the fee extension shows them before the create
- **Lifecycle timings:** each grace period, the auto-renew rule, the transfer wait and locks
- **Data:** which contacts are required, which fields are published, how long records are kept
- **DNS:** host model (`hostObj` or `hostAttr`), glue rules, DS limits and checks, CDS scanning

Write these rules down for registrars (the registry's EPP and policy documents) and test them in an OT&E (test) environment before go-live.

---
<!-- _class: section-divider -->
# 6 · Registry Operations

---
<!-- _class: dense table-compact -->
## Service Levels (gTLD Registry Agreement 2026, Spec 10)

| Service | Monthly target |
|---|---|
| DNS service availability | 100% (0 minutes of downtime) |
| Each name server | ≤ 432 min downtime (about 99%) |
| DNS answers | UDP ≤ 500 ms, TCP ≤ 1500 ms, for 95% of queries |
| DNS update time | ≤ 60 min, for 95% of probes |
| EPP service availability | ≤ 864 min downtime (about 98%) |
| EPP session / query / transform commands | ≤ 4000 / 2000 / 4000 ms, for 90% of commands |
| RDAP availability; query time | ≤ 864 min downtime; ≤ 4000 ms for 95% of queries |

- Planned maintenance counts as downtime; ICANN measures from outside
- ccTLDs set their own targets

---
<!-- _class: dense -->
## Running the EPP Service

**Monitor:**
- Availability and round-trip time per command type, from outside, logged in as a test registrar
- Result codes per registrar, so that a jump in 2xxx codes from one registrar stands out
- Sessions per registrar, `check` rates, and poll queues that nobody drains
- Certificate expiry on the server and the registrars' client certificates

**Protect:**
- TLS 1.2+, client certificates and IP allow lists per registrar; login passwords rotated (RFC 8807 warns before expiry)
- Rate limits and session limits (2502 when exceeded); a separate limit for `check`
- Every transaction logged with `clTRID`, `svTRID`, registrar, command and result; registrars log the same IDs

---
<!-- _class: dense -->
## Escrow, Billing and Registrars

- **Data escrow:** a copy of the registration data held by a third party, so a TLD survives the failure of its registry. gTLDs: a full deposit every Sunday and full or differential deposits on the other days, in RFC 8909/9022 format (Spec 2)
- **Registrar accounts:** prepaid balance or credit limit; a create, renew, transfer or restore that the balance cannot cover returns **2104 Billing failure**
- **Credits:** deletes inside a grace period refund the registrar (RFC 3915); the AGP Limits Policy stops abuse of add-grace refunds in gTLDs
- **Registrar onboarding:** agreement, accreditation checks, an OT&E account and a test script before production credentials
- **Reports:** transactions, registrations and billing per registrar per month; gTLDs also report to ICANN

---
<!-- _class: dense -->
## Registry Software

| System | Origin | Notes |
|---|---|---|
| FRED | CZ.NIC, open source | binary packages for Debian 12; PostgreSQL, CORBA, Apache |
| Nomulus | Google, open source | runs on Google Kubernetes Engine and Google Cloud services |
| Namingo | open source (MIT) | PHP and Swoole EPP server; Debian 12 and 13 supported by its installer; this module's lab server |
| CoCCA | — | covered in Module 10 |

- Whatever the software, check its behaviour against the RFCs before you depend on it. The lab server, for example, answers 1001 to a delete inside the add grace period although the name is freed at once
- On the registrar side, Debian packages the Perl library `libnet-epp-perl` (Net::EPP); the lab client is a short script on top of it

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

- **Registry server** (instructor): EPP on `epp.registry.example:700` (address on your lab sheet) for the `.example` TLD; certificate from the lab CA (`lab-ca.crt`). Every minute the registry's zone writer turns its database into the `example.` zone that the Module 7 BIND signs and serves
- **Your account:** registrar `regNN`, its password, and a client certificate and key signed by the lab CA (`EPP_CERT`, `EPP_KEY`); teams work in pairs for the transfer task (your partner is team `PP`)
- **Client VM:** Debian 13 with `libnet-epp-perl`, `openssl`, `bind9-utils` and `bind9-dnsutils`; the `epp-send` script and the XML files `01-…` to `56-…`
- **How to run a step:** `TEAM=NN EPP_PW=… epp-send 02-login.xml <files> 03-logout.xml` prints every frame sent and received
- **Lab rules:** the 60-day transfer lock is off; transfers auto-approve after 5 days; `oldNN.example` was created 10 days ago for you

---
<!-- _class: dense -->
## Lab 9.1: Connect and Log In (15 min)

1. Check the server certificate and TLS version: `openssl s_client -connect epp.registry.example:700 -CAfile lab-ca.crt -brief </dev/null`
2. Read the 4-octet frame length of the greeting (`-quiet … | head -c 4 | od -An -tu1`)
3. `epp-send 01-hello.xml`: list the objects and extensions the server offers
4. `epp-send 02-login.xml 03-logout.xml`: expect 1000, then 1500
5. Repeat with a wrong `EPP_PW`; with the system CA bundle as `EPP_CA`; with no `EPP_CERT`; with your partner's certificate

> **Checkpoint:** TLS 1.2 or 1.3 with "Verification: OK"; login 1000; wrong password 2200; untrusted server certificate refused by the client; no client certificate refused by the server; the wrong registrar's certificate 2201

---
<!-- _class: dense -->
## Lab 9.2: Contacts, Hosts and Domains (25 min)

1. `10-domain-check.xml`: your name and your partner's
2. `11-contact-create.xml`, then `12-domain-create.xml` (`teamNN.example`, 1 year)
3. Edit `13-host-create.xml`: replace the two addresses with your Module 7 server's (lab sheet); send it to create `ns1.teamNN.example` with glue
4. `14-host-create-external.xml`: `nsNN.example.net`, no addresses
5. `15-domain-update-ns.xml`: delegate to both hosts
6. `16-domain-info.xml` and `17-host-info.xml`: read the statuses, `roid`, dates and `rgpStatus`
7. Copy `13` without the `host:addr` lines and send it; send `12` again: note the codes

> **Checkpoint:** `info` shows both name servers, status `ok` and `rgpStatus addPeriod`; the host shows `linked`; you can explain 2306 and 2302

---
<!-- _class: dense -->
## Lab 9.3: Publish Your DS (15 min)

1. Get your DS from Module 7: `dig @ns1.teamNN.example teamNN.example CDS +short`, or `dnssec-dsfromkey -2` on your KSK
2. Put the key tag, algorithm, digest type and digest (without the space `dig` may insert) into `20-domain-update-ds-add.xml`; send it
3. `16-domain-info.xml`: find your DS under `secDNS:infData`
4. Try a SHA-1 DS (`dnssec-dsfromkey -1`, digest type 1): note the result
5. **Discussion:** after a KSK rollover (Lab 7.4), how would `21-domain-update-ds-swap.xml` change? What would a registry that scans CDS do instead?

> **Checkpoint:** the DS in `info` matches your CDS record field for field; within about a minute `dig @registry teamNN.example DS +short` returns it; you can explain why `rem` is processed before `add`

---
<!-- _class: dense -->
## Lab 9.4: Transfer and Renew (20 min)

Work with team `PP`. Each team moves the other team's domain.

1. Both teams: `export PARTNER=PP` (your partner's number). **Losing registrar** (owner): `export AUTHINFO=$(openssl rand -base64 18)`, send `35-domain-update-authinfo.xml`, give `$AUTHINFO` to your partner
2. **Gaining registrar:** `AUTHINFO=… epp-send … 30-domain-transfer-request.xml 31-domain-transfer-query.xml` (expect 1001, `pending`); try a wrong code first
3. **Losing registrar:** `32-poll-req.xml` (1301), `33-domain-transfer-approve.xml`, then `MSGID=<the id= in the msgQ line> epp-send … 34-poll-ack.xml`
4. **Gaining registrar:** `36-domain-info-partner.xml` (new `clID`, `transferPeriod`, DS and name servers kept); `CUREXPDATE=… 37-domain-renew.xml`

> **Checkpoint:** you sponsor your partner's domain, its expiry moved twice (transfer, then renew), and a wrong code gives 2202

---
<!-- _class: dense -->
## Lab 9.5: Delete and Restore (15 min)

1. **Add grace:** `50-domain-create-spare.xml`, `51-domain-delete-spare.xml`, `52-domain-check-spare.xml`: the name is available again at once
2. **Redemption:** note the time (`date -u +%Y-%m-%dT%H:%M:%SZ`), send `53-domain-delete-old.xml` (1001), then `54-domain-info-old.xml`: `pendingDelete` and `redemptionPeriod`
3. **Restore request:** note the time again, send `55-rgp-restore-request.xml`, then `54`: `pendingRestore`
4. **Restore report:** `DELTIME=<time of 53> RESTIME=<time of 55> epp-send … 56-rgp-restore-report.xml`, then `54`: status `ok`, no RGP status

> **Checkpoint:** you can draw the RFC 3915 state diagram from what you saw, and say which delete earned a refund under RFC 3915

**Discussion:** a customer's domain expired 20 days ago and its website is down. What can the registrar still do, and what does it cost?

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 5730-5734: EPP core, objects, TLS transport; RFC 8996
- RFC 5910: DNSSEC extension; RFC 3915: grace periods
- RFC 9154: secure transfer codes; RFC 9874: deletion (BCP)
- RFC 3735, 7451 and the IANA EPP extensions registry
- RFC 8334 (7848), 8748, 8495, 8807, 8590, 8543/8544, 9038, 9167, 9803; 8056
- RFC 7344, 8078, 9615, 9975: CDS/CDNSKEY
- RFC 7480, 7481, 9082, 9083, 9224, 9537: RDAP
- RFC 8909, 9022: escrow
- ICANN: EPP status codes, Transfer Policy, base Registry Agreement (12 March 2026; Specs 2, 6, 10)

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>openssl s_client -connect host:700 -brief
epp-send 02-login.xml cmd.xml 03-logout.xml
dnssec-dsfromkey -2 Kzone.+013+id.key
dig zone CDS +short
dig @parent zone DS +short
openssl rand -base64 18
curl https://rdap.host/domain/name
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. A transfer request for a name created last week returns 2201; another, for a different name, returns 2304. What does each code tell the registrar?
2. What is the difference between `clientHold` and `clientTransferProhibited`?
3. Why is the DS Data interface of RFC 5910 usually preferred over Key Data?
4. A domain is deleted on day 3 after creation, and another on day 300. What happens to each?
5. Name three RFC 9154 requirements for transfer codes.
6. A registry scans CDS records. Under what conditions must it ignore a CDS RRset for a signed child?

<!--
Answers:
1. 2201 is an authorisation error: a policy forbids this registrar the action, here the lock in the first 60 days after creation (the lab server's message says so). 2304 means a status on the object prohibits it, e.g. clientTransferProhibited, serverTransferProhibited or pendingDelete. A wrong transfer code would be 2202.
2. clientHold removes the domain from the zone (it stops resolving); clientTransferProhibited only blocks transfer requests. Both are set by the sponsoring registrar.
3. DS Data matches what signers and CDS already produce, the child's operator chooses the digest type, and the registry publishes exactly what it was given instead of computing records itself.
4. Day 3 is in the add grace period: the name is purged at once and the registrar is credited. Day 300: pendingDelete with redemptionPeriod (30 days in gTLDs), restorable with a restore request and report, then pendingDelete (5 days for .com) and purge.
5. Any three of: generated from a secure random source with at least 128 bits of entropy; set only while a transfer is in process (with a TTL); stored by the registry as a salted hash (256-bit hash, 128-bit salt); never returned in info responses; not stored by the losing registrar; cleared after the transfer; 2202 when it does not match or is unset.
6. RFC 7344: it is not at the child apex, it is not signed by a key in both the current DNSKEY and DS sets, or applying it would break the delegation. RFC 9975 adds: the CDS/CDNSKEY sets from the child's name servers disagree.
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
