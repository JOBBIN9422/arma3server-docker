docker run -d \
    --name arma3server \
    --env-file .env \
    -p 2301:2301/udp \
    -p 2302:2302/udp \
    -p 2303:2303/udp \
    -p 2304:2304/udp \
    -p 2305:2305/udp \
    -p 2306:2306/udp \
    arma3server
