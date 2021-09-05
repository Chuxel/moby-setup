#!/usr/bin/env bash
set -e

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
wget -q https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get -yq install moby-cli moby-buildx moby-compose moby-engine
rm packages-microsoft-prod.deb

cat << 'EOF' > /usr/local/bin/mobyd
#!/usr/bin/env bash
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or su before running this script.'
    exit 1
fi
case "${1-:"start"}" in
    start)
        if ! pidof dockerd > /dev/null 2>&1; then
            echo "(*) Starting Moby Engine daemon..."
            ( nohup dockerd > /tmp/dockerd.log 2>&1 ) &
            while ! pidof dockerd > /dev/null 2>&1; do
                sleep 1
            done
            echo "(*) Done!"
        else
            echo "(!) Moby Engine is already running."
        fi
        ;;
    stop)
        if ! pidof dockerd > /dev/null 2>&1; then
            echo "(*) Stopping Moby Engine..."
            kill "$(pidof dockerd)"
        else
            echo "(!) Moby Engine is not running."
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
chmod +x /usr/local/bin/mobyd

cat << 'EOF'
** Install complete! **

If you are using WSL, run:

    sudo mobyd start

to start the Moby/Docker Engine.

EOF