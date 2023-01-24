#!/bin/bash

mkdir -p mkosi.cache
mkdir -p mkosi.workspace
ln -sf ../mkosi.cache rootfs/mkosi.cache
ln -sf ../mkosi.workspace rootfs/mkosi.workspace
ln -sf ../mkosi.cache swupdate-initramfs/mkosi.cache
ln -sf ../mkosi.workspace swupdate-initramfs/mkosi.workspace

# Build initramfs and kernel
mkosi -C swupdate-initramfs --force build

# Create unified kernel image for initramfs
# Instructions from https://wiki.archlinux.org/title/Unified_kernel_image#Manually
ARTIFACTS="swupdate-initramfs/artifacts"
osrel_offs=$(objdump -h "$ARTIFACTS/linuxx64.efi.stub" | awk 'NF==7 {size=strtonum("0x"$3); offset=strtonum("0x"$4)} END {print size + offset}')
cmdline_offs=$((osrel_offs + $(stat -Lc%s "$ARTIFACTS/os-release")))
linux_offs=$((cmdline_offs + $(stat -Lc%s "$ARTIFACTS/cmdline")))
initrd_offs=$((linux_offs + $(stat -Lc%s "$ARTIFACTS/vmlinuz")))
objcopy \
    --add-section .osrel="$ARTIFACTS/os-release" --change-section-vma .osrel=$(printf 0x%x $osrel_offs) \
    --add-section .cmdline="$ARTIFACTS/cmdline" \
    --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    --add-section .linux="$ARTIFACTS/vmlinuz" \
    --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    --add-section .initrd="swupdate-initramfs/image.cpio" \
    --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    "$ARTIFACTS/linuxx64.efi.stub" "swupdate-linux.efi"

rm -rf $ARTIFACTS

# Copy artifact from initramfs build dir to rootfs
mkdir -p rootfs/mkosi.extra/efi/EFI/Linux
mv swupdate-linux.efi rootfs/mkosi.extra/efi/EFI/Linux/a-swupdate-linux.efi

# Build rootfs
mkosi -C rootfs --force build
