


# MeshSense Docker Compose Quick Commands

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

## 📋 See What’s Running

```
docker compose ps
```

Lists all containers managed by your compose file.
