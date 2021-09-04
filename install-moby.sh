#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo or su before running this script.'
    exit 1
fi

required_packages="apt-transport-https wget ca-certificates lxc pigz gnupg2"
if ! dpkg -s ${required_packages} 2>&1 > /dev/null; then
    apt-get update
    apt-get -yq install ${required_packages}
fi

# Get Microsoft GPG key
. /etc/os-release
wget -q https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get -yq install moby-cli moby-buildx moby-compose moby-engine
rm packages-microsoft-prod.deb

cat << 'EOF' > /usr/local/bin/start-moby
#!/usr/bin/env bash
    if [ "$(id -u)" -ne 0 ]; then
        echo -e 'Script must be run as root. Use sudo or su before running this script.'
        exit 1
    fi
    if ! pidof dockerd 2>&1 > /dev/null
        ( nohup dockerd > /tmp/dockerd.log 2>&1 ) &
    fi
EOF

cat << 'EOF'
** Install complete! **

Run:

    sudo start-moby

to start up the Moby/Docker Engine. If you are using a Linux machine or VM
(rather than WSL), you may be able to execute:

    sudo systemctl enable docker

to ensure docker is running on boot.

EOF