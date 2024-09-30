#!/bin/env bash

## Manual chroot. Machine specific.
## To be used only if you did not chroot immemdiately after the ArchLinux installation

## mount raw btrfs volume
RAW_DEV=/dev/nvme0n1p2
mkdir /btrfs
mount $RAW_DEV /btrfs

TARGET_MOUNT=/mnt

## Get subvolumes
btrfs subvolume list /btrfs | while read -r V; do
  _id=$(awk '{print $2}' <<< "$V")
  _path=$(awk '{print $9}' <<< "$V")
  mount -o subvolid="$_id" $RAW_DEV "$TARGET_MOUNT${_path#root}"
done

mount --bind /proc $TARGET_MOUNT/proc
mount --bind /sys $TARGET_MOUNT/sys
mount --bind /dev $TARGET_MOUNT/dev
mount --bind /run $TARGET_MOUNT/run

mount /dev/nvme0n1p1 $TARGET_MOUNT/boot/efi
mount -t efivarfs efivarfs $TARGET_MOUNT/sys/firmware/efi/efivars

chroot $TARGET_MOUNT bash
