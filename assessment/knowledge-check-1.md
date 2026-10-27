# Knowledge Check 1: DNS Fundamentals (Day 1)

Covers Modules 1 and 2. Taken on paper in the last 15 minutes of Session 3 on Day 1 (`dns_assessment_plan.md`).

## How to build the paper

- The bank has 15 question slots in the plan's four categories, and two variants (a and b) of each slot. Pick one variant per slot, so a paper has 15 questions.
- The answer key is in `assessment/instructor/knowledge-check-1-key.md`; do not hand it out. The repository is public, so for a graded paper also change the names or numbers in some questions.
- One point per question; a short answer needs every part listed under "Accept" for the point. Pass: 11 of 15 (70%, rounded up).
- Questions marked **SA** are short answer; the rest are multiple choice with one correct option.
- Slide references are to the Module 1 (M1) and Module 2 (M2) decks.

## A. DNS hierarchy and delegation (5 questions)

**A1a.** What is the longest a single label can be, and the longest a whole domain name can be?
(a) 64 octets and 256 octets (b) 255 octets and 1024 octets (c) 63 octets and 255 octets (d) 32 octets and 512 octets

**A1b.** Are `WWW.Good.EXAMPLE.` and `www.good.example.` the same name to the DNS?
(a) No: labels are octets, so upper and lower case make different names (b) Yes: names are compared without regard to case (c) Only if the zone file is written in lower case (d) Only for A and AAAA queries

**A2a.** In the lab, the `example.` zone on 192.0.2.53 delegates `good.example`. Which of these records does the registry's `example.` zone file hold, and send in its referrals?
(a) `www.good.example. A 192.0.2.80` (b) `good.example. SOA ns1.good.example. ...` (c) `web.good.example. CNAME www.good.example.` (d) `good.example. NS ns1.good.example.`

**A2b.** What marks a zone cut?
(a) An SOA record for the child's name, in the parent's zone file (b) An NS record set at the child's name, in the parent zone (c) A CNAME at the child's name (d) An `$ORIGIN` line in the parent's zone file

**A3a.** `example.org` is delegated to `ns1.example.org` and `ns.example.net`. For which servers must the `org` zone send glue?
(a) `ns1.example.org` only (b) both (c) neither (d) `ns.example.net` only

**A3b.** `team01.example` is delegated to `ns.team02.example`. What does RFC 9499 call this relationship, and what does RFC 9471 say about glue for it?
(a) in-domain; glue MUST be sent (b) sibling domain; glue SHOULD be sent (c) unrelated; no glue (d) glue is not allowed for a name in another zone

**A4a.** `dig @192.0.2.53 www.good.example +norec` returns `status: NOERROR`, `flags: qr`, `ANSWER: 0`, the NS record for `good.example` in the authority section, and that server's address in the additional section. What is this reply?
(a) NODATA (b) NXDOMAIN (c) a referral (d) a truncated reply

**A4b.** An authoritative server replies `status: NOERROR`, `flags: qr aa`, `ANSWER: 0`, with the zone's SOA in the authority section. What is this reply?
(a) a referral to the servers named in the authority section (b) NXDOMAIN (c) SERVFAIL (d) NODATA: the name exists, but not with that type

**A5a.** How many root server names are there, and how many organisations operate them?
(a) 13 names, 13 organisations (b) 13 names, 12 organisations (c) 12 names, 13 organisations (d) 1,437 names, 13 organisations

**A5b. (SA)** A resolver with an empty cache (apart from its root hints) resolves `www.example.com`. Which server does it ask first, and what kind of reply does that server send?

## B. Record types and their purposes (5 questions)

**B1a.** Which record type holds an IPv6 address?
(a) A (b) A6 (c) AAAA (d) PTR

**B1b.** Which record type lists the authoritative servers for a zone?
(a) NS (b) SOA (c) MX (d) SRV

**B2a.** Which of these is allowed?
(a) `www CNAME host1` and `www TXT "v=spf1 -all"` (b) `@ CNAME www` at the zone apex (c) `@ MX 10 alias`, where `alias` is a CNAME (d) `web CNAME www` with `www A 192.0.2.80`

**B2b.** Which standard record type lets a web client use an alias at the zone apex?
(a) ALIAS (b) ANAME (c) HTTPS (d) DNAME

**B3a.** A domain has `MX 10 a`, `MX 5 b` and `MX 20 c`. Which host does a sending server try first?
(a) `a` (b) `b` (c) `c` (d) a random one of the three

**B3b.** What does `ftp IN MX 0 .` publish?
(a) mail for `ftp` goes to the zone apex (b) mail for `ftp` goes to the host with preference 0 (c) a syntax error: the target must be a host name (d) `ftp` takes no mail (null MX)

**B4a. (SA)** You edited a zone on the primary, but the secondaries keep the old data even after NOTIFY. Which SOA field did you most likely forget, and what must happen to it on every change?

**B4b.** In the SOA record `team01.example. SOA ns1.team01.example. hostmaster.team01.example. ( ... )`, what does `hostmaster.team01.example.` mean?
(a) the primary server (b) a host that must have an A record (c) the mailbox `hostmaster@team01.example` (d) the secondary server that NOTIFY messages are sent to

**B5a.** At which name does the PTR record for 192.0.2.80 live?
(a) `192.0.2.80.in-addr.arpa.` (b) `80.2.0.192.in-addr.arpa.` (c) `80.2.0.192.ip6.arpa.` (d) `192.0.2.in-addr.arpa.`

**B5b.** `team01.example` has `CAA 0 issue "ca.example.net"` at its apex, and `www.team01.example` has no CAA records. A CA that follows RFC 8659 gets a request for `www.team01.example`. What may it do?
(a) Issue freely: `www` has no CAA records (b) Refuse: `www` must carry its own CAA (c) Issue only if it is `ca.example.net` (d) Issue only a wildcard certificate

## C. TTL concepts and caching (3 questions)

**C1a.** The authoritative server shows `www.good.example. 300 IN A 192.0.2.80`; a resolver queried a little later shows `297`. Why?
(a) The authoritative server lowered the TTL (b) The resolver subtracts the network delay it measured from the TTL before answering (c) The resolver rounds TTLs down to a multiple of 3 (d) The resolver answered from its cache, and its copy's TTL counts down

**C1b.** A zone file gives `www 60 IN A 192.0.2.80` and then `www 300 IN A 192.0.2.90`. What does BIND do?
(a) Warns and gives the whole RRset one TTL, the first one (60) (b) Keeps two TTLs, one per record (c) Refuses to load the zone, because one RRset cannot hold two TTLs (d) Uses the larger TTL (300) for both

**C2a. (SA)** A zone's SOA record has a TTL of 3600 and a MINIMUM of 300. For how long may a resolver cache an NXDOMAIN from this zone, and why?

**C2b. (SA)** A zone's SOA record has a TTL of 600 and a MINIMUM of 86400. An Unbound 1.26 resolver with default settings gets an NXDOMAIN from it. For how long does it cache it?

**C3a.** `www` has a TTL of 3600, and its address changes at 12:00. What is the latest time to lower the TTL to 60 so that resolvers pick up the change within a minute?
(a) 11:59 (b) 11:00 (c) 12:00 (d) 13:00

**C3b. (SA)** Give one advantage of a long TTL and one advantage of a short TTL.

## D. DNS stakeholder roles (2 questions)

**D1a.** Which party is the only one that talks EPP to a registry?
(a) the registrant (b) the reseller (c) the registrar (d) the DNS operator

**D1b.** Which role runs the name servers for a domain?
(a) the registry (b) the reseller (c) IANA (d) the DNS operator

**D2a.** Who performs the IANA functions today?
(a) the IETF (b) Public Technical Identifiers (PTI), an affiliate of ICANN (c) Verisign (d) the Root Server System Advisory Committee (RSSAC) of ICANN

**D2b.** Who builds the root zone file, signs it and distributes it to the root server operators?
(a) the Root Zone Administrator (IANA) (b) RSSAC (c) the Root Zone Maintainer (Verisign) (d) the root server operators themselves

