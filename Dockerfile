# Multi-stage build from this repo (fork of Telegram MTProxy).
#
# Final image matches what AmneziaVPN expects when deploying MTProxy:
# - mtproto-proxy in /usr/local/bin
# - /opt/amnezia/start.sh stub (Amnezia replaces it at deploy and runs configure_container + real start.sh)
# - /data volume for secret, proxy-secret, proxy-multi.conf
# - curl/openssl/hostname: server_scripts configure_container.sh and start.sh
#
# Build: docker build -t amneziavpn/mtproxy:local .
# Hub:  tag as amneziavpn/mtproxy:latest or :v2 after CI tests.

FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .

RUN make -j"$(nproc)" && \
    cp objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy

FROM debian:bookworm-slim

# openssl: configure_container.sh (openssl rand, hex check)
# curl + ca-certificates: Telegram config downloads + NAT IP in start.sh
# hostname: start.sh uses hostname -i for optional --nat-info
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libssl3 \
    openssl \
    hostname \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/mtproto-proxy /usr/local/bin/mtproto-proxy

RUN mkdir -p /opt/amnezia /data
RUN printf '#!/bin/sh\ntail -f /dev/null\n' > /opt/amnezia/start.sh && \
    chmod a+x /opt/amnezia/start.sh

# 443 = MTPROXY_PORT; 2398 = stats (see client/server_scripts/mtproxy/start.sh)
EXPOSE 443 2398

VOLUME /data
ENTRYPOINT ["/bin/sh", "/opt/amnezia/start.sh"]
CMD [""]
