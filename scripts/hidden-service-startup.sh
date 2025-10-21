#!/bin/bash
set -e

echo "Starting hidden service setup..."

# Fix permissions
chown -R debian-tor:debian-tor /var/lib/tor
mkdir -p /shared/hidden_service

# Generate torrc from template
FINGERPRINT=$(cat /var/lib/tor-dirauth/fingerprint | awk '{print $2}')
V3IDENT=$(cat /var/lib/tor-dirauth/keys/authority_certificate | grep fingerprint | head -1 | awk '{print $2}')

sed "s/__DIRAUTH_FINGERPRINT__/$FINGERPRINT/g; s/__DIRAUTH_V3IDENT__/$V3IDENT/g" /etc/tor/torrc.template > /etc/tor/torrc

echo "Configuration complete. Starting services..."

# Start HTTP server in background
cd /var/www
python3 -m http.server 8080 &

# Wait for server
sleep 2

# Start Tor
/bin/bash /start.sh &

# Wait for hidden service hostname
sleep 20
while [ ! -f /var/lib/tor/hidden_service/hostname ]; do 
    sleep 2
done
cp /var/lib/tor/hidden_service/hostname /shared/hidden_service/hostname

# Keep container running
wait

