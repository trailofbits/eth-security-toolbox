FROM trailofbits/etheno:latest
MAINTAINER Evan Sultanik

USER root

# Remove the version of solc installed by Etheno
RUN apt-get -y remove solc
# Install all versions of solc
COPY install_solc.sh /
RUN bash /install_solc.sh
RUN rm /install_solc.sh
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

RUN pip3 install slither-analyzer pyevmasm
# Slither now requires npx
# Also install Embark while we are at it
USER root
RUN npm -g install npx
RUN npm -g install embark
RUN npm -g install @trailofbits/embark-contract-info
RUN npm -g install n
RUN n stable
USER ethsec

RUN git clone https://github.com/trailofbits/not-so-smart-contracts.git

RUN git clone https://github.com/trailofbits/rattle.git

RUN mkdir .workshops
WORKDIR /home/ethsec/.workshops
RUN git init
RUN git remote add origin https://github.com/trailofbits/publications.git
RUN git fetch origin
RUN git checkout origin/master -- workshops
RUN mv workshops ../
RUN rm -rf .workshops

WORKDIR /home/ethsec

USER root
COPY motd /etc/motd
RUN echo '\ncat /etc/motd\n' >> /etc/bash.bashrc
USER ethsec

ENTRYPOINT ["/bin/bash"]