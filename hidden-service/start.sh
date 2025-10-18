#!/bin/bash

# Start simple HTTP server in background
cd /var/www
python3 -m http.server 8080 &

# Wait a moment for server to start
sleep 2

# Start Tor
exec tor -f /etc/tor/torrc

