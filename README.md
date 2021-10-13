# moby-vscode

To install using Moby:

```bash
sudo apt-get update && sudo apt-get-yq intsall wget
sudo bash -c "$(wget -qO- https://github.com/Chuxel/moby-vscode/raw/main/install-moby.sh)"
sudo usermod -aG docker $(whoami)
```

To install using Docker CE:

```bash
sudo apt-get update && sudo apt-get-yq intsall wget
sudo bash -c "$(wget -qO- https://github.com/Chuxel/moby-vscode/raw/main/install-moby.sh)" -- false
sudo usermod -aG docker $(whoami)
```

This script is not enough to get "Docker in Docker" working in a container. [See here for a container compatible script.](https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/docker-in-docker.md)
