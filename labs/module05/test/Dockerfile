# A stand-in participant VM for test/rehearse.sh (used for both VM 1 and
# VM 2): Debian 13 with the packages of Modules 2-4 (bind9, bind9-utils,
# bind9-dnsutils, bind9-host, openssl, unbound, pdns-server,
# pdns-backend-sqlite3, sqlite3, curl, jq) plus Module 5's bird2, with
# iproute2 and procps (part of a standard Debian install, not of the slim
# image), installed with --no-install-recommends as the README's image rule
# says. No service is started here: rehearse.sh starts named as Module 4
# left it, and anycast-lab.sh starts BIRD inside its own namespaces. The
# postinst's rndc.key is removed (image-build rule in ../../module02/README.md);
# rehearse.sh makes each VM's key, as Modules 2 and 3 did in class.
# /root/.digrc: shorter dig timeouts, so a broken stack fails fast.
ARG DEBIAN_TAG=trixie-20261005-slim
FROM debian:${DEBIAN_TAG}
ARG DEBIAN_FRONTEND=noninteractive
# The base image's policy-rc.d (exit 101) keeps the postinsts from starting
# named, unbound, pdns or bird during the build (no session.key, no pid
# files in the image); stop if a base image ever lacks it.
RUN test -x /usr/sbin/policy-rc.d
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends \
        bind9 bind9-utils bind9-dnsutils bind9-host openssl \
        unbound pdns-server pdns-backend-sqlite3 sqlite3 curl jq \
        bird2 iproute2 procps \
 && /usr/libexec/unbound-helper root_trust_anchor_update \
 && rm -rf /var/lib/apt/lists/* /etc/bind/rndc.key \
 && printf '+time=3 +tries=2\n' > /root/.digrc
CMD ["sleep", "infinity"]
