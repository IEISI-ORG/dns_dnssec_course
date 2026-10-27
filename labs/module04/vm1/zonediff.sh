#!/bin/sh
# zonediff.sh ZONE FILE SERVER [PORT]: does SERVER serve what FILE says?
# (Module 4, Lab 4.3: a migration check.)
# Fetches ZONE from SERVER by AXFR and compares it with the zone file FILE.
# Both go through named-checkzone -D -s full, which writes every record in
# one canonical form (absolute names, one record per line, sorted), so
# only real differences in the data show. Prints "same" or the differing
# lines: "<" from the file, ">" from the server. Exit 0 same, 1 different,
# 2 error. Owner names are compared as written: a difference in case only
# (WWW against www) shows as a difference, although DNS names match without
# regard to case.
# The server must allow the transfer: PowerDNS allows AXFR from 127.0.0.1
# by default (allow-axfr-ips); BIND 9.20 allows none (allow-transfer).
# Needs dig and named-checkzone (Debian: bind9-dnsutils, bind9-utils).
[ $# -ge 3 ] || { echo "usage: $0 ZONE FILE SERVER [PORT]" >&2; exit 2; }
zone=$1 file=$2 server=$3 port=${4:-53}
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
trap 'exit 2' INT TERM HUP
named-checkzone -q "$zone" "$file" || { echo "$file: named-checkzone failed" >&2; exit 2; }
dig @"$server" -p "$port" "$zone" AXFR +nocomments +nostats > "$tmp/axfr" ||
    { echo "$server port $port: no answer" >&2; exit 2; }
grep -q 'Transfer failed' "$tmp/axfr" && { echo "$server: transfer refused" >&2; exit 2; }
named-checkzone -q "$zone" "$tmp/axfr" || { echo "$server: no usable transfer" >&2; exit 2; }
named-checkzone -D -s full -o "$tmp/a" "$zone" "$file" >/dev/null 2>&1 || exit 2
named-checkzone -D -s full -o "$tmp/b" "$zone" "$tmp/axfr" >/dev/null 2>&1 || exit 2
diff "$tmp/a" "$tmp/b" > "$tmp/d"; rc=$?
case $rc in
    0) echo same ;;
    1) grep '^[<>]' "$tmp/d"; exit 1 ;;
    *) exit 2 ;;
esac
