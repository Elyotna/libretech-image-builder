#!/bin/sh

cd image
md5sum $(find ./usr -type f) > md5sums

tar cf data.tar usr

cp ../../../control .
tar cf control.tar control md5sums

xz -T4 data.tar
xz -T4 control.tar

echo '2.0' > debian-binary
ar r chromium_browser_71.0.3545.0_18.04_arm64.deb debian-binary control.tar.xz data.tar.xz

rm debian-binary control.tar.xz data.tar.xz control

cd -