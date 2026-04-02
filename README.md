# Containerized ARMA 3 Server
This project builds a containerized ARMA 3 server from a Debian+steamcmd base image.

## Prerequisites
- Docker
- Docker Compose
- A Steam account which owns ARMA 3 + any of the desired additional content you want to host

## Installation
1. Clone the repo.
2. Create the following directories inside the root of the source tree:
    - `arma3-server-mount`
    - `arma3-profiles`
3. If you want to add mods, create a file named `modlist.txt` based on the included template:
    - Place `modlist.txt` in `arma3-server-mount`
    - For each mod you want to install, add a line with this format:
        - `steam_workshop_mod_id,mod-name`
        - the `mod-name` should be all lowercase and not contain spaces or other invalid path characters (see Linux file naming conventions).
4. If you want to load any of the ARMA 3 Creator DLC, create a file named `expansionlist.txt` based on the included template:
    - Place `expansionlist.txt` in `arma3-server-mount`
    - For each expansion you want to load, add a line with the all-lowercase folder name of that expansion:
        - `vn`: SOG Prairie Fire
        - `gm`: Global Mobilization
        - `spe`: Spearhead 1944
        - `rf`: Reaction Forces
        - `ef`: Expeditionary Forces
        - `ws`: Western Sahara
        - `csla`: SCLA Iron Curtain
5. Run `chown -R 1000:1000` on each of the directories from step 2.
6. Create a file named `.env` in the root of the source tree with the following values:
    - `STEAM_USER`: The username of the steam account which will run the ARMA 3 server.
    - `STEAM_PASS`: The password of the steam account which will run the ARMA 3 server.
    - `UPDATE_SERVER`: `true/false (default if not present)`: Whether or not to update & validate the ARMA 3 server installation at startup.
    - `UPDATE_MODS`: `true/false (default if not present)`: Whether or not to update & validate the ARMA 3 workshop content at startup.
    - `NUM_HEADLESS_CLIENTS`: `numeric value (default 0 if not present)`: How many headless clients to spawn in addition to the server.
7. Start the container via `docker compose up arma3server -d` or execute the included `start.sh`.
