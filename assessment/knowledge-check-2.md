# Knowledge Check 2: DNS Infrastructure (Day 2)

Covers Modules 3 and 4. Taken on paper in the last 15 minutes of Session 3 on Day 2 (`dns_assessment_plan.md`).

## How to build the paper

- The bank has 12 question slots in the plan's four focus areas, and two variants (a and b) of each slot. Pick one variant per slot, so a paper has 12 questions: about 75 seconds each.
- Use at most three short-answer questions per paper.
- The answer key is in `assessment/instructor/knowledge-check-2-key.md`; do not hand it out. The repository is public, so for a graded paper also change the names or addresses in some questions.
- One point per question; a short answer needs every part listed under "Accept" for the point. Pass: 9 of 12 (70%, rounded up).
- Questions marked **SA** are short answer; the rest are multiple choice with one correct option.
- Slide references in the key are to the Module 1 (M1), Module 3 (M3) and Module 4 (M4) decks.

## R. DNS server roles and relationships (4 questions)

**R1a.** A server answers `dig @192.0.2.30 www.team01.example +norec` with `flags: qr aa ra`. What does that tell you about it?
(a) It is a resolver that answered from its cache, so the copy may be old (b) It is authoritative-only and refuses recursion (c) It is authoritative for this zone, and it also offers recursion (d) It is a forwarder passing your query to the primary

**R1b.** `dig @192.0.2.53 www.team01.example` returns `flags: qr rd`, `ANSWER: 0`, one NS record in authority, and `recursion requested but not available`. What is 192.0.2.53?
(a) A recursive resolver that could not reach the zone's servers (b) An authoritative-only server sending a referral (c) A forwarder whose upstream resolver is down (d) A stealth secondary with an expired copy of the zone

**R2a.** A new secondary logs `failed while receiving responses: REFUSED` for every transfer. What do you change?
(a) The secondary's address, or a TSIG key, in `allow-transfer` on the primary (b) The serial on the primary, so that it is higher than the secondary's copy of it (c) `also-notify` on the secondary, so that it hears the primary (d) `forward only` on the secondary, so that it asks the primary first

**R2b. (SA)** `team01.example` lists only `ns1` in its NS set, and `ns1` is also the SOA MNAME. VM 2 is a secondary for the zone. After a change on the primary, why does VM 2 receive no NOTIFY, and which statement on the primary fixes that?

**R3a.** A secondary has not reached its primary for 20 days. The zone's SOA EXPIRE is 1209600. What do the secondary's clients get for names in the zone?
(a) The last copy, still marked `aa` (b) SERVFAIL (c) NXDOMAIN for every name (d) The last copy, without `aa`

**R3b.** The primary's zone file was edited by hand and reloaded with a higher serial. The secondary asks for IXFR. What does BIND 9.20 send by default?
(a) Only the changed records, from its journal (b) Nothing, until the secondary gives up and asks for AXFR instead (c) A refusal, because the zone has no journal (d) The whole zone, because no journal holds the change

**R4a.** Why does a stealth secondary not count towards RFC 2182's recommended three listed servers?
(a) It cannot answer with `aa`, because it holds only a transferred copy (b) RFC 2182 forbids secondaries on the same site (c) It may not hold an SOA record of its own (d) It is not in the NS set, so resolvers elsewhere never ask it

**R4b.** `zone "corp.example" { type forward; forward only; forwarders { 10.1.1.1; }; };` gives SERVFAIL, and the log says `non-improving referral`. What is 10.1.1.1, and what do you change?
(a) A resolver that is down; add a second forwarder (b) An authoritative-only server; use `static-stub` with `server-addresses` (c) A secondary with an expired zone; restore its primary (d) A resolver that refuses your queries by policy; add your address to its `allow-recursion` list

## W. Software platform capabilities (4 questions)

**W1a.** Which of these has no recursion, by design?
(a) BIND 9 (b) Unbound (c) NSD (d) PowerDNS Recursor

**W1b.** Which Unbound setting does the job of BIND's `validate-except` for the lab's `example.`?
(a) `local-zone: "example." static` (b) `stub-zone:` with `stub-addr` (c) `access-control: example. allow` (d) `domain-insecure: "example."`

**W2a.** You load a zone into PowerDNS 4.9 with `pdnsutil load-zone`, and queries for it return REFUSED. What is the cause?
(a) The API key is missing from the query (b) The running server's zone cache does not list the new zone yet (c) The SQLite file belongs to the wrong user (d) PowerDNS needs a NOTIFY from a primary before it serves any new zone

**W2b.** Three PowerDNS servers use the generic SQL backend in native mode. How do `ns2` and `ns3` get a change made on `ns1`?
(a) Through the database's own replication; no NOTIFY or zone transfer (b) By NOTIFY and IXFR from `ns1`, in the same way as BIND secondaries do (c) Through a catalog zone that `ns1` publishes (d) Each server polls the others' HTTP API

**W3a.** Unbound 1.26 listens on the VM's address (`interface: 192.0.2.10`) and has no `access-control` lines. A host on the same subnet sends it a query. What happens?
(a) It answers: the local subnet is allowed by default (b) It answers only names in its local zones (c) It refuses: only localhost is allowed by default (d) It drops the query without a reply

**W3b.** What must a BIND 9.20 server have before `rndc addzone` works?
(a) A catalog zone that lists the new zone (b) A TSIG key shared with `rndc` (c) A `dnssec-policy` for the new zone (d) `allow-new-zones yes`

**W4a. (SA)** Before you choose a DNS server version for a three-year deployment, name two things to find out about who fixes its bugs.

**W4b.** Which way of moving a zone into new software does Module 4 call the safest?
(a) A zone transfer: the new server fetches the zone as a secondary of the old primary (b) Copying the old server's zone file and loading it with the new server's import tool, relative names and all (c) Typing the records into the new server's web console (d) Copying the old server's database files across

## A. Architecture decision factors (2 questions)

**A1a.** A branch office has no direct Internet path. Its users need internal and external names, and every answer should be validated. Which design does Module 3 describe as typical?
(a) An authoritative-only server at the branch, holding a copy of every internal and external zone its users need (b) An open resolver at the branch that anyone may use (c) Branch resolvers forwarding to two central resolvers, which resolve from the root and validate (d) `forward only` from each laptop to one central resolver

**A1b.** A resolver has `forward only; forwarders { 192.0.2.250; };`, and nothing answers at 192.0.2.250. What do its clients get?
(a) Answers, because the resolver falls back to the root servers (b) SERVFAIL for every name not in its cache, after a delay (c) Answers from the cache, marked stale (d) NXDOMAIN for names not in the cache

**A2a. (SA)** Give two reasons to run authoritative service and recursive service on separate servers.

**A2b.** Why run different software on your listed authoritative servers?
(a) The protocol requires at least two implementations (b) Different software answers queries faster (c) Resolvers prefer servers that differ (d) One software bug cannot stop all of them at once

## F. Performance considerations (2 questions)

**F1a.** A vendor publishes a query rate for its server. What does Module 4 tell you to do with it?
(a) Measure your own servers with your own query mix, and record the set-up with the number (b) Use it to size your servers, adding a safety margin of half the published rate for peaks (c) Compare it with the other vendors' published rates (d) Ignore performance: every implementation is fast enough

**F1b.** How large does BIND 9.20 let its resolver cache grow when `max-cache-size` is not set (one view)?
(a) 4 MB, as Unbound's default (b) Until the cache's TTLs expire, with no size limit (c) 90% of physical memory (d) 1 GB

**F2a.** All of a zone's servers are unreachable, and a BIND 9.20 resolver's cached answer has just expired. With default settings, what does the client get?
(a) The expired answer, served stale (b) SERVFAIL, because serve-stale is off by default (c) NXDOMAIN, cached for the SOA record's negative-caching TTL (d) A referral to the zone's servers

**F2b.** For how long does BIND 9.20 cache a SERVFAIL by default?
(a) 30 seconds, the most it allows (b) 5 minutes, the RFC 9520 maximum (c) Not at all: failures are never cached (d) 1 second
