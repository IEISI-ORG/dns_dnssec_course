#!/bin/sh
# Module 11, Lab 11.4 fault 3 (instructor only): a wrong DS for teamNN.example
# at the registry, as after a mistyped DS submission. Run it on the
# instructor server, in labs/instructor (the Compose project directory):
#   sh ../module11/instructor/ds-fault.sh set NN [digest|tag]
#       variant digest (default): the team's DS with its last digest digit
#       changed; variant tag: the right digest under a wrong key tag
#   sh ../module11/instructor/ds-fault.sh fix NN
#       the DS again from the team's DNSKEY (what a registry does with the
#       team's corrected submission)
# Both work from the DNSKEY RRset the team's server publishes now, so a
# repeated "set" sets the same wrong DS. COMPOSE overrides the Compose
# command (the test harness passes its project and files). Prints only
# "fault set" or "DS replaced".
set -eu
usage() { echo "usage: ds-fault.sh set NN [digest|tag] | fix NN" >&2; exit 2; }
[ $# -ge 2 ] || usage
act=$1; NN=$2; v=${3:-digest}
case $NN in [0-9][0-9]) ;; *) echo "NN must be two digits" >&2; exit 2 ;; esac
Z=team$NN.example
P="${COMPOSE:-docker compose} exec -T parent"
# the team's DNSKEY RRset, asked from the team's address in teams.conf
KEYS="a=\$(awk '\$1 == \"$NN\" { print \$2 }' /etc/lab-classroom/teams.conf); dig @\$a +norec +noall +answer $Z DNSKEY"
case $act in
set)
    good=$($P sh -c "$KEYS | dnssec-dsfromkey -2 -f - $Z" | head -1)
    [ -n "$good" ] || { echo "no DNSKEY from team $NN" >&2; exit 1; }
    case $v in
    digest) bad=$(echo "$good" | awk '{ d = $NF; c = substr(d, length(d)); $NF = substr(d, 1, length(d) - 1) ((c == "0") ? "1" : "0"); print }') ;;
    tag)    bad=$(echo "$good" | awk '{ $4 = ($4 + 1) % 65536; print }') ;;
    *) usage ;;
    esac
    echo "$bad" | $P publish-ds "$Z" >/dev/null
    echo "fault set"
    ;;
fix)
    $P sh -c "$KEYS | publish-ds $Z" >/dev/null
    echo "DS replaced"
    ;;
*)
    usage
    ;;
esac
