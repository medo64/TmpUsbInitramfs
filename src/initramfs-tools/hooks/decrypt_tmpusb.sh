#!/bin/sh
set -e

PREREQ="cryptroot"

prereqs()  {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions

# Check whether cryptroot hook has installed tmpusb_keyctl script
if [ ! -x "$DESTDIR/lib/cryptsetup/scripts/decrypt_tmpusb" ]; then
    exit 0
fi

copy_exec /usr/lib/cryptsetup/scripts/decrypt_tmpusb
copy_exec /lib/cryptsetup/askpass
copy_exec /bin/keyctl
exit 0
