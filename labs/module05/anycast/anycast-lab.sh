#!/bin/sh
# anycast-lab.sh: Module 5 Labs 5.3-5.4, an anycast service in one VM.
# Run as root on VM 2 (sudo sh anycast-lab.sh COMMAND):
#   up            build the lab: six network namespaces, BIRD in four, named in two
#   status        BGP sessions and the service route at R1 and R2, health logs
#   stop a|b      stop named at a site (its health check keeps running)
#   start a|b     start named at a site again
#   fix           put every site back as `up` left it (after Lab 5.4's faults,
#                 which the instructor sets with ../instructor/faults.sh)
#   down          stop everything and remove the lab (Lab 5.4's last step)
#
#   C1 ── R1 (AS 65001) ── R2 (AS 65002) ── C2
#          │                      │
#        site A                 site B        both AS 65100, both 198.51.100.53
#
# Addresses (RFC 5737 TEST-NET-2, inside the VM only; nothing here touches
# the VM's own interfaces, routes or named):
#   C1-R1 .2/.1   R1-A .5/.6   R1-R2 .9/.10   R2-B .13/.14   R2-C2 .17/.18
#   service 198.51.100.53/32 on lo at both sites
# Never use pkill or killall here: the VM's own named has the same name.
# This script signals only processes inside the m05-* namespaces.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
RUN=/run/m05-anycast             # BIRD's sockets and pid files, the BIRD configs, health logs
LIB=/usr/local/lib/m05-anycast   # healthcheck.sh: Debian mounts /run noexec
ETC=/etc/bind/m05-anycast
VAR=/var/cache/bind/m05-anycast
NSS="m05-c1 m05-r1 m05-r2 m05-c2 m05-a m05-b"

die() { echo "anycast-lab: $*" >&2; exit 1; }
[ "$(id -u)" = 0 ] || die "run as root (sudo)"

# nspid NS COMM: process IDs in namespace NS whose command name is COMM
nspid() {
    for p in $(ip netns pids "$1" 2>/dev/null); do
        [ "$(cat "/proc/$p/comm" 2>/dev/null)" = "$2" ] && echo "$p"
    done
    return 0
}
# link NS1 IF1 ADDR1 NS2 IF2 ADDR2: a veth pair, a /30 on each end
link() {
    ip link add "$2" netns "$1" type veth peer name "$5" netns "$4"
    ip -n "$1" addr add "$3/30" dev "$2"; ip -n "$1" link set "$2" up
    ip -n "$4" addr add "$6/30" dev "$5"; ip -n "$4" link set "$5" up
}
start_named() {   # start_named a|b
    [ -z "$(nspid "m05-$1" named)" ] || return 0
    ip netns exec "m05-$1" named -u bind -c "$ETC/$1/named.conf"
}
health_running() { [ -n "$(nspid "m05-$1" healthcheck.sh)" ]; }
named_stopped() { [ -z "$(nspid "m05-$1" named)" ]; }
start_health() {  # start_health a|b; stops the script if the check is not running 5 s later
    health_running "$1" && return 0
    ip netns exec "m05-$1" "$LIB/healthcheck.sh" "$1" </dev/null >/dev/null 2>&1 &
    wait_for 5 health_running "$1" || die "health check at site $1 did not start ($LIB/healthcheck.sh); run: down"
}
reload_named() {  # reload_named a|b: SIGHUP re-reads the configuration and zone files
    for p in $(nspid "m05-$1" named); do kill -HUP "$p"; done
}
route_at() {      # route_at r1|r2: the forwarding entry for the service address
    ip -n "m05-$1" route show 198.51.100.53
}
# wait_for SECONDS COMMAND...: poll once a second until COMMAND succeeds
wait_for() {
    n=$1; shift
    while [ "$n" -gt 0 ]; do "$@" >/dev/null 2>&1 && return 0; sleep 1; n=$((n - 1)); done
    return 1
}
sessions() {     # sessions R: the number of Established BGP sessions at router R
    birdc -s "$RUN/$1.ctl" show protocols | grep -c Established
}
all_up() {       # all four BGP sessions up and each router at its own site
    [ "$(sessions r1)" = 2 ] && [ "$(sessions r2)" = 2 ] && normal
}
normal() {       # each router forwards to its own city's site
    route_at r1 | grep -q 'via 198.51.100.6 ' && route_at r2 | grep -q 'via 198.51.100.14 '
}

up() {
    [ ! -e "$RUN" ] && [ ! -e "$LIB" ] || die "already up (run: down)"
    command -v bird >/dev/null && command -v birdc >/dev/null || die "bird2 is not installed"
    trap 'echo "anycast-lab: interrupted; removing the lab" >&2; down >/dev/null; exit 1' INT TERM HUP
    for f in bird-r1.conf bird-r2.conf bird-site-a.conf bird-site-b.conf named-site-a.conf named-site-b.conf db.svc.test healthcheck.sh; do
        [ -r "$here/$f" ] || die "missing $here/$f"
    done
    install -d -o bird -g bird -m 755 "$RUN"    # BIRD writes its sockets and pid files here
    install -d -m 755 "$ETC/a" "$ETC/b"
    install -d -o bind -g bind -m 755 "$VAR" "$VAR/a" "$VAR/b"
    install -d -m 755 "$LIB"
    install -m 755 "$here/healthcheck.sh" "$LIB/"
    for s in a b; do
        install -m 644 "$here/named-site-$s.conf" "$ETC/$s/named.conf"
        install -m 644 "$here/db.svc.test" "$ETC/$s/db.svc.test"
        install -m 644 "$here/bird-site-$s.conf" "$RUN/$s.conf"
    done
    install -m 644 "$here/bird-r1.conf" "$RUN/r1.conf"
    install -m 644 "$here/bird-r2.conf" "$RUN/r2.conf"
    for s in a b; do named-checkconf -z "$ETC/$s/named.conf" >/dev/null || die "named-checkconf failed for site $s"; done
    for n in r1 r2 a b; do bird -p -c "$RUN/$n.conf" || die "bird -p failed for $n"; done

    for ns in $NSS; do ip netns add "$ns"; ip -n "$ns" link set lo up; done
    link m05-c1 c1-r1 198.51.100.2  m05-r1 r1-c1 198.51.100.1
    link m05-r1 r1-a  198.51.100.5  m05-a  a-r1  198.51.100.6
    link m05-r1 r1-r2 198.51.100.9  m05-r2 r2-r1 198.51.100.10
    link m05-r2 r2-b  198.51.100.13 m05-b  b-r2  198.51.100.14
    link m05-r2 r2-c2 198.51.100.17 m05-c2 c2-r2 198.51.100.18
    ip -n m05-a addr add 198.51.100.53/32 dev lo
    ip -n m05-b addr add 198.51.100.53/32 dev lo
    ip -n m05-c1 route add default via 198.51.100.1
    ip -n m05-c2 route add default via 198.51.100.17
    ip -n m05-a route add default via 198.51.100.5
    ip -n m05-b route add default via 198.51.100.13
    # the links themselves are static routes: BGP carries only the service
    ip -n m05-r1 route add 198.51.100.12/30 via 198.51.100.10
    ip -n m05-r1 route add 198.51.100.16/30 via 198.51.100.10
    ip -n m05-r2 route add 198.51.100.0/30 via 198.51.100.9
    ip -n m05-r2 route add 198.51.100.4/30 via 198.51.100.9
    ip netns exec m05-r1 sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
    ip netns exec m05-r2 sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'

    for n in r1 r2 a b; do
        # as Debian's bird.service runs it: started as root, then user bird
        ip netns exec "m05-$n" bird -u bird -g bird -c "$RUN/$n.conf" -s "$RUN/$n.ctl" -P "$RUN/$n.pid"
    done
    start_named a; start_named b
    start_health a; start_health b
    wait_for 60 all_up || { status; die "lab not ready after 60 s (see status above); run: down, then up"; }
    trap - INT TERM HUP
    echo "anycast lab up: R1 $(route_at r1); R2 $(route_at r2)"
}

status() {
    for r in r1 r2; do
        echo "== $r: BGP sessions"
        birdc -s "$RUN/$r.ctl" show protocols | awk 'NR > 2 && $2 == "BGP" { print "   " $1, $4, $5, $6 }'
        echo "== $r: routes to 198.51.100.53/32 (* = in use)"
        birdc -s "$RUN/$r.ctl" show route 198.51.100.53/32 all | sed -n 's/^\(198\.51\.100\.53\/32 \)\{0,1\}[[:space:]]*\(unicast .*\)$/   \2/p; s/^[[:space:]]*BGP\.as_path: /     AS path: /p'
        echo "== $r: forwarding: $(route_at "$r")"
    done
    for s in a b; do
        echo "== site $s: named $( [ -n "$(nspid "m05-$s" named)" ] && echo running || echo stopped)," \
             "health check $( [ -n "$(nspid "m05-$s" healthcheck.sh)" ] && echo running || echo stopped)"
        tail -n 3 "$RUN/$s-health.log" 2>/dev/null | sed 's/^/   /'
    done
}

stop_site() {
    for p in $(nspid "m05-$1" named); do kill "$p" 2>/dev/null || true; done
    wait_for 10 named_stopped "$1" || die "named at site $1 did not stop"
    echo "named at site $1 stopped"
}

fix() {          # every site's zone, BIRD config, named and health check as `up` left them
    for s in a b; do
        cmp -s "$here/db.svc.test" "$ETC/$s/db.svc.test" || { install -m 644 "$here/db.svc.test" "$ETC/$s/db.svc.test"; reload_named "$s"; }
        cmp -s "$here/bird-site-$s.conf" "$RUN/$s.conf" || { install -m 644 "$here/bird-site-$s.conf" "$RUN/$s.conf"; birdc -s "$RUN/$s.ctl" configure >/dev/null; }
        start_named "$s"; start_health "$s"
    done
    wait_for 30 normal || { status; die "routes not back to normal after 30 s"; }
    echo "faults undone"
}

down() {
    for ns in $NSS; do
        for p in $(ip netns pids "$ns" 2>/dev/null); do kill "$p" 2>/dev/null || true; done
    done
    n=10
    while [ "$n" -gt 0 ]; do
        left=""; for ns in $NSS; do left="$left$(ip netns pids "$ns" 2>/dev/null)"; done
        [ -z "$left" ] && break; sleep 1; n=$((n - 1))
    done
    for ns in $NSS; do
        for p in $(ip netns pids "$ns" 2>/dev/null); do kill -9 "$p" 2>/dev/null || true; done
        ip netns del "$ns" 2>/dev/null || true
    done
    rm -rf "$RUN" "$ETC" "$VAR" "$LIB"
    echo "anycast lab removed"
}

case ${1:-} in
up)     up ;;
status) [ -e "$RUN" ] || die "not up"; status ;;
stop)   [ -e "$RUN" ] || die "not up"; case ${2:-} in a|b) stop_site "$2" ;; *) die "stop a|b" ;; esac ;;
start)  [ -e "$RUN" ] || die "not up"; case ${2:-} in a|b) start_named "$2"; echo "named at site $2 started" ;; *) die "start a|b" ;; esac ;;
fix)    [ -e "$RUN" ] || die "not up"; fix ;;
down)   down ;;
*)      sed -n '2,10s/^# \{0,1\}//p' "$0"; exit 2 ;;
esac
