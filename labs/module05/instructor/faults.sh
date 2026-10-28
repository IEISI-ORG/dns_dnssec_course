#!/bin/sh
# faults.sh N: the instructor sets one Lab 5.4 fault in a team's anycast lab
# (../anycast/anycast-lab.sh, which must be up). Run as root on the team's
# VM 2; it needs no other kit file, so it can be piped over SSH:
#     ssh <VM 2> 'sudo sh -s -- 2' < faults.sh
# Participants undo every fault with `sudo sh anycast/anycast-lab.sh fix`.
# The answers are in README.md here. This repository is public: a graded
# drill assesses the evidence and method, not just the named cause.
#   1  site B serves an older zone (serial 2026102701, www 198.51.100.81)
#   2  site A's health check and named stopped, so its route stays announced
#   3  site A announces the service with AS 65100 prepended twice
set -eu
RUN=/run/m05-anycast
ETC=/etc/bind/m05-anycast

die() { echo "faults: $*" >&2; exit 1; }
[ "$(id -u)" = 0 ] || die "run as root (sudo)"
[ -e "$RUN/a.conf" ] && [ -e "$ETC/a/db.svc.test" ] || die "the anycast lab is not up on this VM"

# nspid NS COMM: process IDs in namespace NS whose command name is COMM
nspid() {
    for p in $(ip netns pids "$1" 2>/dev/null); do
        [ "$(cat "/proc/$p/comm" 2>/dev/null)" = "$2" ] && echo "$p"
    done
    return 0
}

case ${1:-} in
1)  # derived from site A's copy, which anycast-lab.sh installed from the kit
    sed -e 's/2026102801 ; serial/2026102701 ; serial/' -e 's/198\.51\.100\.80/198.51.100.81/' \
        "$ETC/a/db.svc.test" > "$ETC/b/db.svc.test.new"
    grep -q '2026102701 ; serial' "$ETC/b/db.svc.test.new" || die "fault 1: serial line not found"
    mv "$ETC/b/db.svc.test.new" "$ETC/b/db.svc.test"
    for p in $(nspid m05-b named); do kill -HUP "$p"; done ;;
2)  # the check first, so that nothing withdraws the route
    for p in $(nspid m05-a healthcheck.sh); do kill "$p" 2>/dev/null || true; done
    for p in $(nspid m05-a named); do kill "$p" 2>/dev/null || true; done
    n=40; while [ -n "$(nspid m05-a named)" ] && [ "$n" -gt 0 ]; do sleep 0.25; n=$((n - 1)); done
    [ -z "$(nspid m05-a named)" ] || die "fault 2: named at site A did not stop" ;;
3)  sed 's/export where proto = "svc";/export filter { if proto = "svc" then { bgp_path.prepend(65100); bgp_path.prepend(65100); accept; } reject; };/' \
        "$RUN/a.conf" > "$RUN/a.conf.new"
    grep -q 'bgp_path.prepend' "$RUN/a.conf.new" || die "fault 3: the export line of site A's BIRD config was not found"
    mv "$RUN/a.conf.new" "$RUN/a.conf"
    birdc -s "$RUN/a.ctl" configure >/dev/null ;;
*)  die "usage: faults.sh 1|2|3" ;;
esac
echo "fault set"
