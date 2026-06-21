 FROM mcr.microsoft.com/devcontainers/base:debian
 
 # Install Hugo extended version
 ARG HUGO_VERSION=0.140.1
 RUN curl -fsSL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb -o hugo.deb \
     && dpkg -i hugo.deb \
     && rm hugo.deb
 
 # Install Python and Pillow for image compression
 RUN apt-get update && apt-get install -y \
     python3 \
     python3-pip \
     python3-pil \
     rsync \
    neovim \
    tmux \
     && rm -rf /var/lib/apt/lists/*
 
 # Verify installations
RUN hugo version && python3 --version && nvim --version | head -1

# Install Factory CLI
RUN curl -fsSL https://app.factory.ai/cli | sh

# Install CLI Proxy API
RUN curl -fsSL https://raw.githubusercontent.com/router-for-me/CLIProxyAPI/main/install.sh | bash \
    && mv /root/.local/bin/cliproxy /usr/local/bin/cliproxy || true
