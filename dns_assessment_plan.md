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

**Tasks:**
1. Trace DNS resolution for a complex domain (5 points)
2. Identify delegation issues in provided scenario (5 points)
3. Analyse DNS response codes and explain their meaning (5 points)
4. Compare IPv4 and IPv6 DNS resolution paths (5 points)

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

**Tasks:**
1. Create complete zone file for assigned domain with all record types (10 points)
2. Implement reverse DNS configuration (5 points)
3. Configure email-related DNS records (SPF, DKIM, DMARC) (5 points)
4. Validate zone file syntax and troubleshoot errors (5 points)

**Assessment Criteria:**
- Syntax accuracy and completeness
- Proper record type usage
- Error identification and correction
- Best practice implementation

#### Knowledge Check 1: DNS Fundamentals Quiz (15 minutes)
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

**Tasks:**
1. Configure BIND authoritative server with primary/secondary setup (10 points)
2. Set up Unbound recursive resolver with forwarding (8 points)
3. Implement PowerDNS with database backend (7 points)
4. Test and validate all configurations (5 points)

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
1. Compare performance characteristics of different DNS software (8 points)
2. Recommend appropriate software for given scenarios (7 points)
3. Document configuration differences and migration considerations (5 points)
4. Present findings to group (5 points)

#### Knowledge Check 2: Infrastructure Quiz (15 minutes)
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
- Performance optimisation (Apply)
- Troubleshooting skills (Analyse)

**Tasks:**
1. Implement anycast DNS configuration (8 points)
2. Configure hidden primary architecture (7 points)
3. Set up split-horizon DNS with views (5 points)
4. Troubleshoot provided DNS issues (5 points)

#### Practical Assessment 3B: DNS Security Implementation (45 minutes)
**Assessment Type:** Security configuration and testing
**Learning Objectives Tested:**
- Security threat understanding (Understand/Analyse)
- Security implementation (Apply)
- Attack mitigation (Apply/Evaluate)

**Tasks:**
1. Configure DNS security controls (rate limiting, ACLs) (8 points)
2. Implement TSIG authentication (6 points)
3. Set up DNS monitoring and alerting (6 points)
4. Analyse and respond to simulated attack scenario (5 points)

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