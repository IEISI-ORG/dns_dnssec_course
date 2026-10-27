# A stand-in participant VM for test/rehearse.sh (used for both VM 1 and
# VM 2): Debian 13 with bind9, bind9-utils, bind9-dnsutils and bind9-host,
# as the VM image carries them from Module 2 on. named is not started here:
# rehearse.sh starts it, as the labs do with systemctl. The postinst's
# rndc.key is removed, as the image-build rule in ../../module02/README.md
# asks, so that Lab 3.1's rndc-confgen is tested from the classroom state.
# /root/.digrc: shorter dig timeouts, so a broken stack fails fast (steps that
# test a timeout give +time and +tries themselves).
ARG DEBIAN_TAG=trixie-20261005-slim
FROM debian:${DEBIAN_TAG}
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends \
        bind9 bind9-utils bind9-dnsutils bind9-host \
 && rm -rf /var/lib/apt/lists/* /etc/bind/rndc.key \
 && printf '+time=3 +tries=2\n' > /root/.digrc
CMD ["sleep", "infinity"]
