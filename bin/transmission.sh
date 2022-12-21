#!/bin/bash

. $HOME/bin/secrets/vpn.sh
PORT=9091

case "$1" in
    start)
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
        
        echo "Starting on URL: 'http://localhost:$PORT'"
    ;;
    
    stop)
        docker stop transmission
        docker rm transmission
    ;;
    
    *)
        echo "Unknown argument '$1', use 'start' or 'stop'"
        exit 1
    ;;
esac
