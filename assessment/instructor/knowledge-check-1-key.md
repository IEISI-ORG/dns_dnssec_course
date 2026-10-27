# Knowledge Check 1: Answer Key (instructor)

Key for `assessment/knowledge-check-1.md`. One point per question; a short answer (SA) needs every part listed under "Accept". Pass: 11 of 15.

| Q | Answer | Why | Source |
|---|---|---|---|
| A1a | (c) | 63 octets per label, 255 per name | RFC 1035 §2.3.4; M1 "A Tree of Labels" |
| A1b | (b) | names compare without regard to case | RFC 4343; M1 "A Tree of Labels" |
| A2a | (d) | the parent's zone file holds the delegation (NS and glue) and nothing else of the child's data; the NS set at the cut is the child's property (RFC 2181 §6.1), but the parent holds a copy to send in referrals | RFC 1034 §4.2; M1 "Domains and Zones" |
| A2b | (b) | delegation is an NS record set in the parent at the child's name | RFC 9499; M1 "Delegation and Glue" |
| A3a | (a) | `ns1.example.org` is in-domain (MUST); `ns.example.net` is unrelated: the resolver looks it up from `net` | RFC 9471; M1 "Delegation and Glue" |
| A3b | (b) | a server in another child of the same parent is a sibling domain; glue SHOULD be sent | RFC 9499, RFC 9471; M1 "Delegation and Glue" |
| A4a | (c) | no `aa`, empty answer, NS records in authority: a downward referral | RFC 9499; M1 "A Referral, Line by Line" |
| A4b | (d) | NOERROR, empty answer, SOA in authority | RFC 2308; M1 "Response Codes" |
| A5a | (b) | `a` to `m`; Verisign runs `a` and `j` | root-servers.org; M1 "Root Server Operators and RSSAC" |
| A5b | SA | Accept: a root server (from its root hints), which sends a referral to the `com` servers with their addresses as glue. Both parts needed | M1 "Resolving www.example.com", "A Referral, Line by Line" |
| B1a | (c) | AAAA, type 28; A6 is historic | RFC 3596; M1 "Five Record Types for Today" |
| B1b | (a) | NS; the SOA names only the primary (MNAME) | RFC 1035; M1 "Five Record Types for Today" |
| B2a | (d) | (a) breaks "no other data" beside a CNAME; (b) the apex holds SOA and NS; (c) an MX target must not be an alias | RFC 1034 §3.6.2, RFC 2181 §10.1, §10.3; M2 "CNAME: An Alias" |
| B2b | (c) | HTTPS (or SVCB) in AliasMode; ALIAS and ANAME are not registered types; DNAME redirects the names below, not the name itself | RFC 9460 §2.4.2, RFC 6672; M2 "The Apex Problem" |
| B3a | (b) | lower preference values are tried first | RFC 5321 §5.1; M2 "MX: Where Mail Goes" |
| B3b | (d) | null MX | RFC 7505; M2 "MX: Where Mail Goes" |
| B4a | SA | Accept: SERIAL; it must go up (within 2³¹ − 1) on every change, because secondaries transfer only when the primary's serial is newer | RFC 1034 §4.3.5, RFC 1982; M2 "Serial Numbers" |
| B4b | (c) | RNAME: the mailbox, with `@` written as a dot | RFC 1035 §3.3.13, RFC 1912 §2.2; M2 "The SOA Record" |
| B5a | (b) | octets reversed under `in-addr.arpa` | RFC 1035 §3.5; M2 "Reverse Zones and PTR" |
| B5b | (c) | the CA climbs from `www` to the apex and uses the first CAA RRset it finds | RFC 8659 §3; M2 "CAA: Which CAs May Issue" |
| C1a | (d) | a cached copy counts down; the source always says 300 | RFC 1034 §2.2; M1 "Caching and TTL" |
| C1b | (a) | one RRset has one TTL; BIND warns `TTL set to prior TTL` and uses the first | RFC 2181 §5.2; M2 "Directives" |
| C2a | SA | Accept: 300 seconds, the smaller of the SOA record's TTL and its MINIMUM | RFC 2308 §5; M2 "Choosing TTLs" |
| C2b | SA | Accept: 600 seconds. The negative TTL is the smaller of 600 and 86400; Unbound's default cap (`cache-max-negative-ttl`, 3600) does not cut it | RFC 2308 §5; unbound.conf(5); M2 "Choosing TTLs" |
| C3a | (b) | lower it at least one old TTL (3600 s) before the change; any earlier time also works | RFC 1912 §2.2; M2 "Planning a Change" |
| C3b | SA | Accept one from each side. Long: fewer queries, faster answers from cache, survives a short outage of your servers. Short: changes reach users sooner | RFC 1034 §2.2; M2 "Choosing TTLs" |
| D1a | (c) | the registrar is the go-between for registrants and registries | RFC 9499; M1 "Registries, Registrars and Registrants" |
| D1b | (d) | the DNS operator, who may be the registrant, the registrar or a third party | M1 "Registries, Registrars and Registrants" |
| D2a | (b) | PTI performs the IANA functions | iana.org; M1 "ICANN and IANA" |
| D2b | (c) | RSSAC037 names the Root Zone Maintainer for building, signing and distributing | RSSAC037; M1 "Changing the Root Zone" |
