# moby-setup

To install using Moby on Linux:

```bash
sudo apt-get update && sudo apt-get-yq intsall wget
sudo bash -c "$(wget -qO- https://github.com/Chuxel/moby-vscode/raw/main/install-moby.sh)"
sudo usermod -aG docker $(whoami)
```

To install using Docker CE on Linux:

```bash
sudo apt-get update && sudo apt-get-yq intsall wget
sudo bash -c "$(wget -qO- https://github.com/Chuxel/moby-vscode/raw/main/install-moby.sh)" -- false
sudo usermod -aG docker $(whoami)
```

This script is not enough to get "Docker in Docker" working in a container. [See here for a container compatible script.](https://github.com/devcontainers/features/blob/main/src/docker-in-docker)
