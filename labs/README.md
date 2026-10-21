# Lab kits

Configs, scripts and EPP frames used to test each module's labs. Each kit's README says what was tested, with which package versions, and what an instructor must generate before class. Lab servers run Debian 13 (Stable) or Debian 12 (LTS).

| Kit | Module | Contents |
|-----|--------|----------|
| `module07/` | 7: DNSSEC implementation | BIND authoritative and validating-resolver configs, Unbound resolver config, team and broken zones |
| `module09/` | 9: Registry operations and EPP | Namingo EPP server settings, `epp-send` client, EPP frames for Labs 9.1-9.5, instructor seeding and zone-publishing scripts |

The kits keep no private keys, TLS keys, rndc keys, signed zones or logs; `.gitignore` here blocks them. Passwords such as `Lab-pass-NN` and `CHANGE-ME` are classroom defaults for an isolated lab network: change them if a lab server can be reached from outside the lab.
