#!/bin/sh

cp patches/*.patch buildtmp/mozilla-release/
cp -r branding/jondobrowser31 buildtmp/mozilla-release/browser/branding/jondobrowser
cd buildtmp/mozilla-release
 
# Essentially the patch-any-src.sh from the Tor Project
# for i in *patch; do patch -tp1 <$i || exit 1; done

cd ..
