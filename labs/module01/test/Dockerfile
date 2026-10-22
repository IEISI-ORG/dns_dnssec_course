# A stand-in participant VM for test/rehearse.sh: Debian 13 with the Module 1
# client tools only (no DNS server), as the authoritative VM is on Day 1.
ARG DEBIAN_TAG=trixie-20261005-slim
FROM debian:${DEBIAN_TAG}
RUN apt-get update \
 && apt-get -y upgrade \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
        bind9-dnsutils bind9-host tcpdump tshark \
 && rm -rf /var/lib/apt/lists/*
CMD ["sleep", "infinity"]
