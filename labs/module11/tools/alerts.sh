#!/bin/sh
# alerts.sh [URL]: Module 11, Labs 11.2-11.4. The alerts Prometheus holds
# now, one per line: name, instance, state (pending or firing) and since
# when. Nothing printed and exit 0: no alert is pending or firing. Exit 2:
# Prometheus did not answer (then nothing is known about the alerts). URL
# defaults to Prometheus on this VM. Needs curl and jq.
set -eu
U=${1:-http://127.0.0.1:9090}
j=$(curl -sf "$U/api/v1/alerts") || { echo "alerts.sh: no answer from Prometheus at $U" >&2; exit 2; }
printf '%s\n' "$j" \
  | jq -r '.data.alerts[] | "\(.labels.alertname) \(.labels.instance // "-") \(.state) since \(.activeAt[0:19])Z"' \
  | sort
