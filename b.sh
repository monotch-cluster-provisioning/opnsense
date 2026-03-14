#!/bin/sh
# b.sh — OPNsense bootstrap
# Usage: GITHUB_USER=xxx fetch -qo - https://raw.githubusercontent.com/USER/b/main/b.sh | sh

# Guard: fail clearly if no user provided
if [ -z "$GITHUB_USER" ]; then
  echo "ERROR: GITHUB_USER not set. Run as: GITHUB_USER=xxx fetch -qo - <url> | sh"
  exit 1
fi

# SSH keys from GitHub
mkdir -p /root/.ssh
fetch -qo /root/.ssh/authorized_keys \
  https://github.com/${GITHUB_USER}.keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Allow root login via SSH
grep -q 'PermitRootLogin yes' /etc/ssh/sshd_config || \
  echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# Start SSH
service openssh start

# Disable firewall
pfctl -d

echo "=== Bootstrap complete ==="
ifconfig | grep 'inet ' | grep -v '127.0.0.1'
