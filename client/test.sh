#!/bin/bash

echo "==================================="
echo "Private Tor Network Test Script"
echo "==================================="
echo ""

# Wait for Tor to be ready
echo "Waiting for Tor client to be ready..."
sleep 10

# Check if Tor SOCKS proxy is working
echo "Checking Tor SOCKS proxy..."
if ! nc -z 127.0.0.1 9050; then
    echo "ERROR: Tor SOCKS proxy is not running on port 9050"
    exit 1
fi
echo "✓ Tor SOCKS proxy is running"
echo ""

# Test 1: Access public HTTP server through Tor
echo "==================================="
echo "Test 1: Accessing HTTP Server via Exit Node"
echo "==================================="
if curl -x socks5h://127.0.0.1:9050 \
    --connect-timeout 30 \
    --max-time 60 \
    -s http://http-server/ | grep -q "Public HTTP Test Server"; then
    echo "✓ SUCCESS: Accessed HTTP server through Tor exit node"
else
    echo "✗ FAILED: Could not access HTTP server"
fi
echo ""

# Test 2: Access hidden service
echo "==================================="
echo "Test 2: Accessing Hidden Service"
echo "==================================="

# Get the hidden service address
if [ -f /shared/hidden_service/hostname ]; then
    ONION_ADDR=$(cat /shared/hidden_service/hostname)
    echo "Hidden service address: $ONION_ADDR"
    echo ""
    
    if curl -x socks5h://127.0.0.1:9050 \
        --connect-timeout 30 \
        --max-time 60 \
        -s "http://$ONION_ADDR/" | grep -q "Hidden Service"; then
        echo "✓ SUCCESS: Accessed hidden service through Tor"
    else
        echo "✗ FAILED: Could not access hidden service"
    fi
else
    echo "✗ FAILED: Hidden service address not found"
    echo "Please wait for the hidden service to generate its address"
fi

echo ""
echo "==================================="
echo "Test Complete"
echo "==================================="

