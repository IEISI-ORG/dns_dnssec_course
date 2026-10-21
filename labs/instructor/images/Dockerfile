# Instructor services on Debian 13 packages, the same versions the labs use.
# Targets: bind (parent registry server, init, test team), knot (DoQ demo), client (tests).
ARG DEBIAN_TAG=trixie-20261005-slim

FROM debian:${DEBIAN_TAG} AS base
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends ca-certificates openssl \
 && rm -rf /var/lib/apt/lists/*

FROM base AS bind
RUN apt-get update \
 && apt-get -y install --no-install-recommends bind9 bind9-utils bind9-dnsutils \
 && rm -rf /var/lib/apt/lists/*
COPY bind/ /opt/lab/bin/
RUN chmod 0755 /opt/lab/bin/* && ln -s /opt/lab/bin/publish-ds /usr/local/bin/publish-ds
CMD ["named", "-g", "-u", "bind", "-c", "/etc/lab/named.conf"]

FROM base AS knot
RUN apt-get update \
 && apt-get -y install --no-install-recommends knot \
 && rm -rf /var/lib/apt/lists/*
COPY knot/ /opt/lab/bin/
RUN chmod 0755 /opt/lab/bin/*
CMD ["/opt/lab/bin/knot-run"]

FROM base AS client
RUN apt-get update \
 && apt-get -y install --no-install-recommends bind9-dnsutils knot-dnsutils \
 && rm -rf /var/lib/apt/lists/*
