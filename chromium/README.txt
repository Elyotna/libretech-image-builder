The script build_chromium.sh allows you to build chromium with ozone-wayland
and v4l2 decoding support.

To be run inside a chrooted ubuntu-base if you want it for arm64.
Please note: The only arm64 specific right now is the gn binary,
which you'll have to replace if you want to build it for another arch.

It is possible that some dependencies are missing despite the apt install line,
please report them!