#!/bin/sh

platform="linux-$(uname -m)"

cp -f .mozconfig_$platform > buildtmp/mozilla-release/.mozconfig

cd buildtmp/mozilla-release
make -f client.mk build

cd linux_build 

# replace search engines


make package

cd ../../..

cp buildtmp/mozilla-release/dist/firefox-*.en-US.$platform.tar.bz2 buildtmp/firefox.en-US.tar.bz2
