# moby-vscode

To install using Moby:

```bash
wget -qO- https://github.com/Chuxel/moby-vscode/raw/main/install-moby.sh | sudo bash
sudo usermod -aG docker $(whoami)
```

To install using Docker CE:


```bash
wget -qO- https://github.com/Chuxel/moby-vscode/raw/main/install-moby.sh | sudo bash -- false
sudo usermod -aG docker $(whoami)
```
