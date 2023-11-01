# syntax=docker/dockerfile:1.6

###
### Medusa build process
###
FROM golang:1.21 AS medusa

WORKDIR /src
RUN git clone https://github.com/crytic/medusa.git
RUN cd medusa && \
    export LATEST_TAG="$(git describe --tags | sed 's/-[0-9]\+-g\w\+$//')" && \
    git checkout "$LATEST_TAG" && \
    go build -trimpath -o=/usr/local/bin/medusa -ldflags="-s -w" && \
    chmod 755 /usr/local/bin/medusa


###
### Echidna "build process"
### TODO: replace this with a aarch64-friendly solution
###
FROM --platform=linux/amd64 ghcr.io/crytic/echidna/echidna:latest AS echidna
RUN chmod 755 /usr/local/bin/echidna


###
### ETH Security Toolbox
###
FROM ubuntu:jammy AS toolbox

# Add common tools
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash-completion \
    curl \
    git \
    python3-dev \
    python3-pip \
    python3-venv \
    sudo \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# improve compatibility with amd64 solc in non-amd64 environments (e.g. Docker Desktop on M1 Mac)
ENV QEMU_LD_PREFIX=/usr/x86_64-linux-gnu
RUN if [ ! "$(uname -m)" = "x86_64" ]; then \
    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends libc6-amd64-cross \
    && rm -rf /var/lib/apt/lists/*; fi

# Add n (node version manager), lts node, npm, and yarn
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/v9.2.0/bin/n -o n && \
    if [ ! "ab1292c18efdac7b6b673949deeee3654b267518dea32569caf2eeb0ee0c69d5  n" = "$(sha256sum n)" ]; then \
        echo "N installer does not match expected checksum! exiting"; \
        exit 1; \
    fi && \
    cat n | bash -s lts && rm n && \
    npm install -g n yarn && \
    n stable && n prune && npm --force cache clean

# Include echidna
COPY --chown=root:root --from=echidna /usr/local/bin/echidna /usr/local/bin/echidna

# Include medusa
COPY --chown=root:root --from=medusa /usr/local/bin/medusa /usr/local/bin/medusa
RUN medusa completion bash > /etc/bash_completion.d/medusa

# Add a user with passwordless sudo
RUN useradd -m ethsec && \
    usermod -aG sudo ethsec && \
    echo 'ethsec ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

##### user-level setup follows
##### Things should be installed in $HOME from now on
USER ethsec
WORKDIR /home/ethsec
ENV HOME="/home/ethsec"
ENV PATH="${PATH}:${HOME}/.local/bin:${HOME}/.vyper/bin:${HOME}/.foundry/bin"

# Install vyper compiler
RUN python3 -m venv ${HOME}/.vyper && \
    ${HOME}/.vyper/bin/pip3 install --no-cache-dir vyper && \
    echo '\nexport PATH=${PATH}:${HOME}/.vyper/bin' >> ~/.bashrc

# Install foundry
RUN curl -fsSL https://raw.githubusercontent.com/foundry-rs/foundry/ded0317584bd835e79f2573e56c0043ab548da04/foundryup/install -o install && \
    if [ ! "5d67b82c1319b26f19d496f8602edf0dd62da7cf41c219bc38cf3f6dd5f9c86b  install" = "$(sha256sum install)" ]; then \
        echo "Foundry installer does not match expected checksum! exiting"; \
        exit 1; \
    fi && \
    cat install | SHELL=/bin/bash bash && rm install && \
    foundryup && \
    COMPLETIONS="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions" && \
    mkdir -p "${COMPLETIONS}" && \
    for tool in anvil cast forge; do \
        "$tool" completions bash > "${COMPLETIONS}/$tool"; \
    done

# Install python tools
RUN pip3 install --no-cache-dir --user \
    pyevmasm \
    solc-select \
    crytic-compile \
    slither-analyzer

# Install one solc release from each branch and select the latest version as the default
RUN solc-select install 0.4.26 0.5.17 0.6.12 0.7.6 latest && solc-select use latest

# Clone useful repositories
RUN git clone --depth 1 https://github.com/crytic/building-secure-contracts.git

# Configure MOTD
COPY --link --chown=root:root motd /etc/motd
RUN echo '\ncat /etc/motd\n' >> ~/.bashrc

CMD ["/bin/bash"]
