# Knowledge Check 4: Security and Privacy (Day 4)

Covers Modules 7 and 8, and Module 6 for the security best practices (Day 3 has the mid-course assessment instead of a quiz). Taken on paper in the last 20 minutes of Session 3 on Day 4 (`dns_assessment_plan.md`).

## How to build the paper

- The bank has 12 question slots in the plan's four topics, and two variants (a and b) of each slot. Pick one variant per slot, so a paper has 12 questions: about 100 seconds each.
- The answer key is in `assessment/instructor/knowledge-check-4-key.md`; do not hand it out. The repository is public, so for a graded paper also change the names, numbers or key tags in some questions.
- One point per question; a short answer needs every part listed under "Accept" for the point. Pass: 9 of 12 (75%, the DNS Security Specialist threshold in `dns_assessment_plan.md`).
- Use at most three short-answer questions per paper.
- Questions marked **SA** are short answer; the rest are multiple choice with one correct option.
- Slide references are to the Module 6 (M6), Module 7 (M7) and Module 8 (M8) decks.

## V. DNSSEC validation chain (4 questions)

**V1a.** `team5.example` is unsigned, and the signed `example.` zone, which the resolver validates from its trust anchor, proves with a signed NSEC record that it has no DS for `team5.example`. What validation state does a validating resolver reach for `www.team5.example`, and what does the client see?
(a) Bogus; SERVFAIL (b) Secure; an answer with AD, because the NSEC proof is signed (c) Indeterminate; SERVFAIL (d) Insecure; an answer without AD

**V1b.** A validating resolver returns SERVFAIL for `www.team3.example`; the same query with `+cd` returns an address. What does that tell you?
(a) The authoritative server is unreachable (b) The data exists; DNSSEC validation is what fails (c) The name does not exist (d) The resolver does not validate, so it cannot handle the signed data

**V2a. (SA)** What does the DS record for `team1.example` contain, in which zone is it published, and which record in `team1.example` must it match?

**V2b.** `team1.example` uses a KSK and a ZSK. Which key's signature covers the A RRset of `www.team1.example`?
(a) the KSK (b) the root KSK (c) the ZSK (d) the ZSK of `example.`

**V3a. (SA)** A validator checks two DS records on its way to `www.team1.example A`, where `example.` is a TLD delegated from the root. In which zone is the DS for `example.`, and in which the DS for `team1.example`? What does each one match?

**V3b.** After a KSK change, a resolver returns SERVFAIL for every name in `team4.example` with `EDE: 9 (DNSKEY Missing)`. What is the most likely cause?
(a) The signatures have expired (b) The resolver's clock is wrong (c) The DS in the parent matches no DNSKEY in the zone (d) The NSEC3 iteration count is above the resolver's limit for this zone

**V4a.** What NSEC3 settings does RFC 9276 recommend?
(a) `NSEC3PARAM 1 0 10 <random salt>`, with the salt changed at every re-sign (b) `NSEC3PARAM 1 0 0 -`: no extra iterations, no salt; or plain NSEC (c) 150 iterations, Unbound's limit, for the strongest protection (d) opt-out for every zone, to keep zones small

**V4b.** On 27 October 2026, a validating resolver trusts only the root KSK-2017 (key tag 20326), as a static anchor. What happens?
(a) Validation fails for every name: SERVFAIL (b) Nothing until KSK-2017 is removed in March 2027 (c) Answers still resolve, but without AD (d) Only names under `arpa` fail

## R. Key rollover procedures (3 questions)

**R1a.** What is the first step of a ZSK pre-publish rollover?
(a) Submit a DS for the new ZSK to the parent, and wait for the parent's DS TTL (b) Publish the new ZSK without signing with it, and wait for the DNSKEY TTL plus propagation (c) Remove the old ZSK (d) Sign every RRset with both the old and the new ZSK, then publish the new ZSK

**R1b.** Which rollover needs a change at the parent?
(a) a KSK or CSK rollover (b) a ZSK rollover (c) neither: the parent holds only NS records (d) only an algorithm rollover

**R2a. (SA)** In a double-KSK rollover, when is it safe to remove the old KSK from the zone?

**R2b.** What does `team2.example. CDS 0 0 0 00` at the zone apex ask the parent to do?
(a) bootstrap the first DS (RFC 9615) (b) publish a SHA-1 DS (c) pause the rollover (d) remove the DS

**R3a.** The KSK of `team6.example` is compromised, and you cannot keep it in the zone until the registrar publishes a new DS. Which last resort keeps the zone resolvable for validating users?
(a) Remove the compromised KSK from the zone at once and publish a new one (b) Lower every TTL in the zone to 60, so that resolvers drop the old DS and keys sooner (c) Have the DS removed so the zone becomes insecure, re-key, then submit the new DS (d) Switch from NSEC to NSEC3

**R3b.** In an algorithm rollover (RSASHA256 to ECDSAP256SHA256), every RRset must carry a signature from each algorithm in the DNSKEY set. In which order do the new items go in?
(a) new DNSKEYs, then new signatures, then the DS (b) the new DS, then new DNSKEYs, then new signatures (c) remove the old signatures, then add the new ones (d) new signatures, then new DNSKEYs, then the DS

## P. Privacy protocol trade-offs (3 questions)

**P1a.** A user switches their browser to DoH with a public resolver. Who can still read the DNS queries themselves: every name looked up, including names the user never connects to?
(a) the café's Wi-Fi operator (b) the user's ISP, between the user and the resolver (c) the DoH resolver's operator (d) nobody

**P1b.** What does DoT give that DNSSEC does not?
(a) integrity of the data through every cache (b) confidentiality of the hop between the client and its resolver (c) proof that the answer is genuine (d) encryption of the resolver's queries to authoritative servers on the second hop

**P2a.** Why is DoT easier for a network to block than DoH?
(a) DoT uses its own port, TCP 853; DoH shares 443 with HTTPS (b) DoT sends a cleartext DNS query on port 853 before the TLS handshake (c) DoH runs over UDP port 53 (d) DoT has no ALPN token

**P2b.** A client learns its encrypted resolver through DNR (a DHCP or RA option). What does it check the resolver's certificate against?
(a) the resolver's IP address, which must appear in the certificate as an IP subjectAltName (b) the authentication domain name carried in the DHCP or RA option (c) nothing: DNR clients accept any certificate (d) an SPKI hash in an SVCB record

**P3a.** Which padding does RFC 8467 recommend?
(a) random lengths for every message (b) queries to a multiple of 468 octets, responses to a multiple of 128 (c) every message to 512 octets, or to 1232 with EDNS (d) queries to a multiple of 128 octets, responses to a multiple of 468

**P3b. (SA)** Your resolver offers DoT to its clients, with padding. Name two things a network observer between a client and the resolver can still learn.

## S. Security best practices (2 questions)

**S1a.** Which one setting stops an authoritative-only BIND 9.20 server from answering recursive queries for strangers?
(a) `version none;` (b) `minimal-responses yes;` (c) `recursion no;` (d) `rate-limit { ... };`

**S1b.** A secondary's TSIG-signed transfers fail with `BADTIME`. What is the cause?
(a) the clocks differ by more than the fudge: synchronise them with NTP (b) the two servers hold different secrets for the key (c) the secondary does not support hmac-sha256 (d) a fudge of 300 seconds is too small for zone transfers, which can run for longer than that

**S2a. (SA)** Name two things to monitor continuously on a signed zone, and for each say what breaks if you do not.

**S2b.** A secondary fetches a zone over TLS with `tls xot-client { };` (no `ca-file`). What does that give, and what should you keep?
(a) Full authentication of the primary, so TSIG is no longer needed for the transfer (b) Nothing: without a CA the transfer is cleartext (c) Integrity of the zone data, as DNSSEC gives (d) Encryption only; the primary is not authenticated, so keep TSIG

