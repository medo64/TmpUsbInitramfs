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
for I in `seq 1 20`; do                                                                      # wait for maximum of 20 seconds
    PARTITIONS=`ls -1 /dev/disk/by-id/usb-*_TmpUsb_*-part1 2>/dev/null || true`              # get all TmpUsb partitions
    if [ "$PARTITIONS" != "" ]; then
        sleep 1                                                                              # wait to detect other USB devices
        PARTITIONS=`ls -1 /dev/disk/by-id/usb-*_TmpUsb_*-part1 2>/dev/null || true`          # get all again in case more gets detected
        if [ "$PARTITIONS" != "" ]; then break; fi
    fi
    echo -n .
    sleep 1
done
echo

if [ "$PARTITIONS" = "" ]; then
    echo "No TmpUsb found!" >&2
    exit 1
fi

for PARTITION in $PARTITIONS; do
    echo "Checking $PARTITION"

    if [ -e "$PARTITION" ]; then
        echo "Mounting $PARTITION to /tmpusb"
        mkdir /tmpusb
        MOUNT_STATUS=`mount -t vfat -o ro "$PARTITION" /tmpusb 2>/dev/null || echo "ERROR"`   # mount in / as /mnt might not be available here
        if [ "$MOUNT_STATUS" != "ERROR" ]; then
            FILE_COUNT=`ls -1 /tmpusb/ 2>/dev/null | wc -l`                                   # check if any files are present
            if [ "$FILE_COUNT" -gt 0 ]; then
                echo "Using $PARTITION (has $FILE_COUNT files)"
                exit 0
            else
                echo "No files found on $PARTITION!" >&2
                umount /tmpusb || ( sleep 1 && umount /tmpusb )                               # unmount if no files are there
            fi
        else
            echo "Error mounting $PARTITION!" >&2
        fi
        rmdir /tmpusb                                                                        # remove directory so it can be created again
    else
        echo "Cannot access TmpUsb partition!" >&2
    fi
done

echo "No TmpUsb partition with files detected!" >&2
exit 1
