#!/bin/bash
# rehearse.sh [TRANSCRIPT]: run every Module 11 lab step (Labs 11.1-11.4) on
# two stand-in participant VMs and check each checkpoint.
#
# It starts the instructor stack (../../instructor, no profile: on Day 6
# only the registry for example. runs) on an internal Docker bridge with no
# route out, plus two Debian 13 containers (test/Dockerfile) set up as
# Modules 6-9 left them: VM 1 at 192.0.2.30, the authoritative server, with
# Module 6's options (no recursion, RRL enforcing) and logging file,
# team01.example signed by Module 7's lab policy (DS at the registry) and
# manual01.example signed by hand (Lab 7.1); VM 2 at 192.0.2.10, the
# validating resolver with Module 6's options, the static-stub zone for
# example, Module 7's trust anchor and Module 8's DoT and DoH listeners and
# certificate. The participant's typing is the commands below; the kit files
# come from ../vm1, ../vm2, ../tools; the instructor's fault script from
# ../instructor, piped in as over SSH. named runs in the foreground with its
# log in /var/log/named.out, where a VM has the journal; the Prometheus
# services run as the prometheus user with the arguments from their
# /etc/default files, as systemd would start them. Both VMs mount /run
# noexec, as Debian 13 does. Everything is removed at the end. The
# transcript goes to TRANSCRIPT, or to a new file under ${TMPDIR:-/tmp} whose
# name is printed. Needs Docker with Compose v2; the lab steps need no
# Internet access; the image build does. KIT_DIR=<copy of labs/module11>
# runs it against a changed kit (mutation tests). SETUP_ONLY=1 stops after
# the set-up and leaves the lab running (for exploring), with its work
# directory ${TMPDIR:-/tmp}/dnslab-m11-<uid>; the next run removes both.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "${KIT_DIR:-$here/..}" && pwd) || exit 1
M02=$(cd "$here/../../module02" && pwd) || exit 1
M06=$(cd "$here/../../module06" && pwd) || exit 1
M08=$(cd "$here/../../module08" && pwd) || exit 1
INS=$(cd "$here/../../instructor" && pwd) || exit 1
unset M01_FAULT_LABELS COMPOSE_PROFILES
PROJ=dnslab-m11
V1=dnslab-m11-vm1
V2=dnslab-m11-vm2
DC=(docker compose -p "$PROJ" --env-file "$INS/test/test.env" -f "$INS/compose.yaml" -f "$INS/compose.test.yaml")
Z=/var/lib/bind/db.team01.example
L=/etc/bind/named.conf.local
O=/etc/bind/named.conf.options
N=/etc/bind/named.conf
pass=0; fail=0
W=${TMPDIR:-/tmp}/dnslab-m11-$(id -u)

stop_lab() {
    docker rm -f "$V1" "$V2" >/dev/null 2>&1
    "${DC[@]}" down -v --remove-orphans >/dev/null 2>&1
}
[ "${SETUP_ONLY:-0}" = 1 ] || trap 'stop_lab; rm -rf "$W"' EXIT
OUT=${1:-$(mktemp "${TMPDIR:-/tmp}/m11-rehearsal.XXXXXX")} || exit 1
# the instructor stack's test env has empty M01_* and DOQ addresses unless set
export CLASSROOM_DIR=$W/classroom HANDOUT_DIR=$W/handout M01_CHILD_ADDR='' M01_ROOT_ADDR='' M01_RESOLVER_ADDR='' DOQ_ADDR=''

log() { printf '%s\n' "$@" >> "$OUT"; }
ok() { echo "PASS  $1"; pass=$((pass + 1)); }
bad() { echo "FAIL  $1"; fail=$((fail + 1)); }
ctr() { case $1 in vm1) echo "$V1" ;; vm2) echo "$V2" ;; *) echo "bad VM $1" >&2; exit 1 ;; esac; }
# step VM NAME COMMAND REGEX...: run COMMAND on VM (vm1 or vm2), keep it in
# the transcript, PASS if the output matches every REGEX (a leading ! negates)
step() {
    local c name=$2 cmd=$3 out r good=1
    c=$(ctr "$1") || exit 1; shift 3
    out=$(docker exec "$c" bash -c "$cmd" 2>&1)
    { echo "[$name]"; echo "$c\$ $cmd"; echo "$out"; echo; } >> "$OUT"
    for r in "$@"; do
        if [[ $r == !* ]]; then grep -Eq -- "${r#!}" <<< "$out" && good=0
        else grep -Eq -- "$r" <<< "$out" || good=0; fi
    done
    if [ "$good" = 1 ]; then ok "$name"; else bad "$name"; sed -n '1,10s/^/        /p' <<< "$out"; fi
    [ "$good" = 1 ]
}
# on VM COMMAND: run quietly on VM (input from stdin), keep it in the transcript
on() {
    local c; c=$(ctr "$1") || exit 1
    log "$c\$ $2"; docker exec -i "$c" bash -c "$2" >> "$OUT" 2>&1
}
# start_named VM: "systemctl start named"; stops the run if named does not come up
start_named() {
    local c; c=$(ctr "$1") || exit 1
    docker exec "$c" install -d -o bind -g bind /run/named
    docker exec -d "$c" sh -c 'exec named -u bind -g >> /var/log/named.out 2>&1'
    for _ in $(seq 20); do docker exec "$c" rndc status >/dev/null 2>&1 && return 0; sleep 0.5; done
    echo "named did not start on $c"; docker exec "$c" tail -20 /var/log/named.out; exit 1
}
reconf() { step "$1" "$2" "named-checkconf && rndc reconfig && echo reconfigured" '^reconfigured$'; }
# poll CMD [TRIES]: a shell fragment that retries CMD every 0.5 s (default 40 tries)
poll() { printf 'for _ in $(seq %s); do %s && break; sleep 0.5; done; ' "${2:-40}" "$1"; }

stop_lab
rm -rf "$W"; mkdir -p "$W/classroom" "$W/handout" || exit 1
echo "01 192.0.2.30" > "$W/classroom/teams.conf"
: > "$OUT" || exit 1
"${DC[@]}" up -d --build --quiet-pull init parent >/dev/null 2>&1 \
    || { "${DC[@]}" logs; exit 1; }
docker build -q --build-arg DEBIAN_TAG="${DEBIAN_TAG:-trixie-20261005-slim}" -t dnslab/m11-vm:local "$here" >/dev/null || exit 1
for v in "$V1 192.0.2.30" "$V2 192.0.2.10"; do
    set -- $v
    docker run -d --init --tmpfs /run:rw,noexec,nosuid,nodev,mode=755 --name "$1" --network "${PROJ}_lab" --ip "$2" \
        -v "$KIT:/kit:ro" -v "$M02:/m02:ro" -v "$M06:/m06:ro" -v "$M08:/m08:ro" -v "$W/handout:/handout:ro" \
        dnslab/m11-vm:local >/dev/null || exit 1
    docker exec "$1" sh -c 'rndc-confgen -a -u bind >/dev/null 2>&1 && install -d -o bind -g bind /var/log/named && touch /var/log/named.out' || exit 1
done
for _ in $(seq 60); do [ -s "$W/handout/trust-anchors.conf" ] && break; sleep 1; done
[ -s "$W/handout/trust-anchors.conf" ] || { echo "registry did not write the trust anchor"; "${DC[@]}" logs; exit 1; }

# VM 1 as Modules 2-9 left it. team01.example: Module 2's records, Module 6's
# additions, Module 8's resolver and secret-project names; signed by the
# lab policy (Lab 7.2), DS at the registry. manual01.example: signed by
# hand (Lab 7.1), DS at the registry. Module 6's options (log-only no after
# Lab 6.3) and logging file. Lab 6.4's TSIG key, made at run time with
# tsig-keygen, its allow-transfer and also-notify lines (VM 1 keeps sending
# signed NOTIFYs to VM 2 at every serial change) and the key file left on
# VM 2 with no include (Lab 6.4 step 6 removed the secondary). Module 8's
# Unbound on 127.0.0.1:5300 is not set up: Module 11 does not use it.
on vm1 "sed -e 's/NN/01/g' -e 's/2026102701 ; serial/2026102731 ; serial/' /m02/zones/db.teamNN.example > \"$Z\" && grep -v '^;' /m06/auth/db.additions >> \"$Z\" && cat >> \"$Z\"" <<'EOF'
@       IN A     192.0.2.80
        IN MX    10 mail
www     IN A     192.0.2.80
mail    IN A     192.0.2.81
ftp     IN A     192.0.2.82
resolver IN A    192.0.2.10
secret-project IN A 192.0.2.88
EOF
on vm1 "sed 's/NN/01/g' /m02/zones/db.192.0.2 > /var/lib/bind/db.192.0.2 && sed 's/NN/01/g' /m02/zones/db.2001-db8-NN > /var/lib/bind/db.2001-db8-01"
on vm1 "sed -e 's/NN/01/g' -e 's/N2\\.N1/1.0/' /m02/zones/named.conf.local > \"$L\""
on vm1 "sed -i 's|file \"/var/lib/bind/db.team01.example\";|&\n    dnssec-policy \"lab\";\n    parental-agents { \"registry\"; };|' \"$L\" && cat >> \"$L\"" <<'EOF'

// Module 7, Lab 7.2: the lab policy from the lab sheet
dnssec-policy "lab" {
    keys {
        ksk lifetime unlimited algorithm ecdsap256sha256;
        zsk lifetime P30D algorithm ecdsap256sha256;
    };
    nsec3param iterations 0 optout no salt-length 0;
    dnskey-ttl 60;
    max-zone-ttl 60;
    publish-safety 30;
    retire-safety 30;
    zone-propagation-delay 30;
    parent-ds-ttl 60;
    parent-propagation-delay 30;
    signatures-validity PT30M;
    signatures-validity-dnskey PT30M;
    signatures-refresh PT25M;
    signatures-jitter PT1M;
};
parental-agents "registry" { 192.0.2.53; };

// Module 7, Lab 7.1: signed by hand
zone "manual01.example" {
    type primary;
    file "/var/lib/bind/db.manual01.example.signed";
};
EOF
on vm1 "sed 's/log-only yes;/log-only no;/' /m06/auth/named.conf.options > \"$O\" && cp /m06/common/named.conf.logging /etc/bind/ && echo 'include \"/etc/bind/named.conf.logging\";' >> \"$N\""
# Lab 6.4 steps 1-2 on VM 1, step 3's copy of the key on VM 2
on vm1 "umask 077; tsig-keygen -a hmac-sha256 team01-xfr > /etc/bind/team01-xfr.key && chown root:bind /etc/bind/team01-xfr.key && chmod 640 /etc/bind/team01-xfr.key && sed -i '1i include \"/etc/bind/team01-xfr.key\";' \"$L\" && sed -i 's|    parental-agents { \"registry\"; };|&\n    allow-transfer { key \"team01-xfr\"; };\n    also-notify { 192.0.2.10 key \"team01-xfr\"; };|' \"$L\" && grep -c 'team01-xfr' \"$L\""
docker exec "$V1" cat /etc/bind/team01-xfr.key | docker exec -i "$V2" sh -c 'umask 077; cat > /etc/bind/team01-xfr.key; chown root:bind /etc/bind/team01-xfr.key; chmod 640 /etc/bind/team01-xfr.key' || exit 1
# Lab 7.1 in the participant's home directory: keys there, signed file in /var/lib/bind
on vm1 "mkdir -p /root/m71 && cd /root/m71 && cat > db.manual01.example && dnssec-keygen -q -a 13 -f KSK manual01.example >/dev/null && dnssec-keygen -q -a 13 manual01.example >/dev/null && dnssec-signzone -q -S -3 - -H 0 -o manual01.example db.manual01.example && install -o bind -g bind -m 644 db.manual01.example.signed /var/lib/bind/" <<'EOF'
$TTL 60
@    IN SOA ns1.manual01.example. hostmaster.manual01.example. 1 3600 600 1209600 60
     IN NS  ns1.manual01.example.
ns1  IN A   192.0.2.30
www  IN A   192.0.2.80
EOF
on vm1 "named-checkconf -z"
start_named vm1
docker exec "$V1" bash -c "$(poll "dig @127.0.0.1 team01.example DNSKEY +short | grep -q '^257 '")" >/dev/null
docker exec "$V1" dig @127.0.0.1 team01.example DNSKEY +noall +answer | "${DC[@]}" exec -T parent publish-ds team01.example >> "$OUT" 2>&1 \
    || { echo "could not publish the team01.example DS"; exit 1; }
docker exec "$V1" cat /root/m71/dsset-manual01.example. | "${DC[@]}" exec -T parent publish-ds manual01.example >> "$OUT" 2>&1 \
    || { echo "could not publish the manual01.example DS"; exit 1; }

# VM 2 as Modules 6-9 left it: Module 6's resolver options without the
# validate-except line (Lab 7.3 step 1) and with Module 8's listen-on and
# padding lines, including the port 53 line that the Module 8 slide shows
# and its kit file leaves out (without it named stops listening on port 53); the static-stub zone; Module 7's trust anchor; Module 8's
# certificate, DoT, DoH and resolver.arpa; Module 6's logging file. Lab
# 6.5's policy zones are not set up: Module 11 does not use them.
on vm2 "grep -v 'validate-except' /m06/resolver/named.conf.options | sed '\$d' > \"$O\" && printf '    listen-on port 53 { any; };\n    listen-on-v6 port 53 { any; };\n' >> \"$O\" && sed -n '/listen-on/,\$p' /m08/resolver/named.conf.options.module08 >> \"$O\" && echo '};' >> \"$O\""
on vm2 "cp /m06/resolver/named.conf.local \"$L\" && cp /m06/common/named.conf.logging /etc/bind/ && cp /handout/trust-anchors.conf /etc/bind/named.conf.trust-anchors && cp /m08/resolver/named.conf.module08 /etc/bind/ && sed 's/NN/01/g' /m08/resolver/db.resolver.arpa > /etc/bind/db.resolver.arpa"
on vm2 "printf 'include \"/etc/bind/named.conf.%s\";\n' logging trust-anchors module08 >> \"$N\""
on vm2 "mkdir /etc/bind/tls && sh /m08/make-certs.sh 01 192.0.2.10 /etc/bind/tls >/dev/null 2>&1 && chown root:bind /etc/bind/tls/resolver.key && chmod 640 /etc/bind/tls/resolver.key"
on vm2 "named-checkconf -z"
start_named vm2
docker exec "$V2" bash -c "$(poll "dig @192.0.2.10 www.team01.example +dnssec | grep -q 'flags: qr rd ra ad;'" 60)" >/dev/null
docker exec "$V2" dig @192.0.2.10 www.team01.example +dnssec | grep -q 'flags: qr rd ra ad;' \
    || { echo "VM 2 does not validate the team zone"; docker exec "$V2" tail -20 /var/log/named.out; "${DC[@]}" logs parent | tail -20; exit 1; }
if [ "${SETUP_ONLY:-0}" = 1 ]; then echo "set up; work dir $W; transcript $OUT"; exit 0; fi

# svc VM start|stop NAME: "systemctl start|stop NAME" for the Prometheus
# services: as user prometheus, with ARGS from /etc/default/NAME, as
# Debian's units run them; a stop waits until the process has gone
svc() {
    local c; c=$(ctr "$1") || exit 1
    local comm; comm=$(printf '%.15s' "$3")
    if [ "$2" = start ]; then
        docker exec -d "$c" sh -c ". /etc/default/$3; exec runuser -u prometheus -- /usr/bin/$3 \$ARGS >> /var/log/$3.out 2>&1"
    else
        docker exec "$c" sh -c "pkill -x '$comm'; for _ in \$(seq 20); do pgrep -x '$comm' >/dev/null || exit 0; sleep 0.5; done; exit 1"
    fi
}
# kit tools where the participant keeps them
for c in "$V1" "$V2"; do docker exec "$c" sh -c 'cp -r /kit /root/m11 && chmod 755 /root/m11/tools/*.sh' || exit 1; done
ALERTS="sh /root/m11/tools/alerts.sh"
# firing ALERT INSTANCE: shell fragment, true while that alert is firing
firing() { printf "$ALERTS | grep -q '^%s %s firing'" "$1" "$2"; }
INS_DC="${DC[*]}"

{ echo "# Module 11 rehearsal, $(date -u +%Y-%m-%dT%H:%MZ)"
  docker exec "$V2" sh -c 'named -v; dpkg-query -W bind9 bind9-dnsutils dnsperf prometheus prometheus-bind-exporter prometheus-blackbox-exporter'
  echo; } >> "$OUT"

echo "== Day 6: the VMs as Module 9 left them"
step vm1 "0.1 VM 1 answers for team01.example with aa and signatures; only named listens" \
    "dig @192.0.2.30 team01.example SOA +norec +dnssec | grep -E 'flags:|RRSIG'; ss -lntuH | awk '{print \$5}' | grep -v '^127\\.0\\.0\\.11:' | sort -u; echo run=\$(findmnt -no OPTIONS /run)" \
    'flags: qr aa;' 'RRSIG[[:space:]]+SOA 13 2 60 ' '^192\.0\.2\.30:53$' '!:(8053|9090|9115|9119)$' '^run=.*noexec'
step vm2 "0.2 VM 2 validates the team zone; listens on 53, 853 and 443; the Prometheus packages installed, not running" \
    "dig @192.0.2.10 www.team01.example +dnssec | grep flags:; ss -lntuH | awk '{print \$5}' | grep -v '^127\\.0\\.0\\.11:' | sort -u; dpkg-query -W prometheus prometheus-bind-exporter prometheus-blackbox-exporter; echo procs=\$(pgrep -cu prometheus)" \
    'flags: qr rd ra ad;' '^192\.0\.2\.10:53$' '^192\.0\.2\.10:853$' '^192\.0\.2\.10:443$' '!:(8053|9090|9115|9119)$' \
    '^prometheus[[:space:]]+2\.53\.' '^prometheus-bind-exporter[[:space:]]+0\.8\.0' '^prometheus-blackbox-exporter[[:space:]]+0\.26\.0' '^procs=0$' \
    || { echo "VM 2 is not in the Day 6 state; stopping"; exit 1; }
# harness only: the starting state, for the end-state comparison
for c in "$V1" "$V2"; do docker exec "$c" sh -c "mkdir /root/start /root/start/default /root/start/prom && cp -p \"$N\" \"$L\" \"$O\" /root/start/ && cp -p /etc/default/prometheus* /root/start/default/ && cp -p /etc/prometheus/*.yml /root/start/prom/ && { cp -p \"$Z\" /root/start/ 2>/dev/null; true; }" || exit 1; done

echo "== Lab 11.1: counters, rates and a capture"
step vm1 "11.1.0 precondition: VM 2 answers plain DNS on port 53 (Module 8's port 53 listen-on line in place)" \
    "dig @192.0.2.10 www.team01.example +short; dig @192.0.2.10 www.team01.example | grep -o 'status: [A-Z]*'" \
    '^192\.0\.2\.80$' '^status: NOERROR$'
for v in vm1 vm2; do
    on "$v" "cp -p \"$L\" \"$L.m09\" && cp -p \"$O\" \"$O.m09\" && cat /root/m11/common/named.conf.stats >> \"$L\""
    reconf "$v" "11.1.1 $v: statistics channel added (named.conf.local), checked, reconfigured"
done
step vm2 "11.1.1b the channel answers on 127.0.0.1:8053 only" \
    "curl -s http://127.0.0.1:8053/json/v1/server | jq -r 'keys[]'; ss -lntH | awk '{print \$4}' | grep 8053" \
    '^nsstats$' '^views$' '^127\.0\.0\.1:8053$' '!0\.0\.0\.0:8053'
on vm1 "sed 's/NN/01/g' /root/m11/vm1/names.txt > /root/names.txt && seq 1 500 | sed 's/.*/u&.team01.example A/' > /root/unique.txt"
# the rates run on VM 2 while dnsperf runs on VM 1 (two SSH sessions in class)
docker exec -d "$V2" sh -c 'sh /root/m11/tools/rates.sh 10 > /root/rates-names.txt 2>&1'
step vm1 "11.1.2 warm cache: 500 queries at 50 per second from VM 1, all answered" \
    "dnsperf -s 192.0.2.10 -d /root/names.txt -Q 50 -l 10 | tee /root/perf-names.txt | grep -E 'Queries completed|Average Latency'" \
    'Queries completed: +500 \(100\.00%\)'
step vm2 "11.1.2b warm cache: hit ratio near 100%, few recursions" \
    "$(poll '[ -s /root/rates-names.txt ]')cat /root/rates-names.txt" \
    'queries (4[0-9]|5[0-9])(\.[0-9])?$' 'cache hit ratio \(client queries\): (9[5-9]|100)%' 'SERVFAIL 0$'
docker exec -d "$V2" sh -c 'sh /root/m11/tools/rates.sh 10 > /root/rates-unique.txt 2>&1'
step vm1 "11.1.3 500 unique names: every one a cache miss, all answered" \
    "dnsperf -s 192.0.2.10 -d /root/unique.txt -Q 50 -l 10 | tee /root/perf-unique.txt | grep -E 'Queries completed|Average Latency'; a=\$(awk '/Average Latency/ {print \$4}' /root/perf-names.txt); b=\$(awk '/Average Latency/ {print \$4}' /root/perf-unique.txt); echo \"warm \$a s, unique \$b s\"; awk -v a=\"\$a\" -v b=\"\$b\" 'BEGIN{ print (b > 2 * a) ? \"unique slower: yes\" : \"unique slower: no\" }'" \
    'Queries completed: +500 \(100\.00%\)' '^unique slower: yes$'
step vm2 "11.1.3b unique names: hit ratio 0%, one recursion per query, all NXDOMAIN" \
    "$(poll '[ -s /root/rates-unique.txt ]')cat /root/rates-unique.txt" \
    'cache hit ratio \(client queries\): 0%' 'recursion (4[0-9]|5[0-9])(\.[0-9])?$' 'NXDOMAIN (4[0-9]|5[0-9])(\.[0-9])?$' 'rrl_drop 0$'
step vm2 "11.1.4 recursive clients now, soft and hard limits (900/1000)" \
    "rndc status | grep -E 'recursive (clients|high-water)'" '^recursive clients: [0-9]+/900/1000$' '^recursive high-water: [0-9]+$'
# paste the two lines inside options { } (the last "};" of the file closes it)
on vm2 "head -n -1 \"$O.m09\" > \"$O\" && cat /root/m11/vm2/dnstap.options >> \"$O\" && tail -n 1 \"$O.m09\" >> \"$O\""
reconf vm2 "11.1.5 dnstap lines pasted into options, checked, reconfigured"
step vm2 "11.1.5b dnstap: one client query, and the resolver's queries upstream" \
    "rndc flushtree team01.example && dig @127.0.0.1 www.team01.example +short && rndc dnstap -roll && $(poll '[ -s /var/cache/bind/dnstap.fstrm.0 ]')dnstap-read /var/cache/bind/dnstap.fstrm.0" \
    '^192\.0\.2\.80$' ' CQ 127\.0\.0\.1:[0-9]+ -> 127\.0\.0\.1:53 UDP [0-9]+b www\.team01\.example/IN/A' ' RQ [0-9.]+:[0-9]+ -> 192\.0\.2\.30:53 UDP [0-9]+b www\.team01\.example/IN/A'
on vm2 "cp -p \"$O.m09\" \"$O\""
reconf vm2 "11.1.5c dnstap lines removed again (the saved options back)"
step vm2 "11.1.5d no dnstap files left; options as before" \
    "rm -f /var/cache/bind/dnstap.fstrm*; dig @127.0.0.1 www.team01.example >/dev/null; echo files=\$(ls /var/cache/bind | grep -c dnstap) open=\$(ls -l /proc/\$(pgrep -xo named)/fd | grep -c dnstap); cmp \"$O\" /root/start/named.conf.options && echo same" '^files=0 open=0$' '^same$'

echo "== Lab 11.2: Prometheus, exporters and alerts"
on vm1 "cp -p /etc/default/prometheus-bind-exporter /etc/default/prometheus-bind-exporter.m09 && cp /root/m11/vm1/prometheus-bind-exporter /etc/default/"
svc vm1 start prometheus-bind-exporter
step vm2 "11.2.1 VM 1's counters through its exporter, from VM 2" \
    "$(poll 'curl -sf http://192.0.2.30:9119/metrics >/dev/null')curl -s http://192.0.2.30:9119/metrics | grep -E '^bind_up |^bind_zone_serial.*team01'" \
    '^bind_up 1$' '^bind_zone_serial\{view="_default",zone_name="team01\.example"\} [0-9.e+]+$' \
    || { docker exec "$V1" tail -20 /var/log/prometheus-bind-exporter.out; echo "VM 1's exporter is not up; stopping"; exit 1; }
step vm1 "11.2.1b VM 1's exporter listens on VM 1's address only, as its /etc/default file says" \
    "ss -lntH | awk '{print \$4}' | grep ':9119\$'" '^192\.0\.2\.30:9119$' '!^(\*|0\.0\.0\.0|\[::\]):9119$'
on vm2 "for f in prometheus prometheus-bind-exporter prometheus-blackbox-exporter; do cp -p /etc/default/\$f /etc/default/\$f.m09 && cp /root/m11/vm2/\$f /etc/default/; done; cp -p /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.m09; cp -p /etc/prometheus/blackbox.yml /etc/prometheus/blackbox.yml.m09; for f in prometheus.yml blackbox.yml dns-rules.yml; do sed 's/NN/01/g' /root/m11/vm2/\$f > /etc/prometheus/\$f; done; install -m 644 /etc/bind/tls/ca.crt /etc/prometheus/team-ca.crt"
step vm2 "11.2.2 promtool and the blackbox exporter accept the files; the rule tests pass" \
    "promtool check config /etc/prometheus/prometheus.yml 2>&1; prometheus-blackbox-exporter --config.file=/etc/prometheus/blackbox.yml --config.check 2>&1 | grep -o 'Config file is ok'; cd /root/m11 && promtool test rules test/dns-rules.test.yml 2>&1" \
    'SUCCESS: 6 rules found' 'is valid prometheus config file syntax' '^Config file is ok$' '^  SUCCESS$' '!FAILED'
for s in prometheus-bind-exporter prometheus-blackbox-exporter prometheus; do svc vm2 start "$s"; done
step vm2 "11.2.3 six targets up: Prometheus, two exporters, three probes" \
    "$(poll "[ \$(curl -s 127.0.0.1:9090/api/v1/targets | jq '[.data.activeTargets[] | select(.health == \"up\")] | length') = 6 ]" 120)curl -s 127.0.0.1:9090/api/v1/targets | jq -r '.data.activeTargets[] | \"\(.labels.job) \(.labels.instance) \(.health)\"' | sort; ss -lntH | awk '{print \$4}' | grep -E ':(9090|9115|9119)$' | sort" \
    '^bind 127\.0\.0\.1:9119 up$' '^bind 192\.0\.2\.30:9119 up$' '^dns_soa 192\.0\.2\.30 up$' '^dns_resolve 192\.0\.2\.10 up$' '^dot 192\.0\.2\.10:853 up$' '^prometheus 127\.0\.0\.1:9090 up$' \
    '^127\.0\.0\.1:9090$' '^127\.0\.0\.1:9115$' '^127\.0\.0\.1:9119$' \
    || { docker exec "$V2" tail -20 /var/log/prometheus.out; echo "the monitoring stack is not up; stopping"; exit 1; }
step vm2 "11.2.4 queries: probes succeed; the probe's serial is the counter's; days left on the DoT certificate; no alert" \
    "Q='promtool query instant http://127.0.0.1:9090'; \$Q 'probe_success'; v() { sed -E 's/.* => ([^ ]+) @.*/\\1/'; }; for _ in \$(seq 60); do p=\$(\$Q 'probe_dns_serial' | v); b=\$(\$Q 'bind_zone_serial{zone_name=\"team01.example\"}' | v); [ -n \"\$p\" ] && [ \"\$p\" = \"\$b\" ] && break; sleep 0.5; done; echo \"probe \$p counter \$b\"; [ -n \"\$p\" ] && [ \"\$p\" = \"\$b\" ] && echo 'same serial'; echo cert_days=\$(\$Q 'floor((probe_ssl_earliest_cert_expiry - time()) / 86400)' | v); \$Q 'sum(rate(bind_incoming_queries_total{role=\"resolver\"}[1m]))'; a=\$($ALERTS); echo \"alerts-rc=\$? count=\$(printf '%s' \"\$a\" | grep -c .)\"" \
    'probe_success\{instance="192\.0\.2\.30", job="dns_soa"\} => 1 ' 'probe_success\{instance="192\.0\.2\.10", job="dns_resolve"\} => 1 ' 'probe_success\{instance="192\.0\.2\.10:853", job="dot"\} => 1 ' \
    '^same serial$' '^cert_days=(29|30)$' '^alerts-rc=0 count=0$'
on vm1 "rndc stop"
step vm2 "11.2.5 alert test: VM 1's named stopped; DNSProbeFailed for VM 1 fires" \
    "t0=\$(date +%s); $(poll "$(firing DNSProbeFailed 192.0.2.30)" 360)echo \"after \$((\$(date +%s) - t0)) s:\"; $ALERTS" \
    '^DNSProbeFailed 192\.0\.2\.30 firing since '
start_named vm1
step vm2 "11.2.5b named back on VM 1: the alert resolves (and Prometheus answered)" \
    "t0=\$(date +%s); $(poll "! $(firing DNSProbeFailed 192.0.2.30)" 120)echo \"after \$((\$(date +%s) - t0)) s:\"; $ALERTS; echo alerts-rc=\$?" \
    '!^DNSProbeFailed 192\.0\.2\.30 firing' '^alerts-rc=0$'

echo "== Lab 11.3: checks across servers and the parent"
step vm2 "11.3.1 zonecheck team01.example (lab signatures: warn 20, critical 10 minutes): OK" \
    "sh /root/m11/tools/zonecheck.sh team01.example 192.0.2.53 192.0.2.10 1200 600; echo rc=\$?" \
    '^ZONECHECK OK: team01\.example, 1 server\(s\) at the parent, 1 in the zone$' \
    '^OK: ns1\.team01\.example\. \(192\.0\.2\.30\): serial [0-9]+, SOA signature expires in [0-9]+ minutes$' \
    '^OK: DS [0-9]+ matches a DNSKEY in the zone that signs the DNSKEY RRset$' '^OK: DNSKEY signature expires in [0-9]+ minutes$' '^rc=0$'
step vm2 "11.3.2 zonecheck manual01.example (default thresholds): the hand-signed zone has 29-30 days left" \
    "sh /root/m11/tools/zonecheck.sh manual01.example 192.0.2.53 192.0.2.10; echo rc=\$?" \
    '^ZONECHECK OK: manual01\.example' 'SOA signature expires in (29|30) days$' '^OK: DS [0-9]+ matches a DNSKEY' '^rc=0$'
step vm2 "11.3.3 the same check with a 31-day warning threshold is a WARNING (exit 1); bad thresholds are UNKNOWN (exit 3)" \
    "sh /root/m11/tools/zonecheck.sh manual01.example 192.0.2.53 192.0.2.10 2678400 259200 | head -2; sh /root/m11/tools/zonecheck.sh manual01.example 192.0.2.53 192.0.2.10 2678400 259200 >/dev/null; echo rc=\$?; sh /root/m11/tools/zonecheck.sh manual01.example 192.0.2.53 192.0.2.10 7d 3d; echo rc=\$?" \
    '^ZONECHECK WARNING: manual01\.example' '^WARNING: ns1\.manual01\.example\. .*expires in (29|30) days$' '^rc=1$' '^ZONECHECK UNKNOWN: WARN must be a number of seconds$' '^rc=3$'

echo "== Lab 11.4: incident drill"
ZC="sh /root/m11/tools/zonecheck.sh team01.example 192.0.2.53 192.0.2.10 1200 600"
step vm1 "11.4.1a instructor sets fault 1 (piped over SSH); a repeated set says the same; the output names nothing" \
    "sh -s -- set 1 01 < /kit/instructor/faults.sh; sh -s -- set 1 01 < /kit/instructor/faults.sh" '^fault set$' '!listen|127|options|already|choose'
step vm2 "11.4.1 fault 1: the probe of VM 1 fails and alerts; zonecheck: connection refused" \
    "$(poll "$(firing DNSProbeFailed 192.0.2.30)" 360)$ALERTS; $ZC; echo rc=\$?" \
    '^DNSProbeFailed 192\.0\.2\.30 firing' '^ZONECHECK CRITICAL' '^CRITICAL: ns1\.team01\.example\. \(192\.0\.2\.30\): connection refused$' '^rc=2$'
step vm1 "11.4.1b evidence on VM 1: named up, its counters fine, listening on loopback only" \
    "rndc status | grep 'server is up'; curl -s 127.0.0.1:8053/json/v1/server | jq -r '.\"boot-time\" != null'; ss -lnuH | awk '{print \$4}' | grep ':53\$' | sort -u; grep -n 'listen-on' \"$O\"" \
    '^server is up and running$' '^true$' '^127\.0\.0\.1:53$' '!^192\.0\.2\.30:53$' 'listen-on \{ 127\.0\.0\.1; \};'
on vm1 "sed -i '/listen-on { 127.0.0.1; };/d; /listen-on-v6 { ::1; };/d' \"$O\""
reconf vm1 "11.4.1c fix: the two listen-on lines removed, checked, reconfigured"
step vm2 "11.4.1d verified: zonecheck OK, the alert resolves (and Prometheus answered)" \
    "$(poll "! $(firing DNSProbeFailed 192.0.2.30)" 120)$ZC | head -1; $ALERTS; echo alerts-rc=\$?" \
    '^ZONECHECK OK' '!DNSProbeFailed 192\.0\.2\.30 firing' '^alerts-rc=0$'
step vm1 "11.4.1e VM 1's options byte-equal to the saved copy" "cmp \"$O\" \"$O.m09\" && echo same" '^same$'

step vm1 "11.4.2a instructor sets fault 2" "sh -s -- set 2 01 192.0.2.10 < /kit/instructor/faults.sh" '^fault set$' '!ns2|192\.0\.2\.10'
step vm2 "11.4.2 fault 2: zonecheck finds a lame second server and NS sets that differ; no Prometheus alert" \
    "$(poll "$ZC | grep -q 'ns2.team01.example'")$ZC; echo rc=\$?; $ALERTS; echo alerts-rc=\$?; dig @192.0.2.30 team01.example NS +short | sort; dig @192.0.2.10 team01.example SOA +norec | grep -o 'status: [A-Z]*'" \
    '^WARNING: NS sets differ: parent \[ns1\.team01\.example\.\] zone \[ns1\.team01\.example\. ns2\.team01\.example\.\]$' \
    '^CRITICAL: ns2\.team01\.example\. \(192\.0\.2\.10\): status: REFUSED$' '^rc=2$' '^alerts-rc=0$' '!(DNSProbeFailed|DNSSerialsDiffer) .* firing' \
    '^ns2\.team01\.example\.$' '^status: REFUSED$'
step vm1 "11.4.2b evidence on VM 1: the zone file has ns2 and a new serial" \
    "grep -nE '^(@|ns2)[[:space:]].*(NS|A)[[:space:]]' \"$Z\"; awk '/; serial/ { print \"serial\", \$1; exit }' \"$Z\"" \
    'NS ns2\.team01\.example\.' '^[0-9]+:ns2 IN A 192\.0\.2\.10$' '^serial 2026102732$'
on vm1 "sed -i '/^@ IN NS ns2\\.team01\\.example\\.\$/d; /^ns2 IN A /d' \"$Z\" && awk '/; serial/ && !d { sub(/[0-9]+/, \$1 + 1); d = 1 } { print }' \"$Z\" > \"$Z.new\" && cat \"$Z.new\" > \"$Z\" && rm \"$Z.new\" && named-checkzone -q team01.example \"$Z\" && rndc reload team01.example"
step vm2 "11.4.2c fixed (lines removed, serial raised, reload): zonecheck OK" \
    "$(poll "$ZC >/dev/null")$ZC; echo rc=\$?" '^ZONECHECK OK: team01\.example, 1 server\(s\) at the parent, 1 in the zone$' '^rc=0$'
step vm1 "11.4.2d the instructor's rescue (undo 2) after the team's fix: the saved zone, serial above the current one, loaded" \
    "sh -s -- undo 2 01 < /kit/instructor/faults.sh; awk '/; serial/ { print \"file\", \$1; exit }' \"$Z\"; $(poll "grep -q 'unsigned): loaded serial 2026102734' /var/log/named.out")grep -o 'unsigned): loaded serial 2026102734' /var/log/named.out | tail -1; grep -c '^ns2' \"$Z\"" \
    '^fault undone$' '^file 2026102734$' '^unsigned\): loaded serial 2026102734$' '^0$'

echo "== Lab 11.4: the faults' variants and the instructor's undo (rescue) paths"
step vm1 "11.4.v1 fault 1, variant acl: VM 1 refuses everyone but itself" \
    "sh -s -- set 1 01 acl < /kit/instructor/faults.sh; dig @192.0.2.30 team01.example SOA +norec | grep -o 'status: [A-Z]*'; dig @127.0.0.1 team01.example SOA +norec | grep -o 'status: [A-Z]*'" \
    '^fault set$' '!acl|allow'
step vm2 "11.4.v1b variant acl seen from VM 2: REFUSED, zonecheck CRITICAL" \
    "dig @192.0.2.30 team01.example SOA +norec | grep -o 'status: [A-Z]*'; $ZC; echo rc=\$?" \
    '^status: REFUSED$' '^CRITICAL: ns1\.team01\.example\. \(192\.0\.2\.30\): status: REFUSED$' '^rc=2$'
step vm1 "11.4.v1c undo 1: options back as saved" \
    "sh -s -- undo 1 01 < /kit/instructor/faults.sh; cmp \"$O\" \"$O.m09\" && echo same" '^fault undone$' '^same$'
step vm1 "11.4.v2 fault 2 with an unused address" "sh -s -- set 2 01 192.0.2.250 < /kit/instructor/faults.sh" '^fault set$'
step vm2 "11.4.v2b an unused address: zonecheck reports a time-out for ns2" \
    "$(poll "$ZC | grep -q 'ns2.team01.example'")$ZC; echo rc=\$?" \
    '^CRITICAL: ns2\.team01\.example\. \(192\.0\.2\.250\): (timed out|no servers could be reached)$' '^rc=2$'
step vm1 "11.4.v2c undo 2: ns2 gone, serial raised again" \
    "sh -s -- undo 2 01 < /kit/instructor/faults.sh; grep -c '^ns2' \"$Z\"; awk '/; serial/ { print \"file\", \$1; exit }' \"$Z\"" \
    '^fault undone$' '^0$' '^file 2026102736$'
out=$(cd "$INS" && COMPOSE="$INS_DC" sh "$KIT/instructor/ds-fault.sh" set 01 tag 2>&1); log "[11.4.v3] instructor\$ ds-fault.sh set 01 tag" "$out"
step vm2 "11.4.v3 fault 3, variant tag: zonecheck CRITICAL (no DNSKEY matches)" \
    "$(poll "$ZC | grep -q 'matches no DNSKEY'")$ZC; echo rc=\$?" '^CRITICAL: DS [0-9]+ at the parent matches no DNSKEY in the zone' '^rc=2$'
[ "$out" = "fault set" ] && ok "11.4.v3a ds-fault.sh set tag prints only 'fault set'" || bad "11.4.v3a ds-fault.sh set tag: $out"
out=$(cd "$INS" && COMPOSE="$INS_DC" sh "$KIT/instructor/ds-fault.sh" fix 01 2>&1); log "[11.4.v3c] instructor\$ ds-fault.sh fix 01" "$out"
[ "$out" = "DS replaced" ] && ok "11.4.v3c ds-fault.sh fix after the tag variant" || bad "11.4.v3c ds-fault.sh fix: $out"

out=$(cd "$INS" && COMPOSE="$INS_DC" sh "$KIT/instructor/ds-fault.sh" set 01 2>&1; cd "$INS" && "${DC[@]}" exec -T parent publish-ds --list | grep '^team01' ; cd "$INS" && COMPOSE="$INS_DC" sh "$KIT/instructor/ds-fault.sh" set 01 2>&1; cd "$INS" && "${DC[@]}" exec -T parent publish-ds --list | grep '^team01')
log "[11.4.3a] instructor\$ ds-fault.sh set 01 (twice), publish-ds --list after each" "$out"
if [ "$(grep -c '^fault set$' <<< "$out")" = 2 ] && [ "$(grep '^team01' <<< "$out" | sort -u | wc -l)" = 1 ]; then
    ok "11.4.3a instructor sets fault 3 at the registry, twice: the same wrong DS, only 'fault set' printed"
else bad "11.4.3a ds-fault.sh set (twice): $out"; fi
step vm2 "11.4.3 fault 3: SERVFAIL through the resolver once the DS TTL runs out; answers with +cd; zonecheck: DS matches no DNSKEY" \
    "t0=\$(date +%s); $(poll "dig @127.0.0.1 www.team01.example | grep -q 'status: SERVFAIL'" 240)echo \"SERVFAIL after \$((\$(date +%s) - t0)) s\"; dig @127.0.0.1 www.team01.example | grep -E 'status|EDE'; dig @127.0.0.1 www.team01.example +cd +short; dig @192.0.2.53 team01.example DS +noall +answer; $ZC; grep -E 'no valid signature found \(DS\)|broken trust chain' /var/log/named.out | tail -2" \
    'status: SERVFAIL' '^192\.0\.2\.80$' '^CRITICAL: DS [0-9]+ at the parent matches no DNSKEY in the zone' 'broken trust chain resolving .www\.team01\.example/A/IN.'
step vm1 "11.4.3b the team's correct DS, to send to the registry" \
    "dig @127.0.0.1 team01.example DNSKEY +noall +answer | dnssec-dsfromkey -2 -f - team01.example" \
    '^team01\.example\. IN DS [0-9]+ 13 2 [0-9A-F]{64}$'
out=$(cd "$INS" && COMPOSE="$INS_DC" sh "$KIT/instructor/ds-fault.sh" fix 01 2>&1); log "[11.4.3c] instructor\$ ds-fault.sh fix 01" "$out"
[ "$out" = "DS replaced" ] && ok "11.4.3c instructor replaces the DS" || bad "11.4.3c ds-fault.sh fix: $out"
step vm2 "11.4.3d verified: AD again once the bad DS leaves the cache; zonecheck OK" \
    "t0=\$(date +%s); $(poll "dig @127.0.0.1 www.team01.example +dnssec | grep -q 'flags: qr rd ra ad;'" 240)echo \"AD after \$((\$(date +%s) - t0)) s\"; dig @127.0.0.1 www.team01.example +dnssec | grep flags:; $ZC | head -1" \
    'flags: qr rd ra ad;' '^ZONECHECK OK'
step vm1 "11.4.3e instructor's clean after the drill: the saved copies deleted" \
    "sh -s -- clean 01 < /kit/instructor/faults.sh; ls -d /var/backups/m11 2>&1" '^cleaned$' 'No such file'

echo "== Lab 11.4: clean-up"
for s in prometheus prometheus-blackbox-exporter prometheus-bind-exporter; do svc vm2 stop "$s" || bad "stop $s on VM 2"; done
svc vm1 stop prometheus-bind-exporter || bad "stop the exporter on VM 1"
on vm2 "for f in prometheus prometheus-bind-exporter prometheus-blackbox-exporter; do mv /etc/default/\$f.m09 /etc/default/\$f; done; mv /etc/prometheus/prometheus.yml.m09 /etc/prometheus/prometheus.yml; mv /etc/prometheus/blackbox.yml.m09 /etc/prometheus/blackbox.yml; rm -f /etc/prometheus/dns-rules.yml /etc/prometheus/team-ca.crt; rm -rf /var/lib/prometheus/metrics2/*"
on vm1 "mv /etc/default/prometheus-bind-exporter.m09 /etc/default/prometheus-bind-exporter"
for v in vm1 vm2; do
    on "$v" "mv \"$L.m09\" \"$L\" && rm -f \"$O.m09\""
    reconf "$v" "11.4.4 $v: saved named.conf.local back (no statistics channel), checked, reconfigured"
done
# ENDSTATE: the same comparison on both VMs: named's three files, the
# Prometheus /etc/default files and Debian's two YAML files against the
# starting copies; then the leftovers counted with labels
ENDSTATE="for f in named.conf named.conf.local named.conf.options; do cmp /root/start/\$f /etc/bind/\$f || echo \"\$f differs\"; done; for f in /root/start/default/*; do cmp \$f /etc/default/\$(basename \$f) || echo \"\$f differs\"; done; for f in /root/start/prom/*; do cmp \$f /etc/prometheus/\$(basename \$f) || echo \"\$f differs\"; done; echo files-checked; echo tsdb=\$(ls -A /var/lib/prometheus/metrics2 | wc -l) left=\$(ls -d /etc/default/*.m09 /etc/prometheus/*.m09 /etc/prometheus/dns-rules.yml /etc/prometheus/team-ca.crt /etc/bind/*.m09 /var/backups/m11 2>/dev/null | wc -l) procs=\$(pgrep -cu prometheus); ss -lntuH | awk '{print \$5}' | grep -v '^127\\.0\\.0\\.11:' | sort -u"
step vm2 "11.4.5 end state VM 2: Module 9's files, ports 53/853/443 only, no Prometheus process, file or data, validates" \
    "$ENDSTATE; dig @127.0.0.1 www.team01.example +dnssec | grep flags:" \
    '^files-checked$' '!differs' '^tsdb=0 left=0 procs=0$' '^192\.0\.2\.10:53$' '^192\.0\.2\.10:853$' '^192\.0\.2\.10:443$' '!:(8053|9090|9115|9119)$' 'flags: qr rd ra ad;'
step vm1 "11.4.6 end state VM 1: Module 9's files, port 53 only, no saved fault copies; the zone with a higher serial and nothing else changed" \
    "$ENDSTATE; diff /root/start/db.team01.example \"$Z\" | grep '^[<>]'" \
    '^files-checked$' '!differs' '^tsdb=0 left=0 procs=0$' '^192\.0\.2\.30:53$' '!:(8053|9119)$' \
    '^< +2026102731 ; serial' '^> +2026102736 ; serial' '!^[<>] .*(ns2|NS)'
step vm2 "11.4.7 zonecheck after the clean-up: OK" "$ZC | head -1" '^ZONECHECK OK'

echo "== $pass passed, $fail failed; transcript: $OUT"
[ "$fail" -eq 0 ]
