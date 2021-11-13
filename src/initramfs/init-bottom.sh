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


if [ -e "/tmpusb" ]; then
    echo "Unmounting $PARTITION..."
    umount /tmpusb
    rmdir /tmpusb
fi
