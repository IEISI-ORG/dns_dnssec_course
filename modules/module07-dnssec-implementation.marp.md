---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 7: DNSSEC Implementation and Operations

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Recall** the DNSSEC record types (DNSKEY, RRSIG, DS, NSEC, NSEC3, CDS, CDNSKEY) and the roles of KSK, ZSK and CSK
- **Explain** the chain of trust, the validation outcomes, and why key rollovers are timed by TTLs
- **Choose** signing and DS digest algorithms from the IANA registry, and NSEC3 settings per RFC 9276
- **Sign** a zone by hand with `dnssec-keygen` and `dnssec-signzone`, and automatically with `dnssec-policy`
- **Configure** BIND and Unbound to validate, and diagnose validation failures
- **Perform** ZSK and KSK rollovers, including the DS change at the parent
- **Draft** a DNSSEC policy for an organisation's zones

---
<!-- _class: dense -->
## What Changed Recently

Older DNSSEC training is out of date in five places:

| Then | Now |
|---|---|
| `auto-dnssec` and scripted rollovers | `dnssec-policy` (KASP); `auto-dnssec` was removed in BIND 9.20 |
| RFC 8624 algorithm tables | IANA registry is authoritative (RFC 9904, Dec 2025); SHA-1 signing is MUST NOT (RFC 9905) |
| NSEC3 with salt and many iterations | Iterations 0, empty salt (RFC 9276); BIND 9.20 treats > 50 iterations as insecure |
| DS sent to the registrar by email or web form | CDS/CDNSKEY published by the zone, read by the parent (RFC 7344, 8078, 9615) |
| Root KSK-2017 (key tag 20326) | KSK-2024 (key tag 38696) has signed the root DNSKEY set since 11 October 2026 |

---
<!-- _class: compact-list -->
## Agenda (90 min Theory)

1. DNSSEC fundamentals (20m)
2. Key management and rollovers (20m)
3. Signing zones (20m)
4. Validation and troubleshooting (15m)
5. Operations and policy (10m)
6. Recap and questions (5m)

## Agenda (90 min Lab)

1. Lab 7.1 Sign a zone by hand (25m)
2. Lab 7.2 Sign with `dnssec-policy` (20m)
3. Lab 7.3 Validate and troubleshoot (25m)
4. Lab 7.4 Roll the keys (20m)

---
<!-- _class: section-divider -->
# 1 · DNSSEC Fundamentals

---
## Why DNSSEC

Plain DNS has no way to tell a real answer from a forged one.

- **Cache poisoning:** an off-path attacker races the real answer; Kaminsky (2008) made this practical against any name
- **On-path tampering:** anyone between resolver and server can rewrite answers
- **Compromised or misconfigured servers** hand out wrong data

Source-port randomisation and 0x20 make forgery harder. They do not prove the data is genuine. DNSSEC does.

---
<!-- _class: dense -->
## What DNSSEC Gives, and What It Does Not

<div class="columns">
<div>

### Gives
- **Origin authentication:** the data came from the zone's key holder
- **Integrity:** the data was not changed on the way
- **Authenticated denial:** "this name does not exist" is provable

</div>
<div>

### Does not give
- **Confidentiality:** queries and answers are still readable (Module 8: DoT, DoH, DoQ)
- **Availability:** a broken signature makes the zone *unreachable* for validating users
- **Protection of the last hop** from resolver to stub, unless the stub validates

</div>
</div>

---
## Design: Sign the Data, Not the Channel

- Signatures are DNS records (RRSIG) stored **in the zone**, next to the data they cover
- Signed data passes through caches, secondaries and anycast nodes unchanged
- The **validator** (usually the recursive resolver) checks the signatures
- Trust starts from a configured **trust anchor**, normally the root KSK
- The private keys never need to be on the public authoritative servers

---
## Public-Key Cryptography in One Slide

<div class="columns">
<div>

### Signing (zone operator)
1. Hash the canonical form of an RRset
2. Sign the hash with the **private key** (RSA, ECDSA or EdDSA)
3. Publish the result as an RRSIG record

</div>
<div>

### Verifying (validator)
1. Fetch the **public key** (DNSKEY)
2. Recompute the hash of the RRset
3. Check the RRSIG against it with the public key

</div>
</div>

Anyone can verify. Only the private-key holder can sign.

---
## Where Hashes Appear

| Use | Record | Hash today |
|---|---|---|
| Inside the signature algorithm | RRSIG | SHA-256 for algorithms 8 and 13; Ed25519 has its own |
| Digest of the child's KSK, held by the parent | DS | SHA-256 (digest type 2) |
| Hashed owner names for denial of existence | NSEC3 | SHA-1, iterations 0 (RFC 9276) |

SHA-1 in NSEC3 is a name-obscuring hash, not a signature, so RFC 9905 does not affect it.

---
<!-- _class: dense table-compact -->
## DNSSEC Record Types

| Record | Lives in | Purpose |
|---|---|---|
| **DNSKEY** | the zone | public keys (ZSK flag 256, KSK/CSK flag 257) |
| **RRSIG** | the zone | a signature over one RRset |
| **DS** | the **parent** | hash of the child's KSK; links parent to child |
| **NSEC** | the zone | next existing name; proves gaps |
| **NSEC3** | the zone | as NSEC, over hashed names |
| **NSEC3PARAM** | the zone apex | tells authoritative servers which NSEC3 chain to use |
| **CDS / CDNSKEY** | the zone apex | the DS the child *wants* the parent to publish (RFC 7344) |

Core specification: RFC 4033, 4034, 4035; the full document map is RFC 9364 (BCP 237).

---
<!-- _class: dense -->
## DNSKEY

```text
team1.example.  300 IN DNSKEY 257 3 13 (
                3CPV9hSRCcktB3wEWvAE2oaaBHXm++E9AS+uoqgBERLo
                Jz89X9xo6xYx6QLw0v4fbmlkxai7/iHgtxsItK9kYg==
                ) ; KSK; alg = ECDSAP256SHA256 ; key id = 1722
```

- **Flags:** 256 = zone key (ZSK); 257 = zone key + Secure Entry Point (KSK or CSK)
- **Protocol:** always 3
- **Algorithm:** 13 = ECDSA P-256 with SHA-256
- **Key tag** (1722): a 16-bit checksum of the key, used to match RRSIG and DS records to it; not unique

---
<!-- _class: dense -->
## RRSIG

```text
www.team1.example.  300 IN RRSIG A 13 3 300 (
                    20261118110605 20261019110605 23500 team1.example.
                    AMwK805wmxrjzG4WX0q8dfGowcmeIB8yYycjDuhsWPgs
                    tbwuVG5cTky2UV1rFogY/eAas9j+JpFknovFDJSFVA== )
```

| Field | Value | Meaning |
|---|---|---|
| Type covered, algorithm, labels | A 13 3 | signs the A RRset; 3 labels in the owner name |
| Original TTL | 300 | caches must not stretch the TTL beyond this |
| Expiration, inception | 20261118… 20261019… | valid window, in UTC; clocks matter |
| Key tag, signer | 23500 team1.example. | which ZSK signed it |

---
<!-- _class: dense -->
## DS: the Link to the Parent

```text
team1.example.  IN DS 1722 13 2 27BC5CECB81E3618174501E1FA7E04414CCAB559D44621602A74F25B BDA0C49B
```

- Published **in the parent zone** (here, `example.`), signed with the parent's keys
- Fields: key tag 1722, algorithm 13, digest type 2 (SHA-256), digest of the child's KSK
- A DS that matches no DNSKEY in the child breaks the zone for every validator
- Getting the DS into the parent is a registry operation (Module 9: EPP `secDNS`, RFC 5910)

---
<!-- _class: dense -->
## The Chain of Trust

```text
.                 DNSKEY (KSK 38696)   <- trust anchor in every validator
.                 DS example.          signed by the root ZSK
example.          DNSKEY               matches the DS above
example.          DS team1.example.    signed by the example. ZSK
team1.example.    DNSKEY (KSK 1722)    matches the DS above
team1.example.    DNSKEY (ZSK 23500)   signed by KSK 1722
www.team1.example A + RRSIG            signed by ZSK 23500
```

Every link is a signature or a hash. Break one and everything below it fails.

In the lab, `example.` has no DS in the real root, so resolvers get a trust anchor for `example.` instead.

---
<!-- _class: dense -->
## Trust Anchors and the Root KSK

- A validator needs at least one trusted key; normally the **root KSK**
- BIND (`dnssec-validation auto`) and Unbound (`auto-trust-anchor-file`) ship the root key and track changes with **RFC 5011** automated updates
- ICANN publishes the root anchors at data.iana.org (format: RFC 9718)

**Root KSK rollover in progress:**
- KSK-2024 (key tag **38696**) has signed the root DNSKEY set since **11 October 2026**; a validator that trusts only KSK-2017 (20326) now fails for every name
- KSK-2017 is revoked on **11 January 2027** and removed on **22 March 2027**
- Static anchors (`static-key` for `.`, Unbound `trust-anchor-file`, appliances) do not update themselves

> **Check every validator:** `dig @resolver . DNSKEY +dnssec` returns the AD flag; on BIND, `rndc managed-keys status` lists 38696 as trusted.

---
<!-- _class: dense -->
## Validation, Step by Step

For `www.team1.example A`:

1. Fetch the answer and its RRSIG; the RRSIG names signer `team1.example.` and key tag 23500
2. Fetch the `team1.example.` DNSKEY set; verify its RRSIG with the KSK
3. Fetch the DS for `team1.example.` from `example.`; check it matches that KSK
4. Validate the DS record set with the `example.` keys, and so on up to a trust anchor
5. Verify the A RRset's RRSIG with ZSK 23500, inside its validity window

Validators cache each validated DNSKEY and DS set, so most of these steps happen once per TTL.

---
<!-- _class: dense table-compact -->
## Validation Outcomes (RFC 4033 §5, RFC 4035 §4.3)

| State | Meaning | What the client sees |
|---|---|---|
| **Secure** | chain of signatures from a trust anchor | answer with the **AD** flag |
| **Insecure** | proven unsigned (no DS at a delegation) | answer, no AD |
| **Bogus** | should be signed, but validation failed | **SERVFAIL** |
| **Indeterminate** | no trust anchor covers the name | answer, no AD |

- A client can set **CD** (checking disabled) to get the data anyway; useful when diagnosing
- An insecure delegation must itself be *proven* with a signed NSEC or NSEC3 record

---
<!-- _class: dense -->
## Proving That a Name Does Not Exist

NSEC links each name to the next one in canonical order:

```text
team1.example.      NSEC ns1.team1.example. NS SOA RRSIG NSEC DNSKEY
ns1.team1.example.  NSEC www.team1.example. A RRSIG NSEC
```

- A query for `mail.team1.example` is answered with the NSEC that covers the gap `ns1` → `www`
- The same records prove "the name exists, but not with that type" (NODATA)
- Side effect: anyone can **walk the zone** and list every name
- Validators may reuse cached NSEC records to answer later queries themselves (RFC 8198)
- **Compact denial** (RFC 9824): signers that sign on the fly answer a missing name with NOERROR and one NSEC record listing the `NXNAME` pseudo-type

---
<!-- _class: dense -->
## NSEC3: Hashed Denial of Existence

```text
5R6JDBR2HC0G8P8GQJKHOCN0UOAD39V2.team1.example. 300 IN NSEC3 1 0 0 - MKU9J2GN... A RRSIG
```

- Owner names are SHA-1 hashes, so walking the chain yields hashes, not names (RFC 5155)
- Hashes of common names can still be guessed offline; NSEC3 slows enumeration, it does not prevent it
- **Opt-out** skips unsigned delegations, which keeps very large TLD zones smaller

**RFC 9276 (BCP, 2022):**
- Use NSEC unless you need NSEC3's features
- Iterations **0**, salt **empty** (`NSEC3PARAM 1 0 0 -`)
- Opt-out only for very large, sparsely signed zones
- Validators limit iterations: BIND 9.20 treats more than 50 as insecure; Unbound's default limit is 150

---
<!-- _class: section-divider -->
# 2 · Key Management

---
<!-- _class: dense -->
## KSK, ZSK and CSK

| Key | Signs | Changing it needs |
|---|---|---|
| **ZSK** (Zone Signing Key) | every RRset in the zone | nothing outside the zone |
| **KSK** (Key Signing Key) | only the DNSKEY RRset | a new DS in the **parent** |
| **CSK** (Combined Signing Key) | everything | a new DS in the parent |

- **KSK + ZSK:** the ZSK can roll often with no registry work; the KSK can be kept offline or in an HSM
- **CSK:** one key, simpler; the BIND 9.20 default policy is a single CSK with an unlimited lifetime
- The split is an operational choice, not a protocol requirement

---
<!-- _class: dense table-compact -->
## Choosing a Signing Algorithm

The IANA "DNS Security Algorithm Numbers" registry is the authority (RFC 9904). Its current recommendations (updated 2026-08-10):

| # | Mnemonic | Use for signing | Use for validation |
|---|---|---|---|
| 13 | ECDSAP256SHA256 | RECOMMENDED | RECOMMENDED |
| 15 | ED25519 | RECOMMENDED | RECOMMENDED |
| 8 | RSASHA256 | RECOMMENDED | RECOMMENDED |
| 14, 16 | ECDSAP384SHA384, ED448 | MAY | RECOMMENDED |
| 10 | RSASHA512 | NOT RECOMMENDED | RECOMMENDED |
| 5, 7 | RSASHA1, RSASHA1-NSEC3-SHA1 | **MUST NOT** (RFC 9905) | RECOMMENDED |
| 1, 3, 6, 12 | RSAMD5, DSA, DSA-NSEC3-SHA1, ECC-GOST | MUST NOT | MUST NOT |

**This course uses algorithm 13.** Check the registry before choosing; recommendations now change there, not in a new RFC.

---
<!-- _class: dense -->
## Why Algorithm 13

| | ECDSA P-256 (13) | RSA-2048 (8) |
|---|---|---|
| Public key size | 64 bytes | 256+ bytes |
| Signature size | 64 bytes | 256 bytes |
| Signing speed | fast | slower |
| Validator support | universal | universal |

- Smaller signatures keep responses inside the 1232-byte UDP buffer that BIND, Unbound and Knot advertise by default (RFC 9715 recommends at most 1400), so fewer fall back to TCP
- Ed25519 (15) is as compact; check your registry and signer support it before choosing it
- If you use RSA (8), use keys of at least 2048 bits

---
<!-- _class: dense table-compact -->
## DS Digest Types

| # | Digest | Use in delegations | Use in validation |
|---|---|---|---|
| 2 | SHA-256 | RECOMMENDED | RECOMMENDED |
| 4 | SHA-384 | MAY | RECOMMENDED |
| 1 | SHA-1 | **MUST NOT** | RECOMMENDED |
| 3 | GOST R 34.11-94 | MUST NOT | MUST NOT |

- Source: IANA "Delegation Signer (DS) Resource Record (RR) Type Digest Algorithms", updated 2026-01-13
- BIND 9.20 `dnssec-signzone` and `dnssec-policy` produce SHA-256 DS records only
- Registries should reject new SHA-1 DS records

---
<!-- _class: dense -->
## Generating Keys

```bash
dnssec-keygen -a ECDSAP256SHA256 -f KSK team1.example   # KSK (flag 257)
dnssec-keygen -a ECDSAP256SHA256 team1.example          # ZSK (flag 256)
```

```text
Kteam1.example.+013+01722.key       public key, as a DNSKEY record
Kteam1.example.+013+01722.private   private key: protect this file
```

- File name: `K<zone>+<algorithm>+<key tag>`
- Generate keys on the signer, never on a public-facing secondary
- `dnssec-policy` generates keys itself and adds a `.state` file per key

---
<!-- _class: dense -->
## Protecting Private Keys

- **File permissions:** readable only by the `named` user; never on secondaries or in version control
- **HSM:** keys generated and used inside hardware; BIND 9.20 reaches HSMs through `key-store` with a PKCS#11 URI
- **Offline KSK:** the KSK signs DNSKEY sets in advance and stays offline; BIND 9.20 supports this with `offline-ksk` and `dnssec-ksr`
- **Backups:** encrypted, tested, and including the `.state` files; losing the KSK private key forces an unplanned DS change
- **Access:** two-person control for KSK operations in high-value zones (TLDs, large enterprises)

---
<!-- _class: dense -->
## Do Keys Need to Roll?

<div class="columns">
<div>

### Reasons to roll
- Suspected or real compromise
- Algorithm change (for example, RSA to ECDSA)
- Staff with key access leave
- Practice, so the procedure works when it matters

</div>
<div>

### Reasons not to roll often
- Every KSK roll needs a DS change at the parent
- Each roll is a chance to break the zone
- ECDSA P-256 keys have no practical cryptanalytic lifetime limit

</div>
</div>

Common practice: roll the ZSK on a schedule (for example 30-90 days); roll the KSK rarely, or when needed. Write the choice down in your policy.

---
<!-- _class: dense table-compact -->
## ZSK Rollover: Pre-Publish

| Step | Zone contains | Wait for |
|---|---|---|
| 1. Publish | old ZSK signs; new ZSK published, not used | DNSKEY TTL + propagation, so caches see the new key |
| 2. Swap | new ZSK signs; old ZSK still published | every signature replaced, then max zone TTL + propagation |
| 3. Remove | new ZSK only | — |

- No change at the parent
- Signatures are never duplicated, so responses stay small
- This is what `dnssec-policy` does for a ZSK

---
<!-- _class: dense table-compact -->
## KSK Rollover: Double-KSK

| Step | Zone | Parent |
|---|---|---|
| 1. Publish | old and new KSK both sign the DNSKEY set | DS for old KSK |
| 2. Submit | CDS/CDNSKEY switch to the new KSK | registry replaces the DS |
| 3. Wait | both KSKs | DS for new KSK; wait DS TTL + propagation |
| 4. Remove | new KSK only | DS for new KSK |

- The DNSKEY set is double-signed for a short time; nothing else changes
- The alternative, **double-DS**, puts both DS records in the parent first: the DNSKEY set never holds two KSKs, but the parent must change twice (RFC 7583 §2.2)
- `dnssec-policy` uses double-KSK and waits for the parent before step 4

---
<!-- _class: dense tight table-compact -->
## Rollover Timing (RFC 7583)

A safe rollover waits for caches to forget old data. The inputs:

| Delay | BIND `dnssec-policy` option | Default |
|---|---|---|
| DNSKEY TTL | `dnskey-ttl` | 1 hour |
| Longest TTL in the zone | `max-zone-ttl` | 24 hours |
| Time to reach all secondaries | `zone-propagation-delay` | 5 minutes |
| Parent's DS TTL | `parent-ds-ttl` | 1 day |
| Time for the parent to publish | `parent-propagation-delay` | 1 hour |
| Safety margins | `publish-safety`, `retire-safety` | 1 hour each |
| Time to replace every signature | `signatures-validity` − `signatures-refresh` | 9 days |

With defaults, a new ZSK signs after about 2 hours and the old ZSK leaves about 10 days later; the old KSK leaves about 26 hours after the parent's DS changes.

---
<!-- _class: dense -->
## Emergency Rollovers

A key is suspected compromised. How fast can you replace it?

- **ZSK:** limited by the DNSKEY TTL, `max-zone-ttl` and re-signing time; no parent involvement
- **KSK:** limited by how fast the registry publishes the new DS, plus the old DS's TTL; until then, the old KSK must stay or the zone goes bogus
- **Standby key:** a pre-published, unused key cuts the wait to the switch-over alone
- **Last resort:** remove the DS (the zone becomes insecure, not bogus), re-key, then add the new DS

Write and rehearse the runbook. Know your registrar's DS turnaround time *before* an emergency.

---
<!-- _class: dense -->
## Algorithm Rollovers

Changing algorithm (for example RSASHA256 → ECDSAP256SHA256) is the riskiest rollover:

- Every RRset must carry a signature from **each** algorithm in the DNSKEY set (RFC 4035 §2.2)
- New signatures go in first, then the new DNSKEYs, then the DS changes
- Order reverses on the way out: old DS first, then old keys, then old signatures (RFC 6781 §4.1.4)

With `dnssec-policy`, change the algorithm in the policy; BIND schedules the steps. Budget for the larger responses while both are present.

---
<!-- _class: section-divider -->
# 3 · Signing Zones

---
<!-- _class: dense -->
## Two Ways to Sign

<div class="columns">
<div>

### By hand
- `dnssec-keygen` + `dnssec-signzone`
- You see every step
- You must re-sign before signatures expire (30 days by default)
- You run every rollover yourself

</div>
<div>

### Automatically
- `dnssec-policy` in BIND (also Knot DNS, PowerDNS, OpenDNSSEC)
- Keys, signatures and rollovers follow a written policy
- Re-signing is continuous
- KSK rollovers still need the parent

</div>
</div>

Learn the manual steps once (Lab 7.1); run production with a policy (Lab 7.2).

---
<!-- _class: dense -->
## Signing by Hand

```bash
dnssec-signzone -S -3 - -H 0 -o team1.example db.team1.example
```

| Option | Meaning |
|---|---|
| `-S` | smart signing: find the zone's keys in the key directory and add the DNSKEYs |
| `-3 -` | use NSEC3 with an empty salt |
| `-H 0` | 0 additional iterations (RFC 9276) |
| `-o team1.example` | the zone origin |

Output: `db.team1.example.signed` (the signed zone) and `dsset-team1.example.` (the DS to send to the parent).

---
<!-- _class: dense -->
## Check Before You Publish

```bash
dnssec-verify -o team1.example db.team1.example.signed
named-checkzone team1.example db.team1.example.signed
```

```text
Zone fully signed:
Algorithm: ECDSAP256SHA256: KSKs: 1 active, 0 stand-by, 0 revoked
                            ZSKs: 1 active, 0 stand-by, 0 revoked
```

Then load the `.signed` file in `named.conf` and query it:

```bash
dig @ns1.team1.example www.team1.example A +dnssec +multi
```

`dnssec-signzone` refuses to write a zone that fails its own check, which catches many mistakes early.

---
<!-- _class: dense -->
## Automatic Signing: `dnssec-policy`

- A **key and signing policy** (KASP): algorithms, key lifetimes, signature validity, TTLs and delays
- `named` creates the keys, signs the zone, re-signs before expiry, and runs rollovers on schedule
- The signed copy is kept separately (**inline signing**, the default in 9.20); you edit the unsigned zone file as before
- `auto-dnssec` was **removed** in BIND 9.20; migrate existing zones to `dnssec-policy`
- When migrating a signed zone, the policy must match its existing keys (algorithm, KSK/ZSK split, key directory), or `named` starts rolling to new keys
- Show the built-in policies with `named -C`

---
<!-- _class: dense -->
## The Built-in `default` Policy (BIND 9.20)

```text
dnssec-policy "default" {
    keys { csk key-directory lifetime unlimited algorithm 13; };
    cdnskey yes;  cds-digest-types { 2; };
    dnskey-ttl 3600;  max-zone-ttl 86400;
    publish-safety 3600;  retire-safety 3600;
    signatures-validity P14D;  signatures-refresh P5D;
    zone-propagation-delay 300;
    parent-ds-ttl 86400;  parent-propagation-delay 3600;
    inline-signing yes;
};
```

- One CSK, algorithm 13, never rolled; NSEC (no `nsec3param`)
- ISC may change the default in future releases; production zones should name their own policy

---
<!-- _class: dense -->
## A Policy of Your Own

```text
dnssec-policy "standard" {
    keys {
        ksk lifetime unlimited algorithm ecdsap256sha256;
        zsk lifetime P90D      algorithm ecdsap256sha256;
    };
    nsec3param iterations 0 optout no salt-length 0;
};

zone "team1.example" {
    type primary;
    file "db.team1.example";
    dnssec-policy "standard";
};
```

- Omit `nsec3param` to use NSEC
- BIND 9.20 accepts only `iterations 0`

---
<!-- _class: dense -->
## Watching the Keys: `rndc dnssec -status`

<div class="columns">
<div>

```text
key: 25929 (ECDSAP256SHA256), KSK
  published:   yes - since 22:07:52
  key signing: yes - since 22:07:52
  No rollover scheduled
  - goal:        omnipresent
  - dnskey:      omnipresent
  - ds:          hidden
  - key rrsig:   omnipresent
```

</div>
<div>

| State | Meaning |
|---|---|
| hidden | not published anywhere |
| rumoured | published, but some caches may not have it yet |
| omnipresent | every cache that matters has it |
| unretentive | being withdrawn, may still be cached |

`ds: rumoured` means the CDS is published and `named` is waiting for the parent; it becomes `omnipresent` only after the DS is seen there.

</div>
</div>

---
<!-- _class: dense -->
## Getting the DS to the Parent: CDS and CDNSKEY

- When the KSK is ready, `named` publishes **CDS** and **CDNSKEY** at the zone apex
- The parent (registry or registrar) reads them, checks they are signed by the current key, and updates the DS (RFC 7344, 8078)
- **RFC 9615** lets a parent bootstrap the *first* DS securely from records the DNS operator signs
- **RFC 9975** (May 2026): the parent acts only when the CDS/CDNSKEY records from all the zone's name servers agree
- `CDS 0 0 0 00` asks the parent to **remove** the DS

```text
team2.example.  CDS  25929 13 2 682BB7A2E874ED733AFAC13CE44C2B850C70FF43...
```

Registries that do not scan CDS still need the DS through EPP or a web form (Module 9).

---
<!-- _class: dense -->
## Telling `named` the Parent Has Changed

<div class="columns">
<div>

```text
remote-servers "registry" {
    192.0.2.53;
};
zone "team2.example" {
    ...
    dnssec-policy "standard";
    parental-agents { "registry"; };
};
```

```bash
rndc dnssec -checkds -key 33905 \
    published team2.example
rndc dnssec -checkds -key 25929 \
    withdrawn team2.example
```

</div>
<div>

- With `parental-agents`, `named` queries those servers for the DS (`checkds explicit`)
- Without them, it queries the parent's NS servers (`checkds yes`)
- A KSK rollover **pauses** until the new DS is seen, so a slow registry cannot break the zone
- A paused check is retried hourly; the `rndc` commands tell `named` straight away

</div>
</div>

---
<!-- _class: dense -->
## More Than One Signer

- **Multi-signer** (RFC 8901): two DNS providers each sign the zone with their own ZSK; every provider's DNSKEY set carries all the providers' ZSKs, signed by a shared KSK or by each provider's own KSK (with a DS for each)
- Used for provider redundancy and for moving providers without going insecure
- Needs coordination of DNSKEY and CDS/CDNSKEY sets between providers (RFC 9975)

Other signers you will meet:
- **Knot DNS:** automatic signing with policies, similar to `dnssec-policy`
- **PowerDNS:** signs answers as it serves them, with keys managed by `pdnsutil`
- **OpenDNSSEC:** a separate signer that feeds signed zones to any name server

---
<!-- _class: section-divider -->
# 4 · Validation and Troubleshooting

---
<!-- _class: dense -->
## Validating with BIND

```text
options {
    dnssec-validation auto;   // built-in root key, RFC 5011 updates
};
```

- `auto` is the default; `yes` needs a trust anchor you configure; `no` turns validation off
- Extra trust anchors, for a zone with no signed path from the root (like the lab's `example.`):

```text
trust-anchors {
    example. static-ds 29435 13 2 "00D828F978A7DED9ED7928C1E06445D7F8BA74C346BF44068443BCD67DFB4362";
};
```

- `static-ds` and `static-key` are fixed; `initial-ds` and `initial-key` are then tracked with RFC 5011

---
<!-- _class: dense -->
## Validating with Unbound

```text
server:
    auto-trust-anchor-file: "/var/lib/unbound/root.key"   # root key, RFC 5011
    trust-anchor: "example. DS 29435 13 2 00D828F978A7..."   # extra anchor
    ede: yes          # return Extended DNS Errors (off by default)
    val-log-level: 2  # log why validation failed
```

- Debian and Ubuntu packages set up `auto-trust-anchor-file` already
- `unbound-anchor` refreshes the root key file when it is stale
- With `ede: yes`, Unbound puts the failure reason in the response

---
<!-- _class: dense -->
## Is My Resolver Validating?

```bash
dig @resolver isc.org SOA +dnssec          # expect: flags ... ad
dig @resolver dnssec-failed.org A          # expect: SERVFAIL (deliberately broken)
dig @resolver dnssec-failed.org A +cd      # expect: an answer (validation skipped)
```

- **AD** set: the resolver validated the answer
- SERVFAIL on a bogus zone, and an answer with `+cd`: validation is on and working
- An answer *without* `+cd` for `dnssec-failed.org`: validation is off

---
<!-- _class: dense -->
## Troubleshooting Workflow

1. **SERVFAIL?** Repeat with `+cd`. An answer now means DNSSEC is the cause.
2. **Read the EDE** in the `dig` output (RFC 8914), if the resolver sends one
3. **Ask `delv`**, which validates locally and explains each step; point it at a server that holds the zone *and* the parent's DS:
   `delv @registry -a anchors.conf +root=example +vtrace www.wrongds.example`
4. **Read the resolver log:** BIND `dnssec` category; Unbound with `val-log-level: 2`
5. **Check the zone:** signature dates, DNSKEY vs DS key tags, the server clock
6. **Temporary relief:** a negative trust anchor (RFC 7646) while the owner fixes it:
   `rndc nta -lifetime 1h team4.example`

---
<!-- _class: dense table-compact -->
## Common Failures

| Symptom | Likely cause | EDE |
|---|---|---|
| SERVFAIL, `+cd` works | expired signatures (re-signing stopped) | 7 Signature Expired |
| Fails only on some resolvers | clock wrong on the resolver or signer | 8 Signature Not Yet Valid |
| SERVFAIL after a KSK change | DS in the parent matches no DNSKEY | 9 DNSKEY Missing, or 6 DNSSEC Bogus |
| SERVFAIL for some names only | missing RRSIG or NSEC3 records | 10 RRSIGs Missing, 12 NSEC Missing |
| Zone treated as insecure | NSEC3 iterations above the validator's limit | 27 Unsupported NSEC3 Iterations Value |
| Zone treated as insecure | algorithm or digest the validator does not support | 1, 2 |

EDE codes are hints: resolvers differ in which code they send, and some send none.

---
<!-- _class: dense -->
## Example: Expired Signatures

```text
$ dig @resolver www.team3.example A +dnssec
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL
; EDE: 7 (Signature Expired): (team3.example/DNSKEY)
```

```text
validating team3.example/DNSKEY: verify failed due to bad signature
    (keyid=58221): RRSIG has expired
validating team3.example/DNSKEY: no valid signature found (DS)
```

The `RRSIG has expired` line is the diagnosis; the next line appears for any broken DNSKEY chain. (Output from the test lab; in class this zone is `expired.example`.)

- Fix: re-sign the zone and reload; with `dnssec-policy`, find out why re-signing stopped
- Prevent: monitor the days left before the earliest RRSIG expires

---
<!-- _class: dense -->
## Example: DS Matches No Key

BIND returns SERVFAIL with **no** EDE. `delv`, pointed at a server holding both the zone and the parent's DS, finds it (in class: `wrongds.example`):

```text
$ delv @registry -a anchors.conf +root=example +vtrace www.team4.example
;; validating team4.example/DS: marking as secure (noqname proof not needed)
;; validating team4.example/DNSKEY: dsset with trust secure
;; validating team4.example/DNSKEY: no DNSKEY matching DS
```

Unbound (`ede: yes`): `EDE: 6 (DNSSEC Bogus)`, "no keys have a DS with algorithm ECDSAP256SHA256".

- Fix: publish the DNSKEY the DS refers to, or replace the DS at the parent
- Prevent: never remove a KSK until the parent's DS has changed and its TTL has passed

---
<!-- _class: section-divider -->
# 5 · Operations and Policy

---
<!-- _class: dense -->
## Planning a Deployment

1. **Inventory** zones, who hosts them, and how DS records reach each parent
2. **Choose** the signer, algorithm (13), NSEC or NSEC3, and key lifetimes
3. **Test** on a non-critical zone; check it with `dnssec-verify` and an external validator
4. **Publish** signed data for at least one TTL before submitting the DS
5. **Submit the DS** and confirm validation from outside your network
6. **Roll back safely:** remove the DS first, wait for its TTL, then stop signing; BIND's `insecure` policy does this in the right order

The order matters: a DS with no matching signed zone breaks resolution for every validating user.

---
<!-- _class: dense -->
## Monitoring

Alert on:

- **Signature expiry:** days until the earliest RRSIG expires, on every authoritative server
- **DS vs DNSKEY:** each DS in the parent matches a published DNSKEY
- **Key events:** stalled rollovers (`rndc dnssec -status`), and keys waiting on the parent
- **External validation:** periodic `dig +dnssec` from outside, checking for AD
- **Clock drift** on signers and resolvers (NTP)
- **Root trust anchor:** every validator trusts KSK-2024 (38696)

Tools: `dnssec-verify`, Zonemaster and DNSViz for one-off checks, and your monitoring system for continuous ones (Module 11).

---
<!-- _class: dense -->
## Operational Pitfalls

- **Secondaries** must serve the signed zone; transfer from the inline-signed copy, not the unsigned file
- **Large responses:** RSA keys plus many signatures overflow 1232 bytes; check TCP works to every server
- **TTL changes:** raising a TTL lengthens every later rollover wait
- **Registrar or DNS-provider changes:** plan the DS handover, or the zone goes bogus (multi-signer, Module 9)
- **Manual signing:** a forgotten re-sign job expires the zone 30 days later

---
<!-- _class: dense -->
## A DNSSEC Policy for Your Organisation

Write down, before signing (structure: RFC 6841 DNSSEC Practice Statement):

- Algorithms, key sizes and DS digest types
- KSK/ZSK or CSK, and key lifetimes
- Where keys are generated and stored (file, HSM, offline KSK), and who can use them
- Signature validity and re-signing schedule
- NSEC or NSEC3 (with RFC 9276 settings)
- Normal and emergency rollover procedures, with the registrar's DS turnaround
- Monitoring, alerting and who responds

In BIND, most of this policy becomes one `dnssec-policy` block.

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

- **Registry server** (instructor): hosts the signed `example.` zone, the "TLD" for the lab, at 192.0.2.53 (your lab sheet has the real address)
- **Your VMs:** an authoritative server for `teamNN.example` and `manualNN.example`, and a validating resolver
- **Software:** BIND 9.20 on Debian 13; Unbound as an optional second resolver
- **Tools:** dig, delv, dnssec-keygen, dnssec-signzone, dnssec-verify, rndc (Debian/Ubuntu packages bind9-dnsutils, bind9-utils)
- **Timings:** the lab policy uses 60-second TTLs and 30-minute signatures, so a ZSK rollover takes about 7 minutes, not 10 days

---
<!-- _class: dense -->
## Lab 7.1: Sign a Zone by Hand (25 min)

1. Create the unsigned zone `manualNN.example` (SOA, NS, A records)
2. Generate a KSK and a ZSK with algorithm 13
3. Sign with `dnssec-signzone -S -3 - -H 0 -o manualNN.example`
4. Check with `dnssec-verify` and `named-checkzone`; load the `.signed` file
5. Query with `dig +dnssec +multi`; identify the DNSKEY, RRSIG and NSEC3 records
6. Send the `dsset-manualNN.example.` file to the registry

> **Checkpoint:** `dnssec-verify` reports "Zone fully signed"; the registry confirms your DS is in `example.`

---
<!-- _class: dense -->
## Lab 7.2: Sign with `dnssec-policy` (20 min)

1. Add the `lab` policy (on your lab sheet) and `dnssec-policy "lab";` to `teamNN.example`
2. Add `parental-agents` pointing at the registry server
3. Reload; run `rndc dnssec -status teamNN.example` and read the key states
4. Wait for the CDS and CDNSKEY records (about 2 minutes with lab timings):
   `dig teamNN.example CDS +short`
5. Ask the registry to publish the DS from your CDS record; check with `dig @registry teamNN.example DS`
6. Tell `named`: `rndc dnssec -checkds -key <KSK id> published teamNN.example` (otherwise it re-checks the parent only hourly)

> **Checkpoint:** the log shows `checkds DS for key ... seen published`; about 2 minutes later `rndc dnssec -status` shows `ds: omnipresent`

---
<!-- _class: dense -->
## Lab 7.3: Validate and Troubleshoot (25 min)

1. On your resolver: `dnssec-validation auto;` plus a `trust-anchors` entry for `example.` (DS on your lab sheet)
2. Add a `static-stub` zone for `example` pointing at the registry server
3. Check: `isc.org` and `www.teamNN.example` return the AD flag; `dnssec-failed.org` returns SERVFAIL
4. Diagnose the two broken zones the instructor provides, `expired.example` and `wrongds.example`:
   - `dig +cd`, then the EDE, then `delv @registry +vtrace`, then the resolver log
5. Add and remove a negative trust anchor for one of them

> **Checkpoint:** for each broken zone, state the cause and the fix in one sentence

---
<!-- _class: dense -->
## Lab 7.4: Roll the Keys (20 min)

1. **ZSK:** `rndc dnssec -rollover -key <ZSK id> teamNN.example`; watch the new ZSK published, then signing, then the old one removed
2. **KSK:** `rndc dnssec -rollover -key <KSK id> teamNN.example`; wait for the CDS to show the new key tag
3. Ask the registry to replace your DS with the new one
4. Tell `named`: `rndc dnssec -checkds -key <new> published` and `-key <old> withdrawn`
5. Keep querying through your resolver: the AD flag must stay set throughout

> **Checkpoint:** one KSK and one ZSK remain, the parent's DS matches the new KSK, and validation never failed

**Discussion:** your KSK is compromised. With the production default timings, what is the fastest safe replacement?

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 9364: DNSSEC document map (BCP 237)
- RFC 4033-4035: DNSSEC core; RFC 6840: clarifications
- RFC 9904 and the IANA algorithm registry; RFC 9905 (SHA-1)
- RFC 9276: NSEC3 parameters; RFC 9824: compact denial
- RFC 7583: rollover timing; RFC 6781: operational practices
- RFC 7344, 8078, 9615, 9975: CDS/CDNSKEY
- RFC 8901: multi-signer; RFC 6841: DNSSEC policies
- RFC 8914: Extended DNS Errors; RFC 7646: negative trust anchors
- BIND 9.20 ARM: DNSSEC guide

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>dig +dnssec +multi zone DNSKEY
dig zone CDS +short
delv +vtrace name
dnssec-verify -o zone file
rndc dnssec -status zone
rndc dnssec -rollover -key id zone
rndc dnssec -checkds published zone
rndc nta -lifetime 1h zone
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. A validator returns SERVFAIL; `dig +cd` returns an answer. What does that tell you?
2. Why does a KSK rollover need the parent, but a ZSK rollover does not?
3. Which signing algorithms does the IANA registry currently RECOMMEND, and which SHA-1 algorithms are MUST NOT for signing?
4. What NSEC3 parameters does RFC 9276 recommend, and what happens on BIND 9.20 above 50 iterations?
5. During a KSK rollover with `dnssec-policy`, the registry has not yet published the new DS. What does `named` do?

<!--
Answers:
1. The data exists, and DNSSEC validation is what fails: the zone is bogus from this validator's view.
2. The parent's DS is a hash of the KSK; the ZSK is vouched for only by the KSK inside the zone.
3. RECOMMENDED: 8 (RSASHA256), 13 (ECDSAP256SHA256), 15 (ED25519). MUST NOT: 5 (RSASHA1), 7 (RSASHA1-NSEC3-SHA1).
4. Iterations 0, empty salt, opt-out only for very large sparse zones. BIND 9.20 treats more than 50 iterations as insecure.
5. It pauses: the old KSK stays published and signing until the new DS is seen (checkds) or confirmed with rndc dnssec -checkds.
-->

---
<!-- _class: section-divider -->
# Thank You

---
<!-- _class: dense -->
## Contact

**Terry Sweetser** — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Licence

---
<!-- _class: dense -->
## Creative Commons Attribution–NonCommercial–ShareAlike 4.0

This work is licensed under a  
[Creative Commons Attribution–NonCommercial–ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

**You are free to:**
- **Share** — copy and redistribute the material
- **Adapt** — remix, transform, and build upon the material

**Under the following terms:**
- **Attribution** — credit **Terry Sweetser (IEISI.ORG)**
- **NonCommercial** — no commercial use
- **ShareAlike** — same licence on derivatives
