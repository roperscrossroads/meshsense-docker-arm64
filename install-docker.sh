#!/bin/bash
# install-docker.sh: Install Docker on Raspberry Pi OS (headless) and add current user to docker group

set -e

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing Docker via official convenience script..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

echo "Adding user '$USER' to the 'docker' group..."
sudo usermod -aG docker $USER

echo "Enabling Docker to start at boot..."
sudo systemctl enable docker

echo "Docker installation complete."
echo "IMPORTANT: Log out and log back in (or run 'newgrp docker') for group changes to take effect."
echo "Test Docker with: docker run hello-world"
