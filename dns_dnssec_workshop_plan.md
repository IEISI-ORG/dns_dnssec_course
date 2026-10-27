# Advanced DNS/DNSSEC Workshop Plan

## Overview
This **modular training program** (six full days plus a Day 7 morning) is informed by ICANN, APNIC and NSRC training, and provides complete DNS training from fundamentals through advanced security and registry operations. The curriculum is structured in **12 modules** following a 90-minute theory + 90-minute practical format with learning objectives based on Bloom's Taxonomy.

**Course Structure (2 modules per day):**
- **Day 1:** DNS Fundamentals - Introduction and Operations (Modules 1-2)
- **Day 2:** DNS Infrastructure - Server Types and Software Platforms (Modules 3-4) 
- **Day 3:** Advanced Operations and Security Fundamentals (Modules 5-6)
- **Day 4:** DNSSEC and DNS Privacy Technologies (Modules 7-8)
- **Day 5:** Registry Operations - EPP and CoCCA Systems (Modules 9-10)
- **Day 6:** Monitoring and Emerging Technologies (Modules 11-12); course conclusion at the end of the day
- **Day 7 (morning only):** Final Project

**Daily Schedule:**
- **Session 1:** 09:00-10:30 (Theory Module A)
- **Break:** 10:30-11:00
- **Session 2:** 11:00-12:30 (Practical Module A)
- **Lunch:** 12:30-14:00
- **Session 3:** 14:00-15:30 (Theory Module B)
- **Break:** 15:30-16:00
- **Session 4:** 16:00-17:30 (Practical Module B)

### Program Facts
This section is the reference for program-level facts. The scope summary, overview deck, assessment plan and slide deck plan follow it; change facts here first.

| Item | Value |
|------|-------|
| Length | 6 full days + Day 7 morning (6.5 days) |
| Contact hours | 39: Days 1-6 at 4 × 90 min (36 h), Day 7 at 2 × 90 min (3 h) |
| Modules | 12, each 90 min theory + 90 min practical |
| Class size | Maximum 20 participants |
| Delivery options | A: Days 1-2 · B: Days 3-6 + Day 7 · C: Days 3-4 (see below) |

**Assessment timing** (assessment content is in `dns_assessment_plan.md`):
- **Practical assessments** are graded lab work. The instructor assesses the day's Appendix A lab exercises against the assessment tasks; they take no extra time.
- **Knowledge checks**, the **Day 3 mid-course assessment** and the **Day 5 case study** take the last 15-30 minutes of Session 3 (theory).
- **Day 6:** the course conclusion (30 min) takes the end of the Module 12 practical session; see Appendix A, Module 12.
- **Day 7:** Final Project in teams of 3-4. Session 1 (09:00-10:30): design and build. Session 2 (11:00-12:30): 15-minute team presentations and close. With 20 participants that is 5-7 teams, 75-105 minutes; with more than 5 teams, presentations start during Session 1.

---

## Alternative Course Programs

The modular design allows for flexible course delivery tailored to specific audiences and organisational needs:

### Option A: "Basic DNS Workshop" (2 Days)
**Target Audience:** Network administrators, system administrators, and IT professionals new to DNS
**Duration:** Days 1-2 of the full program
**Modules Covered:** 1-4

**Learning Outcomes:**
- Solid foundation in DNS concepts and operations
- Hands-on experience with DNS tools and basic configurations
- Understanding of different DNS software platforms
- Ability to manage basic DNS infrastructure

**Prerequisites:** Basic networking knowledge
**Certification:** "DNS Fundamentals Certificate"

---

### Option B: "Advanced Registry Operations" (4.5 Days)
**Target Audience:** Registry operators, registrar technical staff, and DNS professionals working with domain registration systems
**Duration:** Days 3-6 of the full program, plus the Day 7 Final Project
**Modules Covered:** 5-12

**Learning Outcomes:**
- Advanced DNS operations and architecture design
- DNSSEC implementation and management
- EPP protocol mastery and registry system operations
- CoCCA platform expertise
- Modern DNS security and monitoring capabilities

**Prerequisites:** Solid DNS fundamentals (completion of Option A or equivalent experience)
**Certification:** "Advanced Registry Operations Certificate"

---

### Option C: "DNS Security Intensive" (2 Days)
**Target Audience:** Security professionals, network administrators, and DNS operators focusing on security implementations
**Duration:** Days 3-4 of the full program
**Modules Covered:** 5-8

**Learning Outcomes:**
- Advanced DNS security threat understanding
- DNSSEC deployment and operational expertise
- DNS privacy technologies (DoT/DoH) implementation
- Security monitoring and incident response capabilities

**Prerequisites:** DNS fundamentals knowledge
**Certification:** "DNS Security Specialist Certificate"

---

## Course Combination Strategies

### Progressive Learning Path:
1. **Start with Basic DNS Workshop** (2 days) - Build foundation
2. **Follow with DNS Security Intensive** (2 days) - Add security expertise
3. **Complete with Advanced Registry Operations** (4.5 days) - Full professional competency

### Specialised Tracks:
- **Technical Operations Track:** Basic DNS → Advanced Registry Operations
- **Security Focus Track:** Basic DNS → DNS Security Intensive
- **Complete Professional Track:** Full program (6.5 days)

### Organisational Training Options:
- **Network Team Training:** Basic DNS Workshop for entire team
- **Security Team Enhancement:** DNS Security Intensive
- **Registry Staff Development:** Advanced Registry Operations
- **Management Overview:** Day 1 theory sessions only (executive briefing)

## Target Audience
- Network/systems administrators from ISPs, RENs, Universities, or corporations
- DNS operators responsible for authoritative and/or recursive DNS installations
- Registry and registrar technical staff
- Cybersecurity professionals working with DNS infrastructure
- Network engineers seeking in-depth DNS knowledge

## Prerequisites
- Basic understanding of TCP/IP networking concepts
- Familiarity with UNIX/Linux command line environment
- Understanding of client-server architecture
- No prior DNS experience required for foundational modules

---

## Module 1: Introduction to DNS - Foundations and Concepts
**Duration:** 90 minutes theory + 90 minutes practical
**Deck:** `modules/module01-dns-foundations.marp.md` (70 slides: 64 theory, 6 lab). Module 1 also opens the course (welcome, course structure and assessment from Program Facts). Lab kit: `labs/module01/`; lab servers: `labs/instructor` profile `m01`.

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall why the DNS replaced HOSTS.TXT (RFC 1034 §2.1) and the milestones from RFC 882/883 (1983) to RFC 1034/1035 (STD 13, 1987) and RFC 9499 (2024)
- Identify the parts of the namespace: labels, FQDNs, the root, TLD types (generic, country code, IDN, `arpa`), domains, zones, delegation and glue
- List who runs each part: IETF, ICANN, IANA (PTI), the Root Zone Maintainer, the 12 root server operators and RSSAC, registries, registrars, resellers, registrants, DNS operators, RIRs

**Comprehension (Understand):**
- Explain how a recursive resolver turns a name into an address by following referrals from the root, and what it caches
- Describe authoritative servers (primary, secondary), recursive resolvers, stub resolvers and forwarders (RFC 9499 terms)
- Compare the DNS with other ways hosts look up names (`/etc/hosts` and nsswitch, multicast DNS, LLMNR)

**Application (Apply):**
- Use `dig`, `host` and `nslookup` (Debian 13 packages `bind9-dnsutils`, `bind9-host`), and capture DNS traffic with `tcpdump` and `tshark`
- Trace a lookup from the root by hand with `dig +norec`, and with `dig +trace` when the classroom has Internet access

**Analysis (Analyse):**
- Read a DNS message: header flags (QR, AA, TC, RD, RA), RCODEs (NOERROR, NXDOMAIN, SERVFAIL, REFUSED), NODATA, sections, UDP and TCP, IPv4 and IPv6
- Diagnose a broken delegation (server does not serve the zone, unreachable server, stale glue, parent/child NS mismatch, missing delegation) and name who must fix it

### Theory Content
- Course opening: welcome, the 12 modules over 6.5 days, daily schedule, assessment (Program Facts), the lab VMs for the week
- From HOSTS.TXT to the DNS: RFC 608, 952; RFC 882/883; RFC 1034/1035 design goals; a sourced timeline (RFC 920, 1591, 3596; ICANN 1998; root signed 15 July 2010; IANA stewardship transition 1 October 2016; RFC 9499); other naming systems
- The namespace: labels and size limits, FQDNs and the trailing dot, search lists; TLD types with IANA counts (as of 22 October 2026: 1,437 TLDs, 1,127 generic, 309 country code, 1 special use, 151 IDN); IDNA2008 A-labels; special-use names (RFC 6761 and others); domains vs zones; delegation and glue (RFC 9471; in-domain, sibling, unrelated)
- Records, servers and caching: RR format and RRsets; A, AAAA, NS, SOA, CNAME as a preview (Module 2 owns the details); server roles; TTL and caching at concept level; the stub resolver on Debian 13
- Resolution: walk-through, recursive vs iterative queries, referrals, walking the tree by hand, `dig +trace` and its limits, the root server system (13 names, 12 operators, anycast instances as of a date), root hints and priming (RFC 9609; current IANA root hints), what a resolver caches
- The DNS message: sections, header flags, RCODEs, NODATA, Extended DNS Errors (pointer), reading `dig` output, UDP/TCP/EDNS(0) and truncation (RFC 1035, 6891, 7766, 9210), IPv6 (AAAA, ip6.arpa, root service over IPv6)
- Who runs the DNS: ICANN and IANA/PTI, root zone change process (Root Zone Administrator and Maintainer, RSSAC037), root server operators and RSSAC, registries/registrars/resellers/registrants (Module 9 terms), RIRs and reverse DNS
- Tools and a debugging method: `dig` options, `host`, `nslookup`, a seven-step method, delegation faults and their evidence (RFC 9499: "lame delegation" is historic), a worked example on the participant's own not-yet-served zone
- Pointers, not content: Module 2 (record types, zone files, TTL strategy), 3 (server types), 4 (software), 6 (security, QNAME minimisation, cookies), 7 (DNSSEC, AD/CD/DO), 8 (encrypted transports), 9 (registry operations, EPP)

### Practical Lab
- Lab 1.1 Walk the hierarchy (30 min): real root, TLD and authoritative servers; `dig +trace`; TLD types; anycast instances; offline path on the lab hierarchy
- Lab 1.2 Read the response (30 min): flags, RCODEs, NODATA, sections, truncation and TCP, read back from a `tcpdump` capture with `tshark`
- Lab 1.3 Debug a delegation (30 min): five lab zones, one fault each (zone names configurable by the instructor); worksheet assessed as Practical Assessment 1A task 2

---

## Module 2: DNS Operations - Zones, Records, and Data Management
**Duration:** 90 minutes theory + 90 minutes practical
**Deck:** `modules/module02-dns-operations.marp.md` (58 slides: 52 theory, 6 lab). Theory content takes 75 minutes; Knowledge Check 1 (Day 1 quiz, Modules 1-2) takes the last 15 minutes of the session (Program Facts). Lab kit: `labs/module02/`; lab servers: the instructor stack's `m01` profile, kept on all of Day 1.

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall the record types an organisation needs (A, AAAA, CNAME, MX, TXT, SRV, CAA, HTTPS/SVCB, PTR, NS, SOA), their purpose and their defining RFCs
- Identify the parts of a zone file: directives (`$TTL`, `$ORIGIN`, `$INCLUDE`, BIND's `$GENERATE`), owner, TTL, class, type, data; absolute and relative names
- List the SOA fields (MNAME, RNAME, SERIAL, REFRESH, RETRY, EXPIRE, MINIMUM) and what each controls

**Comprehension (Understand):**
- Explain a zone as data served by a primary and copied by secondaries (serial, REFRESH/RETRY/EXPIRE, NOTIFY, AXFR, IXFR) and the parent and child sides of a delegation
- Describe the rules for CNAME (no other data, not at the apex), MX/NS/SRV targets, TXT strings and underscored names
- Interpret `named-checkzone` messages and `dig` answers from a primary (`aa`) and through a resolver (TTL counting down, negative caching)

**Application (Apply):**
- Write `teamNN.example` from a template and load it into BIND 9.20 on Debian 13 (`named.conf.local`, `named-checkconf -z`, `rndc reload`)
- Configure forward and reverse zones for IPv4 and IPv6, and the email records MX, SPF, DKIM (key generated with `openssl`) and DMARC (RFC 9989)
- Set TTLs for a planned change and observe them in a shared resolver's cache

**Analysis (Analyse):**
- Find and fix errors in a zone file with `named-checkzone` (including `-k fail`) and `named-compilezone`
- Evaluate TTL choices: resolver limits, negative TTL, parent-side delegation TTLs

**Synthesis (Create):**
- Design a zone structure for an organisation (where to delegate, reverse zones, naming by function)
- Develop a zone change procedure (version control, serial scheme, checks, reload, verification)

### Theory Content
- Day 1 so far (Module 1's worked example: `teamNN.example` delegated, nothing answering) and what changed recently: DMARC RFC 9989-9991 (May 2026), SPF TXT only (RFC 7208), CAA RFC 8659, HTTPS/SVCB (RFC 9460), DKIM RFC 8301/8463, RFC 9499 terms, Debian 13's `bind9` without example zone files
- Zones as data: apex, SOA and NS, primary and secondaries (RFC 9499; RFC 1034 §4.1 two servers); parent and child sides of a delegation; delegating part of a zone (glue, occluded names, BIND's missing-glue warning)
- Zone file syntax (RFC 1035 §5.1): entries, blank owners, `@`, quoting; absolute and relative names and the missing-dot mistake; directives (RFC 2308 §4 `$TTL`; `$GENERATE` from the BIND 9.20 ARM); the lab zone in full; `named-checkzone`, `named-checkconf -z`, `named-compilezone`, `-k fail`, `-l`; a table of BIND 9.20.30 error messages (tested)
- SOA, serials and loading: SOA fields (RFC 1035 §3.3.13, RFC 2308 §4, RFC 1912 §2.2, RFC 2142); serial arithmetic and schemes (RFC 1982, RFC 1912 §2.2 and §3.1), BIND's unchanged-serial warning; secondaries, NOTIFY, IXFR, AXFR (RFC 1034 §4.3.5, 1995, 1996, 5936), BIND 9.20 defaults (`notify yes`, `allow-transfer` none); loading on Debian 13 (`named.conf.local`, `rndc reload`, AppArmor layout, default recursion to the local subnet)
- Record types: IANA codes (registry updated 16 October 2026); A/AAAA and host names (RFC 1034 §3.5, check-names); CNAME rules (RFC 1034 §3.6.2, RFC 2181 §10); the apex problem: vendor ALIAS/ANAME vs HTTPS/SVCB AliasMode (RFC 9460); MX, implicit MX, null MX (RFC 5321 §5.1, RFC 7505); TXT strings and underscored names (RFC 8552); SRV (RFC 2782, 6186, 6335); CAA (RFC 8659); wildcards, DNAME, unknown types, SPF type 99 (RFC 4592, 6672, 3597, 7208 §14.1); real examples dated 27 October 2026
- Email records: how mail uses the zone; SPF (RFC 7208: TXT only, one record, 10-lookup limit); DKIM (RFC 6376 STD 76, RFC 8301, RFC 8463; key generation and splitting a 392-character key into strings); DMARC (RFC 9989: `p`, `sp`, `np` from RFC 9091, `t` and `psd` new, `rua` RFC 9990, `ruf` RFC 9991, `pct`, `rf`, `ri` removed, DNS Tree Walk; start with `p=none`)
- Reverse DNS: in-addr.arpa and ip6.arpa (RFC 3596 §2.5), who delegates, PTR matching (RFC 1912 §2.1, RFC 8501 §4); classless delegation (RFC 2317, BCP 20) with `$GENERATE`; IPv6 nibble boundaries and RFC 8501's options; the lab's reverse zones
- TTL strategy and zone management: the trade-off (RFC 1034 §2.2), resolver limits (BIND 1 week / 3 hours; Unbound 1 day / 1 hour), negative TTL (RFC 2308 §5), parent-side TTLs, serve-stale (RFC 8767); planning a change (RFC 1912 §2.2); designing zone structure (RFC 1034 §4.2) and naming; a zone change procedure
- Pointers, not content: server types, secondaries and resolvers (Module 3), BIND in depth and other software (4), hidden primaries and anycast (5), TSIG and hardening (6), DNSSEC (7), transfers over TLS and DDR (8), registration over EPP (9), monitoring (11)

### Practical Lab
- Lab 2.1 Write and load your zone (30 min): `teamNN.example` from the kit template, every record type, `named-checkzone`, loaded into BIND on VM 1; Module 1's SERVFAIL becomes an answer through the lab resolver
- Lab 2.2 Reverse zones and a broken file (25 min): `2.0.192.in-addr.arpa` and the team's `ip6.arpa` zone; seven mistakes in `broken/db.broken.example`
- Lab 2.3 TTLs and caching (20 min): TTL countdown, a change waiting for the TTL, a planned change, negative caching, the unchanged-serial warning, `named-checkzone -l 60`
- Lab 2.4 Email records (15 min): SPF, null MX, DKIM (key made with `openssl`, split into strings, read back with `cmp`), DMARC

---

## Module 3: DNS Server Types - Recursive, Authoritative, and Specialised Roles
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall the different types of DNS servers and their functions
- Identify the components of DNS infrastructure architecture
- List DNS server deployment patterns

**Comprehension (Understand):**
- Explain the difference between recursive and authoritative name servers
- Describe DNS caching mechanisms and cache hierarchies
- Compare different DNS server architectures

**Application (Apply):**
- Configure basic recursive and authoritative servers
- Implement DNS forwarding and conditional forwarding
- Set up DNS server redundancy and load balancing

**Analysis (Analyse):**
- Analyse DNS query flows in complex infrastructures
- Evaluate DNS server placement strategies

**Evaluation (Evaluate):**
- Assess DNS infrastructure requirements for different organisations
- Compare architectural approaches for scalability and reliability

### Theory Content
- DNS server types and roles:
  - Recursive resolvers (full resolvers, caching servers)
  - Authoritative name servers (primary, secondary)
  - Forwarders and conditional forwarders
  - Root name servers and TLD servers
- DNS server architectures:
  - Split-brain/split-horizon DNS
  - Hidden primary configurations
  - Anycast deployment patterns
  - Cloud-based DNS services
- DNS caching strategies and cache poisoning prevention
- DNS server security considerations
- Performance and scalability planning

### Practical Lab
- Set up authoritative name servers (primary and secondary)
- Configure recursive resolvers with forwarding
- Implement split-horizon DNS configurations
- Test DNS failover and redundancy mechanisms
- Monitor DNS server performance and query patterns
- Troubleshoot common DNS server issues

---

## Module 4: DNS Software Platforms - BIND, Unbound, PowerDNS, and Alternatives
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall the major DNS software platforms and their characteristics
- Identify configuration file formats for different DNS software
- List the strengths and use cases for each platform

**Comprehension (Understand):**
- Explain the architectural differences between DNS software platforms
- Describe the configuration approaches for each major platform
- Compare performance and feature capabilities

**Application (Apply):**
- Install and configure BIND for both authoritative and recursive roles
- Set up Unbound as a high-performance recursive resolver
- Deploy PowerDNS with database backends

**Analysis (Analyse):**
- Analyse configuration requirements for different use cases
- Compare software platforms for specific deployment scenarios

**Evaluation (Evaluate):**
- Evaluate DNS software selection criteria for different environments
- Assess migration strategies between DNS platforms

**Synthesis (Create):**
- Design DNS software deployment strategies
- Develop standardised configuration templates

### Theory Content
- **BIND (Berkeley Internet Name Domain):**
  - History and market position
  - Authoritative and recursive capabilities
  - Configuration file structure (named.conf, zone files)
  - Advanced features (views, DNSSEC, statistics)

- **Unbound:**
  - High-performance recursive resolver design
  - Security-focused architecture
  - Configuration methodology
  - Integration with system resolvers

- **PowerDNS:**
  - Authoritative and recursive products
  - Database backend capabilities (MySQL, PostgreSQL, etc.)
  - API-driven management
  - Performance characteristics

- **Alternative Solutions:**
  - NSD (Name Server Daemon)
  - Knot DNS and Knot Resolver
  - Microsoft DNS Server
  - Cloud DNS services (Route 53, CloudDNS, etc.)

- **Selection Criteria:**
  - Performance requirements
  - Management complexity
  - Security features
  - Integration capabilities

### Practical Lab
- **BIND Workshop:**
  - Install and configure BIND as authoritative server
  - Set up BIND as recursive resolver
  - Configure BIND views for split-horizon
  - Implement zone transfers and TSIG authentication

- **Unbound Workshop:**
  - Install and configure Unbound
  - Set up local zones and forwarding
  - Configure DNS-over-TLS support
  - Performance tuning and optimisation

- **PowerDNS Workshop:**
  - Install PowerDNS Authoritative with MySQL backend
  - Configure PowerDNS Recursor
  - Use PowerDNS API for zone management
  - Set up web-based administration

- **Comparative Analysis:**
  - Performance benchmarking between platforms
  - Configuration migration exercises
  - Feature comparison in real scenarios

---

## Module 5: Advanced DNS Operations and Architecture
**Duration:** 90 minutes theory + 90 minutes practical
**Prerequisites:** Completion of Modules 1-4 or equivalent experience

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall advanced DNS concepts including delegation models, anycast routing, and hidden primarys
- Identify different DNS server architectures and their use cases

**Comprehension (Understand):**
- Explain the relationship between authoritative and recursive resolvers in complex networks
- Describe DNS caching mechanisms and TTL strategies

**Application (Apply):**
- Configure BIND/NSD for advanced scenarios including split-horizon DNS
- Implement DNS load balancing and failover mechanisms

**Analysis (Analyse):**
- Troubleshoot complex DNS resolution issues using dig, nslookup, and specialised tools
- Analyse DNS query patterns and performance metrics

### Theory Content
- Advanced DNS architecture patterns (hidden primarys, anycast, GeoDNS)
- DNS caching strategies and optimisation
- Split-horizon DNS implementations
- DNS load balancing techniques
- Advanced debugging methodologies

### Practical Lab
- Configure a multi-tier DNS architecture
- Implement split-horizon DNS
- Performance tuning exercises
- Advanced troubleshooting scenarios

---

## Module 6: DNS Security Fundamentals and Threat Landscape
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- List the classes of attack on the DNS (forged data, hijacking, denial of service, abuse as a channel, data exposure) and where each one lands
- Recall the defences and their standards: RFC 5452 randomisation, DNS Cookies (RFC 7873, 9018), QNAME minimisation (RFC 9156), TSIG (RFC 8945), BCP 38 and BCP 140, and the status of RPZ (an expired Internet-Draft)

**Comprehension (Understand):**
- Explain cache poisoning and the Kaminsky attack, and why port and ID randomisation, cookies and DNSSEC validation each help
- Explain reflection and amplification, open resolvers and random-subdomain floods, and how response rate limiting treats legitimate and spoofed clients

**Application (Apply):**
- Configure BIND 9.20 access controls (`allow-query`, `allow-query-cache`, `allow-recursion`, `allow-transfer`) and response rate limiting, and measure their effect
- Observe QNAME minimisation, DNS Cookies and port and ID randomisation in captures and logs
- Implement TSIG-authenticated zone transfers with keys made by `tsig-keygen`
- Configure a Response Policy Zone fed by zone transfer, with a local override zone

**Evaluation (Evaluate):**
- Assess a server's exposure from its configuration, logs and statistics
- Identify the signs of tunnelling and random-subdomain floods in a capture and choose a response

### Theory Content
- Threat landscape: RFC 3833; attack classes; where attacks land; dated history from primary sources only (CVE-2008-1447 and CERT/CC VU#800113; CISA ED 19-01; CVE-2020-8616 NXNSAttack; CVE-2020-25705 SAD DNS; CVE-2023-50387 KeyTrap, CVE-2023-50868)
- Cache poisoning: RFC 5452 matching rules and arithmetic; the Kaminsky attack; source-port and ID randomisation; 0x20 (expired draft); TCP; DNSSEC as the data check (Module 7); SAD DNS
- Hijacking at the registrar or registry (registry lock, Module 9), the server, BGP (RFC 6811) and the stub; CISA ED 19-01 actions
- Reflection and amplification (RFC 5358, BCP 38/84, RFC 8482 `minimal-any`); open resolvers and BIND 9.20 ACL defaults (localnets; `allow-recursion` inherits `allow-query`; `allow-transfer` none since BIND 9.20)
- Response rate limiting (BIND `rate-limit`: slip, cookies, log-only); query floods, random-subdomain attacks and NXNSAttack; resolver fetch limits; response size (1232, RFC 9715, TCP per RFC 7766)
- Authoritative and recursive hardening checklists; resolver hardening without encryption: QNAME minimisation (RFC 9156, obsoletes 7816) and DNS Cookies (RFC 7873, updated by 9018); Module 8 points here
- TSIG (RFC 8945, STD 93): algorithms, fudge, key handling with `tsig-keygen`, failures; XoT pointer to Module 8
- RPZ (draft-vixie-dnsop-dns-rpz-00, expired; BIND `response-policy`, Unbound `rpz:`): triggers, actions, order, EDE 17; DNS tunnelling and covert channels: signs and responses; BIND logging categories, `rndc stats`, dnstap; monitoring is Module 11
- DoT, DoH and DoQ are Module 8; DNSSEC is Module 7 (pointers only)

### Practical Lab
- Close the open doors: Debian defaults seen from a neighbouring team, then ACLs, `recursion no`, `version none` (Lab 6.1)
- Watch the resolver defend itself: source ports, IDs, QNAME minimisation and cookies in a capture and the query log (Lab 6.2)
- Rate limiting under load: measured amplification, RRL in log-only and enforcing mode with a capped `dnsperf` load against the team's own server (Lab 6.3)
- TSIG-protected zone transfer and its failure modes (Lab 6.4)
- RPZ with an instructor feed and a local zone; spotting a tunnel-like pattern in a capture (Lab 6.5)

---

## Module 7: DNSSEC Implementation and Operations
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall DNSSEC key types (KSK, ZSK, CSK) and their purposes
- Identify DNSSEC resource record types (DNSKEY, RRSIG, DS, NSEC, NSEC3, NSEC3PARAM, CDS, CDNSKEY)

**Comprehension (Understand):**
- Explain the DNSSEC validation process, the chain of trust and the four validation outcomes
- Describe key rollover methods and why their timing depends on TTLs and propagation delays

**Application (Apply):**
- Choose signing and DS digest algorithms from the IANA registry (RFC 9904) and NSEC3 settings per RFC 9276
- Sign DNS zones manually and with BIND `dnssec-policy`
- Configure recursive resolvers (BIND, Unbound) for DNSSEC validation and diagnose failures

**Synthesis (Create):**
- Develop DNSSEC key management policies (RFC 6841 practice statement)
- Design DNSSEC deployment strategies for complex organisations

### Theory Content
- DNSSEC cryptographic foundations, record types and the chain of trust
- Trust anchors and the root KSK rollover (KSK-2024 signing since 11 October 2026; KSK-2017 revoked 11 January 2027, removed 22 March 2027)
- Algorithm selection from the IANA registry (RFC 9904, RFC 9905); DS digest types
- NSEC and NSEC3 (RFC 9276: iterations 0, empty salt); compact denial (RFC 9824)
- KSK, ZSK and CSK management; key protection (HSM, offline KSK)
- Key rollover methods (pre-publish, double-KSK, double-DS) and timing (RFC 7583); emergency and algorithm rollovers
- Automated signing with `dnssec-policy` (KASP); `auto-dnssec` was removed in BIND 9.20; migrating signed zones without an unplanned rollover
- DS automation with CDS/CDNSKEY (RFC 7344, 8078, 9615, 9975); multi-signer (RFC 8901)
- Validation troubleshooting: Extended DNS Errors (RFC 8914), `delv`, negative trust anchors (RFC 7646)
- DNSSEC policy framework development

### Practical Lab
- Manual zone signing with BIND's `dnssec-keygen` and `dnssec-signzone`
- Automated signing with `dnssec-policy`, including DS submission from CDS
- Configure DNSSEC validation on recursive resolvers and troubleshoot broken zones
- Perform ZSK and KSK rollovers, including the DS change at the parent

---

## Module 8: DNS Privacy and Encryption Technologies
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall what a DNS query reveals and to whom, and the IETF protocols that protect it (DoT RFC 7858/8310, DoH RFC 8484, DoQ RFC 9250, padding RFC 7830/8467, DDR RFC 9462, DNR RFC 9463, ODoH RFC 9230) with their status
- Identify what encryption leaves visible (resolver address, SNI, sizes and timing, the resolver operator)

**Comprehension (Understand):**
- Explain the strict and opportunistic usage profiles (RFC 8310) and how a client authenticates an encrypted resolver
- Compare DoT, DoH and DoQ (transport, port, ALPN, visibility, head-of-line blocking, software support)

**Application (Apply):**
- Configure DNS over TLS (port 853) and DNS over HTTPS (port 443, `application/dns-message`) on a BIND 9.20 resolver with a team certificate, and test them with `dig` and `kdig`
- Configure Unbound to forward every query over TLS with a verified name
- Publish DDR records (`_dns.resolver.arpa` SVCB) and check the certificate for verified discovery

**Analysis (Analyse):**
- Analyse packet captures to show what DoT hides and what it does not, and measure the effect of padding
- Evaluate deployment choices for an ISP, enterprise or ccTLD: protocols, discovery (DDR, DNR), certificates, logging and the Recursive operator Privacy Statement (RFC 8932)

### Theory Content
- DNS privacy landscape and threats (RFC 9076, which obsoletes RFC 7626); who sees each hop; EDNS Client Subnet (RFC 7871); QNAME minimisation and DNS Cookies are covered in Module 6
- DNS over TLS: RFC 7858 and the RFC 8310 profiles; certificates and service identity (RFC 9525); BIND 9.20 and Unbound 1.26 configuration; testing and failures; connection management (RFC 7766, 9210, 7828)
- DNS over HTTPS: RFC 8484 (wire format only, `application/dns-message`; JSON APIs are vendor-specific); HTTP caching and cookies; deployment behind proxies and load balancers
- DNS over QUIC (RFC 9250) and Debian 13 support; DoT, DoH and DoQ compared
- Resolver discovery: SVCB for DNS servers (RFC 9460, 9461), DDR (RFC 9462), DNR (RFC 9463); client behaviour only from dated vendor sources; enterprise and ISP policy (split horizon, RFC 9704)
- Padding (RFC 7830, 8467); resolver-to-authoritative encryption (RFC 9539, Experimental); zone transfers over TLS (RFC 9103); Oblivious DoH (RFC 9230, Experimental); DNSCrypt (not an IETF standard); Encrypted ClientHello (RFC 9849) and TLS 1.3 (RFC 9846, 9852)
- Operator policy: RFC 8932 (BCP 232), the Recursive operator Privacy Statement, log retention and local law

### Practical Lab
- See plaintext DNS on the wire, including the resolver's own queries (Lab 8.1)
- Add DoT and DoH to the Module 7 BIND resolver with a team certificate; test strict, failing and opportunistic connections (Lab 8.2)
- Forward a client's queries over TLS with Unbound (Lab 8.3)
- Publish DDR records and verify the certificate's IP address (Lab 8.4)
- Measure padded and unpadded message sizes on the wire (Lab 8.5)

---

## Module 9: Registry Operations and EPP Protocol
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall the roles in the registration chain (registry, registrar, reseller, registrant, DNS operator), the EPP object types and the EPP result code classes
- Identify the EPP standards (RFC 5730-5734, 5910, 3915, 9154) and the extensions listed in the IANA EPP extensions registry

**Comprehension (Understand):**
- Explain the domain lifecycle, the grace periods (RFC 3915) and the client and server status codes
- Describe an EPP session over TLS with mutual authentication: framing, greeting, login, commands and the poll queue (RFC 5730, 5734)

**Application (Apply):**
- Execute EPP commands to create contacts, hosts (with glue) and domains, update name servers, renew, transfer and restore
- Submit a DS record through the EPP DNSSEC extension (RFC 5910) and explain how a registry processes CDS/CDNSKEY (RFC 7344, 8078, 9615, 9975)
- Apply secure transfer codes (RFC 9154)

**Analysis (Analyse):**
- Analyse EPP responses and transaction data to find why a command failed
- Evaluate registry service levels and monitoring against the gTLD Registry Agreement (Specification 10)

### Theory Content
- Registry-registrar model; gTLD (ICANN Registry Agreement, RAA) and ccTLD governance; thick and thin registries; registry services
- Domain lifecycle, grace periods and redemption (RFC 3915; .com contract values; ICANN ERRP and AGP Limits Policy); client and server status codes, registry lock
- EPP architecture and standards map (RFC 5730-5734, 5910, 3915, 8334, 8748, 9154, 8807, 3735, 7451, 9874); TLS transport (RFC 8996); sessions, commands, result codes, poll queue
- Contact, host and domain objects: check, create, info, update, renew, delete; glue and external hosts (RFC 5732); safe deletion of hosts (RFC 9874)
- Transfers: authInfo, secure transfer codes (RFC 9154); ICANN Transfer Policy in force (21 February 2024 version) and the revised policy adopted 7 June 2026 (TAC, 720-hour locks; implementation date not yet set)
- DNSSEC at the registry: DS via EPP `secDNS-1.1` (RFC 5910; DS Data vs Key Data and why DS Data is usual); registry checks on DS records; CDS/CDNSKEY from the parent side (RFC 7344, 8078, 9615, 9975)
- Extensions (launch phases RFC 8334, fees RFC 8748, allocation tokens RFC 8495, login security RFC 8807, maintenance RFC 9167, TTL RFC 9803); registration data: RDAP replaced WHOIS for gTLDs on 28 January 2025
- Registry operations: Spec 10 service levels, EPP monitoring and protection, escrow (RFC 8909, 9022), billing; registry software (FRED, Nomulus, Namingo; CoCCA in Module 10)

### Practical Lab
- Connect to the lab registry over TLS with a client certificate and log in (Lab 9.1)
- Create contacts, hosts with glue and domains; update name servers (Lab 9.2)
- Publish the Module 7 DS through EPP `secDNS` (Lab 9.3)
- Transfer a partner team's domain with a secure transfer code, then renew it (Lab 9.4)
- Delete inside the add grace period, and delete and restore through the redemption period (Lab 9.5)

---

## Module 10: Advanced Registry Systems - CoCCA Backend Operations
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall CoCCA architecture components and data models
- Identify CoCCA administrative functions and interfaces

**Comprehension (Understand):**
- Explain CoCCA's role in ccTLD management
- Describe CoCCA integration with registrar systems

**Application (Apply):**
- Navigate CoCCA administrative interfaces
- Configure CoCCA policy settings and business rules

**Synthesis (Create):**
- Design CoCCA deployment strategies for new TLDs
- Develop operational procedures for CoCCA-based registries

### Theory Content
- CoCCA platform overview and architecture
- ccTLD management best practices
- CoCCA database schema and data relationships
- Integration with WHMCS and other registrar platforms
- Billing and financial management in CoCCA

### Practical Lab
- CoCCA installation and configuration
- Registry policy configuration
- WHMCS-CoCCA integration setup
- Registrar management and onboarding
- Operational monitoring and maintenance procedures

---

## Module 11: DNS Monitoring, Incident Response, and Performance Optimisation
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall DNS monitoring metrics and KPIs
- Identify incident response procedures for DNS outages

**Application (Apply):**
- Implement DNS monitoring solutions
- Execute incident response procedures

**Analysis (Analyse):**
- Analyse DNS performance data and identify optimisation opportunities
- Evaluate the effectiveness of monitoring and alerting systems

**Evaluation (Evaluate):**
- Assess DNS infrastructure resilience and redundancy
- Evaluate business continuity planning for DNS services

### Theory Content
- DNS monitoring strategy and metrics, including SOA serial agreement across a zone's servers and the parent's delegation (NS, glue, DS) against the zone (pointed to from Module 2)
- Performance optimisation techniques
- Incident response planning and procedures
- Capacity planning for DNS infrastructure
- Business continuity and disaster recovery

### Practical Lab
- Deploy DNS monitoring with tools like RIPE Atlas, ThousandEyes
- Configure alerting and notification systems
- Conduct tabletop incident response exercises
- Performance optimisation workshops
- Disaster recovery testing scenarios

---

## Module 12: Emerging Technologies and Future Considerations
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall emerging DNS technologies and protocols
- Identify trends in DNS infrastructure evolution

**Comprehension (Understand):**
- Explain the implications of new DNS technologies
- Describe integration challenges with legacy systems

**Evaluation (Evaluate):**
- Evaluate the business case for adopting new DNS technologies
- Assess the security and operational implications of emerging protocols

**Synthesis (Create):**
- Develop migration strategies for new DNS technologies
- Design DNS architectures that can adopt new protocols

### Theory Content
- DNS-over-QUIC (DoQ, RFC 9250) deployment and HTTP/3 implications
- Encrypted Client Hello (ECH) and the HTTPS/SVCB record (RFC 9460)
- DNS filtering and abuse mitigation technologies
- IPv6-only DNS operations
- AI/ML applications in DNS operations

### Practical Lab
- DoQ (RFC 9250) with current implementations (e.g. dnsdist, AdGuard Home)
- IPv6-only DNS testing
- DNS abuse detection and mitigation tools
- Next-generation DNS server evaluation
- Future technology proof-of-concept development

---

## Assessment and Certification
- **Daily Assessment:** Practical lab completion and competency demonstration
- **Mid-course Check:** Day 3 practical assessment covering fundamentals
- **Final Project:** Day 7 morning, in teams - Design and implement a complete DNS infrastructure solution
- **Peer Review:** Team presentations of implemented solutions to the group
- **Written Examination:** Test covering all modules (optional certification track)

## Required Equipment and Environment
- **Laptops:** WiFi-capable with SSH client support (tablets not suitable)
- **Lab Network:** Isolated network environment for hands-on exercises
- **Virtual Machines:** Pre-configured with BIND, Unbound, PowerDNS, and other DNS software
- **Certificates:** Course completion certificates provided
- **Internet Access:** Required for accessing external DNS resources and documentation

## Workshop Logistics
- **Duration:** 6 full days plus a Day 7 morning (see Program Facts)
- **Class Size:** Maximum 20 participants for effective hands-on instruction
- **Equipment:** Participants must bring laptops capable of running SSH clients
- **Materials:** All lab exercises, documentation, and software provided
- **Language:** Conducted in English with materials available for translation

## Identified Gaps and Recommendations

### Gaps in Current Training Landscape
1. **Limited Integration Training:** Few programs combine registry operations (EPP/CoCCA) with DNS security
2. **Privacy Protocol Coverage:** DoT/DoH training often missing from traditional DNS curricula
3. **Operational Focus:** More emphasis needed on day-to-day operations vs. initial deployment
4. **Incident Response:** Limited practical incident response training in DNS context
5. **Modern Threats:** Insufficient coverage of current DNS abuse and attack patterns

### Recommendations
1. **Expand Hands-on Components:** Keep labs at half of each module's time
2. **Include Real-world Scenarios:** Base exercises on actual operational challenges
3. **Add Vendor Diversity:** Include multiple DNS software platforms beyond BIND
4. **Enhance Security Focus:** Integrate security considerations throughout all modules
5. **Regular Updates:** Curriculum should be updated annually to reflect emerging threats and technologies

## Instructor Qualifications
- Minimum 5 years DNS operations experience
- DNSSEC deployment and operational experience
- Registry or registrar operational background
- Current knowledge of DNS security threats and mitigation
- Teaching or training experience preferred

## Continuing Education
- **Annual Refresher Sessions:** 1-day updates on new threats and technologies
- **Advanced Workshops:** Specialised sessions on specific topics
- **Community Engagement:** Participation in DNS-OARC, ICANN meetings
- **Online Resources:** Access to updated materials and virtual labs

---

*The course design is informed by the training work of ICANN Technical Engagement, APNIC Academy and NSRC.*

---

# Appendix A: Laboratory Requirements and Specifications

## Lab Infrastructure Overview

### Network Environment
- **Isolated Lab Network:** 192.168.100.0/24 (recommended)
- **Internet Gateway:** Limited access for external DNS queries and updates
- **VLAN Segmentation:** Separate lab segments for different exercises
- **Virtual Machine Host:** VMware vSphere, VirtualBox, or KVM-based infrastructure
- **Lab Reset Capability:** Snapshots for quick environment restoration
- **Participant VMs for the week:** from Module 1 on, each participant (team `NN`) keeps two Debian 13 VMs: VM 1, the authoritative server for `teamNN.example` and the client (192.0.2.30 on the slides), and VM 2, the resolver (192.0.2.10). Modules 1, 2 and 6-9 use them; Module 2 installs BIND on VM 1 and loads `teamNN.example` there. The "Participant VMs" lines of Modules 3-5 below still give other counts and are to be reconciled when those decks are written

### Base Virtual Machine Requirements
- **Operating System:** Debian 13 "trixie" (Stable; BIND 9.20) or Debian 12 "bookworm" (LTS until 30 June 2028; BIND 9.18, or 9.20 from bookworm-backports)
- **RAM:** Minimum 2GB per VM, 4GB recommended
- **Storage:** 20GB minimum per VM
- **CPU:** 2 vCPU cores minimum
- **Network:** Bridged networking with lab network access

---

## Module 1: Introduction to DNS - Lab Requirements

All steps below were run on 2026-10-22: the lab-server steps from a Debian 13 stand-in VM (bind9-dnsutils and bind9-host 9.20.30, tcpdump 4.99.5, tshark 4.4.19) against the instructor stack (`labs/module01/test/rehearse.sh`, 39 of 39 checks; `labs/instructor/test/run.sh`, 56 of 56); the Internet steps on a Debian 13 host (bind9-dnsutils 9.20.29). Lab kit: `labs/module01/`.

### Lab Environment Setup
- **Participant VMs:** the two Debian 13 VMs each participant (team `NN`) keeps all week. On Day 1 only VM 1 is used (the future authoritative server for `teamNN.example`, 192.0.2.30 on the slides; the client in Modules 6-8). It has `bind9-dnsutils`, `bind9-host`, `tcpdump` and `tshark` and no DNS server. VM 2 (the resolver, 192.0.2.10) waits for Module 3
- **Instructor stack (`labs/instructor`, profile `m01`):** lab root 192.0.2.52 (`.` and `root-servers.test`), registry/lab TLD 192.0.2.53 (`example.`, as in Modules 6-9), lab child 192.0.2.54 (`good.example`, `charlie.example`, `delta.example`), lab resolver 192.0.2.55 (recursive for the lab subnet, root hints = lab root). This is the "root server simulator" and "TLD server simulator"
- **Broken delegations for Lab 1.3** (default labels; `M01_FAULT_LABELS` renames them, and a graded run uses names the class has not seen): `alpha.example` (server does not serve the zone: REFUSED), `bravo.example` (no server at 198.51.100.53), `charlie.example` (stale glue for ns2), `delta.example` (parent NS set differs from the zone's), `echo.example` (not delegated); the DNSSEC-broken zones are not used on Day 1
- **Captures:** `sudo tcpdump` on the VM, read with `tshark -r`; the Wireshark GUI only on a participant's laptop, with the copied file
- **Offline path:** if outbound port 53 is blocked, Lab 1.1 walks the lab hierarchy with `+norec` instead of the real one, without `dig +trace` (dig 9.20 resolves each server name through the VM's resolver and ignores glue); Labs 1.2 and 1.3 use only lab servers either way
- **Not tested:** real VMs (`sudo`, SSH, capture on a VM interface), the Wireshark GUI, ipvlan on a real classroom NIC, IPv6 transport inside the lab hierarchy

### Lab Exercises

#### Lab 1.1: Walk the Hierarchy (30 minutes)
**Objective:** Follow a lookup from the root to an authoritative answer
**Exercise Steps:**
1. `dig . NS` through the classroom resolver: server, flags, TTL
2. `dig -4 @a.root-servers.net . NS +norec`: compare flags (aa) and TTL
3. Walk `www.example.com` by hand with `+norec`, taking each next address from the glue
4. `dig -4 +trace www.example.com`, and a name in the participant's own ccTLD
5. Referrals for `org.`, a ccTLD, `xn--p1ai.` and `arpa.`
6. Root instances with `hostname.bind CH TXT` over IPv4 (and IPv6 where available)
**Offline:** steps 1-3 against 192.0.2.55, .52, .53, .54 for `www.good.example`; `com.` at the lab root (NXDOMAIN); AAAA and `dig -x` names
**Success Criteria:** each reply identified as referral or authoritative answer, with its sender

#### Lab 1.2: Read the Response (30 minutes)
**Objective:** Read flags, response codes and sections in `dig` and in a capture
**Exercise Steps:**
1. Start `sudo tcpdump -i any -n -U -w m01.pcap port 53` (wait a few seconds before stopping it)
2. Authoritative (`aa`) vs resolver (`ra`, TTL counting down) answers for `www.good.example`
3. NXDOMAIN (`nosuch.good.example`), NODATA (`www.good.example TXT`), REFUSED (`www.example.com` at 192.0.2.54), SERVFAIL (`www.teamNN.example` through the resolver: no server on VM 1 yet)
4. A CNAME answer and a referral (authority and additional sections)
5. Truncation at `+bufsize=512 +ignore`, the TCP retry, `+tcp`
6. Read the capture with `tshark -T fields` (flags as True/False, RCODE as a number); with Internet access, an IPv4 and an IPv6 query to a root server
**Success Criteria:** QR, AA, TC, RD, RA and the RCODE named for every reply; NXDOMAIN told from NODATA; TCP retry explained

#### Lab 1.3: Debug a Delegation (30 minutes)
**Objective:** Find the fault in five lab delegations with a written method
**Exercise Steps:**
1. Ask the lab resolver (status, time)
2. Ask the parent with `+norec`: NS names and glue
3. Ask each listed address with `+norec +tries=1 +timeout=2`
4. Compare the parent's NS and glue with the zone's own NS and addresses
5. Worksheet per zone: symptom, evidence, cause, who fixes it, how to check the fix
**Success Criteria:** one cause per zone with evidence (answer key, instructor only: `labs/instructor/module01/README.md`); the worksheet is Practical Assessment 1A task 2

---

## Module 2: DNS Operations - Lab Requirements

All steps below were run on 2026-10-27 from a Debian 13 stand-in VM 1 (bind9, bind9-utils and bind9-dnsutils 1:9.20.30-1~deb13u1, openssl 3.5.7) against the instructor stack with the `m01` profile (`labs/module02/test/rehearse.sh`, 54 checks; first run 2026-10-27, re-run 2026-10-28 after the review fixes). Lab kit: `labs/module02/`.

### Lab Environment Setup
- **Participant VMs:** the two Debian 13 VMs from Module 1. Module 2 uses VM 1 (192.0.2.30 on the slides): it gets `bind9`, `bind9-utils` and `openssl` and becomes the primary for `teamNN.example`, `2.0.192.in-addr.arpa` and the team's `ip6.arpa` zone (`2001:db8:NN::/48`). VM 2 (192.0.2.10) waits for Module 3
- **Packages offline:** the VM image carries the packages with `named` disabled (Module 1 relies on nothing answering on port 53); Lab 2.1 gives the VM its own rndc key and starts it: `sudo rndc-confgen -a -u bind; sudo systemctl enable --now named` (remove `/etc/bind/rndc.key` before sealing the image: Debian's postinst makes one at install time, which every clone would share). With a mirror, `sudo apt install bind9 bind9-utils openssl` in Lab 2.1 does the same
- **Configuration:** only `/etc/bind/named.conf.local`; zone files in `/var/lib/bind`, where Debian's AppArmor profile lets `named` write (Module 7 signs `teamNN.example` inline, which writes `.signed` and journal files next to the zone file; `/etc/bind` is read-only to `named`). Debian's `named.conf.options` stays as installed (Module 6 Lab 6.1 hardens it)
- **Instructor stack:** the `m01` profile stays on for all of Day 1: the registry (192.0.2.53) delegates `teamNN.example` to VM 1 (`teams.conf`), and the lab resolver (192.0.2.55) is the shared cache for Lab 2.3
- **Lab TTLs:** 60 seconds or less in every team zone, to match `max-zone-ttl 60` in the lab signing policy of Appendix A, Module 7; the zone keeps `www` 192.0.2.80, `mail` 192.0.2.81 and `ftp` 192.0.2.82 for Modules 6-8
- **Secrets:** the Lab 2.4 DKIM key is made by each participant in their home directory; nothing secret is in the kit
- **Not tested:** real VMs (`sudo`, `systemctl`, `journalctl`, AppArmor), `apt install` in class, ipvlan on a real classroom NIC, IPv6 transport

### Lab Exercises

#### Lab 2.1: Write and Load Your Zone (30 minutes)
**Objective:** Write `teamNN.example` from a template and serve it from VM 1
**Exercise Steps:**
1. Start BIND; `named -v`; `ls /etc/bind` (no zone files in Debian 13)
2. Copy `zones/db.teamNN.example` to `/var/lib/bind`, set the team number with `sed`, set `ns1`'s address
3. Add apex A, AAAA, `HTTPS 0 www`, `MX 10 mail`, CAA `issue` and `iodef`; `www` A, AAAA, HTTPS; `web` CNAME; `mail` A, AAAA; `ftp` A; `_imaps._tcp` SRV
4. `named-checkzone` until OK with no warnings; read the zone with `named-compilezone -o -`
5. Add the zone statement to `named.conf.local`; `named-checkconf -z`; `rndc reload`; `rndc zonestatus`
6. Query VM 1 with `+norec`, the lab resolver, and compare the registry's NS and glue with the zone
**Success Criteria:** `aa` (and `ra`, Debian's default) from VM 1; NOERROR from the lab resolver where Module 1 had SERVFAIL; parent and child agree (Practical Assessment 1B task 1)

#### Lab 2.2: Reverse Zones and a Broken File (25 minutes)
**Objective:** Serve IPv4 and IPv6 reverse zones; find errors in a zone file
**Exercise Steps:**
1. Copy `zones/db.192.0.2` and `zones/db.2001-db8-NN` to `/var/lib/bind`; add PTRs (owner names for IPv6 from `dig @192.0.2.55 -x ... +noall +question`)
2. Add both zone statements; check; reload
3. `dig -x` against VM 1; confirm each PTR target resolves back to the address; the lab resolver answers NXDOMAIN with `aa` from its own built-in empty zone for `2.0.192.in-addr.arpa` (RFC 6303 locally served zones): read its SOA
4. `broken/db.broken.example`: `named-checkzone` until OK, then `-k fail`, then `named-compilezone -o -` (seven mistakes: serial out of range, bad dotted quad, CNAME and other data, NS without address, MX target without its dot, `_` in a host name, owner without its dot)
**Success Criteria:** PTRs answer and match the forward data; the broken file passes `-k fail` with no warnings (Practical Assessment 1B tasks 2 and 4)

#### Lab 2.3: TTLs and Caching (20 minutes)
**Objective:** Observe TTLs and negative caching in a shared resolver
**Exercise Steps:**
1. Add `app`; compare TTLs from VM 1 (always 60) and the lab resolver (counting down)
2. Change `app`; time how long the resolver keeps the old address (`+norec` shows the cache)
3. Planned change: lower `app`'s TTL to 10, wait for the old copy to expire, change it
4. Negative caching: NXDOMAIN for `new`, add it, wait for the SOA's negative TTL
5. Reload without raising the serial; read BIND's warning in the journal
6. `named-checkzone -l 60` (Module 7's limit)
**Success Criteria:** each delay explained by the TTL that caused it (rehearsed: 53 s for a 60 s copy; 11 s after lowering to 10; 59 s negative); the serial warning explained for secondaries

#### Lab 2.4: Email Records (15 minutes)
**Objective:** Publish MX, SPF, DKIM and DMARC records
**Exercise Steps:**
1. SPF `v=spf1 mx -all` at the apex; null MX and `v=spf1 -all` for `ftp`
2. DKIM: `openssl genpkey` (RSA 2048) in the home directory; the 392-character public key split into strings with `fold -w 250`; try it as one string first (`syntax error`)
3. DMARC `v=DMARC1; p=none; rua=mailto:...` at `_dmarc`
4. Check (`-k fail -l 60`), reload, query VM 1 and the lab resolver; compare the published key with `cmp`
**Success Criteria:** all four answer from VM 1 and through the resolver; the key matches (Practical Assessment 1B task 3)

---

## Module 3: DNS Server Types - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Debian server VMs per participant
- **From Modules 2 and 6-7 (to reconcile when this deck is written):** VM 1 already serves `teamNN.example` as primary (Module 2). A secondary built here on VM 2 must be removed at the end of Module 3: Module 6 Lab 6.4 builds VM 2's TSIG secondary from scratch and removes it, because Module 7 needs VM 2 as a validating resolver. The registry delegates `teamNN.example` to one address per team (`teams.conf`); a second NS for VM 2 needs an instructor-stack change
- **Software:** BIND 9, systemd-resolved
- **Network:** Multi-segment lab network for testing

### Lab Exercises

#### Lab 3.1: Authoritative Server Setup (45 minutes)
**Objective:** Configure primary and secondary authoritative servers
**Resources Needed:**
- Pre-installed BIND 9
- Zone transfer configuration templates
- Monitoring scripts
**Exercise Steps:**
1. The primary on VM 1 exists from Module 2 (`teamNN.example` in `/var/lib/bind`); review it and allow transfers to VM 2
2. Set up the secondary on VM 2 with zone transfers
3. Test automatic zone synchronisation
4. Implement notify mechanisms

#### Lab 3.2: Recursive Resolver Configuration (30 minutes)
**Objective:** Set up and configure recursive DNS resolvers
**Resources Needed:**
- BIND 9 or Unbound
- Forwarder configuration examples
- Client test machines
**Exercise Steps:**
1. Configure basic recursive resolver
2. Implement DNS forwarding
3. Set up conditional forwarding
4. Test resolution from client machines

#### Lab 3.3: Split-Horizon DNS Implementation (15 minutes)
**Objective:** Configure different responses for internal/external clients
**Resources Needed:**
- BIND views configuration
- Internal and external network segments
- Test domains
**Exercise Steps:**
1. Configure BIND views for internal/external
2. Create different zone content for each view
3. Test resolution from different network segments
4. Verify proper view matching

---

## Module 4: DNS Software Platforms - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 3 Debian server VMs per participant
- **Software:** BIND 9, Unbound, PowerDNS Authoritative and Recursor
- **Databases:** MySQL/PostgreSQL for PowerDNS backend

### Lab Exercises

#### Lab 4.1: BIND Deep Dive (30 minutes)
**Objective:** Advanced BIND configuration and management
**Resources Needed:**
- BIND 9 with all modules
- RNDC configuration
- Statistics and logging configuration
**Exercise Steps:**
1. Configure BIND with views and ACLs
2. Set up RNDC for remote management
3. Enable query logging and statistics
4. Implement TSIG for secure communication

#### Lab 4.2: Unbound Configuration (30 minutes)
**Objective:** Configure high-performance recursive resolver
**Resources Needed:**
- Unbound software
- Local zone configuration files
- Performance testing tools
**Exercise Steps:**
1. Install and configure Unbound
2. Set up local zones and forwarding
3. Configure DNS-over-TLS support
4. Performance optimisation and tuning

#### Lab 4.3: PowerDNS with Database Backend (30 minutes)
**Objective:** Implement PowerDNS with MySQL backend
**Resources Needed:**
- PowerDNS Authoritative server
- MySQL database server
- PowerDNS API tools
- Web management interface
**Exercise Steps:**
1. Install PowerDNS with MySQL backend
2. Configure database schema and zones
3. Use PowerDNS API for zone management
4. Set up web-based administration interface

---

## Module 5: Advanced DNS Operations - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 4 Debian server VMs per participant
- **Network:** Complex multi-segment topology
- **Software:** BIND 9, NSD, monitoring tools

### Lab Exercises

#### Lab 5.1: Anycast DNS Implementation (45 minutes)
**Objective:** Configure anycast DNS for high availability
**Resources Needed:**
- Multiple server VMs with same IP addresses
- BGP simulation or static routing
- Health check monitoring
**Exercise Steps:**
1. Configure identical DNS servers with same anycast IP
2. Implement health checking and failover
3. Test automatic failover scenarios
4. Monitor query distribution

#### Lab 5.2: Hidden Primary Architecture (30 minutes)
**Objective:** Implement hidden primary DNS architecture
**Resources Needed:**
- Hidden primary server (not publicly accessible)
- Multiple public secondary servers
- Zone transfer automation
**Exercise Steps:**
1. Configure hidden primary server
2. Set up automated zone transfers to public secondaries
3. Implement security restrictions
4. Test update propagation

#### Lab 5.3: DNS Performance Optimisation (15 minutes)
**Objective:** Optimise DNS server performance
**Resources Needed:**
- Performance monitoring tools
- Load testing utilities
- Configuration optimisation guides
**Exercise Steps:**
1. Baseline DNS server performance
2. Implement caching optimisations
3. Tune server parameters for high load
4. Conduct performance testing and analysis

---

## Module 6: DNS Security Fundamentals - Lab Requirements

All steps below were run on 2026-10-21 with Debian 13 packages (bind9, bind9-utils, bind9-dnsutils 9.20.29 from trixie-security, dnsperf 2.14.0, tcpdump 4.99.5, tshark 4.4.19), inside an unprivileged user and network namespace with no route out (`labs/module06/test/rehearse.sh`). Re-run 2026-10-27 with bind9 9.20.30 (DSA-6576-1): same lab results. Lab kit: `labs/module06/`.

### Lab Environment Setup
- **Participant VMs:** the two Debian 13 VMs used again in Modules 7 and 8: the authoritative server for `teamNN.example` (also the client) and the BIND 9.20 resolver
- **Registry server (instructor):** serves `example.` (as in Module 7: delegations with glue for every team, signed with the `lab` policy) with four extra A records, and the RPZ feed zone `feed.rpz.test`, transferable from the lab subnet only (`labs/module06/instructor/`)
- **Packages:** `bind9`, `bind9-utils`, `bind9-dnsutils`, `dnsperf`, `tcpdump`, `tshark`
- **Containment:** all traffic stays on the isolated lab network; the only load is `dnsperf -Q 50 -l 10` from the team's resolver VM to its own authoritative VM; no spoofing, no poisoning tool
- **Set up here and kept for Module 7:** the resolver's `static-stub` zone for `example` (Module 7 Lab 7.3 step 2) and `validate-except { "example"; };`, which Module 7 Lab 7.3 step 1 deletes when it adds the `example.` trust anchor
- **Secrets:** each team makes its own TSIG key with `tsig-keygen` during Lab 6.4; nothing secret is in the kit
- **Not tested:** the `sudo`/`systemctl` steps and `journalctl` on real VMs; queries from real neighbouring or outside machines (emulated with a second address and a child namespace); the shipped `dnssec-validation auto` with `validate-except`, which was run only with Internet access (slirp4netns) while the harness uses `dnssec-validation no`; Debian 12. Configuration changes were rehearsed with `rndc reconfig`, as in class

### Lab Exercises

#### Lab 6.1: Close the Open Doors (20 minutes)
**Objective:** See what Debian's defaults expose, then restrict both VMs
**Exercise Steps:**
1. From a neighbouring team's VM: query the authoritative VM for its own zone (note `ra`), `version.bind TXT CH`, and an AXFR
2. Install `auth/named.conf.options` (recursion no, `allow-transfer { none; }`, `version none`, minimal responses, RRL in log-only mode) and the logging file; `named-checkconf`; `rndc reconfig`
3. Install the resolver's `named.conf.options` (`acl "trusted"`, ACLs, validation with `validate-except` for `example`) and `named.conf.local` (static-stub for `example`)
4. Repeat step 1 against both VMs; query the resolver from the team's own authoritative VM; read the "queries rejected" counters from `rndc stats`
**Success criteria:** the neighbour gets REFUSED for recursion on both VMs (EDE 20) and no version string; the team's own VM resolves through its resolver; zone transfers fail (BIND 9.20's default)

#### Lab 6.2: Watch the Resolver Defend Itself (15 minutes)
**Objective:** Observe the cache-poisoning defences on the wire
**Exercise Steps:**
1. `rndc flush`; capture `udp port 53` on the resolver while the client looks up three names
2. List the resolver's queries to the team's authoritative VM and the registry with `tshark` (destination, source port, ID, type, name, client and server cookie)
3. Turn on the query log on the authoritative VM, flush the resolver, repeat the lookups and read the `K` and `V` cookie flags
4. Read the COOKIE line in `dig` output; repeat with `+cookie=<value>`
**Success criteria:** a different source port and ID per query; only `teamNN.example NS` sent to the registry (QNAME minimisation); a different client cookie per server and the server cookie returned once learned

#### Lab 6.3: Rate Limiting Under Load (20 minutes)
**Objective:** Measure amplification and show RRL removing it
**Exercise Steps:**
1. Add the `big` TXT records (`auth/db.additions`); compare query and response sizes with `dig +qr`; ANY over UDP with `minimal-any`
2. `dnsperf -s <auth VM> -e -d big.txt -l 10 -Q 50` from the resolver VM with `log-only yes`, then with `log-only no`; read the `rate-limit` log and `rndc stats`
3. During a third run, `dig +nocookie +ignore` (truncated reply) and `dig` with cookies (BADCOOKIE, retry, full answer)
**Success criteria:** in the test lab, log-only answered 500/500 at 1077 octets on average; enforcing answered 205 of 405 (mostly small truncated replies, average 72 octets), "200 responses dropped / 200 truncated for rate limits"

#### Lab 6.4: TSIG-Protected Zone Transfer (20 minutes)
**Objective:** Authenticate zone transfers and NOTIFY with a team key
**Exercise Steps:**
1. `tsig-keygen -a hmac-sha256 teamNN-xfr` into `/etc/bind/teamNN-xfr.key` (root:bind, 640, created under `umask 077`); `allow-transfer { key "teamNN-xfr"; };` and `also-notify` with the key on the primary
2. Copy the key to the resolver VM over SSH (same owner and mode); there, **as root** (`sudo dig`, because `dig -k` on a key it cannot read sends the query unsigned), AXFR with no key, the right key, a wrong secret and an unknown key name
3. Make the resolver VM a TSIG secondary (`resolver/named.conf.secondary`); change the zone and watch NOTIFY and the transfer
4. Remove the secondary zone from the resolver (Module 7 needs the resolver to resolve, not serve, the zone)
**Success criteria:** "Transfer failed" without a key, BADSIG with a wrong secret, BADKEY with an unknown name, the full zone with the right key; the secondary logs "transferred serial <the team's new serial>: TSIG 'teamNN-xfr'" (serial 2 in the Module 6 rehearsal zone)

#### Lab 6.5: RPZ and Spotting a Tunnel (15 minutes)
**Objective:** Filter with a policy feed and recognise covert-channel traffic
**Exercise Steps:**
1. Before: resolve `malware.example`, `phish.example`, `tracker.example` and `c2.teamNN.example`
2. Add the feed secondary, the local policy zone and the `response-policy` block (local first, feed with `ede filtered`)
3. Repeat step 1, then `malware.example` with `+dnssec`; read the `rpz` log lines
4. Capture while sending 30 TXT queries for random base32 labels under `t.teamNN.example`; summarise with `tools/dns-signs.sh`
**Success criteria:** malware NXDOMAIN with EDE 17 (but its real address with `+dnssec`, because the signed `example.` is not rewritten for DO=1 queries), phish redirected to the walled garden, tracker allowed by the local PASSTHRU, c2 blocked by its address (rpz-ip); the summary shows 30 unique 32-character labels, all TXT and NXDOMAIN, under one parent

---

## Module 7: DNSSEC Implementation - Lab Requirements

All steps below were tested on BIND 9.20.29 and Unbound 1.26.1 (Debian 13 packages), and re-run on 2026-10-27 with BIND 9.20.30 and Unbound 1.26.2: same lab results.

### Lab Environment Setup
- **Participant VMs:** 2 Debian 13 VMs per participant: an authoritative server for `teamNN.example` and `manualNN.example`, and a validating resolver
- **Registry server (instructor):** hosts the signed `example.` zone, the lab's parent "TLD"; adds participants' DS records; also hosts two deliberately broken zones, `expired.example` (expired RRSIGs) and `wrongds.example` (DS matching no DNSKEY)
- **Software:** BIND 9.20 (bind9, bind9-utils, bind9-dnsutils); Unbound as an optional second resolver
- **Trust anchor:** `example.` has no DS in the real root, so each resolver gets `trust-anchors { example. static-ds ...; };` (the instructor hands out the DS) alongside `dnssec-validation auto;`
- **Lab policy:** short TTLs and delays so that rollovers take minutes:

```
dnssec-policy "lab" {
    keys {
        ksk lifetime unlimited algorithm ecdsap256sha256;
        zsk lifetime P30D algorithm ecdsap256sha256;
    };
    nsec3param iterations 0 optout no salt-length 0;
    dnskey-ttl 60;
    max-zone-ttl 60;
    publish-safety 30;
    retire-safety 30;
    zone-propagation-delay 30;
    parent-ds-ttl 60;
    parent-propagation-delay 30;
    signatures-validity PT30M;
    signatures-validity-dnskey PT30M;
    signatures-refresh PT25M;
    signatures-jitter PT1M;
};```

Lab zone files use `$TTL 60` to match `max-zone-ttl`. With this policy (measured): CDS/CDNSKEY appear about 2 minutes after first signing, a ZSK rollover completes in about 7 minutes, and a KSK rollover completes about 2 minutes after the DS swap is confirmed. The short signature validity is for the lab only: a stopped signer makes the zone bogus within 30 minutes.

### Lab Exercises

#### Lab 7.1: Sign a Zone by Hand (25 minutes)
**Objective:** Manually sign a DNS zone with DNSSEC
**Exercise Steps:**
1. Create the unsigned zone `manualNN.example`
2. Generate a KSK and a ZSK: `dnssec-keygen -a ECDSAP256SHA256 -f KSK manualNN.example`, then without `-f KSK`
3. Sign: `dnssec-signzone -S -3 - -H 0 -o manualNN.example db.manualNN.example`
4. Check with `dnssec-verify` and `named-checkzone`; load the `.signed` file
5. Query with `dig +dnssec +multi` and identify DNSKEY, RRSIG and NSEC3 records
6. Send `dsset-manualNN.example.` to the registry
**Success criteria:** "Zone fully signed" from `dnssec-verify`; the DS is published in `example.`

#### Lab 7.2: Sign with `dnssec-policy` (20 minutes)
**Objective:** Sign a zone automatically and submit its DS from CDS
**Exercise Steps:**
1. Add the `lab` policy and `dnssec-policy "lab";` to the `teamNN.example` zone
2. Add `parental-agents` pointing at the registry server (a `remote-servers` list)
3. Reload and read `rndc dnssec -status teamNN.example`
4. Wait for CDS/CDNSKEY (`dig teamNN.example CDS +short`)
5. The registry publishes a DS built from the CDS record
6. Tell `named` the DS is published: `rndc dnssec -checkds -key <KSK id> published teamNN.example` (with `parental-agents`, `named` otherwise re-checks only hourly)
**Success criteria:** the parent's DS matches the CDS; `named` logged `checkds DS for key ... seen published`; the KSK's `ds:` state reaches `omnipresent` (note: `ds: rumoured` only means the CDS is published)

#### Lab 7.3: Validate and Troubleshoot (25 minutes)
**Objective:** Configure DNSSEC validation and diagnose validation failures
**Exercise Steps:**
1. Configure the resolver: remove `validate-except { "example"; }` from Module 6, keep `dnssec-validation auto;`, add the `example.` trust anchor; the `static-stub` zone for `example` is already there from Lab 6.1
2. Confirm the AD flag for `isc.org` and `www.teamNN.example`, and SERVFAIL for `dnssec-failed.org`
3. Diagnose `expired.example` and `wrongds.example` with `dig +cd`, Extended DNS Errors, `delv @registry -a anchors.conf +root=example +vtrace` (pointed at the registry, which holds both the broken zones and their DS) and the resolver log
4. Add and remove a negative trust anchor (`rndc nta`)
**Success criteria:** cause and fix stated for each broken zone

#### Lab 7.4: Roll the Keys (20 minutes)
**Objective:** Perform ZSK and KSK rollovers without breaking validation
**Exercise Steps:**
1. ZSK: `rndc dnssec -rollover -key <id> teamNN.example`; follow the key states
2. KSK: `rndc dnssec -rollover -key <id> teamNN.example`; wait for the CDS to show the new key
3. The registry replaces the DS
4. Confirm to `named`: `rndc dnssec -checkds -key <new> published teamNN.example` and `-key <old> withdrawn`
5. Query through the resolver throughout; discuss emergency KSK rollover with production timings
**Success criteria:** one KSK and one ZSK remain; the DS matches the new KSK; the AD flag never dropped

---

## Module 8: DNS Privacy and Encryption - Lab Requirements

All steps below were run on 2026-10-21 with Debian 13 packages (bind9 9.20.29, unbound 1.26.1, knot-dnsutils 3.4.6, openssl 3.5.7, curl 8.14.1, tcpdump 4.99.5, tshark 4.4.19), inside an unprivileged user and network namespace that put the lab addresses on one loopback. Re-run 2026-10-27 with bind9 9.20.30 and unbound 1.26.2: same lab results. Lab kit: `labs/module08/` (certificate script, BIND and Unbound snippets, DDR zone, and the rehearsal harness `test/rehearse.sh`).

### Lab Environment Setup
- **Participant VMs:** the two Debian 13 VMs from Module 7: the BIND 9.20 validating resolver (gets DoT, DoH and DDR) and the authoritative server for `teamNN.example` (used as the client)
- **Packages:** `bind9`, `bind9-dnsutils`, `knot-dnsutils` (`kdig`), `unbound` (client VM), `tcpdump`, `tshark`, `openssl`, `curl`
- **Certificates:** each team runs `make-certs.sh NN <resolver address>` on its resolver: a 30-day team CA and an ECDSA P-256 certificate for `resolver.teamNN.example` with the resolver's address as an IP SAN. Keys stay on the resolver; only `ca.crt` goes to the client. No shared or fixed secrets
- **Zone data:** `resolver.teamNN.example` A (and AAAA) record in `teamNN.example`; `secret-project.teamNN.example` A record for Lab 8.1
- **Instructor demo (optional):** Knot DNS 3.4 with `listen-quic` for DoQ; BIND 9.20 and Unbound 1.26 as packaged in Debian 13 do not serve DoQ
- **Not tested:** the `systemctl` steps on real VMs, Debian 12 (BIND 9.18, Unbound 1.17), DNR options in a DHCP server (discussion only)

### Lab Exercises

#### Lab 8.1: See Plaintext DNS (15 minutes)
**Objective:** See what an on-path observer sees
**Exercise Steps:**
1. Capture on the resolver: `tcpdump -i any -n -w plain.pcap port 53 or port 853 or port 443`
2. From the client, `dig @<resolver> secret-project.teamNN.example A`
3. List the queries with `tshark -r plain.pcap -T fields -e ip.src -e ip.dst -e dns.qry.name`
**Success criteria:** the client's query and the resolver's own queries (one showing QNAME minimisation) identified

#### Lab 8.2: DoT and DoH on Your Resolver (25 minutes)
**Objective:** Serve DoT and DoH from BIND 9.20 and test strict, failing and opportunistic clients
**Exercise Steps:**
1. Make the team certificate: `sudo mkdir /etc/bind/tls; sudo sh labs/module08/make-certs.sh NN <resolver address> /etc/bind/tls`; then `sudo chown root:bind` and `sudo chmod 640` on `/etc/bind/tls/resolver.key`
2. Install `named.conf.module08` (`tls` and `http` blocks, `resolver.arpa` zone) and `db.resolver.arpa`; add the `listen-on` lines from `named.conf.options.module08`; `named-checkconf`; restart `named`
3. Strict DoT with `kdig` and `dig` (`+tls-ca=ca.crt +tls-hostname=resolver.teamNN.example`)
4. A wrong `+tls-hostname`, `+tls-ca` without the file, and `+tls` alone
5. DoH with `kdig +https`, `dig +https` and `dig +https-get`; repeat the Lab 8.1 capture over DoT
**Success criteria:** strict DoT and DoH succeed; wrong name and unknown CA fail; the capture shows SNI and ALPN `dot` but no query name on the client hop, and cleartext queries from the resolver to the authoritative server

#### Lab 8.3: Forward over TLS with Unbound (15 minutes)
**Objective:** Send all of a client's queries over authenticated DoT
**Exercise Steps:**
1. Install `module08-forward.conf` (listens on 127.0.0.1 port 5300; `forward-tls-upstream`, `forward-addr <resolver>@853#resolver.teamNN.example`) and the team `ca.crt`; restart Unbound. After `apt install unbound` the service shows as failed (BIND owns port 53 on this VM); expected until the lab file is installed
2. `dig @127.0.0.1 -p 5300 www.teamNN.example`, with a capture on the client
3. Set a wrong name after `#`, restart, query, read the log
**Success criteria:** answers through Unbound; only TCP 853 to the resolver, queries padded to 147-octet TLS records; wrong name gives SERVFAIL and "hostname mismatch" in the log

#### Lab 8.4: Resolver Discovery with DDR (20 minutes)
**Objective:** Advertise the encrypted resolver with DDR and check verified discovery
**Exercise Steps:**
1. Set the team number in `db.resolver.arpa`; `named-checkzone`; `rndc reload resolver.arpa`
2. `dig @<resolver> _dns.resolver.arpa SVCB` (`dig` 9.20 prints `dohpath` as `key7`)
3. `openssl s_client -connect <resolver>:853 -CAfile ca.crt -verify_ip <resolver> -alpn dot -brief`, then with another team's address
4. Discuss: private lab addresses and opportunistic discovery; what DNR (DHCPv4 option 162, DHCPv6 and RA option 144) would add
**Success criteria:** two SVCB records (DoT on 853, DoH on 443 with `dohpath`); "Verification: OK" for the team's own address and "IP address mismatch" for another

#### Lab 8.5: Padding on the Wire (15 minutes)
**Objective:** Measure what padding hides
**Exercise Steps:**
1. `response-padding { any; } block-size 468;` on the resolver
2. Capture TCP 853 while querying two names of different length over DoT, with and without `+padding=128`
3. Read TLS record lengths with `tshark -Y tls -T fields -e ip.src -e tls.record.length`; compare `kdig +padding` and `+nopadding`
4. Try `+padding=128` over UDP and plain TCP
**Success criteria:** unpadded record sizes differ by the name-length difference (78 and 89 octets in the test lab); padded sizes are identical (147 and 487); participants note that BIND also padded over plain TCP (documented in the BIND ARM for `response-padding`: queries that use TCP or carry a valid server cookie; a design choice that departs from RFC 7830 §6), while Unbound padded only over TLS

---

## Module 9: Registry Operations and EPP - Lab Requirements

All steps below were run on 2026-10-21 against the Namingo v1.0.34 EPP server (MariaDB 11.8 backend) with the Net::EPP 0.28 client from Debian 13, and every EPP frame sent and received validated against the RFC 5730-5733, 5910 and 3915 schemas. Lab files (instructor kit, not yet in the repository): `epp-send` (client script), XML files `01-hello.xml` to `56-rgp-restore-report.xml`, instructor preparation files and `seed-lab.sh`.

### Lab Environment Setup
- **Participant VMs:** 1 Debian 13 client VM per participant (packages `libnet-epp-perl`, `openssl`, `bind9-utils`, `bind9-dnsutils`); the Module 7 VMs supply the DS record
- **Registry server (instructor):** Debian 13 VM running the Namingo EPP server (open source, MIT) for the `.example` TLD on TCP port 700, MariaDB backend, system time zone UTC. Namingo's installer runs as root and adds third-party apt repositories (PHP with Swoole, Caddy, MariaDB); Swoole is not packaged in Debian
- **Accounts:** one registrar per team (`regNN`, password, client certificate from the lab CA whose SHA-256 fingerprint is stored with the registrar); teams work in pairs (`NN` and partner `PP`) for transfers
- **Lab settings:** `disable_60days => true` (the server otherwise refuses transfers within 60 days of creation with 2201); `mandatory_client_ssl => true` (RFC 5734 mutual authentication); transfers auto-approve after 5 days
- **Instructor preparation per team:** create `oldNN.example` (with an instructor contact) and move its creation date back 10 days, so that a delete enters the redemption period
- **Parent zone:** Namingo's zone writer (`automation/write-zone.php`, `dns_reload` off) generates `example.` from the registry database; the instructor's script `publish-example-zone.sh` sets `$TTL 60` (the writer always writes 3600, which the lab policy's `max-zone-ttl` rejects), checks the zone and reloads the Module 7 BIND, which signs it inline. Run both every minute during Lab 9.3 (Namingo's own cron runs the writer every 15 minutes). Tested 2026-10-21: a DS swap sent over EPP was served, signed, by BIND 2 seconds after the writer ran. The writer replaces the hand-edited `db.example`, so register `expired.example`, `wrongds.example` and any Module 7 DS records as registry domains before the first run

### Lab Exercises

#### Lab 9.1: Connect and Log In (15 minutes)
**Objective:** Establish an EPP session over TLS and read the greeting
**Exercise Steps:**
1. `openssl s_client -connect epp.registry.example:700 -CAfile lab-ca.crt -brief`: check TLS version and certificate
2. Read the 4-octet frame length of the greeting (`-quiet ... | head -c 4 | od -An -tu1`)
3. `epp-send 01-hello.xml`: list the objects and extensions offered
4. `epp-send 02-login.xml 03-logout.xml`
5. Repeat with a wrong password, the system CA bundle, no client certificate, and the partner's certificate
**Success criteria:** TLS 1.2 or 1.3 verified; login 1000, logout 1500; wrong password 2200; untrusted server certificate refused by the client; missing client certificate refused by the server; wrong registrar certificate 2201

#### Lab 9.2: Contacts, Hosts and Domains (25 minutes)
**Objective:** Create the objects for a delegation
**Exercise Steps:**
1. Check `teamNN.example` and the partner's name (`10`)
2. Create the contact and the domain (`11`, `12`)
3. Edit `13` to carry the Module 7 server's addresses (lab sheet), then create `ns1.teamNN.example` with glue and the external host `nsNN.example.net` (`13`, `14`)
4. Delegate to both (`15`); read the domain and host (`16`, `17`)
5. Send a copy of `13` without the `host:addr` lines, and send `12` again
**Success criteria:** info shows both name servers, status `ok`, `rgpStatus addPeriod`; host `linked`; 2306 and 2302 explained

#### Lab 9.3: Publish Your DS (15 minutes)
**Objective:** Submit the Module 7 DS through EPP `secDNS-1.1`
**Exercise Steps:**
1. Get the DS: `dig @ns1.teamNN.example teamNN.example CDS +short` or `dnssec-dsfromkey -2` on the KSK
2. Put its four fields in `20-domain-update-ds-add.xml`; send; check with `16`
3. Try a SHA-1 DS (`dnssec-dsfromkey -1`)
4. Discuss the DS swap after a KSK rollover (`21`) and CDS scanning by the registry
**Success criteria:** the DS in `secDNS:infData` matches the CDS record; `dig @registry teamNN.example DS +short` returns it within about a minute; SHA-1 rejected (2004 on the lab server)

#### Lab 9.4: Transfer and Renew (20 minutes)
**Objective:** Move a domain between registrars with a secure transfer code
**Exercise Steps:**
1. Both teams `export PARTNER=PP`; the losing registrar sets a random code (`export AUTHINFO=$(openssl rand -base64 18)`, file `35`) and gives it to the partner
2. Gaining registrar requests and queries the transfer (`30`, `31`): 1001, `pending`
3. Losing registrar reads the poll queue (`32`: 1301), approves (`33`) and acknowledges the message (`MSGID=<id= from the msgQ line>`, `34`)
4. Gaining registrar reads the domain (`36`) and renews it with `curExpDate` from the info response (`37`)
**Success criteria:** sponsor changed, `transferPeriod`, DS and name servers kept, expiry extended by the transfer and by the renew; a wrong code gives 2202

#### Lab 9.5: Delete and Restore (15 minutes)
**Objective:** Follow the RFC 3915 grace periods and redemption process
**Exercise Steps:**
1. Create and delete `spareNN.example` inside the add grace period; check that the name is available (`50`-`52`)
2. Note the time (`date -u +%Y-%m-%dT%H:%M:%SZ`) and delete `oldNN.example` (`53`): `pendingDelete`, `redemptionPeriod` (`54`)
3. Note the time and send the restore request (`55`): `pendingRestore`; restore report with `DELTIME` and `RESTIME` set to those two times (`56`): status `ok`
**Success criteria:** the RFC 3915 state diagram drawn from the observed states; the refunded delete identified

---

## Module 10: Advanced Registry Systems - CoCCA - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 3 Debian server VMs per participant
- **Software:** CoCCA registry software, PostgreSQL, web server
- **Integration:** WHMCS or similar billing system

### Lab Exercises

#### Lab 10.1: CoCCA Installation and Configuration (45 minutes)
**Objective:** Deploy complete CoCCA registry system
**Resources Needed:**
- CoCCA software package
- PostgreSQL database
- Java application server (Resin)
- Web server configuration
**Exercise Steps:**
1. Install CoCCA software stack
2. Configure database and application server
3. Set up initial registry configuration
4. Test basic registry functionality

#### Lab 10.2: Registry Policy Configuration (30 minutes)
**Objective:** Configure registry policies and business rules
**Resources Needed:**
- CoCCA administration interface
- Policy configuration templates
- Grace period and pricing examples
**Exercise Steps:**
1. Configure domain lifecycle policies
2. Set up pricing and billing rules
3. Implement grace period configurations
4. Test policy enforcement

#### Lab 10.3: WHMCS-CoCCA Integration (15 minutes)
**Objective:** Integrate CoCCA with registrar billing system
**Resources Needed:**
- WHMCS installation
- CoCCA EPP module for WHMCS
- Test registrar account
**Exercise Steps:**
1. Install CoCCA-WHMCS EPP module
2. Configure registrar connection settings
3. Test domain registration workflow
4. Verify billing integration

---

## Module 11: DNS Monitoring and Performance - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Debian server VMs per participant
- **Software:** Prometheus, Grafana, RIPE Atlas tools, custom monitoring scripts
- **Monitoring:** Network monitoring capabilities

### Lab Exercises

#### Lab 11.1: DNS Monitoring Implementation (45 minutes)
**Objective:** Deploy DNS monitoring
**Resources Needed:**
- Prometheus and Grafana
- DNS-specific exporters
- Alerting configuration
**Exercise Steps:**
1. Set up Prometheus for DNS metrics collection
2. Configure Grafana dashboards
3. Implement alerting rules
4. Test monitoring and alerting scenarios

#### Lab 11.2: Performance Analysis and Optimisation (30 minutes)
**Objective:** Analyse and optimise DNS performance
**Resources Needed:**
- Performance testing tools
- Query log analysis scripts
- Optimisation configuration examples
**Exercise Steps:**
1. Conduct DNS performance baseline testing
2. Analyse query patterns and bottlenecks
3. Implement performance optimisations
4. Measure improvement results

#### Lab 11.3: Incident Response Simulation (15 minutes)
**Objective:** Practice DNS incident response procedures
**Resources Needed:**
- Simulated DNS outage scenarios
- Incident response playbooks
- Communication tools
**Exercise Steps:**
1. Simulate various DNS failure scenarios
2. Execute incident response procedures
3. Practice communication protocols
4. Conduct post-incident review

---

## Module 12: Emerging Technologies - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Debian server VMs per participant
- **Software:** Experimental DNS software, IPv6 configuration tools
- **Network:** IPv6-enabled lab environment

### Lab Exercises

#### Lab 12.1: IPv6-Only DNS Operations (45 minutes)
**Objective:** Configure and test IPv6-only DNS infrastructure
**Resources Needed:**
- IPv6-enabled network infrastructure
- IPv6 DNS server configurations
- IPv6 client testing capabilities
**Exercise Steps:**
1. Configure IPv6-only DNS servers
2. Set up IPv6 reverse DNS
3. Test IPv6 DNS resolution
4. Analyse IPv6 vs dual-stack performance

#### Lab 12.2: Experimental DNS Technologies (15 minutes)
**Objective:** Explore emerging DNS technologies
**Resources Needed:**
- DNS-over-QUIC (RFC 9250) implementations (e.g. dnsdist, AdGuard Home)
- ECH test endpoints and HTTPS/SVCB record lookups
- Next-generation DNS software
**Exercise Steps:**
1. Test DNS-over-QUIC implementations
2. Inspect ECH configuration published in HTTPS records (`dig HTTPS`)
3. Evaluate new DNS server software
4. Assess migration considerations

#### Course Conclusion (30 minutes)
Closing deck: course recap, Final Project briefing and team allocation, certificates and next steps.
See "Final Assessment and Course Conclusion" in `dns_slide_deck_plan.md`.

#### Lab 12.3: DNS Architecture Design (moved to Day 7)
This exercise now opens the Day 7 Final Project; each team's design feeds its project.
**Objective:** Design DNS architecture for future requirements
**Resources Needed:**
- Architecture design tools
- Capacity planning resources
- Technology roadmap information
**Exercise Steps:**
1. Design scalable DNS architecture
2. Plan for emerging technology adoption
3. Develop migration strategies
4. Present architecture proposals

---

## Lab Equipment Summary

### Per Participant Requirements
- **Laptop:** WiFi-capable with SSH client (required)
- **Virtual Machines:** 4 VMs minimum (provided by lab infrastructure)
- **Network Access:** Lab network and limited internet access

### Shared Lab Infrastructure
- **VM Host Servers:** High-capacity servers for VM hosting
- **Network Infrastructure:** Managed switches, VLANs, internet gateway
- **Storage:** Shared storage for VM images and lab materials
- **Backup Systems:** Snapshot and backup capabilities for lab reset

### Software Licensing
- **Open Source:** BIND, Unbound, PowerDNS (no licensing required)
- **Commercial:** CoCCA (licensing required for full features)
- **Operating Systems:** Debian (freely available)

### Lab Management Tools
- **VM Management:** vSphere, VirtualBox, or KVM management
- **Network Monitoring:** Traffic analysis and monitoring tools
- **Lab Reset Scripts:** Automated environment restoration
- **Progress Tracking:** Lab completion monitoring system