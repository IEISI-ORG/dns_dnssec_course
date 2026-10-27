#!/bin/bash
# rehearse.sh [TRANSCRIPT]: run every Module 4 lab step (Labs 4.1-4.4) on two
# stand-in participant VMs and check each checkpoint.
#
# It starts the instructor stack (../../instructor, profile m01: the registry
# for example. and the Module 1 lab resolver, kept on through Day 2) on an
# internal Docker bridge with no route out, plus two Debian 13 containers
# (test/Dockerfile): VM 1 at 192.0.2.30, set up as Modules 2 and 3 left it
# (primary for team01.example and its two reverse zones, from
# ../../module02/zones, with the Lab 2.1-2.4 records and Module 3's lab33
# record), and VM 2 at 192.0.2.10, the BIND resolver with Module 3's kit
# files (named.conf.local with one line added, as a team's lab-sheet edit
# would change it). teams.conf delegates team01.example to VM 1 only. The participant's
# typing is the commands below; the kit files come from ../vm1 and ../vm2.
# Daemons run in the foreground with their logs in /var/log/*.out, where a
# VM has the journal. Everything is removed at the end. The transcript goes
# to TRANSCRIPT, or to a new file under ${TMPDIR:-/tmp} whose name is
# printed. Needs Docker with Compose v2; the lab steps need no Internet
# access; the image build does. KIT_DIR=<copy of labs/module04> runs it
# against a changed kit (mutation tests). SETUP_ONLY=1 stops after the
# set-up and leaves the lab running (for exploring), with its work directory
# ${TMPDIR:-/tmp}/dnslab-m04-<uid>; the next run removes both.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "${KIT_DIR:-$here/..}" && pwd) || exit 1
M02=$(cd "$here/../../module02" && pwd) || exit 1
M03=$(cd "$here/../../module03" && pwd) || exit 1
INS=$(cd "$here/../../instructor" && pwd) || exit 1
unset M01_FAULT_LABELS
PROJ=dnslab-m04
V1=dnslab-m04-vm1
V2=dnslab-m04-vm2
export COMPOSE_PROFILES=m01
DC=(docker compose -p "$PROJ" --env-file "$INS/test/test.env" -f "$INS/compose.yaml" -f "$INS/compose.test.yaml")
Z=/var/lib/bind/db.team01.example
L=/etc/bind/named.conf.local
O=/etc/bind/named.conf.options
pass=0; fail=0
W=${TMPDIR:-/tmp}/dnslab-m04-$(id -u)

stop_lab() {
    docker rm -f "$V1" "$V2" >/dev/null 2>&1
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
}
[ "${SETUP_ONLY:-0}" = 1 ] || trap 'stop_lab; rm -rf "$W"' EXIT
OUT=${1:-$(mktemp "${TMPDIR:-/tmp}/m04-rehearsal.XXXXXX")} || exit 1
export CLASSROOM_DIR=$W/classroom HANDOUT_DIR=$W/handout

log() { printf '%s\n' "$@" >> "$OUT"; }
ok() { echo "PASS  $1"; pass=$((pass + 1)); }
bad() { echo "FAIL  $1"; fail=$((fail + 1)); }
# ctr VM: the container for vm1 or vm2 (anything else stops the run)
ctr() { case $1 in vm1) echo "$V1" ;; vm2) echo "$V2" ;; *) echo "bad VM $1" >&2; exit 1 ;; esac; }
# step VM NAME COMMAND REGEX...: run COMMAND on VM (vm1 or vm2), keep it in
# the transcript, PASS if the output matches every REGEX (a leading ! negates)
step() {
    local c name=$2 cmd=$3 out r good=1
    c=$(ctr "$1") || exit 1; shift 3
    out=$(docker exec "$c" bash -c "$cmd" 2>&1)
    { echo "[$name]"; echo "$c\$ $cmd"; echo "$out"; echo; } >> "$OUT"
    for r in "$@"; do
        if [[ $r == !* ]]; then grep -Eq -- "${r#!}" <<< "$out" && good=0
        else grep -Eq -- "$r" <<< "$out" || good=0; fi
    done
    if [ "$good" = 1 ]; then ok "$name"; else bad "$name"; sed -n '1,8s/^/        /p' <<< "$out"; fi
    [ "$good" = 1 ]
}
# on VM COMMAND: run quietly on VM (input from stdin), keep it in the transcript
on() {
    local c; c=$(ctr "$1") || exit 1
    log "$c\$ $2"; docker exec -i "$c" bash -c "$2" >> "$OUT" 2>&1
}
# start_named VM: "systemctl start named"; stops the run if named does not come up
start_named() {
    local c; c=$(ctr "$1") || exit 1
    docker exec "$c" install -d -o bind -g bind /run/named
    docker exec -d "$c" sh -c 'exec named -u bind -g >> /var/log/named.out 2>&1'
    for _ in $(seq 20); do docker exec "$c" rndc status >/dev/null 2>&1 && return 0; sleep 0.5; done
    echo "named did not start on $c"; docker exec "$c" tail -20 /var/log/named.out; exit 1
}
# queries: number of query-log lines on VM 1 so far
queries() { docker exec "$V1" grep -c 'query: ' /var/log/named.out; }
# reconf VM NAME: named-checkconf and rndc reconfig after an edit; checked
reconf() { step "$1" "$2" "named-checkconf && rndc reconfig && echo reconfigured" '^reconfigured$'; }
# start_unbound NAME: "sudo systemctl start unbound" on VM 2, as Debian's
# unit does it (unbound-helper writes the root key first, then unbound -d -p).
# The harness adds use-syslog: no, so the log goes to /var/log/unbound.out.
start_unbound() {
    step vm2 "$1" "/usr/libexec/unbound-helper root_trust_anchor_update; printf 'server:\n    use-syslog: no\n' > /etc/unbound/unbound.conf.d/zz-harness.conf; unbound-checkconf && { (unbound -d -p >> /var/log/unbound.out 2>&1 &); for _ in \$(seq 20); do unbound-control status >/dev/null 2>&1 && break; sleep 0.5; done; unbound-control status; }" \
        'unbound \(pid [0-9]+\) is running' 'modules: 2 \[ validator iterator \]' \
        || { echo "unbound did not start"; docker exec "$V2" tail -20 /var/log/unbound.out; exit 1; }
}
# start_pdns NAME: "sudo systemctl start pdns" on VM 1, as Debian's unit runs
# it (user pdns, no guardian, no syslog); the log goes to /var/log/pdns.out
start_pdns() {
    step vm1 "$1" "install -d -o pdns -g pdns /run/pdns; (runuser -u pdns -- pdns_server --guardian=no --daemon=no --disable-syslog --log-timestamp=no --write-pid=no >> /var/log/pdns.out 2>&1 &); for _ in \$(seq 20); do pdns_control rping 2>/dev/null | grep -q PONG && break; sleep 0.5; done; pdns_control rping; cat /var/log/pdns.out" \
        '^PONG$' 'UDP server bound to 192\.0\.2\.30:5300' 'Listening for HTTP requests on 127\.0\.0\.1:8081' \
        || { echo "pdns did not start"; docker exec "$V1" tail -20 /var/log/pdns.out; exit 1; }
}
# waitlog FILE PATTERN [COUNT]: (on the VM) wait up to 10 s until FILE has
# COUNT (default 1) lines matching PATTERN; installed on both VMs below
WAITLOG='#!/bin/sh
n=${3:-1}
for _ in $(seq 20); do [ "$(grep -Ec -- "$2" "$1" 2>/dev/null)" -ge "$n" ] && exit 0; sleep 0.5; done
exit 1'

stop_lab
rm -rf "$W"; mkdir -p "$W/classroom" "$W/handout" || exit 1
echo "01 192.0.2.30" > "$W/classroom/teams.conf"
: > "$OUT" || exit 1
"${DC[@]}" up -d --build --quiet-pull init parent m01-root m01-child m01-resolver >/dev/null 2>&1 \
    || { "${DC[@]}" logs; exit 1; }
docker build -q --build-arg DEBIAN_TAG="${DEBIAN_TAG:-trixie-20261005-slim}" -t dnslab/m04-vm:local "$here" >/dev/null || exit 1
docker run -d --init --name "$V1" --network "${PROJ}_lab" --ip 192.0.2.30 -v "$KIT:/kit:ro" -v "$M02:/m02:ro" dnslab/m04-vm:local >/dev/null || exit 1
docker run -d --init --name "$V2" --network "${PROJ}_lab" --ip 192.0.2.10 -v "$KIT:/kit:ro" -v "$M03:/m03:ro" dnslab/m04-vm:local >/dev/null || exit 1
for c in "$V1" "$V2"; do
    printf '%s\n' "$WAITLOG" | docker exec -i "$c" sh -c 'cat > /usr/local/bin/waitlog && chmod 755 /usr/local/bin/waitlog && touch /var/log/named.out'
    docker exec "$c" sh -c 'rndc-confgen -a -u bind >/dev/null 2>&1' || exit 1
done

# VM 1 as Modules 2 and 3 left it: team01.example with the Lab 2.1-2.4
# records (a fresh DKIM key, as each participant made one) and Module 3's
# lab33 record, and the two reverse zones, all primary zones in /var/lib/bind
on vm1 "cd /root && openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out lab1.private 2>/dev/null && openssl pkey -in lab1.private -pubout -outform DER | base64 -w0 > lab1.pub"
on vm1 "sed -e 's/NN/01/g' -e 's/2026102701 ; serial/2026102709 ; serial/' /m02/zones/db.teamNN.example > \"$Z\" && cat >> \"$Z\" && printf 'lab1._domainkey IN TXT ( \"v=DKIM1; k=rsa; p=\"\n%s )\n' \"\$(fold -w 250 /root/lab1.pub | sed 's/.*/\"&\"/')\" >> \"$Z\"" <<'EOF'
@       IN A     192.0.2.80
        IN AAAA  2001:db8:1::80
        IN HTTPS 0 www
        IN MX    10 mail
        IN CAA   0 issue "ca.example.net"
        IN CAA   0 iodef "mailto:hostmaster@team01.example"
        IN TXT   "v=spf1 mx -all"
www     IN A     192.0.2.80
        IN AAAA  2001:db8:1::80
        IN HTTPS 1 . alpn="h2"
web     IN CNAME www
mail    IN A     192.0.2.81
        IN AAAA  2001:db8:1::81
ftp     IN A     192.0.2.82
        IN MX    0 .
        IN TXT   "v=spf1 -all"
_imaps._tcp IN SRV 0 1 993 mail
app     IN A     192.0.2.86
lab33   IN A     192.0.2.84
new     IN A     192.0.2.87
_dmarc  IN TXT   "v=DMARC1; p=none; rua=mailto:dmarc-reports@team01.example"
EOF
on vm1 "sed 's/NN/01/g' /m02/zones/db.192.0.2 > /var/lib/bind/db.192.0.2 && printf '80 IN PTR www.team01.example.\n81 IN PTR mail.team01.example.\n82 IN PTR ftp.team01.example.\n' >> /var/lib/bind/db.192.0.2"
on vm1 "sed 's/NN/01/g' /m02/zones/db.2001-db8-NN > /var/lib/bind/db.2001-db8-01 && echo '1.8.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR mail.team01.example.' >> /var/lib/bind/db.2001-db8-01"
on vm1 "sed -e 's/NN/01/g' -e 's/N2\\.N1/1.0/' /m02/zones/named.conf.local >> \"$L\" && named-checkconf -z"
start_named vm1
# VM 2 as Module 3 left it: the BIND resolver with the Module 3 kit's files;
# one comment line stands for the team's own edits (lab-sheet addresses), so
# a clean-up that copies the kit's template back would show up in 4.4.5
on vm2 "cp /m03/vm2/named.conf.options \"$O\" && cp /m03/vm2/named.conf.local \"$L\" && echo '// team 01: registry address from the lab sheet' >> \"$L\" && named-checkconf"
start_named vm2
for _ in $(seq 30); do
    docker exec "$V2" dig @192.0.2.10 +short www.team01.example A 2>/dev/null | grep -qx 192.0.2.80 && break
    sleep 1
done
docker exec "$V2" dig @192.0.2.10 +short www.team01.example A 2>/dev/null | grep -qx 192.0.2.80 \
    || { echo "VM 2 does not resolve the team zone"; "${DC[@]}" logs; exit 1; }
docker exec "$V2" dig @192.0.2.55 +short www.team01.example A 2>/dev/null | grep -qx 192.0.2.80 \
    || { echo "lab resolver not answering"; "${DC[@]}" logs; exit 1; }
if [ "${SETUP_ONLY:-0}" = 1 ]; then echo "set up; work dir $W; transcript $OUT"; exit 0; fi

{ echo "# Module 4 rehearsal, $(date -u +%Y-%m-%dT%H:%MZ)"
  docker exec "$V1" sh -c 'named -v; unbound -V | sed -n 1p; pdns_server --version 2>&1 | sed -n 1p; dpkg-query -W bind9 unbound pdns-server pdns-backend-sqlite3 sqlite3 curl jq'
  echo; } >> "$OUT"

echo "== Day 2 afternoon: the VMs as Module 3 left them"
step vm1 "0.1 VM 1 answers for team01.example with aa (BIND, port 53)" "dig @192.0.2.30 team01.example SOA +norec" \
    'flags: qr aa ra;' ' 2026102709 3600 600 1209600 60'
step vm2 "0.2 VM 2's BIND resolves the team zone" "dig @192.0.2.10 www.team01.example" 'status: NOERROR' 'flags: qr rd ra;' '192\.0\.2\.80'
step vm2 "0.3 Module 4's packages are in the image, nothing on port 5300 yet" \
    "dpkg-query -W unbound pdns-server pdns-backend-sqlite3 sqlite3 curl jq; dpkg-query -W -f='pdns-backend-bind status: \${db:Status-Status}\n' pdns-backend-bind 2>&1; ss -lntuH | awk '{print \$5}' | sort -u; stat -c '%U %n' /var/lib/unbound/root.key; unbound-checkconf" \
    '^unbound[[:space:]]+1\.26\.' '^pdns-server[[:space:]]+4\.9\.' '^pdns-backend-sqlite3' '^pdns-backend-bind status: (not-installed|config-files)?$|no packages found matching pdns-backend-bind' '^192\.0\.2\.10:53$' '!:5300$' '^unbound /var/lib/unbound/root\.key$' 'unbound-checkconf: no errors'
on vm1 "cp \"$L\" /root/named.conf.local.m03; cp \"$O\" /root/named.conf.options.m03"
on vm2 "cp \"$L\" /root/named.conf.local.m03; cp \"$O\" /root/named.conf.options.m03"

echo "== Lab 4.1: BIND under the hood"
step vm2 "4.1.1 named -V: the libraries this build uses" "named -V" \
    "'--with-json-c'" 'linked to libxml2 version' "'--with-lmdb=/usr'" "'--with-maxminddb'" 'linked to libnghttp2'
step vm2 "4.1.2 named-checkconf -p: Debian's four files as one configuration" "named-checkconf -p" \
    '^options \{' 'validate-except \{' '^zone "example" \{' 'type static-stub;' '^zone "\." \{' 'type hint;' 'file "/usr/share/dns/root\.hints";'
step vm2 "4.1.3 rndc status" "rndc status" \
    '^worker threads: [0-9]+' '^number of zones: [0-9]+ \([0-9]+ automatic\)' '^recursive clients: [0-9]+/900/1000' '^query logging is OFF'
on vm2 "cp \"$L\" /etc/bind/named.conf.local.m03 && cat /kit/vm2/named.conf.stats >> \"$L\""
reconf vm2 "4.1.4a statistics channel added, loaded"
step vm2 "4.1.4 statistics channel: three lookups counted, two of them from the cache" \
    "j() { curl -s http://127.0.0.1:8053/json/v1/server; }; a=\$(j | jq '.nsstats.Requestv4'); h=\$(j | jq '.views._default.resolver.cachestats.QueryHits'); for i in 1 2 3; do dig @127.0.0.1 mail.team01.example +short; done; b=\$(j | jq '.nsstats.Requestv4'); k=\$(j | jq '.views._default.resolver.cachestats.QueryHits'); echo requests=\$((b - a)) hits=\$((k - h)); j | jq -c '{nsstats: (.nsstats | {Requestv4, QrySuccess, QryRecursion}), cache: (.views._default.resolver.cachestats | {QueryHits, QueryMisses})}'" \
    '^192\.0\.2\.81$' '^requests=3 hits=2$' '"Requestv4":[0-9]+'
on vm1 "sed -i 's|^\\([[:space:]]*directory .*\\)\$|\\1\\n\\tallow-new-zones yes;|' \"$O\"; sed 's/NN/01/g' /kit/vm1/db.lab4.teamNN.example > /var/lib/bind/db.lab4.team01.example; cat \"$O\""
reconf vm1 "4.1.5a VM 1: allow-new-zones yes, loaded"
step vm1 "4.1.5 rndc addzone: a zone without editing named.conf" \
    "rndc addzone lab4.team01.example '{ type primary; file \"/var/lib/bind/db.lab4.team01.example\"; };' && rndc showzone lab4.team01.example; dig @127.0.0.1 www.lab4.team01.example +norec; ls /var/cache/bind" \
    '^zone "lab4\.team01\.example" \{ type primary; file "/var/lib/bind/db\.lab4\.team01\.example"; \};' 'flags: qr aa' 'www\.lab4\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.80' '^_default\.nzd$'
step vm1 "4.1.6 rndc delzone -clean: the zone and its file go" \
    "rndc delzone -clean lab4.team01.example; for _ in \$(seq 20); do [ -e /var/lib/bind/db.lab4.team01.example ] || break; sleep 0.5; done; ls /var/lib/bind; dig @127.0.0.1 www.lab4.team01.example +norec | grep status" \
    'deleted' '!db\.lab4' 'status: NXDOMAIN'
on vm1 "sed -i '/allow-new-zones yes;/d' \"$O\""
reconf vm1 "4.1.6a VM 1: allow-new-zones removed, loaded"
step vm1 "4.1.6b VM 1's options are Debian's again" "cmp /root/named.conf.options.m03 \"$O\" && echo same" '^same$'

echo "== Lab 4.2: Unbound next to BIND on VM 2"
step vm2 "4.2.1 Debian's Unbound defaults: port 53, already taken by BIND" \
    "/usr/libexec/unbound-helper root_trust_anchor_update; printf 'server:\\n    use-syslog: no\\n' > /etc/unbound/unbound.conf.d/zz-harness.conf; ls /etc/unbound/unbound.conf.d; timeout 10 unbound -d -p 2>&1 | grep -E 'error|fatal'" \
    "can't bind socket: Address already in use for .* port 53" 'fatal error: could not open ports' '^remote-control\.conf$' '^root-auto-trust-anchor-file\.conf$'
on vm2 "sed 's/NN/01/g' /kit/vm2/module04.conf > /etc/unbound/unbound.conf.d/module04.conf"
start_unbound "4.2.2 the kit's file: Unbound starts on port 5300"
step vm1 "4.2.2c VM 1: query log on (runtime only: Module 3 restarted named)" "rndc querylog on && rndc status | grep 'query logging'" '^query logging is ON$'
step vm2 "4.2.2b listening on 127.0.0.1 and VM 2's address, port 5300; BIND still on 53" "ss -lnu | grep -E ':(53|5300) ' | awk '{print \$4}' | sort -u" \
    '^127\.0\.0\.1:5300$' '^192\.0\.2\.10:5300$' '^192\.0\.2\.10:53$'
q0=$(queries)
step vm2 "4.2.3 the same question to both resolvers: the same answer" \
    "u=\$(dig @127.0.0.1 -p 5300 ftp.team01.example); b=\$(dig @127.0.0.1 ftp.team01.example); echo \"\$u\"; echo \"\$b\"; echo unbound=\$(grep -E '^ftp' <<< \"\$u\" | awk '{print \$5}') \$(grep -o 'flags: [a-z ]*;' <<< \"\$u\") bind=\$(grep -E '^ftp' <<< \"\$b\" | awk '{print \$5}')" \
    '^unbound=192\.0\.2\.82 flags: qr rd ra; bind=192\.0\.2\.82$'
step vm1 "4.2.4 VM 1's query log: Unbound (DO and CD, no cookie) and BIND (DO and a cookie)" \
    "waitlog /var/log/named.out 'ftp\.team01\.example IN A' 2; grep 'query: ' /var/log/named.out | tail -n +$((q0 + 1)) | grep 'ftp.team01.example IN A'" \
    '192\.0\.2\.10#[0-9]+ \(ftp\.team01\.example\): query: ftp\.team01\.example IN A -E\(0\)DC \(' \
    '192\.0\.2\.10#[0-9]+ \(ftp\.team01\.example\): query: ftp\.team01\.example IN A -E\(0\)D[KV] \('
step vm1 "4.2.5 VM 1 may use Unbound on VM 2 (access-control); +norec is refused" \
    "dig @192.0.2.10 -p 5300 mail.team01.example +short; dig @192.0.2.10 -p 5300 www.team01.example +norec | grep status" \
    '^192\.0\.2\.81$' 'status: REFUSED'
step vm2 "4.2.6 unbound-control: counters, cache, flush" \
    "unbound-control stats_noreset | grep -E '^total\.num\.(queries|cachehits|cachemiss)='; unbound-control dump_cache | grep -E '^ftp\.team01'; unbound-control flush ftp.team01.example; unbound-control dump_cache | grep -c '^ftp\.team01' || true" \
    '^total\.num\.queries=3$' '^total\.num\.cachehits=1$' '^total\.num\.cachemiss=2$' '^ftp\.team01\.example\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.82' '^ok$' '^0$'
on vm2 "sed -i 's/^    # local-/    local-/' /etc/unbound/unbound.conf.d/module04.conf; grep local- /etc/unbound/unbound.conf.d/module04.conf"
step vm2 "4.2.7 local-data and local-zone: Unbound's own answers" \
    "unbound-checkconf && unbound-control reload; dig @127.0.0.1 -p 5300 printer.home.arpa; dig @127.0.0.1 -p 5300 new.team01.example | grep -E 'status|flags'; dig @127.0.0.1 new.team01.example +short" \
    '^ok$' 'flags: qr aa rd ra;' '^printer\.home\.arpa\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.99' 'status: NXDOMAIN' '^192\.0\.2\.87$'
on vm2 "sed -i 's/^stub-zone:\$/forward-zone:/' /etc/unbound/unbound.conf.d/module04.conf; sed -i 's/^    stub-addr: 192.0.2.53\$/    forward-addr: 192.0.2.55/' /etc/unbound/unbound.conf.d/module04.conf; grep -A2 -E '^(stub|forward)-zone' /etc/unbound/unbound.conf.d/module04.conf"
q1=$(queries)
step vm2 "4.2.8 forward-zone to the lab resolver" \
    "grep -c '^forward-zone:' /etc/unbound/unbound.conf.d/module04.conf; unbound-checkconf && unbound-control reload; unbound-control list_forwards; dig @127.0.0.1 -p 5300 web.team01.example +short" \
    '^1$' '^example\. IN forward \+i 192\.0\.2\.55$' '^192\.0\.2\.80$'
step vm1 "4.2.9 VM 1's query log: the lab resolver asked, not VM 2" "waitlog /var/log/named.out '192\.0\.2\.55#.*query: (web|www)\.team01'; grep 'query: ' /var/log/named.out | tail -n +$((q1 + 1))" \
    '192\.0\.2\.55#[0-9]+ \((web|www)\.team01\.example\): query: (web|www)\.team01\.example IN A -' '!192\.0\.2\.10#'
on vm2 "sed -i 's/^    forward-addr: 192.0.2.55\$/    forward-addr: 192.0.2.53/' /etc/unbound/unbound.conf.d/module04.conf"
step vm2 "4.2.10 forwarding to the registry: Unbound passes the referral on (BIND: SERVFAIL)" \
    "unbound-checkconf && unbound-control reload; unbound-control list_forwards | grep example; dig @127.0.0.1 -p 5300 mail.team01.example" \
    '^example\. IN forward \+i 192\.0\.2\.53$' 'status: NOERROR' 'ANSWER: 0, AUTHORITY: 1,' '^team01\.example\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+NS[[:space:]]+ns1\.team01\.example\.'
on vm2 "sed -i -e 's/^forward-zone:\$/stub-zone:/' -e 's/^    forward-addr: 192.0.2.53\$/    stub-addr: 192.0.2.53/' /etc/unbound/unbound.conf.d/module04.conf"
step vm2 "4.2.11 the stub zone is back" \
    "unbound-checkconf && unbound-control reload; unbound-control list_stubs | grep -v '^\. '; dig @127.0.0.1 -p 5300 mail.team01.example +short" \
    '^example\. IN stub noprime .*192\.0\.2\.53' '^192\.0\.2\.81$'

echo "== Lab 4.3: PowerDNS with a database on VM 1"
step vm1 "4.3.1 Debian's pdns.conf: no backend, an include directory, no security polling" \
    "grep -v '^#' /etc/powerdns/pdns.conf | grep .; ls -A /etc/powerdns/pdns.d | wc -l" \
    '^include-dir=/etc/powerdns/pdns\.d$' '^launch=$' '^security-poll-suffix=$' '^0$'
step vm1 "4.3.2 the SQLite database from Debian's schema, owned by pdns" \
    "runuser -u pdns -- sqlite3 /var/lib/powerdns/pdns.sqlite3 < /usr/share/pdns-backend-sqlite3/schema/schema.sqlite3.sql && sqlite3 /var/lib/powerdns/pdns.sqlite3 .tables; stat -c '%U %a' /var/lib/powerdns/pdns.sqlite3" \
    'domains' 'records' 'domainmetadata' '^pdns 644$'
step vm1 "4.3.3 the kit's settings and a new API key, readable by pdns only" \
    "install -m 640 -g pdns /kit/vm1/module04.conf /etc/powerdns/pdns.d/module04.conf; (umask 077; echo \"X-API-Key: \$(openssl rand -hex 16)\" > /root/pdns-api.hdr); sed 's/^X-API-Key: /api-key=/' /root/pdns-api.hdr | install -m 640 -g pdns /dev/stdin /etc/powerdns/pdns.d/api-key.conf; stat -c '%n %U %G %a' /etc/powerdns/pdns.d/* /root/pdns-api.hdr; grep -cE '^api-key=[0-9a-f]{32}$' /etc/powerdns/pdns.d/api-key.conf; umask" \
    '^/etc/powerdns/pdns\.d/api-key\.conf root pdns 640$' '^/etc/powerdns/pdns\.d/module04\.conf root pdns 640$' '^/root/pdns-api\.hdr root root 600$' '^1$' '^0022$'
start_pdns "4.3.4 PowerDNS starts: port 5300, API on 127.0.0.1:8081"
step vm1 "4.3.4b no zones yet: REFUSED" "dig @127.0.0.1 -p 5300 team01.example SOA" 'status: REFUSED' 'flags: qr rd;'
step vm1 "4.3.5 load BIND's zone file into the database" \
    "runuser -u pdns -- pdnsutil load-zone team01.example /var/lib/bind/db.team01.example; runuser -u pdns -- pdnsutil check-zone team01.example; sqlite3 /var/lib/powerdns/pdns.sqlite3 'select count(*) from records'" \
    "Creating 'team01\.example'" 'Checked 25 records of .team01\.example., 0 errors' '^25$'
step vm1 "4.3.5b not served yet: the running server's zone cache does not know it" \
    "dig @127.0.0.1 -p 5300 team01.example SOA | grep status" 'status: REFUSED'
step vm1 "4.3.6 rediscover and purge: served, with aa and BIND's serial" \
    "pdns_control rediscover; pdns_control purge; dig @127.0.0.1 -p 5300 team01.example SOA" \
    'flags: qr aa rd;' 'SOA[[:space:]]+ns1\.team01\.example\. hostmaster\.team01\.example\. 2026102709 '
step vm1 "4.3.7 the migration check: one record differs" \
    "sh /kit/vm1/zonediff.sh team01.example /var/lib/bind/db.team01.example 127.0.0.1 5300; echo rc=\$?; dig @127.0.0.1 -p 5300 team01.example HTTPS +short" \
    '^< team01\.example\.[[:space:]]+60 IN HTTPS[[:space:]]+0 www\.team01\.example\.$' '^> team01\.example\.[[:space:]]+60 IN HTTPS[[:space:]]+0 www\.$' '^rc=1$' '^0 www\.$'
API='H=/root/pdns-api.hdr; A=http://127.0.0.1:8081/api/v1/servers/localhost'
step vm1 "4.3.8 the API: zones listed with the key, 401 without" \
    "$API; curl -s -H @\$H \$A/zones | jq -r '.[] | [.name, .kind, .serial] | @tsv'; curl -s -o /dev/null -w '%{http_code}\n' \$A/zones" \
    '^team01\.example\.[[:space:]]+Native[[:space:]]+2026102709$' '^401$'
on vm1 "sed 's/NN/01/g' /kit/vm1/fix-https.json > /root/fix-https.json; sed 's/NN/01/g' /kit/vm1/add-record.json > /root/add-record.json"
step vm1 "4.3.9 fix the HTTPS record through the API: same data, serial unchanged" \
    "$API; curl -s -o /dev/null -w '%{http_code}\n' -X PATCH -H @\$H --data @/root/fix-https.json \$A/zones/team01.example.; sh /kit/vm1/zonediff.sh team01.example /var/lib/bind/db.team01.example 127.0.0.1 5300; dig @127.0.0.1 -p 5300 team01.example SOA +short" \
    '^204$' '^same$' ' 2026102709 '
step vm1 "4.3.10 SOA-EDIT-API, then a new record: the serial goes up" \
    "$API; echo put=\$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H @\$H --data @/kit/vm1/soa-edit-api.json \$A/zones/team01.example.) patch=\$(curl -s -o /dev/null -w '%{http_code}' -X PATCH -H @\$H --data @/root/add-record.json \$A/zones/team01.example.); curl -s -H @\$H \$A/zones/team01.example. | jq -r '.soa_edit_api'; dig @127.0.0.1 -p 5300 api.team01.example +short; sh /kit/vm1/zonediff.sh team01.example /var/lib/bind/db.team01.example 127.0.0.1 5300" \
    '^put=204 patch=204$' '^INCREASE$' '^192\.0\.2\.85$' '^> team01\.example\.[[:space:]]+60 IN SOA[[:space:]]+ns1\.team01\.example\. hostmaster\.team01\.example\. 2026102710 ' '^> api\.team01\.example\.[[:space:]]+60 IN A[[:space:]]+192\.0\.2\.85$'

echo "== Lab 4.4: compare, then clean up"
on vm2 "sed -i -e 's/^# stub-zone:\$/stub-zone:/' -e 's/^#     name: \"team01.example\"/    name: \"team01.example\"/' -e 's/^#     stub-addr: 192.0.2.30@5300/    stub-addr: 192.0.2.30@5300/' /etc/unbound/unbound.conf.d/module04.conf; tail -4 /etc/unbound/unbound.conf.d/module04.conf"
step vm2 "4.4.1 Unbound asks PowerDNS for the team zone; BIND follows the delegation" \
    "unbound-checkconf && unbound-control reload; dig @127.0.0.1 -p 5300 api.team01.example +short; dig @127.0.0.1 api.team01.example | grep status" \
    '^192\.0\.2\.85$' 'status: NXDOMAIN'
step vm1 "4.4.2 PowerDNS logged VM 2's query" "waitlog /var/log/pdns.out \"Remote 192\\.0\\.2\\.10 wants 'api\\.team01\\.example\\|A'\"; grep \"Remote 192.0.2.10 wants 'api.team01.example|A'\" /var/log/pdns.out | tail -1" \
    "Remote 192\.0\.2\.10 wants 'api\.team01\.example\|A', do = 1"
step vm2 "4.4.3 counters from Unbound and BIND" \
    "unbound-control stats_noreset | grep -E '^total\.num\.queries='; echo bind=\$(curl -s http://127.0.0.1:8053/json/v1/server | jq '.nsstats.Requestv4')" \
    '^total\.num\.queries=1$' '^bind=[1-9][0-9]*$'
step vm1 "4.4.4 counters from PowerDNS (API and pdns_control)" \
    "$API; a=\$(curl -s -H @\$H \$A/statistics | jq -r '.[] | select(.name == \"udp-queries\") | .value'); c=\$(pdns_control show udp-queries); echo api=\$a ctl=\$c; [ -n \"\$a\" ] && [ \"\$a\" = \"\$c\" ] && echo equal" \
    '^api=[1-9][0-9]* ctl=[1-9][0-9]*$' '^equal$'
on vm2 "unbound-control stop; for _ in \$(seq 20); do unbound-control status >/dev/null 2>&1 || break; sleep 0.5; done; rm -f /etc/unbound/unbound.conf.d/module04.conf /etc/unbound/unbound.conf.d/zz-harness.conf; mv /etc/bind/named.conf.local.m03 \"$L\""
reconf vm2 "4.4.5a VM 2: Unbound stopped, the saved named.conf.local back, loaded"
step vm2 "4.4.5 VM 2: only BIND listens, BIND resolves, files as Module 3 left them" \
    "ss -lntuH | awk '{print \$5}' | sort -u; dig @127.0.0.1 www.team01.example +short; cmp /root/named.conf.local.m03 \"$L\" && cmp /root/named.conf.options.m03 \"$O\" && echo same; ls /etc/unbound/unbound.conf.d /etc/bind" \
    '^192\.0\.2\.10:53$' '!:(5300|8053|8081)$' '^192\.0\.2\.80$' '^same$' '!module04|\.m03'
on vm1 "pdns_control quit; for _ in \$(seq 20); do pdns_control rping >/dev/null 2>&1 || break; sleep 0.5; done; rm -f /etc/powerdns/pdns.d/api-key.conf /etc/powerdns/pdns.d/module04.conf /root/pdns-api.hdr"
step vm1 "4.4.6 VM 1: only BIND listens, no API key left, BIND as Module 3 left it" \
    "ss -lntuH | awk '{print \$5}' | sort -u; ls -A /etc/powerdns/pdns.d /root; cmp /root/named.conf.local.m03 \"$L\" && cmp /root/named.conf.options.m03 \"$O\" && echo same; dig @192.0.2.30 team01.example SOA +norec | grep -E 'flags|SOA'" \
    '^192\.0\.2\.30:53$' '!:(5300|8053|8081)$' '!api-key|pdns-api|module04' '^same$' 'flags: qr aa' ' 2026102709 '

echo "== $pass passed, $fail failed; transcript: $OUT"
[ "$fail" -eq 0 ]
