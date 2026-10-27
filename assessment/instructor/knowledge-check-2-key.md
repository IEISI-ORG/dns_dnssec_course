# Knowledge Check 2: Answer Key (instructor)

Key for `assessment/knowledge-check-2.md`. One point per question; a short answer (SA) needs every part listed under "Accept". Pass: 9 of 12.

| Q | Answer | Why | Source |
|---|---|---|---|
| R1a | (c) | `aa`: from a zone it serves; `ra`: it offers recursion to you. VM 1 with Debian's defaults does both | M3 "Read the Flags" |
| R1b | (b) | no `aa`, empty answer, NS in authority, no recursion: an authoritative-only server's referral | M3 "Read the Flags"; M1 "A Referral, Line by Line" |
| R2a | (a) | the primary refused the transfer; BIND 9.20's `allow-transfer` default is none | BIND 9.20 ARM; M3 "Transfer Problems and What BIND Logs" |
| R2b | SA | Accept both: NOTIFY goes to the NS set except the MNAME, which here leaves nobody; add `also-notify { <VM 2>; };` to the zone on the primary | RFC 1996 §2.1; M3 "The Primary's Side" |
| R3a | (b) | after EXPIRE (14 days) without a successful refresh the zone is no longer authoritative | RFC 1035 §3.3.13; M3 "When the Primary Is Down" |
| R3b | (d) | "IXFR version not in journal, falling back to AXFR"; `ixfr-from-differences` is off by default | M3 "AXFR or IXFR" |
| R4a | (d) | a stealth server is not in an NS record; only servers configured to use it ask it | RFC 1996 §2.1, RFC 2182 §5.1; M3 "Stealth Servers and Hidden Primaries" |
| R4b | (b) | a forwarder must be a resolver; an authoritative server's referral is rejected. Forwarding to a resolver that can resolve `corp.example` also works | M3 "A Forwarder Must Be a Resolver", "Three Ways to Send a Domain Elsewhere" |
| W1a | (c) | NSD "has not implemented recursive caching by design" | NLnet Labs; M4 "One Program for Both Jobs" |
| W1b | (d) | `domain-insecure` | unbound.conf(5) 1.26.2; M4 "BIND and Unbound, Side by Side" |
| W2a | (b) | the zone cache refreshes every 300 s, or on `pdns_control rediscover`; a REFUSED already given stays in the packet cache until `purge` | M4 "pdnsutil, pdns_control and the Zone Cache" |
| W2b | (a) | "PowerDNS assumes that the backend is taking care of replication unaided" | PowerDNS documentation; M4 "Native Replication or Zone Transfers" |
| W3a | (c) | "only localhost ... is implicitly allowed, the rest is refused" | unbound.conf(5); M3 "Who May Use It", M4 "Unbound in Brief" |
| W3b | (d) | `rndc addzone` needs `allow-new-zones yes`; zones are kept in `<view>.nzd` | BIND 9.20 ARM; M4 "Adding Zones Without Editing Files" |
| W4a | SA | Accept any two: the vendor's support period for that branch (end-of-life date); whether the distribution's security team patches the packaged version; where advisories are published and how you hear of them; whether paid support covers end-of-life versions; how fast you can test and install a fix | M4 "Who Fixes the Bugs, and for How Long", "21 October 2026" |
| W4b | (a) | AXFR loads the zone as the old server serves it; a file with relative names changed one record on import into PowerDNS 4.9 | M4 "Native Replication or Zone Transfers", "Moving a Zone to Other Software" |
| A1a | (c) | the typical enterprise pattern; validation on the resolvers that resolve | M3 "Should You Forward?" |
| A1b | (b) | `forward only` makes the forwarder a single point of failure: SERVFAIL after about 3 s in the lab; cached answers still come from the cache | M3 "forward only, forward first" |
| A2a | SA | Accept any two: different clients and risks (the world vs your users); a resolver serving a zone answers from its own copy even after the delegation moves; a cache open to the Internet is an open resolver used in reflection attacks; one restart or overload would take down both; each program can be patched and upgraded on its own | M3 "Two Jobs, Two Servers"; M4 "One Program for Both Jobs" |
| A2b | (d) | implementation diversity: one bug does not stop every listed server | M4 "One Program for Both Jobs" |
| F1a | (a) | published rates come from one set-up; measure with `dnsperf`/`resperf` on your own servers and record the set-up | M4 "Measure, Do Not Copy Benchmarks" |
| F1b | (c) | 90% of physical memory for one view, unless `max-cache-size` is set | BIND 9.20 ARM; M3 "Capacity: Measure, Then Plan" |
| F2a | (b) | `stale-answer-enable` and `stale-cache-enable` default to no | RFC 8767; BIND 9.20 ARM; M3 "Staying Useful When Servers Fail" |
| F2b | (d) | `servfail-ttl` default 1 s, at most 30; RFC 9520 requires at least 1 s and at most 5 minutes | RFC 9520; M3 "Remembering Failures and Servers" |
