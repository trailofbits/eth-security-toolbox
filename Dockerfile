FROM trailofbits/etheno:latest
MAINTAINER Evan Sultanik

USER root

# Remove the version of solc installed by Etheno
RUN apt-get -y remove solc
# Install all versions of solc
COPY install_solc.sh /
RUN bash /install_solc.sh && rm /install_solc.sh
# Install the solc-selection script:
COPY solc-select /usr/bin/

WORKDIR /home

RUN usermod -l ethsec etheno
RUN groupmod --new-name ethsec etheno
RUN usermod -d /home/ethsec -m ethsec
RUN sed -i 's/etheno/ethsec/g' /etc/sudoers

USER ethsec
WORKDIR /home/ethsec
ENV HOME="/home/ethsec"
ENV PATH="${PATH}:${HOME}/.local/bin"

# Select the latest version of solc as the default:
RUN solc-select --list | tail -n1 | xargs solc-select

RUN mv examples etheno-examples

RUN pip3 --no-cache-dir install slither-analyzer pyevmasm
# Slither now requires npx
# Also install Embark while we are at it
USER root
RUN apt-get update && apt-get -y install npm && rm -rf /var/lib/apt/lists/*

RUN npm -g install npx \
    embark \
    @trailofbits/embark-contract-info \
    n && \
    n stable && n prune && npm cache clean

USER ethsec

RUN git clone --depth 1 https://github.com/trailofbits/not-so-smart-contracts.git && \
    git clone --depth 1 https://github.com/trailofbits/rattle.git && \
    git clone --depth 1 https://github.com/trailofbits/publications.git && \
    mv publications/workshops . && \
    rm -rf publications


USER root
COPY motd /etc/motd
RUN echo '\ncat /etc/motd\n' >> /etc/bash.bashrc
USER ethsec

ENTRYPOINT ["/bin/bash"]
