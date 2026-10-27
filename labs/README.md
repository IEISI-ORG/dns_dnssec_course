# Lab kits

Configs, scripts and EPP frames used to test each module's labs. Each kit's README says what was tested, with which package versions, and what an instructor must generate before class. Lab servers run Debian 13 (Stable) or Debian 12 (LTS).

| Kit | Module | Contents |
|-----|--------|----------|
| `module01/` | 1: Introduction to DNS | Day 1 topology, online and offline paths, rehearsal harness for Labs 1.1-1.3 (stand-in participant VM against the instructor stack's `m01` profile; the Lab 1.3 answer key is in `instructor/module01/`) |
| `module02/` | 2: DNS operations | Zone file templates for `teamNN.example` and its IPv4 and IPv6 reverse zones, the `zone` statements, a broken zone file for Lab 2.2, rehearsal harness for Labs 2.1-2.4 (stand-in VM 1 with BIND 9.20 against the instructor stack's `m01` profile) |
| `module03/` | 3: DNS server types | VM 2 resolver options and static-stub zone for the lab TLD, the Lab 3.2 forward zones, the stealth secondary and VM 1's transfer lines, rehearsal harness for Labs 3.1-3.4 (stand-in VM 1 and VM 2 with BIND 9.20 against the instructor stack's `m01` profile) |
| `module04/` | 4: DNS software platforms | BIND's statistics channel and an `rndc addzone` zone, Unbound on port 5300 next to BIND on VM 2, PowerDNS Authoritative with SQLite on port 5300 next to BIND on VM 1, `zonediff.sh` migration check, API request bodies, rehearsal harness for Labs 4.1-4.4 (stand-in VM 1 and VM 2 against the instructor stack's `m01` profile) |
| `module06/` | 6: DNS security fundamentals | Hardened BIND options for the authoritative and resolver VMs, security logging, TSIG and RPZ snippets, the instructor's RPZ feed, `dns-signs.sh` capture summary, rehearsal harness |
| `module07/` | 7: DNSSEC implementation | BIND authoritative and validating-resolver configs, Unbound resolver config, team and broken zones |
| `module08/` | 8: DNS privacy and encryption | `make-certs.sh` for the lab CA and resolver certificate, BIND DoT/DoH/padding and Unbound forward-tls snippets, DDR records, rehearsal harness |
| `module09/` | 9: Registry operations and EPP | Namingo EPP server settings, `epp-send` client, EPP frames for Labs 9.1-9.5, instructor seeding and zone-publishing scripts |
| `instructor/` | 1-4, 7-9 (more to come) | Docker Compose stack for the instructor server: the `example.` parent with the Lab 7.3 broken zones, the Module 1 lab hierarchy (profile `m01`, kept on for Modules 2-4), `publish-ds` for team DS records, the Knot DoQ demo, and a test harness |

The kits keep no private keys, TLS keys, rndc keys, signed zones, logs or passwords; `.gitignore` here blocks them. `seed-lab.sh` generates a random EPP password per registrar into `module09/secrets/passwords.tsv`; give each team only its own. `CHANGE-ME` in `module09/server/config.php` marks the database password to set on the server.
