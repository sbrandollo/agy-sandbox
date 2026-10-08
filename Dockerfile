FROM debian:bookworm-slim

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential runtime dependencies and developer tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    less \
    procps \
    sudo \
    tar \
    tmux \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Antigravity CLI via official install script into /usr/local/bin
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin

# Create non-root developer user
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Create config and workspace mount directories with permissive permissions
# so running with any host UID (e.g. 501 on macOS) can create files in ~/.gemini
RUN mkdir -p /home/${USERNAME}/.gemini/config/projects \
             /home/${USERNAME}/.gemini/antigravity-cli \
             /workspace \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} /workspace \
    && chmod -R 777 /home/${USERNAME} /workspace

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["agy"]
CMD ["--dangerously-skip-permissions"]
