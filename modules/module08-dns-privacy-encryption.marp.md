---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 8: DNS Privacy and Encryption Technologies (DoT, DoH)

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Recall** what a DNS query reveals, to whom, and which IETF protocols protect it (DoT, DoH, DoQ, padding, DDR, DNR, ODoH) and their status
- **Explain** the strict and opportunistic usage profiles, and how a client authenticates an encrypted resolver
- **Configure** DNS over TLS and DNS over HTTPS on a BIND 9.20 resolver, and test them with `dig` and `kdig`
- **Configure** Unbound to forward every query over TLS
- **Publish** DDR records and check that the certificate supports verified discovery
- **Measure** what padding hides and what encryption leaves visible on the wire
- **Evaluate** DoT, DoH and DoQ, discovery methods and logging policy for an ISP, enterprise or ccTLD

---
<!-- _class: dense table-compact -->
## What Changed Recently

Older DNS privacy training is out of date in five places:

| Then | Now |
|---|---|
| DoT and DoH | Also DoQ (RFC 9250, 2022) and DNS over CoAP for constrained devices (RFC 9953, March 2026) |
| Encrypted resolver set by hand | Discovery: DDR (RFC 9462) and DNR (RFC 9463), both November 2023 |
| SNI shows the server name | Encrypted ClientHello (RFC 9849, March 2026), keys in SVCB/HTTPS records (RFC 9848) |
| TLS 1.3 is RFC 8446 | RFC 9846 (July 2026); new TLS protocols must require TLS 1.3 (RFC 9852) |
| Only the stub-to-resolver hop | Opportunistic resolver-to-authoritative encryption (RFC 9539, Experimental, 2024) |

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. The DNS privacy problem (15m)
2. DNS over TLS (20m)
3. DNS over HTTPS and QUIC (20m)
4. Discovery and deployment (15m)
5. Beyond the stub: padding, XoT, ODoH, DNSCrypt (15m)
6. Recap and questions (5m)

## Agenda (90 min Lab)

1. Lab 8.1 See plaintext DNS (15m)
2. Lab 8.2 DoT and DoH on your resolver (25m)
3. Lab 8.3 Forward over TLS with Unbound (15m)
4. Lab 8.4 Resolver discovery with DDR (20m)
5. Lab 8.5 Padding on the wire (15m)

---
<!-- _class: section-divider -->
# 1 · The DNS Privacy Problem

---
<!-- _class: dense -->
## What a DNS Query Reveals

- **The name:** every site, mail domain and API a device uses, often before any connection starts
- **The client:** its IP address, so a household, office or subscriber
- **The timing:** when the device is active, and what it does in sequence
- **Extras:** EDNS Client Subnet (RFC 7871) passes part of the client's address on to authoritative servers

Traditional DNS sends all of this in cleartext over UDP or TCP port 53. Anyone on the path can read it, log it or change it.

The IETF analysis of these risks is RFC 9076 (2021), which obsoletes RFC 7626.

---
<!-- _class: dense -->
## Who Can See Your Queries

```text
 stub ──(1)──> recursive resolver ──(2)──> root, TLD, authoritative servers
  │                   │                              │
  Wi-Fi, LAN, ISP     resolver operator:             each server sees the part
  see hop 1           sees everything, keeps logs    of the name it is asked for
```

| Observer | Sees | Protection |
|---|---|---|
| On path, hop 1 | names and client address | DoT, DoH, DoQ |
| Resolver operator | everything | policy and law, not cryptography |
| On path, hop 2 | names, resolver address | RFC 9539 (experimental), QNAME minimisation |
| Authoritative servers | names (or parts), resolver or ECS address | QNAME minimisation; no ECS |

---
<!-- _class: dense -->
## Threat Model (RFC 9076)

<div class="columns">
<div>

### Passive
- Monitoring of hop 1 by anyone on the network
- Bulk collection at ISPs and exchange points
- Correlating DNS with later traffic

</div>
<div>

### Active
- Rewriting or blocking answers (filtering, censorship)
- Redirecting a client to a hostile resolver
- Downgrading encrypted DNS back to cleartext

</div>
</div>

### At the endpoints
- Resolver logs kept, shared or sold; data handed over on request
- Authoritative servers that see client subnets through ECS

Encryption deals with the passive observer on the path. It moves trust to the resolver operator; it does not remove it.

---
<!-- _class: dense -->
## Seen on the Wire (Lab 8.1)

`tshark` on the resolver's network, one `dig @192.0.2.10 secret-project.team01.example` (excerpt; IDs and the AAAA lookup removed):

```text
192.0.2.30  192.0.2.10  DNS  Standard query A secret-project.team01.example
192.0.2.10  192.0.2.1   DNS  Standard query NS team01.example
192.0.2.1   192.0.2.10  DNS  Standard query response NS team01.example ...
192.0.2.10  192.0.2.1   DNS  Standard query A secret-project.team01.example
192.0.2.1   192.0.2.10  DNS  Standard query response A ... A 192.0.2.81
192.0.2.10  192.0.2.30  DNS  Standard query response A ... A 192.0.2.81
```

- Line 1: who asked (192.0.2.30) and for what
- Lines 2-5: the resolver's own queries, also readable; the first asks only for `team01.example` (QNAME minimisation, Module 6)

---
<!-- _class: dense -->
## DNSSEC and Encryption Solve Different Problems

| | DNSSEC (Module 7) | DoT, DoH, DoQ |
|---|---|---|
| Protects | integrity of the data | confidentiality of one hop |
| Works across | caches, any transport | one connection |
| Proves the answer is genuine | yes | no: a lying resolver is still believed |
| Hides the query | no | yes, from the path |

You want both: a validating resolver reached over an encrypted, authenticated connection.

Module 6 covers two privacy measures that need no encryption: **QNAME minimisation** (RFC 9156) and **DNS Cookies** (RFC 7873, 9018).

---
<!-- _class: dense table-compact -->
## The Standards Map

| RFC | Title (short) | Status |
|---|---|---|
| 9076 | DNS privacy considerations (obsoletes 7626) | Informational |
| 7858, 8310 | DNS over TLS; usage profiles | Proposed Standard |
| 8484 | DNS queries over HTTPS | Proposed Standard |
| 9250 | DNS over dedicated QUIC connections | Proposed Standard |
| 7830, 8467 | EDNS(0) padding option; padding policies | Proposed Standard; Experimental |
| 8932 | Recommendations for privacy service operators (BCP 232) | BCP |
| 9460, 9461 | SVCB and HTTPS records; SVCB for DNS servers | Proposed Standard |
| 9462, 9463 | DDR; DNR | Proposed Standard |
| 9103 | Zone transfer over TLS (XoT) | Proposed Standard |
| 9230, 9539, 8094 | Oblivious DoH; resolver-to-authoritative; DNS over DTLS | Experimental |

---
<!-- _class: dense -->
## The Operator's Side: Logs and Policy

Encryption sends all of a user's queries to one operator. RFC 8932 (BCP 232) tells that operator what to do:

- **Minimise data:** log only what operations need; keep logs for a short, stated time
- **Do not leak upstream:** do not send ECS, or offer a separate service that does (§5.3.1)
- **Use the transport well:** DoT and DoH, padding, current TLS (§5.1)
- **Protect data at rest:** pseudonymise or discard client addresses (§5.2)
- **Publish a Recursive operator Privacy Statement (RPS):** what is logged, for how long, who sees it, which filtering applies (§6)

Treat query logs that hold client addresses as personal data: check your country's privacy and data retention law before you choose what to keep.

---
<!-- _class: section-divider -->
# 2 · DNS over TLS

---
<!-- _class: dense -->
## DoT in One Slide (RFC 7858)

- The client opens TCP to **port 853** and starts TLS at once; then sends ordinary DNS messages with the 2-octet length prefix of DNS over TCP
- **Never cleartext on 853:** clients and servers MUST NOT send unencrypted DNS on that port
- One connection carries many queries; responses may come **out of order**, so clients match on the message ID and question
- Keep connections open and reuse them; use TLS session resumption, and TCP Fast Open where available
- ALPN token **`dot`**; TLS 1.2 or later (RFC 8310); IANA service name `domain-s`, TCP/853 (UDP/853 is for DTLS and DoQ)

The firewall sees TCP to port 853, so DoT is easy to identify, and easy to block.

---
<!-- _class: dense -->
## Usage Profiles (RFC 8310)

<div class="columns">
<div>

### Strict
- The client must authenticate the server
- No encrypted, authenticated connection: **hard fail**, no fallback
- Needs an **authentication domain name** (ADN), or an SPKI pin set
- Protects against active attackers

</div>
<div>

### Opportunistic
- Try encryption; accept any certificate, or none
- Falls back to cleartext if DoT is not available
- Protects against passive monitoring only
- Better than cleartext; a stepping stone to strict

</div>
</div>

The ADN comes from configuration, DHCP or RA (DNR), or an SVCB record (DDR). It is checked against the certificate's subjectAltName (RFC 9525, which obsoletes RFC 6125).

---
<!-- _class: dense -->
## The Resolver's Certificate

- **Names:** the ADN as a DNS name in subjectAltName; add the resolver's **IP address** as an IP SAN if clients should find it by DDR (Lab 8.4)
- **Issuer:** a public CA for public resolvers; your own CA when every client is managed (the lab uses a team CA)
- **Keys:** ECDSA P-256 is small and fast; renew automatically before expiry, and monitor expiry dates
- **Visible:** the client's TLS ClientHello still shows the **SNI** (the server name) and ALPN in cleartext

```bash
openssl x509 -in resolver.crt -noout -subject -ext subjectAltName
```
```text
subject=CN=resolver.team01.example
X509v3 Subject Alternative Name:
    DNS:resolver.team01.example, IP Address:192.0.2.10
```

---
<!-- _class: dense -->
## DoT on BIND 9.20

```text
tls resolver-tls {
    cert-file "/etc/bind/tls/resolver.crt";
    key-file  "/etc/bind/tls/resolver.key";
};
options {
    listen-on port 53  { any; };
    listen-on port 853 tls resolver-tls { any; };     // DoT
    ...
};
```

- `tls` names a key and certificate; `listen-on ... tls NAME` turns a listener into DoT
- `tls ephemeral` makes a throw-away self-signed certificate: fine for tests and opportunistic clients, useless for strict ones
- The `tls` block also sets `protocols`, `ciphers` and session tickets; BIND accepts TLS 1.2 and 1.3 by default
- The key file must be readable by `named` (group `bind`, mode 640) and nobody else

---
<!-- _class: dense -->
## The Same on Unbound

```text
server:
    interface: 192.0.2.20@53
    interface: 192.0.2.20@853        # DoT (tls-port)
    interface: 192.0.2.20@443        # DoH (https-port)
    tls-service-key: "/etc/unbound/resolver.key"
    tls-service-pem: "/etc/unbound/resolver.crt"
    tls-port: 853
    https-port: 443
    http-endpoint: "/dns-query"
```

- Only interfaces listed with `@853` (and `@443`) get the TLS (and HTTPS) service
- Debian 13's Unbound 1.26 is built with nghttp2, so it serves DoH itself
- `dnsdist` 1.9 (Debian 13) can front any resolver with DoT, DoH and DNSCrypt; the Debian build has no DoQ

---
<!-- _class: dense -->
## Testing DoT

```text
$ kdig @192.0.2.10 +tls-ca=ca.crt +tls-hostname=resolver.team01.example secret-project.team01.example
;; TLS session (TLS1.3)-(ECDHE-X25519)-(ECDSA-SECP256R1-SHA256)-(AES-256-GCM)
;; ->>HEADER<<- opcode: QUERY; status: NOERROR; id: 29013
;; From 192.0.2.10@853(TLS) in 1.4 ms
```

| `dig` and `kdig` option | Profile |
|---|---|
| `+tls` | opportunistic: encrypt, verify nothing |
| `+tls-ca[=FILE]` | verify the chain (system bundle, or FILE) |
| `+tls-hostname=NAME` | verify the name: strict, with `+tls-ca` |

---
<!-- _class: dense -->
## When Authentication Fails

```text
$ dig @192.0.2.10 +tls-ca=ca.crt +tls-hostname=wrong.team01.example ...
;; TLS peer certificate verification for 192.0.2.10#853 failed: hostname mismatch

$ dig @192.0.2.10 +tls-ca +tls-hostname=resolver.team01.example ...
;; TLS peer certificate verification for 192.0.2.10#853 failed: unable to get local issuer certificate

$ dig @192.0.2.10 +tls ... +short
192.0.2.81
```

- Wrong name, or a CA the client does not trust: a strict client stops
- `+tls` alone still gets an answer: encrypted, but from whoever answered
- `dig` reports the failure and still exits 0; `kdig` exits 1. Scripts should check the output

---
<!-- _class: dense -->
## Performance and Operations

- **Connection setup:** TCP + TLS 1.3 adds one round trip before the first query; reuse and session resumption remove it for later ones
- **Idle connections:** keep them open, but close idle ones under load; both sides MUST cope with a closed connection (RFC 7858 §3.4; `edns-tcp-keepalive`, RFC 7828)
- **Server load:** many long-lived TCP connections and TLS handshakes; size memory, file descriptors and CPU for them (RFC 7766, RFC 9210 for DNS over TCP)
- **Certificates:** expiry breaks every strict client at once; alert well before it
- **Monitoring:** connections, handshake failures and query rates per transport; probe with `kdig +tls-ca +tls-hostname`

---
<!-- _class: dense -->
## DoT on the Wire (Lab 8.2)

Same query, now over DoT (excerpt; TCP segments and some responses removed):

```text
192.0.2.30  192.0.2.10  TLSv1.2  Client Hello (SNI=resolver.team01.example)
192.0.2.10  192.0.2.30  TLSv1.3  Server Hello, Change Cipher Spec, Application Data ...
192.0.2.30  192.0.2.10  TLSv1.3  Application Data
192.0.2.10  192.0.2.1   DNS      Standard query NS team01.example
192.0.2.10  192.0.2.1   DNS      Standard query A secret-project.team01.example
192.0.2.10  192.0.2.30  TLSv1.3  Application Data
```

- Hop 1: only the resolver's name (SNI), ALPN `dot`, and sizes and timing
- Hop 2: still cleartext. DoT protected the client, not the resolver's own lookups
- `tshark` labels the ClientHello record `TLSv1.2` for compatibility; the session is TLS 1.3

---
<!-- _class: section-divider -->
# 3 · DNS over HTTPS and QUIC

---
<!-- _class: dense -->
## DoH in One Slide (RFC 8484)

- A DNS message carried in an HTTPS request to a **URI template**, for example `https://resolver.team01.example/dns-query{?dns}`
- **GET:** the query in the `dns` parameter, base64url without padding; **POST:** the query as the body
- Media type **`application/dns-message`**: the ordinary DNS wire format
- Servers MUST implement both GET and POST; HTTP/2 is the minimum RECOMMENDED version
- Clients SHOULD use DNS message ID **0**, so identical GET requests are cacheable
- Runs on port 443 alongside web traffic: hard to tell apart, hard to block

The URI is configured or discovered; a client MUST NOT switch to another URI just because a server push or an unsolicited answer named it (RFC 8484 §3).

---
<!-- _class: dense -->
## Wire Format Only

RFC 8484 defines one media type: **`application/dns-message`**. Clients and servers MUST support it.

- **JSON APIs are vendor-specific.** Some public resolvers offer a JSON interface with their own URLs and parameters; it is not part of RFC 8484 and not interoperable
- Other media types MAY be negotiated, but none is standardised

Tested on the lab resolver (BIND 9.20):

```text
$ curl ... -H 'accept: application/dns-message' 'https://resolver.team01.example/dns-query?dns=AAAB...'
HTTP/2 200
content-type: application/dns-message

$ curl ... -H 'accept: application/dns-json' '...dns-query?name=www.team01.example&type=A'
HTTP/2 400
```

---
<!-- _class: dense -->
## A DoH Exchange

```bash
curl --cacert ca.crt --resolve resolver.team01.example:443:192.0.2.10 \
  -H 'accept: application/dns-message' -o answer.bin -D - \
  'https://resolver.team01.example/dns-query?dns=AAABAAABAAAAAAAAA3d3dwZ0ZWFtMDEHZXhhbXBsZQAAAQAB'
```

```text
HTTP/2 200
content-type: application/dns-message
content-length: 52
cache-control: max-age=60
```

- The `dns` value is the binary query for `www.team01.example A`, ID 0, base64url-encoded
- The body is a DNS response; `max-age` equals the record's remaining TTL
- `kdig +https` and `dig +https` (POST) or `dig +https-get` do the encoding for you

---
<!-- _class: dense -->
## DoH and HTTP Caching

- DoH responses are HTTP responses: browsers, proxies and CDNs may cache them
- The HTTP freshness lifetime MUST be no longer than the smallest TTL in the Answer section; negative answers use the SOA MINIMUM (RFC 8484 §5.1)
- Clients MUST subtract the HTTP `Age` header from the DNS TTLs
- HTTP cookies SHOULD NOT be accepted by DoH clients unless a use case needs them: they identify the client across queries (§8)
- HTTP adds headers (user agent, language) that cleartext DNS never carried; minimise them

---
<!-- _class: dense -->
## DoH on BIND 9.20

```text
http resolver-http {
    endpoints { "/dns-query"; };
};
options {
    listen-on port 443 tls resolver-tls http resolver-http { any; };   // DoH
};
```

```text
$ kdig @192.0.2.10 +https +tls-ca=ca.crt +tls-hostname=resolver.team01.example www.team01.example
;; HTTP session (HTTP/2-POST)-(resolver.team01.example/dns-query)-(status: 200)
;; From 192.0.2.10@443(HTTPS) in 1.7 ms
```

- One `tls` block can serve DoT and DoH; one `http` block can list several endpoints; port 443 must not clash with a web server on the same address

---
<!-- _class: dense -->
## Deploying DoH

- **Front ends:** run DoH on the resolver, or terminate it on a proxy or load balancer (for example dnsdist) and pass plain DNS to the resolver
- **Behind a proxy**, the resolver sees the proxy's address: logging, ACLs and rate limits move to the front end
- **Load balancing:** HTTP/2 multiplexes many queries on one connection; balance connections, not packets
- **Shared hosting with the web:** possible, but the DoH endpoint inherits the web stack's logs, cookies and outages
- **For the network operator:** DoH looks like other HTTPS traffic; only the server's address and SNI show it is DNS

---
<!-- _class: dense -->
## DNS over QUIC (RFC 9250)

- QUIC on **UDP port 853**, ALPN **`doq`**; QUIC itself uses TLS 1.3
- **One query per QUIC stream**, so one lost packet delays only its own query (no head-of-line blocking as on TCP)
- Messages keep the 2-octet length prefix; the DNS message ID MUST be **0**
- 0-RTT on resumption saves a round trip, but 0-RTT data can be replayed and links sessions; RFC 9250 §5.5.3 and §7.1 limit it
- Suited to resolver-to-authoritative use too (RFC 9539 allows DoQ and DoT)

**On Debian 13:** `kdig +quic` (knot-dnsutils 3.4) and Knot DNS 3.4 (authoritative) speak DoQ. BIND 9.20, Unbound 1.26 and dnsdist 1.9 as packaged do not serve it.

---
<!-- _class: dense -->
## DoQ in Practice (Instructor Demo)

Knot DNS 3.4 with `listen-quic: 192.0.2.40@853`, queried with `kdig`:

```text
$ kdig @192.0.2.40 +quic +tls-ca=ca.crt +tls-hostname=resolver.team01.example www.team01.example
;; QUIC session (QUICv1)-(TLS1.3)-(ECDHE-X25519)-(ECDSA-SECP256R1-SHA256)-(AES-256-GCM)
;; ->>HEADER<<- opcode: QUERY; status: NOERROR; id: 0
;; Flags: qr aa rd; QUERY: 1; ANSWER: 1; AUTHORITY: 0; ADDITIONAL: 1
;; PADDING: 401 B
www.team01.example.     60      IN      A       192.0.2.80
;; Received 468 B
;; From 192.0.2.40@853(QUIC) in 5.5 ms
```

- `id: 0` as RFC 9250 requires; `aa` because Knot answers authoritatively
- The same certificate, the same strict checks as DoT

---
<!-- _class: dense table-compact -->
## DoT, DoH and DoQ Compared

| | DoT | DoH | DoQ |
|---|---|---|---|
| RFC | 7858, 8310 | 8484 | 9250 |
| Transport, port | TCP 853 | TCP 443 (HTTP/2); UDP 443 (HTTP/3) | UDP 853 |
| ALPN | `dot` | `h2`, `h3` | `doq` |
| Visible to the network | port 853 | looks like any HTTPS | UDP 853 |
| Head-of-line blocking | yes (TCP) | yes on HTTP/2 | no |
| Extra layers | TLS | TLS + HTTP (headers, cookies, caches) | QUIC |
| BIND 9.20 / Unbound 1.26 server | yes / yes | yes / yes | no / no |

Choose by client population: offer DoT and DoH; add DoQ when your software supports it.

---
<!-- _class: section-divider -->
# 4 · Discovery and Deployment

---
<!-- _class: dense -->
## How Does a Client Find an Encrypted Resolver?

<div class="columns">
<div>

### Configured
- Typed in by the user or pushed by device management
- Built-in lists of public providers in apps and OSes
- Needs no network support; ignores the local resolver

</div>
<div>

### Discovered
- **DDR** (RFC 9462): ask the network's ordinary resolver for its encrypted twin
- **DNR** (RFC 9463): DHCPv4, DHCPv6 or RA tells the client directly
- Keeps users on the network's resolver, now encrypted

</div>
</div>

Both discovery methods describe resolvers with **SVCB** parameters (RFC 9460, 9461). For a resolver operator, discovery is how encryption reaches clients nobody configured.

---
<!-- _class: dense table-compact -->
## SVCB for DNS Servers (RFC 9460, 9461)

```text
_dns.resolver.arpa. 300 IN SVCB 1 resolver.team01.example. alpn="dot" port=853
_dns.resolver.arpa. 300 IN SVCB 2 resolver.team01.example. alpn="h2" port=443 dohpath="/dns-query{?dns}"
```

| Key | # | Meaning |
|---|---|---|
| `alpn` | 1 | protocols: `dot`, `doq`, `h2`, `h3` |
| `port` | 3 | non-default port (defaults: 853 for DoT and DoQ, 443 for DoH) |
| `ipv4hint`, `ipv6hint` | 4, 6 | addresses, to save a lookup |
| `dohpath` | 7 | DoH URI template, relative; MUST contain the `dns` variable |

Key numbers from the IANA "DNS SVCB Service Parameter Keys (SvcParamKeys)" registry (updated 2026-06-25). BIND 9.20's `dig` prints `dohpath` as `key7`.

---
<!-- _class: dense -->
## DDR: Discovery of Designated Resolvers (RFC 9462)

1. The client knows only the resolver's IP address (from DHCP), say 192.0.2.10
2. It asks that resolver for `_dns.resolver.arpa` SVCB (`resolver.arpa` is a special-use name)
3. The answer names the **designated resolver**, its protocols and ports
4. **Verified discovery:** the client connects and checks that the certificate is valid **and** contains 192.0.2.10 as an IP SAN; then it uses the encrypted resolver
5. **Opportunistic discovery:** for private or link-local resolver addresses only, and only if the encrypted resolver has the same address; no name check

- A resolver with no designated resolver SHOULD answer NODATA
- Designations are per resolver address and per network: rediscover after a network change

---
<!-- _class: dense -->
## DDR in the Lab (Lab 8.4)

```text
$ dig @192.0.2.10 _dns.resolver.arpa SVCB +noall +answer +additional
_dns.resolver.arpa. 300 IN SVCB 1 resolver.team01.example. alpn="dot" port=853
_dns.resolver.arpa. 300 IN SVCB 2 resolver.team01.example. alpn="h2" port=443 key7="/dns-query{?dns}"
resolver.team01.example. 60 IN A 192.0.2.10
```

```text
$ openssl s_client -connect 192.0.2.10:853 -CAfile ca.crt -verify_ip 192.0.2.10 -alpn dot -brief
Verification: OK
Negotiated TLS1.3 group: X25519MLKEM768
ALPN protocol: dot
$ ... -verify_ip 192.0.2.99 ...
verify error:num=64:IP address mismatch
```

- The A record appears in the Additional section once the resolver has it cached (RFC 9462 says SHOULD include it)

---
<!-- _class: dense -->
## DNR: Network-designated Resolvers (RFC 9463)

The network hands out the encrypted resolver directly:

| Carrier | Option |
|---|---|
| DHCPv4 | 162, `OPTION_V4_DNR` |
| DHCPv6 | 144, `OPTION_V6_DNR` |
| IPv6 Router Advertisement | 144, Encrypted DNS Option |

- Each option carries an **authentication domain name** (ADN), the resolver's addresses and SvcParams (`alpn`, `port`, `dohpath`)
- The client checks the certificate against the ADN: no IP SAN needed
- DHCP and RA are not authenticated; DNR is as trustworthy as the local network (RFC 9463 §7.1: use DHCPv6-Shield, RA-Guard)
- Option numbers: IANA DHCP, DHCPv6 and ICMPv6 registries

---
<!-- _class: dense -->
## Clients You Will Meet

Client behaviour changes with every release. Check the vendor's current documentation; these were checked on 21 October 2026:

- **Apple:** encrypted DNS through configuration profiles or apps since iOS 14 and macOS Big Sur; since iOS 16 and macOS Ventura, encrypted DNS is used automatically on networks that support DDR, but not when the resolver's address is private (WWDC22 session 10079, "Improve DNS security for apps and servers")
- **Chrome:** auto-upgrades to the current DNS provider's DoH server when that provider is on Chrome's built-in list; managed deployments are opted out and controlled by policy (chromium.org, "DNS over HTTPS")
- **Windows Server 2022:** the DNS client can use DoH only when the configured server is on its list of known DoH servers (Microsoft Learn, "Secure DNS Client over HTTPS (DoH) on Windows Server 2022")
- **Linux:** stub resolvers and forwarders such as Unbound and `stubby` (Debian packages) do DoT; Lab 8.3 uses Unbound

---
<!-- _class: dense -->
## Enterprise and ISP Policy

When applications choose their own resolver, the network loses:

- **Split-horizon names:** internal zones resolve only on the internal resolver (RFC 9704 lets domain owners tell clients which local resolvers may answer for them)
- **Filtering and security monitoring** at the resolver
- **Troubleshooting:** the helpdesk cannot see which resolver a device used

What works better than blocking:

- Run **your own** encrypted resolver, and advertise it with DDR and DNR
- Configure managed devices by policy (profiles, group policy, browser policy)
- Publish an RPS (RFC 8932) so users know what you log and filter
- Blocking port 853 only pushes clients to DoH on 443

---
<!-- _class: dense -->
## Running an Encrypted Resolver Service

| Decision | Options |
|---|---|
| Protocols | DoT and DoH; DoQ when supported |
| Software | BIND 9.20 or Unbound 1.26 directly; dnsdist in front for scale |
| Certificates | public CA for public users (automated renewal); private CA for managed fleets; IP SAN for DDR |
| Discovery | DDR records on the plain resolver; DNR options in DHCP and RA |
| Privacy | padding on; no ECS; short log retention; RPS published |
| Capacity | TLS handshakes and long-lived connections; test with your real client mix |
| Monitoring | per-transport query rates, handshake failures, certificate expiry |

For a ccTLD: the same choices apply to any public resolver you run; for your authoritative servers, see section 5.

---
<!-- _class: section-divider -->
# 5 · Beyond the Stub

---
<!-- _class: dense -->
## Padding (RFC 7830, RFC 8467)

Encryption hides the content, not the **length**. Name lengths differ, so sizes identify queries.

- **EDNS(0) Padding option** (code 12, RFC 7830): fills a message with zero octets
- Responders MUST pad a response when the query was padded; padding MUST NOT be used on unencrypted transports
- **Block-Length Padding** (RFC 8467, Experimental, recommended strategy): queries to a multiple of **128** octets, responses to a multiple of **468**
- Unbound pads TLS upstream queries (`pad-queries`, 128) and responses to padded queries (`pad-responses`, 468) by default; BIND needs `response-padding { any; } block-size 468;`
- `kdig` pads queries over TLS by default; `dig` needs `+padding=128`

---
<!-- _class: dense table-compact -->
## Padding on the Wire (Lab 8.5)

TLS application-data record lengths, measured with `tshark`:

| Query | Query record | Response record |
|---|---|---|
| `www.team01.example`, no padding | 78 | 110 |
| `secret-project.team01.example`, no padding | 89 | 121 |
| `www.team01.example`, padded | 147 | 487 |
| `secret-project.team01.example`, padded | 147 | 487 |

- Unpadded, the 11-character difference in the name shows up as 11 octets on the wire
- Padded: 128 + 2 (length prefix) + 17 (TLS 1.3 overhead) = 147; 468 + 2 + 17 = 487
- In the lab, BIND padded responses to padded queries over plain TCP too (its ARM pads any query that "includes a valid server cookie or uses TCP" and matches the ACL); Unbound padded only over TLS, which is what RFC 7830 §6 asks for

---
<!-- _class: dense -->
## Resolver to Authoritative (RFC 9539)

The second hop carries every user's queries in cleartext, from the resolver's address.

- RFC 9539 (Experimental, February 2024): a resolver **probes** authoritative servers for DoT or DoQ on port 853 and uses it if it works, with no signalling and no authentication
- Defeats passive monitoring only; a failed probe is remembered (`damping`, default 1 day) and the resolver falls back to cleartext
- Authoritative servers may offer it unilaterally: DoT or DoQ on port 853, and a self-issued certificate is enough (§3.2)
- **For ccTLD operators:** your name servers see the resolver's queries for your zone; encryption here hides them from the path, not from you

---
<!-- _class: dense -->
## Zone Transfers over TLS (RFC 9103)

Zone transfers send the whole zone. For a TLD, that is the full list of registered names.

```text
// primary (BIND 9.20), in options
listen-on port 853 tls ephemeral { 192.0.2.2; };
allow-transfer port 853 transport tls { any; };   // add TSIG or an ACL in production
// secondary
tls xot-client { };   // no ca-file: encrypted, server not authenticated
zone "team01.example" { type secondary;
    primaries { 192.0.2.2 port 853 tls xot-client; }; };
```
```text
transfer of 'team01.example/IN' from 192.0.2.2#853: Transfer completed: 1 messages, 7 records
```

- XoT MUST use TLS 1.3 and the ALPN token `dot`; keep TSIG for authorisation
- Give `tls xot-client` a `ca-file` and `remote-hostname` to authenticate the primary

---
<!-- _class: dense -->
## Oblivious DoH (RFC 9230)

<div class="columns">
<div>

```text
client ──> proxy ──> target (resolver)
 knows      sees the    sees the
 both       client IP,  query, not
            not query   the client
```

</div>
<div>

- The client encrypts the query to the **target's** public key (HPKE); the **proxy** forwards it unread
- Media type `application/oblivious-dns-message`, HTTP POST
- Works only if proxy and target **do not collude**

</div>
</div>

- **Status:** Experimental, published on the Independent Submission stream ("developed outside the IETF")
- The general mechanism is Oblivious HTTP (RFC 9458, Proposed Standard); SVCB key `ohttp` (8) advertises it (RFC 9540)
- Few operators run ODoH; treat it as a design to understand, not a service to deploy now

---
<!-- _class: dense -->
## DNSCrypt

- Encrypts and authenticates DNS between client and resolver with its own protocol, not TLS
- **Not an IETF standard:** the specification is at dnscrypt.info; an individual Internet-Draft (`draft-denis-dprive-dnscrypt-11`, July 2026) has no RFC
- Version 2 uses X25519-XChaCha20Poly1305; the resolver publishes **certificates as TXT records**, signed with Ed25519
- Default port 443, over UDP and TCP
- **On Debian 13:** `dnscrypt-proxy` 2.1.8 (client) and `dnsdist` 1.9 (server feature)

Prefer DoT, DoH or DoQ for new services: standard, supported by common resolvers, and checked with ordinary TLS tools.

---
<!-- _class: dense -->
## What Encryption Still Leaves Visible

- **The resolver's IP address:** DoT and DoQ on port 853 are obvious; DoH is not
- **SNI** in the TLS ClientHello names the resolver; **Encrypted ClientHello** (RFC 9849, March 2026) hides it, with keys published in SVCB/HTTPS records (`ech`, RFC 9848)
- **Sizes and timing** without padding
- **The connection that follows:** the client then connects to the address it looked up, and that connection's SNI often names the site
- **The resolver operator** sees everything, as before

TLS itself keeps moving: TLS 1.3 is now RFC 9846 (July 2026), new TLS protocols must require 1.3 (RFC 9852), and Debian 13's OpenSSL 3.5 negotiated the hybrid post-quantum group X25519MLKEM768 in the lab.

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

- **Your VMs from Module 7:** the authoritative server for `teamNN.example` (used here as the **client**) and the BIND 9.20 validating **resolver**; Debian 13
- **Packages:** `bind9`, `bind9-dnsutils`, `knot-dnsutils` (`kdig`), `unbound`, `tcpdump`, `tshark`, `openssl`, `curl`
- **Lab kit:** `labs/module08/`: `make-certs.sh`, BIND snippets (`resolver/`), Unbound configs (`unbound/`)
- **Certificates:** each team makes its own CA and a resolver certificate for `resolver.teamNN.example` with the resolver's IP address; keys stay on the resolver
- **Name:** add `resolver IN A <resolver address>` to `teamNN.example`
- **Addresses** on the slides are from the test lab: client 192.0.2.30, resolver 192.0.2.10; use the ones on your lab sheet

---
<!-- _class: dense -->
## Lab 8.1: See Plaintext DNS (15 min)

1. On the resolver: `sudo tcpdump -i any -n -w plain.pcap port 53 or port 853 or port 443`
2. On the client: `dig @<resolver> secret-project.teamNN.example A` (add the name to your zone first)
3. Stop the capture; list the queries:
   `tshark -r plain.pcap -T fields -e ip.src -e ip.dst -e dns.qry.name`
4. Find the client's query, the resolver's queries to your authoritative server, and the answers
5. Note which query shows QNAME minimisation (if Module 6 has not covered it yet: the resolver asks for `teamNN.example NS` before `secret-project.teamNN.example A`)

> **Checkpoint:** you can point to the line that shows who asked for `secret-project`, and the lines that show the resolver asking on its behalf

---
<!-- _class: dense -->
## Lab 8.2: DoT and DoH on Your Resolver (25 min)

1. On the resolver: `sudo mkdir /etc/bind/tls; sudo sh labs/module08/make-certs.sh NN <resolver address> /etc/bind/tls`; then `sudo chown root:bind /etc/bind/tls/resolver.key; sudo chmod 640 /etc/bind/tls/resolver.key`
2. Copy `named.conf.module08` and `db.resolver.arpa` to `/etc/bind/`; include the first from `named.conf`; add the lines from `named.conf.options.module08` to `options`; `named-checkconf`; `systemctl restart named`
3. Copy `ca.crt` (never `ca.key`) to the client
4. Strict DoT: `kdig @<resolver> +tls-ca=ca.crt +tls-hostname=resolver.teamNN.example www.teamNN.example`, then the same with `dig`
5. Break it: a wrong `+tls-hostname`; `+tls-ca` without the file; then `+tls` alone
6. DoH: `kdig +https ...`, `dig +https ...`, `dig +https-get ...`; repeat the Lab 8.1 capture with DoT

> **Checkpoint:** strict DoT and DoH succeed; the wrong name and the unknown CA fail; the capture shows SNI and ALPN `dot` but no query name on hop 1

---
<!-- _class: dense -->
## Lab 8.3: Forward over TLS with Unbound (15 min)

1. On the client: copy `ca.crt` to `/etc/unbound/team-ca.crt` and `module08-forward.conf` to `/etc/unbound/unbound.conf.d/`; set `NN` and the resolver address. (After `apt install unbound` the service shows as failed: BIND owns port 53 on this VM. That is expected until step 2.)
2. `sudo unbound-checkconf` and `sudo systemctl restart unbound`
3. `dig @127.0.0.1 -p 5300 www.teamNN.example`
4. Capture on the client: only TCP 853 leaves the VM; Unbound's queries are 147 octets on the wire (padded)
5. Change the name after `#` in `forward-addr` to a wrong one, restart, query again, and read the log

> **Checkpoint:** answers through Unbound; no port 53 traffic from the client to the resolver; with the wrong name, SERVFAIL and `ssl handshake cert error: hostname mismatch`

---
<!-- _class: dense -->
## Lab 8.4: Resolver Discovery with DDR (20 min)

1. Edit `/etc/bind/db.resolver.arpa`: your team number and resolver address; `named-checkzone resolver.arpa db.resolver.arpa`; `rndc reload resolver.arpa`
2. On the client: `dig @<resolver> _dns.resolver.arpa SVCB`; read `alpn`, `port` and `dohpath` (`key7`)
3. Verify as a DDR client would: `openssl s_client -connect <resolver>:853 -CAfile ca.crt -verify_ip <resolver> -alpn dot -brief`
4. Repeat with another team's resolver address in `-verify_ip`
5. **Discussion:** your lab sheet uses private addresses. Which DDR mode applies, and what would DNR (DHCPv4 option 162) add?

> **Checkpoint:** two SVCB records with the right ALPN and ports; "Verification: OK" with your address and "IP address mismatch" with another

---
<!-- _class: dense -->
## Lab 8.5: Padding on the Wire (15 min)

1. Check `response-padding { any; } block-size 468;` is in the resolver's options
2. Capture TCP 853 on the resolver while the client runs, for two names of different length:
   `dig @<resolver> +tls-ca=ca.crt +tls-hostname=resolver.teamNN.example NAME` with and without `+padding=128`
3. List the TLS record lengths: `tshark -r pad.pcap -Y tls -T fields -e ip.src -e tls.record.length`
4. Compare `kdig ... +padding` and `+nopadding`: read the `PADDING` and `Received` lines
5. Try `+padding=128` over plain UDP and TCP: which responses are padded?

> **Checkpoint:** unpadded record sizes differ by the difference in name length; padded ones are identical (147 and 487 in the test lab)

**Discussion:** what can an observer still learn from your padded DoT traffic?

<!--
Step 5: BIND pads the TCP answer because its ARM pads any padded query that "includes a valid server cookie or uses TCP" and matches the response-padding ACL: documented behaviour, a design choice that departs from RFC 7830 §6 (MUST NOT pad on unencrypted transport), not a bug. UDP is unpadded only because dig never presents a valid server cookie; BIND would pad a UDP query that does. Unbound pads only TLS-serviced queries.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 9076: DNS privacy considerations; RFC 8932 (BCP 232)
- RFC 7858, 8310: DoT; RFC 8484: DoH; RFC 9250: DoQ
- RFC 7830, 8467: padding; RFC 9103: XoT
- RFC 7766, 9210: DNS over TCP; RFC 7828: edns-tcp-keepalive
- RFC 9460, 9461: SVCB; RFC 9462: DDR; RFC 9463: DNR; RFC 9704
- RFC 9539, 9230, 9458, 9540, 8094: experimental and related
- RFC 9525: service identity; RFC 9846, 9852: TLS 1.3; RFC 9849, 9848: ECH
- RFC 7871: ECS; RFC 9953: DNS over CoAP
- IANA: SvcParamKeys, ALPN IDs, port 853, DHCP and RA options
- Module 6: QNAME minimisation (RFC 9156), DNS Cookies (RFC 7873, 9018)

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>kdig @r +tls-ca=ca.crt +tls-hostname=n q
dig @r +tls-ca=ca.crt +tls-hostname=n q
kdig @r +https +tls-ca=ca.crt q
dig @r +https-get q
kdig @r +quic q
dig @r _dns.resolver.arpa SVCB
openssl s_client -connect r:853
  -verify_ip r -alpn dot -brief
tshark -r f.pcap -Y tls
  -T fields -e tls.record.length
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. A user switches to DoH with a public resolver. Who can still see their queries, and who no longer can?
2. What is the difference between the strict and opportunistic profiles, and what does a strict client do if the certificate does not match?
3. A colleague says "our DoH server also supports the JSON API from RFC 8484". What is wrong?
4. What must a resolver's certificate contain for verified DDR discovery, and why?
5. Why does padding use fixed block sizes rather than random lengths, and what sizes does RFC 8467 recommend?
6. Your resolver serves DoT. Are its queries to your ccTLD's name servers encrypted? What could change that?

<!--
Answers:
1. No longer: anyone on the path between the user and the resolver (Wi-Fi, LAN, ISP), apart from the resolver's address, SNI, sizes and timing. Still: the DoH resolver operator (everything), the authoritative servers (names, from the resolver's address, plus ECS if sent), and anyone on the resolver-to-authoritative path, which is still cleartext.
2. Strict (RFC 8310) requires an encrypted and authenticated connection, checking the certificate against the authentication domain name or an SPKI pin; if it fails, the client hard-fails and does not fall back. Opportunistic tries encryption, accepts any certificate, and falls back to cleartext; it protects only against passive observers.
3. RFC 8484 defines only the application/dns-message media type (DNS wire format). JSON interfaces are vendor-specific, with their own URLs and parameters; other media types may be negotiated but none is standard. (The lab BIND returns HTTP 400 to a JSON request.)
4. The resolver's IP address, the one the client used for unencrypted DNS, as an iPAddress subjectAltName, in a certificate that chains to a trusted anchor (RFC 9462 §4.2). The SVCB answer came over unauthenticated DNS; the IP SAN proves that the encrypted resolver speaks for that address, so an attacker cannot redirect the client to an unrelated server.
5. Block-length padding makes many different queries and responses the same size while costing little bandwidth; RFC 8467 found random lengths less effective (Random-Length Padding is NOT RECOMMENDED). Queries: multiples of 128 octets; responses: multiples of 468.
6. No: DoT covers only the client-to-resolver hop. The resolver's queries to authoritative servers go over port 53 in cleartext. RFC 9539 (Experimental) lets the resolver probe the name servers for DoT or DoQ on port 853 and use it opportunistically, if the ccTLD offers it; QNAME minimisation (Module 6) reduces what each server sees.
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
