# Module 2 lab kit: DNS operations - zones, records and data management

Files for Labs 2.1-2.4 of `modules/module02-dns-operations.marp.md`.
In Module 2 each team writes the zone `teamNN.example`, two reverse zones
and the email records, and loads them into BIND 9.20 on its VM 1. The
registry (`example.`, 192.0.2.53 on the slides) has delegated
`teamNN.example` to VM 1 since Module 1, so the Module 1 lab resolver
(192.0.2.55) resolves the team's names as soon as the zone loads.

## Topology (Day 1 afternoon)

| Machine | Address on the slides | Role in Module 2 |
|---|---|---|
| Participant VM 1 | 192.0.2.30 | gets `bind9`, `bind9-utils` and `openssl`; primary for `teamNN.example`, `2.0.192.in-addr.arpa` and the team's `ip6.arpa` zone |
| Participant VM 2 | 192.0.2.10 | not used (resolver and secondary from Module 3) |
| Registry / lab TLD (`parent`) | 192.0.2.53 | serves `example.` with the `teamNN.example` delegations from `teams.conf` |
| Lab resolver (`m01-resolver`) | 192.0.2.55 | recursive for the lab subnet, root hints at the Module 1 lab root: the shared cache for Lab 2.3 |

The instructor stack keeps the `m01` profile on for the whole of Day 1:
Module 2 needs the registry and the lab resolver; the lab root (192.0.2.52)
is the resolver's root. Use the lab sheet addresses in place of the slide
addresses.

## Packages and the offline path

Every lab step talks only to VM 1 and the instructor servers on the lab
network; no Internet access is needed. Installing packages is the only step
that needs a mirror, so build the VM image with them already installed and
`named` stopped (Module 1 relies on nothing answering on VM 1's port 53):

```sh
sudo apt install bind9 bind9-utils openssl    # image build, with a mirror
sudo systemctl disable --now named            # until Lab 2.1
sudo rm /etc/bind/rndc.key                    # before sealing the image
```

Debian's `bind9` postinst runs `rndc-confgen -a` at install time, so every
VM cloned from one image would share `/etc/bind/rndc.key`. Remove it before
sealing the image and create a new one on each VM before `named` first
starts: `sudo rndc-confgen -a -u bind` (`-u bind` lets `named`, which runs as
user `bind`, read it; it replaces an existing key; the slides' Lab Environment, before
`systemctl enable --now named`). The default control channel listens on
127.0.0.1 only, so a shared key is a small risk, but it is a needless one.

Lab 2.1 then makes the VM's own rndc key and starts it:
`sudo rndc-confgen -a -u bind; sudo systemctl enable --now named`. With a
mirror in class, `sudo apt install bind9 bind9-utils openssl` in Lab 2.1
installs and starts `named` in one step.

Debian 13's `bind9` installs `named.conf`, `named.conf.local`,
`named.conf.options` (only `directory "/var/cache/bind"`) and
`named.conf.root-hints`; it ships no example zone files. Module 2 changes
only `named.conf.local` and puts its zone files in `/var/lib/bind`;
`named.conf.options` stays as installed, so the server still offers
recursion to its own subnet (`ra` in every answer) until Module 6 Lab 6.1.

## Files

| File | Where it goes | Lab |
|---|---|---|
| `zones/db.teamNN.example` | `/var/lib/bind/db.teamNN.example` (your number); SOA, NS and `ns1` to start from | 2.1, 2.3, 2.4 |
| `zones/db.192.0.2` | `/var/lib/bind/db.192.0.2`: reverse zone `2.0.192.in-addr.arpa` | 2.2 |
| `zones/db.2001-db8-NN` | `/var/lib/bind/db.2001-db8-NN`: reverse zone for `2001:db8:NN::/48` | 2.2 |
| `zones/named.conf.local` | the three `zone` statements for `/etc/bind/named.conf.local` | 2.1, 2.2 |
| `broken/db.broken.example` | your home directory: a zone file with seven mistakes to find | 2.2 |
| `test/` | rehearsal harness (below); not for participants | - |

`sed -i 's/NN/01/g'` sets the team number in a copied template (the comments
are worded to read correctly afterwards). In the IPv6 reverse zone name,
`N2.N1` are the two digits of the team number in reverse order (team 01:
`1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa`; team 12: `2.1.0.0.8.b.d.0.1.0.0.2.ip6.arpa`).

Zone files go in `/var/lib/bind`, not `/etc/bind`: Debian's AppArmor profile
for `named` allows `/etc/bind/** r` but `/var/lib/bind/** rw`, and Module 7
signs `teamNN.example` inline, which writes `db.teamNN.example.signed` and
its journal next to the zone file. With the file in `/etc/bind`, Lab 7.2
would fail on a VM with AppArmor enforcing. Configuration stays in
`/etc/bind`.

If your lab sheet subnet is not 192.0.2.0/24, delete the `30` (ns1) PTR line
from `db.192.0.2`: the zone then holds only the PTRs for 192.0.2.80-82, the
data addresses every team keeps.

Through the lab resolver, `dig -x` for 192.0.2.0/24 or 2001:db8::/32 gets
NXDOMAIN with `aa` from the resolver itself: BIND serves the RFC 6303
locally served zones (`2.0.192.IN-ADDR.ARPA`, `8.B.D.0.1.0.0.2.IP6.ARPA`
among them) as built-in empty zones, on by default. Lab 2.2 step 3 asks
participants to read that SOA. `dig @192.0.2.55 -x <address> +noall
+question` therefore prints the reverse name at once, which is why the kit
and slides name that server.

Every TTL in the lab zones is 60 seconds or less: changes are visible
within a minute in Lab 2.3, and the lab signing policy for Module 7 in the
workshop plan (Appendix A, Module 7) sets `max-zone-ttl 60`, which makes
BIND reject a zone with a longer TTL. Lab 2.3 step 6 checks this with
`named-checkzone -l 60`. (The `lab` policy in `../module07/auth/named.conf`
has 300 today and `lab2` has 60; that is an open question for Module 7.)

The names `www` (192.0.2.80), `mail` (192.0.2.81) and `ftp` (192.0.2.82)
keep these addresses: Modules 6 to 8 query them.

## Keys and secrets

Nothing secret is in this kit. In Lab 2.4 each participant makes a lab
DKIM key with `openssl genpkey` in their home directory on VM 1 (not in
`/etc/bind` or `/var/lib/bind`); only the public half goes into the zone. `../.gitignore`
blocks `*.private`, `*.key` and `*.pem` in case a key is copied into the
repository by mistake.

## Tested

2026-10-27, and again 2026-10-28 after the review fixes, on a Debian 13 host
with Docker 29.9.2 and Compose 5.6.1; images
rebuilt with `build --pull --no-cache`, so that the instructor BIND image and
the stand-in VM carry `bind9`, `bind9-utils` and `bind9-dnsutils`
1:9.20.30-1~deb13u1 (trixie-security) and `openssl` 3.5.7-1~deb13u3.

- `test/rehearse.sh`: starts the instructor stack (profile `m01`, as on
  Day 1) on an internal Docker bridge, puts a stand-in VM 1 at 192.0.2.30
  with this kit mounted, and runs every step of Labs 2.1-2.4 as the slides
  give them: the Day 1 SERVFAIL, a new rndc key for the VM, writing and
  checking the zone, `named-checkconf -z` as an unprivileged user, loading
  it, each record type, the resolver answering, the registry's NS and glue
  compared with the zone's (each side, then `diff`), both reverse zones, the
  lab resolver's RFC 6303 empty-zone answer (`aa` and its own SOA), the
  ip6.arpa zone name for team 12 as well as 01, all seven mistakes in the broken
  file (in the order `named-checkzone` reports them), the TTL countdown, a
  change waiting for the TTL, a planned change with a 10-second TTL, the
  negative cache, the unchanged-serial warning, `-l 60`, the DKIM key split
  into strings, SPF, null MX and DMARC, and the DKIM key read back from the
  DNS with `cmp`. Every reload step reads the new serial back with
  `rndc zonestatus`. About 4 minutes with the images built, most of it
  waiting for TTLs. It removes
  every container, network and volume it made; the transcript goes to the
  file given as the first argument, or to a new file under `$TMPDIR`
  (default `/tmp`), never into the repository.
- Messages quoted on the slides (`named-checkzone`, `rndc`, the serial
  warning) are copied from the transcripts and from `named-checkzone` runs
  recorded in the course's notes.

Not tested:

- real VMs: `sudo`, `systemctl enable --now named`, `journalctl -u named`
  (the harness runs `named -u bind -g` as root in the container and reads
  its log file instead), AppArmor (Docker images do not load the profile:
  the `/var/lib/bind` location follows the Debian profile's rules, read from
  the package, not from a VM enforcing it);
- `apt install` in class (the stand-in VM is built with the packages);
- the instructor stack on ipvlan with a real classroom NIC;
- IPv6 transport (the lab is IPv4-only; the AAAA and `ip6.arpa` data do not
  need it).
