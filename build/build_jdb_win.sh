#!/bin/bash

svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
FFPath=profile/Firefox/App/firefox
FFEnPath=profile/FirefoxByLanguage/enFirefoxPortablePatch/App/firefox

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
  svn export $svnBrowser/build/patches 1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release

svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
svn cat $svnBrowser/build/.mozconfig_win32 > .mozconfig

python build/pymake/make.py -f client.mk
cd win32_build
python ../build/pymake/make.py package
cd dist
mv firefox*.zip ../../../
cd ../../
rm -rf win32_build
cd ../../

# Now preparing the installer
echo "Now we gonna build the installer..."
svn export $svnBrowser/build/win profile
unzip -d profile/Firefox/App build/firefox*.zip

# Moving language specific files...
mkdir -p $FFEnPath
mv $FFPath/omni.ja $FFEnPath
mv $FFPath/dictionaries $FFEnPath
rm -rf $FFPath/searchplugins

# Building the files...
cd profile/Firefox/Other/Source
# TODO: Why don't we get a functional JonDoBrowser.exe if we build it with the
# 2.46 NSIS shipped with Mozilla Build?
echo "Building the JonDoBrowser installer"
makensisu-2.46.exe JonDoBrowser.nsi
cd ../../../../
mv profile/JonDoBrowser*.exe .
rm -rf profile

exit 0
