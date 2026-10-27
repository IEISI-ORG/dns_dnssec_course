# Module 1 lab hierarchy (instructor only)

Templates for the `m01` profile of the instructor stack (see `../README.md`):
`root/` (lab root, 192.0.2.52 on the slides), `child/` (lab child, .54) and
`resolver/` (lab resolver, .55). `../images/bind/m01-run` fills in the
classroom addresses and the fault labels on every start;
`../images/bind/make-example-zone` adds the Module 1 delegations to
`example.` when `M01_CHILD_ADDR` is set. The participants' kit is
`../../module01/`; this file holds what they should not read before Lab 1.3.

## Setting up the Module 1 day

- In `.env`: `M01_ROOT_ADDR`, `M01_CHILD_ADDR`, `M01_RESOLVER_ADDR` (free
  addresses on the classroom subnet, outside DHCP, not a team VM) and `m01`
  in `COMPOSE_PROFILES`; then `docker compose build --pull --no-cache` and
  `docker compose up -d` (no `--build`: see Images in `../README.md`). With `m01` on
  and an address left empty, `up` stops with `invalid IPv4 address:
  ParseAddr("set-M01_..._ADDR-in-.env")` instead of letting Docker pick an
  address that may belong to another host.
- `classroom/teams.conf` must list every team's VM 1 from Day 1: the registry
  then delegates `teamNN.example` to a VM that runs no server yet, the
  worked example on the slides ("connection refused"). `make-example-zone`
  warns if a team VM uses one of the instructor addresses.
- `LAB_SUBNET` limits who may use the lab resolver.
- Switch at the start of a day: changing `M01_CHILD_ADDR` or
  `M01_FAULT_LABELS` recreates the parent (a few seconds without `example.`;
  keys and the handout DS are kept).
- At the end of the day, see "Turning a profile off" in `../README.md`.

## Fault labels and assessed runs

The repository is public, and so are the default zone names on the slides
and this answer key. `M01_FAULT_LABELS` (five comma-separated labels, in the
order of the table below) renames the fault zones; the reference zone stays
`good.example`, which Labs 1.1 and 1.2 use. Labels must be lower-case
letters, digits and hyphens, start with a letter, be distinct, and not be
`good`, `ns1`, `doq`, `expired`, `wrongds`, `teamNN` or `manualNN`.
A bad list is rejected: the parent keeps serving its previous `example.`
zone and the child exits; `docker compose logs parent m01-child` says why.

For a run that is graded (Practical Assessment 1A task 2), set five labels
the class has not seen, for example `M01_FAULT_LABELS=kilo,lima,mike,november,oscar`,
put them on the lab sheet, and keep this file's mapping to yourself: the
fault behind each label is the column order, not the name.
`../test/run.sh` runs the whole stack with exactly those labels.

## Lab 1.3 answer key (default labels)

| Zone | Fault | Evidence | Who fixes it |
|---|---|---|---|
| 1. `alpha.example` | delegated to 192.0.2.54, which does not serve the zone | that server answers REFUSED; resolver SERVFAIL | DNS operator adds the zone, or registrant changes the NS |
| 2. `bravo.example` | delegated to 198.51.100.53, where nothing answers | timed out (or "network unreachable" on a LAN with no route); resolver SERVFAIL | registrant or DNS operator: correct address or a working server |
| 3. `charlie.example` | stale glue: parent says ns2 is 198.51.100.54, the zone says 192.0.2.54 | compare `dig @192.0.2.53 charlie.example NS +norec` with `dig @192.0.2.54 ns2.charlie.example +norec`; still resolves through ns1 | registrant updates the host address through the registrar |
| 4. `delta.example` | NS sets differ: parent ns1, ns2; zone ns1, ns3; ns2 is NXDOMAIN in the zone | compare the referral with `dig @192.0.2.54 delta.example NS +norec`; resolves (the resolver uses the zone's set) | both sides list the same servers |
| 5. `echo.example` | not delegated | NXDOMAIN with `aa` from 192.0.2.53, `example.` SOA in authority | registrant registers or renews |

- **Timing in a classroom with a default gateway:** 198.51.100.0/24 is
  routed to the gateway and dropped, so zone 2 through the resolver takes
  about 10 s and `dig` may print one ";; communications error ... timed
  out" line before the SERVFAIL; the delay is part of the evidence. Zone 3
  can be slow once (about 0.9 s with a cold cache). Both measured in the
  code review with the range dropped; on the test bridge and on a LAN with
  no route both fail at once with "network unreachable".
- **Grading:** `good.example` has one NS, and the two server names in zones
  3 and 4 share one address. These are lab simplifications: credit a
  participant who notices them; do not deduct either way.
- 198.51.100.0/24 is TEST-NET-2 (RFC 5737). If the classroom uses that
  range, change the two addresses in `../images/bind/make-example-zone` and
  rebuild: `docker compose build --pull --no-cache`, then `docker compose up -d`
  (the script is part of the image).
