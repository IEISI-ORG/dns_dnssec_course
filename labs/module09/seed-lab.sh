#!/bin/bash
# seed-lab.sh: add the lab TLD and one registrar account per team to a fresh
# Namingo registry database (MariaDB). Tested 2026-10-21 against Namingo v1.0.34.
#   MYSQL="mariadb -uroot" TEAMS=20 ./seed-lab.sh
#   MYSQL="mariadb -uroot" FIRST=21 TEAMS=22 TLD=0 ./seed-lab.sh   # add teams 21-22 later
# Each team NN gets registrar regNN with EPP password Lab-pass-NN (change these
# for a real class), allowed from LAB_NET (default 127.0.0.1; set your lab subnet).
set -euo pipefail
MYSQL=${MYSQL:-mariadb -uroot}
TEAMS=${TEAMS:-2}
FIRST=${FIRST:-1}
TLD=${TLD:-1}
LAB_NET=${LAB_NET:-127.0.0.1}
{
echo 'USE registry;'
[ "$TLD" = 1 ] && cat <<'SQL'
INSERT INTO domain_tld (tld, idn_table, secure)
  VALUES ('.example', '/^(?!-)(?!.*--)[A-Z0-9-]{1,63}(?<!-)(.(?!-)(?!.*--)[A-Z0-9-]{1,63}(?<!-))*$/i', 0);
SET @tld = LAST_INSERT_ID();
INSERT INTO domain_price (tldid, command, m0, m12, m24, m36, m48, m60, m72, m84, m96, m108, m120)
  SELECT @tld, command, m0, m12, m24, m36, m48, m60, m72, m84, m96, m108, m120 FROM domain_price WHERE tldid = 1;
INSERT INTO domain_restore_price (tldid, price) VALUES (@tld, '50.00');
SQL
for i in $(seq "$FIRST" "$TEAMS"); do
  n=$(printf %02d "$((10#$i))")
  hash=$(php -r "echo password_hash('Lab-pass-$n', PASSWORD_ARGON2ID, ['memory_cost'=>65536,'time_cost'=>3,'threads'=>1]);")
  cat <<SQL
INSERT INTO registrar (name, clid, pw, prefix, email, whois_server, rdap_server, url, abuse_email, abuse_phone,
  accountBalance, creditLimit, creditThreshold, thresholdType, currency, companyNumber, crdate, lastupdate)
  SELECT 'Lab Registrar $n', 'reg$n', '$hash', 'R$n', 'reg$n@registrar.example', whois_server, rdap_server,
  'https://registrar.example', 'abuse-reg$n@registrar.example', abuse_phone, 100000, 100000, 500, 'fixed',
  currency, companyNumber, NOW(), NOW() FROM registrar WHERE clid = 'leonet';
SET @r = LAST_INSERT_ID();
INSERT INTO registrar_whitelist (registrar_id, addr) VALUES (@r, '$LAB_NET');
INSERT INTO registrar_contact (registrar_id, type, title, first_name, middle_name, last_name, org, street1, street2,
  street3, city, sp, pc, cc, voice, fax, email)
  SELECT @r, type, title, first_name, middle_name, last_name, org, street1, street2, street3, city, sp, pc, cc,
  voice, fax, email FROM registrar_contact WHERE registrar_id = 1;
SQL
done
} | $MYSQL
