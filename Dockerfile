# syntax=docker/dockerfile:1.6

###
### Medusa build process
###
FROM golang:1.22 AS medusa

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
### ETH Security Toolbox - base
###
FROM ubuntu:jammy AS toolbox-base

# Add common tools
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash-completion \
    curl \
    git \
    jq \
    python3-pip \
    python3-venv \
    sudo \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add n (node version manager), lts node, npm, and yarn
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/v10.1.0/bin/n -o n && \
    if [ ! "a09599719bd38af5054f87b8f8d3e45150f00b7b5675323aa36b36d324d087b9  n" = "$(sha256sum n)" ]; then \
        echo "N installer does not match expected checksum! exiting"; \
        exit 1; \
    fi && \
    cat n | bash -s lts && rm n && \
    npm install -g n yarn && \
    n stable --cleanup && n prune && npm --force cache clean

# Include echidna
COPY --chown=root:root --from=echidna /usr/local/bin/echidna /usr/local/bin/echidna

# Include medusa
COPY --chown=root:root --from=medusa /usr/local/bin/medusa /usr/local/bin/medusa
RUN medusa completion bash > /etc/bash_completion.d/medusa

CMD ["/bin/bash"]


###
### ETH Security Toolbox - interactive variant
###
FROM toolbox-base AS toolbox

# improve compatibility with amd64 solc in non-amd64 environments (e.g. Docker Desktop on M1 Mac)
ENV QEMU_LD_PREFIX=/usr/x86_64-linux-gnu
RUN if [ ! "$(uname -m)" = "x86_64" ]; then \
    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends libc6-amd64-cross \
    && rm -rf /var/lib/apt/lists/*; fi

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
RUN curl -fsSL https://raw.githubusercontent.com/foundry-rs/foundry/27cabbd6c905b1273a5ed3ba7c10acce90833d76/foundryup/install -o install && \
    if [ ! "e4456a15d43054b537b329f6ca6d00962242050d24de4c59657a44bc17ad8a0c  install" = "$(sha256sum install)" ]; then \
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


###
### ETH Security Toolbox - CI variant
### Differences:
###   * Runs as root
###   * No Foundry autocompletions
###   * No pyevmasm
###   * No preinstalled solc binaries
###   * No BSC copy
###
FROM toolbox-base AS toolbox-ci

ENV HOME="/root"
ENV PATH="${PATH}:${HOME}/.crytic/bin:${HOME}/.vyper/bin:${HOME}/.foundry/bin"

# Install vyper compiler
RUN python3 -m venv ${HOME}/.vyper && \
    ${HOME}/.vyper/bin/pip3 install --no-cache-dir vyper && \
    echo '\nexport PATH=${PATH}:${HOME}/.vyper/bin' >> ~/.bashrc

# Install foundry
RUN curl -fsSL https://raw.githubusercontent.com/foundry-rs/foundry/27cabbd6c905b1273a5ed3ba7c10acce90833d76/foundryup/install -o install && \
    if [ ! "e4456a15d43054b537b329f6ca6d00962242050d24de4c59657a44bc17ad8a0c  install" = "$(sha256sum install)" ]; then \
        echo "Foundry installer does not match expected checksum! exiting"; \
        exit 1; \
    fi && \
    cat install | SHELL=/bin/bash bash && rm install && \
    foundryup

# Install python tools
RUN python3 -m venv ${HOME}/.crytic && \
    ${HOME}/.crytic/bin/pip3 install --no-cache-dir \
        solc-select \
        crytic-compile \
        slither-analyzer && \
    echo '\nexport PATH=${PATH}:${HOME}/.crytic/bin' >> ~/.bashrc
