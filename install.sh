#!/usr/bin/env bash
# Install vrm-fan-control on the ASUS ROG Zenith Extreme Alpha (Ubuntu): the out-of-tree it87 driver via DKMS,
# its module options, the control script and the systemd service. Run as root from this directory.
set -euo pipefail
cd "$(dirname "$0")"

apt-get install -y -qq git dkms build-essential "linux-headers-$(uname -r)" lm-sensors

if ! dkms status | grep -q '^it87/'; then
    build_directory=$(mktemp -d)
    git clone -q --depth 1 https://github.com/frankcrawford/it87.git "$build_directory/it87"
    make -C "$build_directory/it87" dkms || true  # its own modprobe fails without ignore_resource_conflict; installed below
    rm -rf "$build_directory"
fi

install -m 644 it87-modprobe.conf /etc/modprobe.d/it87.conf
install -m 644 it87-modules-load.conf /etc/modules-load.d/it87.conf
[ -f /etc/default/vrm-fan-control ] || install -m 644 vrm-fan-control.default /etc/default/vrm-fan-control
install -m 755 vrm-fan-control /usr/local/bin/vrm-fan-control
install -m 644 vrm-fan-control.service /etc/systemd/system/vrm-fan-control.service

modprobe it87
systemctl daemon-reload
systemctl enable --now vrm-fan-control
systemctl --no-pager --lines=0 status vrm-fan-control
