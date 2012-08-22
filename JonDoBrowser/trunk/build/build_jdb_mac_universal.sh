#!/bin/bash

svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile
svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
langs="en de"
# We only need the german language pack currently as english is the default
xpiLang=de
platforms="mac"
jdbVersion="0.1"
langs="en de"
title="JonDoBrowser"
size="200000"
source="JDB"
backgroundPictureName="background.png"

generateDmgImage() {
  # Function for creating JonDoBrowser dmg on Mac OS X.
  # Originally by Arturo Filasto' 2011 for the TorBrowserBundle.
  #
  # To make this work you need to set the $source and $backgroundPictureName
  # The $source directory should contain the .background directory with the# background image inside
  #
  # based on:
  # http://stackoverflow.com/questions/96882/how-do-i-create-a-nice-looking-dmg-for-mac-os-x-using-command-line-tools
  # Adapted for JonDoBrowser's needs by Georg Koppen, JonDos GmbH 2012.

  applicationName="JonDoBrowser-mac-$jdbVersion-$1.app"
  finalDMGName="JonDoBrowser-mac-$jdbVersion-$1.dmg"
  # TODO GeKo: Why does the backslash as a line delimiter not work but result in an error?
  # UDBZ?
  hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k JDB.temp.dmg

  # TODO Geko: Why does the backslash as a line delimiter not work but result in an error?
  device=$(hdiutil attach -readwrite -noverify -noautoopen "JDB.temp.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}')

  echo '
    tell application "Finder"
      tell disk "'${title}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 450}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 128
           set background picture of theViewOptions to file ".background:'${backgroundPictureName}'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${applicationName}'" of container window to {100, 120}
           set position of item "Applications" of container window to {375, 120} 
           update without registering applications
           delay 5
           eject
       end tell
     end tell
  ' | osascript

  chmod -Rf go-w /Volumes/"${title}"
  sync
  sync
  hdiutil detach ${device}
  hdiutil convert "JDB.temp.dmg" -format UDBZ -o "${finalDMGName}"
  rm "$source.temp.dmg"
}

prepareProfile() {
  echo "Fetching sources..."
  svn export $svnProfile
  svn export $svnBrowser/build/patches/xpi/XPI-Branding.patch XPI.patch
  for lang in $langs; do
    svn export $svnBrowser/build/langPatches/prefs_browser_$lang.js
  done
  svn export $svnBrowser/build/mac/JonDoBrowser
  chmod +x JonDoBrowser
  svn export $svnBrowser/build/patches/xpi/jondofox.xpi
  svn export $svnBrowser/build/mac/Info.plist
  svn export $svnBrowser/build/mac/jondobrowser.icns

  echo "Preparing the profile..."
  # We do not need ProfileSwitcher in our JonDoBrowser, thus removing it.
  rm -rf profile/extensions/\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4\}
  # Patching the profile xpi to be optimized for JDB, sigh...
  unzip -d profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\} -o jondofox.xpi 
  # Cruft from the old JonDoFox-Profile...
  rm -f profile/prefs_portable*
  rm -f profile/bookmarks* 
}

prepareMacProfiles() {
  echo "Creating language specific Mac profiles..."
  local appDir
  local dataDir
  local profileDir

  for lang in $langs; do
    jdbDir=JonDoBrowser-mac-$jdbVersion-$lang
    appDir=$jdbDir/Contents/MacOS
    dataDir=$appDir/Firefox.app/Contents/MacOS/Data
    profileDir=$jdbDir/Library/Application\ Support/Firefox/Profiles/profile
    mkdir -p $appDir/Firefox.app/Contents/Resources
    mkdir $jdbDir/Contents/Resources
    mkdir -p $dataDir/profile
    mkdir $dataDir/plugins
    mkdir -p "$profileDir"
    cp -rf profile/* "$profileDir"
    cp -f prefs_browser_$lang.js "$profileDir"/prefs.js
    mv -f "$profileDir"/places.sqlite_$lang "$profileDir"/places.sqlite
    rm -f "$profileDir"/places.sqlite_*
    cp JonDoBrowser $appDir
    cp Info.plist $jdbDir/Contents
    cp jondobrowser.icns $jdbDir/Contents/Resources
    # Copying the language xpi to get other language strings than the en-US
    # ones.
    # TODO: We need to get that copied from the Linux machine first...
    if [ "$lang" = "de" ]; then
      cp -f mac_de.xpi "$profileDir"/extensions/langpack-de@firefox.mozilla.org.xpi
    fi
  done
}

cleanup() {
  # Cleanup: Imitating make...
  echo "Cleaning up everything..."
  rm -rf tmp && rm -rf build
  exit 0
}

OPTSTR="ch"
getopts "${OPTSTR}" CMD_OPT
while [ $? -eq 0 ];
do
  case ${CMD_OPT} in
    c) cleanup;;
    h) echo '' 
       echo 'JonDoBrowser Build Script 1.0 (2012 Copyright (c) JonDos GmbH)'
       echo "usage: $0 [options]"
       echo ''
       echo 'Possible options are:'
       echo '-c removes old build cruft.'
       echo '-h prints this help text.'
       echo ''
       exit 0
       ;;
  esac
  getopts "${OPTSTR}" CMD_OPT
done

# In tmp there have to be the FF source and the mac lang xpi.
cd tmp

echo "Setting up the JonDoBrowser profiles..."
prepareProfile
prepareMacProfiles

cd ..

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
  svn export https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build/patches \
    1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release

svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
svn cat $svnBrowser/build/.mozconfig_mac_universal > .mozconfig
make -f client.mk build

echo "Creating the final packages..."
cd ../..
for lang in $langs; do
  jdbDir=JonDoBrowser-mac-$jdbVersion-$lang
  cp -rf tmp/$jdbDir .
  cp -rf build/mozilla-release/mac_build/i386/dist/universal/firefox/JonDoBrowser.app/* $jdbDir/Contents/MacOS/Firefox.app
  mv $jdbDir $jdbDir.app
  # Preparing everything for generating the dmg image...
  if [ ! -d $source ]; then
    mkdir $source
    cd $source && mkdir .background && cd .background
    svn cat $svnBrowser/build/mac/background-$lang.png > ${backgroundPictureName}
    cd ../..
  fi
  mv $jdbDir.app $source/
  generateDmgImage $lang
  rm -rf $source
done
