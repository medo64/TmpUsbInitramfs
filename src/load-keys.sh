#!/bin/sh -e

# mount tmpusb
sh -e /usr/share/initramfs-tools/scripts/init-premount/tmpusb-mount

# load keys
echo "Checking for unavailable datasets"
DATASETS=`zfs list -o name,keystatus,keylocation | grep unavailable | grep 'file:///tmpusb/' | awk '{print $1}'`
for DATASET in $DATASETS; do
    echo "Attempting to unlock dataset $DATASET"
    /usr/sbin/zfs load-key -r $DATASET || true
done

# unmount tmpusb
sh -e /usr/share/initramfs-tools/scripts/init-bottom/tmpusb-umount
