git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-4.19.y --depth 1 linux
cd linux
git apply ../patches/linux/*.patch
cp ../defconfig_amlogic_arm64 .config
PATH=$PWD/../gcc-linaro-6.4.1-2017.08-x86_64_aarch64-linux-gnu/bin:$PATH make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j4
cd -
