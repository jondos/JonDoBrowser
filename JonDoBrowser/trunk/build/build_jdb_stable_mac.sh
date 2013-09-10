#!/bin/bash

# Copyright (C) 2012-2013 Jondos GmbH

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

# This script is used to compile the JonDoBrowser on Mac OS X 10.8. If a working
# version on Mac OS X 10.6 is needed, check out rev 4230 and adapt it to the
# latest Firefox ESR changes (e.g. new patches that may be necessary).

svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile
svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
# The locales we support. en-US must be first as all the other localized builds
# are actually only a repackaging of the en-US one.
langs="en-US de"
macPlatforms="mac-x86_64 mac-i386"
jdbVersion="0.9"
title="JonDoBrowser"
size="200000"
mozKey=5445390EF5D0C2ECFB8A6201057CC3EB15A0A4BC
releasePath=http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-esr
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
  finalDMGName="JonDoBrowser-$jdbVersion-$1-$2.dmg"
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
  rm -rf profile/extensions/\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4\}.xpi
  # Patching the profile xpi to be optimized for JDB, sigh...
  unzip -d profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\} -o jondofox.xpi
  # TODO: Why does -f or -s not work? And removing the .xpi in the extensions folder if it exists...
  #if [ -f "profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi" ]
  #then
    rm profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi
  #fi
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

# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.
# When we are using 'wget' in this script we retry three times if necessary
# as some mirrors of releases.mozilla.org seem to be not reachable at times...
echo "Getting the latest Firefox source version..."
ffVersion=$(curl -L --retry 3 -so - $releasePath/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9])*esr.source.tar.bz2' | tail -n1 | \
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
elif [ ! -e "firefox-${ffVersion}esr.source.tar.bz2" ]; then
  echo "Getting the latest Firefox ESR sources (version $ffVersion)..."
  curl --retry 3 -O $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-${ffVersion}esr.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  curl --retry 3 -O $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
gpgVerification firefox-${ffVersion}esr.source.tar.bz2.asc

echo "Retrieving commonly used resources preparing the profiles..."
prepareProfile

echo "Setting up the JonDoBrowser profiles..."
prepareMacProfiles

cd ..

# Now, extracting, patching, rebranding and building JonDoBrowser...
if [ ! -d "build" ]; then
  mkdir build
fi

# Assuming we got the verified FF source copied to tmp first...
cd build && cp ../tmp/firefox-${ffVersion}esr.source.tar.bz2 .
tar -xjvf firefox-${ffVersion}esr.source.tar.bz2
# We do not want to care about specific ESR versions, thus we rename the dir
# to "mozilla-release".
mv mozilla-esr* mozilla-release
echo
echo "Downloading the build config file..."
svn cat $svnBrowser/build/.mozconfig_mac > .mozconfig
echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export $svnBrowser/build/patches 1>/dev/null
fi

cd patches
svn export $svnBrowser/build/patches/os/Mac107ESR17.patch
cd ..

cp patches/*.patch mozilla-release/ && cd mozilla-release

svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
for macPlatform in $macPlatforms; do
  for lang in $langs; do
    cp -f ../.mozconfig .
    echo >> .mozconfig
    echo "mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/mac_build_${macPlatform}" \
      >> .mozconfig
    echo >> .mozconfig
    echo "ac_add_options --with-macos-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.6.sdk" \
      >> .mozconfig
    echo "ac_add_options --enable-macos-target=10.6" >> .mozconfig
    echo >> .mozconfig
    echo "HOST_CC=clang" >> .mozconfig
    echo "HOST_CXX=clang++" >> .mozconfig
    echo "RANLIB=ranlib" >> .mozconfig
    echo "AR=ar" >> .mozconfig
    echo 'AS=$CC' >> .mozconfig
    echo "LD=ld" >> .mozconfig
    echo "STRIP=\"strip -x -S\"" >> .mozconfig
    echo "CROSS_COMPILE=1" >> .mozconfig

    if [ "$macPlatform" == "mac-i386" ]; then
      # TODO: Not sure if we need everything here.
      # On 10.6.8 our building platform we only get clang 2.9 as newest clang
      # version if installed via MacPorts. But that is not recent enough to
      # build JonDoBrowser if it is based at least on FF 17. Thus, we need our
      # own compiler (3.1 is working atm)...
      echo "CC=\"clang -arch i386\"" >> .mozconfig
      echo "CXX=\"clang++ -arch i386\"" >> .mozconfig
      echo "ac_add_options --target=i386-apple-darwin10.6.0" >> .mozconfig
    else
      echo "CC=\"clang -arch x86_64\"" >> .mozconfig
      echo "CXX=\"clang++ -arch x86_64\"" >> .mozconfig
      echo "ac_add_options --target=x86_64-apple-darwin10.6.0" >> .mozconfig
    fi
    if [ "$lang" == "en-US" ]; then
      make -f client.mk build && make -C mac_build_$macPlatform package
    else
      # Now, we do all the stuff needed for localized builds
      cd ../../tmp
      # Checking out the locale repo if it is not existing already
      if [ ! -d $lang ]; then
        # TODO: Can we make it even more sure that no one tampered with the
        # repo(s)? It seems not as tags are not signed yet...
        hg clone -r FIREFOX_${ffVersion//./_}esr_RELEASE https://hg.mozilla.org/releases/l10n/mozilla-release/$lang
        cd $lang
        echo "Verifying the source repo..."
        hg verify
        retVal=$?
        if [ $retVal -eq 1 ]; then
          echo "Something went wrong with verifying the source repo! Exiting..."
          exit 1
        fi
        echo "Done."
        cd ..
        # We need the branding files in the locale repo as well
        rsync ../build/mozilla-release/browser/branding/jondobrowser/locales/en-US/brand* $lang/browser/branding/jondobrowser
      fi
      # Updating the .mozconfig
      cd ../build/mozilla-release
      echo >> .mozconfig
      echo "ac_add_options --with-l10n-base=$(cd ../../tmp && pwd)" >> .mozconfig
      echo "ac_add_options --disable-compile-environment" >> .mozconfig
      # Reconfiguring the build to be aware of the locale other than en-US
      make -f client.mk configure
      # Now we go and repack the binary
      cd mac_build_${macPlatform}/browser/locales
      # We are supposed to need the compare-locales tool for the merge-$lang
      # target. BUT it seems we can omit that which results in an error (127)
      # but adds the german language strings, though. Going this route for now
      # as this means less build dependencies...
      make merge-$lang LOCALE_MERGEDIR=mergedir
      make installers-$lang LOCALE_MERGEDIR=mergedir
      cd ../../../
    fi

    echo "Creating the final packages..."
    cd ../..
    jdbDir=JonDoBrowser-$lang
    cp -rf tmp/$jdbDir .
    # Now we unpack the .dmg file created during the packaging phase in order
    # to benfit from the packaging step (e.g. omni.ja) creation AND be able to
    # ship our own dmg files + having no langpack extension
    build/mozilla-release/build/package/mac_osx/unpack-diskimage build/mozilla-release/mac_build_$macPlatform/dist/firefox-${ffVersion}.$lang.*.dmg testing tmp
    cp -rf tmp/JonDoBrowser.app/* $jdbDir/Contents/MacOS/Firefox.app
    mv $jdbDir JonDoBrowser.app
    # Preparing everything for generating the dmg image...
    if [ ! -d $source ]; then
      mkdir $source
      cd $source && mkdir .background && cd .background
      svn cat $svnBrowser/build/mac/background-$lang.png > $backgroundPictureName
      cd ../..
    fi
    mv JonDoBrowser.app $source/
    generateDmgImage $macPlatform $lang
    rm -rf $source
    rm -rf tmp/JonDoBrowser.app
    # TODO: Only needed if we have to build another (localized) build...
    cd build/mozilla-release
  done
done

cd ../../

exit 0
