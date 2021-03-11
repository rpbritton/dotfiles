#!/bin/bash

# create desktops
# create_desktops() {
#     bspc monitor any -d
# }

# get the desktop
get_desktop() {
    bspc query -D -d focused --names | grep -E "^[0-9]+-[0-9]+-active$" | cut -d "-" -f 2
}
# get the workspace
get_workspace() {
    bspc query -D -d focused --names | grep -E "^[0-9]+-[0-9]+-active$" | cut -d "-" -f 1
}

# go to desktop
go_to_desktop() {
    # see if workspace is included
    if [[ $1 =~ ^[0-9]+- ]]
    then
        workspace=$(echo $1 | cut -d "-" -f 1)
        desktop=$(echo $1 | cut -d "-" -f 2)
    else
        workspace=$(get_workspace)
        desktop=$1
    fi

    # see if need to add desktop
    if [[ $desktop =~ ^(\+|-)[0-9]+$ ]]
    then
        desktop=$(($(get_desktop) $desktop))
    fi

    # go to desktop
    name=$(bspc query -D --names | grep -E "^$workspace-$desktop")
    bspc desktop $name --focus
}
# go to workspace
go_to_workspace() {
    # see if need to add workspace
    if [[ $1 =~ ^(\+|-)[0-9]+$ ]]
    then
        workspace=$(($(get_workspace) $1))
    else
        workspace=$1
    fi

    # go to desktop
    name=$(bspc query -D --names | grep -E "^$workspace-[0-9]+-active")
    bspc desktop $name --focus
}

# send to desktop
send_to_desktop() {

}
# send to workspace
send_to_workspace() {

}

while test $# -gt 0
do
	case "$1" in
		--get-desktop) get_desktop; exit ;;
		--get-workspace) get_workspace; exit ;;
        --go-to-desktop) go_to_desktop $2; exit ;;
        --go-to-workspace) go_to_workspace $2; exit ;;
		*)
			echo "unexpected: $1"
			exit 1
			;;
	esac
done