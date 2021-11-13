#!/bin/sh -e

PREREQ="udev"
prereqs() {
    echo "$PREREQ"
}

case $1 in
    prereqs)
        prereqs
        exit 0
    ;;
esac


echo -n "Waiting for TmpUsb"
for I in `seq 1 20`; do
    PARTITION=`ls /dev/disk/by-id/usb-*_TmpUsb_*-part1 2>/dev/null | sed -n 1p`  # use the first one
    if [ -e "$PARTITION" ]; then break; fi
    echo -n .
    sleep 1
done
echo
echo "Using $PARTITION"

sleep 2

if [ -e "$PARTITION" ]; then
    echo "Mounting $PARTITION..."
    mkdir /tmpusb
    mount -t vfat -o ro "$PARTITION" /tmpusb  # mount to root as /mnt might not be available here
    if [ $? -eq 0 ]; then
        exit 0
    else
        echo "Error mounting $PARTITION" >&2
    fi
else
    echo "Cannot find TmpUsb partition" >&2
fi

exit 1
