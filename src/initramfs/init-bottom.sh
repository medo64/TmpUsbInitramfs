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
    umount /tmpusb 2>/dev/null || ( sleep 1 && umount /tmpusb 2>/dev/null || true )  # give it a two tries
    rmdir /tmpusb 2>/dev/null || true                                                # continue even if we cannot remove directory
fi
