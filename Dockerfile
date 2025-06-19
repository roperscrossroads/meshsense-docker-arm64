# Stage 1: Builder
FROM node:23-bookworm-slim AS builder

ARG NATIVEBUILD=false
ENV NATIVEBUILD=${NATIVEBUILD}

RUN apt-get update && apt-get install -y libdbus-1-3 git && rm -rf /var/lib/apt/lists/*

WORKDIR /meshsense

RUN git clone https://github.com/Affirmatech/MeshSense.git .

WORKDIR /meshsense/api
RUN npm install --omit=dev

WORKDIR /meshsense/ui
RUN npm install --omit=dev

# Stage 2: Runtime
FROM node:23-bookworm-slim

RUN apt-get update && \
    apt-get install -y \
        fonts-noto-color-emoji \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libgdk-pixbuf-2.0-0 \
        libgtk-3-0 \
        libgbm1 \
        xvfb \
        libnss3 \
        libasound2 \
        dbus \
        dumb-init \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Add node user to dialout group for Bluetooth permissions
RUN usermod -aG dialout node

# Create custom home directory
RUN mkdir -p /home/mesh && chown node:node /home/mesh

# Copy app as node user
COPY --from=builder --chown=node:node /meshsense /meshsense

# Configure DBus with unique machine ID
RUN mkdir -p /var/run/dbus && \
    chown node:node /var/run/dbus && \
    dbus-uuidgen > /var/lib/dbus/machine-id

# Security: Remove setuid from chrome-sandbox if exists
RUN if [ -f /meshsense/chrome-sandbox ]; then \
        chmod 0755 /meshsense/chrome-sandbox; \
    fi

USER node
WORKDIR /meshsense
EXPOSE 5920

ENTRYPOINT ["dumb-init", "--"]
CMD ["sh", "-c", "dbus-daemon --system --fork && node /meshsense/api/dist/index.cjs --headless --disable-gpu --in-process-gpu --disable-software-rasterizer"]
