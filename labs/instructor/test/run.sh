#!/bin/bash
# test/run.sh: build the stack on an internal bridge (no classroom NIC) and
# check every instructor-side step of Labs 7.1-7.4, the Module 8 DoQ demo and
# the Module 1 lab hierarchy (lab root, child zones with their faults, lab
# resolver).
# Leaves nothing running; removes its volumes and handout at the end
# (KEEP=1 keeps them for inspection).
set -uo pipefail
cd "$(dirname "$0")/.."
export COMPOSE_PROFILES=m01,m08,test
DC=(docker compose -p dnslab-test --env-file test/test.env -f compose.yaml -f compose.test.yaml)
W=test/work            # disposable: classroom copy and handout
H=$W/handout
export CLASSROOM_DIR=./$W/classroom HANDOUT_DIR=./$H
pass=0; fail=0
# Module 1: test with fault labels other than the defaults on the slides
export M01_FAULT_LABELS=kilo,lima,mike,november,oscar
N=kilo D=lima G=mike M=november X=oscar

c() { "${DC[@]}" exec -T client "$@"; }
p() { "${DC[@]}" exec -T parent "$@"; }
ok() { echo "PASS  $1"; pass=$((pass + 1)); }
no() { echo "FAIL  $1"; fail=$((fail + 1)); }
# on failure, show the first lines the command printed
check() {
    local name=$1 out; shift
    if out=$("$@" 2>&1); then ok "$name"; else no "$name"; sed -n '1,6s/^/        /p' <<< "$out"; fi
}
delv_() { c delv @192.0.2.53 -a /handout/trust-anchors.conf +root=example "$@" 2>&1; }
wait_for() { local i; for i in $(seq "$1"); do "${@:2}" >/dev/null 2>&1 && return 0; sleep 2; done; return 1; }
# through the test resolver (192.0.2.10), as a team's Lab 7.3 resolver sees it
rq() { c dig @192.0.2.10 +dnssec "$@"; }
validated() { rq "$1" A | grep -Eq 'status: NOERROR' && rq "$1" A | grep -Eq 'flags: qr rd ra ad;'; }
insecure() { local o; o=$(rq "$1" A); grep -q 'status: NOERROR' <<< "$o" && ! grep -q ' ad;' <<< "$o"; }
# Module 1: one iterative query from the client; grep its output
d() { c dig +norec "$@" 2>&1; }
has() { grep -Eq "$1" <<< "$2"; }
m01_root() { local o; o=$(d @192.0.2.52 . NS)
    has 'flags: qr aa;' "$o" && has '^a\.root-servers\.test\..*A.*192\.0\.2\.52' "$o"; }
m01_root_referral() { local o; o=$(d @192.0.2.52 www.good.example A)
    has 'flags: qr;' "$o" && has '^example\..*NS.*ns1\.example\.' "$o" && has '^ns1\.example\..*A.*192\.0\.2\.53' "$o"; }
m01_parent_referral() { local o; o=$(d @192.0.2.53 www.good.example A)
    has 'flags: qr;' "$o" && has '^good\.example\..*NS.*ns1\.good\.example\.' "$o" && has '^ns1\.good\.example\..*A.*192\.0\.2\.54' "$o"; }
m01_child() { local o; o=$(d @192.0.2.54 www.good.example A)
    has 'flags: qr aa;' "$o" && has '^www\.good\.example\..*A.*192\.0\.2\.80' "$o"; }
m01_resolver() { local o; o=$(c dig @192.0.2.55 www.good.example A)
    has 'status: NOERROR' "$o" && has 'flags: qr rd ra;' "$o" && has '192\.0\.2\.80' "$o"; }
m01_notserved() { has 'status: REFUSED' "$(d @192.0.2.54 www.$N.example A)" \
    && has 'status: SERVFAIL' "$(c dig @192.0.2.55 www.$N.example A)"; }
m01_dead() { has "^ns1\\.$D\\.example\\..*A.*198\\.51\\.100\\.53" "$(d @192.0.2.53 www.$D.example A)" \
    && has 'status: SERVFAIL' "$(c dig @192.0.2.55 www.$D.example A)"; }
m01_glue() { has "^ns2\\.$G\\.example\\..*A.*198\\.51\\.100\\.54" "$(d @192.0.2.53 $G.example NS)" \
    && has "^ns2\\.$G\\.example\\..*A.*192\\.0\\.2\\.54" "$(d @192.0.2.54 ns2.$G.example A)" \
    && has 'status: NOERROR' "$(c dig @192.0.2.55 www.$G.example A)"; }
m01_nsset() { local p k; p=$(d @192.0.2.53 $M.example NS); k=$(d @192.0.2.54 $M.example NS)
    has "NS.*ns2\\.$M\\.example\\." "$p" && ! has "NS.*ns3\\.$M\\.example\\." "$p" \
    && has "NS.*ns3\\.$M\\.example\\." "$k" && ! has "NS.*ns2\\.$M\\.example\\." "$k" \
    && has 'status: NOERROR' "$(c dig @192.0.2.55 www.$M.example A)"; }
m01_nodeleg() { has 'status: NXDOMAIN' "$(d @192.0.2.53 www.$X.example A)" \
    && has 'status: NXDOMAIN' "$(c dig @192.0.2.55 www.$X.example A)"; }
m01_defaults_gone() { ! has 'alpha|bravo|charlie|delta' "$(p cat /var/lib/lab/db.example)"; }
# make-example-zone into a scratch directory inside the parent, with
# overrides: m01_mez VAR=value ... ; prints the zone file (or the error)
m01_mez() { p env "$@" LAB_STATE=/tmp/mez bash -c 'rm -rf /tmp/mez && mkdir -p /tmp/mez/ds && /opt/lab/bin/make-example-zone && cat /tmp/mez/db.example' 2>&1; }
m01_truncated() { has 'flags: qr aa tc;' "$(d @192.0.2.54 big.good.example TXT +bufsize=512 +ignore)" \
    && has '\(TCP\)' "$(d @192.0.2.54 big.good.example TXT +bufsize=512)"; }
m01_refused() { has 'status: REFUSED' "$(d @192.0.2.54 www.example.com A)"; }
cleanup() {
    [ "${KEEP:-0}" = 1 ] && return
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
    rm -rf "$W"
}
trap cleanup EXIT

"${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
rm -rf "$W"; mkdir -p "$H"; cp -r test/classroom "$W/classroom"

echo "== empty addresses: refused with the profile on, ignored with it off"
"${DC[@]}" build -q >/dev/null 2>&1 || { echo "build failed"; exit 1; }
for v in M01_ROOT_ADDR:m01-root M01_CHILD_ADDR:m01-child M01_RESOLVER_ADDR:m01-resolver DOQ_ADDR:doq; do
    out=$(env "${v%%:*}=" "${DC[@]}" create --no-build "${v##*:}" 2>&1)
    check "empty ${v%%:*} with its profile on: ${v##*:} not created" \
        bash -c 'grep -q "set-$2-in-.env" <<< "$1" && [ -z "$(docker ps -aq --filter label=com.docker.compose.project=dnslab-test --filter label=com.docker.compose.service=$3)" ]' _ "$out" "${v%%:*}" "${v##*:}"
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
done
out=$(env COMPOSE_PROFILES= M01_ROOT_ADDR= M01_CHILD_ADDR= M01_RESOLVER_ADDR= DOQ_ADDR= "${DC[@]}" create --no-build 2>&1)
check "all of them empty with the profiles off: init and parent created" \
    bash -c '[ "$(docker ps -aq --filter label=com.docker.compose.project=dnslab-test | wc -l)" -eq 2 ]'
"${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
"${DC[@]}" up -d --build --quiet-pull >/dev/null 2>&1 || { "${DC[@]}" logs init parent; exit 1; }
wait_for 60 test -s "$H/trust-anchors.conf" || { "${DC[@]}" logs parent; exit 1; }

echo "== versions"
p named -v; "${DC[@]}" exec -T doq knotd -V | head -n 1; c kdig -V
echo "== parent"
check "parent answers authoritatively for example." \
    bash -c "${DC[*]} exec -T client dig @192.0.2.53 +norec example SOA | grep -q 'flags: qr aa'"
check "handout DS matches the KSK in example." \
    bash -c "diff <(${DC[*]} exec -T client dig @192.0.2.53 +norec +noall +answer example DNSKEY | ${DC[*]} exec -T parent dnssec-dsfromkey -2 -f - example) $H/example.ds"
check "delv validates ns1.example with the handout trust anchor" validated ns1.example
out=$(delv_ www.expired.example A)
check "expired.example fails: RRSIG has expired" grep -q 'RRSIG has expired' <<< "$out"
out=$(delv_ www.wrongds.example A)
check "wrongds.example fails validation" bash -c '! grep -q "fully validated" <<< "$1" && grep -qi "fail\|no valid" <<< "$1"' _ "$out"
check "resolver: example. names get the AD flag" wait_for 15 validated ns1.example
out=$(rq www.expired.example A)
check "resolver: expired.example SERVFAIL with EDE 7 (Signature Expired)" bash -c 'grep -q "status: SERVFAIL" <<< "$1" && grep -q "EDE: 7" <<< "$1"' _ "$out"
check "resolver: expired.example answers with +cd" bash -c "${DC[*]} exec -T client dig @192.0.2.10 +cd +short www.expired.example A | grep -qx 192.0.2.80"
out=$(rq www.wrongds.example A)
check "resolver: wrongds.example SERVFAIL" grep -q 'status: SERVFAIL' <<< "$out"
check "example. delegates teamNN and manualNN to the team address" \
    bash -c "${DC[*]} exec -T client dig @192.0.2.53 +norec manual01.example NS | grep -q 'ns1.manual01.example.*192.0.2.101\|192.0.2.101'"

echo "== Module 1 lab hierarchy"
check "m01 root: . NS is authoritative and carries the root server's address" m01_root
check "m01 root refers www.good.example to the parent (example. NS, glue 192.0.2.53)" m01_root_referral
check "m01 parent refers www.good.example to the child (glue 192.0.2.54)" m01_parent_referral
check "m01 child answers www.good.example authoritatively" m01_child
check "m01 lab resolver answers www.good.example (ra, no aa)" m01_resolver
check "m01 $N (not served): child REFUSED, resolver SERVFAIL" m01_notserved
check "m01 $D (no server): glue 198.51.100.53, resolver SERVFAIL" m01_dead
check "m01 $G (stale glue): parent glue for ns2 differs from the zone; still resolves" m01_glue
check "m01 $M (NS sets differ): parent {ns1,ns2}, zone {ns1,ns3}; still resolves" m01_nsset
check "m01 $X (not delegated): NXDOMAIN from the parent and the resolver" m01_nodeleg
check "m01 custom labels: none of the default names in example." m01_defaults_gone
out=$(m01_mez M01_CHILD_ADDR=)
check "m01 other days: empty M01_CHILD_ADDR gives no Module 1 delegations" \
    bash -c '! grep -Eq "^(good|kilo|lima|mike|november) " <<< "$1" && grep -q "^team01 " <<< "$1"' _ "$out"
out=$(m01_mez M01_CHILD_ADDR=192.0.2.300)
check "m01 bad M01_CHILD_ADDR rejected" grep -q 'bad M01_CHILD_ADDR' <<< "$out"
out=$(m01_mez M01_FAULT_LABELS=alpha,bravo,team01,delta,echo)
check "m01 reserved fault label rejected" grep -q 'bad, reserved or repeated label: team01' <<< "$out"
out=$(m01_mez M01_FAULT_LABELS=alpha,bravo,charlie,delta)
check "m01 wrong number of fault labels rejected" grep -q 'need five' <<< "$out"
out=$(m01_mez M01_CHILD_ADDR=192.0.2.101)
check "m01 warns when a team VM uses an instructor address" grep -q 'warning: team 01 uses M01_CHILD_ADDR' <<< "$out"
check "m01 live db.example untouched by the scratch builds" m01_defaults_gone
check "m01 big.good.example: TC at 512 octets, full answer over TCP" m01_truncated
check "m01 child refuses a zone it does not serve" m01_refused

echo "== teams.conf edit + publish-ds --refresh"
check "team02 not delegated yet" bash -c "! ${DC[*]} exec -T client dig @192.0.2.53 +norec team02.example NS | grep -q 192.0.2.102"
# replace the file the way an editor does (new inode), then refresh
{ cat "$W/classroom/teams.conf"; echo "02 192.0.2.102"; } > "$W/classroom/teams.new"
mv "$W/classroom/teams.new" "$W/classroom/teams.conf"
p publish-ds --refresh >/dev/null && ok "publish-ds --refresh" || no "publish-ds --refresh"
check "team02 delegated after --refresh" wait_for 10 bash -c "${DC[*]} exec -T client dig @192.0.2.53 +norec team02.example NS | grep -q 192.0.2.102"

echo "== Lab 7.1 path: DS from records on stdin"
check "team01 is insecure before any DS" wait_for 15 insecure www.team01.example
c dig @192.0.2.101 +norec +noall +answer team01.example DNSKEY | p publish-ds team01.example \
    && ok "publish-ds from DNSKEY on stdin" || no "publish-ds from DNSKEY on stdin"
check "www.team01.example validates" wait_for 10 validated www.team01.example
c dig @192.0.2.101 +norec +noall +answer team01.example DNSKEY | p dnssec-dsfromkey -2 -f - team01.example \
    | sed 's/ IN DS / 3600 IN DS /' | p publish-ds team01.example | grep -q unchanged \
    && ok "dsset-style input with a TTL: DS unchanged" || no "dsset-style input with a TTL: DS unchanged"
# a dsset- file as dnssec-signzone writes it: digest split after 56 characters
c dig @192.0.2.101 +norec +noall +answer team01.example DNSKEY | p dnssec-dsfromkey -2 -f - team01.example \
    | awk '{ d = $NF; $NF = substr(d, 1, 56) " " substr(d, 57); print }' \
    | p publish-ds team01.example | grep -q unchanged \
    && ok "dsset- file with a split digest: DS unchanged" || no "dsset- file with a split digest: DS unchanged"
echo "team01.example. IN DS 12345 13 2 ABCD" | p publish-ds team01.example >/dev/null 2>&1 \
    && no "truncated DS rejected" || ok "truncated DS rejected"
check "DS list unchanged after the rejected input" bash -c "${DC[*]} exec -T parent publish-ds --list | grep -c 'team01.example. IN DS' | grep -qx 1"
check "www.team01.example still validates" validated www.team01.example
check "rejects a zone that is not teamNN/manualNN" bash -c "! ${DC[*]} exec -T parent publish-ds example --remove"
check "rejects a team that is not in teams.conf" bash -c "! ${DC[*]} exec -T parent publish-ds team07.example --cds"

echo "== Lab 7.2 path: DS from CDS"
echo "      (waiting for team01's CDS; the lab policy takes about 2 minutes)"
check "team01 publishes CDS" wait_for 120 bash -c "${DC[*]} exec -T client dig @192.0.2.101 +norec +short team01.example CDS | grep -Eq '^[0-9]+ 13 2 [0-9A-F]+'"
p publish-ds team01.example --cds 192.0.2.101 | grep -q unchanged \
    && ok "CDS checked by dnssec-cds against the current DS: unchanged" || no "CDS checked by dnssec-cds: unchanged"
p publish-ds team01.example --remove >/dev/null && ok "--remove" || no "--remove"
check "team01 insecure again after --remove" wait_for 10 insecure www.team01.example
out=$(p publish-ds team01.example --cds 2>&1)
check "CDS bootstrap (address from teams.conf) warns to confirm the key tag" grep -q 'confirm these key tags' <<< "$out"
check "www.team01.example validates after the CDS bootstrap" wait_for 10 validated www.team01.example

echo "== Module 8 DoQ demo"
out=$(c kdig @192.0.2.40 +quic +tls-ca=/handout/doq.crt +tls-hostname=doq.example www.doq.example A 2>&1)
check "kdig +quic gets a QUIC session" grep -q 'QUIC session' <<< "$out"
check "kdig +quic answer 192.0.2.82" grep -q '192.0.2.82' <<< "$out"
check "example. delegates doq.example to the Knot address" \
    bash -c "${DC[*]} exec -T client dig @192.0.2.53 +norec doq.example NS | grep -q '192.0.2.40'"

echo "== restart: keys kept, expired.example re-signed"
ds_before=$(cat "$H/example.ds")
sig_before=$(c dig @192.0.2.53 +norec +dnssec +short www.expired.example A | awk '$1 == "A" {print $6}')
sleep 2
"${DC[@]}" down >/dev/null 2>&1
"${DC[@]}" up -d >/dev/null 2>&1
wait_for 60 bash -c "${DC[*]} exec -T client dig @192.0.2.53 +norec +short example SOA | grep -q ."
sig_after=$(c dig @192.0.2.53 +norec +dnssec +short www.expired.example A | awk '$1 == "A" {print $6}')
check "example. DS unchanged after down/up" bash -c '[ "$1" = "$(cat "$2")" ]' _ "$ds_before" "$H/example.ds"
check "expired.example re-signed on up (inception $sig_before -> $sig_after)" bash -c '[ -n "$1" ] && [ "$1" != "$2" ]' _ "$sig_after" "$sig_before"
check "team01 DS kept after down/up" wait_for 15 validated www.team01.example
wait_for 30 validated ns1.example
check "m01 lab resolver answers again after down/up" wait_for 15 m01_resolver
check "expired.example still fails after restart" wait_for 15 bash -c "${DC[*]} exec -T client delv @192.0.2.53 -a /handout/trust-anchors.conf +root=example www.expired.example A 2>&1 | grep -q 'RRSIG has expired'"

echo "== team removed from teams.conf while its DS is published"
grep -v '^01 ' "$W/classroom/teams.conf" > "$W/classroom/teams.new"
mv "$W/classroom/teams.new" "$W/classroom/teams.conf"
out=$(p publish-ds --refresh 2>&1)
check "--refresh succeeds and warns about the orphan DS" grep -q 'team 01 is not in' <<< "$out"
check "init runs while the parent is up" "${DC[@]}" run --rm --no-deps init
check "--refresh still works after that" bash -c "${DC[*]} exec -T parent publish-ds --refresh"
"${DC[@]}" restart parent >/dev/null 2>&1
check "parent restarts and serves example. with the orphan DS on disk" wait_for 30 bash -c "${DC[*]} exec -T client dig @192.0.2.53 +norec example SOA | grep -q 'status: NOERROR'"
check "team01 no longer delegated" bash -c "! ${DC[*]} exec -T client dig @192.0.2.53 +norec team01.example NS | grep -q 192.0.2.101"
check "--remove works for a team not in teams.conf" bash -c "${DC[*]} exec -T parent publish-ds team01.example --remove"
check "orphan DS file gone" bash -c "! ${DC[*]} exec -T parent publish-ds --list | grep -q team01"

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
