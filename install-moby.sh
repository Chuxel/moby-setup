#!/usr/bin/env bash
set -e

USE_MOBY="${1:-true}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or su before running this script.'
    exit 1
fi

required_packages="apt-transport-https wget ca-certificates lxc iptables pigz gnupg2"
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
    apt-get -yq install docker-ce-cli docker-ce containerd.io
fi

cat << 'EOF' > /usr/local/bin/mobyctl
#!/usr/bin/env bash
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or su before running this script.'
    exit 1
fi
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
        if ! pidof dockerd > /dev/null 2>&1; then
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