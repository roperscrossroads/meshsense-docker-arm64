# MeshSense Docker Compose for ARM64 & x86-64

This project builds Docker containers for [MeshSense](https://affirmatech.com/meshsense) for multiple architectures (ARM64 and x86-64) that can easily be run on various platforms including 64-bit Raspberry Pi boards (RPI3/4/5), Intel/AMD systems, and other ARM64/x86-64 compatible hardware. It can be built locally but that takes a while so I would recommend starting with the automated build. If you have Docker installed, you can run MeshSense with a single command.

Please hop in the [CSRA Mesh Discord](https://discord.com/invite/mgzj2PmhKf), the [Middle GA Mesh Discord](https://discord.com/invite/6cSJ738Prp) or the [Mountain Mesh Discord](https://discord.gg/4WN32RHGSs) if you get it going and have an questions.

Thanks to [@dB-SPL](https://github.com/dB-SPL) for doing an writeup for the [CSRA Mesh](http://csramesh.org) to get this started.

## Testing Status

| Platform | Device | Runs | IP | Bluetooth |
|----------|--------|------|------|-----------|
| ARM64    | RPI3   | ✅   | ✅ | ❌ Internal BT is unreliable |
| ARM64    | RPI4   | ✅   | ✅ | ✅ |
| ARM64    | RPI5   | ✅   | ✅ | ⏳ Untested |
| x86-64   | Intel/AMD PCs | ✅ | ✅ | ⏳ Untested |

- Verified on RPI3 with Raspberry Pi OS 64-bit (Debian Bookworm)
- Verified on RPI4 with Raspberry Pi OS 64-bit (Debian Bookworm)
- Verified on RPI5 with Raspberry Pi OS 64-bit (Debian Bookworm)
- x86-64 support tested on Windows 11
- **Automated test suite available in `tests/` directory.**

---

## Quickstart: Run Pre-Built from GitHub

### Prerequisites

- **ARM64 systems**: Raspberry Pi 3/4/5 running Raspberry Pi OS 64-bit (Bookworm or newer)
- **x86-64 systems**: Any Intel/AMD-based Linux system with Docker support
- **Internet connection & Docker and Docker Compose installed**

### Debian & Ubuntu: Install Docker & Docker Compose

You can **use the provided [`install-docker.sh`](https://github.com/roperscrossroads/meshsense-docker-arm64/blob/main/install-docker.sh) script**

```
sudo apt update
sudo apt install -y wget
wget https://github.com/roperscrossroads/meshsense-docker-arm64/raw/main/install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
newgrp docker
```

### Launch MeshSense (Docker Run Command)

#### **Linux / macOS**

You can use the following **multi-line command** (with backslashes for line continuation):

```bash
docker run --name meshsense \
-p 5920:5920 \
-e PORT=5920 \
-e HOST=0.0.0.0 \
-e ACCESS_KEY=changeme \
-e DISPLAY=:99 \
--cap-add NET_ADMIN \
-v meshsense-data:/home/mesh/.meshsense \
-v /run/dbus:/run/dbus:ro \
--restart unless-stopped \
--user 1000:1000 \
--label project=meshsense \
ghcr.io/roperscrossroads/meshsense-docker-arm64:main
```

Or as a **single line**:

```bash
docker run --name meshsense -p 5920:5920 -e PORT=5920 -e HOST=0.0.0.0 -e ACCESS_KEY=changeme -e DISPLAY=:99 --cap-add NET_ADMIN -v meshsense-data:/home/mesh/.meshsense -v /run/dbus:/run/dbus:ro --restart unless-stopped --user 1000:1000 --label project=meshsense ghcr.io/roperscrossroads/meshsense-docker-arm64:main
```

#### **Windows (Command Prompt / PowerShell)**

Copy and paste the following **single-line command**—no backslashes, no line breaks:

```powershell
docker run --name meshsense -p 5920:5920 -e PORT=5920 -e HOST=0.0.0.0 -e ACCESS_KEY=changeme -e DISPLAY=:99 --cap-add NET_ADMIN -v meshsense-data:/home/mesh/.meshsense -v /run/dbus:/run/dbus:ro --restart unless-stopped --user 1000:1000 --label project=meshsense ghcr.io/roperscrossroads/meshsense-docker-arm64:main
```

**Notes:**
- On Windows, you must use Docker Desktop.
- If you want to mount a folder from your computer instead of a named volume, adjust the `-v` option. Example:  
  `-v C:\path\to\data:/home/mesh/.meshsense`
- Replace `changeme` in `-e ACCESS_KEY=changeme` with your own secure access key.

---

The service will be accessible at [http://your-device-ip:5920/](http://your-device-ip:5920/).
Docker will automatically select the correct image for your platform (ARM64 or x86-64).


- It will be accessible at http://your-device-ip:5920/
- Docker will automatically pull the correct image for your platform (ARM64 or x86-64)
- See below for info on how to pair bluetooth devices.
- Tested on RPI3 and RPI4, should work on RPI5 and x86-64 systems.
- RPI3 internal bluetooth might not be reliable.

---

## Linux: Pair and Connect with `bluetoothctl`

You must do the following on the host for the Docker container to access Meshtastic devices via Bluetooth:

1. Start bluetoothctl:
   ```bash
   bluetoothctl
   ```
2. Power on the adapter:
   ```
   power on
   ```
3. Enable agent and set as default:
   ```
   agent on
   default-agent
   ```
4. Scan for devices:
   ```
   scan on
   ```
   *Wait for your device to appear and note its MAC address (e.g., `00:1D:43:6D:03:26`).*
5. Pair:
   ```
   pair 00:1D:43:6D:03:26
   ```
6. Trust:
   ```
   trust 00:1D:43:6D:03:26
   ```
7. Connect:
   ```
   connect 00:1D:43:6D:03:26
   ```
8. (Optional) Stop scanning and exit:
   ```
   scan off
   exit
   ```

## Build & Run Locally

Building locally will work on both ARM64 and x86-64 systems. This took a while to build on an RPI3 (35-40 minutes), but will be faster on x86-64 systems.

```bash
git clone https://github.com/roperscrossroads/meshsense-docker-arm64.git
cd meshsense-docker-arm64
chmod +x install-docker.sh
./install-docker.sh
newgrp docker
sed -i "s/ACCESS_KEY=changeme/ACCESS_KEY=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c16)/" docker-compose.yml
docker compose build
docker compose up
```

The build process will automatically detect your platform and build the appropriate image.

Once everything works, run it detached from the terminal:

```bash
docker compose up -d
```

---

## Multi-Platform Build Information

This repository now supports building for both ARM64 and x86-64 architectures using Docker buildx:

### Automatic Platform Selection
- Docker automatically selects the correct image for your platform when pulling from the registry
- No special configuration needed - just use the standard `docker run` command

### Manual Multi-Platform Building
If you want to build for multiple platforms manually:

```bash
# Set up buildx for cross-platform builds
docker buildx create --name cross-platform --driver docker-container --bootstrap
docker buildx use cross-platform

# Build for both platforms
docker buildx build --platform linux/arm64,linux/amd64 -t your-tag:latest .

# Build and push to registry for both platforms
docker buildx build --platform linux/arm64,linux/amd64 -t your-tag:latest --push .
```

### Supported Platforms
- `linux/arm64` - For Raspberry Pi, Apple Silicon, and other ARM64 devices
- `linux/amd64` - For Intel/AMD x86-64 systems

---

## Testing

A comprehensive test suite is available to verify multi-platform functionality:

See [`tests/README.md`](tests/README.md) for detailed testing documentation.

---

## Useful Docker Commands

| Command                                                      | Description                                                            |
|--------------------------------------------------------------|------------------------------------------------------------------------|
| `docker compose ps`                                          | List running containers                                                |
| `docker compose build`                                       | Build the image(s)                                                     |
| `docker compose up -d`                                       | Start all services in the background                                   |
| `docker compose stop`                                        | Stop all running containers                                            |
| `docker compose start`                                       | Start previously stopped containers                                    |
| `docker compose restart`                                     | Restart all services                                                   |
| `docker compose up -d --build --force-recreate`              | Rebuild and re-create all containers                                   |
| `docker compose down`                                        | Stop and remove containers, networks, and default volumes              |
| `docker compose logs`                                        | View logs for all services                                             |
| `docker compose logs -f`                                     | Follow logs for all services (live tail)                               |
| `docker compose logs `                              | View logs for a specific service (e.g., `meshsense-webui`)             |
| `docker compose start `                             | Start a specific service                                               |
| `docker compose stop `                              | Stop a specific service                                                |
| `docker compose restart `                           | Restart a specific service                                             |
| `docker compose exec  `                    | Run a command in a running service container (e.g., `bash`)            |
| `docker compose run --rm  `                | Run a one-off command in a new container (removed after exit)          |
| `docker system prune -f`                                     | Remove all unused containers, networks, images, and build cache         |
| `docker volume prune -f`                                     | Remove all unused volumes                                              |
| `docker image prune -f`                                      | Remove unused images                                                   |
| `docker network prune -f`                                    | Remove unused networks                                                 |

---

## Access a Running Docker Container

1. List containers:
   ```bash
   docker ps
   ```
2. Get a root shell (replace `meshsense-webui` with your container name if different):
   ```bash
   docker exec -it -u root meshsense-webui bash
   ```
