# Module 7 lab configs (DNSSEC implementation)

The configs used to run every Module 7 command and lab step, tested on 2026-10-19 with BIND 9.20.29 and Unbound 1.26.1 (Debian 13 packages from trixie-security). All paths assume the kit is unpacked at `/srv/dnslab/module07` (`env.sh` sets `$L` to that path). rndc.key, private keys, signed zones and logs are not kept: generate them on the lab server.

- `env.sh`: sets `$L`, the kit root used in the lab commands.
- `auth/`: authoritative server on 127.0.0.1:5300. Holds `example.` (the lab "registry") and the team zones under the `lab` dnssec-policy.
- `brk/`: unsigned sources for the broken zones (team3: expired RRSIGs, signed with `-P`; team4 with `ds-team4-wrong`: a DS that matches no DNSKEY).
- `m71/`: zone source for Lab 7.1 (manual signing).
- `res/`: BIND validating resolver on :5301 (`dnssec-validation auto` plus an `example.` static-ds anchor in `anchor.conf` and `ta.ds`).
- `unb/`: the Unbound equivalent (`trust-anchor`, `forward-zone`, `ede: yes`).

## Before first use
1. `rndc-confgen -a -c $L/auth/rndc.key` (both `named.conf` files and `auth/rndc.conf` include it).
2. Sign `m71/` and `brk/` zones as in the Lab 7.1 and Lab 7.3 slides; `named.conf` loads the `.signed` files. Re-sign the expired zone (team3) with past dates before each class.
3. Replace `ta.ds` and the `trust-anchor` line in `unb/unbound.conf` with the DS of your own `example.` KSK.

This kit is the starting point for the instructor registry server. Module 9 (`../module09/`) replaces the hand-written `example.` zone with one built from the registry database.
