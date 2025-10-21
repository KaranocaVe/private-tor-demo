#!/bin/bash
set -e

echo "Starting relay/exit node setup..."

# Fix permissions
chown -R debian-tor:debian-tor /var/lib/tor

# Generate torrc from template
FINGERPRINT=$(cat /var/lib/tor-dirauth/fingerprint | awk '{print $2}')
V3IDENT=$(cat /var/lib/tor-dirauth/keys/authority_certificate | grep fingerprint | head -1 | awk '{print $2}')

sed "s/__DIRAUTH_FINGERPRINT__/$FINGERPRINT/g; s/__DIRAUTH_V3IDENT__/$V3IDENT/g" /etc/tor/torrc.template > /etc/tor/torrc

echo "Configuration complete. Starting Tor..."

# Start Tor as debian-tor user
exec sudo -u debian-tor tor -f /etc/tor/torrc

