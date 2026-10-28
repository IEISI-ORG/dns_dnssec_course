---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 5: Advanced DNS Operations and Architecture

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Describe** the layers of a DNS service: provisioning, a hidden primary, listed secondaries, anycast instances and resolvers
- **Build** a hidden primary with a public secondary, restrict who may query, transfer and be notified, and check that a change reaches every listed server
- **Explain** anycast: catchments, BGP route selection, health-checked withdrawal, and what a lab can and cannot show about it
- **Configure** split horizon with BIND views, and name the costs of running two versions of a zone
- **Compare** round robin, weighted records, GeoDNS and anycast for spreading load, and choose TTLs and resolver cache settings
- **Troubleshoot** a service that answers differently depending on who asks: which server, which view, which instance, which cache

---
<!-- _class: dense -->
## Where Day 3 Starts

```text
 VM 1  192.0.2.30   BIND: primary for teamNN.example and two reverse zones (Modules 2-4)
 VM 2  192.0.2.10   BIND: resolver, static-stub for example. (Module 3); Unbound disabled (Module 4)
 registry 192.0.2.53      example.: delegates teamNN.example to VM 1
 lab resolver 192.0.2.55  Module 1's resolver, on until the end of this morning's lab
 This morning:  VM 2 a hidden primary, VM 1 two views, an anycast service inside VM 2
```

- Module 3 named the roles (stealth server, hidden primary, anycast); this module builds them and puts them together
- Every lab undoes its changes: Module 6 starts this afternoon from the state above
- Pointers out: TSIG on transfers, rate limits (Module 6); signing with several servers (Module 7); monitoring (Module 11)

---
<!-- _class: dense table-compact -->
## What Changed Recently

| Then | Now (as of 28 October 2026) |
|---|---|
| Older RFCs' names for the primary, the secondary and a hidden primary | RFC 9499 (BCP 219, March 2024) defines stealth server, hidden primary ("a stealth server that is a primary server for zone transfers"), split DNS and views; BIND 9.20 writes `primary`, `secondary` |
| Anycast guidance: RFC 4786 (BCP 126, 2006) | RFC 9199 (March 2022): anycast for every NS; routing matters more than instance count; plan withdraw and absorb strategies |
| Resolver gives SERVFAIL when the authorities are down | Serve-stale (RFC 8767, 2020): BIND 9.20 has it, off by default. RFC 9520 (2023): cache resolution failures for 1 s to 5 minutes |
| "13 root servers" | 13 identifiers, 12 operators, 2049 operational instances (root-servers.org, 27 October 2026 UTC) |

<!--
Sources fetched 28 October 2026 (plan/m05_notes.md): rfc-editor.org JSON and text for RFC 9499, 4786, 9199, 8767, 9520; BIND 9.20.30 `named -C` (stale-answer-enable false, stale-cache-enable false); root-servers.org front page ("As of 2026-10-27T20:02:01Z, the root server system consists of 2049 operational instances operated by the 12 independent root server operators"). The instance count changes weekly: read it on the day. RFC 9499 files the definition under the older term and quotes RFC 6781; the course says hidden primary, as BIND says primary.
-->

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. Day 3 so far and what changed (5m)
2. Building blocks of a DNS service (10m)
3. Hidden primary (13m)
4. Anycast (20m)
5. Split horizon (14m)
6. Traffic and caching (16m)
7. Troubleshooting a distributed service (12m)

## Agenda (90 min Lab)

1. Lab 5.1 Hidden primary (25m)
2. Lab 5.2 Split horizon with views (20m)
3. Lab 5.3 Anycast in one VM (25m)
4. Lab 5.4 Troubleshooting drill and clean-up (20m)

<!--
Day 3 Session 1 has no knowledge-check slot: Program Facts put Day 3's mid-course assessment in Session 3 (Module 6's theory). The 90 minutes are all content.
-->

---
<!-- _class: section-divider -->
# 1 · Building Blocks of a DNS Service

---
<!-- _class: dense -->
## Layers of an Authoritative Service

```text
 provisioning      registry database, IPAM, portal, Git        (Modules 4, 9-10)
       │ writes zone data
 hidden primary    signs (Module 7), NOTIFY, serves transfers   (section 2)
       │ IXFR/AXFR, TSIG (Module 6)
 listed servers    ns1, ns2, ns3: in the NS set and the parent's delegation
       │ each one may be many instances behind one address   (section 3)
 resolvers         ask any listed server, cache the answer      (section 6)
```

- Each layer has one job and its own failure: bad data at the top reaches every server below within seconds (NOTIFY)
- Only the listed servers face the Internet; the layers above can sit in a private network
- The same split exists on the resolver side: clients, resolver instances, anycast, forwarders (Module 3)

---
<!-- _class: dense -->
## Listed Servers: Module 3's Rule, RFC 9199's Addition

- **Module 3's rule, unchanged:** RFC 2182 §5 asks for three servers, one far from the others, and warns that each extra server is one more that can be misconfigured unnoticed
- **RFC 9199 C1:** resolvers spread their queries over every listed server, so "all must be similarly capable": a slow or distant ns3 slows everyone who picks it. It recommends "equally strong IP anycast instances for every authoritative server"
- **RFC 9199 C6:** parent and child copies of NS and glue often carry different TTLs; most resolvers use the child's. Keep the two NS sets equal (Module 1, Lab 1.3) and their TTLs deliberate
- **Diversity:** different networks, sites and power, and preferably software (Module 4); a provider's secondary service is one way to get it
- One listed server is what Lab 5.1 builds; the slides say what production needs

<!--
RFC 2182 §5 (July 1997): "It is recommended that three servers be provided for most organisation level zones, with at least one which must be well removed from the others" and "More servers also increase the likelihood that one server will be misconfigured, or malfunction, without being detected" (Module 3 has the full slide). RFC 9199 §3.1.2 and §3.6 (March 2022), fetched 28 October 2026. RFC 9199 C6 reports that "roughly 90% of resolvers follow the child's view of the TTL" in the cited study; the deck quotes no other numbers from it.
-->

---
<!-- _class: dense -->
## Moving Data Between the Layers

- **NOTIFY (RFC 1996):** the primary tells its secondaries "the zone changed"; they ask for the SOA, compare serials and transfer. The default Notify Set is "all servers named in the NS RRset, except for any server also named in the SOA MNAME"; stealth servers are added by configuration
- **IXFR and AXFR:** incremental or whole-zone transfer (Module 3); a secondary only transfers when the serial is higher
- **TSIG:** a shared key on every transfer and NOTIFY (Module 6 Lab 6.4); address ACLs alone are what Lab 5.1 uses
- **Catalog zones (RFC 9432):** the list of zones travels as a zone too (Module 3)
- **Several signers (RFC 8901):** two providers that sign the same zone (Module 7)
- **Out of band:** some providers fetch zones by API or take a database feed (PowerDNS, Module 4): then serials may not mean anything

---
<!-- _class: dense table-compact -->
## Two Kinds of Replication

| | More listed servers (NS records) | Anycast (one address, many instances) |
|---|---|---|
| Who chooses the server | the resolver, from the NS set | the routing system, from BGP paths |
| Failure of one | resolver times out and tries another | route withdrawn, traffic moves; without withdrawal, a black hole |
| Adds | names, glue, delegation entries | sites, routers, a BGP session per site |
| Limit | response size of the NS set | routing policy you do not control |
| In this lab | Lab 5.1 (one listed server) | Labs 5.3-5.4 |

- RFC 9199 calls these the two complementary mechanisms: "name server replication (multiple NS records) and anycast (multiple physical locations)"
- Large zones use both: several NS names, each one anycast

---
<!-- _class: dense -->
## Example: the Root Server System

- 13 identifiers (`a` to `m.root-servers.net`), 12 independent operators, **2049 operational instances** as of 27 October 2026 (root-servers.org)
- Each identifier is one IPv4 and one IPv6 address announced from many sites: anycast behind a fixed NS set
- root-servers.org lists sites as "Global" or "Local": a local site is announced only to nearby networks (RFC 4786: "local-scope anycast")
- Resolvers prime from the hints file and then pick among the 13 by their own rules (Module 1); the operator decides which instance answers each resolver through routing
- Lab 3.1's address database (`rndc dumpdb`) showed the resolver's per-server round-trip times: that is the resolver's half of the choice

<!--
root-servers.org front page and site list fetched 2026-10-27T20:02Z (online; not part of the offline lab). The "Global"/"Local" labels are root-servers.org's; RFC 4786 §2 defines local-scope anycast. Do not quote the number from this slide on another day without checking.
-->

---
<!-- _class: section-divider -->
# 2 · Hidden Primary

---
<!-- _class: dense -->
## Why Hide the Primary

- **Definition** (RFC 9499): a hidden primary is "a stealth server that is a primary server for zone transfers"; it is in no NS set (Module 3)
- **Fewer targets:** only the listed secondaries take queries from the Internet; the primary can sit behind a firewall that admits only them
- **One place to change and sign:** provisioning, DNSSEC signing and dynamic updates happen on one server (Module 7)
- **Free choice of public servers:** your own at several sites, a provider's secondary service, or both, without moving the zone's source
- **Costs:** it is still a single source of truth; if it stops, the secondaries serve until SOA EXPIRE and then fail (Module 3). Watch its transfers and serials (section 6)
- **Not a resolver:** a server that holds a zone answers it from that copy; Lab 5.1 shows what happens when that copy refuses its own users

---
<!-- _class: dense -->
## Who Gets the NOTIFY

```text
notify yes;        NS set (except SOA MNAME) + also-notify      BIND's default
notify explicit;   also-notify only                             Lab 5.1
notify no;         nobody: secondaries wait for the SOA refresh timer
```

- With a hidden primary, the NS set names the public servers: `notify yes` already reaches them, by the addresses their names resolve to
- `notify explicit` is for when those are not the right addresses, for example a provider whose listed servers are anycast addresses and who takes NOTIFY and transfers on separate addresses it gives you
- **SOA MNAME:** RFC 1996 leaves the server named there out of the Notify Set. RFC 9499 quotes RFC 4641 (the hidden primary's name "appears in the SOA RRs MNAME field") and adds that in some set-ups it appears nowhere; Lab 5.1 names ns1, the public server
- Secondaries also check the SOA every refresh interval: NOTIFY makes changes fast, the timers make them certain

<!--
BIND 9.20 ARM, notify: "If set to explicit, notifies are sent only to servers explicitly listed using also-notify"; yes sends to "the servers listed in the zone's NS records (except the primary server identified in the SOA MNAME field), and to any servers listed in the also-notify option". RFC 1996 §2 (Notify Set). RFC 9499 (its hidden-primary entry, under the older name), quoting RFC 4641 for MNAME and adding "the name does not appear at all in the global DNS in some setups".
-->

---
<!-- _class: dense -->
## The Lab's Configuration

<div class="columns">
<div>

**VM 2, hidden primary**
```text
zone "hp.teamNN.example" {
  type primary;
  file "/var/lib/bind/db.hp.teamNN.example";
  notify explicit;
  also-notify { 192.0.2.30; };
  allow-transfer { 192.0.2.30; };
  allow-query { 192.0.2.30; };
};
```

</div>
<div>

**VM 1, public secondary**
```text
zone "hp.teamNN.example" {
  type secondary;
  primaries { 192.0.2.10; };
  file "/var/cache/bind/db.hp.teamNN.example";
};
```
**In `teamNN.example`:**
```text
hp  IN NS  ns1.teamNN.example.
```

</div>
</div>

- The child zone's NS set names only ns1 (VM 1); VM 2 appears in no record anywhere
- Why a child zone: VM 1 serves `teamNN.example`, so a hidden zone on VM 1 would refuse the resolvers that follow the delegation to it

<!--
Kit files labs/module05/vm2/named.conf.hidden-primary, vm2/db.hp.teamNN.example, vm1/named.conf.public-secondary. The secondary's file goes in /var/cache/bind and the primary's in /var/lib/bind: Debian's AppArmor profile (Module 2).
-->

---
<!-- _class: dense -->
## Seen in Lab 5.1

```text
VM 2$ dig @127.0.0.1 www.hp.teamNN.example
  status: REFUSED   EDE: 18 (Prohibited)       # allow-query is VM 1 only, even for VM 2
VM 1  zone hp.teamNN.example/IN: transferred serial 2026102801
VM 2$ dig @192.0.2.55 www.hp.teamNN.example +short
  192.0.2.120                                  # registry -> VM 1, which answers with aa
VM 1  client 192.0.2.55#... (www.hp.teamNN.example): query: www.hp.teamNN.example IN A
VM 2  (no query from 192.0.2.55)
VM 2$ dig @192.0.2.10 hp.teamNN.example AXFR
  ; Transfer failed.                           # allow-transfer: VM 1 only
VM 2  zone hp.teamNN.example/IN: sending notify to 192.0.2.30#53
```

- The public path never reaches VM 2; its own users are refused too, because a zone's `allow-query` applies to everyone who asks VM 2
- A real hidden primary is not a resolver: in production, VM 2's resolver role and its primary role would be two servers (Module 3)

<!--
Rehearsed 28 October 2026 (labs/module05/test/rehearse.sh 5.1.1-5.1.6; transcripts in plan/m05_notes.md). In 5.1.1 BIND also adds "EDE: 20 (Not Authoritative): (recursion disabled)". BIND does not fall back to resolving the name through the public servers when its own zone refuses the client.
-->

---
<!-- _class: dense -->
## Serial Discipline

```text
VM 2  zone hp.teamNN.example/IN: zone serial (2026102802) unchanged.
      zone may fail to transfer to secondaries.
VM 1$ dig @192.0.2.10 app.hp.teamNN.example +short     192.0.2.122   (hidden primary)
VM 1$ dig @127.0.0.1  app.hp.teamNN.example +short     192.0.2.121   (public server)
      both: SOA serial 2026102802
```

- A change without a new serial reaches nobody: the secondary sees the same serial and keeps its copy. BIND warns, once, in the log
- **Check every listed server, not one:** `for s in <every NS address>; do dig @$s zone SOA +short +norec; done`; equal serials with different data mean a forgotten serial
- Serials only go up (RFC 1982 arithmetic, Module 2). Never "fix" a mistake by lowering one: secondaries ignore it
- With a database or API behind the primary, let the software raise the serial (Module 4: SOA-EDIT-API)

<!--
Rehearsed (5.1.7, 5.1.7b, 5.1.7c): the warning text is BIND 9.20.30's. After raising the serial, VM 1 logged "transferred serial 2026102803" and answered 192.0.2.122.
-->

---
<!-- _class: dense -->
## Hidden Primary: a Checklist

- **Reachability:** the primary reaches every secondary's transfer address on TCP and UDP 53; the secondaries reach it back. Firewall both directions, nothing else
- **Restrictions:** `allow-transfer` and `allow-query` to the secondaries, NOTIFY accepted only from the primaries (BIND's default for a secondary; `allow-notify` adds others), TSIG on both (Module 6)
- **Timers:** SOA REFRESH and RETRY so that a lost NOTIFY is repaired; EXPIRE longer than any outage you plan to survive (two weeks in the lab zone)
- **Monitoring:** serial on every listed server, transfer errors in the logs, the primary's own health (Module 11)
- **Spare:** a second, warm primary or a tested restore; secondaries can be pointed at it with one `primaries` change
- **Delegation:** the parent's NS set and glue name only the listed servers

<!--
BIND 9.20 ARM, allow-notify: "If not specified, the default is to process NOTIFY messages only from the configured primaries for the zone". Module 3 showed EXPIRE (Lab 3.4) and the clamp on very short timers.
-->

---
<!-- _class: section-divider -->
# 3 · Anycast

---
<!-- _class: dense -->
## One Address, Many Servers

- **Anycast** (RFC 4786, BCP 126): the same service address is announced into routing from several **anycast nodes**; each packet goes to one of them
- **Catchment:** "the topological region of a network within which packets directed at an Anycast Address are routed to one particular node" (RFC 4786)
- **For DNS:** RFC 3258 (2002) described "a single named server in multiple locations" to bring servers closer to "previously under-served areas"; the root and most TLDs use it today (RFC 9199)
- **Why DNS suits it:** most queries are one UDP packet each way, so each one stands alone; a route change between two queries does no harm
- **TCP needs care:** a route change during a TCP connection sends the next packets to another node, which knows nothing of it; RFC 4786 §4.4.3 raises the same for equal-cost paths

---
<!-- _class: dense -->
## Routing Decides, Not Distance

```text
   C1 ── R1 (AS 65001) ── R2 (AS 65002) ── C2
          │                       │
        site A (AS 65100)       site B (AS 65100)     both announce 198.51.100.53/32
R1: 198.51.100.53/32  via site A   AS path 65100         * shortest, in use
                      via R2       AS path 65002 65100
```

- Each router picks one best path by BGP's rules (RFC 4271 §9.1.2.2), early among them the shortest AS path; distance and server load are not inputs
- **Same origin AS at every site:** routers see one service, announced from several places
- **Steering:** an operator moves catchments with routing tools, such as AS-path prepending or BGP communities agreed with neighbours (RFC 9199 C4); Lab 5.4 shows prepending moving city 1 to site B
- RFC 9199 C2: "optimizing routing policies is more important than simply adding new instances"

<!--
The diagram is the lab's (labs/module05/anycast/), as rehearsed: R1 learned both paths and used site A's (5.3.2). RFC 4271 §9.1.2.2 (a), the first tie-breaking step after the degree of preference (LOCAL_PREF, §9.1.2): "Remove from consideration all routes that are not tied for having the smallest number of AS numbers present in their AS_PATH attributes". BIRD shows the local preference (100) and the AS path; the private ASNs are from RFC 6996, the addresses from RFC 5737.
-->

---
<!-- _class: dense -->
## Health Checks and Withdrawal

- RFC 4786 §4.4.1: couple the route to the service, so that "availability of the service triggers the route advertisement, and non-availability of the service triggers a route withdrawal", with a routing daemon on the server itself
- The lab's check: every second, ask the local `named` for the SOA on the anycast address; if it fails, `birdc disable svc`, and the route is withdrawn; when it answers again, `birdc enable svc`
- **Avoid flapping:** "a minimum delay following a withdrawal before the service can be re-advertised" (RFC 4786); the lab's check has none, so watch what it does
- **Check the thing users need:** a server that answers SOA but serves an old zone passes this check (Lab 5.4)
- **Covering prefix:** on the Internet a single address (/32) does not propagate; announce "often a 24-bit prefix" for IPv4 (RFC 4786 §4.4.2). The lab uses a /32, inside one VM

<!--
labs/module05/anycast/healthcheck.sh sets the state every round (so a BIRD reconfiguration cannot leave a site withdrawn for more than a second) and logs each change. Production tools for this include ExaBGP and BIRD or FRR with a check script; Debian 13 packages exabgp 4.2.25, bird2 2.17.5 and frr 10.3 (apt, 28 October 2026). The lab uses BIRD only.
-->

---
<!-- _class: dense -->
## The Lab: Anycast Inside VM 2

```text
 namespaces on VM 2      what runs there
 m05-c1, m05-c2          clients in "city 1" and "city 2" (dig)
 m05-r1, m05-r2          BIRD 2.17.5: the two ISPs' routers, BGP to each other
 m05-a, m05-b            named (a second and third instance) + BIRD + healthcheck.sh
```

- `sudo sh anycast-lab.sh up` builds it and waits until all four BGP sessions are up (seconds); `down` removes every namespace, process and file
- The site servers are ordinary BIND 9.20 from Debian: their files are where Debian's AppArmor profile allows (`/etc/bind/m05-anycast`, `/var/cache/bind/m05-anycast`), with `pid-file none` and `session-keyfile none` so that they do not collide with VM 2's own `named`
- Nothing touches VM 2's interfaces, routes or its resolver; the box is not reachable from the lab network
- **Never `pkill named` here:** it would stop VM 2's resolver too. The script signals only processes inside its namespaces

<!--
Rehearsed (5.3.1, 5.3.7): "anycast lab up: R1 198.51.100.53 via 198.51.100.6 dev r1-a proto bird ... R2 198.51.100.53 via 198.51.100.14 dev r2-b"; VM 2's listening sockets unchanged (only 192.0.2.10:53 and 127.0.0.1:53), no 198.51.100 route in its main table. The four BIRD processes used 12-13 MiB together in every run (ps RSS). The named figure (three processes, 527-534 MiB in the last five runs, 92 MiB in an earlier one, on a 12-CPU host) is mostly VM 2's own resolver and its cache, not the two site servers, so it is not quoted as the lab's cost.
-->

---
<!-- _class: dense table-compact -->
## What This Lab Can and Cannot Show

| Shown, and observed in the rehearsal | Not shown: theory only |
|---|---|
| Two instances behind one address, told apart by NSID | Catchments on the Internet, shaped by thousands of networks' policies |
| Route choice by AS-path length at each router | Latency: every hop here is inside one VM |
| Withdrawal when `named` stops: C1 at site B within about a second (0.7 s in the rehearsal) | BGP convergence across the Internet, path hunting, route damping |
| A dead site that is still announced (black hole) | Covering prefixes, prefix filters, RPKI (Module 6) |
| Steering with AS-path prepending | Absorbing a DDoS at the nearest site (RFC 9199 C4) |
| Instances with different data | A TCP connection broken by a route change |

- The lag is where in the health check's 1-second cycle the stop lands, plus the BGP update; production is slower and varies

<!--
Measured 28 October 2026 in rehearse.sh 5.3.5 (nine runs): C1 queried every 0.2 s with +time=1; site A's named stopped at t=0; "+0.1 s fail, +0.7 s site-b" each run. The harness stops the site at the same point of the check's 1-second cycle every time, so the runs agree; typed by hand, expect anything from about 0.1 s to 1.2 s. Set-up: BIRD 2.17.5, BIND 9.20.30, Docker container on a 12-CPU host, BGP between network namespaces over veth pairs, healthcheck.sh interval 1 s.
-->

---
<!-- _class: dense -->
## Which Instance Answered?

```text
$ dig @198.51.100.53 www.svc.test +nsid           ; NSID: 73 69 74 65 2d 61 ("site-a")
$ dig @198.51.100.53 id.server CH TXT +short       "site-a"
```

- **NSID** (RFC 5001): an EDNS option the client asks for; the server returns its own identifier with any normal answer. BIND: `server-id "site-a";` (default `none`)
- **`id.server` and `hostname.bind`** (RFC 4892): CHAOS-class TXT queries for the same purpose
- **BIND rate-limits the CHAOS answers:** 3 per second per /24, dropped without a reply (`named -C`: the built-in `_bind` view). A loop of `id.server` queries in the rehearsal timed out every few queries; use NSID on a normal query for monitoring
- Every instance also needs its own unicast address, for SOA checks and for logging in to it
- Ask from many places: an anycast address answers differently depending on where you stand (RFC 4786 §5.1: probes, RIPE RIS, Route Views)

<!--
Rehearsed (5.3.3): C1 got NSID "site-a", C2 "site-b"; site B's own address 198.51.100.14 answered id.server "site-b" from C1. The rate limit: site B's log showed "rate limit drop response to 198.51.100.0/24 for id.server CH TXT" (plan/m05_notes.md). `named -C` shows the _bind view's rate-limit { responses-per-second 3; slip 0; min-table-size 10; }.
-->

---
<!-- _class: dense -->
## When Anycast Goes Wrong

- **A site keeps announcing but cannot answer:** its catchment gets nothing. Causes: no health check, a check that tests the wrong thing, a check that died with the server
- **Instances disagree:** one site missed a transfer and serves old data to its catchment only; from your desk everything looks fine
- **The catchment is not where you think:** a neighbour's policy or your own prepending sends a city to a far site; measure from many places (RFC 9199 C3: catchment maps)
- **Overload:** RFC 9199 C4 lists two strategies, withdraw a site so others take the load, or absorb at the site; decide in advance, in a playbook
- **Partial reachability:** one address works from some networks only; users report it, your monitoring may not

<!--
Lab 5.4 reproduces the first three. RFC 9199 §3.3 recommends catchment measurement before changes (Verfploeter); §3.4.2: "Operators should consider having both an anycast site withdraw strategy and an absorption strategy ready to be used before a network overload occurs".
-->

---
<!-- _class: dense table-compact -->
## Anycast for Authoritative Servers and for Resolvers

| | Authoritative (ns1.example.net) | Resolver (the address in clients' settings) |
|---|---|---|
| Data | the same zone at every instance; transfers keep it equal | a cache per instance, filled by its own catchment |
| A route change moves a client | to an instance with the same answers | to a cold or different cache; answers may change |
| Address the client sees | listed in NS records, glue at the parent | in DHCP, router adverts, or typed by hand |
| Typical operators | root, TLDs, DNS providers (RFC 9199) | ISPs, public resolver services |

- For resolvers, each instance also needs its own address for outbound queries; authorities see those, not the anycast address
- Resolver anycast across sites mixes with ECS and GeoDNS answers (section 5): the site a client reaches decides which answers it gets

---
<!-- _class: section-divider -->
# 4 · Split Horizon

---
<!-- _class: dense -->
## Split Horizon

- **Split DNS** (RFC 9499): authoritative servers "provide partly or completely different answers in those domains depending on the source of the query"; the effect is that "a domain name that is notionally globally unique has different meanings for different network users"
- **Views** are the usual tool, and "are not a standardized part of the DNS" (RFC 9499): each implementation has its own
- **Typical uses:** internal names (intranet, printers) visible only inside; an internal address for a public name; a smaller zone for outsiders
- **Simpler alternatives first:** a separate internal zone such as `corp.example.org` or `home.arpa` (RFC 8375, Module 4); RPZ local overrides on the resolver (Module 6); separate internal servers
- Choose views when the same name must answer differently, and accept running two versions of the zone

---
<!-- _class: dense -->
## BIND Views

- `view "name" { match-clients { ... }; match-destinations { ... }; ... zones ... };`
- "The order of the view statements is significant; a client request is resolved in the context of the first view that it matches" (ARM): the specific view goes first, `any` last
- "If any explicit view statements are present, all zone statements must occur inside view statements": on Debian that includes the root-hints zone in `named.conf` (tested: `named-checkconf` stops)
- `match-clients` can name a TSIG key instead of addresses: a secondary that must transfer one particular view uses that view's key (Module 6)
- **One zone in two views** without loading it twice: `zone "..." { in-view "internal"; };` in a later view
- Each view has its own options, by default its own cache, and its own managed keys; `rndc` commands for a zone in two views need the view name

<!--
BIND 9.20.30 ARM, §8.2.31 (view) and §8.2.33.5 (Multiple Views: "An in-view option cannot refer to a view that is configured later in the configuration file"). Rehearsed: the named-checkconf error is "/etc/bind/named.conf.root-hints:2: when using 'view' statements, all zones must be in views"; "rndc reload team01.example" gives "zone 'team01.example' was found in multiple views". After the views were removed, /var/cache/bind held internal.mkeys.jnl and external.mkeys.jnl; Lab 5.2 deletes them.
-->

---
<!-- _class: dense -->
## The Lab's Views on VM 1

```text
acl "internal" { localhost; 192.0.2.10; };      // VM 1 itself, VM 2 (the organisation's resolver)
view "internal" {
    match-clients { internal; };
    include "/etc/bind/named.conf.root-hints";  // moved from named.conf
    zone "teamNN.example"       { type primary; file ".../db.teamNN.example.internal"; };
    zone "2.0.192.in-addr.arpa" { type primary; file ".../db.192.0.2"; };   // and ip6.arpa
};
view "external" {
    match-clients { any; };
    recursion no;
    zone "teamNN.example"       { type primary; file ".../db.teamNN.example"; };
    zone "2.0.192.in-addr.arpa" { in-view "internal"; };                     // and ip6.arpa
};
```

- The internal copy is the team zone plus `intranet` (192.0.2.90) and `whichview TXT "internal"`
- Outsiders keep the zone exactly as before; insiders get more

<!--
Kit file labs/module05/vm1/named.conf.views (full paths /var/lib/bind/...; the slide shortens them) and vm1/internal.additions. It replaces named.conf.local for Lab 5.2 only.
-->

---
<!-- _class: dense -->
## Seen in Lab 5.2

```text
VM 2$ dig @192.0.2.10 intranet.teamNN.example +short     192.0.2.90     (VM 2 -> internal view)
VM 2$ dig @192.0.2.55 intranet.teamNN.example            NXDOMAIN       (lab resolver -> external)
VM 1  client 192.0.2.10#... (intranet.teamNN.example): view internal: query: ...
VM 1  client 192.0.2.55#... (intranet.teamNN.example): view external: query: ...
VM 1$ sudo rndc reload teamNN.example
      zone 'teamNN.example' was found in multiple views
VM 1$ sudo rndc reload teamNN.example IN internal
```

- After VM 2 is taken out of the `internal` ACL, VM 2 still answers 192.0.2.90 from its cache until the TTL runs out or `rndc flushtree`; then NXDOMAIN
- **The view is chosen by the address that asks VM 1:** the resolver's, not the user's. Every client of VM 2 gets the internal view, wherever it is

<!--
Rehearsed (5.2.2-5.2.5). With VM 2 in the external view, a direct query from VM 2 to VM 1 shows "flags: qr aa rd" without ra: recursion no in that view.
-->

---
<!-- _class: dense -->
## Costs of Split Horizon

- **Two zones to keep in step:** a change to a shared name must go into both files, with a serial each; scripts or one source that writes both help
- **Caches in between decide:** a resolver that serves inside and outside users, or forwards to an outside one, mixes the views; so does a laptop that keeps its cache while it moves
- **Leaks:** internal names in public logs, certificates, mail headers and search lists; anything that makes an internal name visible outside
- **Secondaries:** each view needs its own transfer; with views selected by address, a secondary only ever gets one of them (use TSIG keys per view)
- **DNSSEC:** both versions must be signed, and a validating resolver that sees one view's signatures with the other's data fails; Module 7 signs without views
- **Debugging:** "it works for me" is the normal state of a split zone; always ask from the user's side (section 6)

---
<!-- _class: section-divider -->
# 5 · Traffic and Caching

---
<!-- _class: dense -->
## Round Robin and Its Limits

- Several A or AAAA records for one name; BIND 9.20 returns them in random order (`named -C`: `rrset-order { order random; }`)
- The ARM's own note: caveats "(mostly stemming from caching) ... usually make it a suboptimal choice for load balancing purposes when used on its own"
- **Why:** each resolver caches one order for the TTL and gives it to many clients; clients sort addresses themselves (RFC 6724 rule 9, longest matching prefix, written for IPv6 and IPv4 alike); DNS does not know whether a server is up
- **What it is good for:** spreading new connections roughly over a few equal servers that are all healthy
- `rrset-order fixed` is deprecated and only in builds with `--enable-fixed-rrset`

<!--
BIND 9.20.30 ARM §8.2.13.11 RRset Ordering. RFC 6724 §6 Rule 9: "When DA and DB belong to the same address family (both are IPv6 or both are IPv4)". Module 1 and Module 2 introduced several records per name; no measurement of distribution is quoted.
-->

---
<!-- _class: dense table-compact -->
## Records That Carry Weights and Choices

| Record | How it spreads load | Who obeys it |
|---|---|---|
| MX (RFC 5321) | preference: lowest first; equal values in random order | mail servers |
| SRV (RFC 2782) | priority, then weight: "a server selection mechanism" | clients that look up SRV (Module 2's `_imaps._tcp`) |
| HTTPS/SVCB (RFC 9460) | SvcPriority, alternative endpoints, ports, ALPN | browsers and clients that support it (Module 2) |
| A/AAAA | none in the record: order only | every client |

- Weights in the data are honest: every resolver passes them on unchanged, and the client chooses
- Anything that changes the answer per client (GeoDNS, health-checked answers) lives in the authoritative server's logic, next slide

<!--
RFC 2782 (February 2000) defines Priority and Weight; RFC 9460 (November 2023) SvcPriority. RFC 5321 for MX preference. Module 2 Lab 2.1 published SRV and HTTPS records in the team zone.
-->

---
<!-- _class: dense -->
## GeoDNS, ECS and Health-Checked Answers

- **GeoDNS:** the authoritative server picks an answer by where the query seems to come from: the resolver's address, or the client subnet if the resolver sends one
- **EDNS Client Subnet** (RFC 7871, Informational, 2016, "known operational and privacy shortcomings"): the resolver sends part of the client's address; it recommends truncating to 24 bits for IPv4 and 56 for IPv6; caches then hold one answer per subnet
- **BIND:** `geoip` ACL elements (country, region, city, ASN ...) usable in `match-clients` (Debian's build has `--with-maxminddb`, Module 4); the MaxMind databases are not part of Debian's bind9 and not in the lab
- **Health-checked answers:** a provider feature, not a DNS standard: for example Route 53 health checks with DNS failover stop handing out an address whose probes fail; the TTL decides how long clients keep the old one
- **Compared with anycast:** GeoDNS chooses per resolver at query time; anycast chooses per packet by routing. Many services use both

<!--
RFC 7871 Abstract and §11.1 ("encouraged to conceal part of the user's IP address by truncating IPv4 addresses to 24 bits. 56 bits are recommended for IPv6"). BIND 9.20 ARM §5 (ACLs: "geoip db database field value"; fields country, region, city, continent, postal, metro, area, tz, isp, asnum, domain); geoip-directory default /usr/share/GeoIP (named -C), which Debian's AppArmor profile allows. AWS documentation "Creating Amazon Route 53 health checks" and DNS failover (fetched 28 October 2026). Not tested in the lab.
-->

---
<!-- _class: dense -->
## TTL Strategy at Scale

- Module 2 set the basics: short TTLs before a change, long ones after; the negative TTL is the lower of the SOA MINIMUM and the SOA's own TTL (RFC 2308)
- **RFC 9199 C5:** "Consider Longer Time-to-Live Values Whenever Possible": caching gives speed, less traffic and protection from short outages and attacks
- **RFC 9199 C6:** parent and child copies of NS and glue can have different TTLs; most resolvers follow the child's
- **Load balancing wants short TTLs, resilience wants long ones:** a 30-second TTL moves traffic fast, and without serve-stale makes an outage of all the authorities visible to users within 30 seconds
- **Anycast and hidden primaries change little here:** TTLs decide how long old answers live, whatever served them
- Write the TTL for each name down with its reason: change frequency, failover time, query load

---
<!-- _class: dense table-compact -->
## Resolver Cache Controls in BIND 9.20

| Option | Default (`named -C`) | What it does |
|---|---|---|
| `max-cache-ttl` | 604800 (1 week) | caps positive TTLs; 0 "may cause all queries to return SERVFAIL" (ARM) |
| `max-ncache-ttl` | 10800 (3 hours) | caps negative caching |
| `min-cache-ttl`, `min-ncache-ttl` | 0 | floor for TTLs, at most 90 s: overrides the zone owner |
| `prefetch` | 2 9 | a query for a record with 2 s or less left refreshes it, if its TTL was 9 s or more |
| `servfail-ttl` | 1 | caches SERVFAIL; RFC 9520 says 1 s to 5 minutes for resolution failures |
| `stale-cache-enable`, `stale-answer-enable` | no, no | keep and serve expired records (next slide) |

- Each view and each anycast instance has its own cache: flush all of them after an emergency change

<!--
Defaults from named -C (BIND 9.20.30); texts from the ARM entries. RFC 9520 §3.2: "Resolvers MUST cache resolution failures for at least 1 second" and they "MUST NOT be cached for longer than 5 minutes". Rehearsal S.3: after VM 1 came back, VM 2 answered again on the third try one second apart.
-->

---
<!-- _class: dense -->
## Serve-Stale (RFC 8767)

```text
options { ... stale-cache-enable yes; stale-answer-enable yes; ... };   # VM 2, rehearsal only
VM 1 stopped, cache expired:
$ dig @127.0.0.1 www.teamNN.example
  status: NOERROR   EDE: 3 (Stale Answer): (resolver failure)
  www.teamNN.example.   30   IN   A   192.0.2.80
Without serve-stale:   status: SERVFAIL
```

- When the authorities cannot be reached, the resolver answers from expired data, marked with EDE 3 and a short TTL (`stale-answer-ttl`, 30 s)
- RFC 8767 suggests keeping stale data "between 1 and 3 days" (`max-stale-ttl`, default 1 day)
- **For:** an outage of your servers becomes invisible to users who asked recently. **Against:** a removed record can live on; an attacker who silences your servers freezes the old answers
- Off by default in BIND 9.20 and in this course's resolvers; if you enable it, count stale answers in your monitoring (Module 11)

<!--
Rehearsed (S.1, S.2): stale-cache-enable yes; stale-answer-enable yes; plus max-cache-ttl 5 only to expire the cache quickly; VM 1's named stopped. The stale answer came in 11 ms because VM 1's host answered with ICMP port unreachable; with an unreachable host, BIND waits for its resolver timeout first (stale-answer-client-timeout off by default). VM 2's options went back to Module 4's afterwards.
-->

---
<!-- _class: dense -->
## Caches in a Multi-Server Design

- **Who caches what:** stub resolvers and browsers, the resolver (per view, per instance), forwarders behind it; an answer can be old at any of these
- **Cold caches:** a restarted or newly announced resolver instance starts empty and sends a burst of queries upstream; stagger restarts
- **Emergency change:** lower the TTL first if you can wait; if not, change the data, then flush where you control (`rndc flushname`, `flushtree`, `flush`), and wait out the old TTL everywhere else
- **Negative answers are cached too:** adding a name that someone looked up a moment ago takes up to the negative TTL to appear (RFC 2308)
- **Measure the cache with your own traffic:** BIND's statistics channel shows cache hits and misses (Module 4 Lab 4.1); hit rates differ per instance and per catchment

---
<!-- _class: section-divider -->
# 6 · Troubleshooting a Distributed Service

---
<!-- _class: dense -->
## "It Works for Me": Four Questions

1. **Which server answered?** Listed server, which instance (NSID), or a cache in between
2. **Which version of the data?** SOA serial on that server; a view; a stale answer (EDE 3)
3. **Which path?** Resolver used, forwarders, the route to an anycast address from where the user is
4. **How old is it?** The TTL in the answer counts down in caches (Module 1); compare it with the zone's TTL

- Then reproduce from the user's side: their resolver, their network, their address family
- Module 1's method still applies (start at the user, walk the delegation with `+norec`); this section adds the questions that several servers raise

---
<!-- _class: dense -->
## Ask Every Server

```text
for s in 192.0.2.30 198.51.100.6 198.51.100.14; do
    echo "$s $(dig @$s zone SOA +short +norec)"
done
dig @198.51.100.53 www.svc.test +nsid +norec      # which instance, from here
dig @<server> name +norec                        # aa? data? from the server itself
```

- One loop over every listed address and every instance's unicast address finds most inconsistencies: different serials, missing zones, REFUSED
- **Read the flags:** `aa` from an authority, `ra` and no `aa` from a resolver (Module 1); `rd` without `ra` from a server that does not recurse for you
- **Read the EDE** (RFC 8914): 3 Stale Answer, 18 Prohibited, 20 Not Authoritative, 22 No Reachable Authority; 33 (IANA registry, not in RFC 8914) when a negative trust anchor applies: VM 2 adds it under `example` because of Module 3's `validate-except`
- Then the logs: NOTIFY and transfer lines on primary and secondaries, query logs (with the view), health and BGP state for anycast

<!--
The loop's addresses are the lab's: VM 1 and the two anycast sites' own addresses; in production, every NS address plus each instance's management address. EDE codes from RFC 8914 §4; code 33 is in the IANA registry ("Negative Trust Anchor"); the rehearsal's serve-stale step shows VM 2 adding "EDE: 33: (Negative Trust Anchor applied (RFC 7646))".
-->

---
<!-- _class: dense table-compact -->
## Symptoms and Where to Look

| Symptom | Likely layer | Evidence |
|---|---|---|
| Change visible on one server only | serial or transfer | SOA on all servers; "unchanged" or transfer errors in logs |
| Some users get an old answer | one instance or a cache | NSID per catchment; TTL left in their resolver's answer |
| Internal users see the public answer | views | which address reached the server; query log "view ..." |
| One city cannot resolve | anycast site announced but dead | routes at the routers; the site's own address; health log |
| Users far away are slow | catchment | NSID from their side; AS paths; prepending |
| Answers flap between two values | two instances or two views disagree | ask each one directly |

- Fix the source, then check every server again; then wait out the TTLs or flush the caches you control

---
<!-- _class: dense -->
## Exercise: Three Reports from the Service Desk

The anycast service `198.51.100.53` (`www.svc.test`) has sites A and B. For each report, say what you would ask, which commands you run, and what you expect to see.

1. "Users in city 2 still reach the **old address** of `www.svc.test`, users in city 1 the new one."
2. "Since ten minutes ago **nobody in city 1 can resolve** anything in `svc.test`; city 2 is fine."
3. "City 1 users say lookups have become **slow**; the answers are correct."

Lab 5.4 gives you faults like these on your own VM, without saying which.

<!--
Answers (accept others with the same evidence):
1. A stale instance: dig +nsid from both cities (city 2 answered by site B), then SOA at each site's own address (198.51.100.6 and .14): B has an older serial (2026102701 instead of 2026102801). Cause: site B missed transfers or loaded an old file. Fix: reload or retransfer at B; then add a serial check per instance to monitoring. (Lab 5.4, instructor fault 1.)
2. A site that is announced but not answering: from city 1, connection refused or timeout; R1 still forwards to site A (status); site A's named and health check both stopped. Cause: the health check died with the server, so nothing withdrew the route. Fix: start named, and run the health check independently (supervised), with an alarm when it stops. (Instructor fault 2.)
3. Catchment shift: dig +nsid from city 1 says site-b; R1's paths show site A's announcement with AS path 65100 65100 65100, longer than the path via R2. Cause: prepending at site A (left from a maintenance or an attack response). Fix: remove the prepend, birdc configure. (Instructor fault 3.) In the lab "slow" cannot be measured: every hop is inside one VM.
-->

---
<!-- _class: dense -->
## Operating It: a Change Checklist

- **Before:** lower TTLs if the change moves addresses; know every server and instance that must change; have the SOA loop ready
- **Change at the source:** the hidden primary, or both view files; raise each serial
- **After:** NOTIFY and transfer lines in the logs; SOA loop: one serial everywhere; ask each instance by NSID; ask from inside and outside if there are views
- **Anycast change:** one site at a time, withdrawn first, checked through its own address, then announced again
- **Write down** what you changed, when, and the old values, for the next person who asks "it works for me"
- Monitoring (Module 11) runs the same checks every minute; this section is what you do by hand when it alarms

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

```text
 VM 1 192.0.2.30              VM 2 192.0.2.10                  registry .53   lab resolver .55
 BIND :53 primary             BIND :53 resolver                example.       "a resolver elsewhere"
 + public secondary (5.1)     + hidden primary (5.1)
 + views (5.2)                + anycast lab in namespaces (5.3-5.4)
```

- **Packages:** `bird2` is in the VM image with its service disabled; with a mirror: `sudo apt install --no-install-recommends bird2`, then `sudo systemctl disable --now bird`. `iproute2` is part of Debian
- **Kit** `labs/module05/`: `vm2/` (hidden primary), `vm1/` (public secondary, views, internal records), `anycast/` (`anycast-lab.sh`, BIRD and named files, `healthcheck.sh`, the zone); `instructor/` is the instructor's
- **Logs:** `sudo journalctl -u named -f` on both VMs; the anycast lab's logs are in `/run/m05-anycast` and `/var/cache/bind/m05-anycast`
- **Offline:** everything uses your VMs, the registry and the lab resolver. Replace `NN` and the addresses with your lab sheet's
- **End state (Lab 5.4):** both VMs as Module 4 left them; `teamNN.example` two serials higher

---
<!-- _class: dense -->
## Lab 5.1: Hidden Primary (25 min)

1. VM 2: save `named.conf.local` as `.m04`; zone file `vm2/db.hp.teamNN.example` into `/var/lib/bind`; append `vm2/named.conf.hidden-primary`; check; `sudo rndc reconfig`; `sudo rndc querylog on`. Ask it for `www.hp.teamNN.example`: why REFUSED?
2. VM 1: save `named.conf.local`; append `vm1/named.conf.public-secondary`; check, reconfig, `querylog on`; find "transferred serial"; ask VM 1 with `+norec`
3. VM 1: add `hp IN NS ns1.teamNN.example.` to your zone, raise its serial, `sudo rndc reload teamNN.example`
4. VM 2: `dig @192.0.2.55 www.hp.teamNN.example`, then walk it with `+norec`. Whose log shows the lab resolver?
5. AXFR of `hp.teamNN.example` from VM 2 itself, then from VM 1
6. VM 2: add `app IN A 192.0.2.121`, new serial, reload the zone; read both journals. Change it to .122 **without** a new serial; from VM 1 ask VM 2 (`@192.0.2.10`) and VM 1 (`@127.0.0.1`); then raise it
7. Clean up both VMs: saved files back; VM 1: `hp` line out, serial up, reload, reconfig, then delete the secondary's file; VM 2: reconfig, delete the zone file, `querylog off`

> **Checkpoint:** answers reach the lab resolver from VM 1 only; the missing serial explained; both VMs clean (3A, task 2)

<!--
Rehearsed 28 October 2026 (rehearse.sh 5.1.1-5.1.8c). Step 1: REFUSED, EDE 18 Prohibited. Step 2: "transferred serial 2026102801", flags qr aa, www.hp 192.0.2.120, the file bind 644 in /var/cache/bind. Step 4: 192.0.2.120; the registry refers to ns1.teamNN.example (192.0.2.30); VM 1's log has 192.0.2.55, VM 2's has no query from it. Step 5: "Transfer failed." from VM 2, 4 records to VM 1. If there is time: VM 1 against itself also fails (BIND 9.20's allow-transfer default none), so nobody can copy the zone from the public server either. Step 6: VM 2 "sending notify to 192.0.2.30#53" only, VM 1 "notify from 192.0.2.10" and "transferred serial 2026102802"; then "zone serial (2026102802) unchanged" and hidden=.122 public=.121 with the same serial; after the new serial VM 1 has .122. Step 7: the zone diff against the start is the serial line only (2026102709 -> 2026102711 in the harness). Assess 3A task 2 before step 7.
-->

---
<!-- _class: dense -->
## Lab 5.2: Split Horizon with Views (20 min)

1. VM 1: copy `named.conf.local` and `named.conf` to `*.m04`. Install `vm1/named.conf.views` as `named.conf.local` (your `NN`, N1 N2, VM 2's address); `named-checkconf`: which zone is outside a view?
2. Put `//` before the root-hints `include` in `named.conf`. `sudo cp /var/lib/bind/db.teamNN.example /var/lib/bind/db.teamNN.example.internal`, append `vm1/internal.additions`, raise its serial; `named-checkconf -z`; `sudo rndc reconfig`
3. From VM 1: `dig @127.0.0.1 intranet.teamNN.example`. From VM 2: `sudo rndc flushtree teamNN.example`, then `intranet` and `whichview TXT` through 192.0.2.10 and through 192.0.2.55. VM 1's query log: which view?
4. `sudo rndc reload teamNN.example`, then `sudo rndc reload teamNN.example IN internal`
5. Comment out VM 2's line in `acl "internal"`; reconfig. On VM 2 ask for `intranet` again, then flush and ask; `dig @192.0.2.30 www.teamNN.example`: which flags?
6. Undo: move both `*.m04` files back, delete the internal zone file, check, reconfig; then `sudo rm /var/cache/bind/internal.mkeys* /var/cache/bind/external.mkeys*`; `sudo rndc querylog off`

> **Checkpoint:** VM 2 sees `intranet` and "internal", the lab resolver NXDOMAIN; the cached answer after the ACL change explained; VM 1 without views, files as before (3A, task 3)

<!--
Rehearsed (5.2.1-5.2.6b). Step 1: "named.conf.root-hints:2: when using 'view' statements, all zones must be in views". Step 2: two copies loaded (serials 2026102712 internal, 2026102711 external, in the harness). Step 3: 192.0.2.90 and "internal" via VM 2; NXDOMAIN via the lab resolver; log lines "view internal" from 192.0.2.10 and "view external" from 192.0.2.55. Step 4: "found in multiple views", then "zone reload up-to-date". Step 5: cached 192.0.2.90, then NXDOMAIN; flags qr aa rd (no ra: recursion no in the external view). Step 6: no "view" in new log lines, both files byte-equal to the saved copies. Assess 3A task 3 before step 6.
-->

---
<!-- _class: dense -->
## Lab 5.3: Anycast in One VM (25 min)

1. VM 2, in `labs/module05`: read `anycast/bird-r1.conf`, `bird-site-a.conf`, `named-site-a.conf`, `healthcheck.sh`. `sudo sh anycast/anycast-lab.sh up`; `ip netns list`
2. `sudo sh anycast/anycast-lab.sh status`: how many paths does R1 have, which one is in use, and why?
3. `sudo ip netns exec m05-c1 dig @198.51.100.53 www.svc.test +nsid`; the same from `m05-c2`; `id.server CH TXT`; from C1, site B's own address 198.51.100.14
4. Ten queries from each client; count them in `/var/cache/bind/m05-anycast/a/query.log` and `.../b/query.log`
5. In a second SSH session: `while sleep 0.2; do sudo ip netns exec m05-c1 dig @198.51.100.53 www.svc.test +nsid +time=1 +tries=1 | grep -o 'site-.' || echo fail; done`. Then `sudo sh anycast/anycast-lab.sh stop a`; read `/run/m05-anycast/a-health.log` and `status`
6. `sudo sh anycast/anycast-lab.sh start a`: when does C1 return to site A?

> **Checkpoint:** C1 answered by site A, C2 by site B, each site logging only its city; after `stop a`, C1 at site B within a second or two and R1's route via R2; back after `start a` (3A, task 1)

<!--
Rehearsed (5.3.1-5.3.7). Step 2: R1 "unicast [site_a ...] * (100) [AS65100i]" with AS path 65100, and a second path via r2 with 65002 65100. Step 3: NSID "site-a" for C1, "site-b" for C2, both www 198.51.100.80. Step 4: site a c1=10 c2=0, site b c1=0 c2=10. Step 5: "+0.1 s fail, +0.7 s site-b"; health log "site a: named down, route withdrawn"; R1 forwards via 198.51.100.10. Step 6: "site-a" again, "named up, route announced". The loop uses NSID, not id.server: BIND rate-limits CHAOS answers to 3 per second.
-->

---
<!-- _class: dense -->
## Lab 5.4: Troubleshooting Drill and Clean-Up (20 min)

The instructor breaks your anycast lab three times, one fault at a time, and gives you only the symptom. For each:

1. Gather evidence before changing anything: `+nsid` from both cities, the SOA at each site's own address, `sudo sh anycast/anycast-lab.sh status`, the health logs
2. Name the cause and show the instructor the output that proves it, and what ruled the other causes out
3. `sudo sh anycast/anycast-lab.sh fix`; check that each city is back at its own site
4. After the third: `sudo sh anycast/anycast-lab.sh down`; `ip netns list` (empty); `sudo ss -lntup` (only `named` on port 53)
5. Both VMs: `named-checkconf`; `ls /etc/bind /var/lib/bind /var/cache/bind` (no `.m04`, `hp`, `internal` or `mkeys` files); `sudo rndc status | grep 'query logging'` (OFF); `dig @192.0.2.10 www.teamNN.example`

> **Checkpoint:** each fault explained with the commands that showed it, in the order you ran them; nothing of Module 5 left on either VM (3A, task 4)

**Discussion** (a minute per team): which of today's patterns would your own zones need first, and what would you monitor?

<!--
The instructor sets the faults with labs/module05/instructor/faults.sh (answers in its README), piped to each team's VM 2 over SSH; choose the order and do not name the fault. Rehearsed (5.4.1-5.4.7). Fault 1: c1 site-a 198.51.100.80, c2 site-b 198.51.100.81; SOA at 198.51.100.6 serial 2026102801, at 198.51.100.14 2026102701. Fault 2: c1 "connection refused", c2 site-b; R1 still via 198.51.100.6; site a named stopped, health check stopped. Fault 3: both cities site-b; R1's path via site A has AS path 65100 65100 65100, R1 forwards via R2. After fix: each city at its own site. After down: no namespaces, no /run/m05-anycast, /etc/bind/m05-anycast or /var/cache/bind/m05-anycast, one named; both VMs' named.conf, named.conf.local and named.conf.options byte-equal to the pre-Module-5 copies; the team zone differs from the start in the serial line only. Module 6 starts from this state.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 1034, 1982, 1996 (NOTIFY), 2182 (BCP 16), 2308, 2782, 4271 (BGP), 5321
- RFC 3258, 4786 (BCP 126), 7094, 9199: anycast and large authoritative operators
- RFC 4892, 5001 (NSID); RFC 8914 (EDE); RFC 8767 (serve-stale); RFC 9520
- RFC 6724, 7871 (ECS), 9460 (SVCB/HTTPS); RFC 8375, 9432, 8901
- RFC 9499 (BCP 219) terminology, quoting RFC 4641 (obsoleted by 6781); RFC 5737, 6761, 6996 (lab addresses, `.test`, private ASNs)
- ISC: BIND 9.20 ARM (views, `in-view`, `notify`, RRset ordering, cache and stale options); `named -C`
- BIRD 2.17 documentation (bird.network.cz), Debian `bird2` package
- root-servers.org (instances, sites)

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>dig @srv zone SOA +short +norec
dig @addr name +nsid
dig @addr id.server CH TXT
rndc reload zone IN view
rndc flushtree name
named-checkconf -z
ip netns list
ip netns exec NS cmd
birdc -s SOCK show route all
sh anycast-lab.sh status
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. Your hidden primary's change reached ns1 but not ns2. Name three causes and the command that tells them apart.
2. Why might `notify yes` not reach a DNS provider's secondaries, and what do you configure instead?
3. An anycast site's `named` crashed but the site's router still announces the prefix. What do users see, and what should have happened?
4. Two anycast instances serve different data. How do you find out which users are affected?
5. Your internal users get the external view of a split zone. Name two reasons.
6. When would you enable serve-stale on a resolver, and what risk do you accept?

<!--
1. The secondary did not get the NOTIFY (notify explicit without it in also-notify, firewall), the transfer is refused (allow-transfer, TSIG mismatch), or the serial did not go up: SOA from both (dig @ns1/@ns2 zone SOA +norec) and the logs on the primary (notify, xfer-out) and ns2 (notify from, transfer, refresh failure).
2. notify yes sends to the addresses of the NS names (minus the SOA MNAME); a provider's listed servers are usually anycast addresses that do not take NOTIFY or transfers; it gives separate addresses: also-notify (with notify explicit) and allow-transfer for those, with TSIG.
3. Users in that site's catchment get no answer (refused or timeout); resolvers retry other listed servers, so it shows as slowness or failures for one region. The health check should have withdrawn the route (RFC 4786 §4.4.1) and an alarm should have fired.
4. Query each instance by its own address for the SOA and the record; ask the anycast address from many places with NSID (probes, RIPE Atlas, users) to map which catchments reach the bad instance.
5. The resolver they use reaches the authoritative server from an address outside the internal ACL (NAT, a new resolver, a forwarder to an outside resolver), or the view order puts a matching external view first, or they cached an answer from when they were outside.
6. When the availability of answers matters more than their freshness (an ISP resolver facing outages of popular authorities); risk: removed or changed records live on for up to max-stale-ttl; an attacker who blocks the authorities can keep old answers in place.
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
