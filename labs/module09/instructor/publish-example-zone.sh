#!/bin/bash
# publish-example-zone.sh: copy the .example zone that Namingo's zone writer
# (automation/write-zone.php, with 'dns_reload' => false) generated into the
# file the instructor's BIND loads for example. (the Module 7 parent, signed
# inline by dnssec-policy), set the TTL to the lab value and reload.
# Tested 2026-10-21: Namingo v1.0.34 writer + BIND 9.20.29.
#   SRC=/var/lib/bind/example.zone DST=/var/lib/bind/db.example TTL=60 ./publish-example-zone.sh
# Why the TTL edit: the writer always writes "$TTL 3600"; the lab policy has
# max-zone-ttl 300 (named refuses the zone otherwise: "TTL 3600 exceeds
# configured max-zone-ttl"), and the Module 7 child policies assume a parent
# DS TTL of 60 seconds (parent-ds-ttl 60).
set -euo pipefail
SRC=${SRC:-/var/lib/bind/example.zone}
DST=${DST:-/var/lib/bind/db.example}
TTL=${TTL:-60}
RNDC=${RNDC:-rndc}
tmp=$(mktemp "$DST.XXXXXX")
sed "s/^\$TTL 3600\$/\$TTL $TTL/" "$SRC" > "$tmp"
named-checkzone -q example "$tmp"
chmod 0644 "$tmp"
mv "$tmp" "$DST"
$RNDC reload example
