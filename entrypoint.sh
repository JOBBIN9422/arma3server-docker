#!/bin/bash

echo "START ENTRYPOINT.SH"

if [[ "${UPDATE_SERVER}" == "true" ]]; then
    # download ARMA 3 server and creator DLCs
    echo "begin download ARMA 3 server"
    steamcmd +force_install_dir /home/arma3/arma3server \
             +login ${STEAM_USER} ${STEAM_PASS} \
             +app_update 233780 -beta creatordlc validate \
             +quit 
fi

# read the modlist and download each mod 
echo "begin processing modlist.txt"
while IFS= read -r line; do
    echo "begin download mod ${line}"
    mod_id=$(echo ${line} | cut -d ',' -f 1)
    mod_symlink_name=$(echo ${line} | cut -d ',' -f 2)

    if [[ "${UPDATE_MODS}" == "true" ]]; then
        # download the mod via steamcmd
        steamcmd +login ${STEAM_USER} ${STEAM_PASS} \
    	         +workshop_download_item 107410 ${mod_id} +quit
    fi

    mod_path="/home/arma3/.local/share/Steam/steamapps/workshop/content/107410/${mod_id}"
    
    # recursively lowercase everything in the downloaded mod folder (Gemini told me how to do this - fair warning)
    echo "normalizing case for mod ${mod_id}..."
    find "$mod_path" -depth -exec bash -c '
        for item; do
            dir=$(dirname "$item")
            base=$(basename "$item")
            lower=$(echo "$base" | tr "[:upper:]" "[:lower:]")
            if [ "$base" != "$lower" ]; then
                # Move only if the name actually changed to avoid errors
                mv "$item" "$dir/$lower"
            fi
        done
    ' _ {} +

    # symlink the mod content into the server directory
    echo "create symlink ${mod_symlink_name}"
    ln -sf "$mod_path" "/home/arma3/arma3server/${mod_symlink_name}"

    # append the mod name to the -mod command line option
    mod_cmd_line_str="${mod_symlink_name};${mod_cmd_line_str}"
done < "modlist.txt"

# load the expansions from expansionlist.txt
echo "begin processing expansionlist.txt"
while IFS= read -r line; do
    mod_cmd_line_str="${line};${mod_cmd_line_str}"
done < "expansionlist.txt"

echo "mod list: ${mod_cmd_line_str}"

# start the server
echo "start ARMA 3 server"
./arma3server_x64 -name=server -config=server.cfg -mod="${mod_cmd_line_str}" -malloc=system &
SERVER_PID=$!

# wait for the server to init before spawning HCs
sleep 30

if [[ "${NUM_HEADLESS_CLIENTS}" -gt 0 ]]; then
    # start headless clients
    for i in $(seq 1 "${NUM_HEADLESS_CLIENTS}")
    do
        echo "start Headless Client #$i"
        ./arma3server_x64 -client -connect=127.0.0.1 -password="${SERVER_PASS}" -mod="${mod_cmd_line_str}" -name="HC_${i}" &
    done
fi

wait $SERVER_PID
