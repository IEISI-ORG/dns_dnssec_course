#!/bin/sh
# Test harness: build a work directory for the Module 8 rehearsal.
# Usage: setup.sh WORKDIR
# Needs BIND 9.20 tools (named-checkconf, rndc-confgen) and openssl in PATH.
# The lab files are taken from the directory above this script, so the
# classroom snippets (resolver/, unbound/) are tested as written, with only
# their /etc paths rewritten to WORKDIR.
set -eu
W=$1
L=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$W/auth" "$W/res" "$W/unb" "$W/cap"

sed "s#@W@#$W#g" "$L/test/auth.conf"     > "$W/auth/named.conf"
sed "s#@W@#$W#g" "$L/test/resolver.conf" > "$W/res/named.conf"
cp "$L/test/db.example" "$L/test/db.team01.example" "$W/auth/"

sed "s#/etc/bind/tls/#$W/res/#; s#/etc/bind/#$W/res/#" \
    "$L/resolver/named.conf.module08" > "$W/res/named.conf.module08"
sed 's/teamNN/team01/g; s/192\.0\.2\.10/192.0.2.10/' \
    "$L/resolver/db.resolver.arpa" > "$W/res/db.resolver.arpa"

# Unbound: harness header + the classroom file, paths rewritten
for u in forward server; do
    sed "s#/etc/unbound/team-ca.crt#$W/res/ca.crt#; s#/etc/unbound/#$W/res/#; s/teamNN/team01/g" \
        "$L/unbound/module08-$u.conf" > "$W/unb/module08-$u.conf"
    cat > "$W/unb/$u.conf" <<EOT
server:
    username: ""
    chroot: ""
    directory: "$W/unb"
    pidfile: "$W/unb/$u.pid"
    use-syslog: no
    logfile: "$W/unb/$u.log"
    verbosity: 1
    interface-automatic: no
include: "$W/unb/module08-$u.conf"
EOT
done
# the forwarder plays the client VM (192.0.2.30)
printf 'server:\n    outgoing-interface: 192.0.2.30\n' >> "$W/unb/forward.conf"
# the Unbound server finds example. at the test authoritative server
printf 'server:\n    module-config: "iterator"\n' >> "$W/unb/server.conf"
printf 'stub-zone:\n    name: "example"\n    stub-addr: 192.0.2.1\n' >> "$W/unb/server.conf"
printf 'server:\n    access-control: 0.0.0.0/0 allow\n' >> "$W/unb/server.conf"

(cd "$W/res" && sh "$L/make-certs.sh" 01 192.0.2.10 . >/dev/null 2>&1)
rndc-confgen -a -c "$W/res/rndc.key" >/dev/null 2>&1
named-checkconf "$W/auth/named.conf"
named-checkconf "$W/res/named.conf"
# the classroom options lines, syntax only (they listen on any address)
{ echo 'options {'; cat "$L/resolver/named.conf.options.module08"; echo '};'
  echo "include \"$W/res/named.conf.module08\";"; } > "$W/res/classroom-check.conf"
named-checkconf "$W/res/classroom-check.conf"
named-checkzone -q resolver.arpa "$W/res/db.resolver.arpa"
unbound-checkconf "$W/unb/forward.conf" >/dev/null
unbound-checkconf "$W/unb/server.conf" >/dev/null
echo "setup OK: $W"
