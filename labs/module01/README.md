# Module 1 lab kit: Introduction to DNS

Files and instructor notes for Labs 1.1-1.3 of `modules/module01-dns-foundations.marp.md`.
Module 1 is taught before participants build any server, so the labs use
only client tools on the participant's VM and servers that the instructor
runs: the real Internet DNS (Lab 1.1, when outbound port 53 is open) and a
small lab hierarchy in the instructor stack (`../instructor`, profile `m01`).

## Topology on Day 1

| Machine | Address on the slides | State on Day 1 |
|---|---|---|
| Participant VM 1 (`teamNN` authoritative server in Modules 2-9; the client in Modules 6-8) | 192.0.2.30 | Debian 13 with `bind9-dnsutils`, `bind9-host`, `tcpdump`, `tshark`; no DNS server |
| Participant VM 2 (`teamNN` resolver from Module 3) | 192.0.2.10 | not used |
| Lab root (`m01-root`) | 192.0.2.52 | serves `.` (delegates `example.` and `root-servers.test`) and `root-servers.test` |
| Registry / lab TLD (`parent`) | 192.0.2.53 | serves `example.`, as in Modules 6-9 |
| Lab child (`m01-child`) | 192.0.2.54 | serves `good.example`, `charlie.example`, `delta.example` |
| Lab resolver (`m01-resolver`) | 192.0.2.55 | recursive for the lab subnet; its root hints point at the lab root, so it resolves only the lab hierarchy |

Participants log in to VM 1 over SSH from their laptops. Captures are taken
with `sudo tcpdump` and read with `tshark -r` (no root needed); the file can
be copied to a laptop for the Wireshark GUI. Use the lab sheet addresses in
place of the slide addresses.

## Online and offline

- **With outbound port 53:** Lab 1.1 queries the real root, TLD and
  authoritative servers at interactive rates, and uses `dig +trace`.
- **Without:** Lab 1.1 walks the lab hierarchy by hand with `+norec`
  (`@192.0.2.52` -> `@192.0.2.53` -> `@192.0.2.54` for `www.good.example`).
  `dig +trace` is left out: dig 9.20 looks up every server name through the
  VM's own resolver and ignores the glue it prints, so with the classroom
  resolver (which uses the real root) it stops at "couldn't get address for
  'a.root-servers.test'".
- **Labs 1.2 and 1.3** use only the lab servers, so they run the same way in
  both cases. IPv6 transport (`dig -6`) works only where the classroom has
  IPv6; the AAAA data and `dig -x` names do not need it.

## Files

| File | What it is |
|---|---|
| `test/rehearse.sh [TRANSCRIPT]` | starts the instructor stack (profile `m01`, default zone labels) on an internal Docker bridge, puts a stand-in VM 1 at 192.0.2.30, runs every lab command that uses the lab servers and checks each checkpoint; removes everything afterwards. The transcript goes to TRANSCRIPT or to a new file under `$TMPDIR` (default `/tmp`), never into the repository |
| `test/Dockerfile` | the stand-in VM 1: Debian 13 with the Module 1 client tools only |

The lab servers themselves are in `../instructor` (`module01/` configs,
`images/bind/m01-run`, the `m01` services in `compose.yaml`, the Module 1
delegations in `images/bind/make-example-zone`).

## Instructor side

Set-up, the fault labels for assessed runs and the Lab 1.3 answer key are in
`../instructor/module01/README.md`, outside this participant kit.

## Tested

2026-10-22, on a Debian 13 host with Docker 29.9.1 and Compose 5.6.0, with
images rebuilt (`--pull --no-cache`, `DEBIAN_TAG=trixie-slim`) so that they
carry BIND 1:9.20.30-1~deb13u1 from trixie-security (DSA-6576-1):

- `../instructor/test/run.sh`: 68 of 68 checks, including the Module 1
  hierarchy under non-default fault labels.
- `test/rehearse.sh`: 39 of 39 checks; stand-in VM with bind9-dnsutils and
  bind9-host 1:9.20.30-1~deb13u1, tcpdump 4.99.5-2, tshark 4.4.19-0+deb13u1.
  The capture uses the slide's command (`tcpdump -i any -n -U`, stopped
  with Ctrl-C a few seconds after the last query) and kept the TCP retries.
- Both scripts left no containers, networks or volumes, and no transcript
  in the repository.
- Lab 1.1 online steps on the host itself (bind9-dnsutils 9.20.29, IPv4 and
  IPv6 Internet access): real root, `com`, `org`, `nz`, `fj`, `xn--p1ai` and
  `arpa` referrals, `dig +trace`, `hostname.bind`/`+nsid`, `dig -6`,
  `host`, `nslookup`, `dig -x`.
- `getent hosts` reads `/etc/hosts`; `dig`, `host` and `nslookup` do not.
  `host` and `nslookup` use the `search` list; `dig` does only with
  `+search`.

Not tested:

- real participant VMs: `sudo`, SSH, and capture with `tcpdump -i any` on a
  VM's own interface (tested inside a container as root);
- the Wireshark GUI (only `tshark`);
- the instructor stack on ipvlan with a real classroom NIC (the tests use an
  internal bridge, where 198.51.100.0/24 fails at once with "network
  unreachable"). With that range silently dropped, as behind a classroom
  gateway, the code review measured about 10 s to SERVFAIL for the
  no-server zone and about 0.9 s for the first stale-glue lookup;
- IPv6 transport inside the lab hierarchy (the stack is IPv4-only).

Before a class, rebuild the instructor images with
`docker compose build --pull --no-cache` so they carry the current Debian 13
security updates, then start them with `docker compose up -d`, not
`up -d --build` (see Images in `../instructor/README.md`).
