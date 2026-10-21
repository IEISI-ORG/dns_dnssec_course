#!/bin/sh
# Module 8 rehearsal: runs every lab command against BIND, Unbound and Knot
# inside an unprivileged user + network namespace (no root needed), with the
# lab addresses on the namespace's loopback:
#   192.0.2.1  authoritative server (team01.example, example.)
#   192.0.2.10 team resolver, BIND 9.20: Do53, DoT 853, DoH 443, DDR
#   192.0.2.20 the same service on Unbound (reference config)
#   192.0.2.30 the client VM (dig/kdig source address; Unbound forwarder)
#   192.0.2.40 Knot DNS with DoQ (instructor demo)
# Usage: rehearse.sh WORKDIR > transcript.txt
# Needs in PATH: unshare, ip, named, rndc-confgen, named-checkconf,
# named-checkzone, unbound, unbound-checkconf, dig, kdig, openssl, curl,
# tcpdump, tshark, python3; knotd/knotc for the DoQ demo (skipped if absent).
# Every server is stopped on exit; the namespace disappears with it.
if [ "${M8_IN_NS:-}" != 1 ]; then
    exec env M8_IN_NS=1 unshare -rn sh "$0" "$@"
fi
set -eu
W=$1
T=$(cd "$(dirname "$0")" && pwd)
ip link set lo up
for a in 1 2 3 10 20 30 40; do ip addr add 192.0.2.$a/32 dev lo; done

sh "$T/setup.sh" "$W"
PIDS=""
KDIR=""
cleanup() {
    for p in $PIDS; do kill "$p" 2>/dev/null || true; done
    for f in "$W"/auth/named.pid "$W"/res/named.pid "$W"/unb/*.pid "$W"/xot/*.pid; do
        [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null || true
    done
    sleep 1
    [ -n "$KDIR" ] && rm -rf "$KDIR"
    echo "### servers stopped"
}
trap cleanup EXIT

named -c "$W/auth/named.conf" -L "$W/auth/named.log"
named -c "$W/res/named.conf" -L "$W/res/named.log"
unbound -c "$W/unb/server.conf" 2>/dev/null
unbound -c "$W/unb/forward.conf" 2>/dev/null
sleep 2

step() { echo; echo "### $*"; }
run()  { echo "\$ $*"; "$@" 2>&1 || echo "(exit $?)"; }
# capture FILE FILTER CMD...: tcpdump on the namespace loopback around CMD
capture() {
    out=$1; filt=$2; shift 2
    tcpdump -Z root -i lo -n -U -w "$out" "$filt" 2>/dev/null & tp=$!
    sleep 2; "$@" >/dev/null 2>&1 || true; sleep 1
    kill "$tp"; wait "$tp" 2>/dev/null || true
}
show() { tshark -r "$1" -T fields -e ip.src -e ip.dst -e _ws.col.Protocol -e _ws.col.Info 2>/dev/null; }
flush() { rndc -k "$W/res/rndc.key" -s 127.0.0.1 flush; }

C=192.0.2.30
R=192.0.2.10
Q=secret-project.team01.example
cd "$W/res"
STRICT="+tls-ca=ca.crt +tls-hostname=resolver.team01.example"

step "Lab 8.1: plaintext DNS on the wire"
flush
capture "$W/cap/plain.pcap" "port 53 or port 853 or port 443" dig -b $C @$R $Q A
show "$W/cap/plain.pcap"

step "Lab 8.2: DoT, strict profile (team CA + name)"
flush
capture "$W/cap/dot.pcap" "port 53 or port 853 or port 443" dig -b $C @$R $STRICT $Q A
show "$W/cap/dot.pcap"
run dig -b $C @$R $STRICT $Q A +noall +answer +stats
echo "--- SNI and ALPN in the ClientHello:"
tshark -r "$W/cap/dot.pcap" -Y 'tls.handshake.type==1' -T fields \
    -e tls.handshake.extensions_server_name -e tls.handshake.extensions_alpn_str 2>/dev/null
run kdig -b $C @$R $STRICT $Q A
run dig -b $C @$R +tls-ca=ca.crt +tls-hostname=wrong.team01.example $Q A
run kdig -b $C @$R +tls-ca=ca.crt +tls-hostname=wrong.team01.example $Q A
run dig -b $C @$R +tls $Q A +short
run dig -b $C @$R +tls-ca +tls-hostname=resolver.team01.example $Q A +short

step "Lab 8.2: DoH"
run dig -b $C @$R +https $STRICT www.team01.example A +noall +answer +stats
run dig -b $C @$R +https-get $STRICT www.team01.example A +noall +answer +stats
run kdig -b $C @$R +https $STRICT www.team01.example A
B64=$(python3 -I -c 'import base64,struct
n=b"".join(bytes([len(l)])+l for l in b"www.team01.example".split(b"."))+b"\0"
m=struct.pack(">HHHHHH",0,0x0100,1,0,0,0)+n+struct.pack(">HH",1,1)
print(base64.urlsafe_b64encode(m).decode().rstrip("="))')
echo "\$ curl --cacert ca.crt --resolve resolver.team01.example:443:$R -H 'accept: application/dns-message' 'https://resolver.team01.example/dns-query?dns=$B64' -o answer.bin -D -"
curl -s --cacert ca.crt --resolve resolver.team01.example:443:$R \
    -H 'accept: application/dns-message' \
    "https://resolver.team01.example/dns-query?dns=$B64" -o "$W/cap/answer.bin" -D -
od -An -tx1 "$W/cap/answer.bin"
echo "\$ curl ... -H 'accept: application/dns-json' 'https://resolver.team01.example/dns-query?name=www.team01.example&type=A' -D -"
curl -s --cacert ca.crt --resolve resolver.team01.example:443:$R \
    -H 'accept: application/dns-json' \
    "https://resolver.team01.example/dns-query?name=www.team01.example&type=A" -o /dev/null -D -

step "Lab 8.3: Unbound forwarder on the client, DoT upstream"
flush
capture "$W/cap/fwd.pcap" "port 53 or port 853 or port 5300" dig @127.0.0.1 -p 5300 www.team01.example A
run dig @127.0.0.1 -p 5300 www.team01.example A +short
tshark -r "$W/cap/fwd.pcap" -T fields -e ip.src -e ip.dst -e tcp.dstport -e udp.dstport \
    -e tls.record.length -e _ws.col.Info 2>/dev/null
echo "--- forward-addr with the wrong name:"
kill "$(cat "$W/unb/forward.pid")"; sleep 1
sed -i 's/#resolver.team01.example/#wrong.team01.example/' "$W/unb/module08-forward.conf"
unbound -c "$W/unb/forward.conf" 2>/dev/null; sleep 1
run dig @127.0.0.1 -p 5300 www2.team01.example A +noall +comments
grep -E 'ssl handshake' "$W/unb/forward.log" | sed 's/^\[[0-9]*\] //' | tail -3

step "Lab 8.4: Discovery of Designated Resolvers"
run dig -b $C @$R _dns.resolver.arpa SVCB +noall +answer +additional
run dig -b $C @$R resolver.team01.example A +short
run dig -b $C @$R _dns.resolver.arpa SVCB +noall +answer +additional
echo "\$ openssl s_client -connect $R:853 -CAfile ca.crt -verify_ip $R -alpn dot -brief </dev/null"
openssl s_client -connect $R:853 -CAfile ca.crt -verify_ip $R -alpn dot -brief </dev/null 2>&1 | grep -E 'Protocol|Peer cert|Verification|group'
openssl s_client -connect $R:853 -CAfile ca.crt -alpn dot </dev/null 2>&1 | grep 'ALPN'
echo "\$ openssl s_client -connect $R:853 -CAfile ca.crt -verify_ip 192.0.2.99 -verify_return_error -brief </dev/null"
openssl s_client -connect $R:853 -CAfile ca.crt -verify_ip 192.0.2.99 -verify_return_error -brief </dev/null 2>&1 | grep -E 'verify error|Verification' || true
echo "\$ openssl x509 -in resolver.crt -noout -ext subjectAltName"
openssl x509 -in resolver.crt -noout -ext subjectAltName

step "Lab 8.5: padding"
for q in www.team01.example $Q; do
    for p in +nopadding +padding; do
        echo "\$ kdig $STRICT $p $q"
        kdig -b $C @$R $STRICT $p $q A 2>&1 | grep -E 'PADDING|Received'
    done
done
for p in "" "+padding=128"; do
    capture "$W/cap/pad$p.pcap" "port 853" sh -c "dig -b $C @$R $STRICT $p www.team01.example A; dig -b $C @$R $STRICT $p $Q A"
    echo "--- TLS record lengths, dig ${p:-(no padding)}: www then $Q"
    tshark -r "$W/cap/pad$p.pcap" -Y 'tls' -T fields -e tcp.stream -e ip.src -e tls.record.length 2>/dev/null
done
run dig -b $C @$R +padding=128 www.team01.example A +noall +comments +stats
run dig -b $C @$R +tcp +padding=128 www.team01.example A +noall +comments +stats
run dig -b $C @192.0.2.20 +tcp +padding=128 www.team01.example A +noall +comments +stats
run dig -b $C @192.0.2.20 +tls +padding=128 www.team01.example A +noall +comments +stats

step "Reference: the same service on Unbound (192.0.2.20)"
run kdig -b $C @192.0.2.20 +tls $STRICT www.team01.example A
run kdig -b $C @192.0.2.20 +https $STRICT www.team01.example A

step "Demo: zone transfer over TLS (XoT, RFC 9103), BIND 9.20"
mkdir -p "$W/xot"
for x in primary secondary; do sed "s#@W@#$W#g" "$T/xot-$x.conf" > "$W/xot/$x.conf"; named-checkconf "$W/xot/$x.conf"; done
named -c "$W/xot/primary.conf" -L "$W/xot/primary.log"; sleep 1
capture "$W/cap/xot.pcap" "host 192.0.2.2" sh -c "named -c $W/xot/secondary.conf -L $W/xot/secondary.log; sleep 3"
grep 'xfer-in' "$W/xot/secondary.log" | sed 's/0x[0-9a-f]*: //'
echo "--- packets to and from the primary, by port and protocol:"
tshark -r "$W/cap/xot.pcap" -T fields -e tcp.dstport -e udp.dstport -e _ws.col.Protocol 2>/dev/null | sort | uniq -c

if command -v knotd >/dev/null 2>&1; then
    step "Demo: DoQ on Knot DNS (authoritative, 192.0.2.40)"
    KDIR=$(mktemp -d)   # short path: a UNIX socket path is limited to 108 bytes
    mkdir -p "$W/knot"
    sed "s#@W@#$W#g; s#@K@#$KDIR#g" "$T/knot.conf" > "$W/knot/knot.conf"
    knotc -c "$W/knot/knot.conf" conf-check
    knotd -c "$W/knot/knot.conf" >/dev/null 2>&1 & PIDS="$PIDS $!"
    sleep 2
    run kdig -b $C @192.0.2.40 +quic $STRICT www.team01.example A
fi
