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


if [ -t 1 ]; then
    ANSI_RESET='\e[0m'
    ANSI_RED='\e[31m'
    ANSI_CYAN='\e[36m'
fi

echo -n "Waiting for TmpUsb"
for I in `seq 1 20`; do
    PARTITION=`ls --color=never /dev/disk/by-id/usb-*_TmpUsb_*-part1 | head -1`  # use the first one
    if [ -e "$PARTITION" ]; then break; fi
    echo -n .
    sleep 1
done
echo
echo "Using ${ANSI_CYAN}$PARTITION${ANSI_RESET}"

sleep 2

if [ -e "$PARTITION" ]; then
    mkdir /tmpusb
    mount -t vfat -o ro "$PARTITION" /tmpusb  # mount to root as /mnt might not be available here
    if [ $? -eq 0 ]; then
        exit 0
    else
        echo "${ANSI_RED}Error mounting $PARTITION${ANSI_RESET}" >&2
    fi
else
    echo "${ANSI_RED}Cannot find TmpUsb partition${ANSI_RESET}" >&2
fi

exit 1
