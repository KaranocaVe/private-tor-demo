#!/bin/bash
set -e

echo "Starting Directory Authority setup..."

# Create necessary directories
mkdir -p /var/lib/tor/keys

# Generate authority keys if they don't exist
if [ ! -f /var/lib/tor/keys/authority_certificate ]; then
    echo "Generating directory authority keys..."
    echo "" | tor-gencert --create-identity-key -m 12 -a 172.20.0.10:7001 \
        -i /var/lib/tor/keys/authority_identity_key \
        -s /var/lib/tor/keys/authority_signing_key \
        -c /var/lib/tor/keys/authority_certificate \
        --passphrase-fd 0
    
    echo "Authority keys generated successfully"
fi

# Set proper permissions
chown -R debian-tor:debian-tor /var/lib/tor
chmod 700 /var/lib/tor/keys
chmod 600 /var/lib/tor/keys/*

# Generate fingerprint if it doesn't exist
if [ ! -f /var/lib/tor/fingerprint ]; then
    echo "Generating fingerprint..."
    cat > /tmp/torrc.tmp << 'EOF'
Nickname dirauth
ContactInfo tor@example.com
DataDirectory /var/lib/tor
AuthoritativeDirectory 1
V3AuthoritativeDirectory 1
ORPort 7000
DirPort 7001
Address 172.20.0.10
ExitPolicy reject *:*
AssumeReachable 1
EOF
    
    sudo -u debian-tor timeout 10 tor -f /tmp/torrc.tmp 2>&1 | head -20 || true
    sleep 2
fi

# Extract V3 identity and fingerprint
V3IDENT=$(grep fingerprint /var/lib/tor/keys/authority_certificate | head -1 | awk '{print $2}')
echo "V3 Identity: $V3IDENT"

if [ -f /var/lib/tor/fingerprint ]; then
    FINGERPRINT=$(cat /var/lib/tor/fingerprint | awk '{print $2}')
else
    echo "ERROR: Could not generate fingerprint"
    exit 1
fi
echo "Fingerprint: $FINGERPRINT"

# Create final torrc from base template + dynamic DirAuthority line
cat /etc/tor/torrc.base > /etc/tor/torrc
echo "" >> /etc/tor/torrc
echo "# Self-reference for TestingTorNetwork (auto-generated)" >> /etc/tor/torrc
echo "DirAuthority dirauth orport=7000 no-v2 v3ident=$V3IDENT 172.20.0.10:7001 $FINGERPRINT" >> /etc/tor/torrc

echo "Configuration complete. Starting Tor..."

# Start Tor as debian-tor user
exec sudo -u debian-tor tor -f /etc/tor/torrc
