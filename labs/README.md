# Lab kits

Configs, scripts and EPP frames used to test each module's labs. Each kit's README says what was tested, with which package versions, and what an instructor must generate before class. Lab servers run Debian 13 (Stable) or Debian 12 (LTS).

| Kit | Module | Contents |
|-----|--------|----------|
| `module07/` | 7: DNSSEC implementation | BIND authoritative and validating-resolver configs, Unbound resolver config, team and broken zones |
| `module08/` | 8: DNS privacy and encryption | `make-certs.sh` for the lab CA and resolver certificate, BIND DoT/DoH/padding and Unbound forward-tls snippets, DDR records, rehearsal harness |
| `module09/` | 9: Registry operations and EPP | Namingo EPP server settings, `epp-send` client, EPP frames for Labs 9.1-9.5, instructor seeding and zone-publishing scripts |

The kits keep no private keys, TLS keys, rndc keys, signed zones, logs or passwords; `.gitignore` here blocks them. `seed-lab.sh` generates a random EPP password per registrar into `module09/secrets/passwords.tsv`; give each team only its own. `CHANGE-ME` in `module09/server/config.php` marks the database password to set on the server.
