#!/bin/sh

apt -y install build-essential git bison yasm python nodejs gperf libjpeg-turbo8-dev libxml2-dev libxslt1-dev libnss3-dev libcups2-dev libflac-dev libpci-dev uuid-dev

CHROMIUM="chromium-ozone-wayland-dev-71.0.3545.0.r589108.igalia.1"
CHROMIUM_TARBALL="${CHROMIUM}.tar.xz"
IGALIA_URI="https://tmp.igalia.com/chromium-tarballs/"

GN_UNBUNDLE_LIBS="flac libjpeg libwebp libxml libxslt yasm"
GN_ARGS="use_gnome_keyring=false use_kerberos=false use_system_freetype=true use_system_libjpeg=true is_debug=false is_official_build=true use_custom_libcxx=false symbol_level=0 enable_remoting=false enable_nacl=false use_sysroot=false treat_warnings_as_errors=false is_cfi=false use_ozone=true ozone_auto_platforms=false ozone_platform_headless=true ozone_platform_wayland=true ozone_platform_x11=false use_xkbcommon=true use_system_libwayland=true use_system_minigbm=true use_wayland_gbm=false use_v4l2_codec=true use_v4lplugin=true use_linux_v4l2_only=true ffmpeg_branding=\"Chrome\" proprietary_codecs=true linux_use_bundled_binutils=false target_cpu=\"arm64\" is_clang=false"
OUTPUT_DIR="out/Release"

if [ ! -f /usr/bin/gn ]
then
	cp gn.arm64 /usr/bin/gn
fi

if [ ! -f ${CHROMIUM_TARBALL} ]
then
	wget ${IGALIA_URI}${CHROMIUM_TARBALL}
	tar xf ${CHROMIUM_TARBALL}
	cd ${CHROMIUM}
	git apply ../*.patch
else
	cd ${CHROMIUM}
fi

if [ ! -f third_party/node/linux/node-linux-x64/bin/node ]
then
	cp /usr/bin/node third_party/node/linux/node-linux-x64/bin/
fi

./build/linux/unbundle/replace_gn_files.py --system-libraries ${GN_UNBUNDLE_LIBS}
gn gen --args="${GN_ARGS}" "${OUTPUT_DIR}"
cd ${OUTPUT_DIR}
ninja -v -j6 chrome chrome_sandbox chromedriver
../../install_chromium.sh

cd -
cd -
