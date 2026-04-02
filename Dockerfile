# use debian-based steamcmd base image
FROM steamcmd/steamcmd:debian-trixie

# install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    procps \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# create a user for running the server
RUN groupadd -g 1000 arma3 && \
    useradd -u 1000 -g arma3 -m arma3

USER root

COPY entrypoint.sh /home/arma3/entrypoint.sh
RUN chown arma3 /home/arma3/entrypoint.sh
RUN chmod a+x /home/arma3/entrypoint.sh

# precreate steam install dir and chown to prevent named volume permissions issues
RUN mkdir -p /home/arma3/.local/share/Steam /home/arma3/arma3server && \
    chown -R arma3:arma3 /home/arma3/.local /home/arma3/arma3server

USER arma3

WORKDIR /home/arma3/arma3server

# tell steamcmd where the server account's home dir is
ENV HOME=/home/arma3

# expose the required ARMA server ports in the container
EXPOSE 2302-2306/udp

# load the entrypoint script to start the server
ENTRYPOINT ["/home/arma3/entrypoint.sh"]
