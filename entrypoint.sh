#!/bin/bash

echo "START ENTRYPOINT.SH"

# download ARMA 3 server and creator DLCs
if [[ "${UPDATE_SERVER}" == "true" ]]; then
    echo "begin download ARMA 3 server"
    steamcmd +force_install_dir /home/arma3/arma3server \
             +login ${STEAM_USER} ${STEAM_PASS} \
             +app_update 233780 -beta creatordlc validate \
             +quit 
fi

# read the modlist and download each mod 
echo "begin processing modlist.txt"
while IFS= read -r line; do
    # parse each line in the format "<mod-id>,<mod-desired-symlink-name>"
    echo "begin download mod ${line}"
    mod_id=$(echo ${line} | cut -d ',' -f 1)
    mod_symlink_name=$(echo ${line} | cut -d ',' -f 2)

    if [[ "${UPDATE_MODS}" == "true" ]]; then
        # download the mod via steamcmd
        steamcmd +login ${STEAM_USER} ${STEAM_PASS} \
    	         +workshop_download_item 107410 ${mod_id} +quit
    fi

    # the installation target for the current mod
    mod_path="/home/arma3/.local/share/Steam/steamapps/workshop/content/107410/${mod_id}"
    
    echo "normalizing case for mod ${mod_id}..."
    # Linux filesystem is case-sensitive. Some ARMA mods have file/dir names which aren't entirely lowercase.
    # Thus, we must force all-lowercase for workshop content.
    #
    # this is the method recommended on the BIS wiki - it relies on the 'rename' package which must be installed via apt in the Dockerfile
    #find "${mod_path}" -depth -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
    #
    # this is the bash-native method that Gemini recommended. I'm going to be real with you, I copypasted this without any alterations.
    # it seems to be more performant than the BIS method and doesn't rely on an external package, but it's hard to read.
    find "$mod_path" -depth -exec bash -c '
        for item; do
            dir=$(dirname "$item")
            base=$(basename "$item")
            lower=$(echo "$base" | tr "[:upper:]" "[:lower:]")
            if [ "$base" != "$lower" ]; then
                mv "$item" "$dir/$lower"
            fi
        done
    ' _ {} +

    # symlink the mod content into the server directory
    echo "create symlink ${mod_symlink_name}"
    ln -sf "${mod_path}" "/home/arma3/arma3server/${mod_symlink_name}"

    # append the mod name to the -mod command line option
    # The name of each mod folder/symlink must be added to the -mod command-line option.
    # Each mod identifier is semicolon-separated.
    mod_cmd_line_str="${mod_symlink_name};${mod_cmd_line_str}"
done < "modlist.txt"

# load the expansions from expansionlist.txt
# The -creatordlc flag installs all of the Creator DLC along with the ARMA server.
# Each DLC is located in the server directory with its name as a lowercased acronym
# For example, ws refers to Western Sahara.
# Each expansion that needs to be loaded must have its folder name passed to the -mod command line option
# As with the workshop mods, each identifier in the -mod string is semicolon-separated.
echo "begin processing expansionlist.txt"
while IFS= read -r line; do
    echo "adding expansion ${line} to -mod command"
    mod_cmd_line_str="${line};${mod_cmd_line_str}"
done < "expansionlist.txt"

echo "mod list: ${mod_cmd_line_str}"

# start the server
echo "start ARMA 3 server"
./arma3server_x64 -name=server -config=server.cfg -mod="${mod_cmd_line_str}" &
SERVER_PID=$!

# wait for the server to init before spawning HCs
#sleep 30
# wait for the server to open port 2302
echo "waiting for Arma 3 server to bind to port 2302..."
while ! ss -ulpn | grep -q ":2302"; do
    sleep 2
done

# start headless clients
echo "begin loading headless clients"
if [[ "${NUM_HEADLESS_CLIENTS}" -gt 0 ]]; then
    for i in $(seq 1 "${NUM_HEADLESS_CLIENTS}")
    do
        echo "start headless client #${i}"
        ./arma3server_x64 -client -connect=127.0.0.1 -password="${SERVER_PASS}" -mod="${mod_cmd_line_str}" -name="HC_${i}" -nosound -nopause -nosplash &
	sleep 60
    done
fi

wait $SERVER_PID
