# Using TmpUsb drive for boot passphrase storage

Contains all the scripts to allow boot-time mounting of disks by using
[TmpUsb](https://medo64.com/tmpusb) drive as a source for the passphrase.
If drive is not found, passphrase will be used as a fallback.


### Native ZFS

This package updates ZFS initramfs script to use TmpUsb drive for passphrase.
To use it just set `keylocation` and `keyformat`.

```bash
zfs set keylocation=file:///tmpusb/passphrase.pwd Tank
zfs set keyformat=passphrase Tank
```

While you can use just keylocation and read raw bytes from file, I recommend
using passphrase as that way you can always manually enter the key.


### CryptSetup (LUKS)

Assuming you setup your system with password, just adjust `keyscript` to use
`decrypt_tmpusb` and place passphrase.pwd onto your TmpUsb drive.

```plain
# sample crypttab entries:
# test1   /dev/sda1    none         luks,keyscript=decrypt_tmpusb
```

TmpUsb will be checked for the passphrase files in the following order:
* `<keyfileid>.pwd`
* `<hostname>.pwd`
* `passphrase.pwd`
