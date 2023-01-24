# Building OS with mkosi using swupdate for updates

## Tested workflow

### Build

> $ sudo ./build.sh

### Start qemu

> $ sudo mkosi -C rootfs qemu

### Boot into initramfs from rootfs

> $ bootctl set-oneshot 10-swupdate-initramfs.efi
> $ reboot


