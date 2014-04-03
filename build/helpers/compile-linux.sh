#!/bin/sh

platform="linux-$(uname -m)"

cp -f .mozconfig_$platform buildtmp/mozilla-release/.mozconfig
 
cd buildtmp/mozilla-release
make -f client.mk build

cd linux_build 
make package

cd ../../..

cp buildtmp/mozilla-release/linux_build/dist/firefox-*.en-US.$platform.tar.bz2 buildtmp/firefox.tar.bz2
