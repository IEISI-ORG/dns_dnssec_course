#!/bin/sh
# Module 11, Lab 11.4 (instructor only): set or undo a fault on a team's VM 1.
# Run it as root on VM 1 without copying it there (root login or
# NOPASSWD sudo for the instructor: with stdin redirected, sudo cannot
# prompt):
#   ssh <VM 1> 'sudo sh -s -- set 1 NN [listen|acl]' < faults.sh
#   ssh <VM 1> 'sudo sh -s -- set 2 NN ADDRESS'      < faults.sh
#   ssh <VM 1> 'sudo sh -s -- undo 1|2 NN'           < faults.sh   (rescue)
#   ssh <VM 1> 'sudo sh -s -- clean NN'              < faults.sh   (after the drill)
# Fault 1, variant listen (default): named answers on loopback only;
# variant acl: named answers everyone REFUSED except loopback. Fault 2: a
# second name server at ADDRESS is added to the zone's NS set: give VM 2's
# address (a resolver: REFUSED) or an unused address (time-outs). It prints
# only "fault set", "fault undone" or "cleaned", and a repeated "set" of a
# fault that is in place prints "fault set" again. The answers are in
# README.md next to this file. Fault 3 (a wrong DS at the registry) is set
# on the instructor server with ds-fault.sh. The original files are kept in
# /var/backups/m11 (root only) for "undo"; "clean" deletes them.
set -eu
usage() { echo "usage: sh -s -- set 1 NN [listen|acl] | set 2 NN ADDRESS | undo 1|2 NN | clean NN" >&2; exit 2; }
[ $# -ge 2 ] || usage
act=$1
if [ "$act" = clean ]; then n=0; NN=$2; else [ $# -ge 3 ] || usage; n=$2; NN=$3; fi
case $NN in [0-9][0-9]) ;; *) echo "NN must be two digits" >&2; exit 2 ;; esac
Z=team$NN.example
O=/etc/bind/named.conf.options
B=/var/backups/m11
F=$(named-checkconf -p | awk -v z="\"$Z\"" '$1 == "zone" && $2 == z { f = 1 } f && $1 == "file" { gsub(/[";]/, "", $2); print $2; exit }')
[ -n "$F" ] && [ -f "$F" ] || { echo "no zone file for $Z in named.conf" >&2; exit 1; }
serial() { awk '/; serial/ { print $1; exit }' "$1"; }
# reconf: check the configuration and reconfigure; put the saved options
# back if the check fails
reconf() {
    named-checkconf || { [ ! -f "$B/options.1" ] || cp -p "$B/options.1" "$O"; echo "configuration check failed; options restored" >&2; exit 1; }
    rndc reconfig >/dev/null
}

case "$act $n" in
"set 1")
    v=${4:-listen}
    if grep -q '^    listen-on { 127.0.0.1; };$' "$O" || grep -q '^    allow-query { 127.0.0.1; };  // m11$' "$O"; then
        echo "fault set"; exit 0
    fi
    mkdir -p "$B"; chmod 700 "$B"
    case $v in
    listen)
        grep -q 'listen-on' "$O" && { echo "cannot set this one on this VM; choose another" >&2; exit 1; }
        cp -p "$O" "$B/options.1"
        sed -i 's/^options {/options {\n    listen-on { 127.0.0.1; };\n    listen-on-v6 { ::1; };/' "$O"
        grep -q '^    listen-on { 127.0.0.1; };$' "$O" || { cp -p "$B/options.1" "$O"; echo "edit failed" >&2; exit 1; } ;;
    acl)
        grep -q '^ *allow-query { any; };' "$O" || { echo "cannot set this one on this VM; choose another" >&2; exit 1; }
        cp -p "$O" "$B/options.1"
        sed -i 's/^ *allow-query { any; };.*$/    allow-query { 127.0.0.1; };  \/\/ m11/' "$O"
        grep -q '^    allow-query { 127.0.0.1; };  // m11$' "$O" || { cp -p "$B/options.1" "$O"; echo "edit failed" >&2; exit 1; } ;;
    *) usage ;;
    esac
    reconf
    ;;
"undo 1")
    [ -f "$B/options.1" ] || { echo "nothing saved to undo" >&2; exit 1; }
    cp -p "$B/options.1" "$O"
    reconf
    ;;
"set 2")
    [ $# -ge 4 ] || usage
    grep -q "^@ IN NS ns2\.$Z\.\$" "$F" && { echo "fault set"; exit 0; }
    grep -q '^ns2[[:space:]]' "$F" && { echo "cannot set this one on this VM; choose another" >&2; exit 1; }
    mkdir -p "$B"; chmod 700 "$B"
    cp -p "$F" "$B/zone.2"
    awk '/; serial/ && !d { sub(/[0-9]+/, $1 + 1); d = 1 } { print }' "$B/zone.2" > "$F.new"
    grep -q '; serial' "$F.new" || { rm -f "$F.new"; echo "no '; serial' line in $F" >&2; exit 1; }
    printf '@ IN NS ns2.%s.\nns2 IN A %s\n' "$Z" "$4" >> "$F.new"
    named-checkzone -q "$Z" "$F.new" || { rm -f "$F.new"; echo "zone check failed" >&2; exit 1; }
    cat "$F.new" > "$F"; rm -f "$F.new"
    rndc reload "$Z" >/dev/null
    ;;
"undo 2")
    # the saved records, with a serial above both the saved and the current one
    [ -f "$B/zone.2" ] || { echo "nothing saved to undo" >&2; exit 1; }
    cur=$(serial "$F"); old=$(serial "$B/zone.2")
    [ -n "$cur" ] && [ -n "$old" ] || { echo "no '; serial' line" >&2; exit 1; }
    s=$(( (cur > old ? cur : old) + 1 ))
    awk -v s="$s" '/; serial/ && !d { sub(/[0-9]+/, s); d = 1 } { print }' "$B/zone.2" > "$F.new"
    named-checkzone -q "$Z" "$F.new" || { rm -f "$F.new"; echo "zone check failed" >&2; exit 1; }
    cat "$F.new" > "$F"; rm -f "$F.new"
    rndc reload "$Z" >/dev/null
    ;;
"clean 0")
    rm -rf "$B"; echo "cleaned"; exit 0
    ;;
*)
    usage
    ;;
esac
[ "$act" = set ] && echo "fault set" || echo "fault undone"
