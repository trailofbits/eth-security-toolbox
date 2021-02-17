FROM trailofbits/etheno:latest
MAINTAINER Evan Sultanik

USER root
ENV HOME="/root"
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WORKDIR /root

# Remove the version of solc installed by Etheno
RUN apt-get -y remove solc
# Install all versions of solc
COPY install_solc.sh /
RUN bash /install_solc.sh && rm /install_solc.sh
# Install the solc-selection script:
COPY solc-select /usr/bin/

# Slither now requires npx
# Also install Embark while we are at it

RUN npm install --force -g \
    embark \
    @trailofbits/embark-contract-info \
    n && \
    n stable && n prune && npm --force cache clean

WORKDIR /home

RUN usermod -l ethsec etheno
RUN groupmod --new-name ethsec etheno
RUN usermod -d /home/ethsec -m ethsec
RUN sed -i 's/etheno/ethsec/g' /etc/sudoers

RUN add-apt-repository ppa:sri-csl/formal-methods -y
RUN apt-get update
RUN apt-get install yices2 -y

USER ethsec
WORKDIR /home/ethsec
ENV HOME="/home/ethsec"
ENV PATH="${PATH}:${HOME}/.local/bin"

# Select the latest version of solc as the default:
RUN solc-select --list | tail -n1 | xargs solc-select

RUN mv examples etheno-examples

RUN pip3 --no-cache-dir install slither-analyzer pyevmasm
RUN pip3 --no-cache-dir install --upgrade manticore

RUN git clone --depth 1 https://github.com/trailofbits/not-so-smart-contracts.git && \
    git clone --depth 1 https://github.com/trailofbits/rattle.git && \
    git clone --depth 1 https://github.com/crytic/building-secure-contracts




USER root
COPY motd /etc/motd
RUN echo '\ncat /etc/motd\n' >> /etc/bash.bashrc
USER ethsec

CMD ["/bin/bash"]
