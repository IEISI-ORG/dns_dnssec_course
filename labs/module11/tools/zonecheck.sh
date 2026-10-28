#!/bin/sh
# zonecheck.sh ZONE PARENT RESOLVER [WARN CRIT]
#
# Module 11, Lab 11.3: the checks a probe of one fixed server cannot make.
#   ZONE      the zone to check, e.g. teamNN.example
#   PARENT    an authoritative server of the parent zone (the registry,
#             192.0.2.53 on the slides)
#   RESOLVER  a resolver this host may use, for name server names outside
#             the zone that have no glue (192.0.2.10 on the slides)
#   WARN CRIT seconds of signature validity left below which a signature is
#             a WARNING or CRITICAL (default 345600 and 172800: 4 and 2
#             days, below BIND's default refresh point of 5 days, so a
#             running signer never warns; for the lab policy use 1200 600)
#
# It takes the server list from the parent's delegation and from the zone's
# own NS RRset, so a server added on one side only is still checked. For
# every server address (IPv4 and IPv6): an authoritative answer (aa), its
# SOA serial and the time left on the SOA signature (a server without
# signatures is CRITICAL when the parent has a DS). Then: the serials agree,
# the two NS sets agree, the glue matches the zone's addresses, a DS at the
# parent matches a DNSKEY in the zone (SHA-1, SHA-256 and SHA-384 digests)
# and that key signs the DNSKEY RRset, and the DNSKEY signature has time
# left.
#
# Exit codes follow the Monitoring Plugins guidelines: 0 OK, 1 WARNING,
# 2 CRITICAL, 3 UNKNOWN (bad arguments, a missing tool, no usable answer
# from the parent, an unreadable signature time). The first line is the
# verdict; one line per finding follows for people (the guidelines ask for
# one line only). Needs dig and dnssec-dsfromkey (Debian: bind9-dnsutils,
# bind9-utils). Read-only: it sends a few dozen queries and changes nothing.
set -u
[ $# -ge 3 ] || { echo "usage: zonecheck.sh ZONE PARENT RESOLVER [WARN CRIT]"; exit 3; }
Z=${1%.}; PARENT=$2; RES=$3; WARN=${4:-345600}; CRIT=${5:-172800}
case $WARN in ''|*[!0-9]*) echo "ZONECHECK UNKNOWN: WARN must be a number of seconds"; exit 3 ;; esac
case $CRIT in ''|*[!0-9]*) echo "ZONECHECK UNKNOWN: CRIT must be a number of seconds"; exit 3 ;; esac
[ "$WARN" -ge "$CRIT" ] || { echo "ZONECHECK UNKNOWN: WARN must not be below CRIT"; exit 3; }
command -v dig >/dev/null && command -v dnssec-dsfromkey >/dev/null \
    || { echo "ZONECHECK UNKNOWN: needs dig and dnssec-dsfromkey"; exit 3; }
D="dig +norec +time=2 +tries=1"
now=$(date -u +%s)
st=0; out=""
# rank LEVEL: CRITICAL outranks UNKNOWN, which outranks WARNING and OK
rank() { case $1 in 0) echo 0 ;; 1) echo 1 ;; 3) echo 2 ;; *) echo 3 ;; esac; }
say() {   # say LEVEL TEXT: record a finding; LEVEL 0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN
    case $1 in 0) l=OK ;; 1) l=WARNING ;; 2) l=CRITICAL ;; *) l=UNKNOWN ;; esac
    out="$out$l: $2
"
    [ "$(rank "$1")" -gt "$(rank "$st")" ] && st=$1
    return 0
}
# left SIG: seconds until an RRSIG's expiration (field 9, YYYYMMDDHHMMSS);
# prints "x" when the time cannot be read
left() {
    e=$(echo "$1" | awk '{ print $9 }')
    case $e in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;; *) echo x; return ;; esac
    t=$(date -u -d "$(echo "$e" | sed -E 's/(....)(..)(..)(..)(..)(..)/\1-\2-\3 \4:\5:\6/')" +%s 2>/dev/null) || { echo x; return; }
    echo $((t - now))
}
human() {
    s=$1
    if [ "$s" -lt 0 ]; then echo "expired $(( -s / 60 )) minutes ago"
    elif [ "$s" -ge 172800 ]; then echo "expires in $((s / 86400)) days"
    elif [ "$s" -ge 7200 ]; then echo "expires in $((s / 3600)) hours"
    else echo "expires in $((s / 60)) minutes"; fi
}
siglevel() { if [ "$1" -lt "$CRIT" ]; then echo 2; elif [ "$1" -lt "$WARN" ]; then echo 1; else echo 0; fi; }
# sigsay WHAT SIG: one finding for a signature's time left
sigsay() {
    l=$(left "$2")
    if [ "$l" = x ]; then say 3 "$1: signature time unreadable"
    else say "$(siglevel "$l")" "$1 $(human "$l")"; fi
}
is_addr() { grep -E '^([0-9]+\.){3}[0-9]+$|^[0-9a-fA-F:]+:[0-9a-fA-F:.]*$'; }

# 1. The delegation, as the parent publishes it
ref=$($D @"$PARENT" "$Z" NS 2>&1) || { echo "ZONECHECK UNKNOWN: no answer from the parent server $PARENT"; exit 3; }
echo "$ref" | grep -q 'status: NOERROR' \
    || { echo "ZONECHECK UNKNOWN: the parent server $PARENT answered $(echo "$ref" | grep -o 'status: [A-Z]*' | head -1)"; exit 3; }
pns=$(echo "$ref" | awk -v z="$Z." '$1 == z && $4 == "NS" { print tolower($5) }' | sort -u)
[ -n "$pns" ] || { echo "ZONECHECK CRITICAL: $PARENT has no delegation for $Z"; exit 2; }
glue=$(echo "$ref" | awk '$4 == "A" || $4 == "AAAA" { print tolower($1), $5 }' | sort -u)
dsraw=$($D @"$PARENT" "$Z" DS +short 2>&1) || { echo "ZONECHECK UNKNOWN: no DS answer from the parent server $PARENT"; exit 3; }
pds=$(printf '%s\n' "$dsraw" | grep -v '^;' | awk 'NF >= 4 { d = ""; for (i = 4; i <= NF; i++) d = d $i; print $1, $2, $3, toupper(d) }')

# addrs NAME: glue; else, for a name inside the zone, the zone's own first
# answering server (a resolver may still hold an old address); else the
# resolver (A and AAAA)
addrs() {
    a=$(echo "$glue" | awk -v n="$1" '$1 == n { print $2 }')
    if [ -z "$a" ] && [ -n "${first:-}" ]; then
        case $1 in *."$Z".|"$Z".) a=$(for t in A AAAA; do $D @"$first" "$1" "$t" +short 2>/dev/null; done | is_addr) ;; esac
    fi
    [ -n "$a" ] || a=$(for t in A AAAA; do dig @"$RES" +time=2 +tries=1 +short "$1" "$t" 2>/dev/null; done | is_addr)
    echo "$a"
}

# 2. The zone's own NS set, from the first listed server that answers
cns=""; first=""
for n in $pns; do
    for a in $(addrs "$n"); do
        cns=$($D @"$a" "$Z" NS +short 2>/dev/null | grep -E '^[A-Za-z0-9._-]+\.$' | tr 'A-Z' 'a-z' | sort -u)
        [ -n "$cns" ] && first=$a && break 2
    done
done
[ -n "$cns" ] || say 2 "no listed server returned the NS RRset of $Z"
if [ -n "$cns" ] && [ "$pns" != "$cns" ]; then
    say 1 "NS sets differ: parent [$(echo $pns)] zone [$(echo $cns)]"
fi

# 3. Every server named on either side: authoritative answer, serial, signature
serials=""
for n in $(printf '%s\n%s\n' "$pns" "$cns" | sort -u); do
    [ -n "$n" ] || continue
    al=$(addrs "$n")
    [ -n "$al" ] || { say 2 "$n: no address (no glue, the resolver has none)"; continue; }
    for a in $al; do
        r=$($D @"$a" "$Z" SOA +dnssec 2>&1)
        if ! echo "$r" | grep -q 'status: NOERROR'; then
            say 2 "$n ($a): $(echo "$r" | grep -Eo 'status: [A-Z]+|timed out|connection refused|no servers could be reached' | head -1)"
            continue
        fi
        echo "$r" | grep -q 'flags:[^;]* aa' || { say 2 "$n ($a): answer not authoritative (no aa): lame"; continue; }
        s=$(echo "$r" | awk -v z="$Z." '$1 == z && $4 == "SOA" { print $7 }')
        serials="$serials$s
"
        sig=$(echo "$r" | awk '$4 == "RRSIG" && $5 == "SOA"' | head -1)
        if [ -n "$sig" ]; then
            sigsay "$n ($a): serial $s, SOA signature" "$sig"
        elif [ -n "$pds" ]; then
            say 2 "$n ($a): serial $s, no signature, but the parent has a DS (validating resolvers: SERVFAIL)"
        else
            say 0 "$n ($a): serial $s, unsigned"
        fi
    done
done
ns=$(printf '%s' "$serials" | sort -u | grep -c .)
[ "$ns" -le 1 ] || say 2 "serials differ: $(printf '%s' "$serials" | sort -u | tr '\n' ' ')"

# 4. Glue against the zone's own address records
gl=$([ -n "$first" ] && echo "$glue" | while read -r gn ga; do
    [ -n "$gn" ] || continue
    za=$(for t in A AAAA; do $D @"$first" "$gn" "$t" +short 2>/dev/null; done | is_addr)
    echo "$za" | grep -qix "$ga" || echo "WARNING: glue $gn $ga at the parent, the zone has [$(echo $za)]"
done)
if [ -n "$gl" ]; then out="$out$gl
"; [ "$(rank "$st")" -lt 1 ] && st=1; fi

# 5. DS at the parent against the zone's DNSKEYs, the DS key signing the
#    DNSKEY RRset, and the DNSKEY signature
keys=""
[ -n "$first" ] && keys=$($D @"$first" "$Z" DNSKEY +dnssec 2>/dev/null)
kds=$(echo "$keys" | awk '$4 == "DNSKEY"' | dnssec-dsfromkey -a SHA-1 -a SHA-256 -a SHA-384 -f - "$Z" 2>/dev/null \
      | awk '{ d = ""; for (i = 7; i <= NF; i++) d = d $i; print $4, $5, $6, toupper(d) }')
stags=$(echo "$keys" | awk '$4 == "RRSIG" && $5 == "DNSKEY" { print $11 }')
if [ -n "$pds" ] && [ -z "$first" ]; then
    say 2 "DS at the parent, but no listed server answered for the DNSKEY RRset"
elif [ -n "$pds" ]; then
    dl=$(echo "$pds" | while read -r t al dt dg; do
        if ! echo "$kds" | grep -qx "$t $al $dt $dg"; then
            echo "CRITICAL: DS $t at the parent matches no DNSKEY in the zone (validating resolvers: SERVFAIL)"
        elif ! echo "$stags" | grep -qx "$t"; then
            echo "CRITICAL: DS $t matches a DNSKEY that does not sign the DNSKEY RRset (validating resolvers: SERVFAIL)"
        else
            echo "OK: DS $t matches a DNSKEY in the zone that signs the DNSKEY RRset"
        fi
    done)
    out="$out$dl
"
    echo "$dl" | grep -q '^CRITICAL' && st=2
elif [ -n "$kds" ]; then
    say 1 "the zone has DNSKEYs but the parent has no DS (an island of security)"
else
    say 0 "no DS and no DNSKEY: unsigned delegation"
fi
ksig=$(echo "$keys" | awk '$4 == "RRSIG" && $5 == "DNSKEY"' | head -1)
[ -z "$ksig" ] || sigsay "DNSKEY signature" "$ksig"

case $st in 0) s=OK ;; 1) s=WARNING ;; 2) s=CRITICAL ;; *) s=UNKNOWN ;; esac
echo "ZONECHECK $s: $Z, $(echo $pns | wc -w) server(s) at the parent, $(echo $cns | wc -w) in the zone"
printf '%s' "$out"
exit "$st"
