# MeshSense Docker Compose

Seems to be working with Wifi, might work with Bluetooth. Will update more soon. Tested on RPI4, should work on RPI3 & RPI5 as well.

## Quick start

```
git clone https://github.com/roperscrossroads/meshsense-docker-arm64.git
```

```
cd meshsense-docker-arm64
```

```
chmod +x install-docker.sh
```

```
./install-docker.sh
```

```
newgrp docker
```

```
sed -i "s/ACCESS_KEY=changeme/ACCESS_KEY=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c16)/" docker-compose.yml
```

```
 docker compose build
```

```
docker compose up
```

Once you see it working, ctrl+c and run it like this:

```
docker compose up -d
```

---

# Pair with bluetooth

TODO: test this again on a newly-flashed RPI

Using a bluetooth device requires that you run some CLI commands on the RPI to get it to trust the device. This is the basic flow.

## Using `bluetoothctl` to Trust and Connect to a Device

1. **Start `bluetoothctl`:**
   ```sh
   bluetoothctl
   ```

2. **Power on the Bluetooth adapter:**
   ```
   power on
   ```

3. **Enable agent and set as default:**
   ```
   agent on
   default-agent
   ```

4. **Scan for devices:**
   ```
   scan on
   ```
   *Wait for your device to appear and note its MAC address (e.g., `00:1D:43:6D:03:26`).*

5. **Pair with the device:**
   ```
   pair 00:1D:43:6D:03:26
   ```

6. **Trust the device:**
   ```
   trust 00:1D:43:6D:03:26
   ```

7. **Connect to the device:**
   ```
   connect 00:1D:43:6D:03:26
   ```

8. **(Optional) Stop scanning and exit:**
   ```
   scan off
   exit
   ```

This sequence will pair, trust, and connect to a Bluetooth device using `bluetoothctl`.

---

# Useful Docker Commands

## 📋 See What’s Running

```
docker compose ps
```

Lists all containers managed by your compose file.

## 🚀 Build the Container

```
docker compose build
```

Builds the image from your Dockerfile. Run this after changes to your Dockerfile or dependencies.

## ▶️ Run (Start) the Container

```
docker compose up -d
```

Starts the service in the background. If the image isn’t built yet, it builds automatically.

## ⏹️ Stop the Container

```
docker compose stop
```

Gracefully stops the running container(s) without removing them.

## 🔄 Restart the Container

```
docker compose restart
```

Restarts your service container(s). Use after config changes that don’t require a rebuild.

## 💥 Re-create the Container (with rebuild)

```
docker compose up -d --build --force-recreate
```

Rebuilds the image and re-creates the container, even if nothing changed. Use after Dockerfile or environment changes.

## 🧹 Remove Everything (Stop & Clean Up)

```
docker compose down
```

Stops and removes containers, networks, and by default, anonymous volumes.

## 🚀 Get a root shell in a running container: 

```
docker ps
```

    CONTAINER ID   IMAGE                                    COMMAND                  CREATED         STATUS         PORTS                                         NAMES
    bb2754fe6146   meshsense-docker-arm64-meshsense-webui   "/home/mesh/entrypoi…"   5 minutes ago   Up 4 minutes   0.0.0.0:5920->5920/tcp, [::]:5920->5920/tcp   meshsense-webui


```
docker exec -it  -u root meshsense-webui bash
```

    root@bb2754fe6146:/meshsense#