#!/bin/sh
# Module 6, Lab 6.5: summarise the DNS queries in a capture, per parent
# domain, to spot tunnelling and random-subdomain floods.
# Usage: dns-signs.sh capture.pcap [SERVER]
#   SERVER: count only queries sent to this address (for example the
#   resolver, so that its own upstream queries are not counted twice).
# Needs tshark (Debian package tshark). Reads only the file it is given.
set -eu
[ $# -ge 1 ] && [ $# -le 2 ] || { echo "usage: $0 capture.pcap [SERVER]" >&2; exit 2; }
F='dns'; [ $# -eq 2 ] && F="dns && (dns.flags.response == 1 || ip.dst == $2)"
printf '%-24s %7s %7s %9s %6s  %s\n' parent queries unique max-label nxdom qtypes
tshark -r "$1" -Y "$F" -T fields -E separator='|' \
    -e dns.flags.response -e dns.flags.rcode -e dns.qry.type -e dns.qry.name 2>/dev/null |
awk -F'|' -v srv="${2:-}" '
$4 == "" { next }
{
    name = tolower($4); n = index(name, ".")
    first = substr(name, 1, n - 1); parent = substr(name, n + 1)
    if ($1 == "False" || $1 == "0") {          # a query
        q[parent]++
        if (!((parent, name) in seen)) { seen[parent, name] = 1; u[parent]++ }
        if (length(first) > maxl[parent]) maxl[parent] = length(first)
        if (!((parent, $3) in st)) { st[parent, $3] = 1; t[parent] = t[parent] " " $3 }
    } else if ($2 == 3 && !((parent, name, "nx") in seen)) {   # NXDOMAIN, once per name
        seen[parent, name, "nx"] = 1; nx[parent]++
    }
}
END {
    for (p in q)
        printf "%-24s %7d %7d %9d %6d %s\n", p, q[p], u[p], maxl[p], nx[p] + 0, t[p]
}' | sort -k2,2nr
echo "(qtypes are numbers: 1 A, 2 NS, 16 TXT, 28 AAAA)"
