ARG BASE_VERSION=15
FROM ghcr.io/daemonless/base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="ca_root_nss"
ARG UPSTREAM_URL="https://api.github.com/repos/traefik/traefik/releases/latest"
ARG UPSTREAM_JQ=".tag_name"

LABEL org.opencontainers.image.title="Traefik" \
    org.opencontainers.image.description="Traefik reverse proxy on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/traefik" \
    org.opencontainers.image.url="https://traefik.io/" \
    org.opencontainers.image.documentation="https://doc.traefik.io/traefik/" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="80,443,8080" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.category="Infrastructure" \
    io.daemonless.upstream-url="${UPSTREAM_URL}" \
    io.daemonless.upstream-jq="${UPSTREAM_JQ}" \
    io.daemonless.packages="${PACKAGES}"

# Install ca_root_nss for HTTPS backends
RUN pkg update && \
    pkg install -y ${PACKAGES} && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Download and install Traefik
RUN TRAEFIK_VERSION=$(fetch -qo - "${UPSTREAM_URL}" | \
    jq -r "${UPSTREAM_JQ}") && \
    echo "Installing Traefik $TRAEFIK_VERSION" && \
    fetch -qo /tmp/traefik.tar.gz "https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_freebsd_amd64.tar.gz" && \
    mkdir -p /usr/local/bin && \
    tar xzf /tmp/traefik.tar.gz -C /usr/local/bin traefik && \
    chmod +x /usr/local/bin/traefik && \
    mkdir -p /app && echo "$TRAEFIK_VERSION" > /app/version && \
    rm /tmp/traefik.tar.gz

# Create traefik user

# Create directories
RUN mkdir -p /config /config/dynamic /config/letsencrypt && \
    chown -R bsd:bsd /config

COPY root/ /

RUN chmod +x /healthz /etc/services.d/traefik/run /etc/cont-init.d/* 2>/dev/null || true

RUN mkdir -p /run/s6/services/traefik && \
    ln -sf /etc/services.d/traefik/run /run/s6/services/traefik/run

EXPOSE 80 443 8080

VOLUME /config


