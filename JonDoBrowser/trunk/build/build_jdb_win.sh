#!/bin/bash

svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk

# Now, extracting, patching, rebranding and building JonDoBrowser...
if [ ! -d "build" ]; then
  mkdir build
fi

# Assuming we got the verified FF source copied to tmp first...
cd build && cp ../tmp/firefox-*.source.tar.bz2 .
tar -xjvf firefox-*.source.tar.bz2
echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export $svnBrowser/trunk/build/patches 1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release

svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
svn cat $svnBrowser/build/.mozconfig_win > .mozconfig

python build/pymake/make.py -f client.mk
cd win32_build
python ../build/pymake/make.py package
cd dist
mv firefox*.zip ../../../
cd ../../
rm -rf win32_build
cd ..
