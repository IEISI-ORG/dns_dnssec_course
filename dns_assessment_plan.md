# Advanced DNS/DNSSEC Workshop Assessment Plan

## Overview
This assessment plan sets out how the Advanced DNS/DNSSEC Workshop is assessed, so that participants demonstrate both theoretical knowledge and practical competency across all learning objectives. The assessment framework aligns with Bloom's Taxonomy progression and industry best practices for technical certification.

## Assessment Philosophy
- **Competency-Based:** Focus on demonstrable skills rather than memorisation
- **Progressive Evaluation:** Building complexity from basic concepts to advanced operations
- **Practical Application:** Emphasis on real-world scenarios and problem-solving
- **Multiple Assessment Types:** Varied evaluation methods to accommodate different learning styles
- **Industry Relevance:** Assessments mirror actual DNS operational challenges

---

## Assessment Framework

### Learning Outcome Categories
1. **Technical Knowledge:** Understanding of DNS concepts, protocols, and technologies
2. **Operational Skills:** Ability to configure, manage, and troubleshoot DNS infrastructure
3. **Security Implementation:** DNSSEC deployment and DNS security best practices
4. **Problem-Solving:** Analytical thinking and troubleshooting methodology
5. **Professional Application:** Real-world scenario handling and decision-making

### Assessment Methods
- **Practical Lab Assessments:** Hands-on skill demonstration
- **Written Examinations:** Knowledge verification and theory understanding
- **Project-Based Evaluation:** Applying the course's skills in one integrated project
- **Peer Assessment:** Collaborative learning and knowledge sharing
- **Continuous Monitoring:** Ongoing evaluation throughout the course

---

## Daily Assessment Structure

**Timing** follows the Program Facts section of `dns_dnssec_workshop_plan.md`:
- **Practical assessments** are graded lab work. The minutes shown are the part of that module's practical session that is assessed, not extra time.
- **Knowledge checks**, the **mid-course assessment** (Day 3) and the **case study** (Day 5) take the last 15-30 minutes of Session 3.
- The **Final Project** runs on the Day 7 morning.

### Day 1: DNS Fundamentals Assessment
**Modules 1-2: Introduction to DNS and DNS Operations**

#### Practical Assessment 1A: DNS Hierarchy and Query Analysis (30 minutes)
**Assessment Type:** Hands-on lab evaluation
**Learning Objectives Tested:**
- DNS hierarchy understanding (Remember/Understand)
- Query tracing and analysis (Apply/Analyse)
- Tool usage proficiency (Apply)

**Tasks** (assessed from the Module 1 labs; see Appendix A of `dns_dnssec_workshop_plan.md` and `labs/module01/README.md`):
1. Trace the resolution of a name from the root to an authoritative answer, by hand with `dig +norec`, naming the server, referral or answer, and glue at each step (Lab 1.1; offline: `www.good.example` through the lab hierarchy) (5 points)
2. Identify the fault in each of the five lab delegations with evidence and the party that must fix it: the Lab 1.3 worksheet (5 points). The default zone names (`alpha` to `echo.example`) and the answer key are public in the course repository, so for a graded run the instructor sets `M01_FAULT_LABELS` to five names the class has not seen and puts them on the lab sheet (`labs/instructor/module01/README.md`)
3. Analyse response codes and flags: NOERROR, NODATA, NXDOMAIN, REFUSED, SERVFAIL, `aa`/`ra`/`tc`, in `dig` and in a `tshark` reading of the participant's own capture (Lab 1.2) (5 points)
4. Compare IPv4 and IPv6: A and AAAA data, the `in-addr.arpa` and `ip6.arpa` names `dig -x` builds, root server addresses, and the same query over `-4` and `-6` where the classroom has IPv6 (Labs 1.1-1.2) (5 points)

**Assessment Criteria:**
- **Excellent (18-20 points):** Complete accurate analysis with detailed explanations
- **Good (14-17 points):** Mostly correct with minor gaps in understanding
- **Satisfactory (10-13 points):** Basic competency demonstrated with some errors
- **Needs Improvement (<10 points):** Significant gaps requiring additional training

#### Practical Assessment 1B: Zone File Creation and Management (30 minutes)
**Assessment Type:** Configuration and validation exercise
**Learning Objectives Tested:**
- Zone file syntax and structure (Remember/Understand)
- Record type implementation (Apply)
- DNS data management (Apply/Analyse)

**Tasks** (assessed from the Module 2 labs; see Appendix A of `dns_dnssec_workshop_plan.md` and `labs/module02/README.md`):
1. Write `teamNN.example` with every record type of Lab 2.1 (A, AAAA, CNAME, MX, CAA, HTTPS, SRV) and load it on VM 1: `named-checkzone` OK with no warnings, `aa` from VM 1, NOERROR through the lab resolver, the registry's NS and glue matching the zone (10 points)
2. Implement reverse DNS: `2.0.192.in-addr.arpa` and the team's `ip6.arpa` zone, PTR records that match the forward data (Lab 2.2) (5 points)
3. Configure the email records: MX, SPF, a null MX for a name that takes no mail, DKIM (key made on VM 1, published as split strings, read back unchanged) and DMARC (Lab 2.4) (5 points)
4. Validate and troubleshoot: name and fix the seven mistakes in `broken/db.broken.example` until it passes `named-checkzone -k fail` with no warnings (Lab 2.2) (5 points). The file and its answers are public in the course repository (kit, presenter notes, harness), so the task is assessed by observation, not by the result alone: the participant shows each `named-checkzone` pass and explains each mistake and its fix in their own words

**Assessment Criteria:**
- Syntax accuracy and completeness
- Proper record type usage
- Error identification and correction
- Best practice implementation

#### Knowledge Check 1: DNS Fundamentals Quiz (15 minutes)
**Timing:** the last 15 minutes of Session 3 on Day 1, which is the Module 2 theory session; the Module 2 deck reserves them in its agenda. The quiz is handed out on paper and is not in the deck. Question bank: `assessment/knowledge-check-1.md` (two variants per question; the instructor picks one of each). Answer key: `assessment/instructor/knowledge-check-1-key.md`, not handed out; the repository is public, so for a graded paper the instructor also changes names or numbers in some questions
**Assessment Type:** Multiple choice and short answer
**Question Categories:**
- DNS hierarchy and delegation (5 questions)
- Record types and their purposes (5 questions)
- TTL concepts and caching (3 questions)
- DNS stakeholder roles (2 questions)

**Passing Criteria:** 70% minimum score required

---

### Day 2: DNS Infrastructure Assessment
**Modules 3-4: DNS Server Types and Software Platforms**

#### Practical Assessment 2A: DNS Server Configuration (45 minutes)
**Assessment Type:** Multi-platform server setup
**Learning Objectives Tested:**
- Server type understanding (Understand)
- Configuration skills (Apply)
- Architecture implementation (Apply/Analyse)

**Tasks** (task 1 and part of task 4 are assessed from the Module 3 labs, tasks 2-3 and the rest of task 4 from the Module 4 labs; see Appendix A of `dns_dnssec_workshop_plan.md`, `labs/module03/README.md`, `labs/module04/README.md`):
1. Configure BIND authoritative servers with a primary/secondary setup: VM 2 as a secondary for `teamNN.example` (Lab 3.3): `allow-transfer` and `also-notify` on VM 1, the transfer and NOTIFY shown in both servers' logs, the same serial with `aa` from both, and an explanation of why VM 2 is a stealth server (not in the NS set) and what Lab 3.4 showed about it (10 points). Assess before the Lab 3.4 clean-up
2. Set up an Unbound recursive resolver with forwarding (Lab 4.2): Unbound on VM 2 next to BIND (port 5300) with `access-control`, `domain-insecure` and a stub zone for the lab TLD, then a forward zone to the lab resolver; the participant shows the same answer from Unbound and BIND, points out Unbound's query in VM 1's query log (`-E(0)DC`) and who asked VM 1 when forwarding, and explains why forwarding to the registry hands the client a referral where BIND gives SERVFAIL (8 points)
3. Implement PowerDNS with a database backend (Lab 4.3): PowerDNS Authoritative with the SQLite backend (`gsqlite3`) on VM 1 port 5300, `teamNN.example` imported from BIND's zone file and served with `aa` (after `pdns_control rediscover`), the `zonediff.sh` migration check showing the changed HTTPS record and its fix through the API, and a record added through the API with the serial one higher (SOA-EDIT-API set to `INCREASE`); the API key made on the VM, never shown on screen or written to the kit (7 points). SQLite replaces the original MySQL: the generic SQL backends share one schema, and a database server per team would add a database password to manage
4. Test and validate all configurations: for the Module 3 part, the participant shows from VM 1's query log who queried VM 1 with a static-stub zone and with conditional forwarding (Labs 3.1-3.2); for the Module 4 part, Unbound's answer from PowerDNS against BIND's NXDOMAIN for the API-added name, and the Lab 4.4 clean-up (nothing on port 5300, BIND as Module 3 left it) (5 points)

**Assessment Criteria:**
- Configuration accuracy and completeness
- Proper service functionality
- Security implementation
- Documentation and explanation quality

#### Practical Assessment 2B: DNS Software Comparison (30 minutes)
**Assessment Type:** Analysis and evaluation exercise
**Learning Objectives Tested:**
- Platform comparison (Analyse/Evaluate)
- Decision-making skills (Evaluate)
- Technical communication (Create)

**Tasks:**
Assessed from Lab 4.4's comparison sheet (`labs/module04/comparison-sheet.md`, one per team, with the assessor's notes) and discussion, and the deck's "Which Software Where?" exercise (Module 4 section 6).
1. Compare the characteristics of BIND, Unbound and PowerDNS from the labs and the vendors' documentation: roles, data store, control tool, statistics, defaults, support life. Performance claims only from measurements on the participant's own servers with the set-up stated (date, versions, hardware, query file); no vendor benchmark figures (8 points)
2. Recommend software for given scenarios (the four organisations of the exercise, or the instructor's own), naming the data path and one accepted risk (7 points)
3. Document configuration differences (the BIND and Unbound side-by-side table) and migration considerations (the HTTPS import finding, AXFR or absolute-name import, comparing answers before moving the delegation) (5 points)
4. Answer the Lab 4.4 discussion question to the group: which software for a zone the participant runs, and what to test before switching (about one minute per team, at the end of Lab 4.4) (5 points)

#### Knowledge Check 2: Infrastructure Quiz (15 minutes)
**Timing:** the last 15 minutes of Day 2 Session 3 (Module 4 theory: 75 minutes of content, then the quiz on paper; the questions are not in the deck)
**Question bank:** `assessment/knowledge-check-2.md` (12 questions, two variants each; the instructor picks one of each). **Answer key:** `assessment/instructor/knowledge-check-2-key.md`, not handed out; the repository is public, so for a graded paper the instructor also changes names or addresses in some questions. Pass: 9 of 12
**Assessment Type:** Scenario-based questions
**Focus Areas:**
- DNS server roles and relationships
- Software platform capabilities
- Architecture decision factors
- Performance considerations

---

### Day 3: Advanced Operations and Security Assessment
**Modules 5-6: Advanced DNS Operations and Security Fundamentals**

#### Practical Assessment 3A: Advanced Architecture Implementation (45 minutes)
**Assessment Type:** Complex configuration exercise
**Learning Objectives Tested:**
- Advanced architecture design (Apply/Analyse)
- Operating a distributed service: propagation, views, anycast routing (Apply)
- Troubleshooting skills (Analyse)

**Tasks** (assessed from the Module 5 labs on the participant's own VMs; see Appendix A of `dns_dnssec_workshop_plan.md` and `labs/module05/README.md`):
1. Run the anycast service (Lab 5.3): bring up `anycast-lab.sh`, show from the routers' tables and NSID which site answers each city and why (AS-path length), stop one site and show the health check withdrawing its route and the other site taking its catchment; name two things the single-VM lab cannot show about Internet anycast (8 points)
2. Configure a hidden primary (Lab 5.1): VM 2 as the primary for `hp.teamNN.example` with `notify explicit`, `also-notify`, `allow-transfer` and `allow-query` for VM 1 only; VM 1 as the listed secondary with the delegation in `teamNN.example`; show the lab resolver's answer coming from VM 1, the refused transfer from VM 2's own address, and a change reaching VM 1 by NOTIFY; explain the result of a change without a new serial (7 points). Assess before the Lab 5.1 clean-up
3. Set up split horizon with views (Lab 5.2): two views on VM 1 (VM 2 internal, everyone else external, the reverse zones shared with `in-view`), the root-hints include moved into a view; show `intranet` through VM 2 and NXDOMAIN through the lab resolver, and explain why the view follows the resolver's address, not the user's (5 points). Assess before the Lab 5.2 clean-up
4. Troubleshoot the anycast faults (Lab 5.4): the instructor sets three faults one at a time with `labs/module05/instructor/faults.sh` and gives only the symptom. Graded on the evidence and the method, not the named cause alone: the commands run and their order (both cities with `+nsid`, the SOA at each site's own address, the routers' paths and forwarding, the health logs), what each showed and which causes it ruled out, then the fix checked from both cities; finally the lab removed and both VMs as Module 4 left them (5 points). The repository is public, so the faults and answers can be read in advance; the instructor sets them in an order of their choosing without naming them

#### Practical Assessment 3B: DNS Security Implementation (45 minutes)
**Assessment Type:** Security configuration and testing
**Learning Objectives Tested:**
- Security threat understanding (Understand/Analyse)
- Security implementation (Apply)
- Attack mitigation (Apply/Evaluate)

**Tasks:** (same tools and lab kit as Labs 6.1-6.5, on the participant's own VMs; any load stays within `dnsperf -Q 50 -l 10` against the participant's own server)
1. Restrict a resolver to its clients and make an authoritative server non-recursive; show REFUSED from an outside address and the "queries rejected" counters; enable RRL and show the drop and truncation counters under the capped load (8 points)
2. Set up a TSIG-protected zone transfer with a key made by `tsig-keygen`; show a refused unsigned transfer and a successful signed one, and explain BADSIG and BADTIME (6 points)
3. Configure security logging (`security`, `rate-limit`, `rpz`, `xfer-out`) and an RPZ zone that blocks a given name; show the log line for a rewrite (6 points)
4. From a provided capture or log, identify the attack (amplification, random-subdomain flood or tunnelling), the signs that show it, and the response (5 points)

#### Mid-Course Assessment: Integrated Practical (30 minutes)
**Assessment Type:** Integrated skills demonstration
**Scenario:** Design and implement DNS infrastructure for fictional organisation
**Requirements:**
- Multi-site DNS architecture
- Security considerations
- Performance optimisation
- Documentation and presentation

**Evaluation Criteria:**
- Technical accuracy (40%)
- Security implementation (30%)
- Documentation quality (20%)
- Presentation and explanation (10%)

---

### Day 4: DNSSEC and Privacy Technologies Assessment
**Modules 7-8: DNSSEC Implementation and DNS Privacy**

#### Practical Assessment 4A: DNSSEC Implementation (45 minutes)
**Assessment Type:** End-to-end DNSSEC deployment
**Learning Objectives Tested:**
- DNSSEC concepts and implementation (Apply/Analyse)
- Key management (Apply)
- Validation configuration (Apply)

**Tasks:**
1. Generate DNSSEC keys and sign zone (10 points)
2. Configure DNSSEC validation on recursive resolver (8 points)
3. Perform key rollover procedure (7 points)
4. Troubleshoot DNSSEC validation failures (5 points)

#### Practical Assessment 4B: DNS Privacy Implementation (45 minutes)
**Assessment Type:** Encryption protocol deployment
**Learning Objectives Tested:**
- Privacy protocol understanding (Understand/Apply)
- Encryption implementation (Apply)
- Traffic and privacy analysis (Analyse/Evaluate)

**Tasks:** (same tools and lab kit as Labs 8.2-8.5, on a fresh resolver)
1. Configure DNS over TLS on BIND with a certificate that carries the resolver's name and IP address; show a strict `kdig` query succeeding and a wrong-name query failing (8 points)
2. Add a DNS over HTTPS endpoint (`/dns-query`, `application/dns-message`); query it with GET and POST (8 points)
3. Point a client at it: Unbound forwarding over TLS, and DDR records for `_dns.resolver.arpa` that pass verified discovery (6 points)
4. From a packet capture, state what DoT hid and what it left visible, and show the effect of padding on record sizes (8 points)

#### Knowledge Check 4: Security and Privacy Quiz (20 minutes)
**Assessment Type:** Technical scenarios and analysis
**Question bank:** `assessment/knowledge-check-4.md` (12 questions, two variants each; the instructor picks one of each). **Answer key:** `assessment/instructor/knowledge-check-4-key.md`, not handed out; the repository is public, so for a graded paper the instructor also changes names or numbers in some questions. Pass: 9 of 12 (75%, the Security Specialist threshold). The security best practices questions also draw on Module 6, because Day 3 has no quiz
**Topics:**
- DNSSEC validation chain
- Key rollover procedures
- Privacy protocol trade-offs
- Security best practices

---

### Day 5: Registry Operations Assessment
**Modules 9-10: EPP Protocol and CoCCA Systems**

#### Practical Assessment 5A: EPP Operations (assessed from the Lab 9.1-9.5 checkpoints; no separate session)
**Assessment Type:** Registry protocol implementation
**Learning Objectives Tested:**
- EPP protocol understanding (Understand/Apply)
- Domain lifecycle management (Apply)
- Registry operations (Apply/Analyse)

**Tasks** (assessed during Labs 9.1-9.5):
1. Establish an authenticated EPP session over TLS (client certificate, login) and interpret the greeting (8 points)
2. Execute a complete domain registration workflow: contact, hosts with glue, domain, delegation and DS (10 points)
3. Perform domain transfer and renewal operations with a secure transfer code (7 points)
4. Delete and restore a domain through the grace periods, explaining each result code and status (5 points)

#### Practical Assessment 5B: CoCCA Registry Management (45 minutes)
**Assessment Type:** Registry system administration
**Learning Objectives Tested:**
- Registry platform management (Apply)
- Policy configuration (Apply/Analyse)
- Integration capabilities (Apply)

**Tasks:**
1. Configure CoCCA registry policies and business rules (10 points)
2. Set up WHMCS-CoCCA integration (8 points)
3. Manage registrar accounts and permissions (5 points)
4. Monitor registry performance and generate reports (7 points)

#### Registry Operations Case Study (30 minutes)
**Assessment Type:** Problem-solving scenario
**Scenario:** Handle registry operational challenges
**Requirements:**
- Policy violation handling
- System performance issues
- Registrar dispute resolution
- Regulatory compliance

---

### Day 6: Monitoring and Future Technologies
**Modules 11-12: Monitoring/Performance and Emerging Technologies**

#### Practical Assessment 6A: Monitoring and Incident Response (45 minutes)
**Assessment Type:** Operational readiness evaluation
**Learning Objectives Tested:**
- Monitoring implementation (Apply)
- Incident response (Apply/Analyse)
- Performance optimisation (Analyse/Evaluate)

**Tasks:**
1. Deploy a DNS monitoring solution (10 points)
2. Respond to simulated DNS outage scenario (10 points)
3. Analyse performance data and recommend optimisations (5 points)
4. Document incident response procedures (5 points)

---

### Day 7 (morning): Final Project

#### Final Project: DNS Infrastructure Design (Sessions 1-2, 180 minutes)
**Assessment Type:** Team capstone project and presentation (teams of 3-4)
**Schedule:** Session 1 design and build, starting from the Lab 12.3 architecture exercise; Session 2 presentations and close
**Requirements:**
- Complete DNS infrastructure design for complex organisation
- Security implementation plan
- Operational procedures
- Future technology roadmap
- 15-minute team presentation to group

**Evaluation Criteria:**
- **Technical Design (40%):**
  - Architecture appropriateness
  - Security implementation
  - Scalability considerations
  - Technology selection rationale

- **Implementation Plan (30%):**
  - Deployment methodology
  - Risk assessment
  - Timeline and resources
  - Testing procedures

- **Operational Excellence (20%):**
  - Monitoring and alerting
  - Incident response procedures
  - Maintenance and updates
  - Performance optimisation

- **Presentation Quality (10%):**
  - Clear communication
  - Technical accuracy
  - Q&A handling
  - Professional delivery

---

## Certification Pathways

### DNS Fundamentals Certificate
**Requirements:**
- Completion of Days 1-2
- Pass all practical assessments (70% minimum)
- Pass knowledge checks (70% minimum)
- Demonstrate basic DNS operational competency

**Competencies Certified:**
- DNS concepts and hierarchy understanding
- Basic DNS operations and troubleshooting
- DNS software platform familiarity
- Zone management capabilities

### DNS Security Specialist Certificate
**Requirements:**
- DNS Fundamentals Certificate OR equivalent experience
- Completion of Days 3-4
- Pass security-focused assessments (75% minimum)
- Demonstrate DNSSEC implementation capability
- Complete privacy technology implementation

**Competencies Certified:**
- Advanced DNS security implementation
- DNSSEC deployment and management
- DNS privacy technologies (DoT/DoH)
- Security monitoring and incident response

### Advanced Registry Operations Certificate
**Requirements:**
- DNS Fundamentals Certificate OR equivalent experience
- Completion of Days 3-6 and the Day 7 Final Project
- Pass all advanced assessments (75% minimum)
- Complete final project successfully
- Demonstrate operational capability across all modules

**Competencies Certified:**
- Advanced DNS architecture design
- Registry operations and EPP protocol
- CoCCA platform management
- DNS operations across all 12 modules

### DNS Professional Master Certificate
**Requirements:**
- Complete the full program (Days 1-7)
- Pass all assessments (80% minimum)
- Excellent final project (85% minimum)
- Peer evaluation excellence
- Demonstrate teaching/mentoring capability

**Competencies Certified:**
- Expert-level DNS knowledge and skills
- Leadership in DNS operations
- Training and mentoring capability
- Strategic DNS planning and implementation

---

## Assessment Administration

### Grading Scale
- **Excellent:** 90-100% - Exceeds expectations, demonstrates mastery
- **Good:** 80-89% - Meets expectations, solid competency
- **Satisfactory:** 70-79% - Acceptable performance, basic competency
- **Needs Improvement:** 60-69% - Below expectations, requires additional training
- **Unsatisfactory:** <60% - Significant deficiencies, substantial remediation needed

### Remediation Procedures
**For participants scoring below 70%:**
1. **Immediate Review:** One-on-one discussion with instructor
2. **Additional Practice:** Extra lab time and guided exercises
3. **Peer Support:** Pairing with successful participants
4. **Reassessment:** Opportunity for improvement demonstration
5. **Extended Learning:** Additional resources and follow-up training

### Quality Assurance
- **Instructor Calibration:** Regular review of assessment criteria
- **Peer Review:** Cross-validation of assessment results
- **Industry Validation:** External review by DNS experts
- **Continuous Improvement:** Regular assessment refinement
- **Participant Feedback:** Incorporation of learner perspectives

### Documentation Requirements
- **Individual Assessment Records:** Detailed performance tracking
- **Competency Matrices:** Skills demonstration documentation
- **Portfolio Development:** Collection of participant work
- **Progress Reports:** Regular feedback and improvement tracking
- **Certificate Records:** Permanent record of certificates issued

---

## Assessment Tools and Resources

### Digital Assessment Platform
- **Online Quiz System:** Automated knowledge testing
- **Lab Submission Portal:** Practical work evaluation
- **Progress Tracking:** Real-time performance monitoring
- **Resource Library:** Assessment preparation materials
- **Feedback System:** Immediate results and improvement guidance

### Practical Assessment Infrastructure
- **Isolated Lab Environment:** Consistent assessment conditions
- **Standardised Scenarios:** Repeatable assessment challenges
- **Automated Validation:** Objective configuration checking
- **Performance Monitoring:** Quantitative skill measurement
- **Documentation Templates:** Structured reporting requirements

### Instructor Resources
- **Assessment Rubrics:** Detailed evaluation criteria
- **Scenario Descriptions:** Full challenge documentation
- **Solution Guides:** Reference implementations
- **Training Materials:** Instructor preparation resources
- **Calibration Exercises:** Consistency maintenance tools

---

## Standards and Value to Employers

### Professional Standards
- **ICANN Guidelines:** Alignment with industry best practices
- **RFC Compliance:** Standards-based assessment criteria
- **Vendor Neutrality:** Platform-agnostic competency evaluation
- **Continuing Education:** Professional development pathway

### Value to Employers
- **Skills Verification:** Demonstrable competency proof
- **Role Readiness:** Job-specific capability assessment
- **Career Advancement:** Professional development documentation
- **Training Investment:** Quantifiable learning outcomes