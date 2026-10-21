#!/bin/sh
# Module 6 rehearsal: runs every lab command against BIND 9.20 inside an
# unprivileged user + network namespace (no root needed). Nothing leaves
# the namespace: it has only a loopback interface, with these addresses:
#   192.0.2.53  registry server (instructor): example., RPZ feed
#   192.0.2.30  team01 authoritative VM (also the client of the resolver)
#   192.0.2.10  team01 resolver VM
#   192.0.2.31  a neighbouring team's VM (outside team01's ACLs)
#   203.0.113.7 a host on another network, in a child namespace behind a
#               veth pair (so it is neither "localhost" nor "localnets")
# Usage: rehearse.sh WORKDIR > transcript.txt
# Needs in PATH: unshare, ip, named, rndc, rndc-confgen, named-checkconf,
# named-checkzone, tsig-keygen, dig, dnsperf, tcpdump, tshark.
# Load is capped (dnsperf -Q 50) and goes only to the namespace's own servers.
# Every server is stopped on exit; the namespace disappears with it.
if [ "${M6_IN_NS:-}" != 1 ]; then
    exec env M6_IN_NS=1 unshare -rn sh "$0" "$@"
fi
set -eu
W=$1
T=$(cd "$(dirname "$0")" && pwd)
L=$(cd "$T/.." && pwd)
ip link set lo up
for a in 53 30 10 31; do ip addr add 192.0.2.$a/24 dev lo; done

sh "$T/setup.sh" "$W"
# The outside host: a child network namespace, routed via 198.51.100.0/30
unshare -n sleep 900 & OPID=$!
sleep 1
ip link add v0 type veth peer name v1
ip link set v1 netns $OPID
ip addr add 198.51.100.1/30 dev v0; ip link set v0 up
nsenter -t $OPID -n sh -c 'ip link set lo up; ip link set v1 up
    ip addr add 198.51.100.2/30 dev v1; ip addr add 203.0.113.7/32 dev lo
    ip route add default via 198.51.100.1'
ip route add 203.0.113.7/32 via 198.51.100.2
OUT=203.0.113.7
outside() { echo "\$ (from $OUT) $*"; nsenter -t $OPID -n "$@" 2>&1 || echo "(exit $?)"; }
cleanup() {
    kill $OPID 2>/dev/null || true
    for s in reg auth res; do
        [ -f "$W/$s/named.pid" ] && kill "$(cat "$W/$s/named.pid")" 2>/dev/null || true
    done
    sleep 1; echo "### servers stopped"
}
trap cleanup EXIT

REG=192.0.2.53 AUTH=192.0.2.30 RES=192.0.2.10 NB=192.0.2.31
step() { echo; echo "### $*"; }
run()  { echo "\$ $*"; "$@" 2>&1 || echo "(exit $?)"; }
rn()   { rndc -k "$W/$1/rndc.key" -s "$2" $3 ${4:-}; }
# start SERVER CONF: copy CONF to active.conf and start named on it
start() { cp "$W/$1/$2" "$W/$1/active.conf"; named -c "$W/$1/active.conf" -L "$W/$1/named.log"; sleep 1; }
# switch SERVER ADDRESS CONF: replace active.conf and "rndc reconfig", as in class
switch() { cp "$W/$1/$3" "$W/$1/active.conf"; named-checkconf "$W/$1/active.conf"
           echo "(rndc reconfig on $1: $3)"; rn $1 $2 reconfig; sleep 2; }
log()   { sed 's/^[0-9]*-[A-Za-z]*-[0-9]* [0-9:.]* //; s/@0x[0-9a-f]* //' "$@"; }
capture() { # capture FILE FILTER CMD...: tcpdump on the namespace loopback around CMD
    out=$1; filt=$2; shift 2
    tcpdump -Z root -i lo -n -U --immediate-mode -w "$out" "$filt" 2>/dev/null & tp=$!
    sleep 1; "$@" >/dev/null 2>&1 || true; sleep 1
    kill "$tp"; wait "$tp" 2>/dev/null || true
}

start reg named.conf

step "Lab 6.1: Debian defaults, seen from a neighbouring team ($NB)"
start auth default.conf; start res default.conf
run dig -b $NB @$AUTH www.team01.example A +noall +comments +answer
run dig -b $NB @$RES www.team01.example A +noall +comments
run dig -b $NB @$AUTH version.bind TXT CH +short
run dig -b $NB @$AUTH team01.example AXFR
outside dig -b $OUT @$AUTH www.team01.example A +noall +comments
outside dig -b $OUT @$RES www.team01.example A +noall +comments
step "Lab 6.1 (theory check): Debian defaults plus allow-query { any; } on the authoritative VM"
switch auth $AUTH trap.conf
outside dig -b $OUT @$AUTH www.team01.example A +noall +comments

step "Lab 6.1: Module 6 configuration"
switch auth $AUTH named.conf; switch res $RES named.conf
run dig -b $NB @$AUTH www.team01.example A +noall +comments +answer
run dig -b $NB @$AUTH www.example.org A +noall +comments
run dig -b $NB @$RES www.team01.example A +noall +comments
run dig -b $AUTH @$RES www.team01.example A +noall +comments +answer
run dig -b $NB @$AUTH version.bind TXT CH +noall +comments
rn res $RES stats; echo "--- rndc stats on the resolver:"
grep -E 'queries rejected' "$W/res/named.stats"

step "Lab 6.2: what the resolver sends upstream (cold cache)"
rn res $RES flush
capture "$W/cap/up.pcap" "udp port 53" \
    sh -c "dig -b $AUTH @$RES www.team01.example A; dig -b $AUTH @$RES mail.team01.example A; dig -b $AUTH @$RES ftp.team01.example A"
echo "--- queries the resolver sent: destination, source port, ID, type, name, client cookie, server cookie"
echo "\$ tshark -r up.pcap -Y 'ip.src==$RES && dns.flags.response==0 && (ip.dst==$AUTH || ip.dst==$REG)' -T fields -e ip.dst -e udp.srcport -e dns.id -e dns.qry.type -e dns.qry.name -e dns.opt.cookie.client -e dns.opt.cookie.server"
tshark -r "$W/cap/up.pcap" -Y "ip.src==$RES && dns.flags.response==0 && (ip.dst==$AUTH || ip.dst==$REG)" -T fields \
    -e ip.dst -e udp.srcport -e dns.id -e dns.qry.type -e dns.qry.name \
    -e dns.opt.cookie.client -e dns.opt.cookie.server 2>/dev/null
echo "--- as the authoritative server logs them (rndc querylog; V = valid server cookie, K = cookie without one)"
rn auth $AUTH querylog on; rn res $RES flush
for n in www mail; do dig -b $AUTH @$RES $n.team01.example A +short >/dev/null; done
sleep 1; rn auth $AUTH querylog off
grep 'query:' "$W/auth/named.log" | log | tail -4
echo "--- the client's side: a cookie in every answer"
run dig -b $AUTH @$RES www.team01.example A +noall +comments
CK=$(dig -b $AUTH @$RES www.team01.example A +noall +comments | sed -n 's/^; COOKIE: \([0-9a-f]*\).*/\1/p')
run dig -b $AUTH @$RES www.team01.example A +cookie=$CK +noall +comments

step "Lab 6.3: amplification, measured on the authoritative server"
run dig -b $RES @$AUTH big.team01.example TXT +qr +noall +stats
run dig -b $RES @$AUTH team01.example ANY +notcp +noall +answer +stats
echo "big.team01.example TXT" > "$W/big.txt"
step "Lab 6.3: 50 queries/s for 10 s from the resolver VM, RRL log-only"
run dnsperf -s $AUTH -a $RES -e -d "$W/big.txt" -l 10 -Q 50
grep 'rate-limit' "$W/auth/log/security.log" | log
step "Lab 6.3: the same load, RRL enforcing (log-only no)"
sed -i 's/log-only yes;/log-only no;/' "$W/auth/active.conf" "$W/auth/named.conf" "$W/auth/tsig.conf"
named-checkconf "$W/auth/active.conf"; rn auth $AUTH reconfig; sleep 1
dnsperf -s $AUTH -a $RES -e -d "$W/big.txt" -l 10 -Q 50 2>&1 | grep -v '^\[Timeout\]' | sed -n '/Statistics/,$p'
rn auth $AUTH stats
grep -E 'for rate limits' "$W/auth/named.stats"
grep 'rate-limit' "$W/auth/log/security.log" | log | tail -2
echo "--- dig while the stream is limited: without, then with a DNS cookie"
dnsperf -s $AUTH -a $RES -e -d "$W/big.txt" -l 6 -Q 50 >/dev/null 2>&1 & DP=$!
sleep 2
run dig -b $RES @$AUTH big.team01.example TXT +nocookie +ignore +tries=1 +time=1 +noall +comments
run dig -b $RES @$AUTH big.team01.example TXT +tries=3 +time=1 +noall +comments
wait $DP

step "Lab 6.4: TSIG key and transfers"
(cd "$W/auth" && umask 077 && tsig-keygen -a hmac-sha256 team01-xfr > team01-xfr.key && chmod 640 team01-xfr.key)
ls -l "$W/auth/team01-xfr.key" | cut -c1-10
sed 's/secret ".*"/secret "(hidden)"/' "$W/auth/team01-xfr.key"
(umask 077; cat "$W/auth/team01-xfr.key" > "$W/res/team01-xfr.key"); chmod 640 "$W/res/team01-xfr.key"
switch auth $AUTH tsig.conf
run dig -b $RES @$AUTH team01.example AXFR +onesoa
echo "--- the same key, read by a user who may not read it (emulated in the namespace:"
echo "    a mode-000 copy, and dig run without CAP_DAC_OVERRIDE and CAP_DAC_READ_SEARCH)"
cp "$W/res/team01-xfr.key" "$W/res/unreadable.key"; chmod 000 "$W/res/unreadable.key"
run setpriv --bounding-set -dac_override,-dac_read_search dig -b $RES @$AUTH -k "$W/res/unreadable.key" team01.example AXFR +onesoa
echo "--- as root (sudo dig in class):"
run dig -b $RES @$AUTH -k "$W/res/team01-xfr.key" team01.example AXFR +onesoa +nostats
tsig-keygen -a hmac-sha256 team01-xfr > "$W/res/wrong.key"
run dig -b $RES @$AUTH -k "$W/res/wrong.key" team01.example AXFR +onesoa
tsig-keygen -a hmac-sha256 team99-xfr > "$W/res/other.key"
run dig -b $RES @$AUTH -k "$W/res/other.key" team01.example AXFR +onesoa
echo "--- xfer-out and security log on the authoritative server:"
grep -E 'xfer-out|security' "$W/auth/log/security.log" | log | grep -v 'debug' | tail -6
step "Lab 6.4: the resolver VM as a TSIG-authenticated secondary"
switch res $RES tsig.conf; sleep 1
grep -E 'xfer-in' "$W/res/log/security.log" | log | tail -3
sed -i 's/^\(@ *SOA .*\) 1 300/\1 2 300/' "$W/auth/db.team01.example"
echo "news       A   192.0.2.83" >> "$W/auth/db.team01.example"
rn auth $AUTH reload team01.example; sleep 3
grep -E 'notify|xfer-in' "$W/res/log/security.log" | log | tail -4
run dig -b $AUTH @$RES news.team01.example A +noall +comments +answer
echo "--- remove the secondary again (Module 7 needs the resolver to resolve this zone)"
switch res $RES named.conf
run dig -b $AUTH @$RES news.team01.example A +noall +comments +answer

step "Lab 6.5: before RPZ"
echo "--- the registry's example. is signed:"
dig -b $AUTH @$REG malware.example A +dnssec +noall +answer | sed 's/\(RRSIG A 13 2 60\) .*/\1 .../'
for n in malware.example phish.example tracker.example c2.team01.example ftp.team01.example; do
    echo "\$ dig @$RES $n A +short"; dig -b $AUTH @$RES $n A +short
done
step "Lab 6.5: with the feed and the local policy zone"
switch res $RES rpz.conf; sleep 1
grep -E 'xfer-in' "$W/res/log/security.log" | log | grep feed | tail -2
run dig -b $AUTH @$RES malware.example A +noall +comments +answer
run dig -b $AUTH @$RES phish.example A +noall +answer
run dig -b $AUTH @$RES tracker.example A +noall +comments +answer
run dig -b $AUTH @$RES c2.team01.example A +noall +comments
run dig -b $AUTH @$RES ftp.team01.example A +noall +comments
echo "--- DO=1 (+dnssec): example. is signed at the registry, team01.example is not"
run dig -b $AUTH @$RES malware.example A +dnssec +noall +comments +answer
run dig -b $AUTH @$RES c2.team01.example A +dnssec +noall +comments
echo "--- rpz log on the resolver:"
grep 'rpz:' "$W/res/log/security.log" | log | grep -v 'zone' | tail -6
step "Lab 6.5: spot the pattern"
capture "$W/cap/signs.pcap" "udp port 53 and host $RES and host $AUTH" sh -c "
for i in \$(seq 30); do
    dig -b $AUTH @$RES \$(head -c 20 /dev/urandom | base32 | tr -d '=' | tr 'A-Z' 'a-z').t.team01.example TXT +short
done
for n in www mail ftp www mail; do dig -b $AUTH @$RES \$n.team01.example A +short; done"
run sh "$L/tools/dns-signs.sh" "$W/cap/signs.pcap" $RES
rn res $RES stats
grep -E 'NXDOMAIN|rpz|RPZ' "$W/res/named.stats" | head -5
