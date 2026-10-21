#!/bin/bash
# test/run.sh: build the stack on an internal bridge (no classroom NIC) and
# check every instructor-side step of Labs 7.1-7.4 and the Module 8 DoQ demo.
# Leaves nothing running; removes its volumes and handout at the end
# (KEEP=1 keeps them for inspection).
set -uo pipefail
cd "$(dirname "$0")/.."
export COMPOSE_PROFILES=m08,test
DC=(docker compose -p dnslab-test --env-file test/test.env -f compose.yaml -f compose.test.yaml)
W=test/work            # disposable: classroom copy and handout
H=$W/handout
export CLASSROOM_DIR=./$W/classroom HANDOUT_DIR=./$H
pass=0; fail=0

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
cleanup() {
    [ "${KEEP:-0}" = 1 ] && return
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
    rm -rf "$W"
}
trap cleanup EXIT

"${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
rm -rf "$W"; mkdir -p "$H"; cp -r test/classroom "$W/classroom"
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
