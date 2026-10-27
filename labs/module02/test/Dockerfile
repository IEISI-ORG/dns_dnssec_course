# A stand-in participant VM 1 for test/rehearse.sh: Debian 13 with
# bind9-dnsutils and bind9-host (Module 1's dig and host) plus what Module 2
# adds (bind9, bind9-utils, openssl).
# named is not started here: rehearse.sh starts it, as Lab 2.1 does.
ARG DEBIAN_TAG=trixie-20261005-slim
FROM debian:${DEBIAN_TAG}
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends \
        bind9 bind9-utils bind9-dnsutils bind9-host openssl \
 && rm -rf /var/lib/apt/lists/*
CMD ["sleep", "infinity"]
