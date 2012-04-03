#!/bin/bash
svn cat ${svnDir}.mozconfig_mac > .mozconfig
mv .mozconfig build/mozilla-release

cd build/mozilla-release
make -f client.mk build
cd ../..
cp -rf build/mozilla-release/mac_build/dist/Firefox.app/* ${appDir}/Firefox.app 
