# Module 9 lab files (registry operations and EPP)

Tested on 2026-10-21 with the Namingo v1.0.34 EPP server and the Net::EPP 0.28 client: two full run-throughs of Labs 9.1-9.5 for paired teams, the second with TLS client certificates required. No private keys, passwords or logs are kept.

- `epp-send`: the participants' client. Perl, needs only the Debian packages `libnet-epp-perl` (Debian 13: 0.28; Debian 12: 0.22, not tested) and `openssl`. Substitutes `NN`, `PP`, `@PASSWORD@` and any `@NAME@` from the environment; makes each clTRID unique.
- `xml/`: one EPP frame per file, numbered by lab task (0x connect, 1x objects, 2x DNSSEC, 3x transfer and renew, 5x delete and restore). All validate against the RFC 5730-5733, 5910 and 3915 schemas.
- `instructor/`: per-team preparation (an aged `oldNN.example` for the restore exercise) and `publish-example-zone.sh` (registry database -> signed `example.` zone).
- `seed-lab.sh`: adds the `.example` TLD and registrars `reg01`..`regNN` to a fresh Namingo MariaDB database.
- `rehearse-pair.sh A B`: the instructor's dry run of Labs 9.1-9.5 for two partner teams; prints the result codes per step. Run it from a copy of this directory that holds `certs/` and `keys/`; never commit those (see `../.gitignore`).
- `server/config.php`: the EPP server settings used (password removed).

## Instructor server build (not yet a tested recipe on a VM)
The test run used Debian 13 packages extracted without root plus Swoole 6.2.3 built from PECL. On the classroom VM the supported route is Namingo's installer (`docs/install.sh`, run as root on Debian 13), which adds third-party apt repositories (packages.sury.org for PHP 8.5 with Swoole, Caddy, MariaDB). Then:
1. Choose MariaDB when asked; keep the system time zone UTC (the installer sets it).
2. `MYSQL="mariadb -uroot" TEAMS=20 LAB_NET=<lab subnet> ./seed-lab.sh`. It writes a random password per registrar to `secrets/passwords.tsv` (mode 600): give each team only its own line.
3. Issue the EPP server certificate and one client certificate per registrar (`extendedKeyUsage=clientAuth`) from a lab CA; store each client certificate's fingerprint: `UPDATE registrar SET ssl_fingerprint='<openssl x509 -outform DER | sha256sum, upper case>' WHERE clid='regNN'`. Hand each team `ca.crt`, `regNN.crt`, `regNN.key`.
4. Set `disable_60days => true`, `mandatory_client_ssl => true` and `ssl_client_ca` (the lab CA) in `/opt/registry/epp/config.php` (see `server/config.php`); restart the EPP service.
5. For each team: `TEAM=NN EPP_PW=$(awk '$1=="regNN"{print $2}' secrets/passwords.tsv) epp-send xml/02-login.xml instructor/prep-1-contact.xml instructor/prep-2-old-domain.xml xml/03-logout.xml`, then `mariadb -uroot < instructor/prep-3-age-old-domains.sql`.
6. Parent zone: in `/opt/registry/automation/config.php` set `dns_server` bind, `ns` = the `example.` name servers, `dns_reload` false, and add `example.php` with the parent's own A record; then every minute during Lab 9.3 run `php write-zone.php && SRC=/var/lib/bind/example.zone DST=<file named loads for example.> ./instructor/publish-example-zone.sh`. Tested 2026-10-21 against BIND 9.20.29 with the Module 7 `lab` policy. Before the first run, register `expired.example`, `wrongds.example` and Module 7 DS records as registry domains, because the writer replaces the whole zone (not tested).
