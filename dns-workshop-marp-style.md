# DNS Workshop MARP Style Sheet & Demo Deck

## DNS Workshop Theme CSS (dns-workshop.css)

```css
/*
 * DNS Advanced Workshop Theme for Marp
 * Professional presentation theme compliant with technical organization brand guidelines
 * Based on ICANN-style branding with blue and orange color palette
 */

/* === ROOT VARIABLES === */
:root {
  /* Primary Brand Colors */
  --primary-blue: #1e3a8a;        /* Deep blue - main brand color */
  --primary-orange: #ea580c;       /* Vibrant orange - accent color */
  --secondary-blue: #3b82f6;       /* Medium blue - secondary elements */
  --light-blue: #dbeafe;           /* Light blue - backgrounds */
  
  /* Supporting Colors */
  --dark-navy: #0f172a;            /* Dark navy - high contrast text */
  --warm-gray: #6b7280;            /* Warm gray - body text */
  --light-gray: #f3f4f6;           /* Light gray - subtle backgrounds */
  --white: #ffffff;                /* Pure white */
  --success-green: #059669;        /* Success states */
  --warning-amber: #d97706;        /* Warning states */
  --error-red: #dc2626;            /* Error states */
  
  /* Typography Scale */
  --font-size-xs: 0.75rem;         /* 12px */
  --font-size-sm: 0.875rem;        /* 14px */
  --font-size-base: 1rem;          /* 16px */
  --font-size-lg: 1.125rem;        /* 18px */
  --font-size-xl: 1.25rem;         /* 20px */
  --font-size-2xl: 1.5rem;         /* 24px */
  --font-size-3xl: 1.875rem;       /* 30px */
  --font-size-4xl: 2.25rem;        /* 36px */
  --font-size-5xl: 3rem;           /* 48px */
  
  /* Spacing Scale */
  --space-1: 0.25rem;              /* 4px */
  --space-2: 0.5rem;               /* 8px */
  --space-3: 0.75rem;              /* 12px */
  --space-4: 1rem;                 /* 16px */
  --space-5: 1.25rem;              /* 20px */
  --space-6: 1.5rem;               /* 24px */
  --space-8: 2rem;                 /* 32px */
  --space-10: 2.5rem;              /* 40px */
  --space-12: 3rem;                /* 48px */
  --space-16: 4rem;                /* 64px */
  
  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  
  /* Border Radius */
  --radius-sm: 0.125rem;           /* 2px */
  --radius-md: 0.375rem;           /* 6px */
  --radius-lg: 0.5rem;             /* 8px */
  --radius-xl: 0.75rem;            /* 12px */
}

/* === BASE SECTION STYLES === */
section {
  background: linear-gradient(135deg, var(--white) 0%, var(--light-gray) 100%);
  color: var(--dark-navy);
  font-family: 'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif;
  font-size: var(--font-size-lg);
  line-height: 1.6;
  padding: var(--space-12);
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  position: relative;
}

/* === HEADER STYLES === */
section::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 6px;
  background: linear-gradient(90deg, var(--primary-blue) 0%, var(--primary-orange) 100%);
}

header {
  background: var(--primary-blue);
  color: var(--white);
  margin: calc(-1 * var(--space-12)) calc(-1 * var(--space-12)) var(--space-8) calc(-1 * var(--space-12));
  padding: var(--space-6) var(--space-12);
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: var(--shadow-md);
}

/* === TYPOGRAPHY === */
h1 {
  font-size: var(--font-size-4xl);
  font-weight: 700;
  color: var(--primary-blue);
  margin: 0 0 var(--space-8) 0;
  line-height: 1.2;
  letter-spacing: -0.025em;
}

h2 {
  font-size: var(--font-size-3xl);
  font-weight: 600;
  color: var(--primary-blue);
  margin: var(--space-8) 0 var(--space-6) 0;
  line-height: 1.3;
  position: relative;
  padding-left: var(--space-6);
}

h2::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 4px;
  height: 100%;
  background: var(--primary-orange);
  border-radius: var(--radius-sm);
}

h3 {
  font-size: var(--font-size-2xl);
  font-weight: 600;
  color: var(--secondary-blue);
  margin: var(--space-6) 0 var(--space-4) 0;
  line-height: 1.4;
}

h4 {
  font-size: var(--font-size-xl);
  font-weight: 600;
  color: var(--warm-gray);
  margin: var(--space-5) 0 var(--space-3) 0;
  line-height: 1.4;
}

h5 {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--warm-gray);
  margin: var(--space-4) 0 var(--space-2) 0;
  line-height: 1.5;
}

h6 {
  font-size: var(--font-size-base);
  font-weight: 600;
  color: var(--warm-gray);
  margin: var(--space-3) 0 var(--space-2) 0;
  line-height: 1.5;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

p {
  margin: 0 0 var(--space-4) 0;
  line-height: 1.7;
}

/* === LIST STYLES === */
ul, ol {
  margin: 0 0 var(--space-6) 0;
  padding-left: var(--space-6);
}

li {
  margin: 0 0 var(--space-2) 0;
  line-height: 1.6;
}

ul li {
  position: relative;
}

ul li::marker {
  color: var(--primary-orange);
  font-size: 1.2em;
}

ol li::marker {
  color: var(--primary-blue);
  font-weight: 600;
}

/* === CODE STYLES === */
code {
  background: var(--light-gray);
  color: var(--dark-navy);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-sm);
  font-family: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
  font-size: 0.9em;
  border: 1px solid #e5e7eb;
}

pre {
  background: var(--dark-navy);
  color: var(--white);
  padding: var(--space-6);
  border-radius: var(--radius-lg);
  margin: var(--space-6) 0;
  overflow-x: auto;
  box-shadow: var(--shadow-lg);
  border-left: 4px solid var(--primary-orange);
}

pre code {
  background: transparent;
  color: inherit;
  padding: 0;
  border: none;
  font-size: var(--font-size-sm);
  line-height: 1.6;
}

/* === TABLE STYLES === */
table {
  width: 100%;
  border-collapse: collapse;
  margin: var(--space-6) 0;
  background: var(--white);
  border-radius: var(--radius-lg);
  overflow: hidden;
  box-shadow: var(--shadow-md);
}

th {
  background: var(--primary-blue);
  color: var(--white);
  padding: var(--space-4) var(--space-6);
  text-align: left;
  font-weight: 600;
  font-size: var(--font-size-base);
}

td {
  padding: var(--space-4) var(--space-6);
  border-bottom: 1px solid var(--light-gray);
  vertical-align: top;
}

tr:nth-child(even) td {
  background: var(--light-blue);
}

tr:hover td {
  background: var(--light-blue);
}

/* === BLOCKQUOTE STYLES === */
blockquote {
  border-left: 4px solid var(--primary-orange);
  background: var(--light-blue);
  padding: var(--space-6);
  margin: var(--space-6) 0;
  border-radius: 0 var(--radius-lg) var(--radius-lg) 0;
  font-style: italic;
  position: relative;
}

blockquote::before {
  content: '"';
  font-size: var(--font-size-4xl);
  color: var(--primary-orange);
  position: absolute;
  top: var(--space-2);
  left: var(--space-4);
  line-height: 1;
}

blockquote p {
  margin-left: var(--space-8);
  margin-bottom: 0;
}

/* === SPECIAL SECTION CLASSES === */
.title-slide {
  background: linear-gradient(135deg, var(--primary-blue) 0%, var(--secondary-blue) 100%);
  color: var(--white);
  text-align: center;
  justify-content: center;
  align-items: center;
  padding: var(--space-16);
}

.title-slide h1 {
  color: var(--white);
  font-size: var(--font-size-5xl);
  margin-bottom: var(--space-6);
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.title-slide h2 {
  color: var(--primary-orange);
  font-size: var(--font-size-2xl);
  font-weight: 400;
  margin-top: 0;
  margin-bottom: var(--space-8);
}

.title-slide h2::before {
  display: none;
}

.section-divider {
  background: linear-gradient(135deg, var(--primary-orange) 0%, #f97316 100%);
  color: var(--white);
  text-align: center;
  justify-content: center;
  align-items: center;
}

.section-divider h1 {
  color: var(--white);
  font-size: var(--font-size-4xl);
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.lab-intro {
  background: linear-gradient(135deg, var(--success-green) 0%, #10b981 100%);
  color: var(--white);
}

.lab-intro h1,
.lab-intro h2,
.lab-intro h3 {
  color: var(--white);
}

.lab-intro h2::before {
  background: var(--white);
}

/* === EMPHASIS CLASSES === */
.highlight {
  background: var(--primary-orange);
  color: var(--white);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-sm);
  font-weight: 600;
}

.badge {
  display: inline-block;
  background: var(--secondary-blue);
  color: var(--white);
  padding: var(--space-1) var(--space-3);
  border-radius: var(--radius-xl);
  font-size: var(--font-size-sm);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.warning {
  background: #fef3c7;
  border: 1px solid var(--warning-amber);
  border-left: 4px solid var(--warning-amber);
  padding: var(--space-4);
  border-radius: var(--radius-md);
  margin: var(--space-4) 0;
}

.error {
  background: #fee2e2;
  border: 1px solid var(--error-red);
  border-left: 4px solid var(--error-red);
  padding: var(--space-4);
  border-radius: var(--radius-md);
  margin: var(--space-4) 0;
}

.success {
  background: #d1fae5;
  border: 1px solid var(--success-green);
  border-left: 4px solid var(--success-green);
  padding: var(--space-4);
  border-radius: var(--radius-md);
  margin: var(--space-4) 0;
}

/* === FOOTER === */
footer {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--primary-blue);
  color: var(--white);
  padding: var(--space-3) var(--space-12);
  font-size: var(--font-size-sm);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* === TWO-COLUMN LAYOUT === */
.columns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-8);
  align-items: start;
}

.columns-3 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: var(--space-6);
  align-items: start;
}

/* === IMAGE STYLES === */
img {
  max-width: 100%;
  height: auto;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  margin: var(--space-4) 0;
}

/* === MARP-SPECIFIC === */
section[data-theme~="dns-workshop"] {
  --color-background: var(--white);
  --color-foreground: var(--dark-navy);
  --color-highlight: var(--primary-orange);
  --color-dimmed: var(--warm-gray);
}

/* === RESPONSIVE ADJUSTMENTS === */
@media (max-width: 768px) {
  section {
    padding: var(--space-8);
  }
  
  h1 {
    font-size: var(--font-size-3xl);
  }
  
  h2 {
    font-size: var(--font-size-2xl);
  }
  
  .columns,
  .columns-3 {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }
}

/* === PRINT STYLES === */
@media print {
  section {
    break-inside: avoid;
    page-break-inside: avoid;
  }
  
  h1, h2, h3 {
    break-after: avoid;
    page-break-after: avoid;
  }
}
```

## Demo Presentation

```markdown
---
marp: true
theme: dns-workshop
class: title-slide
paginate: true
footer: 'Advanced DNS/DNSSEC Workshop | Module 1 | DNS Foundations'
---

# Advanced DNS/DNSSEC Workshop
## Complete 6-Day Professional Training Program

**DNS Foundations and Advanced Operations**
*Building Enterprise-Grade DNS Infrastructure*

---

<!-- class: section-divider -->

# Module 1
## Introduction to DNS Foundations and Concepts

---

## Learning Objectives

By the end of this module, participants will be able to:

- **Understand** the fundamental architecture of the Domain Name System
- **Explain** the DNS hierarchy and namespace structure
- **Analyze** DNS query resolution processes
- **Evaluate** different DNS server types and their roles
- **Apply** basic DNS troubleshooting techniques

<div class="badge">Knowledge</div> <div class="badge">Comprehension</div> <div class="badge">Application</div> <div class="badge">Analysis</div>

---

## DNS History & Evolution

### The Pre-DNS Era (1970s-early 1980s)

- **HOSTS.TXT file limitations**
  - Manual maintenance at Stanford Research Institute (SRI)
  - Single point of failure for name resolution
  - No hierarchical structure

<div class="warning">
<strong>Challenge:</strong> By 1983, HOSTS.TXT contained thousands of entries and was updated multiple times daily, creating an unsustainable operational burden.
</div>

### Birth of DNS (1983-1987)

- **Paul Mockapetris** designed the Domain Name System
- RFC 882 and RFC 883 (1983) - Original specifications
- RFC 1034 and RFC 1035 (1987) - Current foundation standards

---

## DNS Fundamentals

### What is DNS?

The **Domain Name System** is a hierarchical, distributed naming system that:

- Translates human-readable domain names to IP addresses
- Provides a scalable directory service for the Internet
- Enables email routing, service discovery, and text-based information storage
- Operates as a <span class="highlight">distributed database</span> across millions of servers

### Key Characteristics

<div class="columns">
<div>

**Hierarchical Structure**
- Tree-based namespace
- Delegation model
- Distributed authority

</div>
<div>

**Fault Tolerance**
- Multiple redundant servers
- Caching mechanisms
- No single point of failure

</div>
</div>

---

## DNS Namespace Hierarchy

```
                    . (root)
                    /    \
                 com      org     net     edu     gov
                /         |        \       |       \
           google    wikipedia   cloudflare  mit   nih
          /      \              
       www      mail
```

### Domain Name Components

- **Root Domain**: `.` (implicit in most representations)
- **Top-Level Domains (TLDs)**: `.com`, `.org`, `.net`, `.gov`
- **Second-Level Domains**: `google`, `wikipedia`, `cloudflare`
- **Subdomains**: `www`, `mail`, `blog`, `api`

<div class="success">
<strong>Best Practice:</strong> Always think of domain names as paths in an inverted tree structure, reading from right to left.
</div>

---

## DNS Components Overview

<div class="columns-3">
<div>

### Domain Names
- Human-readable identifiers
- Hierarchical labels
- Case-insensitive
- Up to 253 characters total

</div>
<div>

### Zones
- Administrative boundaries
- Delegation points
- Authority scope
- Zone files contain records

</div>
<div>

### Name Servers
- Authoritative servers
- Recursive resolvers
- Caching servers
- Root servers

</div>
</div>

### Resource Records (RRs)

| Record Type | Purpose | Example |
|-------------|---------|---------|
| **A** | IPv4 address mapping | `www.example.com. A 192.0.2.1` |
| **AAAA** | IPv6 address mapping | `www.example.com. AAAA 2001:db8::1` |
| **MX** | Mail exchange routing | `example.com. MX 10 mail.example.com.` |
| **NS** | Name server delegation | `example.com. NS ns1.example.com.` |
| **CNAME** | Canonical name alias | `blog.example.com. CNAME www.example.com.` |

---

## DNS Resolution Process

### Step-by-Step Query Resolution

```
1. User types "www.example.com" in browser
2. OS checks local cache
3. Query sent to recursive resolver
4. Resolver checks cache
5. Query to root server for "com" NS
6. Query to .com TLD server for "example.com" NS  
7. Query to example.com authoritative server for "www"
8. Response returned with IP address
9. Connection established to web server
```

<div class="columns">
<div>

### Recursive Queries
- Client delegates full resolution
- Resolver does all the work
- Single request/response pair
- Most common for end users

</div>
<div>

### Iterative Queries
- Client follows referrals
- Multiple query/response pairs
- Resolver provides best answer
- Used between DNS servers

</div>
</div>

---

## DNS Stakeholder Ecosystem

### Internet Corporation for Assigned Names and Numbers (ICANN)

- **Policy Development**: Multi-stakeholder consensus process
- **Contract Management**: Registry and registrar agreements
- **Root Zone Management**: IANA functions operator
- **Compliance**: Enforcement of contractual obligations

### Key Stakeholders

<div class="columns">
<div>

**Root Server Operators**
- 13 root server systems (A-M)
- Anycast deployment
- Geographic distribution
- Voluntary cooperation

**Registry Operators**
- TLD database maintenance
- Registration processing
- WHOIS services
- DNS infrastructure

</div>
<div>

**Registrars**
- Customer interface
- Domain registration services
- ICANN accreditation required
- Compliance obligations

**Internet Service Providers**
- Recursive DNS services
- Customer DNS resolution
- Caching infrastructure
- Performance optimization

</div>
</div>

---

<!-- class: lab-intro -->

# Practical Lab Introduction
## DNS Hierarchy Exploration

---

## Lab Environment Overview

### Virtual Machine Setup
- **Ubuntu 22.04 LTS** with DNS tools pre-installed
- **Network Topology**: Simulated Internet environment
- **Available Tools**: dig, nslookup, host, wireshark, bind9-utils

### Lab Exercises

1. **DNS Hierarchy Exploration**
   - Trace queries from root to authoritative servers
   - Understand delegation and referral process

2. **Query Analysis Workshop**
   - Use `dig +trace` to follow resolution path
   - Analyze response codes and flags

3. **DNS Server Identification**
   - Identify different server types in resolution chain
   - Understand caching behavior

---

## dig Command Reference

### Basic Syntax
```bash
dig [@server] [domain] [record-type] [options]
```

### Essential Options

| Option | Purpose | Example |
|--------|---------|---------|
| `+trace` | Follow delegation path | `dig +trace www.example.com` |
| `+short` | Minimal output | `dig +short example.com A` |
| `+norecurse` | Disable recursion | `dig +norecurse example.com` |
| `@server` | Query specific server | `dig @8.8.8.8 example.com` |
| `+stats` | Show query statistics | `dig +stats example.com` |

<div class="warning">
<strong>Lab Note:</strong> Always use the +trace option when learning DNS hierarchy to see the complete resolution process.
</div>

---

## Module Summary

### Key Takeaways

- **DNS is hierarchical and distributed** - No single point of control or failure
- **Caching is essential** - Improves performance and reduces server load  
- **Delegation enables scalability** - Administrative responsibility distributed
- **Multiple record types serve different purposes** - A, AAAA, MX, NS, CNAME, etc.
- **Understanding the ecosystem is crucial** - ICANN, registries, registrars, ISPs

### Next Module Preview

**Module 2: DNS Operations - Zones, Records, and Data Management**
- Zone file creation and management
- Advanced record types and configurations
- Zone transfer mechanisms
- Email infrastructure DNS setup

---

## Questions & Discussion

<div class="columns">
<div>

### Discussion Topics
- Real-world DNS performance experiences
- Common resolution problems you've encountered
- Questions about the DNS hierarchy
- Clarifications on stakeholder roles

</div>
<div>

### Up Next
- 15-minute break
- Hands-on lab exercises
- DNS query tracing workshop
- Group problem-solving session

</div>
</div>

<div class="success">
<strong>Remember:</strong> The best way to learn DNS is through hands-on practice and experimentation!
</div>

---

<!-- class: title-slide -->

# Thank You
## Questions & Lab Time

**Advanced DNS/DNSSEC Workshop**
*DNS Foundations Complete*

Ready for hands-on practice?
```

## Usage Instructions

### 1. Save the CSS Theme

Save the CSS content above as `dns-workshop.css` in your presentation directory.

### 2. Marp Configuration

For VS Code with Marp extension, add to your settings.json:

```json
{
  "markdown.marp.themes": [
    "./dns-workshop.css"
  ]
}
```

### 3. Use in Presentations

Add this frontmatter to your markdown files:

```yaml
---
marp: true
theme: dns-workshop
class: title-slide
paginate: true
footer: 'Workshop Title | Module X | Topic'
---
```

### 4. Available Classes

- `title-slide` - For title and section introduction slides
- `section-divider` - For module/section breaks  
- `lab-intro` - For practical exercise introductions
- `columns` - Two-column layout
- `columns-3` - Three-column layout

### 5. Special Elements

- `<span class="highlight">text</span>` - Orange highlight
- `<div class="badge">Label</div>` - Blue badge
- `<div class="warning">content</div>` - Warning callout
- `<div class="success">content</div>` - Success callout
- `<div class="error">content</div>` - Error callout

### 6. Export Options

```bash
# Export to PDF
marp --theme dns-workshop.css presentation.md --pdf

# Export to HTML
marp --theme dns-workshop.css presentation.md --html

# Export to PowerPoint
marp --theme dns-workshop.css presentation.md --pptx
```

This theme provides a professional, accessible design following modern brand guidelines with the blue and orange color scheme commonly used by technical organizations like ICANN.