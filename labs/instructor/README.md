# Instructor server (Docker Compose)

The instructor-side services for the labs run as one Compose project on a Debian 13 host on the classroom LAN. Participants keep their own Debian 13 VMs. Every service gets a fixed address on the classroom network (ipvlan L2), so the team VMs reach it exactly as they would reach a separate server.

| Service | Address (`.env`) | Module | What it does |
|---|---|---|---|
| `init` | none | 7-9 | One-shot, on every `up`: rndc key; broken-zone keys; re-signs `expired.example` with validity in the past |
| `parent` | `PARENT_ADDR` (192.0.2.53 on the slides) | 7-9 | The "registry": on start, builds `db.example` from `classroom/teams.conf` and the published DS records; BIND serving `example.` (signed by the Module 7 `lab` policy), `expired.example` and `wrongds.example`; `publish-ds` for team DS records; writes the trust-anchor handout |
| `doq` | `DOQ_ADDR` (192.0.2.40), profile `m08` | 8 | Knot DNS 3.4 serving `doq.example` over DoQ (UDP 853) for the instructor demo |
| `m01-root` | `M01_ROOT_ADDR` (192.0.2.52), profile `m01` | 1 | Lab root server: a root zone `.` that delegates `example.` to the parent, and `root-servers.test` |
| `m01-child` | `M01_CHILD_ADDR` (192.0.2.54), profile `m01` | 1 | `good.example` and two of the Lab 1.3 fault zones; the parent delegates `good` and four fault zones, each with one fault (names from `M01_FAULT_LABELS`) |
| `m01-resolver` | `M01_RESOLVER_ADDR` (192.0.2.55), profile `m01` | 1 | Recursive resolver for `LAB_SUBNET` whose root hints are the lab root: resolves only the lab hierarchy |

The `m01` services have no keys and no state: `m01-run` fills the classroom addresses and fault labels into the templates in `module01/` on every start. The faults, the labels for assessed runs and the Lab 1.3 answer key are in `module01/README.md` (instructor only; the participants' kit is `../module01/`).

Still to come: Namingo for Module 9 (it will write `db.example` for the parent, as `../module09/instructor/publish-example-zone.sh` does now), the Module 6 instructor services, and CoCCA for Module 10.

## Requirements
- A Debian 13 VM (or host) on the hypervisor, with one NIC on the classroom bridge or VLAN.
- Docker Engine and Compose v2. Debian 13 packages them as `docker.io` 26.1 and `docker-compose` 2.26; this stack was tested with Docker 29.9 and Compose 5.6.
- Free addresses for `PARENT_ADDR`, `DOQ_ADDR` and the `M01_*` services on the classroom subnet: outside the DHCP range and not used by any team VM.

## Set up for a class
```sh
cp .env.example .env                                  # set the NIC, subnet, gateway, addresses, your uid/gid
cp classroom/teams.conf.example classroom/teams.conf  # one "NN address" line per team
mkdir -p handout
docker compose build --pull --no-cache                # current Debian 13 security updates (see Images below)
docker compose up -d                                  # no --build: see Images below
docker compose exec parent named -v                   # the BIND version this class runs
cat handout/example.ds                                # the example. DS for the lab sheet (written a few seconds after start)
```
On the Module 1 day, set the three `M01_*` addresses and add `m01` to `COMPOSE_PROFILES`; for a graded Lab 1.3, also set `M01_FAULT_LABELS` to five names the class has not seen (`module01/README.md`). `teams.conf` must already list every team's VM 1 (the registry delegates `teamNN.example` to it before it runs a server, which Module 1 uses as a worked example). Leave `M01_CHILD_ADDR` empty on other days: the Module 1 zones are then not delegated. Make these changes at the start of a day: changing them recreates the parent, which leaves `example.` unanswered for a few seconds (keys and the handout are kept).

With a profile on, an empty address for one of its services stops `up` (`invalid IPv4 address: ParseAddr("set-..._ADDR-in-.env")`), rather than letting Docker pick an address that may belong to another host on the classroom LAN. With the profile off, the empty address is ignored.

On the Module 8 day, set `COMPOSE_PROFILES=m08` in `.env` (or put `--profile m08` before `up`) to add the DoQ server. `docker compose down` removes it only while `m08` is still active; after you take `m08` out of `.env` it keeps running (see "Turning a profile off"). Leave `DOQ_ADDR` empty when you do not run Module 8: `doq.example` is then not delegated.

`handout/` then holds what participants need. None of it is secret:
- `example.ds`: the DS record for `example.`;
- `trust-anchors.conf`: the BIND `trust-anchors` statement for Lab 7.3;
- `unbound-trust-anchor.conf`: the same anchor for Unbound;
- `doq.crt`: with profile `m08`, the certificate that `kdig +tls-ca=` needs.

**Network notes.** The `lab` network uses ipvlan in L2 mode on `LAB_PARENT_IF`. Every container shares that NIC's MAC address, so the hypervisor's virtual switch needs no promiscuous mode or MAC-address changes. The host itself cannot reach the containers through that NIC, which is how ipvlan works, so run checks from a team VM or with `docker compose exec`. Plain port publishing on Docker's default bridge network is not used, because it can hide the participants' real source addresses, and Module 9's registrar IP allowlists and Module 6's rate limits depend on them.

## During the labs
Run these in this directory. `-T` lets you pipe a file in.

| Lab | Participants send | Instructor runs |
|---|---|---|
| 7.1 | their `dsset-manualNN.example.` file | `docker compose exec -T parent publish-ds manualNN.example < dsset-manualNN.example.` |
| 7.2 | "our CDS is up" | `docker compose exec parent publish-ds teamNN.example --cds` (asks the address in `teams.conf`; add an address to ask another) |
| 7.4 | "new CDS after the KSK rollover" | the same `--cds` command |

- **First DS for a zone:** when a zone has no DS yet, `--cds` cannot check the CDS signature against anything. It checks that the CDS matches a DNSKEY the team publishes, accepts it and prints the key tags; confirm them with the team before moving on. RFC 8078 calls this accepting the initial DS by out-of-band means.
- **Replacing a DS:** when a DS is already published, `dnssec-cds` accepts the new CDS only if it is signed by a key that matches the current DS (RFC 7344). A CDS of `0 0 0 00` withdraws the DS.
- **Input checks:** DS lines are checked before anything is published (numeric key tag, algorithm and digest type; a hex digest of the right length). If the new `example.` zone still fails its check, the old DS is kept and nothing changes.
- **Other commands:**
  - `publish-ds --list` shows every published DS.
  - `publish-ds teamNN.example --remove` withdraws a team's DS, also for a team already taken out of `teams.conf`.
  - `publish-ds --refresh` rebuilds `example.` after you edit `classroom/teams.conf`. The whole directory is mounted, so saving the file with any editor works. A DS for a team that is no longer in the file is skipped with a warning.
- Run all `publish-ds` commands through `docker compose exec parent`.

## Between days and between classes
- `docker compose down`, then `docker compose up -d`: the keys and published DS records are kept, so the trust anchor on the lab sheet stays valid. `expired.example` is re-signed with past dates on every `up`, so it is always expired.
- `docker compose down -v`: new class. This deletes the keys, so `example.` gets a new KSK and a new handout DS; print new lab sheets.
- The DoQ certificate is valid for 30 days. It is replaced on start when fewer than 7 days remain or `DOQ_ADDR` has changed, so restart `doq` at least every 3 weeks.
- The parent uses the TTLs and delays of the Module 7 `lab` policy (as printed in `dns_dnssec_workshop_plan.md`, so a DS change reaches team resolvers within a minute) but BIND's default signature validity, so `example.` stays valid while the stack is down.

## Turning a profile off
Compose acts only on services whose profile is active (in `COMPOSE_PROFILES` or given with `--profile`) or that you name. After you take `m01` or `m08` out of `.env`, its containers keep running, `restart: unless-stopped` brings them back after a reboot, and a plain `docker compose down` leaves them and the network ("Resource is still in use"). Remove them by name; this works whether or not the profile is still in `.env`:
```sh
# end of the Module 1 day
docker compose rm -sf m01-root m01-child m01-resolver
# then, in .env: empty the M01_* addresses and remove m01 from COMPOSE_PROFILES
docker compose up -d        # recreates the parent without the Module 1 delegations
# end of the Module 8 day: the same with
docker compose rm -sf doq   # then empty DOQ_ADDR and remove m08
```
If the stack goes down overnight anyway, run `docker compose down` before you edit `.env`: with the profile still active it removes everything. All of this was checked with Compose 5.6.0 on the test bridge (2026-10-22).

## What is kept where
- **Secrets** (the rndc key, the DNSSEC private keys and the DoQ TLS key) exist only in the `parent-state` and `doq-state` volumes. They are made at `up` time and are never in an image or in this repository.
- **Per-classroom files** (`.env`, `classroom/teams.conf`, `handout/`) are listed in `../.gitignore`.
- **Images** are built on `debian:${DEBIAN_TAG}` and are upgraded from Debian 13 security updates at build time. The versions tested are listed below. Build with `docker compose build --pull --no-cache`, then start with `docker compose up -d`, never `up -d --build`: on a host that has built the images before, a cached build can go back to the old package layer. Seen 2026-10-22 with Docker 29.9.1 and Compose 5.6.0: after a `--no-cache` build gave BIND 9.20.30, the next cached `build` gave 9.20.29 again. Check with `docker compose exec parent named -v`.

## Test
`test/run.sh` runs the whole stack with no classroom NIC. `compose.test.yaml` swaps ipvlan for an internal bridge with the same addresses and adds three containers:
- a stand-in team authoritative server, `team01.example` at 192.0.2.101, with the `lab` policy and `parental-agents` set as in Lab 7.2;
- a validating resolver at 192.0.2.10, with the handout trust anchor and a static-stub zone for `example`, as in Lab 7.3;
- a client.

It first checks that an empty address stops each profile's service and is ignored with the profiles off. It then checks the Module 1 lab hierarchy with non-default fault labels (`kilo` to `oscar`: each delegation and its fault, the lab resolver, truncation and TCP), the other-day path (empty `M01_CHILD_ADDR`: no Module 1 delegations), the rejection of a bad address or label list and the warning for a team on an instructor address, the instructor side of Labs 7.1-7.4 and the DoQ demo, then restarts the stack to check that keys persist and `expired.example` is re-signed. It takes about 6 minutes, most of it waiting for the team's CDS, and removes everything it made. `KEEP=1 test/run.sh` leaves the stack running.

Tested 2026-10-21 with BIND 9.20.29-1~deb13u1, Knot DNS 3.4.6 and kdig 3.4.6 (Debian 13 packages on `debian:trixie-20261005-slim`), Docker 29.9.1 and Compose 5.6.0: 43 of 43 checks passed. With the Module 1 checks, the empty-address guards and the other-day path added, 2026-10-22: 68 of 68 with BIND 1:9.20.30-1~deb13u1 from trixie-security (DSA-6576-1), images built with `--pull --no-cache` and `DEBIAN_TAG=trixie-slim`. Docker's build cache can keep serving an older `apt-get upgrade` layer: build with `--pull --no-cache` to pick up security updates.

Not tested:
- ipvlan on a real hypervisor NIC (the test uses a bridge);
- Debian's own `docker.io` 26.1 and `docker-compose` 2.26 packages;
- a KSK rollover through `--cds` (Lab 7.4): it uses the same `dnssec-cds` path the test checks, but the rollover itself was not run.
