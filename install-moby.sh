#!/usr/bin/env bash
set -e

USE_MOBY="${1:-true}"
DOCKER_DASH_COMPOSE_VERSION=${2:-"v1"} # v1 or v2

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or su before running this script.'
    exit 1
fi

required_packages="apt-transport-https curl ca-certificates pigz gnupg2 dirmngr"
if ! dpkg -s ${required_packages} > /dev/null 2>&1; then
    apt-get update
    apt-get -yq install ${required_packages}
fi

. /etc/os-release
if [ "${USE_MOBY}" = "true" ]; then
    wget -q https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    apt-get update
    apt-get -yq install moby-cli moby-buildx moby-compose moby-engine
    rm packages-microsoft-prod.deb
else
    wget -qO- https://download.docker.com/linux/${ID}/gpg | gpg --dearmor > /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get -yq install docker-ce-cli docker-ce docker-compose-plugin
fi

if ! grep -q 'DOCKER_BUILDKIT' /etc/bash.bashrc > /dev/null 2>&1; then
    echo 'export DOCKER_BUILDKIT=1' > /etc/bash.bashrc
fi
if [ -e '/etc/zsh' ] && ! grep -q 'DOCKER_BUILDKIT' /etc/zsh/zshenv > /dev/null 2>&1; then
    echo 'export DOCKER_BUILDKIT=1' > /etc/zsh/zshenv
fi

# Install docker compose
if type docker-compose > /dev/null 2>&1; then
    echo "Docker Compose v1 already installed."
else
    curl -fsSL "https://github.com/docker/compose/releases/download/${compose_v1_version}/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi


# Install docker-compose switch if not already installed - https://github.com/docker/compose-switch#manual-installation
current_v1_compose_path="$(which docker-compose)"
target_v1_compose_path="$(dirname "${current_v1_compose_path}")/docker-compose-v1"
if ! type compose-switch > /dev/null 2>&1; then
    echo "(*) Installing compose-switch..."
    compose_switch_version="latest"
    find_version_from_git_tags compose_switch_version "https://github.com/docker/compose-switch"
    curl -fsSL "https://github.com/docker/compose-switch/releases/download/v${compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/compose-switch
    chmod +x /usr/local/bin/compose-switch
    # TODO: Verify checksum once available: https://github.com/docker/compose-switch/issues/11

    # Setup v1 CLI as alternative in addition to compose-switch (which maps to v2)
    mv "${current_v1_compose_path}" "${target_v1_compose_path}"
    update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99
    update-alternatives --install /usr/local/bin/docker-compose docker-compose "${target_v1_compose_path}" 1
fi
if [ "${DOCKER_DASH_COMPOSE_VERSION}" = "v1" ]; then
    update-alternatives --set docker-compose "${target_v1_compose_path}"
else
    update-alternatives --set docker-compose /usr/local/bin/compose-switch
fi

cat << 'EOF' > /usr/local/bin/mobyctl
#!/usr/bin/env bash
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or su before running this script.'
    exit 1
fi
export DOCKER_BUILDKIT=1
case "${1-:"start"}" in
    start)
        if ! pidof dockerd > /dev/null 2>&1; then
            echo "(*) Starting Docker/Moby Engine daemon..."
            ( nohup dockerd > /tmp/dockerd.log 2>&1 ) &
            while ! pidof dockerd > /dev/null 2>&1; do
                sleep 1
            done
            echo "(*) Done!"
        else
            echo "(!) Docker/Moby Engine is already running."
        fi
        ;;
    stop)
        if pidof dockerd > /dev/null 2>&1; then
            echo "(*) Stopping Docker/Moby Engine..."
            kill "$(pidof dockerd)"
        else
            echo "(!) Docker/Moby Engine is not running."
        fi
        ;;
    status)
        if pidof dockerd > /dev/null 2>&1; then
            echo "(*) Status: Running"
        else
            echo "(*) Status: Stopped"
        fi
        ;;
    *)
        echo "(!) Invalid command $1. Valid commands: start, stop, status"
        ;;
esac
EOF
chmod +x /usr/local/bin/mobyctl

cat << 'EOF'
** Install complete! **

If you are using WSL, run:

    sudo mobyctl start

to start the Moby/Docker Engine.

EOF