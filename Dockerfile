# Multi-stage build for Telegram MTProxy (https://github.com/TelegramMessenger/MTProxy)
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .

RUN make -j"$(nproc)"

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy

EXPOSE 443 8888

ENTRYPOINT ["/usr/local/bin/mtproto-proxy"]
CMD ["--help"]
