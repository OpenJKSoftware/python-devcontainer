#!/usr/bin/env bash
# Script to install base dependencies for Python container
set -euo pipefail

echo "Installing base dependencies..."

apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
    build-essential \
    apt-transport-https \
    ca-certificates \
    iputils-ping \
    rsync \
    expect \
    git \
    openssh-client \
    manpages \
    less \
    zsh \
    fonts-powerline \
    htop \
    fzf \
    neovim \
    pv \
    jq \
    lsb-release

# Cleanup
apt-get clean

echo "Base dependencies installation complete"
