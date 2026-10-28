#!/bin/bash
# rehearse.sh [TRANSCRIPT]: run every Module 5 lab step (Labs 5.1-5.4) on two
# stand-in participant VMs and check each checkpoint.
#
# It starts the instructor stack (../../instructor, profile m01: the registry
# for example. and the Module 1 lab resolver, kept on through the Module 5
# lab) on an internal Docker bridge with no route out, plus two Debian 13
# containers (test/Dockerfile): VM 1 at 192.0.2.30, set up as Modules 2-4
# left it (primary for team01.example and its two reverse zones, from
# ../../module02/zones, with the Lab 2.1-2.4 records and Module 3's lab33
# record), and VM 2 at 192.0.2.10, the BIND resolver with Module 3's kit
# files (named.conf.local with one line added, as a team's lab-sheet edit
# would change it). teams.conf delegates team01.example to VM 1 only.
# VM 2 runs privileged: Labs 5.3-5.4 create network namespaces and set
# forwarding inside them, as root on a real VM can. The participant's typing
# is the commands below; the kit files come from ../vm1, ../vm2, ../anycast.
# named runs in the foreground with its log in /var/log/named.out, where a
# VM has the journal. Everything is removed at the end. The transcript goes
# to TRANSCRIPT, or to a new file under ${TMPDIR:-/tmp} whose name is
# printed. Needs Docker with Compose v2; the lab steps need no Internet
# access; the image build does. KIT_DIR=<copy of labs/module05> runs it
# against a changed kit (mutation tests). SETUP_ONLY=1 stops after the
# set-up and leaves the lab running (for exploring), with its work directory
# ${TMPDIR:-/tmp}/dnslab-m05-<uid>; the next run removes both.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "${KIT_DIR:-$here/..}" && pwd) || exit 1
M02=$(cd "$here/../../module02" && pwd) || exit 1
M03=$(cd "$here/../../module03" && pwd) || exit 1
INS=$(cd "$here/../../instructor" && pwd) || exit 1
unset M01_FAULT_LABELS
PROJ=dnslab-m05
V1=dnslab-m05-vm1
V2=dnslab-m05-vm2
export COMPOSE_PROFILES=m01
DC=(docker compose -p "$PROJ" --env-file "$INS/test/test.env" -f "$INS/compose.yaml" -f "$INS/compose.test.yaml")
Z=/var/lib/bind/db.team01.example
L=/etc/bind/named.conf.local
O=/etc/bind/named.conf.options
N=/etc/bind/named.conf
pass=0; fail=0
W=${TMPDIR:-/tmp}/dnslab-m05-$(id -u)

stop_lab() {
    docker rm -f "$V1" "$V2" >/dev/null 2>&1
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
}
[ "${SETUP_ONLY:-0}" = 1 ] || trap 'stop_lab; rm -rf "$W"' EXIT
OUT=${1:-$(mktemp "${TMPDIR:-/tmp}/m05-rehearsal.XXXXXX")} || exit 1
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
# reconf VM NAME: named-checkconf and rndc reconfig after an edit; checked
reconf() { step "$1" "$2" "named-checkconf && rndc reconfig && echo reconfigured" '^reconfigured$'; }
# waitlog FILE PATTERN [COUNT]: (on the VM) wait up to 10 s until FILE has
# COUNT (default 1) lines matching PATTERN; installed on both VMs below
WAITLOG='#!/bin/sh
n=${3:-1}
for _ in $(seq 20); do [ "$(grep -Ec -- "$2" "$1" 2>/dev/null)" -ge "$n" ] && exit 0; sleep 0.5; done
exit 1'
# bump FILE: raise the serial line (YYYYMMDDnn ; serial) of a zone file by one
BUMP='#!/bin/sh
awk '\''/; serial/ && !done { sub(/[0-9]+/, $1 + 1); done = 1 } { print }'\'' "$1" > "$1.new" && cat "$1.new" > "$1" && rm "$1.new"'
# lab VM COMMAND...: anycast-lab.sh on VM 2, as "sudo sh anycast-lab.sh ..."
AC="sh /root/anycast/anycast-lab.sh"

stop_lab
rm -rf "$W"; mkdir -p "$W/classroom" "$W/handout" || exit 1
echo "01 192.0.2.30" > "$W/classroom/teams.conf"
: > "$OUT" || exit 1
"${DC[@]}" up -d --build --quiet-pull init parent m01-root m01-child m01-resolver >/dev/null 2>&1 \
    || { "${DC[@]}" logs; exit 1; }
docker build -q --build-arg DEBIAN_TAG="${DEBIAN_TAG:-trixie-20261005-slim}" -t dnslab/m05-vm:local "$here" >/dev/null || exit 1
docker run -d --init --tmpfs /run:rw,noexec,nosuid,nodev,mode=755 --name "$V1" --network "${PROJ}_lab" --ip 192.0.2.30 -v "$KIT:/kit:ro" -v "$M02:/m02:ro" dnslab/m05-vm:local >/dev/null || exit 1
docker run -d --init --privileged --tmpfs /run:rw,noexec,nosuid,nodev,mode=755 --name "$V2" --network "${PROJ}_lab" --ip 192.0.2.10 -v "$KIT:/kit:ro" -v "$M03:/m03:ro" dnslab/m05-vm:local >/dev/null || exit 1
for c in "$V1" "$V2"; do
    printf '%s\n' "$WAITLOG" | docker exec -i "$c" sh -c 'cat > /usr/local/bin/waitlog && chmod 755 /usr/local/bin/waitlog && touch /var/log/named.out'
    printf '%s\n' "$BUMP" | docker exec -i "$c" sh -c 'cat > /usr/local/bin/bump && chmod 755 /usr/local/bin/bump'
    docker exec "$c" sh -c 'rndc-confgen -a -u bind >/dev/null 2>&1' || exit 1
done

# VM 1 as Modules 2-4 left it: team01.example with the Lab 2.1-2.4 records
# (a fresh DKIM key, as each participant made one) and Module 3's lab33
# record, and the two reverse zones, all primary zones in /var/lib/bind
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
# VM 2 as Modules 3-4 left it: the BIND resolver with the Module 3 kit's
# files; one comment line stands for the team's own edits (lab-sheet
# addresses), so a clean-up that copies a template back would show up
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
# the participant's copy of the kit's anycast directory on VM 2
on vm2 "cp -r /kit/anycast /root/anycast"
if [ "${SETUP_ONLY:-0}" = 1 ]; then echo "set up; work dir $W; transcript $OUT"; exit 0; fi

{ echo "# Module 5 rehearsal, $(date -u +%Y-%m-%dT%H:%MZ)"
  docker exec "$V2" sh -c 'named -v; bird --version 2>&1; dpkg-query -W bind9 bind9-dnsutils bird2 iproute2'
  echo; } >> "$OUT"

echo "== Day 3 morning: the VMs as Module 4 left them"
step vm1 "0.1 VM 1 answers for team01.example with aa" "dig @192.0.2.30 team01.example SOA +norec" \
    'flags: qr aa ra;' ' 2026102709 3600 600 1209600 60'
step vm2 "0.2 VM 2's BIND resolves the team zone; only named listens; /run is noexec, as on Debian" \
    "dig @192.0.2.10 www.team01.example +short; ss -lntuH | awk '{print \$5}' | sort -u; dpkg-query -W bird2; echo run=\$(findmnt -no OPTIONS /run)" \
    '^192\.0\.2\.80$' '^192\.0\.2\.10:53$' '!:(5300|8053|8081|179)$' '^bird2[[:space:]]+2\.17\.' '^run=.*noexec'
for v in vm1 vm2; do on $v "cp \"$L\" /root/named.conf.local.m04; cp \"$O\" /root/named.conf.options.m04; cp \"$N\" /root/named.conf.m04"; done
on vm1 "cp \"$Z\" /root/db.team01.example.m04"

echo "== Lab 5.1: hidden primary"
HP=/var/lib/bind/db.hp.team01.example
on vm2 "cp \"$L\" /etc/bind/named.conf.local.m04 && sed 's/NN/01/g' /kit/vm2/db.hp.teamNN.example > \"$HP\" && sed 's/NN/01/g' /kit/vm2/named.conf.hidden-primary >> \"$L\""
step vm2 "5.1.1a the hidden primary's zone checks" "named-checkzone hp.team01.example \"$HP\"" 'loaded serial 2026102801' '^OK$'
reconf vm2 "5.1.1b VM 2: hidden primary loaded"
step vm2 "5.1.1 VM 2 refuses even its own users for the hidden zone (allow-query: VM 1 only)" \
    "waitlog /var/log/named.out 'zone hp\\.team01\\.example/IN: loaded serial 2026102801'; dig @127.0.0.1 www.hp.team01.example" \
    'status: REFUSED' 'EDE: 18 \(Prohibited\)' '!192\.0\.2\.120'
on vm1 "cp \"$L\" /etc/bind/named.conf.local.m04 && sed 's/NN/01/g' /kit/vm1/named.conf.public-secondary >> \"$L\""
reconf vm1 "5.1.2a VM 1: public secondary added"
step vm1 "5.1.2 VM 1 transfers the zone and answers it with aa" \
    "waitlog /var/log/named.out 'zone hp\\.team01\\.example/IN: transferred serial 2026102801'; grep 'hp.team01.example/IN: transferred serial' /var/log/named.out; dig @127.0.0.1 www.hp.team01.example +norec; stat -c '%U %a %n' /var/cache/bind/db.hp.team01.example" \
    'transferred serial 2026102801' 'flags: qr aa' 'www\.hp\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.120' '^bind 644 /var/cache/bind/db\.hp\.team01\.example$'
on vm1 "echo 'hp      IN NS    ns1.team01.example.' >> \"$Z\" && bump \"$Z\" && rndc reload team01.example && rndc querylog on"
on vm2 "rndc querylog on"
step vm1 "5.1.3 the delegation in team01.example (serial 2026102710)" \
    "named-checkzone team01.example $Z; waitlog /var/log/named.out 'zone team01\\.example/IN: loaded serial 2026102710'; dig @127.0.0.1 hp.team01.example NS +norec" \
    'loaded serial 2026102710' '^OK$' 'flags: qr aa' 'hp\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+NS[[:space:]]+ns1\.team01\.example\.'
step vm2 "5.1.4 a resolver elsewhere gets the answer; the path never names VM 2" \
    "dig @192.0.2.55 www.hp.team01.example +short; dig @192.0.2.53 www.hp.team01.example +norec; dig @192.0.2.30 www.hp.team01.example +norec | grep -E 'flags|^www'" \
    '^192\.0\.2\.120$' 'flags: qr;' 'team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+NS[[:space:]]+ns1\.team01\.example\.' 'ns1\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.30' 'flags: qr aa' '!192\.0\.2\.10'
step vm1 "5.1.4b VM 1's query log shows the lab resolver" \
    "waitlog /var/log/named.out 'client .* 192\\.0\\.2\\.55#[0-9]+ \\(www\\.hp\\.team01\\.example\\): query: www\\.hp\\.team01\\.example IN A'; grep 'query: www.hp.team01.example IN A' /var/log/named.out" \
    '192\.0\.2\.55#[0-9]+ \(www\.hp\.team01\.example\): query: www\.hp\.team01\.example IN A'
step vm2 "5.1.4c VM 2 logs queries, and none came from the lab resolver" \
    "dig @127.0.0.1 www.team01.example +short >/dev/null; waitlog /var/log/named.out '127\\.0\\.0\\.1#[0-9]+ \\(www\\.team01\\.example\\): query:' && echo querylog-on; echo from55=\$(grep -c '192\\.0\\.2\\.55#' /var/log/named.out)" \
    '^querylog-on$' '^from55=0$'
step vm2 "5.1.5a AXFR from VM 2 itself is refused (allow-transfer: VM 1 only)" "dig @192.0.2.10 hp.team01.example AXFR" '; Transfer failed\.'
step vm1 "5.1.5b VM 1 may transfer from VM 2; nobody may transfer from VM 1" \
    "echo records=\$(dig @192.0.2.10 hp.team01.example AXFR +noall +answer | grep -c IN); dig @192.0.2.30 hp.team01.example AXFR" \
    '^records=4$' '; Transfer failed\.'
on vm2 "echo 'app     IN A    192.0.2.121' >> \"$HP\" && bump \"$HP\" && rndc reload hp.team01.example"
step vm2 "5.1.6 a change on the hidden primary: NOTIFY to VM 1 only" \
    "waitlog /var/log/named.out 'hp\\.team01\\.example/IN: sending notify to 192\\.0\\.2\\.30#53' 2; grep -E 'hp.team01.example/IN: (loaded serial|sending notify)' /var/log/named.out | tail -3" \
    'loaded serial 2026102802' 'sending notify to 192\.0\.2\.30#53' '!sending notify to 192\.0\.2\.(10|53|55)'
step vm1 "5.1.6b VM 1 transfers serial 2026102802; the lab resolver sees app" \
    "waitlog /var/log/named.out 'transferred serial 2026102802'; grep -E 'hp.team01.example/IN: (notify from|transferred serial 2026102802)' /var/log/named.out; dig @192.0.2.55 app.hp.team01.example +short" \
    'notify from 192\.0\.2\.10#[0-9]+: serial 2026102802' 'transferred serial 2026102802' '^192\.0\.2\.121$'
on vm2 "sed -i 's/192\\.0\\.2\\.121/192.0.2.122/' \"$HP\" && rndc reload hp.team01.example"
step vm2 "5.1.7 a change without a new serial: BIND warns" \
    "waitlog /var/log/named.out 'zone serial \\(2026102802\\) unchanged'; grep 'unchanged' /var/log/named.out" \
    'zone hp\.team01\.example/IN: zone serial \(2026102802\) unchanged\. zone may fail to transfer to secondaries\.'
step vm1 "5.1.7b same serial on both servers, different data" \
    "for _ in \$(seq 20); do [ \"\$(dig @192.0.2.10 app.hp.team01.example +short +norec)\" = 192.0.2.122 ] && break; sleep 0.25; done; echo hidden=\$(dig @192.0.2.10 app.hp.team01.example +short +norec) public=\$(dig @127.0.0.1 app.hp.team01.example +short +norec); for s in 192.0.2.10 127.0.0.1; do dig @\$s hp.team01.example SOA +short +norec; done" \
    '^hidden=192\.0\.2\.122 public=192\.0\.2\.121$' 'hostmaster\.team01\.example\. 2026102802 '
on vm2 "bump \"$HP\" && rndc reload hp.team01.example"
step vm1 "5.1.7c a new serial: the public copy catches up" \
    "waitlog /var/log/named.out 'transferred serial 2026102803'; dig @127.0.0.1 app.hp.team01.example +short +norec" '^192\.0\.2\.122$'
on vm1 "mv /etc/bind/named.conf.local.m04 \"$L\" && sed -i '/^hp[[:space:]]/d' \"$Z\" && bump \"$Z\" && rndc reload team01.example"
reconf vm1 "5.1.8a VM 1: secondary and delegation removed"
on vm1 "rm -f /var/cache/bind/db.hp.team01.example"
on vm2 "mv /etc/bind/named.conf.local.m04 \"$L\""
reconf vm2 "5.1.8b VM 2: hidden primary removed"
on vm2 "rm -f \"$HP\"; rndc querylog off"
step vm1 "5.1.8 clean-up: no hp zone on either VM; only the serial of team01.example changed" \
    "waitlog /var/log/named.out 'zone team01\\.example/IN: loaded serial 2026102711'; dig @127.0.0.1 www.hp.team01.example +norec | grep status; cmp /root/named.conf.local.m04 \"$L\" && echo same-conf; diff /root/db.team01.example.m04 \"$Z\"; ls /var/cache/bind" \
    'status: NXDOMAIN' '^same-conf$' '^< .*2026102709 ; serial' '^> .*2026102711 ; serial' '!^[<>] .*hp' '!db\.hp'
step vm2 "5.1.8c VM 2: named.conf.local as Module 4 left it, no zone file" \
    "cmp /root/named.conf.local.m04 \"$L\" && echo same-conf; ls /var/lib/bind; rndc flushtree team01.example; dig @127.0.0.1 www.hp.team01.example | grep status" \
    '^same-conf$' '!db\.hp' 'status: NXDOMAIN'

echo "== Lab 5.2: split horizon with views"
on vm1 "cp \"$L\" /etc/bind/named.conf.local.m04 && cp \"$N\" /etc/bind/named.conf.m04 && sed -e 's/NN/01/g' -e 's/N2\\.N1/1.0/' /kit/vm1/named.conf.views > \"$L\""
step vm1 "5.2.1 views with a zone outside them: named-checkconf refuses" "named-checkconf; echo rc=\$?" \
    "named\.conf\.root-hints:[0-9]+: when using 'view' statements, all zones must be in views" '^rc=1$'
on vm1 "sed -i 's|^include \"/etc/bind/named.conf.root-hints\";|// & // Module 5: in the views now|' \"$N\" && cp \"$Z\" \"$Z.internal\" && cat /kit/vm1/internal.additions >> \"$Z.internal\" && bump \"$Z.internal\""
step vm1 "5.2.2a both copies of the zone and the shared reverse zones load" "named-checkconf -z" \
    'zone team01\.example/IN: loaded serial 2026102712' 'zone team01\.example/IN: loaded serial 2026102711' 'zone 2\.0\.192\.in-addr\.arpa/IN: loaded serial'
reconf vm1 "5.2.2b VM 1: views loaded"
step vm1 "5.2.2 VM 1 itself (localhost) is internal" \
    "dig @127.0.0.1 intranet.team01.example +short; dig @127.0.0.1 whichview.team01.example TXT +short; dig @127.0.0.1 -x 192.0.2.80 +short" \
    '^192\.0\.2\.90$' '^"internal"$' '^www\.team01\.example\.$'
step vm2 "5.2.3 VM 2's users see the internal zone, the lab resolver's users the external one" \
    "rndc flushtree team01.example; for r in 192.0.2.10 192.0.2.55; do for n in intranet whichview; do echo \$r \$n \$(dig @\$r \$n.team01.example ANY | grep -o 'status: [A-Z]*') \$(dig @\$r \$n.team01.example ANY +short); done; done; dig @192.0.2.55 www.team01.example +short" \
    '^192\.0\.2\.10 intranet status: NOERROR 192\.0\.2\.90$' '^192\.0\.2\.10 whichview status: NOERROR "internal"$' '^192\.0\.2\.55 intranet status: NXDOMAIN$' '^192\.0\.2\.55 whichview status: NXDOMAIN$' '^192\.0\.2\.80$'
step vm1 "5.2.3b the query log names the view" \
    "grep -E 'view (internal|external): query: intranet' /var/log/named.out" \
    '192\.0\.2\.10#[0-9]+ \(intranet\.team01\.example\): view internal: query: intranet\.team01\.example IN ANY' '192\.0\.2\.55#[0-9]+ \(intranet\.team01\.example\): view external: query: intranet\.team01\.example IN ANY'
step vm1 "5.2.4 rndc needs the view name for a zone in two views" \
    "rndc reload team01.example; rndc reload team01.example IN internal" \
    "zone 'team01\.example' was found in multiple views" '^zone reload (up-to-date|queued)$'
on vm1 "sed -i 's|^    192\\.0\\.2\\.10;|    // 192.0.2.10;|' \"$L\""
reconf vm1 "5.2.5a VM 2 taken out of the internal ACL"
step vm2 "5.2.5 VM 2 now matches the external view: a cached answer first, NXDOMAIN after a flush" \
    "echo cached=\$(dig @127.0.0.1 intranet.team01.example +short); rndc flushtree team01.example; dig @127.0.0.1 intranet.team01.example | grep -o 'status: [A-Z]*'; dig @192.0.2.30 www.team01.example | grep flags" \
    '^cached=192\.0\.2\.90$' 'status: NXDOMAIN' 'flags: qr aa rd;'
on vm1 "mv /etc/bind/named.conf.local.m04 \"$L\" && mv /etc/bind/named.conf.m04 \"$N\" && rm -f \"$Z.internal\""
reconf vm1 "5.2.6a VM 1: views removed"
on vm1 "ls /var/cache/bind; rm -f /var/cache/bind/internal.mkeys* /var/cache/bind/external.mkeys*"
step vm1 "5.2.6 VM 1 as before: no views, no internal names, files back" \
    "rndc querylog on >/dev/null 2>&1; dig @127.0.0.1 intranet.team01.example | grep -o 'status: [A-Z]*'; dig @127.0.0.1 www.team01.example +norec | grep flags; cmp /root/named.conf.local.m04 \"$L\" && cmp /root/named.conf.m04 \"$N\" && echo same; ls /var/lib/bind /var/cache/bind; tail -1 /var/log/named.out" \
    'status: NXDOMAIN' 'flags: qr aa' '^same$' '!internal$|(internal|external)\.mkeys' '!view (internal|external)'
on vm1 "rndc querylog off"
step vm2 "5.2.6b VM 2 resolves the team zone again (cache flushed)" \
    "rndc flushtree team01.example; dig @127.0.0.1 www.team01.example +short; dig @127.0.0.1 intranet.team01.example | grep -o 'status: [A-Z]*'" \
    '^192\.0\.2\.80$' 'status: NXDOMAIN'

echo "== Theory slide check: serve-stale on VM 2 (RFC 8767), VM 1 stopped"
on vm2 "sed -i 's|^    validate-except|    stale-cache-enable yes;\\n    stale-answer-enable yes;\\n    max-cache-ttl 5;            // test only: expire the cache quickly\\n    validate-except|' \"$O\"; grep -n stale \"$O\""
reconf vm2 "S.1a VM 2: serve-stale on, max-cache-ttl 5"
step vm2 "S.1b a fresh answer, capped at 5 s" "rndc flushtree team01.example; dig @127.0.0.1 www.team01.example | grep -E '^www|status'" \
    'status: NOERROR' 'www\.team01\.example\.[[:space:]]+5[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.80'
on vm1 "rndc stop; for _ in \$(seq 20); do rndc status >/dev/null 2>&1 || break; sleep 0.5; done"
step vm2 "S.1 VM 1 down, TTL expired: a stale answer with EDE 3 and TTL 30" \
    "sleep 6; dig @127.0.0.1 www.team01.example +time=15 +tries=1 | grep -E 'status|EDE|^www'" \
    'status: NOERROR' 'EDE: 3 \(Stale Answer\)' 'www\.team01\.example\.[[:space:]]+30[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.80'
on vm2 "cp /root/named.conf.options.m04 \"$O\""
reconf vm2 "S.2a VM 2: Module 4's options back"
step vm2 "S.2 the same without serve-stale: SERVFAIL" \
    "rndc flushtree team01.example; dig @127.0.0.1 www.team01.example +time=15 +tries=1 | grep -E 'status|EDE'; cmp /root/named.conf.options.m04 \"$O\" && echo same" \
    'status: SERVFAIL' '^same$' '!Stale Answer'
start_named vm1
step vm2 "S.3 VM 1 back: VM 2 resolves the team zone again" \
    "for i in \$(seq 20); do a=\$(dig @127.0.0.1 www.team01.example +short); [ -n \"\$a\" ] && break; sleep 1; done; echo \"\$a after \$i tries\"" '^192\.0\.2\.80 after [0-9]+ tries$'

echo "== Lab 5.3: anycast in one VM"
step vm2 "5.3.1 the lab comes up: six namespaces, the service route at both routers" \
    "$AC up; ip netns list | sort" \
    '^anycast lab up: R1 198\.51\.100\.53 via 198\.51\.100\.6 dev r1-a proto bird' 'R2 198\.51\.100\.53 via 198\.51\.100\.14 dev r2-b proto bird' \
    '^m05-a' '^m05-b' '^m05-c1' '^m05-c2' '^m05-r1' '^m05-r2' \
    || { docker exec "$V2" sh /root/anycast/anycast-lab.sh status; echo "the anycast lab did not come up; stopping"; exit 1; }
step vm2 "5.3.2 R1 knows two paths and uses the shorter (site A); R2 uses site B" "$AC status" \
    'site_a up .*Established' 'r2 up .*Established' 'unicast \[site_a [0-9:.]+\] \* \(100\) \[AS65100i\]' 'AS path: 65002 65100' \
    'r2: forwarding: 198\.51\.100\.53 via 198\.51\.100\.14' 'site a: named running, health check running' 'site b: named running, health check running'
step vm2 "5.3.3 one address, two servers: NSID and id.server name the site" \
    "for c in c1 c2; do echo \$c \$(ip netns exec m05-\$c dig @198.51.100.53 www.svc.test +nsid +norec | grep -E '^; NSID|^www' | tr -s '\t ' ' '); echo \$c \$(ip netns exec m05-\$c dig @198.51.100.53 id.server CH TXT +short); done; ip netns exec m05-c1 dig @198.51.100.14 id.server CH TXT +short; echo loop: \$(ip netns exec m05-c1 dig @198.51.100.53 www.svc.test +nsid +time=1 +tries=1 | grep -o 'site-.' || echo fail)" \
    '^loop: site-a$' '^c1 ; NSID: 73 69 74 65 2d 61 \("site-a"\) www\.svc\.test\. 30 IN A 198\.51\.100\.80$' '^c2 ; NSID: 73 69 74 65 2d 62 \("site-b"\) www\.svc\.test\. 30 IN A 198\.51\.100\.80$' \
    '^c1 "site-a"$' '^c2 "site-b"$' '^"site-b"$'
step vm2 "5.3.4 ten queries from each client: each site logs one city's queries" \
    "for c in c1 c2; do for i in \$(seq 10); do ip netns exec m05-\$c dig @198.51.100.53 q\$i.\$c.svc.test +short >/dev/null; done; done; for s in a b; do echo site \$s: c1=\$(grep -c 'client @[^ ]* 198\\.51\\.100\\.2#.*query: q[0-9]*\\.c1' /var/cache/bind/m05-anycast/\$s/query.log) c2=\$(grep -c 'client @[^ ]* 198\\.51\\.100\\.18#.*query: q[0-9]*\\.c2' /var/cache/bind/m05-anycast/\$s/query.log); done" \
    '^site a: c1=10 c2=0$' '^site b: c1=0 c2=10$'
step vm2 "5.3.5 named at site A stops: the health check withdraws the route, C1 moves to site B" \
    "( for i in \$(seq 60); do r=\$(ip netns exec m05-c1 dig @198.51.100.53 www.svc.test +nsid +norec +time=1 +tries=1 2>/dev/null | grep -o 'site-[ab]' | head -1); echo \"\$(date +%s.%N) \${r:-fail}\"; sleep 0.2; done > /root/failover.txt ) & sleep 1; t0=\$(date +%s.%N); $AC stop a; wait; awk -v t0=\$t0 '\$1 >= t0 { if (\$2 != prev) printf \"%+.1f s %s\\n\", \$1 - t0, \$2; prev = \$2; if (\$2 == \"site-b\") b = 1; else if (b) back = 1 } END { print \"reached-b=\" b+0 \" back=\" back+0 }' /root/failover.txt; cat /run/m05-anycast/a-health.log; $AC status" \
    '^named at site a stopped$' '^\+[0-9.]+ s site-b$' '^reached-b=1 back=0$' 'site a: named down, route withdrawn' 'r1: forwarding: 198\.51\.100\.53 via 198\.51\.100\.10 dev r1-r2' 'site a: named stopped, health check running'
step vm2 "5.3.6 named at site A starts again: C1 is back at site A" \
    "$AC start a; for _ in \$(seq 20); do ip -n m05-r1 route show 198.51.100.53 | grep -q 'via 198.51.100.6' && break; sleep 0.5; done; ip netns exec m05-c1 dig @198.51.100.53 id.server CH TXT +short; tail -1 /run/m05-anycast/a-health.log" \
    '^"site-a"$' 'site a: named up, route announced'
step vm2 "5.3.7 the box is separate: VM 2's own named and routes are unchanged" \
    "ss -lntuH | awk '{print \$5}' | sort -u; ip route show | grep -c 198.51.100; ps -o rss=,comm= -C named,bird | awk '{ s[\$2] += \$1; n[\$2]++ } END { for (k in s) printf \"%s %d processes %d MiB\\n\", k, n[k], s[k] / 1024 }'" \
    '^192\.0\.2\.10:53$' '^0$' '!198\.51\.100' '^named 3 processes' '^bird 4 processes'

echo "== Lab 5.4: troubleshooting drill (faults set by ../instructor/faults.sh, piped as over SSH)"
Q='for c in c1 c2; do echo $c $(ip netns exec m05-$c dig @198.51.100.53 www.svc.test +nsid +norec +time=1 +tries=1 2>&1 | grep -E "^; NSID|^www|connection refused|timed out" | grep -o "site-[ab]\|198\.51\.100\.8[01]\|connection refused\|timed out"); done'
# poll UNTIL: wait up to 10 s until the shell test UNTIL holds (on VM 2)
poll() { printf 'for _ in $(seq 40); do %s && break; sleep 0.25; done; ' "$1"; }
faultset() { step vm2 "$1" "cat /kit/instructor/faults.sh | sh -s -- $2" '^fault set$' '!fault [0-9]'; }
fixed() { step vm2 "$1" "$AC fix && $AC status" '^faults undone$' \
    'site a: named running, health check running' 'site b: named running, health check running' \
    'r1: forwarding: 198\.51\.100\.53 via 198\.51\.100\.6 ' 'r2: forwarding: 198\.51\.100\.53 via 198\.51\.100\.14 '; }
faultset "5.4.1a instructor sets fault 1 (the output does not name it)" 1
step vm2 "5.4.1 fault 1: city 2 gets an old address; site B has an older serial" \
    "$(poll "ip netns exec m05-c1 dig @198.51.100.14 svc.test SOA +short | grep -q ' 2026102701 '")$Q; for u in 198.51.100.6 198.51.100.14; do echo \$u \$(ip netns exec m05-c1 dig @\$u svc.test SOA +short); done" \
    '^c1 site-a 198\.51\.100\.80$' '^c2 site-b 198\.51\.100\.81$' '^198\.51\.100\.6 .* 2026102801 ' '^198\.51\.100\.14 .* 2026102701 '
fixed "5.4.1b fix: both sites healthy, each city at its own site"
faultset "5.4.2a instructor sets fault 2" 2
step vm2 "5.4.2 fault 2: city 1 cannot resolve; R1 still routes to site A, where nothing runs" \
    "$(poll "ip netns exec m05-c1 dig @198.51.100.53 www.svc.test +time=1 +tries=1 2>&1 | grep -q 'connection refused'")$Q; $AC status" \
    '^c1 connection refused' '^c2 site-b 198\.51\.100\.80$' 'r1: forwarding: 198\.51\.100\.53 via 198\.51\.100\.6 dev r1-a' 'site a: named stopped, health check stopped'
fixed "5.4.2b fix: site A's named and health check back, the restart visible in its log"
step vm2 "5.4.2c the health log shows the check's restart" "tail -3 /run/m05-anycast/a-health.log" \
    'site a: health check started \(pid [0-9]+\)' 'site a: named up, route announced'
faultset "5.4.3a instructor sets fault 3" 3
step vm2 "5.4.3 fault 3: city 1 answered from site B; site A's path is longer" \
    "$(poll "birdc -s /run/m05-anycast/r1.ctl show route 198.51.100.53/32 all | grep -q '65100 65100 65100'")$Q; $AC status" \
    '^c1 site-b 198\.51\.100\.80$' '^c2 site-b 198\.51\.100\.80$' 'AS path: 65100 65100 65100' 'r1: forwarding: 198\.51\.100\.53 via 198\.51\.100\.10 dev r1-r2'
fixed "5.4.3b fix: the prepending gone"
step vm2 "5.4.4 after fix: each city at its own site again" "$Q" '^c1 site-a 198\.51\.100\.80$' '^c2 site-b 198\.51\.100\.80$'
step vm2 "5.4.5 down: no namespaces, no files, no processes left" \
    "$AC down; echo netns=\$(ip netns list | wc -l) bird=\$(pgrep -cx bird) health=\$(pgrep -cf '[h]ealthcheck\\.sh') named=\$(pgrep -cx named); ls -d /run/m05-anycast /etc/bind/m05-anycast /var/cache/bind/m05-anycast /usr/local/lib/m05-anycast 2>&1" \
    '^anycast lab removed$' '^netns=0 bird=0 health=0 named=1$' \
    "cannot access '/run/m05-anycast'" "cannot access '/etc/bind/m05-anycast'" "cannot access '/var/cache/bind/m05-anycast'" "cannot access '/usr/local/lib/m05-anycast'"
step vm2 "5.4.6 end state VM 2: Module 4's files, only named on port 53, resolves the team zone" \
    "cmp /root/named.conf.local.m04 \"$L\" && cmp /root/named.conf.options.m04 \"$O\" && cmp /root/named.conf.m04 \"$N\" && echo same; ss -lntuH | awk '{print \$5}' | sort -u; dig @127.0.0.1 www.team01.example +short; ls /var/lib/bind /var/cache/bind; rndc status | grep 'query logging'" \
    '^query logging is OFF$' '^same$' '^192\.0\.2\.10:53$' '!:(179|5300|8053|8081)$' '^192\.0\.2\.80$' '!db\.hp|m05'
step vm1 "5.4.7 end state VM 1: Module 4's files, the zone with a higher serial and nothing else changed" \
    "cmp /root/named.conf.local.m04 \"$L\" && cmp /root/named.conf.options.m04 \"$O\" && cmp /root/named.conf.m04 \"$N\" && echo same; diff /root/db.team01.example.m04 \"$Z\" | grep -c '^[<>]'; ls /var/lib/bind /var/cache/bind; rndc status | grep 'query logging'; dig @192.0.2.55 www.team01.example +short" \
    '^same$' '^2$' '!internal|db\.hp' '^192\.0\.2\.80$' '^query logging is OFF$'

echo "== $pass passed, $fail failed; transcript: $OUT"
[ "$fail" -eq 0 ]
