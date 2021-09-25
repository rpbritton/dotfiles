#!/bin/bash

# ---------------------------------------------------
# Creating a new disk:
# * Following: https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption
# * Create disk:
# 	* # cryptsetup luksFormat /dev/sdX
# * Create key:
# 	* # dd if=/dev/urandom of=/root/keyfile bs=1024 count=4
# 	* # cryptsetup luksAddKey /dev/sdX /root/<keyfile>
# * Create a backup of the header
#	* # cryptsetup luksHeaderBackup /dev/sdX --header-backup-file <file>.img
#	* This doesn't have to be encrypted, change the permissions to read
# * Get the uuid
#	* lsblk -nro UUID /dev/sdX
# * Format the disk
# 	* # udisksctl unlock -b /dev/sdX
# 	* # mkfs.ext4 /dev/dm-X -L <backup_disk_label>
# * Mount the disk
#	* # udisksctl mount -b /dev/dm-X
# * Create the backups folder
# 	* # mkdir /run/media/root/<backup_disk_name>/backups
# ---------------------------------------------------

BACKUP_DISK_UUID="0f0652d9-91a4-4182-ae56-a11a6c696f55"
BACKUP_DISK_LABEL="1tb-nvme-wd"
BACKUP_DISK_KEY="/root/backup_1tb-nvme-wd_key"

exit_the_program () {
    [[ $# != 1 ]] && echo "no exit message" || echo $1
    exit 1
}

[[ "$EUID" != 0 ]] && exit_the_program "please run as root"
[[ $# == 0 ]] && exit_the_program "no arguments"

is_mounted () {
    findmnt -rno SOURCE "/dev/disk/by-label/$BACKUP_DISK_LABEL" > /dev/null
}

unmount_backup_disk () {
    is_mounted || return
    echo "--- starting unmount process ---"
    udisksctl unmount -b "/dev/disk/by-label/$BACKUP_DISK_LABEL" || exit_the_program "failed to unmount"
    udisksctl lock -b "/dev/disk/by-uuid/$BACKUP_DISK_UUID" || exit_the_program "failed to lock"
}

mount_backup_disk () {
    is_mounted && return
    echo "--- starting mount process ---"
    udisksctl unlock -b "/dev/disk/by-uuid/$BACKUP_DISK_UUID" --key-file $BACKUP_DISK_KEY || exit_the_program "failed to unlock"
    udisksctl mount -b "/dev/disk/by-label/$BACKUP_DISK_LABEL" || exit_the_program "failed to mount"
}

run_backup () {
    is_mounted || mount_backup_disk
    echo "--- starting backup process ---"
    rsnapshot -V sync || exit_the_program "failed to sync"
    rsnapshot -V $1 || exit_the_program "failed to create snapshot"
}

is_mounted && END_STATE=mounted || END_STATE=unmounted

while [[ $# -gt 0 ]]
do
    case $1 in
        -m|--mount)
            shift 1
            END_STATE=mounted
        ;;
        -u|--unmount)
            shift 1
            END_STATE=unmounted
        ;;
        -b|--backup)
            shift 1
            [[ ! $1 =~ ^(daily|weekly|monthly)$ ]] && exit_the_program "unknown type '$1', use: daily, weekly, monthly"
            BACKUP_TYPE=$1
            shift 1
        ;;
        -*) exit_the_program "unknown option '$1'" ;;
        *) exit_the_program "unexpected argument '$1'" ;;
    esac
done

[[ ! -z "$BACKUP_TYPE" ]] && run_backup $BACKUP_TYPE
[[ $END_STATE == mounted ]] && mount_backup_disk || unmount_backup_disk
