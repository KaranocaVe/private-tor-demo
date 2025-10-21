#!/bin/bash
set -e

echo "Starting client setup..."

# Fix permissions
chown -R debian-tor:debian-tor /var/lib/tor

# Generate torrc from template
FINGERPRINT=$(cat /var/lib/tor-dirauth/fingerprint | awk '{print $2}')
V3IDENT=$(cat /var/lib/tor-dirauth/keys/authority_certificate | grep fingerprint | head -1 | awk '{print $2}')

sed "s/__DIRAUTH_FINGERPRINT__/$FINGERPRINT/g; s/__DIRAUTH_V3IDENT__/$V3IDENT/g" /etc/tor/torrc.template > /etc/tor/torrc

echo "Configuration complete. Starting Tor client..."

# Start Tor in background
sudo -u debian-tor tor -f /etc/tor/torrc &

# Wait for Tor to be ready
sleep 30

# Run test
/bin/bash /test.sh

# Keep container running
tail -f /dev/null

