#!/bin/bash

# This script initializes the directory authority
# It needs to be run once to generate keys and fingerprints

echo "Initializing directory authority..."

# Start dirauth container to generate keys
docker-compose up -d dirauth

# Wait for key generation
echo "Waiting for keys to be generated..."
sleep 10

# Get fingerprint and v3ident
echo "Extracting fingerprint and v3ident..."
FINGERPRINT=$(docker-compose exec -T dirauth cat /var/lib/tor/fingerprint 2>/dev/null | awk '{print $2}')
V3IDENT=$(docker-compose exec -T dirauth cat /var/lib/tor/keys/authority_certificate 2>/dev/null | grep fingerprint | head -1 | awk '{print $2}')

if [ -z "$FINGERPRINT" ] || [ -z "$V3IDENT" ]; then
    echo "Error: Failed to get fingerprint or v3ident"
    docker-compose logs dirauth
    exit 1
fi

echo "Fingerprint: $FINGERPRINT"
echo "V3 Identity: $V3IDENT"

# Stop dirauth
docker-compose stop dirauth

echo ""
echo "Directory authority initialized successfully!"
echo "You can now start the full network with: docker-compose up -d"

