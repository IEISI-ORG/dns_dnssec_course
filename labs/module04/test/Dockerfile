# A stand-in participant VM for test/rehearse.sh (used for both VM 1 and
# VM 2): Debian 13 with the Module 2-3 packages (bind9, bind9-utils,
# bind9-dnsutils, bind9-host, openssl) plus Module 4's: unbound,
# pdns-server, pdns-backend-sqlite3, sqlite3, curl and jq, installed with
# --no-install-recommends as the README's image rule says (pdns-server
# recommends pdns-backend-bind, whose pdns.d/bind.conf stops Lab 4.3).
# No service is
# started here: rehearse.sh starts named as Modules 2-3 left it, and the
# lab steps start unbound and pdns, as the VMs do with systemctl. The
# postinst's rndc.key is removed (image-build rule in ../../module02/README.md);
# rehearse.sh makes each VM's key, as Modules 2 and 3 did in class.
# unbound-helper writes /var/lib/unbound/root.key (the public root trust
# anchor), as the README's image rule does, so unbound-checkconf works on a
# VM where Unbound has never started (Module 8 Lab 8.3 on VM 1).
# /root/.digrc: shorter dig timeouts, so a broken stack fails fast.
ARG DEBIAN_TAG=trixie-20261005-slim
FROM debian:${DEBIAN_TAG}
ARG DEBIAN_FRONTEND=noninteractive
# The base image's policy-rc.d (exit 101) keeps the postinsts from starting
# named, unbound or pdns during the build (no session.key, no pid files in
# the image); stop if a base image ever lacks it.
RUN test -x /usr/sbin/policy-rc.d
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends \
        bind9 bind9-utils bind9-dnsutils bind9-host openssl \
        unbound pdns-server pdns-backend-sqlite3 sqlite3 curl jq \
 && /usr/libexec/unbound-helper root_trust_anchor_update \
 && rm -rf /var/lib/apt/lists/* /etc/bind/rndc.key \
 && printf '+time=3 +tries=2\n' > /root/.digrc
CMD ["sleep", "infinity"]
