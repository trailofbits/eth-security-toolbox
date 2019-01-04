FROM trailofbits/etheno:latest
MAINTAINER Evan Sultanik

USER root

# Remove the version of solc installed by Etheno
RUN apt-get -y remove solc
COPY install_solc.sh /
RUN bash /install_solc.sh
RUN rm /install_solc.sh

# Install all versions of solc


WORKDIR /home

RUN usermod -l ethsec etheno
RUN groupmod --new-name ethsec etheno
RUN usermod -d /home/ethsec -m ethsec
RUN sed -i 's/etheno/ethsec/g' /etc/sudoers

USER ethsec
WORKDIR /home/ethsec
ENV HOME="/home/ethsec"
ENV PATH="${PATH}:${HOME}/.local/bin"

RUN mv examples etheno-examples

RUN pip3 install slither-analyzer pyevmasm 

RUN git clone https://github.com/trailofbits/not-so-smart-contracts.git

RUN git clone https://github.com/trailofbits/rattle.git

USER root
COPY motd /etc/motd
RUN echo '\ncat /etc/motd\n' >> /etc/bash.bashrc
USER ethsec

ENTRYPOINT ["/bin/bash"]