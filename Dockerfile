# use debian-based steamcmd base image
FROM steamcmd/steamcmd:debian-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    procps \
    && rm -rf /var/lib/apt/lists/*

# create a user for running the server
RUN groupadd -g 1000 arma3 && \
    useradd -u 1000 -g arma3 -m arma3

# create and switch to the server install directory
USER root
#WORKDIR /home/arma3/arma3server

COPY entrypoint.sh /home/arma3/entrypoint.sh
RUN chown arma3 /home/arma3/entrypoint.sh
RUN chmod a+x /home/arma3/entrypoint.sh

USER arma3
# copy required files to the server install dir, set ownership & permissions
#USER root
#COPY server.cfg server.cfg
#COPY entrypoint.sh entrypoint.sh
#COPY modlist.txt modlist.txt
#COPY expansionlist.txt expansionlist.txt
#RUN chown arma3 entrypoint.sh
#RUN chmod a+x entrypoint.sh
#RUN chown arma3 server.cfg
#RUN chown arma3 modlist.txt
#RUN chown arma3 expansionlist.txt

WORKDIR /home/arma3/arma3server

# tell steamcmd where the server account's home dir is
ENV HOME=/home/arma3

# expose the required ARMA server ports in the container
EXPOSE 2302-2306/udp

# load the entrypoint script to start the server
ENTRYPOINT ["/home/arma3/entrypoint.sh"]
