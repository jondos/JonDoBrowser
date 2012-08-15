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

# This script fetches the latest sources of a Firefox release and verifies them.
# Afterwards the browser profiles are prepared and JonDoBrowser for Linux is
# built.

svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile
svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
langs="en de"
# We only need the german language pack currently as english is the default
xpiLang=de
# Allowing 32bit and 64bit JonDoBrowser builds
linuxPlatform="linux-$(uname -m)"
platforms="${linuxPlatform} mac"
version="0.1"
mozKey=247CA658AA95F6171EB0F13EA7D75CC7C52175E2 
releasePath=http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest
# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.
# When we are using 'wget' in this script we retry three times if necessary
# as some mirrors of releases.mozilla.org seem to be not reachable at times...
echo "Getting the latest Firefox source version..."
version=$(wget -t 3 -qO - $releasePath/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9])*.source.tar.bz2' | tail -n1 | \
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])*')

gpgVerification() {
  file=$1
  sigKey=$(gpg --verify $1 2>&1 | \
    grep -Eom 2 '([A-Z0-9]{4}\s*){10}' | tail -n1 | tr -d ' ')

  if [ "$sigKey" = "$mozKey" ]; then
    echo "Successful verification!"
  else
    echo "Wrong signature, aborting..."
    exit 1
  fi 
}

prepareProfile() {
  echo "Fetching sources..."
  svn export $svnProfile
  svn export $svnBrowser/build/patches/xpi/0004-XPI-Branding.patch XPI.patch
  for lang in $langs; do
    svn export $svnBrowser/build/langPatches/prefs_browser_$lang.js
  done
  svn export $svnBrowser/start-jondobrowser.sh
  chmod +x start-jondobrowser.sh
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

prepareLinuxProfiles() {
  echo "Creating language specific Linux profiles..."
  local profileDir

  for lang in $langs; do
    local jdbDir=JonDoBrowser-$linuxPlatform-$version-$lang 
    profileDir=$jdbDir/Data/profile
    mkdir -p $jdbDir/App/Firefox
    mkdir -p $jdbDir/Data/plugins
    cp -rf profile $jdbDir/Data
    cp -f prefs_browser_$lang.js $profileDir/prefs.js
    cp start-jondobrowser.sh $jdbDir
    mv -f $profileDir/places.sqlite_$lang $profileDir/places.sqlite
    rm -f $profileDir/places.sqlite_*
    # Copying the language xpi to get other language strings than the en-US
    # ones.
    if [ "$lang" = "de" ]; then
      cp -f ${linuxPlatform}_de.xpi $profileDir/extensions/langpack-de@firefox.mozilla.org.xpi
    fi
  done
}

prepareMacProfiles() {
  echo "Creating language specific Mac profiles..."
  local appDir
  local dataDir
  local profileDir
  local jdbPlatform="JonDoBrowser-mac"

  for lang in $langs; do
    appDir=$jdbPlatform-$lang/Contents/MacOS
    dataDir=$appDir/Firefox.app/Contents/MacOS/Data
    profileDir=$jdbPlatform-$lang/Library/Application\ Support/Firefox/Profiles/profile
    # TODO: Maybe we should include the JDB version in the directory name.
    # Something like JonDoBrowser-x.x.x-lang
    mkdir -p $appDir/Firefox.app/Contents/Resources
    mkdir $jdbPlatform-$lang/Contents/Resources
    mkdir -p $dataDir/profile
    mkdir $dataDir/plugins
    mkdir -p "$profileDir"
    cp -rf profile/* "$profileDir"
    cp -f prefs_browser_$lang.js "$profileDir"/prefs.js
    mv -f "$profileDir"/places.sqlite_$lang "$profileDir"/places.sqlite
    rm -f "$profileDir"/places.sqlite_*
    cp JonDoBrowser $appDir
    cp Info.plist $jdbPlatform-$lang/Contents
    cp jondobrowser.icns $jdbPlatform-$lang/Contents/Resources
    # Copying the language xpi to get other language strings than the en-US
    # ones.
    if [ "$lang" = "de" ]; then
      cp -f mac_de.xpi "$profileDir"/extensions/langpack-de@firefox.mozilla.org.xpi
    fi
  done
}

cleanup() {
  #Cleanup
  echo "Cleaning up everything..."
  rm -rf tmp && rm -rf build
  exit 0
}

if [ ! -d "tmp" ]; then
  mkdir tmp
fi
cd tmp

#TODO: Mitigation of downgrade attacks
if [ "$version" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-$version.source.tar.bz2" ]; then
  echo "Getting the latest Firefox sources ..."
  wget -t 3 $releasePath/source/firefox-$version.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-$version.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  wget -t 3 $releasePath/source/firefox-$version.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
gpgVerification firefox-$version.source.tar.bz2.asc

echo "Gettings the necessary language packs..."
echo "Fetching and verifying the SHA1SUMS file..."

wget -t 3 $releasePath/SHA1SUMS
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving SHA1SUMS, exiting..."
  exit 1
fi

wget -t 3 $releasePath/SHA1SUMS.asc
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving the SHA1SUMS signature, exiting..."
  exit 1
fi

gpgVerification SHA1SUMS.asc

echo "Retrieving the language pack(s) and verifying them..."

for platform in $platforms; do
  wget -t 3 -O ${platform}_$xpiLang.xpi $releasePath/$platform/xpi/$xpiLang.xpi 
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the $xpiLang language pack for"
    echo "$platform, continuing without it..."
    continue
  fi 
  xpiHash1=$(grep -E "$platform/xpi/$xpiLang.xpi" SHA1SUMS | \
    grep -Eo "[a-z0-9]{40}")
  xpiHash2=$(sha1sum ${platform}_$xpiLang.xpi | grep -Eo "[a-z0-9]{40}") 
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
done

# Now, we set up the JonDoBrowser profiles
echo "Setting up the JonDoBrowser profiles..."
prepareProfile
prepareLinuxProfiles
#prepareMacProfiles

cd ..

# Now, extracting, patching, rebranding and building JonDoBrowser...
if [ ! -d "build" ]; then
  mkdir build
fi

cd build && cp ../tmp/firefox-$version.source.tar.bz2 .
tar -xjvf firefox-$version.source.tar.bz2
echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build/patches \
    1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release
svn cat $svnBrowser/build/.mozconfig_linux-i686 > .mozconfig
svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

#TODO: Code for copying the Mac stuff to the Mac build server...
echo "Building JonDoBrowser..."
make -f client.mk build

echo "Creating the final packages..."
cd linux_build && make package 
mv dist/firefox-$version.en-US.${linuxPlatform}.tar.bz2 ../../../tmp
cd ../../../tmp && tar -xjvf firefox-$version.en-US.${linuxPlatform}.tar.bz2 

for lang in $langs; do
  local jdbDir=JonDoBrowser-$linuxPlatform-$version-$lang
  cp -rf firefox/* $jdbDir/App/Firefox
  tar -cf $jdbDir.tar $jdbDir
  bzip2 -z9 $jdbDir.tar
  mv $jdbDir.tar.bz2 ../
done

cd ..

exit 0
