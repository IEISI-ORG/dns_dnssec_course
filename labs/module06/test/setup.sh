#!/bin/sh
# Module 6 rehearsal: build a work directory from the classroom files.
# Usage: setup.sh WORKDIR
# Classroom files are used as written; only these are rewritten:
#   /etc/bind/ and /var/cache/bind -> WORKDIR/<server>/, /var/log/named/ -> WORKDIR/<server>/log/,
#   teamNN -> team01, "dnssec-validation auto" -> "no" (no Internet in the
#   namespace), and "localhost" in the resolver's ACL -> 127.0.0.1 (in the
#   namespace every lab address is a local address, so "localhost" would
#   match the neighbouring team too).
# Each server also gets harness-only lines: listen-on its own address,
# query/notify/transfer source address, pid file and an rndc channel.
set -eu
W=$1
L=$(cd "$(dirname "$0")/.." && pwd)
for s in reg auth res; do mkdir -p "$W/$s/log"; done
mkdir -p "$W/cap"

fix() { # fix SERVER FILE: rewrite classroom paths for SERVER
    sed -e "s#/etc/bind/#$W/$1/#g" -e "s#/var/cache/bind#$W/$1#g" \
        -e "s#/var/log/named/#$W/$1/log/#g" -e 's/teamNN/team01/g' \
        -e 's/dnssec-validation auto;/dnssec-validation no;   \/\/ harness: no Internet/' \
        -e 's/^    localhost;$/    127.0.0.1;   \/\/ harness: every lab address is local here/' "$2"
}
harness() { # harness SERVER ADDRESS: lines added inside options { }
    cat <<EOT
    listen-on { $2; }; listen-on-v6 { none; };
    query-source address $2; notify-source $2; transfer-source $2;
    pid-file "$W/$1/named.pid"; session-keyfile "$W/$1/session.key";
EOT
}
for s in reg auth res; do rndc-confgen -a -c "$W/$s/rndc.key" >/dev/null 2>&1; done
top() { # top SERVER ADDRESS: rndc channel
    echo "include \"$W/$1/rndc.key\";"
    echo "controls { inet $2 port 953 allow { any; } keys { \"rndc-key\"; }; };"
}

# Registry (instructor): example. and the RPZ feed
cat "$L/test/db.example" "$L/instructor/example.additions" > "$W/reg/db.example"
cp "$L/instructor/db.feed.rpz.test" "$W/reg/"
{ top reg 192.0.2.53
  echo "options {"; echo "    directory \"$W/reg\";"; echo "    recursion no;"; echo "    key-directory \"$W/reg\";"; harness reg 192.0.2.53; echo "};"
  # signed, as the classroom registry is (Module 7 uses its "lab" policy)
  echo "zone \"example\" { type primary; file \"$W/reg/db.example\"; dnssec-policy default; inline-signing yes; };"
  fix reg "$L/instructor/named.conf.module06"; } > "$W/reg/named.conf"

# Team zone file with the Module 6 additions
cat "$L/test/db.team01.example" > "$W/auth/db.team01.example"
sed 's/teamNN/team01/g' "$L/auth/db.additions" >> "$W/auth/db.team01.example"

# Debian's out-of-the-box configuration, for the "before" checks:
# options { directory "/var/cache/bind"; }; and the team zone
for s in auth:192.0.2.30 res:192.0.2.10; do n=${s%%:*}; a=${s#*:}
    { top $n $a; echo "options {"; echo "    directory \"$W/$n\";"; harness $n $a
      [ $n = res ] && echo "    dnssec-validation no;   // harness: no Internet"
      echo "};"
      [ $n = auth ] && echo "zone \"team01.example\" { type primary; file \"$W/auth/db.team01.example\"; };"
      [ $n = res ] && fix res "$L/resolver/named.conf.local"
    } > "$W/$n/default.conf"
done

# The trap: Debian's defaults plus allow-query { any; } (theory slide check)
sed 's/^    directory \(.*\)$/    directory \1\n    allow-query { any; };/' "$W/auth/default.conf" > "$W/auth/trap.conf"

# Module 6 configuration (Labs 6.1-6.3), classroom files
{ top auth 192.0.2.30
  fix auth "$L/auth/named.conf.options" > "$W/auth/named.conf.options"
  harness auth 192.0.2.30 > "$W/auth/h.txt"
  sed "/^options {/r $W/auth/h.txt" "$W/auth/named.conf.options"
  fix auth "$L/common/named.conf.logging"
  echo "zone \"team01.example\" { type primary; file \"$W/auth/db.team01.example\"; };"
} > "$W/auth/named.conf"
{ top res 192.0.2.10
  fix res "$L/resolver/named.conf.options" > "$W/res/named.conf.options"
  harness res 192.0.2.10 > "$W/res/h.txt"
  sed "/^options {/r $W/res/h.txt" "$W/res/named.conf.options"
  fix res "$L/common/named.conf.logging"
  fix res "$L/resolver/named.conf.local"
} > "$W/res/named.conf"

# Lab 6.4: TSIG. The key is made at run time with tsig-keygen, as in class,
# so these two files are checked by rehearse.sh, not here.
{ top auth 192.0.2.30
  sed "/^options {/r $W/auth/h.txt" "$W/auth/named.conf.options"
  fix auth "$L/common/named.conf.logging"
  echo "include \"$W/auth/team01-xfr.key\";"
  echo "zone \"team01.example\" { type primary; file \"$W/auth/db.team01.example\";"
  fix auth "$L/auth/zone-tsig.snippet"
  echo "};"
} > "$W/auth/tsig.conf"
{ cat "$W/res/named.conf"; fix res "$L/resolver/named.conf.secondary"; } > "$W/res/tsig.conf"

# Lab 6.5: RPZ (response-policy block pasted at the marker line)
fix res "$L/resolver/named.conf.rpz-options" > "$W/res/rpz-options.txt"
fix res "$L/resolver/db.local.rpz" > "$W/res/db.local.rpz"
{ top res 192.0.2.10
  sed -e "/^options {/r $W/res/h.txt" -e "/Lab 6.5: paste/r $W/res/rpz-options.txt" "$W/res/named.conf.options"
  fix res "$L/common/named.conf.logging"
  fix res "$L/resolver/named.conf.local"
  fix res "$L/resolver/named.conf.rpz"
} > "$W/res/rpz.conf"

named-checkzone -q example "$W/reg/db.example"
named-checkzone -q feed.rpz.test "$W/reg/db.feed.rpz.test"
named-checkzone -q team01.example "$W/auth/db.team01.example"
named-checkzone -q local.rpz "$W/res/db.local.rpz"
for f in reg/named.conf auth/default.conf auth/trap.conf res/default.conf auth/named.conf res/named.conf res/rpz.conf; do
    named-checkconf "$W/$f"
done
echo "setup OK: $W"
