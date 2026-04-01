# use debian-based steamcmd base image
FROM steamcmd/steamcmd:debian-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    procps \
    && rm -rf /var/lib/apt/lists/*

# create a user for running the server
RUN useradd -m arma3

# create and switch to the server install directory
USER arma3
WORKDIR /home/arma3/arma3server

# copy required files to the server install dir, set ownership & permissions
USER root
COPY server.cfg server.cfg
COPY entrypoint.sh entrypoint.sh
COPY modlist.txt modlist.txt
COPY expansionlist.txt expansionlist.txt
RUN chown arma3 entrypoint.sh
RUN chmod a+x entrypoint.sh
RUN chown arma3 server.cfg
RUN chown arma3 modlist.txt
RUN chown arma3 expansionlist.txt

USER arma3

# tell steamcmd where the server account's home dir is
ENV HOME=/home/arma3

# expose the required ARMA server ports in the container
EXPOSE 2302-2306/udp

# load the entrypoint script to start the server
ENTRYPOINT ["/home/arma3/arma3server/entrypoint.sh"]
