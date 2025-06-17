# Stage 1: Builder
FROM debian:bookworm AS builder

ARG TARGETARCH

# Install extraction dependencies only
RUN apt-get update && \
    apt-get install -y \
        wget \
        libfuse2 \
        zlib1g-dev \
        ca-certificates \
        bsdtar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Download and extract AppImage ONLY for arm64
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimage-extract -O appimage-extract && \
      chmod +x appimage-extract && \
      wget https://affirmatech.com/download/meshsense/meshsense-beta-arm64.AppImage && \
      chmod +x meshsense-beta-arm64.AppImage && \
      ./appimage-extract meshsense-beta-arm64.AppImage; \
    else \
      echo "Skipping AppImage extraction for $TARGETARCH"; \
    fi

# Stage 2: Runtime
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y \
        libfuse2 \
        fonts-noto-color-emoji \
        zlib1g-dev \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libgdk-pixbuf-2.0-0 \
        libgtk-3-0 \
        libgbm1 \
        xvfb \
        libnss3 \
        libasound2 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create mesh user and groups
RUN groupadd -g 1000 mesh && \
    useradd --create-home --home-dir /home/mesh --uid 1000 --gid 1000 --groups dialout mesh

# Copy extracted files from builder (will only exist for arm64)
COPY --from=builder --chown=mesh:mesh /tmp/squashfs-root /meshsense
RUN ln -sf /meshsense/meshsense /meshsense/app || true

RUN if [ -f /meshsense/chrome-sandbox ]; then \
      chown root:root /meshsense/chrome-sandbox && chmod 4755 /meshsense/chrome-sandbox; \
    fi

# Copy entrypoint script
COPY --chown=mesh:mesh entrypoint.sh /home/mesh/entrypoint.sh
RUN chmod 0700 /home/mesh/entrypoint.sh

# Final configuration
USER mesh
WORKDIR /meshsense
EXPOSE 5920
ENTRYPOINT ["/home/mesh/entrypoint.sh"]
