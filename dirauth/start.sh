#!/bin/bash
set -e

# Create necessary directories
mkdir -p /var/lib/tor/keys

# Generate authority keys if they don't exist
if [ ! -f /var/lib/tor/keys/authority_certificate ]; then
    echo "Generating directory authority keys..."
    # Use --passphrase-fd 0 with empty input for automated key generation
    echo "" | tor-gencert --create-identity-key -m 12 -a 172.20.0.10:7001 \
        -i /var/lib/tor/keys/authority_identity_key \
        -s /var/lib/tor/keys/authority_signing_key \
        -c /var/lib/tor/keys/authority_certificate \
        --passphrase-fd 0
    
    echo "Authority keys generated successfully"
fi

# Set proper permissions - debian-tor needs to read these files
chown -R debian-tor:debian-tor /var/lib/tor
chmod 700 /var/lib/tor/keys
chmod 600 /var/lib/tor/keys/*

# Need to run tor once to generate fingerprint if it doesn't exist
if [ ! -f /var/lib/tor/fingerprint ]; then
    echo "Generating fingerprint with initial Tor run..."
    # Create temporary torrc - need ContactInfo and AssumeReachable for authority
    cat > /tmp/torrc.tmp << EOF
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
    
    # Run tor briefly to generate fingerprint - it will fail but should create the fingerprint
    sudo -u debian-tor timeout 10 tor -f /tmp/torrc.tmp 2>&1 | head -20 || true
    sleep 2
fi

# Extract v3ident from authority certificate
V3IDENT=$(grep fingerprint /var/lib/tor/keys/authority_certificate | head -1 | awk '{print $2}')
echo "V3 Identity: $V3IDENT"

# Extract fingerprint - if file doesn't exist yet, compute it from secret_id_key
if [ -f /var/lib/tor/fingerprint ]; then
    FINGERPRINT=$(cat /var/lib/tor/fingerprint | awk '{print $2}')
else
    echo "Fingerprint file not found, computing from keys..."
    # Tor should have created it, but if not, we can compute it
    # For now, let's wait a bit more and try the temporary tor run again
    sudo -u debian-tor tor --list-fingerprint --orport 7000 \
        --datadirectory /var/lib/tor \
        --contact-info tor@example.com 2>&1 || true
    
    if [ -f /var/lib/tor/fingerprint ]; then
        FINGERPRINT=$(cat /var/lib/tor/fingerprint | awk '{print $2}')
    else
        echo "ERROR: Could not generate fingerprint"
        exit 1
    fi
fi

echo "Fingerprint: $FINGERPRINT"

# Create final torrc with DirAuthority self-reference
cat > /etc/tor/torrc.final << EOF
# Directory Authority Configuration
Nickname dirauth
ContactInfo tor@example.com
DataDirectory /var/lib/tor
RunAsDaemon 0
Log notice stdout

# Authority configuration
AuthoritativeDirectory 1
V3AuthoritativeDirectory 1

# Network configuration
ORPort 7000
DirPort 7001
Address 172.20.0.10

# Exit policy
ExitPolicy reject *:*

# Speed up private network
TestingTorNetwork 1
AssumeReachable 1
V3AuthVotingInterval 5 minutes
V3AuthVoteDelay 20 seconds
V3AuthDistDelay 20 seconds

# Vote all nodes as Guard and Exit in test network
TestingDirAuthVoteGuard dirauth,relay1,relay2,exit1
TestingDirAuthVoteExit exit1,relay1,relay2

# Self-reference for TestingTorNetwork
DirAuthority dirauth orport=7000 no-v2 v3ident=$V3IDENT 172.20.0.10:7001 $FINGERPRINT
EOF

echo "Created final torrc with DirAuthority self-reference"

# Start Tor as debian-tor user
echo "Starting Tor as debian-tor user..."
exec sudo -u debian-tor tor -f /etc/tor/torrc.final

