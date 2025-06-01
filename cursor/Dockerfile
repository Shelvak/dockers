# Use a stable base image, like Ubuntu LTS
FROM ubuntu:24.04

# Arguments for user creation - can be overridden at build time
ARG USERNAME=cursor
ARG USER_UID=1000
ARG USER_GID=1000

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:rabbitmq/rabbitmq-erlang

# Install dependencies for Cursor and X11 forwarding
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Utilities
    wget \
    sudo \
    jq \
    libgbm-dev \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxss1 \
    libasound2t64 \
    xdg-utils \
    libgl1 \
    git \
    # Fonts (important for GUI rendering)
    fonts-liberation \
    elixir erlang curl \
    # Clean up APT cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Remove default ubuntu user
RUN userdel -r ubuntu

# Create a non-root user to run Cursor
# This user should ideally have the same UID/GID as your host user
# to avoid permission issues with mounted volumes
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && usermod -aG sudo $USERNAME \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ARG DUMMY=this-is-to-build-from-here
## Install Cursor
RUN wget -qO- --no-check-certificate "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" | jq -r .downloadUrl | xargs wget --no-check-certificate  -q -O cursor.appImage \
    && chmod +x cursor.appImage \
    && ./cursor.appImage --appimage-extract \
    && mv squashfs-root /opt/cursor \
    && ln -s /opt/cursor/AppRun /usr/bin/cursor \
    && rm cursor.appImage

# Switch to the non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Default command to launch Cursor
# --no-sandbox is often required when running in containers
# --disable-dev-shm-usage is to avoid issues with shared memory in containers [Avoid resizing crash]
CMD ["cursor", "--no-sandbox", "--disable-dev-shm-usage"]
## Possible flags to avoid crashing
#"--disable-gpu-compositing" , "--disable-gpu", "--disable-software-rasterizer", "--enable-features=UseOzonePlatform", "--ozone-platform=x11"
