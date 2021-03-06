#!/bin/bash
set -x
export PATH=$PWD/gcc-linaro-6.4.1-2017.08-x86_64_aarch64-linux-gnu/bin:$PATH
#RAM=1
RAM=0
#PROXY="http://127.0.0.1:3142"
PROXY=""
IMAGE_FOLDER="img/"
IMAGE_VERSION="linux"
IMAGE_DEVICE_TREE="amlogic/meson-gxl-s905x-libretech-cc"
UBUNTU_RELEASE="cosmic"
UBUNTU_VERSION="18.10"
if [ ! -z "$1" ]; then
	IMAGE_VERSION="$1"
fi
if [ ! -z "$2" ]; then
	IMAGE_DEVICE_TREE="$2"
fi
if [ ! -f "$IMAGE_VERSION/arch/arm64/boot/dts/$IMAGE_DEVICE_TREE.dts" ]; then
	echo "Missing Device Tree"
	exit 1
fi
if [ ! -f ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz ]; then
	echo "Missing Ubuntu Base tarball"
	exit 1
fi
set -eux -o pipefail
IMAGE_LINUX_LOADADDR="0x1080000"
IMAGE_LINUX_VERSION=`head -n 1 $IMAGE_VERSION/include/config/kernel.release | xargs echo -n`
IMAGE_FILE_SUFFIX="$(date +%F)"
IMAGE_FILE_NAME="aml-s905x-cc-ubuntu-${UBUNTU_RELEASE}-${IMAGE_VERSION}-${IMAGE_LINUX_VERSION}-${IMAGE_FILE_SUFFIX}.img"
if [ $RAM -ne 0 ]; then
	IMAGE_FOLDER="ram/"
fi
mkdir -p "$IMAGE_FOLDER"
if [ $RAM -ne 0 ]; then
	mount -t tmpfs -o size=1G tmpfs $IMAGE_FOLDER
fi
truncate -s 4G "${IMAGE_FOLDER}${IMAGE_FILE_NAME}"
fdisk "${IMAGE_FOLDER}${IMAGE_FILE_NAME}" <<EOF
o
n
p
1
2048
524287
a
t
b
n
p
2
524288

p
w

EOF
IMAGE_LOOP_DEV="$(losetup --show -f ${IMAGE_FOLDER}${IMAGE_FILE_NAME})"
IMAGE_LOOP_DEV_BOOT="${IMAGE_LOOP_DEV}p1"
IMAGE_LOOP_DEV_ROOT="${IMAGE_LOOP_DEV}p2"
partprobe "${IMAGE_LOOP_DEV}"
mkfs.vfat -n BOOT "${IMAGE_LOOP_DEV_BOOT}"
mkfs.ext4 -L ROOT "${IMAGE_LOOP_DEV_ROOT}"
mkdir -p p1 p2
mount "${IMAGE_LOOP_DEV_BOOT}" p1
mount "${IMAGE_LOOP_DEV_ROOT}" p2
sync
umount p2
mount -o defaults,noatime "${IMAGE_LOOP_DEV_ROOT}" p2

PATH=$PWD/gcc/bin:$PATH make -C ${IMAGE_VERSION} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- install INSTALL_PATH=$PWD/p1/
cp ${IMAGE_VERSION}/arch/arm64/boot/Image p1/Image
mkdir -p p1/$(dirname $IMAGE_DEVICE_TREE)
cp ${IMAGE_VERSION}/arch/arm64/boot/dts/$IMAGE_DEVICE_TREE.dtb p1/$(dirname $IMAGE_DEVICE_TREE)
PATH=$PWD/gcc/bin:$PATH make -C ${IMAGE_VERSION} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- headers_install INSTALL_HDR_PATH=$PWD/p2/usr/
PATH=$PWD/gcc/bin:$PATH make -C ${IMAGE_VERSION} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_install INSTALL_MOD_PATH=$PWD/p2/

# Mali Kernel driver
git clone https://github.com/superna9999/meson_gx_mali_450 -b DX910-SW-99002-r7p0-00rel1_meson_gx --depth 1
(cd meson_gx_mali_450 && KDIR=$PWD/../$IMAGE_VERSION ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- ./build.sh)
VER=$(ls p2/lib/modules/)
sudo cp meson_gx_mali_450/mali.ko p2/lib/modules/$VER/kernel/
sudo depmod -b p2/ -a $VER
rm -fr meson_gx_mali_450

# copy ubuntu base
tar xfz ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz -C p2/

# Install meson firmware for the VDEC
if [ ! -d meson-firmware ]
then
	git clone https://github.com/chewitt/meson-firmware.git
fi

mkdir -p p2/lib/firmware/
cp -r meson-firmware/meson p2/lib/firmware/

mkdir -p p2/etc/apt/apt.conf.d p2/etc/dpkg/dpkg.cfg.d
echo "force-unsafe-io" > "p2/etc/dpkg/dpkg.cfg.d/dpkg-unsafe-io"
mkdir -p p2/usr/bin
cp $(which "qemu-aarch64-static") p2/usr/bin
tee p2/etc/fstab <<EOF
/dev/root	/	ext4	defaults,noatime 0 1
EOF
if [ -n "$PROXY" ] ; then
	tee "p2/etc/apt/apt.conf.d/30proxy" <<EOF
Acquire::http::proxy "http://127.0.0.1:3142";
EOF
fi

cp stage2.sh p2/root

# Copy mutter, xserver, chromium packages modified for mali
cp mutter/build/gir1.2-mutter-3_*.deb mutter/build/libmutter-3-0_*.deb mutter/build/mutter_*.deb mutter/build/mutter-common_*.deb chromium/chromium_browser_71.0.3545.0_18.04_arm64.deb xserver/build/*.deb p2/root

# Run stage2 from chroot
mount -o bind /dev p2/dev
mount -o bind /dev/pts p2/dev/pts
chroot p2 /root/stage2.sh
umount p2/dev/pts
umount p2/dev

rm p2/root/*.deb
rm p2/usr/bin/qemu-aarch64-static
rm p2/root/stage2.sh

if [ -n "$PROXY" ] ; then
	rm p2/etc/apt/apt.conf.d/30proxy
fi
rm p2/etc/dpkg/dpkg.cfg.d/dpkg-unsafe-io

# HiKey libMali for Mali-450
wget https://developer.arm.com/-/media/Files/downloads/mali-drivers/user-space/hikey/mali-450_r7p0-01rel0_linux_1arm64.tar.gz
tar xfz mali-450_r7p0-01rel0_linux_1arm64.tar.gz
rm mali-450_r7p0-01rel0_linux_1arm64.tar.gz

# Notice: We must distribute Mali License along the binary
mkdir -p p2/usr/share/doc/mali-450_r7p0-01rel0_linux_1arm64/
cp mali-450_r7p0-01rel0_linux_1+arm64/END_USER_LICENCE_AGREEMENT.txt p2/usr/share/doc/mali-450_r7p0-01rel0_linux_1arm64/
ln -s /usr/share/doc/mali-450_r7p0-01rel0_linux_1arm64/END_USER_LICENCE_AGREEMENT.txt p2/home/libre/END_USER_LICENCE_AGREEMENT.txt

cp mali-450_r7p0-01rel0_linux_1+arm64/wayland-drm/libMali.so p2/usr/lib/aarch64-linux-gnu/
chmod 644 p2/usr/lib/aarch64-linux-gnu/libMali.so
chown root:root p2/usr/lib/aarch64-linux-gnu/libMali.so

mkdir -p p2/usr/lib/mesa-disabled/
cd p2/usr/lib/aarch64-linux-gnu/
# Move mesa EGL libs to another directory
mv libEGL* libgbm* libGLESv2* libwayland-egl* libGLESv1_CM* ../mesa-disabled/
# Recreate them around the libMali.so
ln -s libMali.so libGLESv2.so.2.0
ln -s libMali.so libGLESv1_CM.so.1.1
ln -s libMali.so libEGL.so.1.4
ln -s libMali.so libwayland-egl.so.1.0.0
ln -s libMali.so libgbm.so.1.0.0
ln -s libGLESv2.so.2.0 libGLESv2.so.2
ln -s libGLESv1_CM.so.1.1 libGLESv1_CM.so.1
ln -s libEGL.so.1.4 libEGL.so.1
ln -s libGLESv2.so.2 libGLESv2.so
ln -s libGLESv1_CM.so.1 libGLESv1_CM.so
ln -s libEGL.so.1 libEGL.so
ln -s libgbm.so.1.0.0 libgbm.so.1
ln -s libgbm.so.1 libgbm.so
ln -s libwayland-egl.so.1.0.0 libwayland-egl.so.1
ln -s libwayland-egl.so libwayland-egl.so
cd -
rm -fr mali-450_r7p0-01rel0_linux_1+arm64

# Mali, video decoder udev rules
tee p2/etc/udev/rules.d/50-mali.rules <<EOF
KERNEL=="mali", MODE="0666", GROUP="video"
SUBSYSTEM=="video4linux", ATTR{name}=="meson-video-decoder", SYMLINK+="video-dec0"
EOF

binary-amlogic/mkimage -C none -A arm -T script -d binary-amlogic/boot.cmd p1/boot.scr

umount p2
umount p1

dd if=binary-amlogic/u-boot.bin.sd.bin of="${IMAGE_LOOP_DEV}" conv=fsync bs=1 count=442
dd if=binary-amlogic/u-boot.bin.sd.bin of="${IMAGE_LOOP_DEV}" conv=fsync bs=512 skip=1 seek=1

losetup -d "${IMAGE_LOOP_DEV}"
mv "${IMAGE_FOLDER}${IMAGE_FILE_NAME}" "${IMAGE_FILE_NAME}"
if [ $RAM -ne 0 ]; then
	umount "${IMAGE_FOLDER}"
fi
rmdir "${IMAGE_FOLDER}"
rmdir p1 p2
