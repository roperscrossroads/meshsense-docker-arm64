# MeshSense Docker Compose for RPI/arm64

This project aims to build an arm64 version of MeshSense that can easily be run on 64-bit RPI boards such as the RPI3/4/5. It might also work on other arm64 boards. It can be built locally but that takes a while so I would recommend starting with the automated build. If you have Docker installed, you can run MeshSense with a single command.

Please hop in the [CSRA Mesh Discord](https://discord.com/invite/mgzj2PmhKf) and the [Mountain Mesh Discord](https://discord.gg/4WN32RHGSs) if you get it going and have an questions.

Thanks to [@dB-SPL](https://github.com/dB-SPL) for doing an writeup for the [CSRA Mesh](http://csramesh.org) to get this started.

## Testing Status

| Device | Runs | WiFi | Bluetooth | Serial     |
|--------|------|------|-----------|------------|
| RPI3   | ✅   | ⏳ Untested | ⏳ Internal BT is unreliable | ⏳ Untested |
| RPI4   | ✅   | ✅ | ✅ | ⏳ Untested |
| RPI5   | ⏳ Untested | ⏳ Untested | ⏳ Untested | ⏳ Untested |

- Verified on RPI4 with Raspberry Pi OS 64-bit (Debian Bookworm, 2025-05-13).
- RPI3 and RPI5 expected to work but need further testing.

---

## Quickstart: Run Pre-Built from GitHub

### Prerequisites

- **Raspberry Pi 3/4/5 running Raspberry Pi OS 64-bit (Bookworm or newer)**
- **Internet connection & Docker and Docker Compose installed**

### Install Docker & Docker Compose

You can **use the provided [`install-docker.sh`](https://github.com/roperscrossroads/meshsense-docker-arm64/blob/main/install-docker.sh) script**

```
sudo apt update
sudo apt install -y wget
wget https://github.com/roperscrossroads/meshsense-docker-arm64/raw/main/install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
newgrp docker
```

**Launch MeshSense on your Raspberry Pi using the pre-built Docker image with the following command.**

Be sure to replace `changeme` with a secure access key before running!

```

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

- It will be accessible at http://board-ip:5920/
- See below for info on how to pair bluetooth devices.
- Tested on RPI3 and RPI4, should work on RPI5.
- RPI3 internal bluetooth might not be reliable.

---

## Pair and Connect with `bluetoothctl`

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

This took a while to build on an RPI3 (35-40 minutes)

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

Once everything works, run it detached from the terminal:

```bash
docker compose up -d
```

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
