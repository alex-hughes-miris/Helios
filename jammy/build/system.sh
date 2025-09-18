#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

cat >/etc/apt/preferences.d/firefox-no-snap <<EOL
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOL

sed -i '/locale/d' /etc/dpkg/dpkg.cfg.d/excludes
apt update
apt upgrade -y
apt install -y gnupg curl wget
wget -q -O- https://packagecloud.io/dcommander/virtualgl/gpgkey |
	gpg --dearmor >/etc/apt/trusted.gpg.d/VirtualGL.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/VirtualGL.gpg] https://packagecloud.io/dcommander/virtualgl/any/ any main" >/etc/apt/sources.list.d/virtualgl.list
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt update

apt install --no-install-recommends -y \
	$(cat /lists/ubuntu.list) \
	neofetch

# ubuntu icon hack
rm -rf /usr/share/icons/elementary
mv /usr/share/icons/elementary-xfce-darker /usr/share/icons/elementary

# backwards compat for neofetch
ln -sf /bin/neofetch /bin/fastfetch

# handle background
rm -rfv /usr/share/backgrounds/*

# remove screensaver and lock screen
rm -f /etc/xdg/autostart/xscreensaver.desktop

# configure vgl
/opt/VirtualGL/bin/vglserver_config +glx +s +f +t

# build locale
/usr/sbin/locale-gen en_US.UTF-8

# - - - - - - - - - - - - #
# Add support for docker via nerdctl

# Get latest nerdctl
LATEST_TAG=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest \
  | grep '"tag_name":' \
  | sed -E 's/.*"v([^"]+)".*/\1/')

URL="https://github.com/containerd/nerdctl/releases/download/v${LATEST_TAG}/nerdctl-${LATEST_TAG}-linux-amd64.tar.gz"
echo "Downloading nerdctl v${LATEST_TAG} from:"
echo "$URL"
curl -LO "$URL"
tar -zxf nerdctl-${LATEST_TAG}-linux-amd64.tar.gz nerdctl
mv nerdctl /usr/bin/nerdctl
chmod 777 /usr/bin/nerdctl

rm nerdctl-${LATEST_TAG}-linux-amd64.tar.gz

# Buildctl support
LATEST_TAG=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest \
  | grep '"tag_name":' \
  | sed -E 's/.*"v([^"]+)".*/\1/')
arch=$(uname -m); case "$arch" in x86_64) arch=amd64;; aarch64) arch=arm64;; *) echo "Unsupported arch: $arch"; exit 1;; esac
curl -fsSL -o /tmp/buildkit.tgz "https://github.com/moby/buildkit/releases/download/${LATEST_TAG}/buildkit-${LATEST_TAG}.linux-$arch.tar.gz"
tar -xzf /tmp/buildkit.tgz -C /tmp
sudo mv /tmp/bin/buildctl /usr/local/bin/
buildctl --version


# Install sudo
apt install sudo

# run clean up
apt clean -y
apt autoclean -y
apt autoremove --purge -y
rm -rfv /var/lib/{apt,cache,log}/ /tmp/* /etc/systemd /var/lib/apt/lists/* /var/tmp/* /tmp/*
