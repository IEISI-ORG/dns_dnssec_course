# Advanced DNS/DNSSEC Workshop - Complete Slide Deck Plan

## Overall Presentation Structure
- **Course Duration:** 6 full days + Day 7 Final Project morning, 12 modules (see Program Facts in `dns_dnssec_workshop_plan.md`)
- **Slide Format:** Theory sessions (90 minutes each) with practical lab introductions
- **Estimated Total Slides:** ~770 (see Total Slide Count Summary)
- **Format:** Professional presentation template with consistent branding

---

## Module 1: Introduction to DNS - Foundations and Concepts
**Duration:** 90 minutes theory + 90 minutes practical
**Slides:** 70 (64 theory, 6 lab); deck: `modules/module01-dns-foundations.marp.md`

### Opening (9 slides)
- Title; welcome (instructor, participant introductions, venue placeholders for the instructor to fill in); the course (12 modules over Days 1-7, shorter programmes); how each day runs (daily schedule, assessment from Program Facts); the lab VMs for the week
- Module overview, learning objectives
- What changed recently: RFC 9499 terminology (BCP 219, 2024); TCP MUST (RFC 7766, RFC 9210); glue MUST (RFC 9471); b.root-servers.net renumbered 27 November 2023; IANA stewardship transition 1 October 2016 (PTI)
- Agenda (theory and lab)

### 1. From HOSTS.TXT to the DNS (5 slides)
- Names before the DNS (RFC 608, RFC 952, RFC 1034 §2.1); the design (RFC 882/883, RFC 1034/1035 STD 13, design goals); a sourced timeline; other ways hosts find names (`/etc/hosts` and nsswitch, mDNS, LLMNR)

### 2. The Namespace (8 slides)
- Tree of labels and size limits (RFC 1035 §2.3.4, RFC 4343); FQDNs, trailing dot, search lists; TLD types with IANA counts as of 22 October 2026; IDNA2008 A-labels; special-use names; domains and zones; delegation and glue (RFC 9471; in-domain, sibling, unrelated; RFC 1034 §4.2.2)

### 3. Records, Servers and Caching (6 slides)
- Resource records and RRsets; A, AAAA, NS, SOA, CNAME as a preview (Module 2 owns the details); server roles (RFC 9499; primary/secondary); caching and TTL; the stub resolver on Debian 13

### 4. Resolution (9 slides)
- Resolution walk-through; recursive and iterative queries; a real referral line by line; walking the lab hierarchy by hand; `dig +trace` and its limits; the root server system (anycast, instance identity, instances as of a date); root hints and priming (RFC 9609, current IANA root hints); what the resolver remembers

### 5. The DNS Message (7 slides)
- Message format (RFC 1035 §4.1); header flags; RCODEs, NODATA and EDE (pointer); reading `dig` output; UDP, TCP, EDNS(0) and truncation (lab output); IPv6 (AAAA, ip6.arpa, root service over IPv6)

### 6. Who Runs the DNS (7 slides)
- The map; ICANN and IANA/PTI; changing the root zone (RSSAC037 roles; root signed since 15 July 2010); root server operators and RSSAC; registries, registrars, resellers, registrants, DNS operators (Module 9 terms); RIRs and reverse DNS

### 7. Tools and a Debugging Method (7 slides)
- Tools and their Debian 13 packages; `dig` options; `host` and `nslookup`; a seven-step debugging method; delegation faults and their evidence; worked example: the participant's own zone on Day 1 (connection refused)

### Practical Lab (6 slides)
- Lab introduction, lab environment (Day 1 topology, lab hierarchy), online or offline, Labs 1.1-1.3 (walk the hierarchy, read the response, debug a delegation)

### Closing (6 slides)
- References, knowledge check (answers in presenter notes), thank you, contact, licence

---

## Module 2: DNS Operations - Zones, Records, and Data Management
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 50-55

### Zone Concepts Deep Dive (12 slides)
1. **Understanding DNS Zones**
   - Zone vs domain distinction
   - Zone boundaries and delegation
   - Authoritative zone concept

2. **Zone Delegation Process**
   - Parent-child relationships
   - NS record placement
   - Glue records necessity and function

3. **Zone Types Classification**
   - Primary zones (legacy BIND keyword: `type master`)
   - Secondary zones (legacy BIND keyword: `type slave`)
   - Stub zones
   - Forward zones

4. **Zone Transfer Mechanisms**
   - AXFR (full zone transfer)
   - IXFR (incremental zone transfer)
   - NOTIFY mechanisms
   - Security considerations

### DNS Record Types (20 slides)
5. **Address Records (A/AAAA)**
   - IPv4 address mapping (A records)
   - IPv6 address mapping (AAAA records)
   - Multiple address configurations
   - Load balancing considerations

6. **Canonical Name Records (CNAME)**
   - Alias functionality
   - CNAME restrictions and limitations
   - CNAME vs A record decisions
   - Common CNAME use cases

7. **Name Server Records (NS)**
   - Delegation specification
   - NS record placement rules
   - Circular dependency prevention
   - Best practices for NS records

8. **Mail Exchange Records (MX)**
   - Mail routing configuration
   - Priority and preference values
   - Multiple MX record strategies
   - Backup mail server setup

9. **Reverse DNS and PTR Records**
   - Reverse DNS concept and importance
   - PTR record structure
   - in-addr.arpa and ip6.arpa zones
   - Reverse delegation management

10. **Text Records (TXT)**
    - General purpose text storage
    - SPF (Sender Policy Framework) TXT records (RFC 7208; the SPF RR type is deprecated)
    - DKIM (DomainKeys Identified Mail) public keys in TXT at `_domainkey` (RFC 6376)
    - DMARC (Domain-based Message Authentication, Reporting, and Conformance) policies in TXT at `_dmarc` (RFC 9989)

11. **Service Records (SRV)**
    - Service discovery mechanism
    - SRV record format and fields
    - Common SRV implementations
    - Microsoft Active Directory usage

12. **Certificate Authority Authorisation (CAA)**
    - SSL/TLS certificate control
    - CAA record format
    - Certificate authority restrictions
    - Implementation best practices

### Zone File Management (10 slides)
13. **Zone File Syntax and Structure**
    - BIND zone file format
    - $ORIGIN and $TTL directives
    - Comment conventions
    - Record ordering best practices

14. **Start of Authority (SOA) Records**
    - SOA record components
    - Serial number management
    - Refresh, retry, and expire timers
    - Minimum TTL field

15. **TTL Strategy and Implementation**
    - Time-to-Live concept
    - Default TTL settings
    - Record-specific TTL values
    - TTL planning for different scenarios

16. **Zone File Validation**
    - Syntax checking tools
    - named-checkzone utility
    - Common zone file errors
    - Debugging techniques

### Email Infrastructure DNS (8 slides)
17. **Complete Email DNS Setup**
    - MX record configuration
    - SPF record implementation
    - DKIM key publication
    - DMARC policy deployment

18. **Anti-Spam DNS Techniques**
    - SPF alignment strategies
    - DKIM key rotation
    - DMARC policy evolution
    - Monitoring and reporting

### Practical Lab Introduction (5 slides)
19. **Zone Creation Workshop**
    - Zone file templates
    - Domain assignments
    - Validation procedures

20. **Email DNS Laboratory**
    - Mail server scenarios
    - Security record implementation
    - Testing procedures

---

## Module 3: DNS Server Types - Recursive, Authoritative, and Specialised Roles
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 55-60

### DNS Server Architecture Overview (10 slides)
1. **DNS Infrastructure Components**
   - Recursive resolvers
   - Authoritative name servers
   - Forwarders and conditional forwarders
   - Caching servers

2. **Recursive Resolver Deep Dive**
   - Full resolver functionality
   - Caching mechanisms
   - Query processing workflow
   - Client interface responsibilities

3. **Authoritative Server Roles**
   - Primary server functions
   - Secondary server operations
   - Hidden primary architectures
   - Stealth secondary configurations

### DNS Query Resolution Process (12 slides)
4. **Step-by-Step Query Resolution**
   - Client query initiation
   - Recursive resolver processing
   - Root server consultation
   - TLD server interaction
   - Authoritative server response

5. **Caching Strategies and Optimisation**
   - Positive caching mechanisms
   - Negative caching (NXDOMAIN)
   - TTL-based cache expiration
   - Cache pollution prevention

6. **DNS Forwarding Configurations**
   - Forward-only mode
   - Forward-first mode
   - Conditional forwarding
   - Split-brain DNS implementations

### Advanced DNS Architectures (15 slides)
7. **Split-Horizon DNS Design**
   - Internal vs external views
   - BIND views configuration
   - Security and access control
   - Use case scenarios

8. **Hidden Primary Architecture**
   - Hidden primary benefits
   - Security advantages
   - Implementation strategies
   - Zone transfer optimisation

9. **Anycast DNS Deployment**
   - Anycast concept and benefits
   - Geographic load distribution
   - Failover mechanisms
   - Implementation challenges

10. **DNS Load Balancing Techniques**
    - Round-robin DNS
    - Weighted responses
    - Geographic load balancing
    - Health checking integration

### DNS Server Placement and Topology (10 slides)
11. **DNS Infrastructure Planning**
    - Server placement strategies
    - Network topology considerations
    - Redundancy requirements
    - Performance optimisation

12. **ISP DNS Infrastructure**
    - ISP resolver deployment
    - Customer DNS services
    - Peering and transit considerations
    - Cache hierarchy design

13. **Enterprise DNS Architecture**
    - Internal DNS requirements
    - Active Directory integration
    - Branch office considerations
    - Cloud service integration

### Security and Performance Considerations (8 slides)
14. **DNS Security Architecture**
    - Access control implementations
    - Rate limiting strategies
    - DDoS mitigation techniques
    - Monitoring and logging

15. **Performance Optimisation**
    - Query response time optimisation
    - Cache hit ratio improvement
    - Network latency reduction
    - Capacity planning

### Practical Lab Introduction (5 slides)
16. **Lab Environment Setup**
    - Multi-server configuration
    - Network segments
    - Testing procedures

17. **Server Configuration Workshop**
    - Primary/secondary setup
    - Recursive resolver configuration
    - Split-horizon implementation

---

## Module 4: DNS Software Platforms - BIND, Unbound, PowerDNS, and Alternatives
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 60-65

### DNS Software Landscape Overview (8 slides)
1. **DNS Software Categories**
   - Open source vs commercial solutions
   - Authoritative vs recursive specialisation
   - Performance and feature comparisons
   - Market share and adoption trends

2. **Selection Criteria Framework**
   - Performance requirements
   - Security features
   - Management complexity
   - Integration capabilities
   - Support and community

### BIND (Berkeley Internet Name Domain) (18 slides)
3. **BIND History and Evolution**
   - Development timeline since 1980s
   - Version history and major releases
   - Current BIND 9 architecture
   - Future development roadmap

4. **BIND Architecture and Components**
   - named daemon functionality
   - Configuration file structure
   - Zone file management
   - RNDC remote control

5. **BIND Configuration Deep Dive**
   - named.conf structure and syntax
   - Options, logging, and zone statements
   - ACL (Access Control List) implementation
   - Views for split-horizon DNS

6. **BIND Security Features**
   - TSIG (Transaction Signature) authentication
   - DNS64 and RPZ (Response Policy Zones)
   - Rate limiting capabilities
   - Chroot jail deployment

7. **BIND Performance Tuning**
   - Memory management optimisation
   - Query processing efficiency
   - Cache tuning parameters
   - Multi-threading configuration

8. **BIND Operational Management**
   - Zone transfer configuration
   - Dynamic updates with nsupdate
   - Statistics and monitoring
   - Logging and debugging

### Unbound Recursive Resolver (12 slides)
9. **Unbound Design Philosophy**
   - Security-focused architecture
   - High-performance resolver design
   - Minimal attack surface
   - Standards compliance emphasis

10. **Unbound Configuration Management**
    - Configuration file structure
    - Local zones and data
    - Forwarding configurations
    - Access control implementation

11. **Unbound Security Features**
    - DNS-over-TLS support
    - DNSSEC validation
    - DNS filtering capabilities
    - Privacy protection features

12. **Unbound Performance Characteristics**
    - Multi-threading architecture
    - Memory usage optimisation
    - Cache management efficiency
    - Benchmarking results

### PowerDNS Platform (15 slides)
13. **PowerDNS Product Portfolio**
    - PowerDNS Authoritative Server
    - PowerDNS Recursor
    - PowerDNS Admin web interface
    - Commercial support options

14. **PowerDNS Authoritative Architecture**
    - Backend system design
    - Database integration options
    - API-driven management
    - Multi-primary capabilities

15. **PowerDNS Database Backends**
    - MySQL/MariaDB integration
    - PostgreSQL support
    - SQLite for smaller deployments
    - LDAP and other backends

16. **PowerDNS API and Automation**
    - RESTful API functionality
    - Zone management automation
    - Integration with provisioning systems
    - Monitoring and metrics

17. **PowerDNS Recursor Features**
    - High-performance recursive resolution
    - Lua scripting capabilities
    - Advanced filtering options
    - Cloud deployment optimisation

### Alternative DNS Solutions (8 slides)
18. **NSD (Name Server Daemon)**
    - Authoritative-only design
    - High-performance characteristics
    - Security-focused implementation
    - Use cases and deployment scenarios

19. **Knot DNS and Knot Resolver**
    - Modern DNS server implementation
    - Advanced DNSSEC features
    - High-performance resolver
    - CZ.NIC development and support

20. **Microsoft DNS Server**
    - Windows Server integration
    - Active Directory dependency
    - Enterprise feature set
    - Management and automation tools

21. **Cloud DNS Services**
    - Amazon Route 53
    - Google Cloud DNS
    - Cloudflare DNS
    - Azure DNS service comparison

### Practical Lab Introduction (4 slides)
22. **Multi-Platform Workshop**
    - BIND full configuration walkthrough
    - Unbound resolver setup
    - PowerDNS with database backend
    - Performance comparison testing

---

## Module 5: Advanced DNS Operations and Architecture
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 55-60

### Advanced Architecture Patterns (15 slides)
1. **Complex DNS Topologies**
   - Multi-tier DNS architectures
   - Geographic distribution strategies
   - Redundancy and failover planning
   - Scalability considerations

2. **Anycast DNS Implementation**
   - Anycast routing principles
   - BGP advertisement strategies
   - Health checking and monitoring
   - Failover mechanisms and timing

3. **Hidden Primary Architectures**
   - Security benefits and use cases
   - Implementation strategies
   - Zone transfer optimisation
   - Operational procedures

4. **Split-Horizon DNS Advanced Concepts**
   - Complex view configurations
   - Policy-based routing
   - Security implications
   - Management and maintenance

### DNS Caching Optimisation (12 slides)
5. **Advanced Caching Strategies**
   - Cache hierarchy design
   - Negative caching optimisation
   - Prefetching mechanisms
   - Cache warming techniques

6. **TTL Strategy Development**
   - Business requirement analysis
   - Change frequency assessment
   - Performance vs freshness tradeoffs
   - Emergency change procedures

7. **Cache Performance Analysis**
   - Hit ratio optimisation
   - Memory usage patterns
   - Query pattern analysis
   - Capacity planning methodologies

### DNS Load Balancing and Traffic Management (10 slides)
8. **DNS-Based Load Balancing**
   - Round-robin implementations
   - Weighted response strategies
   - Geographic load balancing
   - Health check integration

9. **GeoDNS Implementation**
   - Geographic query routing
   - Content delivery optimisation
   - Latency-based routing
   - Compliance and legal considerations

10. **Traffic Engineering with DNS**
    - Capacity management
    - Planned maintenance procedures
    - Emergency traffic redirection
    - Performance monitoring

### Advanced Troubleshooting Methodologies (12 slides)
11. **Systematic DNS Troubleshooting**
    - Problem classification frameworks
    - Tool selection strategies
    - Data collection methodologies
    - Root cause analysis techniques

12. **Query Path Analysis**
    - End-to-end query tracing
    - Latency measurement techniques
    - Bottleneck identification
    - Performance optimisation

13. **Complex Resolution Issues**
    - Delegation problems
    - DNSSEC validation failures
    - Timeout and retry scenarios
    - Interoperability challenges

### DNS Monitoring and Observability (8 slides)
14. **End-to-End Monitoring Strategies**
    - Metrics collection frameworks
    - Real-time alerting systems
    - Performance baseline establishment
    - Trend analysis and capacity planning

15. **Operational Excellence Practices**
    - Change management procedures
    - Documentation standards
    - Incident response protocols
    - Continuous improvement processes

### Practical Lab Introduction (3 slides)
16. **Advanced Configuration Workshop**
    - Complex architecture implementation
    - Performance optimisation exercises
    - Troubleshooting scenarios

---

## Module 6: DNS Security Fundamentals and Threat Landscape
**Duration:** 90 minutes theory + 90 minutes practical
**Slides:** 70 (62 theory, 8 lab); deck: `modules/module06-dns-security-fundamentals.marp.md`

### Opening (5 slides)
- Title, module overview, learning objectives
- What changed recently: TSIG is RFC 8945 (STD 93; HMAC-MD5 MUST NOT); interoperable server cookies (RFC 9018); QNAME minimisation RFC 9156 obsoletes Experimental RFC 7816; BIND 9.20 `allow-transfer` defaults to none (9.18: any); 1232-octet EDNS buffer defaults and RFC 9715
- Agenda (theory and lab)

### 1. The Threat Landscape (6 slides)
- Why DNS is a target; RFC 3833 threat analysis
- Attack classes (forgery, hijacking, denial of service, abuse as a channel, data exposure) and where in the course each is defended
- Where attacks land (registrar/registry, server, off-path forgery, reflection, stub and LAN)
- Dated history from primary sources only: CVE-2008-1447 and CERT/CC VU#800113 (Kaminsky, 2008); CISA ED 19-01 (DNS infrastructure tampering, 2019); CVE-2020-8616 (NXNSAttack, 2020); CVE-2020-25705 (SAD DNS, 2020); CVE-2023-50387 and CVE-2023-50868 (KeyTrap, NSEC3, 2024)
- Defence map: which measure covers which class

### 2. Cache Poisoning and Hijacking (9 slides)
- How a resolver accepts an answer (RFC 5452 §9.1; RFC 2181 §5.4.1); the arithmetic of guessing (RFC 5452 §8.1: 7 seconds with one port, about 116 hours with 64,000)
- The Kaminsky attack; source-port and ID randomisation (RFC 5452 §9.2), 0x20 (expired draft; Unbound `use-caps-for-id`), cookies, TCP, DNSSEC; NAT de-randomisation
- Lab 6.2 capture: ports, IDs, per-server client cookies
- SAD DNS (side channel, kernel fix); hijacking at the registrar, the server, BGP (RFC 6811) and the stub, with registry lock (Module 9); CISA ED 19-01 actions

### 3. Floods and Amplification (11 slides)
- Reflection and amplification (RFC 5358 factor; BCP 38, BCP 84); measured amplification on the team's own server; `minimal-any` (RFC 8482)
- Open resolvers (RFC 5358, BCP 140); BIND 9.20 access controls and their defaults (`allow-recursion` inherits `allow-query`; localnets); the localnets trap (Lab 6.1 output)
- Response rate limiting (`rate-limit`, slip, cookies, log-only) and its lab measurements; what a legitimate client sees (TC, BADCOOKIE)
- Query floods and random-subdomain attacks; NXNSAttack; resolver fetch limits; response size and fragmentation (1232, RFC 9715, RFC 7766)

### 4. Hardening Servers (11 slides)
- Authoritative checklist and lab configuration (recursion no, transfers by TSIG, version none, minimal responses, RRL, hidden primary pointer to Module 5)
- Recursive resolver checklist and lab configuration (ACLs, validation, `validate-except` for the lab TLD until Module 7, static-stub for `example`)
- QNAME minimisation (RFC 9156, obsoletes 7816): algorithm, QTYPE choice, iteration limit, BIND relaxed and Unbound defaults; seen in the lab capture; Module 8 points here
- DNS Cookies (RFC 7873, updated by 9018): client and server cookies, SipHash-2-4 server cookie, BADCOOKIE; seen in `dig` and the query log; BIND and Unbound options; Module 8 points here
- Pointers: DNSSEC and aggressive NSEC caching (Module 7); DoT, DoH, DoQ and DDR (Module 8)

### 5. TSIG and Zone Transfers (6 slides)
- TSIG (RFC 8945): fudge 300, one key per pair, algorithm table
- Making a key with `tsig-keygen`; TSIG-protected transfers in BIND; failures (BADSIG, BADKEY, BADTIME, NOTAUTH) from the lab; beyond TSIG (rotation, XoT pointer, SIG(0), GSS-TSIG, catalog zones)

### 6. RPZ, Tunnelling and Detection (8 slides)
- Response Policy Zones: status (expired individual draft `draft-vixie-dnsop-dns-rpz-00`, not an RFC), triggers and actions, BIND configuration (order, `ede filtered`, RD and DO rules), lab output
- DNS tunnelling and covert channels: mechanism, detection signs, responses; summary of a lab capture (`tools/dns-signs.sh`)
- Logging and detection signs in BIND (categories, `rndc stats` counters, dnstap); Module 11 for monitoring

### Practical Lab (8 slides)
- Lab introduction, lab environment, lab rules (containment), Labs 6.1-6.5 (close the open doors, watch the resolver defend itself, rate limiting under load, TSIG-protected zone transfer, RPZ and spotting a tunnel)

### Closing (6 slides)
- References, knowledge check (answers in presenter notes), thank you, contact, licence

---

## Module 7: DNSSEC Implementation and Operations
**Duration:** 90 minutes theory + 90 minutes practical
**Slides:** 70 (64 theory, 6 lab); deck: `modules/module07-dnssec-implementation.marp.md`

### Opening (5 slides)
- Title, module overview, learning objectives
- What changed recently: `dnssec-policy` replaces `auto-dnssec` (BIND 9.20); IANA algorithm registry (RFC 9904) and SHA-1 deprecation (RFC 9905); NSEC3 per RFC 9276; CDS/CDNSKEY; root KSK-2024 signing since 11 October 2026
- Agenda (theory and lab)

### 1. DNSSEC Fundamentals (16 slides)
- Why DNSSEC; what it gives and does not give; signing data, not the channel
- Public-key cryptography and where hashes appear
- Record types: DNSKEY, RRSIG, DS, NSEC, NSEC3, NSEC3PARAM, CDS, CDNSKEY; anatomy of DNSKEY, RRSIG and DS from real lab output
- Chain of trust; trust anchors and the root KSK rollover (KSK-2024, key tag 38696, signing since 11 October 2026; KSK-2017 revoked 11 January 2027; RFC 5011, RFC 9718)
- Validation steps and outcomes (RFC 4035 §4.3); AD and CD bits
- NSEC, zone walking, aggressive caching (RFC 8198), compact denial (RFC 9824); NSEC3 and RFC 9276 parameters (iterations 0, empty salt, opt-out only for large sparse zones); validator iteration limits

### 2. Key Management (13 slides)
- KSK, ZSK and CSK
- Algorithm choice from the IANA registry (8, 13 and 15 RECOMMENDED; 5 and 7 MUST NOT for signing); why algorithm 13
- DS digest types (SHA-256; SHA-1 MUST NOT)
- Key generation; key protection (permissions, HSM via `key-store`, offline KSK, backups)
- Whether and when to roll; ZSK pre-publish; KSK double-KSK and double-DS
- Rollover timing (RFC 7583) mapped to `dnssec-policy` options; emergency and algorithm rollovers

### 3. Signing Zones (11 slides)
- Manual signing: `dnssec-keygen`, `dnssec-signzone -S -3 - -H 0`, `dnssec-verify`
- Automatic signing with `dnssec-policy` (KASP): the built-in `default` policy, a custom policy, `rndc dnssec -status` and key states
- CDS/CDNSKEY and DS automation (RFC 7344, 8078, 9615, 9975); `parental-agents`, `checkds` and `rndc dnssec -checkds`
- Multi-signer (RFC 8901) and other signers (Knot DNS, PowerDNS, OpenDNSSEC)

### 4. Validation and Troubleshooting (8 slides)
- BIND: `dnssec-validation auto`, `trust-anchors` (static and initial); Unbound: `auto-trust-anchor-file`, `trust-anchor`, `ede: yes`
- Testing a validator (AD flag, `dnssec-failed.org`, `+cd`)
- Troubleshooting workflow: `+cd`, Extended DNS Errors (RFC 8914), `delv +vtrace`, resolver logs, negative trust anchors (RFC 7646)
- Common failures and worked examples: expired signatures, DS matching no key

### 5. Operations and Policy (5 slides)
- Deployment planning and safe rollback (remove the DS first)
- Monitoring; operational pitfalls
- A DNSSEC policy and practice statement (RFC 6841)

### Practical Lab (6 slides)
- Lab environment; Labs 7.1-7.4 (sign by hand, sign with `dnssec-policy`, validate and troubleshoot, roll the keys)

### Closing (6 slides)
- References, knowledge check (answers in presenter notes), thank you, contact, licence

---

## Module 8: DNS Privacy and Encryption Technologies
**Duration:** 90 minutes theory + 90 minutes practical
**Slides:** 63 (56 theory, 7 lab); deck: `modules/module08-dns-privacy-encryption.marp.md`

### Opening (5 slides)
- Title, module overview, learning objectives
- What changed recently: DoQ (RFC 9250) and DNS over CoAP (RFC 9953); resolver discovery with DDR and DNR (RFC 9462, 9463); Encrypted ClientHello (RFC 9849, 9848); TLS 1.3 as RFC 9846 and RFC 9852; opportunistic resolver-to-authoritative encryption (RFC 9539, Experimental)
- Agenda (theory and lab)

### 1. The DNS Privacy Problem (8 slides)
- What a query reveals (name, client address, timing; ECS, RFC 7871); who sees which hop; threat model (RFC 9076, which obsoletes RFC 7626)
- Plaintext DNS on the wire (Lab 8.1 capture)
- DNSSEC and encryption solve different problems; QNAME minimisation and DNS Cookies are Module 6
- Standards map with RFC status; operator obligations: RFC 8932 (BCP 232), the Recursive operator Privacy Statement, logs and local law

### 2. DNS over TLS (10 slides)
- RFC 7858: TCP 853, ALPN `dot`, no cleartext on 853, pipelining and out-of-order responses; RFC 8310 strict and opportunistic profiles, authentication domain name, RFC 9525
- The resolver's certificate (DNS name, IP SAN for DDR; SNI stays visible)
- BIND 9.20 `tls` block and `listen-on ... tls`; the same on Unbound 1.26; dnsdist
- Testing with `dig` and `kdig` (strict, opportunistic, failures); performance and operations (connection reuse, RFC 7766, 9210, 7828); DoT on the wire

### 3. DNS over HTTPS and QUIC (10 slides)
- RFC 8484: URI template, GET and POST, HTTP/2, message ID 0
- Wire format only (`application/dns-message`, RFC 8484); JSON APIs are vendor-specific
- A DoH exchange with `curl`; HTTP caching rules and cookies; BIND 9.20 `http` block; deploying DoH behind proxies and load balancers
- DoQ (RFC 9250): UDP 853, ALPN `doq`, one query per stream, ID 0, 0-RTT limits; Debian 13 support (`kdig`, Knot DNS; not BIND 9.20 or Unbound 1.26 as packaged); instructor demo
- DoT, DoH and DoQ compared

### 4. Discovery and Deployment (9 slides)
- Configured vs discovered resolvers; SVCB for DNS servers (RFC 9460, 9461: `alpn`, `port`, `dohpath`; IANA SvcParamKeys)
- DDR (RFC 9462): `_dns.resolver.arpa`, verified and opportunistic discovery, IP SAN; lab output
- DNR (RFC 9463): DHCPv4 option 162, DHCPv6 option 144, RA option 144; authentication domain name; spoofing
- Clients you will meet (dated primary sources only: Apple, Chrome, Windows Server 2022, Linux forwarders)
- Enterprise and ISP policy (split horizon, RFC 9704; run your own encrypted resolver and advertise it); running an encrypted resolver service

### 5. Beyond the Stub (8 slides)
- Padding (RFC 7830, RFC 8467 block-length 128/468) and measured record sizes (Lab 8.5)
- Resolver-to-authoritative encryption (RFC 9539, Experimental); zone transfers over TLS (RFC 9103) with BIND 9.20
- Oblivious DoH (RFC 9230, Experimental, Independent Submission; RFC 9458, 9540)
- DNSCrypt (not an IETF standard; individual draft; Debian packages)
- What encryption still leaves visible (address, SNI and ECH, sizes, the resolver operator); TLS 1.3 updates

### Practical Lab (7 slides)
- Lab environment; Labs 8.1-8.5 (see plaintext DNS, DoT and DoH on the resolver, forward over TLS with Unbound, resolver discovery with DDR, padding on the wire)

### Closing (6 slides)
- References, knowledge check (answers in presenter notes), thank you, contact, licence

---

## Module 9: Registry Operations and EPP Protocol
**Duration:** 90 minutes theory + 90 minutes practical
**Slides:** 67 (60 theory, 7 lab); deck: `modules/module09-registry-operations-epp.marp.md`

### Opening (5 slides)
- Title, module overview, learning objectives
- What changed recently: RDAP replaced WHOIS for gTLDs (28 January 2025); secure transfer codes (RFC 9154); revised ICANN Transfer Policy adopted 7 June 2026, not yet in force; DS by EPP `secDNS` and CDS/CDNSKEY; RFC 9874 for deleting hosts
- Agenda (theory and lab)

### 1. The Registry Operating Model (9 slides)
- Roles: registry, registrar, reseller, registrant, DNS operator; the shared registry model; gTLD (Registry Agreement, RAA) and ccTLD governance
- Thick and thin registries; services a registry runs (EPP, zone, RDAP, escrow, billing, reporting)
- Domain lifecycle; grace periods (RFC 3915: add, renew, auto-renew, transfer, redemption, pending delete; .com contract values; ERRP, AGP Limits Policy); redemption and restore state diagram
- Client, server and pending status codes; registry lock

### 2. EPP Fundamentals (10 slides)
- What EPP is (RFC 5730; STD 69 = RFC 5730-5734; history from RFC 3730); EPP standards map (RFC 5730-5734, 5910, 3915, 8334, 8748, 9154, 8807, 3735, 7451, 9874)
- TLS transport with mutual authentication and 4-octet framing (RFC 5734, 8996); session, greeting and login
- Commands; result codes; objects and their links; the poll queue

### 3. Objects, Renewals and Transfers (13 slides)
- Contacts (RFC 5733); `check`; domain `create`; host objects and glue, internal and external hosts (RFC 5732); name server updates (`hostObj`, `hostAttr`); `info`; renew
- Transfers: flow, request and response, secure transfer codes (RFC 9154), ICANN Transfer Policy (in force, and the revision adopted 7 June 2026)
- Deleting hosts and domains (RFC 5731 2305; RFC 9874 sacrificial hosts)

### 4. DNSSEC at the Registry (7 slides)
- Paths for the DS (EPP, CDS scanning, web form); Registry Agreement Spec 6
- `secDNS-1.1` (RFC 5910): DS Data vs Key Data and why DS Data is usual; adding a DS; KSK rollover with `rem` then `add`
- What a registry should check (digest type, algorithm, matching DNSKEY); CDS/CDNSKEY from the registry side (RFC 7344, 8078, 9615, 9975)

### 5. Extensions and Registration Data (5 slides)
- How EPP is extended (RFC 3735, 7451, 9038); extensions you will meet (RFC 8334, 8748, 8495, 8807, 8590, 9167, 9803, 8543/8544, 9873)
- Registration data: RDAP replaced WHOIS for gTLDs on 28 January 2025 (except .com, .name, .post); ccTLD policy; redaction (RFC 9537); EPP to RDAP status mapping (RFC 8056)
- Policy in software: eligibility, reserved names, pricing, lifecycle timings, data, DNS rules

### 6. Registry Operations (5 slides)
- Service levels (gTLD Registry Agreement Spec 10); running and protecting the EPP service
- Escrow (RFC 8909, 9022; Spec 2), billing and registrar onboarding
- Registry software: FRED, Nomulus, Namingo; CoCCA in Module 10

### Practical Lab (7 slides)
- Lab environment; Labs 9.1-9.5 (connect and log in, contacts/hosts/domains, publish the DS, transfer and renew, delete and restore)

### Closing (6 slides)
- References, knowledge check (answers in presenter notes), thank you, contact, licence

---

## Module 10: Advanced Registry Systems - CoCCA Backend Operations
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 50-55

### CoCCA Platform Overview (12 slides)
1. **CoCCA Architecture and History**
   - Developed and operated by CoCCA (Council of Country Code Administrators)
   - ccTLD focus and design
   - Component architecture
   - Version evolution and roadmap

2. **CoCCA Core Components**
   - Registry database schema
   - EPP server implementation
   - RDAP and WHOIS service integration
   - Administrative interfaces

3. **CoCCA Deployment Models**
   - Single registry deployment
   - Multi-registry hosting
   - Cloud deployment options
   - Disaster recovery planning

### CoCCA Technical Implementation (15 slides)
4. **Database Architecture**
   - PostgreSQL integration
   - Schema design principles
   - Data relationships and integrity
   - Performance optimisation

5. **EPP Server Configuration**
   - CoCCA EPP implementation
   - Extension support
   - Security configuration
   - Performance tuning

6. **RDAP and WHOIS Service Setup**
   - RDAP and WHOIS server configuration
   - Query rate limiting
   - Privacy protection integration
   - Output format customisation

7. **Administrative Interface Usage**
   - Web-based administration
   - User management and permissions
   - Policy configuration
   - Reporting and analytics

### Registry Business Logic (10 slides)
8. **Policy Configuration**
   - Registration rules setup
   - Grace period configuration
   - Pricing and billing rules
   - Eligibility requirement enforcement

9. **Registrar Management**
   - Registrar onboarding process
   - Account management procedures
   - Billing and financial tracking
   - Performance monitoring

### Integration and Automation (8 slides)
10. **External System Integration**
    - Billing system connectivity
    - WHMCS integration setup
    - API-based integrations
    - Third-party service connections

11. **Operational Automation**
    - Automated monitoring setup
    - Backup and recovery procedures
    - Update and maintenance processes
    - Alert and notification systems

### Practical Lab Introduction (5 slides)
12. **CoCCA Workshop**
    - Complete CoCCA installation
    - Registry configuration
    - Registrar integration testing
    - Operational procedures

---

## Module 11: DNS Monitoring, Incident Response, and Performance Optimisation
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 55-60

### DNS Monitoring Strategy (15 slides)
1. **Monitoring Framework Development**
   - Key Performance Indicators (KPIs)
   - Service Level Objectives (SLOs)
   - Monitoring architecture design
   - Tool selection criteria

2. **DNS Metrics and Measurements**
   - Query response times
   - Availability measurements
   - Error rate tracking
   - Cache performance metrics

3. **Monitoring Infrastructure**
   - Prometheus and Grafana setup
   - RIPE Atlas integration
   - ThousandEyes deployment
   - Custom monitoring solutions

4. **Alerting and Notification Systems**
   - Alert threshold configuration
   - Escalation procedures
   - Notification channel management
   - Alert fatigue prevention

### Performance Optimisation (15 slides)
5. **DNS Performance Analysis**
   - Baseline establishment
   - Bottleneck identification
   - Performance testing methodologies
   - Capacity planning procedures

6. **Query Response Optimisation**
   - Caching strategy optimisation
   - Network latency reduction
   - Server placement strategies
   - Load balancing improvements

7. **Infrastructure Scaling**
   - Horizontal scaling strategies
   - Vertical scaling considerations
   - Auto-scaling implementations
   - Cost optimisation techniques

### Incident Response Management (15 slides)
8. **Incident Response Framework**
   - Incident classification system
   - Response team organisation
   - Communication procedures
   - Documentation requirements

9. **DNS Incident Types**
   - Service outages
   - Performance degradation
   - Security incidents
   - Configuration errors

10. **Incident Response Procedures**
    - Detection and alerting
    - Initial assessment
    - Mitigation strategies
    - Resolution and recovery

11. **Post-Incident Activities**
    - Root cause analysis
    - Lessons learned documentation
    - Process improvement implementation
    - Preventive measure development

### Business Continuity and Disaster Recovery (10 slides)
12. **Disaster Recovery Planning**
    - Risk assessment procedures
    - Recovery time objectives (RTO)
    - Recovery point objectives (RPO)
    - Backup and restore strategies

13. **Business Continuity Implementation**
    - Service redundancy design
    - Geographic distribution strategies
    - Failover automation
    - Communication plans

### Practical Lab Introduction (5 slides)
14. **Monitoring Implementation Workshop**
    - Complete monitoring stack deployment
    - Incident response simulation
    - Performance optimisation exercises
    - Recovery procedure testing

---

## Module 12: Emerging Technologies and Future Considerations
**Duration:** 90 minutes theory + 90 minutes practical
**Estimated Slides:** 50-55

### DNS Technology Evolution (12 slides)
1. **Current DNS Limitations**
   - Scalability challenges
   - Security vulnerabilities
   - Privacy concerns
   - Performance bottlenecks

2. **Emerging Protocol Developments**
   - DNS-over-QUIC (DoQ, RFC 9250, 2022): standardised; deployment status
   - HTTP/3 implications for DoH
   - Encrypted Client Hello (ECH) published via HTTPS/SVCB records (RFC 9460)
   - New transport protocols

3. **Next-Generation DNS Features**
   - Adaptive DNS implementations
   - AI/ML integration possibilities
   - Blockchain-based DNS alternatives
   - Quantum-resistant cryptography

### IPv6 and DNS Evolution (10 slides)
4. **IPv6-Only DNS Operations**
   - IPv6-only network challenges
   - DNS64 and NAT64 integration
   - Performance considerations
   - Migration strategies

5. **Dual-Stack Optimisation**
   - Happy Eyeballs implementation
   - IPv4/IPv6 preference handling
   - Performance measurement
   - Operational best practices

### DNS Abuse and Mitigation (10 slides)
6. **Modern DNS Abuse Patterns**
   - Domain generation algorithms
   - Fast-flux networks
   - DNS tunneling evolution
   - Amplification attack trends

7. **Advanced Mitigation Technologies**
   - Machine learning detection
   - Behavioural analysis systems
   - Real-time threat intelligence
   - Automated response systems

8. **Collaborative Defence Initiatives**
   - Industry threat sharing
   - DNS abuse reporting systems
   - Coordinated response frameworks
   - Legal and policy developments

### Cloud and Edge Computing Impact (8 slides)
9. **Cloud-Native DNS Services**
   - Serverless DNS implementations
   - Container-based deployments
   - Microservices architecture
   - Edge computing integration

10. **Global DNS Distribution**
    - Edge DNS optimisation
    - CDN integration strategies
    - Latency reduction techniques
    - Regional compliance considerations

### Future Architecture Considerations (10 slides)
11. **Scalability Planning**
    - Internet growth projections
    - Infrastructure scaling strategies
    - Technology adoption timelines
    - Investment planning frameworks

12. **Security Evolution**
    - Post-quantum cryptography
    - Zero-trust network integration
    - Privacy-preserving technologies
    - Regulatory compliance evolution

13. **Operational Model Changes**
    - Automation and orchestration
    - Self-healing systems
    - Predictive maintenance
    - Skills development requirements

### Practical Lab Introduction (5 slides)
14. **Future Technology Workshop**
    - IPv6-only DNS testing
    - Experimental protocol evaluation
    - Performance comparison studies
    - Architecture design exercises

---

## Final Assessment and Course Conclusion
**Duration:** 30 minutes, at the end of the Module 12 practical session (Day 6)
**Estimated Slides:** 10-12

### Course Review (4 slides)
1. **Course Content Summary**
   - Module-by-module recap
   - Key learning objectives achieved
   - Practical skills developed
   - Knowledge integration

2. **DNS Best Practices Synthesis**
   - Security implementation checklist
   - Operational excellence guidelines
   - Performance optimisation summary
   - Future-readiness preparation

### Final Project Briefing for Day 7 (4 slides)
3. **Project Requirements Overview**
   - Infrastructure design scope
   - Security implementation requirements
   - Operational procedure documentation
   - Future technology roadmap

4. **Presentation Structure**
   - Technical design presentation
   - Implementation plan walkthrough
   - Risk assessment and mitigation
   - Q&A session guidelines

### Certification and Continuing Education (2 slides)
5. **Certification Pathways**
   - DNS Fundamentals Certificate
   - DNS Security Specialist Certificate
   - Advanced Registry Operations Certificate
   - DNS Professional Master Certificate

6. **Continuing Education Opportunities**
   - Industry conferences and events
   - Professional development resources
   - Community engagement options
   - Advanced specialisation paths

7. **Course Evaluation and Feedback**
   - Learning experience assessment
   - Content relevance evaluation
   - Instructor feedback
   - Improvement suggestions

---

## Supplementary Slide Decks

### A. Reference Materials (20 slides)
1. **DNS RFC Reference Guide**
   - Core DNS RFCs summary
   - DNSSEC specification references
   - Security-related RFCs
   - Emerging protocol standards

2. **Command Reference Quick Guide**
   - dig command options
   - nslookup usage examples
   - BIND configuration snippets
   - Troubleshooting command sequences

3. **Troubleshooting Flowcharts**
   - DNS resolution problems
   - DNSSEC validation issues
   - Performance problems
   - Security incident response

### B. Lab Exercise Templates (15 slides)
1. **Configuration Templates**
   - BIND zone file templates
   - Unbound configuration examples
   - PowerDNS setup scripts
   - Monitoring configuration samples

2. **Testing and Validation Scripts**
   - DNS functionality tests
   - Performance benchmarking scripts
   - Security validation procedures
   - Monitoring setup verification

### C. Industry Resources (10 slides)
1. **Professional Organisations**
   - DNS-OARC (DNS Operations, Analysis, and Research Center)
   - ICANN technical engagement programs
   - Regional Internet Registry training
   - Vendor-specific certification programs

2. **Online Resources and Documentation**
   - Official software documentation
   - Community forums and mailing lists
   - Technical blogs and publications
   - Research papers and studies

---

## Slide Design and Presentation Guidelines

### Visual Design Standards
- **Colour Scheme:** Professional blue and grey palette
- **Typography:** Sans-serif fonts for readability
- **Layout:** Consistent header/footer with module identification
- **Imagery:** Technical diagrams, network topology illustrations
- **Branding:** Course logo and instructor information

### Content Structure Guidelines
- **Title Slides:** Clear module and section identification
- **Content Slides:** Maximum 6 bullet points per slide
- **Diagram Slides:** Large, clear technical illustrations
- **Code Examples:** Syntax-highlighted configuration snippets
- **Summary Slides:** Key takeaways and next steps

### Interactive Elements
- **Question Slides:** Knowledge check opportunities
- **Discussion Points:** Group interaction prompts
- **Lab Transitions:** Clear practical exercise introductions
- **Assessment Markers:** Progress tracking indicators

### Presentation Delivery Notes
- **Timing Guides:** Recommended time allocation per slide
- **Speaker Notes:** Detailed explanation points
- **Demonstration Cues:** Live demo integration points
- **Interaction Prompts:** Audience engagement opportunities

---

## Total Slide Count Summary

| Module | Theory Slides | Lab Intro | Total |
|--------|---------------|-----------|-------|
| Module 1: DNS Foundations | 64 | 6 | 70 |
| Module 2: DNS Operations | 45 | 5 | 50 |
| Module 3: DNS Server Types | 50 | 5 | 55 |
| Module 4: DNS Software Platforms | 56 | 4 | 60 |
| Module 5: Advanced Operations | 52 | 3 | 55 |
| Module 6: DNS Security | 62 | 8 | 70 |
| Module 7: DNSSEC Implementation | 64 | 6 | 70 |
| Module 8: DNS Privacy | 56 | 7 | 63 |
| Module 9: Registry Operations | 60 | 7 | 67 |
| Module 10: CoCCA Systems | 45 | 5 | 50 |
| Module 11: Monitoring & Performance | 50 | 5 | 55 |
| Module 12: Emerging Technologies | 45 | 5 | 50 |
| Course Conclusion | 10 | 0 | 10 |
| **Total Core Content** | **659** | **66** | **725** |
| **Supplementary Materials** | | | **45** |
| **Grand Total** | | | **770** |

---

## Implementation Timeline

### Phase 1: Content Development (8 weeks)
- **Weeks 1-2:** Modules 1-3 slide creation and review
- **Weeks 3-4:** Modules 4-6 slide creation and review
- **Weeks 5-6:** Modules 7-9 slide creation and review
- **Weeks 7-8:** Modules 10-12 and supplementary materials

### Phase 2: Review and Refinement (4 weeks)
- **Week 9:** Technical accuracy review by subject matter experts
- **Week 10:** Instructional design review and optimisation
- **Week 11:** Visual design finalisation and branding
- **Week 12:** Final review and pilot preparation

### Phase 3: Pilot Testing (2 weeks)
- **Week 13:** First pilot delivery with selected audience
- **Week 14:** Feedback incorporation and final adjustments

### Quality Assurance Checkpoints
- **Technical Review:** DNS experts validate technical accuracy
- **Educational Review:** Instructional designers optimise learning flow
- **Visual Review:** Graphic designers ensure professional presentation
- **Accessibility Review:** Materials meet accessibility standards
- **Industry Review:** Professional community validates relevance
