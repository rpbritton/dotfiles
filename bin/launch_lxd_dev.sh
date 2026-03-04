#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [--vm] [--refresh] <container_name>"
    exit 1
}

VM=false
REFRESH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vm|-v)
            VM=true
            shift
            ;;
        --refresh|-r)
            REFRESH=true
            shift
            ;;
        -*)
            usage
            ;;
        *)
            CONTAINER_NAME="$1"
            shift
            ;;
    esac
done

[[ -z "$CONTAINER_NAME" ]] && usage

SSH_HOST="lxd-$CONTAINER_NAME"
SSH_CONFIG=~/.ssh/config_lxd

if $REFRESH; then
    echo "Refreshing existing instance: $CONTAINER_NAME"
else
    echo "Creating LXD instance: $CONTAINER_NAME"
    if $VM; then
        lxc launch ubuntu:jammy "$CONTAINER_NAME" --vm
    else
        lxc launch ubuntu:jammy "$CONTAINER_NAME"
    fi

    echo "Installing SSH key"
    until lxc exec "$CONTAINER_NAME" -- id ubuntu &>/dev/null; do
        echo "Waiting for ubuntu user..."
        sleep 1
    done
    lxc exec "$CONTAINER_NAME" -- su ubuntu -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    lxc file push ~/.ssh/id_coconut.pub "$CONTAINER_NAME/home/ubuntu/.ssh/authorized_keys" --uid 1000 --gid 1000 --mode 0600
fi

echo "Getting IP address"
IFACE=$($VM && echo "enp5s0" || echo "eth0")
until
    LXC_JSON=$(lxc list "$CONTAINER_NAME" --format json)
    IP_ADDRESS=$(echo "$LXC_JSON" | jq -r ".[0].state.network.\"$IFACE\".addresses[] | select(.scope==\"global\") | .address" | head -1)
    [[ -n "$IP_ADDRESS" && "$IP_ADDRESS" != "null" ]]
do
    echo "Waiting for IP address..."
    sleep 2
done
echo "IP address: $IP_ADDRESS"

# ssh-keygen/ssh-keyscan need IPv6 addresses wrapped in brackets
if [[ "$IP_ADDRESS" == *:* ]]; then
    SSH_ADDR="[$IP_ADDRESS]"
else
    SSH_ADDR="$IP_ADDRESS"
fi

echo "Updating SSH host config"
touch "$SSH_CONFIG"
if grep -q "^Host $SSH_HOST$" "$SSH_CONFIG"; then
    awk "/^Host $SSH_HOST\$/ { skip=1; next } skip && /^Host / { skip=0 } !skip" \
        "$SSH_CONFIG" > "$SSH_CONFIG.tmp" && mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
fi
cat <<EOF >> "$SSH_CONFIG"
Host $SSH_HOST
    Hostname $IP_ADDRESS
    User ubuntu
    ForwardAgent yes
    ForwardX11 yes

EOF

echo "Updating known_hosts"
ssh-keygen -R "$SSH_ADDR" 2>/dev/null || true
ssh-keygen -R "$SSH_HOST" 2>/dev/null || true
ssh-keyscan "$IP_ADDRESS" >> ~/.ssh/known_hosts

echo "Copying git config"
scp ~/canonical/.gitconfig "$SSH_HOST":~/.gitconfig

echo "Copying git-drop-squashed"
ssh "$SSH_HOST" "mkdir -p ~/.local/bin"
scp ~/.local/bin/git-drop-squashed "$SSH_HOST":~/.local/bin/git-drop-squashed

echo "Done"
