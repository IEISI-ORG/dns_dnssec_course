# A stand-in participant VM for test/rehearse.sh (used for both VM 1 and
# VM 2): Debian 13 with the DNS packages of Modules 2-8 that Module 11 uses
# (bind9, bind9-utils, bind9-dnsutils, dnsperf, knot-dnsutils, openssl,
# curl, jq, tcpdump, tshark) plus Module 11's prometheus,
# prometheus-bind-exporter and prometheus-blackbox-exporter, with iproute2
# and procps (part of a standard Debian install, not of the slim image), all
# with --no-install-recommends as the README's image rule says (that keeps
# out prometheus-node-exporter, which prometheus only recommends). No
# service is started here: rehearse.sh starts named as Module 9 left it and
# starts the exporters and Prometheus as Lab 11.2 does. The postinst's
# rndc.key is removed (image-build rule in ../../module02/README.md);
# rehearse.sh makes each VM's key. /root/.digrc: shorter dig timeouts, so a
# broken stack fails fast.
ARG DEBIAN_TAG=trixie-20261005-slim
FROM debian:${DEBIAN_TAG}
ARG DEBIAN_FRONTEND=noninteractive
# The base image's policy-rc.d (exit 101) keeps the postinsts from starting
# named or the Prometheus services during the build (no session.key, no pid
# files, no TSDB in the image); stop if a base image ever lacks it.
RUN test -x /usr/sbin/policy-rc.d
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends \
        bind9 bind9-utils bind9-dnsutils bind9-host dnsperf knot-dnsutils \
        openssl curl jq tcpdump tshark \
        prometheus prometheus-bind-exporter prometheus-blackbox-exporter \
        iproute2 procps \
 && rm -rf /var/lib/apt/lists/* /etc/bind/rndc.key \
 && printf '+time=3 +tries=2\n' > /root/.digrc
CMD ["sleep", "infinity"]
