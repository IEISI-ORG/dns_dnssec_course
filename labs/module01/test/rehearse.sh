#!/bin/bash
# rehearse.sh [TRANSCRIPT]: run the Module 1 lab steps that use the lab
# servers (Lab 1.1 offline path, Labs 1.2 and 1.3, the worked example) from a
# stand-in participant VM, and check each checkpoint.
#
# It starts the instructor stack (../../instructor, profile m01) on an
# internal Docker bridge with no route out, as test/run.sh there does, plus a
# Debian 13 container with the Module 1 client tools at 192.0.2.30: the
# team's authoritative VM, which runs no DNS server yet on Day 1. teams.conf
# delegates team01.example to it. The Lab 1.3 zones use the default labels
# (alpha..echo). Everything is removed at the end. The transcript goes to
# TRANSCRIPT, or to a new file under ${TMPDIR:-/tmp} whose name is printed.
# Needs Docker with Compose v2; about 2 minutes. The lab-hierarchy commands
# need no Internet access; the image build does.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
INS=$(cd "$here/../../instructor" && pwd)
OUT=${1:-$(mktemp "${TMPDIR:-/tmp}/m01-rehearsal.XXXXXX")}
W=$(mktemp -d)
unset M01_FAULT_LABELS
PROJ=dnslab-m01
VM=dnslab-m01-vm
export COMPOSE_PROFILES=m01 CLASSROOM_DIR=$W/classroom HANDOUT_DIR=$W/handout
DC=(docker compose -p "$PROJ" --env-file "$INS/test/test.env" -f "$INS/compose.yaml" -f "$INS/compose.test.yaml")
pass=0; fail=0

stop_lab() {
    docker rm -f "$VM" >/dev/null 2>&1
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
}
trap 'stop_lab; rm -rf "$W"' EXIT

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

stop_lab
mkdir "$W/classroom" "$W/handout"
echo "01 192.0.2.30" > "$W/classroom/teams.conf"
: > "$OUT" || exit 1
"${DC[@]}" up -d --build --quiet-pull init parent m01-root m01-child m01-resolver >/dev/null 2>&1 \
    || { "${DC[@]}" logs; exit 1; }
docker build -q --build-arg DEBIAN_TAG="${DEBIAN_TAG:-trixie-20261005-slim}" -t dnslab/m01-vm:local "$here" >/dev/null || exit 1
docker run -d --name "$VM" --network "${PROJ}_lab" --ip 192.0.2.30 dnslab/m01-vm:local >/dev/null || exit 1
for i in $(seq 30); do
    docker exec "$VM" dig @192.0.2.55 +short www.good.example A 2>/dev/null | grep -q . && break
    sleep 1
done

{ echo "# Module 1 rehearsal, $(date -u +%Y-%m-%dT%H:%MZ)"
  docker exec "$VM" sh -c 'dig -v 2>&1; tcpdump --version 2>&1 | head -1; tshark --version 2>/dev/null | head -1'
  echo; } >> "$OUT"

echo "== Lab 1.1, offline path (lab hierarchy)"
step "1.1.1 lab resolver: 13-style root NS answer, not authoritative" \
    "dig @192.0.2.55 . NS" 'flags: qr rd ra;' 'NS[[:space:]]+a\.root-servers\.test\.'
step "1.1.2 lab root: authoritative, with the server's address" \
    "dig @192.0.2.52 . NS +norec" 'flags: qr aa;' 'a\.root-servers\.test\..*A[[:space:]]+192\.0\.2\.52'
step "1.1.3a root: referral to example. with glue" \
    "dig @192.0.2.52 www.good.example +norec" 'flags: qr;' 'AUTHORITY: 1' '^example\..*NS' 'ns1\.example\..*192\.0\.2\.53'
step "1.1.3b TLD: referral to good.example with glue" \
    "dig @192.0.2.53 www.good.example +norec" 'flags: qr;' '^good\.example\..*NS' 'ns1\.good\.example\..*192\.0\.2\.54'
step "1.1.3c child: authoritative answer" \
    "dig @192.0.2.54 www.good.example +norec" 'flags: qr aa;' 'www\.good\.example\..*A[[:space:]]+192\.0\.2\.80'
step "1.1.4 +trace needs the stub to resolve server names (offline: it stops)" \
    "dig @192.0.2.52 +trace www.good.example" "couldn't get address for 'a\.root-servers\.test'"
step "1.1.5 lab root: com. does not exist here" \
    "dig @192.0.2.52 com. NS +norec" 'status: NXDOMAIN' 'flags: qr aa;'
step "1.1.6a AAAA from the child" \
    "dig @192.0.2.54 www.good.example AAAA +norec +short" '^2001:db8::80$'
step "1.1.6b ip6.arpa name built by dig -x" \
    "dig @192.0.2.52 -x 2001:db8::80 +norec +noall +question" '0\.8\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.0\.8\.b\.d\.0\.1\.0\.0\.2\.ip6\.arpa\.'
step "1.1.6c host and nslookup against the lab resolver" \
    "host www.good.example 192.0.2.55; nslookup www.good.example 192.0.2.55" \
    'www\.good\.example has address 192\.0\.2\.80' 'has IPv6 address 2001:db8::80' 'Non-authoritative answer'

echo "== Lab 1.2 (lab servers; with a capture)"
docker exec -d "$VM" sh -c 'tcpdump -i any -n -U -w /root/m01.pcap port 53 2>/root/tcpdump.err & echo $! > /root/tcpdump.pid; wait'
sleep 2
step "1.2.2a authoritative answer: aa, no ra" \
    "dig @192.0.2.54 www.good.example +norec" 'flags: qr aa;' 'status: NOERROR'
step "1.2.2b resolver answer: ra, no aa; TTL counts down" \
    "dig @192.0.2.55 www.good.example | grep -E 'flags:|^www'; t1=\$(dig @192.0.2.55 www.good.example +noall +answer | awk '{print \$2}'); sleep 3; t2=\$(dig @192.0.2.55 www.good.example +noall +answer | awk '{print \$2}'); echo \"TTL \$t1 then \$t2\"; [ \"\$t2\" -lt \"\$t1\" ] && echo countdown-ok" \
    'flags: qr rd ra;' 'countdown-ok'
step "1.2.3a NXDOMAIN, with the zone's SOA in authority" \
    "dig @192.0.2.55 nosuch.good.example" 'status: NXDOMAIN' '^good\.example\..*SOA'
step "1.2.3b NODATA: NOERROR, no answer, SOA in authority" \
    "dig @192.0.2.55 www.good.example TXT" 'status: NOERROR' 'ANSWER: 0' '^good\.example\..*SOA'
step "1.2.3c REFUSED: a server asked for a zone it does not serve" \
    "dig @192.0.2.54 www.example.com +norec" 'status: REFUSED'
step "1.2.3d SERVFAIL from the resolver (your own zone, no server yet)" \
    "dig @192.0.2.55 www.team01.example" 'status: SERVFAIL'
step "1.2.4a CNAME then the address" \
    "dig @192.0.2.55 web.good.example +noall +answer" 'web\.good\.example\..*CNAME[[:space:]]+www\.good\.example\.' 'www\.good\.example\..*A[[:space:]]+192\.0\.2\.80'
step "1.2.4b referral: empty answer, NS in authority, glue in additional" \
    "dig @192.0.2.53 www.good.example +norec" 'ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2' 'AUTHORITY SECTION' 'ADDITIONAL SECTION'
step "1.2.5a 512-octet UDP: TC set" \
    "dig @192.0.2.54 big.good.example TXT +norec +bufsize=512 +ignore" 'flags: qr aa tc;'
step "1.2.5b without +ignore dig retries over TCP" \
    "dig @192.0.2.54 big.good.example TXT +norec +bufsize=512" 'Truncated, retrying in TCP mode' '\(TCP\)' 'ANSWER: 3'
step "1.2.5c +tcp from the start" \
    "dig @192.0.2.54 www.good.example +norec +tcp" '\(TCP\)' 'flags: qr aa;'
sleep 3      # the slide: wait a few seconds before Ctrl-C
docker exec "$VM" sh -c 'kill -INT $(cat /root/tcpdump.pid)'
sleep 1
step "1.2.6 tshark reads the capture (2>/dev/null: tshark's warning about running as root): flags and RCODEs per response" \
    "tshark -r /root/m01.pcap -Y 'dns.flags.response == 1' -T fields -E header=y -e ip.src -e tcp.srcport -e dns.flags.authoritative -e dns.flags.truncated -e dns.flags.recavail -e dns.flags.rcode -e dns.qry.name 2>/dev/null" \
    '192\.0\.2\.54[[:space:]]+True[[:space:]]+True[[:space:]]+False[[:space:]]+0[[:space:]]+big\.good\.example' \
    '192\.0\.2\.55[[:space:]]+False[[:space:]]+False[[:space:]]+True[[:space:]]+3[[:space:]]+nosuch\.good\.example' \
    '192\.0\.2\.54[[:space:]]+False[[:space:]]+False[[:space:]]+False[[:space:]]+5[[:space:]]+www\.example\.com' \
    '192\.0\.2\.55[[:space:]]+False[[:space:]]+False[[:space:]]+True[[:space:]]+2[[:space:]]+www\.team01\.example' \
    '192\.0\.2\.54[[:space:]]+53[[:space:]]+True[[:space:]]+False[[:space:]]+False[[:space:]]+0[[:space:]]+big\.good\.example'

echo "== Worked example: teamNN.example on Day 1 (no server on the VM yet)"
step "W.1 resolver: SERVFAIL" \
    "dig @192.0.2.55 www.team01.example" 'status: SERVFAIL'
step "W.2 parent: delegated to the team VM" \
    "dig @192.0.2.53 www.team01.example +norec" '^team01\.example\..*NS[[:space:]]+ns1\.team01\.example\.' 'ns1\.team01\.example\..*A[[:space:]]+192\.0\.2\.30'
# from another host: the m01 resolver container has dig (bind9-dnsutils)
out=$("${DC[@]}" exec -T m01-resolver dig @192.0.2.30 www.team01.example +norec +tries=1 2>&1)
{ echo "\$ dig @192.0.2.30 www.team01.example +norec +tries=1   (from another host on the lab network)"; echo "$out"; echo; } >> "$OUT"
if grep -q 'connection refused' <<< "$out"; then echo "PASS  W.3 team VM: connection refused (no server on port 53)"; pass=$((pass + 1))
else echo "FAIL  W.3 team VM: connection refused"; fail=$((fail + 1)); sed -n '1,6s/^/        /p' <<< "$out"; fi

echo "== Lab 1.3 (one fault per zone)"
step "1.3 alpha: resolver SERVFAIL" "dig @192.0.2.55 www.alpha.example" 'status: SERVFAIL'
step "1.3 alpha: parent delegates to 192.0.2.54" "dig @192.0.2.53 www.alpha.example +norec" 'ns1\.alpha\.example\..*192\.0\.2\.54'
step "1.3 alpha: that server REFUSED (does not serve the zone)" "dig @192.0.2.54 www.alpha.example +norec" 'status: REFUSED'
step "1.3 bravo: resolver SERVFAIL" "dig @192.0.2.55 www.bravo.example" 'status: SERVFAIL'
step "1.3 bravo: parent glue 198.51.100.53" "dig @192.0.2.53 www.bravo.example +norec" 'ns1\.bravo\.example\..*198\.51\.100\.53'
step "1.3 bravo: no answer from 198.51.100.53" "dig @198.51.100.53 www.bravo.example +norec +tries=1 +timeout=2" 'no servers could be reached|timed out|unreachable'
step "1.3 charlie: resolver NOERROR" "dig @192.0.2.55 www.charlie.example" 'status: NOERROR'
step "1.3 charlie: parent glue for ns2 is 198.51.100.54" "dig @192.0.2.53 charlie.example NS +norec" 'ns2\.charlie\.example\..*A[[:space:]]+198\.51\.100\.54'
step "1.3 charlie: the zone says ns2 is 192.0.2.54" "dig @192.0.2.54 ns2.charlie.example +norec" 'flags: qr aa;' 'ns2\.charlie\.example\..*A[[:space:]]+192\.0\.2\.54'
step "1.3 delta: resolver NOERROR" "dig @192.0.2.55 www.delta.example" 'status: NOERROR'
step "1.3 delta: parent lists ns1 and ns2" "dig @192.0.2.53 delta.example NS +norec" 'NS[[:space:]]+ns2\.delta\.example\.' '!NS[[:space:]]+ns3\.delta\.example\.'
step "1.3 delta: the zone lists ns1 and ns3" "dig @192.0.2.54 delta.example NS +norec" 'flags: qr aa;' 'NS[[:space:]]+ns3\.delta\.example\.' '!NS[[:space:]]+ns2\.delta\.example\.'
step "1.3 delta: ns2 does not exist in the zone" "dig @192.0.2.54 ns2.delta.example +norec" 'status: NXDOMAIN' 'flags: qr aa;'
step "1.3 echo: NXDOMAIN from the parent (not delegated)" "dig @192.0.2.53 www.echo.example +norec" 'status: NXDOMAIN' 'flags: qr aa;'

echo "== $pass passed, $fail failed; transcript: $OUT"
[ "$fail" -eq 0 ]
