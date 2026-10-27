# Knowledge Check 4: Answer Key (instructor)

Key for `assessment/knowledge-check-4.md`. One point per question; a short answer (SA) needs every part listed under "Accept". Pass: 9 of 12.

| Q | Answer | Why | Source |
|---|---|---|---|
| V1a | (d) | a proven-unsigned delegation is insecure: the answer is returned without AD | RFC 4033 §5, RFC 4035 §4.3; M7 "Validation Outcomes" |
| V1b | (b) | `+cd` skips validation; an answer then means the data exists and validation fails | M7 "Troubleshooting Workflow" |
| V2a | SA | Accept all three: (1) a digest of the KSK's (or CSK's) DNSKEY, with key tag, algorithm and digest type; (2) published in the parent zone `example.`; (3) it must match the KSK's DNSKEY record in `team1.example`. Not required: that the parent signs it, or flag 257 | RFC 4034 §5.1; M7 "DS: the Link to the Parent" |
| V2b | (c) | the ZSK signs every RRset; the KSK signs only the DNSKEY RRset | M7 "KSK, ZSK and CSK" |
| V3a | SA | Accept all four: the DS for `example.` is in the root zone and matches the KSK in the `example.` DNSKEY set; the DS for `team1.example` is in `example.` and matches the KSK in the `team1.example` DNSKEY set. "Matches the zone's DNSKEY" is enough for each match | M7 "The Chain of Trust", "Validation, Step by Step" |
| V3b | (c) | EDE 9 after a KSK change points at a DS with no matching DNSKEY | RFC 8914; M7 "Common Failures" |
| V4a | (b) | RFC 9276: iterations 0, empty salt, opt-out only for very large sparse zones, NSEC unless NSEC3 is needed | RFC 9276; M7 "NSEC3: Hashed Denial of Existence" |
| V4b | (a) | KSK-2024 (38696) has signed the root DNSKEY set since 11 October 2026; a validator that trusts only KSK-2017 cannot validate the root, so every name fails | M7 "Trust Anchors and the Root KSK" |
| R1a | (b) | publish first, so caches hold the new key before signatures that need it appear | RFC 7583; M7 "ZSK Rollover: Pre-Publish" |
| R1b | (a) | the parent's DS is a hash of the KSK (or CSK); the ZSK is vouched for only inside the zone | M7 "KSK, ZSK and CSK" |
| R2a | SA | Accept: only after the parent has replaced the DS with one for the new KSK, and the old DS's TTL (plus the parent's propagation time) has passed. Removing it earlier leaves resolvers with a cached DS that matches no key | RFC 7583; M7 "KSK Rollover: Double-KSK", "Example: DS Matches No Key" |
| R2b | (d) | `CDS 0 0 0 00` is the delete request | RFC 8078 §4 (erratum 5049 corrects `0 0 0 0` to `0 0 0 00`); M7 "Getting the DS to the Parent" |
| R3a | (c) | the same registrar wait, but never bogus: without a DS the zone is insecure; removing the KSK while the old DS stands makes it bogus | M7 "Emergency Rollovers" |
| R3b | (d) | signatures first, so every RRset already carries both algorithms when the new DNSKEYs appear; the reverse order on the way out | RFC 4035 §2.2, RFC 6781 §4.1.4; M7 "Algorithm Rollovers" |
| P1a | (c) | DoH hides the queries from the path, not from the resolver operator. Hop-1 observers can still infer sites from the SNI of the connection that follows, which is why the stem says "the queries themselves" | RFC 9076; M8 "Who Can See Your Queries" |
| P1b | (b) | DNSSEC protects integrity; DoT protects confidentiality of one hop | M8 "DNSSEC and Encryption Solve Different Problems" |
| P2a | (a) | port 853 identifies DoT; DoH shares 443 with web traffic | RFC 7858, RFC 8484; M8 "DoT in One Slide", "DoT, DoH and DoQ Compared" |
| P2b | (b) | DNR carries an ADN; no IP SAN is needed (that is DDR) | RFC 9463; M8 "DNR: Network-designated Resolvers" |
| P3a | (d) | Block-Length Padding: 128 for queries, 468 for responses | RFC 8467; M8 "Padding" |
| P3b | SA | Accept any two: the client's address; the resolver's address; that the client uses DoT at all (TCP 853); the SNI in the TLS ClientHello; timing and number of queries; the connection the client opens next and its SNI. Exact sizes: not accepted (the resolver pads); accept "the size class" or "the number of 128/468-octet blocks" if the answer says padding is in blocks | M8 "What Encryption Still Leaves Visible" |
| S1a | (c) | `recursion no;` on an authoritative server; the others hide the version, shrink answers or rate-limit | RFC 5358; M6 "Authoritative Server Checklist" |
| S1b | (a) | BADTIME: the signature is valid, the time is outside the fudge (300 s recommended); different secrets give BADSIG | RFC 8945; M6 "TSIG" |
| S2a | SA | Accept two, each with its effect: days left before the earliest RRSIG expires (zone goes bogus); each DS at the parent matches a DNSKEY (zone goes bogus); stalled rollovers (keys never retire, or the zone breaks at the next step); validation from outside, AD set (users see SERVFAIL first); clock drift on signers and resolvers (signatures not yet valid or expired); every validator trusts KSK-2024 (all names fail) | M7 "Monitoring" |
| S2b | (d) | encrypted, unauthenticated: below RFC 9103 §7.5's bar for XoT until `ca-file` and `remote-hostname` are added; TSIG still authorises the transfer | RFC 9103 §7.5, §9.1; M8 "Zone Transfers over TLS" |
