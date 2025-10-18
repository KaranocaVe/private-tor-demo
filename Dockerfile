FROM debian:bullseye-slim

# Install Tor and other necessary tools
RUN apt-get update && \
    apt-get install -y \
    tor \
    curl \
    socat \
    python3 \
    netcat \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Allow debian-tor to run commands without password
RUN echo "debian-tor ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create necessary directories
RUN mkdir -p /var/lib/tor /etc/tor /var/log/tor && \
    chown -R debian-tor:debian-tor /var/lib/tor /etc/tor /var/log/tor

WORKDIR /etc/tor

# Default command
CMD ["tor", "-f", "/etc/tor/torrc"]

