#!/bin/bash

echo "==================================="
echo "Private Tor Network Setup"
echo "==================================="
echo ""

# Create shared directory for hidden service hostname
mkdir -p shared/hidden_service

# Make scripts executable
chmod +x dirauth/start.sh
chmod +x hidden-service/start.sh
chmod +x client/test.sh

echo "Building Docker images..."
docker-compose build

echo ""
echo "Starting Tor network..."
docker-compose up -d

echo ""
echo "Waiting for network to initialize..."
echo "This process includes:"
echo "1. Starting directory authority (10s)"
echo "2. Starting relay and exit nodes (15s)"
echo "3. Building consensus (20s)"
echo "4. Establishing circuits (20s)"
echo "5. Running tests (10s)"
echo ""

# Wait in steps so the user knows what's happening
echo -n "Initializing directory authority"
for i in {1..10}; do echo -n "."; sleep 1; done
echo ""

echo -n "Starting relay nodes"
for i in {1..10}; do echo -n "."; sleep 1; done
echo ""

echo -n "Building network consensus"
for i in {1..15}; do echo -n "."; sleep 1; done
echo ""

echo -n "Establishing circuits"
for i in {1..15}; do echo -n "."; sleep 1; done
echo ""

echo -n "Running tests"
for i in {1..10}; do echo -n "."; sleep 1; done
echo ""

echo ""
echo "==================================="
echo "Network Status"
echo "==================================="
docker-compose ps

echo ""
echo "==================================="
echo "Test Results"
echo "==================================="
docker-compose logs --tail=50 client | grep -A 50 "Private Tor Network Test Script"

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "To view all logs:"
echo "  docker-compose logs -f [service_name]"
echo ""
echo "Available services:"
echo "  - dirauth (Directory Authority)"
echo "  - relay1, relay2 (Relay Nodes)"
echo "  - exit1 (Exit Node)"
echo "  - hidden-service (Hidden Service)"
echo "  - client (Tor Client)"
echo "  - http-server (Test HTTP Server)"
echo ""
echo "To run tests again:"
echo "  docker-compose exec client /bin/bash /test.sh"
echo ""
echo "To access HTTP server directly:"
echo "  curl http://localhost:8888"
echo ""
echo "To stop the network:"
echo "  docker-compose down"
echo ""
echo "To stop and clean up all data:"
echo "  docker-compose down -v"
echo ""

