# Private Tor Network Demo

A complete private Tor network implementation using Docker Compose, demonstrating the core components of the Tor network including directory authority, relay nodes, exit nodes, hidden services, and clients.

## Architecture

This demo implements a fully functional private Tor network with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Private Tor Network                       │
│                                                              │
│  ┌──────────────┐                                           │
│  │   DirAuth    │  ←─── Authority Directory Server         │
│  │  172.20.0.10 │                                           │
│  └──────┬───────┘                                           │
│         │                                                    │
│    ┌────┴────┬────────────┬────────────┐                   │
│    │         │            │            │                    │
│  ┌─▼───┐  ┌─▼────┐    ┌─▼────┐    ┌─▼──────┐             │
│  │Relay1│  │Relay2│    │Exit1 │    │Hidden  │             │
│  │.0.11 │  │.0.12 │    │.0.13 │    │Service │             │
│  └──────┘  └──────┘    └───┬──┘    │.0.14   │             │
│                            │        └────┬───┘             │
│                            │             │                  │
│                        ┌───▼─────┐   ┌──▼──────────┐      │
│                        │  HTTP   │   │  HTTP       │      │
│                        │ Server  │   │ (hidden)    │      │
│  ┌──────────┐          │.0.20    │   │ via .onion │      │
│  │  Client  │─────────►└─────────┘   └─────────────┘      │
│  │ .0.15    │                                               │
│  └──────────┘                                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Components

1. **Directory Authority (dirauth)**: 
   - Maintains the network consensus
   - Provides directory information to all nodes
   - Generates authority keys and certificates
   - IP: 172.20.0.10

2. **Relay Nodes (relay1, relay2)**:
   - Forward encrypted traffic through the network
   - Do not allow exit traffic
   - IPs: 172.20.0.11, 172.20.0.12

3. **Exit Node (exit1)**:
   - Allows traffic to exit the Tor network
   - Configured to allow HTTP/HTTPS traffic
   - IP: 172.20.0.13

4. **Hidden Service Node (hidden-service)**:
   - Hosts a .onion hidden service
   - Provides a test web page accessible only via Tor
   - IP: 172.20.0.14

5. **Client Node (client)**:
   - Connects to the private Tor network
   - Runs automated tests
   - Provides SOCKS proxy on port 9050
   - IP: 172.20.0.15

6. **HTTP Test Server (http-server)**:
   - Public HTTP server for testing exit node functionality
   - Accessible directly or via Tor
   - IP: 172.20.0.20
   - Also exposed on host port 8888

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 1.29 or higher)
- At least 2GB of available RAM
- Linux, macOS, or Windows with WSL2

## Quick Start

### 1. Clone or navigate to the project directory

```bash
cd private-tor-demo
```

### 2. Run the setup script

```bash
chmod +x setup.sh
./setup.sh
```

The setup script will:
- Build all Docker images
- Start all services
- Wait for the network to initialize
- Run automated tests
- Display results

### 3. View the results

The client will automatically run tests to verify:
- Access to the HTTP server through the Tor exit node
- Access to the hidden service via .onion address

## Manual Operations

### Start the network

```bash
docker-compose up -d
```

### View logs

View all logs:
```bash
docker-compose logs -f
```

View specific service logs:
```bash
docker-compose logs -f client
docker-compose logs -f dirauth
docker-compose logs -f hidden-service
```

### Run tests manually

```bash
docker-compose exec client /bin/bash /test.sh
```

### Get hidden service address

```bash
docker-compose exec hidden-service cat /var/lib/tor/hidden_service/hostname
```

### Access client shell

```bash
docker-compose exec client /bin/bash
```

Inside the client container, you can use curl with Tor:
```bash
# Access public HTTP server via Tor
curl -x socks5h://127.0.0.1:9050 http://http-server/

# Access hidden service (replace with actual .onion address)
ONION_ADDR=$(cat /shared/hidden_service/hostname)
curl -x socks5h://127.0.0.1:9050 "http://$ONION_ADDR/"
```

### Stop the network

```bash
docker-compose down
```

### Clean up (including data)

```bash
docker-compose down -v
```

## Configuration Files

All Tor configuration files are stored locally and copied into containers:

- `dirauth/torrc` - Directory authority configuration
- `relay1/torrc` - First relay node configuration
- `relay2/torrc` - Second relay node configuration
- `exit/torrc` - Exit node configuration
- `hidden-service/torrc` - Hidden service configuration
- `client/torrc` - Client configuration

### Key Configuration Options

- **TestingTorNetwork**: Speeds up consensus generation for testing
- **V3AuthVotingInterval**: Set to 5 minutes for faster network convergence
- **ExitPolicy**: Configured to allow HTTP/HTTPS traffic only
- **HiddenServiceDir**: Directory for hidden service keys and hostname

## Testing

### Automated Tests

The client node runs two automated tests:

1. **Exit Node Test**: Accesses the public HTTP server through Tor
2. **Hidden Service Test**: Accesses the .onion hidden service through Tor

### Manual Testing

You can also test manually:

```bash
# Access HTTP server directly (from host)
curl http://localhost:8888

# Access via Tor (from client container)
docker-compose exec client curl -x socks5h://127.0.0.1:9050 http://http-server/

# Get hidden service address
ONION=$(docker-compose exec hidden-service cat /var/lib/tor/hidden_service/hostname | tr -d '\r')

# Access hidden service via Tor
docker-compose exec client curl -x socks5h://127.0.0.1:9050 "http://$ONION/"
```

## Troubleshooting

### Network takes too long to converge

The private Tor network needs time to build consensus. Wait 60-90 seconds after starting before running tests.

### Client cannot connect

Check that all services are running:
```bash
docker-compose ps
```

Check directory authority logs:
```bash
docker-compose logs dirauth
```

### Hidden service not accessible

Check if the hidden service has generated its hostname:
```bash
docker-compose exec hidden-service cat /var/lib/tor/hidden_service/hostname
```

If the file doesn't exist, wait a bit longer or check logs:
```bash
docker-compose logs hidden-service
```

### Reset everything

Stop and remove all containers and volumes:
```bash
docker-compose down -v
rm -rf shared/
```

Then run `./setup.sh` again.

## Network Details

### IP Addressing

- Network: 172.20.0.0/16
- Directory Authority: 172.20.0.10
- Relay 1: 172.20.0.11
- Relay 2: 172.20.0.12
- Exit Node: 172.20.0.13
- Hidden Service: 172.20.0.14
- Client: 172.20.0.15
- HTTP Server: 172.20.0.20

### Ports

- DirAuth: 7000 (OR), 7001 (Dir)
- Relay 1: 7002 (OR), 7003 (Dir)
- Relay 2: 7004 (OR), 7005 (Dir)
- Exit: 7006 (OR), 7007 (Dir)
- Hidden Service: 7008 (OR), 8080 (HTTP internal)
- Client: 9050 (SOCKS)
- HTTP Server: 80 (internal), 8888 (host)

## Security Notes

⚠️ **This is a demo/testing environment only!**

- All components run in TestingTorNetwork mode
- Keys are generated automatically without proper security
- The network is not anonymous (all traffic visible within Docker)
- Exit policy is permissive
- Not suitable for production use

## Learning Resources

### Tor Protocol

This demo implements the core Tor protocol:

1. **Directory Authority**: Maintains network consensus
2. **Circuit Building**: Client builds 3-hop circuits (Entry → Middle → Exit)
3. **Onion Routing**: Each hop only knows previous and next hop
4. **Hidden Services**: .onion addresses accessible only via Tor

### File Structure

```
.
├── Dockerfile                 # Base Tor image
├── docker-compose.yml         # Service orchestration
├── setup.sh                   # Setup script
├── README.md                  # This file
├── dirauth/
│   ├── torrc                  # Authority config
│   └── start.sh               # Key generation script
├── relay1/
│   └── torrc                  # Relay config
├── relay2/
│   └── torrc                  # Relay config
├── exit/
│   └── torrc                  # Exit config
├── hidden-service/
│   ├── torrc                  # Hidden service config
│   ├── start.sh               # Service startup
│   └── index.html             # Web page
├── client/
│   ├── torrc                  # Client config
│   └── test.sh                # Test script
└── http-server/
    ├── Dockerfile             # HTTP server image
    └── index.html             # Test page
```

## License

This project is provided as-is for educational purposes.

## Contributing

Feel free to submit issues or pull requests to improve this demo.

## Acknowledgments

- The Tor Project for the Tor software
- Docker for containerization technology

