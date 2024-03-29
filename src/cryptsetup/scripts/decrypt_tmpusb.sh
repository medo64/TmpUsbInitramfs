#!/bin/sh
# decrypt_tmpusb - to use in /etc/crypttab as keyscript
#  Loads password from TmpUsb drive and caches it in kernel keyring.
#  The same password is used for for cryptdevices with the same identifier.
#  The keyfile parameter, which is the third field from /etc/crypttab, is
#  used as identifier in this keyscript.
#
# sample crypttab entries:
# test1   /dev/sda1    test_pw         luks,keyscript=decrypt_tmpusb
# test2   /dev/sda2    test_pw         luks,keyscript=decrypt_tmpusb
# test3   /dev/sda3    test_other_pw   luks,keyscript=decrypt_tmpusb
#
#  test1 and test2 have the same identifier thus test2 does not need a password
#  typed in manually
#
# This script is based on decrypt_keyctl.sh from cryptsetup package.

die() {
    echo "$@" >&2
    exit 1
}

if [ -z "${CRYPTTAB_KEY:-}" ] || [ "$CRYPTTAB_KEY" = "none" ]; then
    # store the passphrase in the key name used by systemd-ask-password
    ID_="cryptsetup"
    IDFILE_=
else
    # the keyfile given from crypttab is used as identifier in the keyring
    # including the prefix "cryptsetup:"
    ID_="cryptsetup:$CRYPTTAB_KEY"
    IDFILE_="$CRYPTTAB_KEY.pwd"
fi

TIMEOUT_='60'
ASKPASS_='/lib/cryptsetup/askpass'
PROMPT_="Caching passphrase for ${CRYPTTAB_NAME}: "

if ! KID_="$(keyctl search @u user "$ID_" 2>/dev/null)" || [ -z "$KID_" ] || [ "$CRYPTTAB_TRIED" -gt 0 ]; then
    # check for TmpUsb with given identifier
    if [ -n "$IDFILE_" ] && [ -f "/tmpusb/$IDFILE_" ]; then
        # since there is a key file with ID name, use it
        KEY_="$(cat /tmpusb/$IDFILE_)"
    elif [ -f "/tmpusb/$(hostname).pwd" ]; then
        # if there is no key file with ID name, try to use hostname
        KEY_="$(cat /tmpusb/$(hostname).pwd)"
    elif [ -f "/tmpusb/passphrase.pwd" ]; then
        # try passphrase.pwd if all else fails
        KEY_="$(cat /tmpusb/passphrase.pwd)"
    elif [ -z "$KID_" ]; then
        # key not found or wrong, ask the user
        KEY_="$($ASKPASS_ "$PROMPT_")" || die "Error executing $ASKPASS_"
    fi

    if [ -n "$KID_" ]; then
        # I have cached wrong password and now i may use either `keyctl update`
        # to update $KID_ or just unlink old key, and add new. With `update` i
        # may hit "Key has expired", though. So i'll go "unlink and add" way.
        keyctl unlink "$KID_" @u
        KID_=""
    fi

    KID_="$(printf "%s" "$KEY_" | keyctl padd user "$ID_" @u)"
    [ -n "$KID_" ] || die "Error adding passphrase to kernel keyring"

    if ! keyctl timeout "$KID_" "$TIMEOUT_"; then
        keyctl unlink "$KID_" @u
        die "Error setting timeout on key ($KID_), removing"
    fi
else
    echo "Using cached passphrase for ${CRYPTTAB_NAME}." >&2
fi

keyctl pipe "$KID_"
