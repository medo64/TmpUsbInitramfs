#!/bin/sh -e

if [ -t 1 ]; then
    ANSI_RESET='\e[0m'
    ANSI_RED='\e[31m'
    ANSI_GREEN='\e[32m'
    ANSI_CYAN='\e[36m'
fi

EXIT_CODE=0

# adjust initramfs script
APP_DIR=/usr/lib/tmpusb-zfs-passphrase
IRF_DIR=/usr/share/initramfs-tools/scripts
if [ -e $IRF_DIR/zfs ]; then
    if grep -q 'KEYLOCATION=prompt' $IRF_DIR/zfs; then
        echo "ZFS initramfs script [${ANSI_GREEN}OK${ANSI_RESET}]"
    else
        echo "ZFS initramfs script [${ANSI_CYAN}UPDATE${ANSI_RESET}]"

        cp $APP_DIR/initramfs/init-premount $IRF_DIR/init-premount/tmpusb
        cp $APP_DIR/initramfs/init-bottom $IRF_DIR/init-bottom/tmpusb
        chmod 755 $IRF_DIR/init-premount/tmpusb
        chmod 755 $IRF_DIR/init-bottom/tmpusb

        mkdir -p $APP_DIR/backup/
        cp $IRF_DIR/zfs $APP_DIR/backup/zfs

        if grep -q 'If root dataset is encrypted...' $IRF_DIR/zfs; then
            sed -i 's/load-key/load-key -L prompt/' $IRF_DIR/zfs
            sed -i '0,/load-key/ {s/-L prompt//}' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\t$ZFS load-key "${ENCRYPTIONROOT}"' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\tTPOOLS=`$ZPOOL import | grep "^   pool:" | cut -d: -f2`' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\tfor TPOOL in $TPOOLS; do' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\t\t$ZPOOL import $TPOOL' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\t\t$ZFS load-key $TPOOL' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\tdone' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i \\t\t\tKEYLOCATION=prompt' $IRF_DIR/zfs
            sed -i '/KEYSTATUS=/i\\' $IRF_DIR/zfs
            if update-initramfs -u; then
                echo "ZFS initramfs script update [${ANSI_GREEN}OK${ANSI_RESET}]"
            else
                echo "ZFS initramfs script update [${ANSI_RED}NOK${ANSI_RESET}]"
                EXIT_CODE=11
            fi
        else
            echo "ZFS initramfs script [${ANSI_RED}UNKNOWN${ANSI_RESET}]"
            EXIT_CODE=12
        fi
    fi
else
    echo "${ANSI_RED}Cannot find ZFS initramfs-tools script${ANSI_RESET}" >&2
    EXIT_CODE=10
fi

# adjust zfs-mount service
ZFS_MOUNT_SERVICE_FILE=/usr/lib/systemd/system/zfs-mount.service
if [ -e $ZFS_MOUNT_SERVICE_FILE ]; then
    if grep -q 'ExecStartPre=/usr/lib/tmpusb-zfs-passphrase/bin/tmpusb-zfs-load-keys' $ZFS_MOUNT_SERVICE_FILE; then
        echo "ZFS mount service [${ANSI_GREEN}OK${ANSI_RESET}]"
    else
        echo "ZFS mount service [${ANSI_CYAN}UPDATE${ANSI_RESET}]"
        sed -i '/^ExecStart=/i\ExecStartPre=/usr/lib/tmpusb-zfs-passphrase/bin/tmpusb-zfs-load-keys' $ZFS_MOUNT_SERVICE_FILE
        if systemctl daemon-reload; then
            echo "ZFS mount service update [${ANSI_GREEN}OK${ANSI_RESET}]"
        else
            echo "ZFS mount service update [${ANSI_RED}NOK${ANSI_RESET}]"
            EXIT_CODE=21
        fi
    fi
fi

exit $EXIT_CODE
