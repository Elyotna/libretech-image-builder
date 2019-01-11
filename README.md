LibreTech CC Ubuntu 16.04 Image Build Script
============================================

Prerequesite
============

On an Ubuntu 18.04+ x86_64/AMD64 system :

```
# sudo apt install build-essential bc git qemu debootstrap qemu-user-static parted dosfstools bison flex libssl-dev
```

NOTE: On Ubuntu 18.04, please fetch the qemu-user-static package from Ubuntu 18.10.
(for instance: http://fr.archive.ubuntu.com/ubuntu/pool/universe/q/qemu/qemu-user-static_2.12+dfsg-3ubuntu8.2_amd64.deb)

Steps
=====

```
# ./init.sh
# ./build_linux.sh
# sudo ./linux-image.sh
# sudo ./clean.sh
```

Image will be in the same directory.

Simply dd it onto an SDCard like :

```
# sudo dd if=aml-s905x-cc-ubuntu-cosmic-linux-4.19.5-dirty-2018-11-30.img of=/dev/mmcblk0 bs=8M
```

Account details
=====
- Username: libre
- Password: computer

- Username: root
- Password: root

Enjoy !
