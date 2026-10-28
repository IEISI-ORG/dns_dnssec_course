#!/bin/sh
# rates.sh [SECONDS [URL]]: Module 11, Lab 11.1. Read BIND's counters from
# the statistics channel twice, SECONDS apart (default 10), and print what
# happened per second in between. Counters only ever grow (until named
# restarts), so a single reading says little; the difference is the rate.
# URL defaults to the channel the kit sets up: http://127.0.0.1:8053.
# Needs curl and jq.
set -eu
S=${1:-10}
case $S in ''|*[!0-9]*|0) echo "rates.sh: SECONDS must be a whole number above 0" >&2; exit 2 ;; esac
U=${2:-http://127.0.0.1:8053}/json/v1/server
pick='{
  queries:   (.opcodes.QUERY // 0),
  NOERROR:   (.rcodes.NOERROR // 0),
  NXDOMAIN:  (.rcodes.NXDOMAIN // 0),
  SERVFAIL:  (.rcodes.SERVFAIL // 0),
  REFUSED:   (.rcodes.REFUSED // 0),
  recursion: (.nsstats.QryRecursion // 0),
  rrl_drop:  (.nsstats.RateDropped // 0),
  rrl_slip:  (.nsstats.RateSlipped // 0),
  hits:      (.views._default.resolver.cachestats.QueryHits // 0),
  misses:    (.views._default.resolver.cachestats.QueryMisses // 0)
}'
# read_stats: one reading as compact JSON; stops the script if the channel
# does not answer
read_stats() {
    j=$(curl -sf "$U") || { echo "rates.sh: no statistics channel at $U" >&2; exit 1; }
    printf '%s\n' "$j" | jq -c "$pick"
}
a=$(read_stats)
sleep "$S"
b=$(read_stats)
jq -rn --argjson a "$a" --argjson b "$b" --argjson s "$S" '
  if $b.queries < $a.queries then "counters went down: named restarted between the readings; run again"
  else
  def r(k): (($b[k] - $a[k]) / $s * 10 | round) / 10;
  ($b.hits - $a.hits) as $h | ($b.misses - $a.misses) as $m |
  "over \($s) s, per second:",
  ( ["queries","NOERROR","NXDOMAIN","SERVFAIL","REFUSED","recursion","rrl_drop","rrl_slip"][]
    | "  \(.) \(r(.))" ),
  "  cache hit ratio (client queries): " +
    (if $h + $m == 0 then "no cache lookups" else "\(($h * 100 / ($h + $m)) | round)%  (\($h) hits, \($m) misses)" end)
  end'
