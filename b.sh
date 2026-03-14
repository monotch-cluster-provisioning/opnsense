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

/usr/local/bin/php -r '
  $xml = simplexml_load_file("/conf/config.xml");

  # Remove old enablessh if we added it
  unset($xml->system->enablessh);
  unset($xml->system->permitrootlogin);

  # Create the ssh block as seen in config.xml
  $ssh = $xml->addChild("ssh");
  $ssh->addChild("group", "admins");
  $ssh->addChild("noauto", "1");
  $ssh->addChild("interfaces");
  $ssh->addChild("kex");
  $ssh->addChild("ciphers");
  $ssh->addChild("macs");
  $ssh->addChild("keys");
  $ssh->addChild("keysig");
  $ssh->addChild("rekeylimit");
  $ssh->addChild("enabled", "enabled");
  $ssh->addChild("passwordauth", "1");
  $ssh->addChild("permitrootlogin", "1");

  $dom = dom_import_simplexml($xml);
  $dom->ownerDocument->save("/conf/config.xml");
  echo "config.xml updated\n";
'

# Verify
grep -A5 '<ssh>' /conf/config.xml

# Reload configd
/usr/local/etc/rc.d/configd restart

# Start SSH
/usr/local/sbin/pluginctl -s openssh start

# Start SSH via OPNsense's own service manager
/usr/local/sbin/pluginctl -s openssh start

# Disable firewall
pfctl -d

echo "=== Bootstrap complete ==="
ifconfig | grep 'inet ' | grep -v '127.0.0.1'
