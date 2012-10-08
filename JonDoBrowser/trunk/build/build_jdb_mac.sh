#!/bin/bash

# Copyright (C) 2012 Jondos GmbH

# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, 
#    this list of conditions and the following disclaimer in the documentation 
#    and/or other materials provided with the distribution.
#  * Neither the name of the JonDos GmbH nor the names of its contributors may 
#    be used to endorse or promote products derived from this software without 
#    specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile
svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
langs="en de"
# We only need the german language pack currently as english is the default
xpiLang=de
macPlatform=""
platform="mac"
jdbVersion="0.1"
title="JonDoBrowser"
size="200000"
mozKey=247CA658AA95F6171EB0F13EA7D75CC7C52175E2
releasePath=http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest
source="JDB"
backgroundPictureName="background.png"

generateDmgImage() {
  # Function for creating JonDoBrowser dmg on Mac OS X based on:
  # http://stackoverflow.com/questions/96882/how-do-i-create-a-nice-looking-
  # dmg-for-mac-os-x-using-command-line-tools
   
  # To make this work you need to set source and $backgroundPictureName.
  # The $source directory should contain the .background directory with the
  # background image inside.
  #
  # Adapted for JonDoBrowser's needs by Georg Koppen, JonDos GmbH 2012.

  # We want to have just "JonDoBrowser" shown. 
  applicationName="JonDoBrowser.app"
  finalDMGName="JonDoBrowser-${macPlatform}-$jdbVersion-$1.dmg"
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
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 128
           set background picture of theViewOptions to file ".background:'${backgroundPictureName}'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${applicationName}'" of container window to {100, 120}
           set position of item "Applications" of container window to {375, 120} 
           close
           open
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
  svn export $svnBrowser/CHANGELOG
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
  # And removing the .xpi in the extensions folder if it exists...
  if [ -f "profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi" ]
  then
    rm profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi
  fi
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
    jdbDir=JonDoBrowser-$lang
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
    cp CHANGELOG $appDir
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

# On which platform are we building? |uname -m| does not necessarily work as we
# may have a 32Bit Kernel but build nevertheless 64Bit JonDoBrowsers. Testing
# via |ioreg -l -p IODeviceTree | grep firmware-abi | grep -Eo 64| does not work
# either. Assuming we have gcc available we borrow the test from config.guess.
if gcc -E -dM -x c /dev/null | grep __LP64__>/dev/null 2>&1 ; then
  macPlatform="mac-x86_64"
else
  macPlatform="mac-i386"
fi

# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.
# When we are using 'wget' in this script we retry three times if necessary
# as some mirrors of releases.mozilla.org seem to be not reachable at times...
echo "Getting the latest Firefox source version..."
ffVersion=$(curl -L --retry 3 -so - $releasePath/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9])*.source.tar.bz2' | tail -n1 | \
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])*')

gpgVerification() {
  sigKey=$(gpg --verify $1 2>&1 | tail -n1 | tr -d ' ' | \
           sed 's/.*[^A-F0-9]\([A-F0-9]\{40\}\)/\1/g')

  if [ "$sigKey" = "$mozKey" ]; then
    echo "Successful verification!"
  else
    echo "Wrong signature, aborting..."
    exit 1
  fi 
}

if [ ! -d "tmp" ]; then
  mkdir tmp
fi
cd tmp

#TODO: Mitigation of downgrade attacks
if [ "$ffVersion" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-$ffVersion.source.tar.bz2" ]; then
  echo "Getting the latest Firefox sources (version $ffVersion)..."
  curl --retry 3 -O $releasePath/source/firefox-$ffVersion.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-$ffVersion.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  curl --retry 3 -O $releasePath/source/firefox-$ffVersion.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
gpgVerification firefox-$ffVersion.source.tar.bz2.asc

echo "Gettings the necessary language packs..."
echo "Fetching and verifying the SHA1SUMS file..."

curl --retry 3 -O $releasePath/SHA1SUMS
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving SHA1SUMS, exiting..."
  exit 1
fi

curl --retry 3 -O $releasePath/SHA1SUMS.asc
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving the SHA1SUMS signature, exiting..."
  exit 1
fi

gpgVerification SHA1SUMS.asc

echo "Retrieving commonly used resources preparing the profiles..."
prepareProfile

echo "Retrieving the language pack(s) and verifying them..."

curl --retry 3 -o ${platform}_$xpiLang.xpi $releasePath/$platform/xpi/$xpiLang.xpi
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving the $xpiLang language pack for"
  echo "$platform, continuing without it..."
  continue
fi
xpiHash1=$(grep -E "$platform/xpi/$xpiLang.xpi" SHA1SUMS | \
  grep -Eom 1 "[a-z0-9]{40}")
xpiHash2=$(shasum ${platform}_$xpiLang.xpi | grep -Eo "[a-z0-9]{40}")
if [ "$xpiHash1" = "$xpiHash2" ]; then
  echo "Verified SHA1 hash..."
  if [ ! -d xpi_helper ]; then
    mkdir xpi_helper
  fi
  unzip -d xpi_helper ${platform}_$xpiLang.xpi
  cd xpi_helper
  # TODO: That is german only! If we start to support other languages besides
  # enlish and german we have to create language specific patches!
  echo "Patching the xpi..."
  patch -tp1 < ../XPI.patch 
  zip -r ${platform}_$xpiLang.xpi *
  mv ${platform}_$xpiLang.xpi ../
  rm -rf * && cd ..
else
  echo "Wrong SHA1 hash of ${platform}_$xpiLang.xpi, removing it" 
  rm ${platform}_$xpiLang.xpi
  exit 1
fi

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
svn cat $svnBrowser/build/.mozconfig_mac > .mozconfig
make -f client.mk build

echo "Creating the final packages..."
cd ../..
for lang in $langs; do
  jdbDir=JonDoBrowser-$lang
  cp -rf tmp/$jdbDir .
  cp -rf build/mozilla-release/mac_build/dist/JonDoBrowser.app/* $jdbDir/Contents/MacOS/Firefox.app
  mv $jdbDir JonDoBrowser.app
  # Preparing everything for generating the dmg image...
  if [ ! -d $source ]; then
    mkdir $source
    cd $source && mkdir .background && cd .background
    svn cat $svnBrowser/build/mac/background-$lang.png > ${backgroundPictureName}
    cd ../..
  fi
  mv JonDoBrowser.app $source/
  generateDmgImage $lang
  rm -rf $source
done

exit 0
