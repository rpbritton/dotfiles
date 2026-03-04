#!/bin/bash

set -e
CONTAINER_NAME="$1"

echo "Creating LXD container"
lxc launch ubuntu:jammy "$CONTAINER_NAME" --vm

echo "Importing SSH key"
until lxc exec "$CONTAINER_NAME" -- su ubuntu -c "ssh-import-id-lp rpbritton"
do
	echo "Retrying"
	sleep 1
done

echo "Adding SSH host to local config"
SSH_HOST="lxd-$CONTAINER_NAME"
IP_ADDRESS=$(lxc info "$CONTAINER_NAME" | yq '.Resources["Network usage"]["enp5s0"]["IP addresses"]["inet"]' | cut -d "/" -f 1)
cat <<EOF >> ~/.ssh/config_lxd
Host $SSH_HOST
    Hostname $IP_ADDRESS
    User ubuntu
    ForwardAgent yes
    ForwardX11 yes

EOF

echo "Adding SSH key for host checking"
ssh-keyscan $IP_ADDRESS >> ~/.ssh/known_hosts

echo "Copying git config"
scp ~/canonical/.gitconfig $SSH_HOST:~/.gitconfig

