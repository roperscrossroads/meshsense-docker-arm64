# Stage 1: Builder (explicit ARM64)
FROM debian:bookworm AS builder

ARG NATIVEBUILD=false
ENV NATIVEBUILD=${NATIVEBUILD}
ENV APPIMAGE=meshsense-beta-arm64.AppImage
ENV APPIMAGE_URL=https://affirmatech.com/download/meshsense/meshsense-beta-arm64.AppImage
ENV APPIMAGE_SHA256=b31702d980864f10a007fcc38edf12fcfdbfdcae9cdf0a46b68a4c9885170381
ENV KNOWN_OFFSET=197808

RUN apt-get update && \
    apt-get install -y wget libfuse2 ca-certificates squashfs-tools && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN wget $APPIMAGE_URL && \
    echo "$APPIMAGE_SHA256  $APPIMAGE" | sha256sum -c - && \
    if [ "$NATIVEBUILD" = "true" ]; then \
        chmod +x $APPIMAGE && \
        ./$APPIMAGE --appimage-extract; \
    else \
        dd if=$APPIMAGE of=fs.squashfs bs=1 skip=$KNOWN_OFFSET && \
        if ! unsquashfs -d squashfs-root fs.squashfs; then \
            echo "First extraction failed, installing binwalk to find offset..."; \
            apt-get update && apt-get install -y --no-install-recommends binwalk python3 && \
            OFFSET=$(binwalk -y 'squashfs' $APPIMAGE | awk '/Squashfs filesystem/ {print $1; exit}'); \
            if [ -z "$OFFSET" ]; then echo "Could not find SquashFS offset"; exit 1; fi; \
            dd if=$APPIMAGE of=fs.squashfs bs=1 skip=$OFFSET && \
            unsquashfs -d squashfs-root fs.squashfs; \
        fi; \
    fi


# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y \
        libfuse2 \
        fonts-noto-color-emoji \
        zlib1g \
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

RUN groupadd -g 1000 mesh && \
    useradd --create-home --home-dir /home/mesh --uid 1000 --gid 1000 --groups dialout mesh

COPY --from=builder --chown=mesh:mesh /tmp/squashfs-root /meshsense
RUN ln -s /meshsense/meshsense /meshsense/app && \
    chown root:root /meshsense/chrome-sandbox && \
    chmod 4755 /meshsense/chrome-sandbox

COPY --chown=mesh:mesh entrypoint.sh /home/mesh/entrypoint.sh
RUN chmod 0700 /home/mesh/entrypoint.sh

USER mesh
WORKDIR /meshsense
EXPOSE 5920 5921
ENTRYPOINT ["/home/mesh/entrypoint.sh"]
