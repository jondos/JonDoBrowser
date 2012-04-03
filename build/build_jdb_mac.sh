#!/bin/bash
svnDir=https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build
langs="en de"
svn cat $svnDir/.mozconfig_mac > build/mozilla-release/.mozconfig

cd build/mozilla-release
make -f client.mk build
cd ../..
for lang in $langs; do
  appDir=JonDoBrowser-mac-$lang/Contents/MacOS
  cp -rf build/mozilla-release/mac_build/dist/Firefox.app/* $appDir/Firefox.app 
  mv JonDoBrowser-mac-$lang JonDoBrowser-mac-$lang.app
  zip -r9 JonDoBrowser-mac-$lang.zip JonDoBrowser-mac-$lang.app
done
