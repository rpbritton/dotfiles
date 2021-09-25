#!/bin/bash

# list of disks
declare -A DISKS
add_disk() {
    DISKS[$1,UUID]=$2
    DISKS[$1,KEY]=$3
}
add_disk "wd" "0f0652d9-91a4-4182-ae56-a11a6c696f55" "$HOME/bin/secrets/drivekeys/1tb-nvme-wd_key"

# get if encrypted
is_encrypted_disk() {
    FSTYPE=$(lsblk -nro UUID,FSTYPE | grep "^${DISKS[$1,UUID]}" | cut -d " " -f 2)
    [[ $FSTYPE == "crypto_LUKS" ]]
}

# get encrypted mapper path
mapped_ecrypted_path() {
    lsblk -nro UUID,PATH | grep "^${DISKS[$1,UUID]}" -A 1 | tail -n 1 | cut -d " " -f 2
}

# unmount
unmount_disk () {
    # check if encrypted
    if is_encrypted_disk $1
    then
        # unmount
        DISK_LOCATION=$(mapped_ecrypted_path $1)
        UNMOUNT_MSG=$(udisksctl unmount -b $DISK_LOCATION 2>&1)
        [[ $? != 0 ]] && [[ $UNMOUNT_MSG != *"is not mounted"* ]] && echo "failed to unmount: '$UNMOUNT_MSG'" && exit 1
        
        #encrypt
        DISK_LOCATION="/dev/disk/by-uuid/${DISKS[$1,UUID]}"
        LOCKED_MSG=$(udisksctl lock -b $DISK_LOCATION 2>&1)
        [[ $? != 0 ]] && [[ $LOCKED_MSG != *"is not a mountable filesystem"* ]] && echo "failed to lock: '$LOCKED_MSG'" && exit 1
    else
        # unmount
        DISK_LOCATION="/dev/disk/by-uuid/${DISKS[$1,UUID]}"
        UNMOUNT_MSG=$(udisksctl unmount -b $DISK_LOCATION 2>&1)
        [[ $? != 0 ]] && [[ $UNMOUNT_MSG != *"is not mounted"* ]] && echo "failed to unmount: '$UNMOUNT_MSG'" && exit 1
    fi
}

# mount
mount_disk () {
    DISK_LOCATION="/dev/disk/by-uuid/${DISKS[$1,UUID]}"
    
    # decrypt
    if is_encrypted_disk $1
    then
        UNLOCKED_MSG=$(udisksctl unlock -b $DISK_LOCATION --key-file ${DISKS[$1,KEY]} 2>&1)
        [[ $? != 0 ]] && [[ $UNLOCKED_MSG != *"already unlocked"* ]] && echo "failed to unlock: '$UNLOCKED_MSG'" && exit 1
        DISK_LOCATION=$(mapped_ecrypted_path $1)
    fi
    
    # mount
    MOUNT_MSG=$(udisksctl mount -b $DISK_LOCATION 2>&1)
    [[ $? != 0 ]] && [[ $MOUNT_MSG != *"already mounted"* ]] && echo "failed to mount: '$MOUNT_MSG'" && exit 1
    
    # list mount point
    echo "mounted at $(lsblk -nro PATH,MOUNTPOINTS | grep "^$DISK_LOCATION" | cut -d " " -f 2)"
}

# handle arguments
case $1 in
    m|mount)
        mount_disk $2
        shift 2
    ;;
    u|unmount)
        unmount_disk $2
        shift 2
    ;;
    *)
        echo "unexpected argument '$1'"
        exit 1
    ;;
esac
