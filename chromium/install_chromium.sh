#!/bin/sh

# Create package directory in ./image/
# To be run in chromium's build dir, like <chromium>/out/Release

# The near entirety of this script is taken from
# https://github.com/Igalia/meta-browser/blob/ozone/wayland/71.0.3545.0.r589108/recipes-browser/chromium/chromium-gn.inc

D="./image"
bindir="/usr/bin"
libdir="/usr/lib"
datadir="/usr/share"
CHROMIUM_EXTRA_ARGS="--use-gl=egl --ozone-platform=wayland --in-process-gpu"

rm -rf ${D}

install -d ${D}${bindir}
install -d ${D}${datadir}
install -d ${D}${datadir}/applications
install -d ${D}${datadir}/icons
install -d ${D}${datadir}/icons/hicolor
install -d ${D}${libdir}/chromium
install -d ${D}${libdir}/chromium/locales

install -m 4755 chrome_sandbox ${D}${libdir}/chromium/chrome-sandbox
install -m 0755 chrome ${D}${libdir}/chromium/chromium-bin
install -m 0644 *.bin ${D}${libdir}/chromium/
install -m 0644 icudtl.dat ${D}${libdir}/chromium/icudtl.dat

# Process and install Chromium's template .desktop file.
sed -e "s,@@MENUNAME@@,Chromium Browser,g" \
    -e "s,@@PACKAGE@@,chromium,g" \
    -e "s,@@USR_BIN_SYMLINK_NAME@@,chromium,g" \
    ../../chrome/installer/linux/common/desktop.template > chromium.desktop
install -m 0644 chromium.desktop ${D}${datadir}/applications/chromium.desktop

# Install icons.
for size in 16 22 24 32 48 64 128 256; do
	install -d ${D}${datadir}/icons/hicolor/${size}x${size}
	install -d ${D}${datadir}/icons/hicolor/${size}x${size}/apps
	for dirname in "chromium" "default_100_percent/chromium"; do
		icon="${S}/chrome/app/theme/${dirname}/product_logo_${size}.png"
		if [ -f "${icon}" ]; then
			install -m 0644 "${icon}" \
				${D}${datadir}/icons/hicolor/${size}x${size}/apps/chromium.png
		fi
	done
done

# A wrapper for the proprietary Google Chrome version already exists.
# We can just use that one instead of reinventing the wheel.
WRAPPER_FILE=../../chrome/installer/linux/common/wrapper
sed -e "s,@@CHANNEL@@,stable,g" \
	-e "s,@@PROGNAME@@,chromium-bin,g" \
	${WRAPPER_FILE} > chromium-wrapper
install -m 0755 chromium-wrapper ${D}${libdir}/chromium/chromium-wrapper
ln -s ${libdir}/chromium/chromium-wrapper ${D}${bindir}/chromium

# Chromium *.pak files
install -m 0644 chrome_*.pak ${D}${libdir}/chromium/
install -m 0644 resources.pak ${D}${libdir}/chromium/resources.pak

# Locales.
install -m 0644 locales/*.pak ${D}${libdir}/chromium/locales/

# Add extra command line arguments to the chromium-wrapper script by
# modifying the dummy "CHROME_EXTRA_ARGS" line
sed -i "s/^CHROME_EXTRA_ARGS=\"\"/CHROME_EXTRA_ARGS=\"${CHROMIUM_EXTRA_ARGS}\"/" ${D}${libdir}/chromium/chromium-wrapper

# ChromeDriver.
install -m 0755 chromedriver ${D}${bindir}/chromedriver
