#!/bin/bash
# rehearse.sh [TRANSCRIPT]: run every Module 2 lab step (Labs 2.1-2.4) on a
# stand-in participant VM 1 and check each checkpoint.
#
# It starts the instructor stack (../../instructor, profile m01: the registry
# for example. and the Module 1 lab resolver) on an internal Docker bridge
# with no route out, as Module 1's harness does, plus a Debian 13 container at
# 192.0.2.30 with bind9, bind9-utils, bind9-dnsutils and openssl: the team's
# VM 1. teams.conf delegates team01.example to it. The participant's typing
# is the heredocs below; the kit files come from ../zones and ../broken.
# Everything is removed at the end. The transcript goes to TRANSCRIPT, or to
# a new file under ${TMPDIR:-/tmp} whose name is printed. Needs Docker with
# Compose v2; about 4 minutes with images already built, most of it Lab 2.3
# waiting for TTLs to run out. The lab steps need no Internet access; the
# image build does.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "$here/.." && pwd)
INS=$(cd "$here/../../instructor" && pwd)
OUT=${1:-$(mktemp "${TMPDIR:-/tmp}/m02-rehearsal.XXXXXX")}
W=$(mktemp -d)
unset M01_FAULT_LABELS
PROJ=dnslab-m02
VM=dnslab-m02-vm
export COMPOSE_PROFILES=m01 CLASSROOM_DIR=$W/classroom HANDOUT_DIR=$W/handout
DC=(docker compose -p "$PROJ" --env-file "$INS/test/test.env" -f "$INS/compose.yaml" -f "$INS/compose.test.yaml")
Z=/var/lib/bind/db.team01.example
pass=0; fail=0

stop_lab() {
    docker rm -f "$VM" >/dev/null 2>&1
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
}
trap 'stop_lab; rm -rf "$W"' EXIT

log() { printf '%s\n' "$@" >> "$OUT"; }
# step NAME COMMAND REGEX...: run COMMAND on the VM, keep it in the
# transcript, PASS if the output matches every REGEX (a leading ! negates)
step() {
    local name=$1 cmd=$2 out r ok=1; shift 2
    out=$(docker exec "$VM" bash -c "$cmd" 2>&1)
    { echo "\$ $cmd"; echo "$out"; echo; } >> "$OUT"
    for r in "$@"; do
        if [[ $r == !* ]]; then grep -Eq -- "${r#!}" <<< "$out" && ok=0
        else grep -Eq -- "$r" <<< "$out" || ok=0; fi
    done
    if [ "$ok" = 1 ]; then echo "PASS  $name"; pass=$((pass + 1))
    else echo "FAIL  $name"; fail=$((fail + 1)); sed -n '1,8s/^/        /p' <<< "$out"; fi
}
# vm COMMAND: run quietly on the VM (input from stdin), keep it in the transcript
vm() { log "\$ $1"; docker exec -i "$VM" bash -c "$1" >> "$OUT" 2>&1; }
# ttl NAME: the TTL the lab resolver reports for NAME's A record (empty if none)
ttl() { docker exec "$VM" dig @192.0.2.55 "$1" A +noall +answer | awk '$4 == "A" {print $2; exit}'; }
# reload NAME SERIAL: the participant's "raise the serial, check, reload"
# after an edit; the server must report the new serial
reload() {
    step "$1" "named-checkzone team01.example $Z && rndc reload team01.example && sleep 1 && rndc zonestatus team01.example" \
        "loaded serial $2" 'zone reload queued' "serial: $2"
}

stop_lab
mkdir "$W/classroom" "$W/handout"
echo "01 192.0.2.30" > "$W/classroom/teams.conf"
: > "$OUT" || exit 1
"${DC[@]}" up -d --build --quiet-pull init parent m01-root m01-child m01-resolver >/dev/null 2>&1 \
    || { "${DC[@]}" logs; exit 1; }
docker build -q --build-arg DEBIAN_TAG="${DEBIAN_TAG:-trixie-20261005-slim}" -t dnslab/m02-vm:local "$here" >/dev/null || exit 1
docker run -d --name "$VM" --network "${PROJ}_lab" --ip 192.0.2.30 \
    -v "$KIT:/kit:ro" dnslab/m02-vm:local >/dev/null || exit 1
for _ in $(seq 30); do
    docker exec "$VM" dig @192.0.2.55 +short www.good.example A 2>/dev/null | grep -q . && break
    sleep 1
done
docker exec "$VM" dig @192.0.2.55 +short www.good.example A 2>/dev/null | grep -q . \
    || { echo "lab resolver not answering"; "${DC[@]}" logs; exit 1; }

{ echo "# Module 2 rehearsal, $(date -u +%Y-%m-%dT%H:%MZ)"
  docker exec "$VM" sh -c 'named -v; dig -v 2>&1; openssl version'
  echo; } >> "$OUT"

echo "== Before Lab 2.1: the Day 1 state (no server on VM 1)"
step "0.1 resolver: SERVFAIL for the team zone" "dig @192.0.2.55 www.team01.example" 'status: SERVFAIL'
step "0.2 packages: BIND 9.20 from Debian 13" "named -v; dpkg-query -W bind9 bind9-utils" \
    '^BIND 9\.20\.' 'bind9[[:space:]]+1:9\.20' 'bind9-utils[[:space:]]+1:9\.20'

echo "== Lab 2.1: write, check and load teamNN.example"
vm "sed 's/NN/01/g' /kit/zones/db.teamNN.example > $Z"
vm "cat >> $Z" <<'EOF'
@       IN A     192.0.2.80
        IN AAAA  2001:db8:1::80
        IN HTTPS 0 www
        IN MX    10 mail
        IN CAA   0 issue "ca.example.net"
        IN CAA   0 iodef "mailto:hostmaster@team01.example"
www     IN A     192.0.2.80
        IN AAAA  2001:db8:1::80
        IN HTTPS 1 . alpn="h2"
web     IN CNAME www
mail    IN A     192.0.2.81
        IN AAAA  2001:db8:1::81
ftp     IN A     192.0.2.82
_imaps._tcp IN SRV 0 1 993 mail
EOF
step "2.1.1 named-checkzone: loaded, OK" "named-checkzone team01.example $Z" \
    'zone team01\.example/IN: loaded serial 2026102701' '^OK$' '!warning|error'
step "2.1.2 named-compilezone shows every name in full" "named-compilezone -o - team01.example $Z 2>/dev/null" \
    '^web\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+CNAME[[:space:]]+www\.team01\.example\.' \
    '^team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+MX[[:space:]]+10 mail\.team01\.example\.' \
    '^_imaps\._tcp\.team01\.example\..*SRV[[:space:]]+0 1 993 mail\.team01\.example\.'
# the image's key is replaced by a new one, as on a VM cloned from an image;
# then named starts with no zones and the zone arrives with rndc reload
step "2.1.0 a new rndc key for this VM, readable by named" \
    "md5sum < /etc/bind/rndc.key; rndc-confgen -a -u bind && md5sum < /etc/bind/rndc.key && stat -c '%U %a' /etc/bind/rndc.key" \
    'wrote key file "/etc/bind/rndc\.key"' '^bind [0-7]+$'
docker exec "$VM" install -d -o bind -g bind /run/named
docker exec -d "$VM" sh -c 'exec named -u bind -g > /var/log/named.out 2>&1'
for _ in $(seq 20); do docker exec "$VM" rndc status >/dev/null 2>&1 && break; sleep 0.5; done
vm "sed -n '/^zone \"teamNN.example\"/,/^};/p' /kit/zones/named.conf.local | sed 's/NN/01/g' >> /etc/bind/named.conf.local"
step "2.1.3 named-checkconf -z loads the zone as named will, without root" "su nobody -s /bin/sh -c 'named-checkconf -z'; echo rc=\$?" \
    'zone team01\.example/IN: loaded serial 2026102701' '^rc=0$'
step "2.1.4 rndc reload" "rndc reload; sleep 1; rndc zonestatus team01.example" \
    'server reload successful' 'serial: 2026102701' 'type: primary'
step "2.1.5 SOA from the VM itself: authoritative" "dig @127.0.0.1 team01.example SOA +norec" \
    'flags: qr aa ra;' 'SOA[[:space:]]+ns1\.team01\.example\. hostmaster\.team01\.example\. 2026102701 3600 600 1209600 60'
step "2.1.6 each type" "for t in A AAAA MX CAA HTTPS; do dig @127.0.0.1 team01.example \$t +norec +short; done; dig @127.0.0.1 web.team01.example +norec +noall +answer; dig @127.0.0.1 _imaps._tcp.team01.example SRV +norec +short; dig @127.0.0.1 www.team01.example HTTPS +norec +short" \
    '^192\.0\.2\.80$' '^2001:db8:1::80$' '^10 mail\.team01\.example\.$' '^0 issue "ca\.example\.net"$' \
    '^0 www\.team01\.example\.$' 'CNAME[[:space:]]+www\.team01\.example\.' '^0 1 993 mail\.team01\.example\.$' '^1 \. alpn="h2"$'
step "2.1.7 MX answer carries the mail server's addresses" "dig @127.0.0.1 team01.example MX +norec" \
    'ANSWER: 1,' 'ADDITIONAL SECTION' '^mail\.team01\.example\..*A[[:space:]]+192\.0\.2\.81' \
    '^mail\.team01\.example\..*AAAA[[:space:]]+2001:db8:1::81' '^ns1\.team01\.example\..*A[[:space:]]+192\.0\.2\.30'
step "2.1.8 the Day 1 worked example is fixed: resolver NOERROR" "dig @192.0.2.55 www.team01.example" \
    'status: NOERROR' 'flags: qr rd ra;' '192\.0\.2\.80'
step "2.1.9a registry: NS and glue for team01" \
    "dig @192.0.2.53 team01.example NS +norec +noall +authority +additional" \
    '^team01\.example\..*NS[[:space:]]+ns1\.team01\.example\.' '^ns1\.team01\.example\..*A[[:space:]]+192\.0\.2\.30'
step "2.1.9b zone: the same NS and ns1 address, authoritative" \
    "dig @192.0.2.30 team01.example NS +norec +noall +comments +answer +additional" \
    'flags: qr aa' '^team01\.example\..*NS[[:space:]]+ns1\.team01\.example\.' '^ns1\.team01\.example\..*A[[:space:]]+192\.0\.2\.30'
step "2.1.9c the two NS and address sets are the same" \
    "diff <(dig @192.0.2.53 team01.example NS +norec +noall +authority +additional | awk '{print \$1,\$4,\$5}' | sort) <(dig @192.0.2.30 team01.example NS +norec +noall +answer +additional | awk '{print \$1,\$4,\$5}' | sort) && echo same" \
    '^same$'
out=$("${DC[@]}" exec -T m01-resolver dig @192.0.2.30 www.team01.example +norec 2>&1)
log "\$ dig @192.0.2.30 www.team01.example +norec   (from another host on the lab network)" "$out" ""
if grep -q 'flags: qr aa ra;' <<< "$out"; then echo "PASS  2.1.10 another host gets aa (and ra: Debian's default recursion for localnets) from VM 1"; pass=$((pass + 1))
else echo "FAIL  2.1.10 another host gets aa (and ra) from VM 1"; fail=$((fail + 1)); fi

echo "== Lab 2.2: reverse zones, then a broken zone file"
vm "sed 's/NN/01/g' /kit/zones/db.192.0.2 > /var/lib/bind/db.192.0.2"
vm "cat >> /var/lib/bind/db.192.0.2" <<'EOF'
80      IN PTR  www.team01.example.
81      IN PTR  mail.team01.example.
82      IN PTR  ftp.team01.example.
EOF
vm "sed 's/NN/01/g' /kit/zones/db.2001-db8-NN > /var/lib/bind/db.2001-db8-01"
step "2.2.1 dig -x gives the PTR owner name for mail's IPv6 address" "dig @192.0.2.55 -x 2001:db8:1::81 +noall +question" \
    '^;1\.8\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.1\.0\.0\.0\.8\.b\.d\.0\.1\.0\.0\.2\.ip6\.arpa\.[[:space:]]+IN[[:space:]]+PTR'
vm "cat >> /var/lib/bind/db.2001-db8-01" <<'EOF'
1.8.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR mail.team01.example.  ; 2001:db8:1::81
EOF
vm "sed -n '/^zone \"2.0.192/,\$p' /kit/zones/named.conf.local | sed -e 's/NN/01/g' -e 's/N2\\.N1/1.0/' >> /etc/bind/named.conf.local"
step "2.2.2 both reverse zones check" \
    "named-checkzone 2.0.192.in-addr.arpa /var/lib/bind/db.192.0.2 && named-checkzone 1.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa /var/lib/bind/db.2001-db8-01 && named-checkconf -z" \
    'zone 2\.0\.192\.in-addr\.arpa/IN: loaded serial 2026102701' 'zone 1\.0\.0\.0\.8\.b\.d\.0\.1\.0\.0\.2\.ip6\.arpa/IN: loaded serial 2026102701'
step "2.2.3 rndc reload; PTR for IPv4 and IPv6" \
    "rndc reload >/dev/null; sleep 1; dig @127.0.0.1 -x 192.0.2.80 +norec; dig @127.0.0.1 -x 2001:db8:1::81 +norec +short" \
    'flags: qr aa ra;' '^80\.2\.0\.192\.in-addr\.arpa\..*PTR[[:space:]]+www\.team01\.example\.' '^mail\.team01\.example\.$'
step "2.2.4 forward-confirmed: PTR target resolves back to the address" \
    "n=\$(dig @127.0.0.1 -x 192.0.2.81 +norec +short); echo \$n; dig @127.0.0.1 \$n A +norec +short" \
    '^mail\.team01\.example\.$' '^192\.0\.2\.81$'
step "2.2.5 the lab resolver answers from its own RFC 6303 empty zone" \
    "dig @192.0.2.55 -x 192.0.2.80" 'status: NXDOMAIN' 'flags: qr aa rd ra;' \
    '^2\.0\.192\.IN-ADDR\.ARPA\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+SOA[[:space:]]+2\.0\.192\.IN-ADDR\.ARPA\. \. 0 '
step "2.2.5b the same for the IPv6 documentation prefix" \
    "dig @192.0.2.55 -x 2001:db8:1::81" 'status: NXDOMAIN' 'flags: qr aa rd ra;' '^8\.B\.D\.0\.1\.0\.0\.2\.IP6\.ARPA\..*SOA'
step "2.2.5c another team number (12): digit order in the ip6.arpa zone name" \
    "sed 's/NN/12/g' /kit/zones/db.2001-db8-NN > /root/t12 && named-checkzone 2.1.0.0.8.b.d.0.1.0.0.2.ip6.arpa /root/t12; dig @192.0.2.55 -x 2001:db8:12::80 +noall +question" \
    'zone 2\.1\.0\.0\.8\.b\.d\.0\.1\.0\.0\.2\.ip6\.arpa/IN: loaded serial' '^;0\.8\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.2\.1\.0\.0\.8\.b\.d\.0\.1\.0\.0\.2\.ip6\.arpa\.'
vm "cp /kit/broken/db.broken.example /root/"
step "2.2.6 broken file, pass 1: four messages" "cd /root && named-checkzone broken.example db.broken.example" \
    "near '20261027001': out of range" "near '192\.0\.2\.8O': bad dotted quad" 'web\.broken\.example: CNAME and other data' \
    'mail_relay\.broken\.example: bad owner name \(check-names\)' 'not loaded due to errors'
vm "cd /root && sed -i -e 's/20261027001/2026102701/' -e 's/192.0.2.8O/192.0.2.80/' -e '/^web .*TXT/d' db.broken.example"
step "2.2.7 pass 2: ns2 has no address" "cd /root && named-checkzone broken.example db.broken.example" \
    "NS 'ns2\.broken\.example' has no address records" 'not loaded due to errors'
vm "cd /root && sed -i 's/^ns1 .*/&\nns2     IN A    192.0.2.54/' db.broken.example"
step "2.2.8 pass 3: loads, with two warnings" "cd /root && named-checkzone broken.example db.broken.example" \
    "MX 'mail\.broken\.example\.broken\.example' has no address records" 'bad owner name' '^OK$'
step "2.2.9 -k fail: check-names as named applies it to a primary zone" "cd /root && named-checkzone -k fail broken.example db.broken.example" \
    'bad owner name \(check-names\)' 'not loaded due to errors'
step "2.2.10 named-compilezone shows the doubled names" "cd /root && named-compilezone -o - broken.example db.broken.example 2>/dev/null" \
    '^ftp\.broken\.example\.broken\.example\.' 'MX[[:space:]]+10 mail\.broken\.example\.broken\.example\.'
vm "cd /root && sed -i -e 's/mail_relay/mail-relay/' -e 's/mail\\.broken\\.example\$/mail.broken.example./' -e 's/^ftp\\.broken\\.example IN/ftp IN/' db.broken.example"
step "2.2.11 all seven fixed: clean with -k fail" "cd /root && named-checkzone -k fail broken.example db.broken.example" \
    '^OK$' '!warning|has no address|bad owner'

echo "== Lab 2.3: TTLs and caching (through the lab resolver)"
vm "sed -i 's/2026102701 ; serial/2026102702 ; serial/' $Z && echo 'app     IN A     192.0.2.84' >> $Z"
reload "2.3.0 add app (serial 02), check, reload" 2026102702
docker exec "$VM" dig @192.0.2.55 app.team01.example A +noall +answer >/dev/null
t1=$(ttl app.team01.example); sleep 5; t2=$(ttl app.team01.example)
log "resolver TTL for app: $t1, then 5 s later $t2"
if [ -n "$t1" ] && [ -n "$t2" ] && [ "$t2" -lt "$t1" ] && [ "$t1" -le 60 ]; then echo "PASS  2.3.1 resolver TTL counts down ($t1 then $t2)"; pass=$((pass + 1))
else echo "FAIL  2.3.1 resolver TTL counts down ($t1 then $t2)"; fail=$((fail + 1)); fi
step "2.3.2 the zone's own server always says 60" "dig @192.0.2.30 app.team01.example +norec +noall +answer" \
    '^app\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.84'
vm "sed -i -e 's/2026102702 ; serial/2026102703 ; serial/' -e 's/^app .*/app     IN A     192.0.2.85/' $Z"
reload "2.3.3 change app to .85 (serial 03)" 2026102703
step "2.3.4 server has the new address, the resolver's cache the old" \
    "dig @192.0.2.30 app.team01.example +norec +short; dig @192.0.2.55 app.team01.example +norec +noall +answer" \
    '^192\.0\.2\.85$' 'app\.team01\.example\..*A[[:space:]]+192\.0\.2\.84'
rest=$(ttl app.team01.example); log "resolver copy expires in ${rest:-?} s"
sleep $(( ${rest:-60} + 2 ))
step "2.3.5 after the TTL ran out the resolver has the new address" "dig @192.0.2.55 app.team01.example +noall +answer" \
    'app\.team01\.example\.[[:space:]]+(60|59|58)[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.85'
vm "sed -i -e 's/2026102703 ; serial/2026102704 ; serial/' -e 's/^app .*/app  10 IN A     192.0.2.85/' $Z"
reload "2.3.6 planned change, part 1: lower app's TTL to 10 (serial 04)" 2026102704
rest=$(ttl app.team01.example); log "old copy (TTL 60) expires in ${rest:-?} s"
sleep $(( ${rest:-60} + 2 ))
step "2.3.7 the resolver now holds the 10-second copy" "dig @192.0.2.55 app.team01.example +noall +answer" \
    'app\.team01\.example\.[[:space:]]+(10|9|8)[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.85'
vm "sed -i -e 's/2026102704 ; serial/2026102705 ; serial/' -e 's/^app .*/app  10 IN A     192.0.2.86/' $Z"
reload "2.3.8 part 2: change the address to .86 (serial 05)" 2026102705
sleep 11
step "2.3.9 within 10 s the resolver has .86" "dig @192.0.2.55 app.team01.example +noall +answer" 'A[[:space:]]+192\.0\.2\.86'
step "2.3.10 negative answer: NXDOMAIN, SOA in authority with TTL at most 60" \
    "dig @192.0.2.55 new.team01.example" 'status: NXDOMAIN' '^team01\.example\.[[:space:]]+(60|5[0-9])[[:space:]]+IN[[:space:]]+SOA'
vm "sed -i -e 's/2026102705 ; serial/2026102706 ; serial/' $Z && echo 'new     IN A     192.0.2.87' >> $Z"
reload "2.3.11 add new (serial 06)" 2026102706
step "2.3.12 the resolver still answers NXDOMAIN from its negative cache" "dig @192.0.2.55 new.team01.example" \
    'status: NXDOMAIN'
nt=$(docker exec "$VM" dig @192.0.2.55 new.team01.example +noall +authority | awk '$4 == "SOA" {print $2; exit}')
log "negative copy expires in ${nt:-?} s"
sleep $(( ${nt:-60} + 2 ))
step "2.3.13 after the negative TTL the name appears" "dig @192.0.2.55 new.team01.example +short" '^192\.0\.2\.87$'
vm "sed -i 's/^app  10 IN A/app     IN A/' $Z"
step "2.3.14 edit without raising the serial: named warns" \
    "rndc reload team01.example; sleep 1; grep 'serial (2026102706) unchanged' /var/log/named.out | tail -1" \
    'zone team01\.example/IN: zone serial \(2026102706\) unchanged\. zone may fail to transfer to secondaries\.'
vm "sed -i 's/2026102706 ; serial/2026102707 ; serial/' $Z"
reload "2.3.15 raise the serial (07) and reload" 2026102707
step "2.3.16 named-checkzone -l 60: no TTL above Module 7's limit" "named-checkzone -l 60 team01.example $Z" '^OK$'
step "2.3.17 -l 60 rejects a 3600 s record" \
    "cp $Z /root/ttl.db && echo 'old 3600 IN A 192.0.2.88' >> /root/ttl.db && named-checkzone -l 60 team01.example /root/ttl.db" \
    'TTL 3600 exceeds configured max-zone-ttl 60' 'not loaded due to errors'

echo "== Lab 2.4: email records"
vm "cd /root && openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out lab1.private 2>/dev/null && openssl pkey -in lab1.private -pubout -outform DER | base64 -w0 > lab1.pub"
step "2.4.1 the DKIM public key is too long for one string" "cd /root && wc -c < lab1.pub; fold -w 250 lab1.pub | sed 's/.*/\"&\"/' | awk '{print length}'" \
    '^392$' '^252$' '^144$'
key=$(docker exec "$VM" sh -c 'cd /root && fold -w 250 lab1.pub | sed "s/.*/\"&\"/"')
vm "cp $Z /root/one.db && printf 'lab1._domainkey IN TXT \"v=DKIM1; k=rsa; p=%s\"\n' \"\$(cat /root/lab1.pub)\" >> /root/one.db"
step "2.4.2 the whole key in one string: syntax error" "named-checkzone team01.example /root/one.db" \
    'one\.db:[0-9]+: syntax error' 'not loaded due to errors'
vm "sed -i 's/2026102707 ; serial/2026102708 ; serial/' $Z && cat >> $Z" <<EOF
@       IN TXT   "v=spf1 mx -all"
ftp     IN MX    0 .
        IN TXT   "v=spf1 -all"
lab1._domainkey IN TXT ( "v=DKIM1; k=rsa; p="
$key )
_dmarc  IN TXT   "v=DMARC1; p=none; rua=mailto:dmarc-reports@team01.example"
EOF
step "2.4.3 check: OK, nothing to warn about" "named-checkzone -k fail -l 60 team01.example $Z" '^OK$' '!warning|has no address'
reload "2.4.4 reload (serial 08)" 2026102708
step "2.4.5 SPF, null MX and DMARC" \
    "dig @127.0.0.1 team01.example TXT +norec +short; dig @127.0.0.1 ftp.team01.example MX +norec +short; dig @127.0.0.1 _dmarc.team01.example TXT +norec +short" \
    '^"v=spf1 mx -all"$' '^0 \.$' '^"v=DMARC1; p=none; rua=mailto:dmarc-reports@team01\.example"$'
step "2.4.6 DKIM: three strings; joined, they give back the public key" \
    "cd /root; dig @127.0.0.1 lab1._domainkey.team01.example TXT +norec +short; dig @127.0.0.1 lab1._domainkey.team01.example TXT +short | tr -d '\" \\n' | sed 's/^.*;p=//' | cmp - lab1.pub && echo match" \
    '^"v=DKIM1; k=rsa; p=" "MII' '^match$'
step "2.4.7 through the lab resolver" "dig @192.0.2.55 _dmarc.team01.example TXT +short; dig @192.0.2.55 team01.example MX +short; dig @192.0.2.55 team01.example TXT +short; dig @192.0.2.55 ftp.team01.example MX +short; dig @192.0.2.55 lab1._domainkey.team01.example TXT +short" \
    '^"v=DMARC1; p=none' '^10 mail\.team01\.example\.$' '^"v=spf1 mx -all"$' '^0 \.$' '^"v=DKIM1; k=rsa; p=" "MII'
step "2.4.8 records Modules 6-8 rely on are unchanged" \
    "for n in ns1 www mail ftp; do dig @127.0.0.1 \$n.team01.example A +norec +short; done" \
    '^192\.0\.2\.30$' '^192\.0\.2\.80$' '^192\.0\.2\.81$' '^192\.0\.2\.82$'
log "# final zone file" "$(docker exec "$VM" cat "$Z")" ""

echo "== $pass passed, $fail failed; transcript: $OUT"
[ "$fail" -eq 0 ]
