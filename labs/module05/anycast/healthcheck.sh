#!/bin/sh
# healthcheck.sh SITE: runs inside the site's namespace (anycast-lab.sh
# installs it in /usr/local/lib/m05-anycast, because Debian mounts /run
# noexec, and starts it). Every second it asks this site's named for the SOA of
# svc.test on the anycast address. While the answer is NOERROR the site's
# BIRD announces 198.51.100.53/32 (static protocol "svc" enabled);
# otherwise the route is withdrawn. It sets the state on every round, so a
# BIRD reconfiguration cannot leave it wrong for more than a second, and
# logs each change with the time.
site=$1
sock=/run/m05-anycast/$site.ctl
log=/run/m05-anycast/$site-health.log
state=unknown
echo "$(date +%T) site $site: health check started (pid $$)" >> "$log"
while :; do
    if dig @198.51.100.53 svc.test SOA +norec +time=1 +tries=1 2>/dev/null | grep -q 'status: NOERROR'; then
        new=up; action=enable; what=announced
    else
        new=down; action=disable; what=withdrawn
    fi
    if birdc -s "$sock" "$action" svc >/dev/null 2>&1 && [ "$new" != "$state" ]; then
        echo "$(date +%T) site $site: named $new, route $what" >> "$log"
        state=$new
    fi
    sleep 1
done
