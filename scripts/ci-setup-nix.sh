#!/bin/sh
set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq --no-install-recommends nix-bin git ca-certificates >/dev/null

mkdir -p /etc/nix
cat >/etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
accept-flake-config = true
build-users-group =
sandbox = false
EOF

nix --version
