#!/bin/bash
# rehearse-pair.sh A B: run every Module 9 lab step for teams A and B (partners),
# as the instructor's dry run. Needs EPP_HOST, EPP_PORT, EPP_CA, and for each team
# NN the files certs/regNN.crt + certs/regNN.key and password Lab-pass-NN, plus
# KSK files in keys/ (Kteam<NN>.example.+013+*.key) for the DS step.
# Writes one transcript per step to out/. Run from the m09_lab directory.
set -euo pipefail
A=$1; B=$2; X=xml; O=out; mkdir -p $O
send() { local t=$1; shift
  TEAM=$t EPP_PW=Lab-pass-$t EPP_CERT=certs/reg$t.crt EPP_KEY=certs/reg$t.key ./epp-send "$@"; }
codes() { grep -o 'result code="[0-9]*"\|avail="[01]"\|rgpStatus s="[A-Za-z]*"\|trStatus>[A-Za-z]*' "$1" | tr '\n' ' '; echo; }
for t in $A $B; do p=$([ $t = $A ] && echo $B || echo $A)
  send $t $X/01-hello.xml > $O/91-$t-hello.txt
  PARTNER=$p send $t $X/02-login.xml $X/10-domain-check.xml $X/11-contact-create.xml $X/12-domain-create.xml \
    $X/13-host-create.xml $X/14-host-create-external.xml $X/15-domain-update-ns.xml $X/16-domain-info.xml \
    $X/17-host-info.xml $X/03-logout.xml > $O/92-$t-objects.txt
  read -r tag alg dt dig < <(dnssec-dsfromkey -2 keys/Kteam$t.example.+013+*.key | awk '{print $4, $5, $6, $7}')
  sed -e "s#<secDNS:keyTag>[0-9]*<#<secDNS:keyTag>$tag<#" -e "s#<secDNS:alg>[0-9]*<#<secDNS:alg>$alg<#" \
      -e "s#<secDNS:digestType>[0-9]*<#<secDNS:digestType>$dt<#" -e "s#<secDNS:digest>[0-9A-F]*<#<secDNS:digest>$dig<#" \
      $X/20-domain-update-ds-add.xml > $O/20-ds-$t.xml
  send $t $X/02-login.xml $O/20-ds-$t.xml $X/16-domain-info.xml $X/03-logout.xml > $O/93-$t-ds.txt
done
for pair in "$A $B" "$B $A"; do set -- $pair; lose=$1; gain=$2
  AUTHINFO=$(openssl rand -base64 18)
  AUTHINFO=$AUTHINFO send $lose $X/02-login.xml $X/35-domain-update-authinfo.xml $X/03-logout.xml > $O/94a-$lose-code.txt
  AUTHINFO=$AUTHINFO PARTNER=$lose send $gain $X/02-login.xml $X/30-domain-transfer-request.xml \
    $X/31-domain-transfer-query.xml $X/03-logout.xml > $O/94b-$gain-request.txt
  send $lose $X/02-login.xml $X/32-poll-req.xml $X/33-domain-transfer-approve.xml $X/03-logout.xml > $O/94c-$lose-approve.txt
  msg=$(grep -o 'msgQ count="[0-9]*" id="[0-9]*"' $O/94c-$lose-approve.txt | head -1 | sed 's/.*id="//; s/"//')
  MSGID=$msg send $lose $X/02-login.xml $X/34-poll-ack.xml $X/03-logout.xml > $O/94d-$lose-ack.txt
  PARTNER=$lose send $gain $X/02-login.xml $X/36-domain-info-partner.xml $X/03-logout.xml > $O/94e-$gain-info.txt
  exp=$(grep -o '<domain:exDate>[0-9-]*' $O/94e-$gain-info.txt | head -1 | sed 's/.*>//')
  CUREXPDATE=$exp PARTNER=$lose send $gain $X/02-login.xml $X/37-domain-renew.xml $X/03-logout.xml > $O/94f-$gain-renew.txt
done
for t in $A $B; do
  send $t $X/02-login.xml $X/50-domain-create-spare.xml $X/51-domain-delete-spare.xml $X/52-domain-check-spare.xml \
    $X/03-logout.xml > $O/95a-$t-agp.txt
  send $t $X/02-login.xml $X/53-domain-delete-old.xml $X/54-domain-info-old.xml $X/55-rgp-restore-request.xml \
    $X/54-domain-info-old.xml $X/03-logout.xml > $O/95b-$t-rgp.txt
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  DELTIME=$now RESTIME=$now send $t $X/02-login.xml $X/56-rgp-restore-report.xml $X/54-domain-info-old.xml \
    $X/03-logout.xml > $O/95c-$t-report.txt
done
for f in $O/9*.txt; do printf '%-22s %s\n' "$(basename $f .txt)" "$(codes $f)"; done
