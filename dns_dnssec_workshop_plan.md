# Advanced DNS/DNSSEC Workshop Plan

## Overview
This comprehensive **6-day modular training program** builds upon established curricula from ICANN, APNIC, and NSRC to provide complete DNS training from fundamentals through advanced security and registry operations. The curriculum is structured in **12 modules** following a 90-minute theory + 90-minute practical format with learning objectives based on Bloom's Taxonomy.

**Course Structure (2 modules per day):**
- **Day 1:** DNS Fundamentals - Introduction and Operations (Modules 1-2)
- **Day 2:** DNS Infrastructure - Server Types and Software Platforms (Modules 3-4) 
- **Day 3:** Advanced Operations and Security Fundamentals (Modules 5-6)
- **Day 4:** DNSSEC and DNS Privacy Technologies (Modules 7-8)
- **Day 5:** Registry Operations - EPP and COCCA Systems (Modules 9-10)
- **Day 6:** Monitoring, Emerging Technologies, and Final Assessment (Modules 11-12)

**Daily Schedule:**
- **Session 1:** 09:00-10:30 (Theory Module A)
- **Break:** 10:30-11:00
- **Session 2:** 11:00-12:30 (Practical Module A)
- **Lunch:** 12:30-14:00
- **Session 3:** 14:00-15:30 (Theory Module B)
- **Break:** 15:30-16:00
- **Session 4:** 16:00-17:30 (Practical Module B)

---

## Alternative Course Programs

The modular design allows for flexible course delivery tailored to specific audiences and organizational needs:

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

### Option B: "Advanced Registry Operations" (4 Days)
**Target Audience:** Registry operators, registrar technical staff, and DNS professionals working with domain registration systems
**Duration:** Days 3-6 of the full program
**Modules Covered:** 5-12

**Learning Outcomes:**
- Advanced DNS operations and architecture design
- Comprehensive DNSSEC implementation and management
- EPP protocol mastery and registry system operations
- COCCA platform expertise
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
3. **Complete with Advanced Registry Operations** (4 days) - Full professional competency

### Specialized Tracks:
- **Technical Operations Track:** Basic DNS → Advanced Registry Operations
- **Security Focus Track:** Basic DNS → DNS Security Intensive
- **Complete Professional Track:** Full 6-day program

### Organizational Training Options:
- **Network Team Training:** Basic DNS Workshop for entire team
- **Security Team Enhancement:** DNS Security Intensive
- **Registry Staff Development:** Advanced Registry Operations
- **Management Overview:** Day 1 theory sessions only (executive briefing)

## Target Audience
- Network/systems administrators from ISPs, RENs, Universities, or corporations
- DNS operators responsible for authoritative and/or recursive DNS installations
- Registry and registrar technical staff
- Cybersecurity professionals working with DNS infrastructure
- Network engineers seeking comprehensive DNS knowledge

## Prerequisites
- Basic understanding of TCP/IP networking concepts
- Familiarity with UNIX/Linux command line environment
- Understanding of client-server architecture
- No prior DNS experience required for foundational modules

---

## Module 1: Introduction to DNS - Foundations and Concepts
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall the purpose and history of the Domain Name System
- Identify the components of the DNS hierarchy and namespace
- List the key stakeholders in DNS management (ICANN, IANA, registries, registrars)

**Comprehension (Understand):**
- Explain how DNS translates domain names to IP addresses
- Describe the distributed and hierarchical nature of DNS
- Compare DNS with other naming systems

**Application (Apply):**
- Use basic DNS lookup tools (nslookup, dig, host)
- Trace DNS resolution from root to authoritative servers

**Analysis (Analyze):**
- Analyze the DNS resolution process step-by-step
- Examine the relationship between different DNS components

### Theory Content
- DNS history and evolution from HOSTS.TXT
- DNS namespace structure and hierarchy (root, TLD, second-level domains)
- DNS stakeholder ecosystem (ICANN, IANA, root operators, TLD operators)
- Basic DNS concepts: zones, domains, subdomains
- DNS and the broader Internet infrastructure
- Introduction to IPv4 and IPv6 address resolution

### Practical Lab
- Basic DNS lookups using command-line tools
- Tracing DNS resolution paths
- Exploring the DNS hierarchy with dig +trace
- Understanding DNS response codes and flags
- Introduction to DNS debugging methodology

---

## Module 2: DNS Operations - Zones, Records, and Data Management
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall different DNS record types and their purposes
- Identify zone file syntax and structure
- List TTL concepts and timing considerations

**Comprehension (Understand):**
- Explain the relationship between zones and domains
- Describe how DNS delegation works
- Interpret zone file contents and record formats

**Application (Apply):**
- Create and edit DNS zone files
- Configure different record types for various use cases
- Set appropriate TTL values for different scenarios

**Analysis (Analyze):**
- Analyze zone file syntax and identify errors
- Evaluate TTL strategies for different environments

**Synthesis (Create):**
- Design zone structures for complex organizations
- Develop naming conventions and zone management policies

### Theory Content
- Zone concepts: authoritative zones, delegation, glue records
- DNS record types in detail:
  - A, AAAA (address records)
  - CNAME, ALIAS (canonical names)
  - MX (mail exchange)
  - NS (name server)
  - PTR (reverse DNS)
  - TXT, SPF, DKIM, DMARC (text and email security)
  - SRV (service records)
  - CAA (certificate authority authorization)
- Zone file syntax and best practices
- TTL strategy and caching implications
- Reverse DNS and PTR record management

### Practical Lab
- Create comprehensive zone files from scratch
- Configure forward and reverse DNS zones
- Implement email-related DNS records (MX, SPF, DKIM, DMARC)
- Set up service discovery with SRV records
- Test and validate zone configurations
- TTL modification and cache behavior observation

---

## Module 3: DNS Server Types - Recursive, Authoritative, and Specialized Roles
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

**Analysis (Analyze):**
- Analyze DNS query flows in complex infrastructures
- Evaluate DNS server placement strategies

**Evaluation (Evaluate):**
- Assess DNS infrastructure requirements for different organizations
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

**Analysis (Analyze):**
- Analyze configuration requirements for different use cases
- Compare software platforms for specific deployment scenarios

**Evaluation (Evaluate):**
- Evaluate DNS software selection criteria for different environments
- Assess migration strategies between DNS platforms

**Synthesis (Create):**
- Design DNS software deployment strategies
- Develop standardized configuration templates

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
  - Performance tuning and optimization

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

## Module 5: Advanced DNS Operations and Architecture
**Duration:** 90 minutes theory + 90 minutes practical
**Prerequisites:** Completion of Modules 1-4 or equivalent experience

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall advanced DNS concepts including delegation models, anycast routing, and hidden masters
- Identify different DNS server architectures and their use cases

**Comprehension (Understand):**
- Explain the relationship between authoritative and recursive resolvers in complex networks
- Describe DNS caching mechanisms and TTL strategies

**Application (Apply):**
- Configure BIND/NSD for advanced scenarios including split-horizon DNS
- Implement DNS load balancing and failover mechanisms

**Analysis (Analyze):**
- Troubleshoot complex DNS resolution issues using dig, nslookup, and specialized tools
- Analyze DNS query patterns and performance metrics

### Theory Content
- Advanced DNS architecture patterns (hidden masters, anycast, GeoDNS)
- DNS caching strategies and optimization
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
- List common DNS security threats and attack vectors
- Recall DNS security best practices and mitigation strategies

**Comprehension (Understand):**
- Explain DNS cache poisoning, DDoS attacks, and DNS hijacking
- Describe the security implications of DNS configuration choices

**Application (Apply):**
- Configure DNS rate limiting and access controls
- Implement TSIG for secure zone transfers

**Evaluation (Evaluate):**
- Assess DNS infrastructure vulnerabilities
- Evaluate the effectiveness of DNS security measures

### Theory Content
- DNS threat landscape overview
- Cache poisoning and Kaminsky attack
- DNS DDoS attacks and mitigation
- DNS tunneling and covert channels
- Rate limiting and access control strategies

### Practical Lab
- Simulate DNS attacks in controlled environment
- Configure BIND rate limiting
- Implement TSIG authentication
- Deploy DNS monitoring and alerting

---

## Module 7: DNSSEC Implementation and Operations
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall DNSSEC key types (KSK, ZSK) and their purposes
- Identify DNSSEC resource record types (DNSKEY, RRSIG, NSEC, DS)

**Comprehension (Understand):**
- Explain the DNSSEC validation process and chain of trust
- Describe key rollover procedures and timing considerations

**Application (Apply):**
- Sign DNS zones using DNSSEC
- Configure recursive resolvers for DNSSEC validation

**Synthesis (Create):**
- Develop DNSSEC key management policies
- Design DNSSEC deployment strategies for complex organizations

### Theory Content
- DNSSEC cryptographic foundations
- Key Signing Key (KSK) and Zone Signing Key (ZSK) management
- DNSSEC validation algorithm and chain of trust
- Key rollover strategies (pre-published, double signature)
- DNSSEC policy framework development

### Practical Lab
- Manual zone signing with dnssec-tools
- Automated signing with BIND inline-signing
- Configure DNSSEC validation on recursive resolvers
- Perform emergency key rollover simulation
- DNSSEC troubleshooting exercises

---

## Module 8: DNS Privacy and Encryption Technologies
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall DNS privacy protocols (DoT, DoH, DNSCrypt)
- Identify implementation differences between privacy protocols

**Comprehension (Understand):**
- Explain the privacy implications of traditional DNS
- Compare DoT vs DoH implementation approaches

**Application (Apply):**
- Configure DNS over TLS (DoT) on port 853
- Implement DNS over HTTPS (DoH) endpoints

**Analysis (Analyze):**
- Evaluate privacy protocol performance and security trade-offs
- Analyze enterprise deployment considerations for encrypted DNS

### Theory Content
- DNS privacy landscape and threats
- DNS over TLS (DoT) - RFC 7858 implementation
- DNS over HTTPS (DoH) - RFC 8484 considerations
- DNSCrypt protocol overview
- Enterprise policy implications of encrypted DNS

### Practical Lab
- Configure Unbound for DoT support
- Set up DoH proxy using nginx/apache
- Test encrypted DNS clients (Android, iOS, browsers)
- Monitor encrypted DNS traffic patterns
- Policy configuration for enterprise DoT/DoH deployment

---

## Module 9: Registry Operations and EPP Protocol
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall EPP protocol structure and command syntax
- Identify registry operational processes and workflows

**Comprehension (Understand):**
- Explain the registrar-registry relationship model
- Describe domain lifecycle management processes

**Application (Apply):**
- Execute EPP commands for domain management
- Configure EPP client connections with proper authentication

**Analysis (Analyze):**
- Analyze EPP transaction logs for operational insights
- Evaluate registry system performance and capacity planning

### Theory Content
- Registry-registrar operational model
- EPP protocol architecture and security
- Domain lifecycle management (registration, renewal, transfer, deletion)
- Grace periods and redemption processes
- Registry policy implementation through EPP

### Practical Lab
- EPP client configuration and authentication
- Domain registration and management workflows
- Transfer and renewal operations
- Grace period and deletion exercises
- Registry reporting and monitoring

---

## Module 10: Advanced Registry Systems - COCCA Backend Operations
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall COCCA architecture components and data models
- Identify COCCA administrative functions and interfaces

**Comprehension (Understand):**
- Explain COCCA's role in ccTLD management
- Describe COCCA integration with registrar systems

**Application (Apply):**
- Navigate COCCA administrative interfaces
- Configure COCCA policy settings and business rules

**Synthesis (Create):**
- Design COCCA deployment strategies for new TLDs
- Develop operational procedures for COCCA-based registries

### Theory Content
- COCCA platform overview and architecture
- ccTLD management best practices
- COCCA database schema and data relationships
- Integration with WHMCS and other registrar platforms
- Billing and financial management in COCCA

### Practical Lab
- COCCA installation and configuration
- Registry policy configuration
- WHMCS-COCCA integration setup
- Registrar management and onboarding
- Operational monitoring and maintenance procedures

---

## Module 11: DNS Monitoring, Incident Response, and Performance Optimization
**Duration:** 90 minutes theory + 90 minutes practical

### Learning Objectives (Bloom's Taxonomy)
**Knowledge (Remember):**
- Recall DNS monitoring metrics and KPIs
- Identify incident response procedures for DNS outages

**Application (Apply):**
- Implement comprehensive DNS monitoring solutions
- Execute incident response procedures

**Analysis (Analyze):**
- Analyze DNS performance data and identify optimization opportunities
- Evaluate the effectiveness of monitoring and alerting systems

**Evaluation (Evaluate):**
- Assess DNS infrastructure resilience and redundancy
- Evaluate business continuity planning for DNS services

### Theory Content
- DNS monitoring strategy and metrics
- Performance optimization techniques
- Incident response planning and procedures
- Capacity planning for DNS infrastructure
- Business continuity and disaster recovery

### Practical Lab
- Deploy DNS monitoring with tools like RIPE Atlas, ThousandEyes
- Configure alerting and notification systems
- Conduct tabletop incident response exercises
- Performance optimization workshops
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
- Design future-ready DNS architectures

### Theory Content
- DNS-over-QUIC (DoQ) and HTTP/3 implications
- Encrypted SNI and privacy enhancements
- DNS filtering and abuse mitigation technologies
- IPv6-only DNS operations
- AI/ML applications in DNS operations

### Practical Lab
- Experimental DoQ implementations
- IPv6-only DNS testing
- DNS abuse detection and mitigation tools
- Next-generation DNS server evaluation
- Future technology proof-of-concept development

---

## Assessment and Certification
- **Daily Assessment:** Practical lab completion and competency demonstration
- **Mid-course Check:** Day 3 practical assessment covering fundamentals
- **Final Project:** Day 6 - Design and implement a complete DNS infrastructure solution
- **Peer Review:** Presentation of implemented solutions to group
- **Written Examination:** Comprehensive test covering all modules (optional certification track)

## Required Equipment and Environment
- **Laptops:** WiFi-capable with SSH client support (tablets not suitable)
- **Lab Network:** Isolated network environment for hands-on exercises
- **Virtual Machines:** Pre-configured with BIND, Unbound, PowerDNS, and other DNS software
- **Certificates:** Course completion certificates provided
- **Internet Access:** Required for accessing external DNS resources and documentation

## Workshop Logistics
- **Duration:** 6 consecutive days (Monday-Saturday recommended)
- **Class Size:** Maximum 20 participants for effective hands-on instruction
- **Equipment:** Participants must bring laptops capable of running SSH clients
- **Materials:** All lab exercises, documentation, and software provided
- **Language:** Conducted in English with materials available for translation

## Identified Gaps and Recommendations

### Gaps in Current Training Landscape
1. **Limited Integration Training:** Few programs combine registry operations (EPP/COCCA) with DNS security
2. **Privacy Protocol Coverage:** DoT/DoH training often missing from traditional DNS curricula
3. **Operational Focus:** More emphasis needed on day-to-day operations vs. initial deployment
4. **Incident Response:** Limited practical incident response training in DNS context
5. **Modern Threats:** Insufficient coverage of current DNS abuse and attack patterns

### Recommendations
1. **Expand Hands-on Components:** Increase practical lab time from current industry standard
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
- **Advanced Workshops:** Specialized sessions on specific topics
- **Community Engagement:** Participation in DNS-OARC, ICANN meetings
- **Online Resources:** Access to updated materials and virtual labs

---

*This curriculum builds upon the foundational work of ICANN Technical Engagement, APNIC Academy, and NSRC training programs while addressing current operational needs and emerging technologies in the DNS ecosystem.*

---

# Appendix A: Laboratory Requirements and Specifications

## Lab Infrastructure Overview

### Network Environment
- **Isolated Lab Network:** 192.168.100.0/24 (recommended)
- **Internet Gateway:** Limited access for external DNS queries and updates
- **VLAN Segmentation:** Separate lab segments for different exercises
- **Virtual Machine Host:** VMware vSphere, VirtualBox, or KVM-based infrastructure
- **Lab Reset Capability:** Snapshots for quick environment restoration

### Base Virtual Machine Requirements
- **Operating System:** Ubuntu 22.04 LTS or CentOS Stream 9
- **RAM:** Minimum 2GB per VM, 4GB recommended
- **Storage:** 20GB minimum per VM
- **CPU:** 2 vCPU cores minimum
- **Network:** Bridged networking with lab network access

---

## Module 1: Introduction to DNS - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 1 Ubuntu desktop VM per participant
- **Shared Infrastructure:** 1 root server simulator, 1 TLD server simulator
- **Tools Pre-installed:** dig, nslookup, host, wireshark, tcpdump

### Lab Exercises

#### Lab 1.1: DNS Hierarchy Exploration (30 minutes)
**Objective:** Understand DNS hierarchy through practical queries
**Resources Needed:**
- Access to real DNS infrastructure via internet
- Pre-configured dig and nslookup tools
**Exercise Steps:**
1. Query root servers using `dig . NS`
2. Query TLD servers for various TLDs
3. Trace resolution path using `dig +trace example.com`
4. Compare IPv4 and IPv6 root servers

#### Lab 1.2: DNS Response Analysis (30 minutes)
**Objective:** Analyze DNS responses and understand flags
**Resources Needed:**
- Packet capture capability (Wireshark)
- Sample DNS queries and responses
**Exercise Steps:**
1. Capture DNS queries using Wireshark
2. Analyze DNS response codes and flags
3. Compare authoritative vs non-authoritative responses
4. Examine DNS over IPv4 vs IPv6

#### Lab 1.3: DNS Debugging Fundamentals (30 minutes)
**Objective:** Learn basic DNS troubleshooting
**Resources Needed:**
- Broken DNS scenarios (pre-configured)
- Multiple DNS tools
**Exercise Steps:**
1. Diagnose non-responsive domains
2. Identify delegation issues
3. Compare results from different DNS servers
4. Document troubleshooting methodology

---

## Module 2: DNS Operations - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 1 Ubuntu server VM per participant
- **Software:** BIND 9 utilities, text editors (vim/nano)
- **Zone Files:** Template zone files and examples

### Lab Exercises

#### Lab 2.1: Zone File Creation and Management (45 minutes)
**Objective:** Create and manage DNS zone files
**Resources Needed:**
- Zone file templates
- Domain name assignments for each participant
- Zone file validation tools
**Exercise Steps:**
1. Create forward zone file for assigned domain
2. Add various record types (A, AAAA, CNAME, MX, TXT)
3. Create reverse zone file
4. Validate zone file syntax using named-checkzone

#### Lab 2.2: TTL and Caching Behavior (30 minutes)
**Objective:** Understand TTL impact on DNS caching
**Resources Needed:**
- DNS server with configurable TTLs
- Cache monitoring tools
**Exercise Steps:**
1. Configure records with different TTL values
2. Monitor cache behavior using dig +norecurse
3. Observe TTL countdown in cached responses
4. Implement TTL strategy for different record types

#### Lab 2.3: Email DNS Records Configuration (15 minutes)
**Objective:** Configure email-related DNS records
**Resources Needed:**
- Email server scenarios
- SPF, DKIM, DMARC record templates
**Exercise Steps:**
1. Configure MX records for mail routing
2. Implement SPF records for sender authentication
3. Add DKIM signatures to DNS
4. Configure DMARC policy records

---

## Module 3: DNS Server Types - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Ubuntu server VMs per participant
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
1. Configure primary authoritative server
2. Set up secondary server with zone transfers
3. Test automatic zone synchronization
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
- **Participant VMs:** 3 Ubuntu server VMs per participant
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
4. Performance optimization and tuning

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
- **Participant VMs:** 4 Ubuntu server VMs per participant
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

#### Lab 5.2: Hidden Master Architecture (30 minutes)
**Objective:** Implement hidden master DNS architecture
**Resources Needed:**
- Hidden master server (not publicly accessible)
- Multiple public slave servers
- Zone transfer automation
**Exercise Steps:**
1. Configure hidden master server
2. Set up automated zone transfers to public slaves
3. Implement security restrictions
4. Test update propagation

#### Lab 5.3: DNS Performance Optimization (15 minutes)
**Objective:** Optimize DNS server performance
**Resources Needed:**
- Performance monitoring tools
- Load testing utilities
- Configuration optimization guides
**Exercise Steps:**
1. Baseline DNS server performance
2. Implement caching optimizations
3. Tune server parameters for high load
4. Conduct performance testing and analysis

---

## Module 6: DNS Security Fundamentals - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Ubuntu server VMs per participant
- **Security Tools:** nmap, tcpdump, DNS security scanners
- **Attack Simulation:** Controlled environment for security testing

### Lab Exercises

#### Lab 6.1: DNS Attack Simulation and Detection (45 minutes)
**Objective:** Understand DNS attacks and detection methods
**Resources Needed:**
- Vulnerable DNS server setup
- Attack simulation tools
- Network monitoring capabilities
**Exercise Steps:**
1. Simulate DNS cache poisoning attempts
2. Conduct DNS amplification attack demonstration
3. Implement rate limiting and access controls
4. Monitor and analyze attack patterns

#### Lab 6.2: DNS Security Hardening (30 minutes)
**Objective:** Implement DNS security best practices
**Resources Needed:**
- BIND 9 with security features
- Firewall configuration tools
- Security configuration templates
**Exercise Steps:**
1. Configure DNS server access controls
2. Implement response rate limiting
3. Set up secure zone transfers with TSIG
4. Enable security logging and monitoring

#### Lab 6.3: DNS Filtering and Response Policy Zones (15 minutes)
**Objective:** Implement DNS-based security filtering
**Resources Needed:**
- RPZ-enabled DNS server
- Threat intelligence feeds
- Policy configuration examples
**Exercise Steps:**
1. Configure Response Policy Zones (RPZ)
2. Implement DNS filtering policies
3. Test malware domain blocking
4. Monitor and analyze filtered queries

---

## Module 7: DNSSEC Implementation - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 3 Ubuntu server VMs per participant
- **Software:** BIND 9 with DNSSEC support, dnssec-tools
- **PKI Infrastructure:** Key generation and management tools

### Lab Exercises

#### Lab 7.1: DNSSEC Zone Signing (45 minutes)
**Objective:** Manually sign DNS zones with DNSSEC
**Resources Needed:**
- Unsigned zone files
- dnssec-keygen and dnssec-signzone utilities
- Key storage and management procedures
**Exercise Steps:**
1. Generate KSK and ZSK keys
2. Sign zone files manually
3. Publish DNSKEY records
4. Verify signed zone integrity

#### Lab 7.2: DNSSEC Validation Configuration (30 minutes)
**Objective:** Configure DNSSEC validation on recursive resolvers
**Resources Needed:**
- Recursive DNS server (BIND/Unbound)
- Trust anchor configuration
- DNSSEC validation testing tools
**Exercise Steps:**
1. Configure trust anchors
2. Enable DNSSEC validation
3. Test validation with signed/unsigned zones
4. Troubleshoot validation failures

#### Lab 7.3: DNSSEC Key Rollover Simulation (15 minutes)
**Objective:** Perform DNSSEC key rollover procedures
**Resources Needed:**
- Signed zones with existing keys
- Automated key rollover scripts
- Timing and scheduling tools
**Exercise Steps:**
1. Plan key rollover timeline
2. Execute ZSK rollover procedure
3. Simulate emergency KSK rollover
4. Verify rollover success and timing

---

## Module 8: DNS Privacy and Encryption - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Ubuntu server VMs per participant
- **Software:** Unbound with DoT support, nginx for DoH, stunnel
- **Certificates:** TLS certificates for encrypted connections

### Lab Exercises

#### Lab 8.1: DNS over TLS (DoT) Implementation (45 minutes)
**Objective:** Configure and test DNS over TLS
**Resources Needed:**
- Unbound with TLS support
- TLS certificates
- DoT client testing tools
**Exercise Steps:**
1. Configure Unbound for DoT on port 853
2. Generate and install TLS certificates
3. Test DoT connectivity with various clients
4. Monitor encrypted DNS traffic

#### Lab 8.2: DNS over HTTPS (DoH) Setup (30 minutes)
**Objective:** Implement DNS over HTTPS service
**Resources Needed:**
- nginx or apache web server
- DoH proxy software
- HTTPS certificates
- DoH client tools
**Exercise Steps:**
1. Configure DoH proxy with nginx
2. Set up HTTPS certificates
3. Test DoH functionality with browsers
4. Compare DoH vs DoT performance

#### Lab 8.3: Privacy Protocol Comparison (15 minutes)
**Objective:** Compare different DNS privacy protocols
**Resources Needed:**
- Multiple privacy protocol implementations
- Network analysis tools
- Performance testing utilities
**Exercise Steps:**
1. Test traditional DNS vs DoT vs DoH
2. Analyze network traffic patterns
3. Measure performance impact
4. Evaluate deployment considerations

---

## Module 9: Registry Operations and EPP - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Ubuntu server VMs per participant
- **Software:** EPP server software, EPP client tools
- **Database:** Registry database with domain data

### Lab Exercises

#### Lab 9.1: EPP Server Configuration (45 minutes)
**Objective:** Set up and configure EPP server
**Resources Needed:**
- EPP server software (CoCCA or alternative)
- Database backend
- TLS certificates for EPP
**Exercise Steps:**
1. Install and configure EPP server
2. Set up database schema
3. Configure TLS security
4. Test basic EPP connectivity

#### Lab 9.2: EPP Client Operations (30 minutes)
**Objective:** Perform domain management via EPP
**Resources Needed:**
- EPP client software
- Test registrar credentials
- Sample domain portfolio
**Exercise Steps:**
1. Connect to EPP server with client
2. Perform domain registration workflow
3. Execute transfer and renewal operations
4. Manage contact and nameserver objects

#### Lab 9.3: EPP Transaction Monitoring (15 minutes)
**Objective:** Monitor and analyze EPP transactions
**Resources Needed:**
- EPP logging and monitoring tools
- Transaction analysis scripts
- Reporting utilities
**Exercise Steps:**
1. Enable comprehensive EPP logging
2. Monitor real-time transactions
3. Generate registry reports
4. Analyze transaction patterns and performance

---

## Module 10: Advanced Registry Systems - COCCA - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 3 Ubuntu server VMs per participant
- **Software:** COCCA registry software, PostgreSQL, web server
- **Integration:** WHMCS or similar billing system

### Lab Exercises

#### Lab 10.1: COCCA Installation and Configuration (45 minutes)
**Objective:** Deploy complete COCCA registry system
**Resources Needed:**
- COCCA software package
- PostgreSQL database
- Java application server (Resin)
- Web server configuration
**Exercise Steps:**
1. Install COCCA software stack
2. Configure database and application server
3. Set up initial registry configuration
4. Test basic registry functionality

#### Lab 10.2: Registry Policy Configuration (30 minutes)
**Objective:** Configure registry policies and business rules
**Resources Needed:**
- COCCA administration interface
- Policy configuration templates
- Grace period and pricing examples
**Exercise Steps:**
1. Configure domain lifecycle policies
2. Set up pricing and billing rules
3. Implement grace period configurations
4. Test policy enforcement

#### Lab 10.3: WHMCS-COCCA Integration (15 minutes)
**Objective:** Integrate COCCA with registrar billing system
**Resources Needed:**
- WHMCS installation
- COCCA EPP module for WHMCS
- Test registrar account
**Exercise Steps:**
1. Install COCCA-WHMCS EPP module
2. Configure registrar connection settings
3. Test domain registration workflow
4. Verify billing integration

---

## Module 11: DNS Monitoring and Performance - Lab Requirements

### Lab Environment Setup
- **Participant VMs:** 2 Ubuntu server VMs per participant
- **Software:** Prometheus, Grafana, RIPE Atlas tools, custom monitoring scripts
- **Monitoring:** Network monitoring capabilities

### Lab Exercises

#### Lab 11.1: DNS Monitoring Implementation (45 minutes)
**Objective:** Deploy comprehensive DNS monitoring
**Resources Needed:**
- Prometheus and Grafana
- DNS-specific exporters
- Alerting configuration
**Exercise Steps:**
1. Set up Prometheus for DNS metrics collection
2. Configure Grafana dashboards
3. Implement alerting rules
4. Test monitoring and alerting scenarios

#### Lab 11.2: Performance Analysis and Optimization (30 minutes)
**Objective:** Analyze and optimize DNS performance
**Resources Needed:**
- Performance testing tools
- Query log analysis scripts
- Optimization configuration examples
**Exercise Steps:**
1. Conduct DNS performance baseline testing
2. Analyze query patterns and bottlenecks
3. Implement performance optimizations
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
- **Participant VMs:** 2 Ubuntu server VMs per participant
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
4. Analyze IPv6 vs dual-stack performance

#### Lab 12.2: Experimental DNS Technologies (30 minutes)
**Objective:** Explore cutting-edge DNS technologies
**Resources Needed:**
- DNS-over-QUIC experimental implementations
- Encrypted SNI testing tools
- Next-generation DNS software
**Exercise Steps:**
1. Test DNS-over-QUIC implementations
2. Explore encrypted SNI capabilities
3. Evaluate new DNS server software
4. Assess migration considerations

#### Lab 12.3: Future-Ready Architecture Design (15 minutes)
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
- **Commercial:** COCCA (licensing required for full features)
- **Operating Systems:** Ubuntu/CentOS (freely available)

### Lab Management Tools
- **VM Management:** vSphere, VirtualBox, or KVM management
- **Network Monitoring:** Traffic analysis and monitoring tools
- **Lab Reset Scripts:** Automated environment restoration
- **Progress Tracking:** Lab completion monitoring system