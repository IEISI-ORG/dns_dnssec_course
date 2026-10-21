#!/bin/sh
# Module 8 lab: make a team CA and a resolver certificate (ECDSA P-256).
# Usage: make-certs.sh NN RESOLVER_IP [OUTDIR]
#   NN          team number, e.g. 03
#   RESOLVER_IP the address clients use for your resolver (it goes in the
#               certificate as an IP SAN, which DDR verified discovery needs)
#   OUTDIR      where to write the files (default: current directory)
# Writes: ca.key ca.crt resolver.key resolver.crt
# Private keys stay on the resolver VM. Never copy ca.key or resolver.key off it.
set -eu
NN=$1; IP=$2; OUT=${3:-.}
NAME="resolver.team$NN.example"
umask 077
cd "$OUT"

# 1. Team CA, valid 30 days
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout ca.key -out ca.crt -days 30 \
    -subj "/CN=Team $NN lab CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"

# 2. Resolver key and certificate: DNS name and IP address in subjectAltName
openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout resolver.key -out resolver.csr -subj "/CN=$NAME"
printf 'subjectAltName=DNS:%s,IP:%s\nextendedKeyUsage=serverAuth\nbasicConstraints=CA:FALSE\n' \
    "$NAME" "$IP" > resolver.ext
openssl x509 -req -in resolver.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 30 -out resolver.crt -extfile resolver.ext
rm -f resolver.csr resolver.ext ca.srl
chmod 644 ca.crt resolver.crt
openssl x509 -in resolver.crt -noout -subject -ext subjectAltName
