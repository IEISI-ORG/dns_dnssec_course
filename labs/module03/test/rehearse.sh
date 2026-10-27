#!/bin/bash
# rehearse.sh [TRANSCRIPT]: run every Module 3 lab step (Labs 3.1-3.4) on two
# stand-in participant VMs and check each checkpoint.
#
# It starts the instructor stack (../../instructor, profile m01: the registry
# for example. and the Module 1 lab resolver, kept on for Day 2) on an
# internal Docker bridge with no route out, plus two Debian 13 containers
# with bind9, bind9-utils and bind9-dnsutils: VM 1 at 192.0.2.30, set up as
# Module 2 left it (primary for team01.example, from ../../module02/zones),
# and VM 2 at 192.0.2.10, where named has never run. teams.conf delegates
# team01.example to VM 1 only. The participant's typing is the commands
# below; the kit files come from ../vm1 and ../vm2. named runs in the
# foreground with its log in /var/log/named.out, where a VM has the journal.
# Everything is removed at the end. The transcript goes to TRANSCRIPT, or to
# a new file under ${TMPDIR:-/tmp} whose name is printed. Needs Docker with
# Compose v2; about a minute with the images built. The lab steps need no
# Internet access; the image build does.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "$here/.." && pwd)
M02=$(cd "$here/../../module02" && pwd)
INS=$(cd "$here/../../instructor" && pwd)
unset M01_FAULT_LABELS
PROJ=dnslab-m03
V1=dnslab-m03-vm1
V2=dnslab-m03-vm2
export COMPOSE_PROFILES=m01
DC=(docker compose -p "$PROJ" --env-file "$INS/test/test.env" -f "$INS/compose.yaml" -f "$INS/compose.test.yaml")
Z=/var/lib/bind/db.team01.example
L=/etc/bind/named.conf.local
pass=0; fail=0
W=

stop_lab() {
    docker rm -f "$V1" "$V2" >/dev/null 2>&1
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
}
trap 'stop_lab; [ -n "$W" ] && rm -rf "$W"' EXIT
OUT=${1:-$(mktemp "${TMPDIR:-/tmp}/m03-rehearsal.XXXXXX")} || exit 1
W=$(mktemp -d) || exit 1
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
}
# on VM COMMAND: run quietly on VM (input from stdin), keep it in the transcript
on() {
    local c; c=$(ctr "$1") || exit 1
    log "$c\$ $2"; docker exec -i "$c" bash -c "$2" >> "$OUT" 2>&1
}
# keygen VM NAME: Lab 3.1's "sudo rndc-confgen -a -u bind" on a VM whose
# image has no key (as the README asks); checked
keygen() {
    step "$1" "$2" "test ! -e /etc/bind/rndc.key && echo no-key-yet; rndc-confgen -a -u bind && stat -c '%U %a' /etc/bind/rndc.key" \
        '^no-key-yet$' 'wrote key file "/etc/bind/rndc\.key"' '^bind 6[04]0$'
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
# reconf VM NAME: what the participant does after editing named.conf*; checked
reconf() { step "$1" "$2" "named-checkconf && rndc reconfig && rndc flush && echo reconfigured" '^reconfigured$'; }
# waitlog PATTERN [COUNT]: (on the VM) wait up to 10 s until named's log has
# COUNT (default 1) lines matching PATTERN; installed on both VMs below
WAITLOG='#!/bin/sh
n=${2:-1}
for _ in $(seq 20); do [ "$(grep -Ec -- "$1" /var/log/named.out)" -ge "$n" ] && exit 0; sleep 0.5; done
exit 1'

stop_lab
mkdir "$W/classroom" "$W/handout"
echo "01 192.0.2.30" > "$W/classroom/teams.conf"
: > "$OUT" || exit 1
"${DC[@]}" up -d --build --quiet-pull init parent m01-root m01-child m01-resolver >/dev/null 2>&1 \
    || { "${DC[@]}" logs; exit 1; }
docker build -q --build-arg DEBIAN_TAG="${DEBIAN_TAG:-trixie-20261005-slim}" -t dnslab/m03-vm:local "$here" >/dev/null || exit 1
docker run -d --name "$V1" --network "${PROJ}_lab" --ip 192.0.2.30 -v "$KIT:/kit:ro" -v "$M02:/m02:ro" dnslab/m03-vm:local >/dev/null || exit 1
docker run -d --name "$V2" --network "${PROJ}_lab" --ip 192.0.2.10 -v "$KIT:/kit:ro" dnslab/m03-vm:local >/dev/null || exit 1
for c in "$V1" "$V2"; do
    printf '%s\n' "$WAITLOG" | docker exec -i "$c" sh -c 'cat > /usr/local/bin/waitlog && chmod 755 /usr/local/bin/waitlog && touch /var/log/named.out'
done

# VM 1 as Module 2 left it: team01.example from the Module 2 template with
# the Lab 2.1 records, loaded as a primary from /var/lib/bind
on vm1 "sed 's/NN/01/g' /m02/zones/db.teamNN.example > \"$Z\" && cat >> \"$Z\"" <<'EOF'
@       IN A     192.0.2.80
        IN AAAA  2001:db8:1::80
        IN MX    10 mail
www     IN A     192.0.2.80
        IN AAAA  2001:db8:1::80
web     IN CNAME www
mail    IN A     192.0.2.81
        IN AAAA  2001:db8:1::81
ftp     IN A     192.0.2.82
EOF
on vm1 "sed -n '/^zone \"teamNN.example\"/,/^};/p' /m02/zones/named.conf.local | sed 's/NN/01/g' >> \"$L\""
keygen vm1 "0.0 VM 1's own rndc key (Module 2, Lab 2.1)"
start_named vm1
for _ in $(seq 30); do
    docker exec "$V1" dig @192.0.2.55 +short www.team01.example A 2>/dev/null | grep -qx 192.0.2.80 && break
    sleep 1
done
docker exec "$V1" dig @192.0.2.55 +short www.team01.example A 2>/dev/null | grep -qx 192.0.2.80 \
    || { echo "lab resolver or VM 1 not answering"; "${DC[@]}" logs; exit 1; }

{ echo "# Module 3 rehearsal, $(date -u +%Y-%m-%dT%H:%MZ)"
  docker exec "$V2" sh -c 'named -v; dig -v 2>&1; dpkg-query -W bind9 bind9-utils bind9-dnsutils'
  echo; } >> "$OUT"

echo "== Day 2 start: VM 1 as Module 2 left it, nothing on VM 2"
step vm1 "0.1 VM 1 answers for team01.example with aa" "dig @192.0.2.30 team01.example SOA +norec" \
    'flags: qr aa ra;' 'SOA[[:space:]]+ns1\.team01\.example\. hostmaster\.team01\.example\. 2026102701 '
step vm1 "0.2 the lab resolver (m01 profile, kept on for Day 2) resolves the team zone" \
    "dig @192.0.2.55 www.team01.example" 'status: NOERROR' '192\.0\.2\.80'
step vm1 "0.3 nothing answers on VM 2 yet" "dig @192.0.2.10 www.team01.example +tries=1 +time=2" \
    'connection refused|timed out|no servers could be reached'
step vm2 "0.4 VM 2 has BIND 9.20 from Debian 13, stopped, no rndc key" "named -v; dpkg-query -W bind9; ls /etc/bind" \
    '^BIND 9\.20\.' 'bind9[[:space:]]+1:9\.20' 'named\.conf\.options' '!rndc\.key'

echo "== Lab 3.1: a resolver on VM 2"
keygen vm2 "3.1.0 VM 2's own rndc key"
start_named vm2
step vm2 "3.1.1 named runs with Debian's configuration" "rndc status; cat /etc/bind/named.conf.options" \
    'server is up and running' '^[[:space:]]*directory "/var/cache/bind";' '!recursion|forward'
step vm2 "3.1.2 Debian's defaults: a resolver that knows only the real root (no Internet: SERVFAIL)" \
    "dig @127.0.0.1 www.team01.example +tries=1" 'status: SERVFAIL' 'flags: qr rd ra;'
on vm2 "cp /kit/vm2/named.conf.options /etc/bind/named.conf.options && cp /kit/vm2/named.conf.local $L"
step vm2 "3.1.3 kit options and static-stub zone: named-checkconf, rndc reconfig" \
    "named-checkconf && rndc reconfig && rndc flush && echo reconfigured" '^reconfigured$'
on vm1 "rndc querylog on"
q0=$(queries)
step vm2 "3.1.4 the team's name through VM 2: an answer, not authoritative" \
    "dig @127.0.0.1 www.team01.example" 'status: NOERROR' 'flags: qr rd ra;' '^www\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.80'
step vm1 "3.1.5 VM 1's query log: VM 2 asked, without RD ('-')" \
    "grep 'query: ' /var/log/named.out | tail -n +$((q0 + 1))" \
    'client @0x[0-9a-f]+ 192\.0\.2\.10#[0-9]+ \(www\.team01\.example\): query: www\.team01\.example IN A -'
q1=$(queries); sleep 3
step vm2 "3.1.6 asked again: from the cache, TTL counting down" "dig @127.0.0.1 www.team01.example +noall +answer" \
    '^www\.team01\.example\.[[:space:]]+5[0-9][[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.80'
q2=$(queries)
log "VM 1 query-log lines before and after the cached answer: $q1 $q2"
if [ "$q1" = "$q2" ]; then ok "3.1.6b no new query reached VM 1"; else bad "3.1.6b no new query reached VM 1 ($q1 -> $q2)"; fi
step vm1 "3.1.7 VM 1 (on VM 2's subnet) may use VM 2 as its resolver" "dig @192.0.2.10 mail.team01.example" \
    'status: NOERROR' 'flags: qr rd ra;' '192\.0\.2\.81'
step vm2 "3.1.8 +norec under the static-stub zone: REFUSED" "dig @127.0.0.1 www.team01.example +norec" \
    'status: REFUSED'
step vm2 "3.1.9 a negative answer, then the cache dump" \
    "dig @127.0.0.1 nosuch.team01.example +noall +comments | grep status; rndc dumpdb -cache && for _ in \$(seq 20); do grep -q '^; Dump complete' /var/cache/bind/named_dump.db 2>/dev/null && break; sleep 0.5; done; stat -c '%U %a' /var/cache/bind/named_dump.db; grep -A1 -E 'team01|^; (Address database|SERVFAIL cache)' /var/cache/bind/named_dump.db" \
    'status: NXDOMAIN' '^www\.team01\.example\.[[:space:]]+[0-9]+[[:space:]]+A[[:space:]]+192\.0\.2\.80' \
    '^nosuch\.team01\.example\.[[:space:]]+[0-9]+[[:space:]]+\\-ANY[[:space:]]+;-\$NXDOMAIN' \
    '^; Address database dump' '^; ns1\.team01\.example\. \[v4 TTL' '^;[[:space:]]+192\.0\.2\.30 \[srtt [0-9]+\]' '^; SERVFAIL cache' '^bind 644$'
q3=$(queries)
step vm2 "3.1.10 flushname: the next query goes to VM 1 again" \
    "rndc flushname www.team01.example && dig @127.0.0.1 www.team01.example +noall +answer" \
    '^www\.team01\.example\.[[:space:]]+60[[:space:]]+IN[[:space:]]+A'
q4=$(queries); log "VM 1 query-log lines before and after flushname: $q3 $q4"
if [ "$q4" -gt "$q3" ]; then ok "3.1.10b VM 1 saw the new query"; else bad "3.1.10b VM 1 saw the new query ($q3 -> $q4)"; fi

echo "== Lab 3.2: forwarding"
on vm2 "sed -n '/^zone \"example\"/,/^};/p' /kit/vm2/named.conf.forward > \"$L\"; cat \"$L\""
reconf vm2 "3.2.0 forward zone (a) loaded"
q5=$(queries)
step vm2 "3.2.1 conditional forwarding to the lab resolver (a name not asked before)" "dig @127.0.0.1 ftp.team01.example" \
    'status: NOERROR' '192\.0\.2\.82'
step vm1 "3.2.2 VM 1's query log: now the forwarder (192.0.2.55) asked, not VM 2" \
    "grep 'query: ' /var/log/named.out | tail -n +$((q5 + 1))" \
    '192\.0\.2\.55#[0-9]+ \(ftp\.team01\.example\): query: ftp\.team01\.example IN A -' '!192\.0\.2\.10#'
step vm2 "3.2.3 the forwarder's cache holds the answer" "dig @192.0.2.55 ftp.team01.example +norec +noall +comments +answer" \
    'status: NOERROR' '^ftp\.team01\.example\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.0\.2\.82'
on vm2 "sed -i 's/forwarders { 192.0.2.55; };/forwarders { 192.0.2.53; };/' \"$L\""
reconf vm2 "3.2.3b forwarder changed to the registry, loaded"
step vm2 "3.2.4 forwarding to the authoritative-only registry: SERVFAIL" \
    "grep -c 'forwarders { 192.0.2.53; };' $L; dig @127.0.0.1 www.team01.example +tries=1; grep 'non-improving referral' /var/log/named.out | tail -1" \
    '^1$' 'status: SERVFAIL' 'DNS format error from 192\.0\.2\.53#53 resolving www\.team01\.example/A for [0-9.#]+: non-improving referral'
on vm2 "sed -i 's/forwarders { 192.0.2.53; };/forwarders { 192.0.2.250; };/' \"$L\""
reconf vm2 "3.2.4b forwarder changed to an unused address, loaded"
step vm2 "3.2.5 a forwarder that does not answer, forward only: SERVFAIL after a timeout" \
    "grep -c 'forwarders { 192.0.2.250; };' $L; dig @127.0.0.1 www.team01.example +tries=1 +time=15" \
    '^1$' 'status: SERVFAIL' 'Query time: [1-9][0-9]{3,} msec'
on vm2 "cp /kit/vm2/named.conf.local \"$L\""
reconf vm2 "3.2.5b static-stub zone restored, loaded"
q6=$(queries)
step vm2 "3.2.6 the static-stub zone is back" "dig @127.0.0.1 www.team01.example; cmp /kit/vm2/named.conf.local $L && echo same" \
    'status: NOERROR' '192\.0\.2\.80' '^same$'
step vm1 "3.2.7 ... and VM 2 asks VM 1 itself again" "grep 'query: ' /var/log/named.out | tail -n +$((q6 + 1))" \
    '192\.0\.2\.10#[0-9]+ \(www\.team01\.example\): query: www\.team01\.example IN A -'

echo "== Lab 3.3: a secondary on VM 2"
step vm2 "3.3.1 zone transfer by hand: refused by BIND's default" "dig @192.0.2.30 team01.example AXFR" \
    '; Transfer failed\.'
on vm2 "sed 's/NN/01/g' /kit/vm2/named.conf.secondary >> \"$L\""
reconf vm2 "3.3.1b secondary zone added, loaded"
step vm2 "3.3.2 the secondary's first transfer: REFUSED" "waitlog 'failed while receiving responses: REFUSED'; grep 'transfer of .team01.example/IN. from' /var/log/named.out" \
    "transfer of 'team01\.example/IN' from 192\.0\.2\.30#53: failed while receiving responses: REFUSED"
step vm1 "3.3.3 VM 1's side: transfer denied" "grep 'zone transfer' /var/log/named.out | tail -1" \
    "client @0x[0-9a-f]+ 192\.0\.2\.10#[0-9]+ \(team01\.example\): zone transfer 'team01\.example/AXFR/IN' denied"
on vm1 "sed -i '/^zone \"team01.example\"/,/^};/ s|^\(    file .*\)\$|\1\n        allow-transfer { 192.0.2.10; };\n        also-notify { 192.0.2.10; };|' \"$L\"; cat \"$L\""
step vm1 "3.3.4 VM 1: allow-transfer and also-notify, checked and loaded" \
    "named-checkconf && rndc reconfig && echo reconfigured; grep -E 'allow-transfer|also-notify' $L" \
    '^reconfigured$' 'allow-transfer \{ 192\.0\.2\.10; \};' 'also-notify \{ 192\.0\.2\.10; \};'
step vm2 "3.3.5 rndc retransfer: the zone arrives" \
    "rndc retransfer team01.example; waitlog 'transferred serial 2026102701'; grep 'transferred serial' /var/log/named.out | tail -1; rndc zonestatus team01.example" \
    'zone team01\.example/IN: transferred serial 2026102701' 'type: secondary' 'serial: 2026102701' 'expires: '
step vm1 "3.3.6 VM 1's side: an AXFR to VM 2" "grep 'AXFR ended' /var/log/named.out | tail -1" \
    "192\.0\.2\.10#[0-9]+ \(team01\.example\): transfer of 'team01\.example/IN': AXFR ended: .*\(serial 2026102701\)"
step vm2 "3.3.7 both servers answer aa with the same serial" \
    "o=\$(for s in 192.0.2.10 192.0.2.30; do dig @\$s team01.example SOA +norec +noall +comments +answer; done); echo \"\$o\"; [ \$(grep -c 'flags: qr aa' <<< \"\$o\") -eq 2 ] && [ \$(grep -Ec 'SOA[[:space:]]+ns1.* 2026102701 ' <<< \"\$o\") -eq 2 ] && echo both-aa-same-serial" \
    '^both-aa-same-serial$'
step vm2 "3.3.8 the secondary's file is in raw format (not text)" "named-compilezone -f raw -F text -o - team01.example /var/cache/bind/db.team01.example 2>/dev/null | grep SOA; head -c 200 /var/cache/bind/db.team01.example | grep -ac 'IN[[:space:]]SOA'; stat -c '%U %a' /var/cache/bind/db.team01.example" \
    'team01\.example\..*SOA.*2026102701' '^0$' '^bind 644$'
on vm1 "sed -i -e 's/2026102701 ; serial/2026102702 ; serial/' \"$Z\" && echo 'app     IN A     192.0.2.84' >> \"$Z\""
step vm1 "3.3.9 a change on VM 1: reload, NOTIFY to VM 2" \
    "named-checkzone team01.example $Z && rndc reload team01.example && waitlog 'AXFR-style IXFR ended: .*serial 2026102702'; grep -E 'notif|transfer of' /var/log/named.out | tail -5" \
    'loaded serial 2026102702' 'zone team01\.example/IN: sending notify to 192\.0\.2\.10#53' \
    "IXFR version not in journal, falling back to AXFR" "AXFR-style IXFR ended: .*\(serial 2026102702\)"
step vm2 "3.3.10 VM 2: notify received, new serial transferred" "waitlog 'transferred serial 2026102702'; grep -E 'notify|transferred' /var/log/named.out | tail -3" \
    'zone team01\.example/IN: notify from 192\.0\.2\.30#[0-9]+: serial 2026102702' 'zone team01\.example/IN: transferred serial 2026102702'
q7=$(queries)
step vm2 "3.3.11 the resolver on VM 2 answers the team's names from its own copy (aa)" \
    "dig @127.0.0.1 app.team01.example" 'status: NOERROR' 'flags: qr aa rd ra;' '192\.0\.2\.84'
q8=$(queries); log "VM 1 query-log lines before and after: $q7 $q8"
if [ "$q7" = "$q8" ]; then ok "3.3.11b no query reached VM 1"; else bad "3.3.11b no query reached VM 1 ($q7 -> $q8)"; fi

echo "== Lab 3.4: failure and clean-up"
on vm1 "rndc stop; for _ in \$(seq 20); do rndc status >/dev/null 2>&1 || break; sleep 0.5; done"
step vm2 "3.4.1 VM 1 stopped: VM 2 still answers with aa" "dig @192.0.2.30 team01.example SOA +tries=1 +time=2; dig @192.0.2.10 www.team01.example +norec" \
    'connection refused|timed out|no servers could be reached' 'status: NOERROR' 'flags: qr aa ra;' '192\.0\.2\.80'
step vm2 "3.4.2 ... but a resolver following the delegation fails: only ns1 is listed" \
    "dig @192.0.2.55 lab34.team01.example; dig @192.0.2.53 team01.example NS +norec +noall +authority" \
    'status: SERVFAIL' '^team01\.example\..*NS[[:space:]]+ns1\.team01\.example\.' '!NS[[:space:]]+ns2'
step vm2 "3.4.3 VM 2's refresh fails; the copy expires in two weeks" \
    "rndc refresh team01.example; waitlog 'refresh: failure trying primary'; grep 'refresh: failure' /var/log/named.out | tail -1; e=\$(rndc zonestatus team01.example | sed -n 's/^expires: //p'); echo \"expires: \$e\"; echo days=\$(( (\$(date -d \"\$e\" +%s) - \$(date +%s)) / 86400 ))" \
    'zone team01\.example/IN: refresh: failure trying primary 192\.0\.2\.30#53 .*connection refused' '^days=1[34]$'
start_named vm1
step vm2 "3.4.4 VM 1 back: refresh succeeds, same serial on both" \
    "n=\$(grep -c 'refresh: failure' /var/log/named.out); rndc refresh team01.example; sleep 2; [ \$(grep -c 'refresh: failure' /var/log/named.out) -eq \$n ] && echo no-new-failure; rndc zonestatus team01.example | grep serial; dig @192.0.2.30 team01.example SOA +short" \
    '^no-new-failure$' 'serial: 2026102702' ' 2026102702 '
on vm2 "sed -i '/^\/\/ Module 3, Lab 3.3/,\$d' \"$L\"; cat \"$L\""
reconf vm2 "3.4.5a clean-up on VM 2: secondary zone deleted, loaded"
step vm2 "3.4.5 ... then its files removed" \
    "rm -f /var/cache/bind/db.team01.example /var/cache/bind/db.team01.example.jnl; rndc zonestatus team01.example; ls /var/cache/bind" \
    'not found' '!db\.team01'
step vm2 "3.4.6 VM 2 resolves the team zone again (no aa)" "dig @127.0.0.1 www.team01.example" \
    'status: NOERROR' 'flags: qr rd ra;' '192\.0\.2\.80'
on vm1 "sed -i '/allow-transfer { 192.0.2.10; };/d; /also-notify { 192.0.2.10; };/d' \"$L\"; cat \"$L\""
step vm1 "3.4.7 clean-up on VM 1: no transfers allowed" "named-checkconf && rndc reconfig && echo reconfigured" '^reconfigured$'
step vm2 "3.4.8 a transfer is refused again" "dig @192.0.2.30 team01.example AXFR" '; Transfer failed\.'
step vm2 "3.4.9 VM 2's configuration is the kit's (the state Modules 4-6 start from)" \
    "cmp /kit/vm2/named.conf.local $L && cmp /kit/vm2/named.conf.options /etc/bind/named.conf.options && echo same" '^same$'
step vm1 "3.4.10 VM 1's zone statement is Module 2's again" \
    "diff <(sed -n '/^zone \"teamNN.example\"/,/^};/p' /m02/zones/named.conf.local | sed 's/NN/01/g') <(sed -n '/^zone \"team01.example\"/,/^};/p' $L) && echo same" '^same$'

log "# VM 1 named.conf.local" "$(docker exec "$V1" cat "$L")" "" "# VM 2 named.conf.local" "$(docker exec "$V2" cat "$L")" ""
echo "== $pass passed, $fail failed; transcript: $OUT"
[ "$fail" -eq 0 ]
