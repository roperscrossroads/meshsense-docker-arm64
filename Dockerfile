# Use official Debian Bookworm base for ARM64
FROM arm64v8/debian:bookworm

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        wget \
        libfuse2 \
        fonts-noto-color-emoji \
        zlib1g-dev \
        libatk-bridge2.0-0 \
        libcups2 \
        libgdk-pixbuf-2.0-0 \
        libgtk-3-0 \
        libgbm1 \
        xvfb \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Create mesh user and add to dialout group for serial access
RUN groupadd -g 1000 mesh && \
    useradd --create-home --home-dir /home/mesh --uid 1000 --gid 1000 --groups dialout mesh

WORKDIR /home/mesh

# Download the Meshsense AppImage & extract it:
RUN wget https://affirmatech.com/download/meshsense/meshsense-beta-arm64.AppImage && \
    chmod +x meshsense-beta-arm64.AppImage && \
    ./meshsense-beta-arm64.AppImage --appimage-extract && \
    mv squashfs-root meshsense-app && \
    rm meshsense-beta-arm64.AppImage

# Copy entrypoint script
COPY entrypoint.sh /home/mesh/entrypoint.sh
RUN chown -R mesh:mesh /home/mesh && \
    chmod 0700 /home/mesh/entrypoint.sh

USER mesh
EXPOSE 5920

ENTRYPOINT ["/home/mesh/entrypoint.sh"]
