#!/bin/sh
# b.sh — OPNsense bootstrap
# Usage: setenv GITHUB_USER xxx && fetch -qo - https://raw.githubusercontent.com/monotch-cluster-provisioning/opnsense/main/b.sh | sh

# Guard: fail clearly if no user provided
if [ -z "$GITHUB_USER" ]; then
  echo "ERROR: GITHUB_USER not set. Run as: setenv GITHUB_USER xxx && fetch -qo - <url> | sh"
  exit 1
fi

# SSH keys from GitHub
mkdir -p /root/.ssh
fetch -qo /root/.ssh/authorized_keys \
  https://github.com/${GITHUB_USER}.keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Update config.xml to enable SSH
/usr/local/bin/php -r '
  $xml = simplexml_load_file("/conf/config.xml");

  # Clean up any previous attempts
  unset($xml->system->ssh);

  # Recreate ssh block under system
  $ssh = $xml->system->addChild("ssh");
  $ssh->addChild("noauto", "1");
  $ssh->addChild("enabled", "enabled");
  $ssh->addChild("passwordauth", "1");
  $ssh->addChild("permitrootlogin", "1");

  $dom = dom_import_simplexml($xml);
  $dom->ownerDocument->save("/conf/config.xml");
  echo "config.xml updated\n";
'

# Reload config without rebooting
/usr/local/etc/rc.reload_all

# Disable firewall
pfctl -d

echo "=== Bootstrap complete ==="
ifconfig | grep 'inet ' | grep -v '127.0.0.1'
