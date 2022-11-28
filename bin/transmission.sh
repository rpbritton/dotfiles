#!/bin/bash

. $HOME/bin/secrets/vpn.sh
PORT=9091

echo "URL: 'http://localhost:$PORT'"

case "$1" in
    run)
        docker run --cap-add=NET_ADMIN -d \
        --name transmission \
        -v $HOME/Videos:/data \
        -e OPENVPN_PROVIDER="$OPENVPN_PROVIDER" \
        -e OPENVPN_CONFIG="$OPENVPN_CONFIG" \
        -e OPENVPN_USERNAME="$OPENVPN_USERNAME" \
        -e OPENVPN_PASSWORD="$OPENVPN_PASSWORD" \
        -e LOCAL_NETWORK=192.168.0.0/16 \
        --log-driver json-file \
        --log-opt max-size=10m \
        -p $PORT:$PORT \
        haugene/transmission-openvpn
    ;;
    
    start)
        docker start transmission
    ;;
    
    stop)
        docker stop transmission
    ;;
    
    rm)
        docker rm transmission
    ;;
    
    *)
        echo "Unknown argument '$1'"
        exit 1
    ;;
esac
