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
    echo "Unmounting /tmpusb"
    for WAIT in 1 1 2; do                                                       # give it a few tries
        umount /tmpusb && break
        sleep $WAIT
    done

    echo "Removing /tmpusb"
    rmdir /tmpusb 2>/dev/null || true                                           # continue even if we cannot remove directory
fi
