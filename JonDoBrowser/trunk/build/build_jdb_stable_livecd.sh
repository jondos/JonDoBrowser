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

# This script fetches the latest sources of a Firefox release and verifies them.
# Afterwards the browser profiles are prepared and JonDoBrowser for Linux is
# built.

svnXPI="https://svn.jondos.de/svnpub/JonDoFox_Extension/trunk/xpi/jondofoxBrowser.xpi"
svnProfile="https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile"
svnBrowser="https://svn.jondos.de/svnpub/JonDoBrowser/trunk"
# The locales we support. en-US must be first as all the other localized builds
# are actually only a repackaging of the en-US one.
langs="de"
# Allowing 32bit and 64bit JonDoBrowser builds
platform="linux-$(uname -m)"
jdbDir="JonDoBrowser"
jdbVersion="0.13"
# TODO: Shouldn't we check whether this one is still used/valid before actually
# building? Maybe that's something which is related to the more generic routine
# for the case the key was not imported yet which is mentioned below.
mozKey="5445390EF5D0C2ECFB8A6201057CC3EB15A0A4BC"

releasePath="http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-esr"


prepareProfile() {
  echo "Fetching sources..."
  svn export $svnProfile
  for lang in $langs; do
    svn export $svnBrowser/start-jondobrowser_$lang.sh
  done
  svn export $svnBrowser/CHANGELOG
  svn export $svnXPI

  echo "Preparing the profile..."
  # We do not need ProfileSwitcher in our JonDoBrowser, thus removing it.
  rm -rf profile/extensions/\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4\}.xpi
  # Remove the JonDoFox-XPI for JonDoFox and replace it with JDB-XPI
  cp -f jondofoxBrowser.xpi profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi

  # Cruft from the old JonDoFox-Profile...
  rm -f profile/prefs_portable*
}

prepareLinuxProfiles() {
  echo "Creating language specific Linux profiles..."
  local profileDir

  for lang in $langs; do
    profileDir="$jdbDir-$lang/Data/profile"
    mkdir -p $jdbDir-$lang/App/Firefox
    mkdir -p $jdbDir-$lang/Data/plugins
    cp -rf profile $jdbDir-$lang/Data

    # modify preferences for JDB
    sed -i "s/Arial/Liberation Sans/" $profileDir/prefs.js
    echo "user_pref(\"extensions.jondofox.browser_version\", \"${jdbVersion}\");" >> $profileDir/prefs.js
    echo "user_pref(\"app.update.enabled\", false);" >> $profileDir/prefs.js

    cp start-jondobrowser_$lang.sh $jdbDir-$lang/start-jondobrowser.sh
    chmod +x $jdbDir-$lang/start-jondobrowser.sh
    cp CHANGELOG $jdbDir-$lang
    mv -f $profileDir/places.sqlite_$lang $profileDir/places.sqlite
    rm -f $profileDir/places.sqlite_*
    
        wget -t 3 -O $profileDir/extensions/langpack-de@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/de.xpi
        wget -t 3 -O $profileDir/extensions/langpack-es-ES@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/es-ES.xpi
        wget -t 3 -O $profileDir/extensions/langpack-fr@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/fr.xpi
        wget -t 3 -O $profileDir/extensions/langpack-it@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/it.xpi
        wget -t 3 -O $profileDir/extensions/langpack-pl@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/pl.xpi
        wget -t 3 -O $profileDir/extensions/langpack-ru@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/ru.xpi
        wget -t 3 -O $profileDir/extensions/langpack-sv-SE@firefox.mozilla.org.xpi  $releasePath/linux-i686/xpi/sv-SE.xpi
        echo "user_pref(\"extensions.langpack-de@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.langpack-es-ES@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.langpack-fr@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.langpack-it@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.langpack-pl@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.langpack-ru@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.langpack-sv-SE@firefox.mozilla.org.update.enabled\", false);" >> $profileDir/prefs.js

        echo "user_pref(\"browser.safebrowsing.dataProvider\", -1);" >> $profileDir/prefs.js
        echo "user_pref(\"browser.safebrowsing.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"browser.safebrowsing.malware.enabled\", false);" >> $profileDir/prefs.js

        echo "user_pref(\"extensions.{437be45a-4114-11dd-b9ab-71d256d89593}.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.{45d8ff86-d909-11db-9705-005056c00008}.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.{73a6fe31-595d-460b-a920-fcc0f8843232}.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.{b9db16a4-6edc-47ec-a1f4-b86292ed211d}.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.update.enabled\", false);" >> $profileDir/prefs.js
        echo "user_pref(\"extensions.https-everywhere@eff.org.update.enabled\", false);" >> $profileDir/prefs.js

        cp $profileDir/prefs.js $profileDir/prefs.js_jondo
        mv $profileDir/prefs.js $profileDir/prefs.js_ohne
  done
}

cleanup() {
  #Cleanup: Imitating make...
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
       echo "JonDoBrowser Build Script 1.2 (2012-2013 Copyright (c) JonDos \
GmbH)"
       echo ''
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
echo "Getting the latest Firefox ESR source version..."
ffVersion=$(wget -t 3 -qO - $releasePath/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9])*esr.source.tar.bz2' | tail -n1 | \
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])*')

gpgVerification() {
  sigKey=$(gpg --verify $1 2>&1 | \
    grep -Eom 2 '([A-Z0-9]{4}\s*){10}' | tail -n1 | tr -d ' ')

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
  echo "Getting the latest Firefox sources ..."
  wget -t 3 $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-${ffVersion}esr.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  wget -t 3 $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine here assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
# gpgVerification firefox-${ffVersion}esr.source.tar.bz2.asc

echo "Retrieving commonly used resources preparing the profiles..."
prepareProfile

# Now, we set up the JonDoBrowser profiles
echo "Setting up the JonDoBrowser profiles..."
prepareLinuxProfiles

cd ..

# Now, extracting, patching, rebranding and building JonDoBrowser...
if [ ! -d "build" ]; then
  mkdir build
fi

cd build && cp ../tmp/firefox-${ffVersion}esr.source.tar.bz2 .
echo "Unpack Firefox source..."
tar -xjf firefox-${ffVersion}esr.source.tar.bz2
# We do not want to care about specific ESR versions, thus we rename the dir
# to "mozilla-release".
mv mozilla-esr* mozilla-release
echo
echo "Downloading the build config file..."
svn cat $svnBrowser/build/.mozconfig_linux-livecd > .mozconfig
echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export $svnBrowser/build/patches 1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release


svn export $svnBrowser/build/branding/jondobrowser24 browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
cp -f ../.mozconfig .
make -f client.mk build
echo "Creating the final packages..."
cd linux_build && make package

for lang in $langs; do
  echo "Creating the JonDoBrowser with $lang support..."
  cp dist/firefox-$ffVersion.en-US.$platform.tar.bz2 ../../../tmp
  cd ../../../tmp && tar -xjf firefox-$ffVersion.en-US.$platform.tar.bz2

  # remove default search engines
  rm firefox/browser/searchplugins/*.xml

  jdbFinal=JonDoBrowser-live-$jdbVersion-$platform
  cp -rf firefox/* $jdbDir-$lang/App/Firefox
  mv $jdbDir-$lang $jdbDir
  tar -cf $jdbFinal.tar $jdbDir
  xz $jdbFinal.tar
  mv $jdbFinal.tar.xz ../
  rm -rf $jdbDir
  # TODO: Only needed if we need to build another localized build...
  cd ../build/mozilla-release/linux_build
done

cd ../../../

exit 0
